require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const rateLimit = require('express-rate-limit');
const path = require('node:path');

const app = express();
const port = Number(process.env.PORT || 3000);
const maxUploadMb = Number(process.env.MAX_UPLOAD_MB || 20);
const geminiApiKey = String(process.env.GEMINI_API_KEY || '').trim();
// Interactions API recebe apenas o ID do modelo. Também corrige o prefixo duplicado models/.
const geminiModel = String(process.env.GEMINI_MODEL || 'gemini-3.5-flash-lite')
  .trim()
  .replace(/^models\//i, '')
  .replace(/^\/+|\/+$/g, '');

app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json({ limit: '2mb' }));
app.use('/api/', rateLimit({
  windowMs: 60 * 1000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
}));

const MIME_BY_EXTENSION = {
  '.pdf': 'application/pdf',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: maxUploadMb * 1024 * 1024, files: 1 },
  fileFilter: (_req, file, cb) => {
    const extension = path.extname(String(file.originalname || '')).toLowerCase();
    const mime = String(file.mimetype || '').toLowerCase();
    const normalizedMime = MIME_BY_EXTENSION[extension] || mime;
    const allowed = Object.values(MIME_BY_EXTENSION).includes(normalizedMime);
    if (allowed) file.mimetype = normalizedMime;
    cb(allowed ? null : new Error('Formato não suportado. Envie PDF, JPG, PNG ou WEBP.'), allowed);
  },
});

const FLASHCARDS_SCHEMA = {
  type: 'object',
  properties: {
    title: { type: 'string' },
    subject: { type: 'string' },
    summary: { type: 'string' },
    cards: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          question: { type: 'string' },
          answer: { type: 'string' },
          topic: { type: 'string' },
        },
        required: ['question', 'answer', 'topic'],
      },
    },
    notes: { type: 'array', items: { type: 'string' } },
  },
  required: ['title', 'subject', 'summary', 'cards', 'notes'],
};

function requireAI(_req, res, next) {
  if (!geminiApiKey) {
    return res.status(503).json({ error: 'Backend sem GEMINI_API_KEY. Configure o arquivo backend/.env.' });
  }
  if (!/^[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(geminiModel)) {
    return res.status(503).json({ error: 'GEMINI_MODEL inválido. Use apenas o ID, por exemplo gemini-3.5-flash-lite, sem espaços ou aspas.' });
  }
  next();
}

function extractJson(text) {
  const cleaned = String(text || '').trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/, '');
  try {
    return JSON.parse(cleaned);
  } catch (_) {
    const first = cleaned.indexOf('{');
    const last = cleaned.lastIndexOf('}');
    if (first >= 0 && last > first) return JSON.parse(cleaned.slice(first, last + 1));
    throw new Error('A IA não retornou um JSON válido. Tente novamente.');
  }
}

function createGeminiInput(file, typedText, subject) {
  const text = String(typedText || '').trim();
  const subjectLine = String(subject || '').trim();
  const prompt = [
    'Você é um professor especialista em transformar materiais didáticos em flashcards corretos e úteis.',
    'Use somente as informações do material fornecido; não invente fatos nem complemente com conhecimento externo.',
    'Leia o documento inteiro, incluindo texto, tabelas, gráficos, imagens, diagramas e legendas.',
    'Gere exatamente 8 flashcards em português brasileiro, com perguntas objetivas e respostas autocontidas e didáticas.',
    'Distribua os 8 cards entre os conceitos mais importantes, evite perguntas repetidas e mantenha uma dificuldade pedagogicamente equilibrada.',
    'Não classifique os cards por nível de dificuldade.',
    `Matéria informada pelo estudante: ${subjectLine || 'identifique a matéria pelo material'}.`,
    text ? `Texto complementar informado pelo estudante:\n${text.slice(0, 90000)}` : '',
    'Retorne somente um objeto JSON no formato exigido pelo schema.',
  ].filter(Boolean).join('\n\n');

  const input = [{ type: 'text', text: prompt }];
  if (file) {
    if (!file.buffer || file.buffer.length === 0) {
      throw new Error('O arquivo enviado está vazio. Selecione o PDF ou a imagem novamente.');
    }
    const extension = path.extname(String(file.originalname || '')).toLowerCase();
    const mimeType = MIME_BY_EXTENSION[extension] || String(file.mimetype || '').toLowerCase();
    const encoded = file.buffer.toString('base64');
    if (mimeType === 'application/pdf') {
      // Interactions document input faz leitura nativa de PDFs, inclusive páginas escaneadas.
      input.push({ type: 'document', data: encoded, mime_type: 'application/pdf' });
    } else if (['image/jpeg', 'image/png', 'image/webp'].includes(mimeType)) {
      input.push({ type: 'image', data: encoded, mime_type: mimeType });
    } else {
      throw new Error('Formato não suportado. Envie PDF, JPG, PNG ou WEBP.');
    }
  } else if (text.length < 30) {
    throw new Error('Envie um arquivo ou informe pelo menos 30 caracteres de conteúdo.');
  }
  return input;
}

function getInteractionText(payload) {
  if (typeof payload.output_text === 'string' && payload.output_text.trim()) {
    return payload.output_text.trim();
  }

  const pieces = [];
  for (const step of Array.isArray(payload.steps) ? payload.steps : []) {
    if (step.type !== 'model_output') continue;
    for (const content of Array.isArray(step.content) ? step.content : []) {
      if (content.type === 'text' && typeof content.text === 'string') pieces.push(content.text);
    }
  }
  // Compatibilidade com respostas da API que ainda usam o formato outputs.
  for (const output of Array.isArray(payload.outputs) ? payload.outputs : []) {
    if (output.type === 'text' && typeof output.text === 'string') pieces.push(output.text);
  }
  return pieces.join('\n').trim();
}

async function askGemini(input) {
  const url = 'https://generativelanguage.googleapis.com/v1beta/interactions';
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-goog-api-key': geminiApiKey,
    },
    body: JSON.stringify({
      model: geminiModel,
      input,
      response_format: {
        type: 'text',
        mime_type: 'application/json',
        schema: FLASHCARDS_SCHEMA,
      },
      generation_config: { max_output_tokens: 8192 },
      store: false,
    }),
    signal: AbortSignal.timeout(180000),
  });

  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = payload?.error?.message || `Gemini API retornou HTTP ${response.status}.`;
    throw new Error(message);
  }

  const output = getInteractionText(payload);
  if (!output) {
    const status = payload.status ? ` (status: ${payload.status})` : '';
    throw new Error(`Gemini não retornou texto${status}. Tente novamente.`);
  }
  return extractJson(output);
}

app.get('/api/health', (_req, res) => res.json({
  ok: true,
  service: 'study-cards-ai',
  aiConfigured: Boolean(geminiApiKey),
  provider: 'gemini',
  api: 'interactions',
  model: geminiModel,
}));

app.post('/api/materials/flashcards', requireAI, upload.single('file'), async (req, res, next) => {
  try {
    const input = createGeminiInput(req.file, req.body.text, req.body.subject);
    const data = await askGemini(input);
    if (!Array.isArray(data.cards) || data.cards.length === 0) {
      throw new Error('A IA não encontrou conteúdo suficiente para gerar flashcards.');
    }

    const cards = data.cards.slice(0, 8).map((card) => ({
      question: String(card.question || '').trim(),
      answer: String(card.answer || '').trim(),
      topic: String(card.topic || '').trim(),
    })).filter((card) => card.question && card.answer);

    if (cards.length !== 8) {
      throw new Error('A IA não conseguiu gerar os 8 flashcards solicitados com o material enviado. Tente um material mais completo.');
    }

    res.json({
      title: String(data.title || 'Novo material de estudo'),
      subject: String(data.subject || req.body.subject || 'Matéria identificada pela IA'),
      summary: String(data.summary || ''),
      cards,
      notes: Array.isArray(data.notes) ? data.notes : [],
      sourceName: req.file?.originalname || 'Texto digitado',
      generatedAt: new Date().toISOString(),
    });
  } catch (error) {
    next(error);
  }
});

app.use((error, _req, res, _next) => {
  console.error(error);
  if (error instanceof multer.MulterError) {
    return res.status(413).json({ error: `Arquivo excede o limite de ${maxUploadMb} MB.` });
  }
  const status = error.statusCode && Number.isInteger(error.statusCode) ? error.statusCode : 400;
  res.status(status).json({ error: error.message || 'Erro ao processar solicitação.' });
});

app.listen(port, () => console.log(`Study Cards AI backend ativo em http://localhost:${port}`));
