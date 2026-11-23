
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const rateLimit = require('express-rate-limit');
const path = require('node:path');
const pdfParse = require('pdf-parse');
const { initializeApp, cert, applicationDefault, getApps } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

const app = express();
const PORT = Number(process.env.PORT || 3000);
const MAX_UPLOAD_MB = Number(process.env.MAX_UPLOAD_MB || 12);
const API_KEY = String(process.env.GEMINI_API_KEY || '').trim();
const MODEL = String(process.env.GEMINI_MODEL || 'gemini-3.5-flash-lite').trim().replace(/^models\//, '');
const TIMEOUT_MS = 180000;
const MAX_ATTEMPTS = 3;

function initializeFirebaseAdmin() {
  if (getApps().length) return;
  const serviceAccountJson = String(process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '').trim();
  const projectId = String(process.env.FIREBASE_PROJECT_ID || '').trim();
  if (serviceAccountJson) {
    let serviceAccount;
    try {
      serviceAccount = JSON.parse(serviceAccountJson);
    } catch (_) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON não contém JSON válido.');
    }
    if (!serviceAccount.project_id || !serviceAccount.private_key || !serviceAccount.client_email) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON está incompleto.');
    }
    initializeApp({
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
  } else {
    initializeApp({
      credential: applicationDefault(),
      ...(projectId ? { projectId } : {}),
    });
  }
}
initializeFirebaseAdmin();

async function requireFirebaseAuth(req, res, next) {
  const authorization = req.get('authorization') || '';
  const match = /^Bearer\s+([^\s]+)$/i.exec(authorization);
  if (!match) return res.status(401).json({ error: 'Faça login para utilizar a IA.' });
  try {
    const decoded = await getAuth().verifyIdToken(match[1], true);
    req.firebaseUser = { uid: decoded.uid };
    return next();
  } catch (error) {
    console.warn('[Auth] Falha ao validar token Firebase:', {
      code: error.code || 'sem código',
      message: error.message || 'sem mensagem',
      projectId: getAuth().app.options.projectId || 'não definido',
    });
    return res.status(401).json({
      error: 'Sessão inválida ou expirada. Faça login novamente.',
    });
  }
}

const aiRateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: req => req.firebaseUser.uid,
  handler: (_req, res) => res.status(429).json({
    error: 'Limite de 5 gerações por hora atingido. Tente mais tarde.',
  }),
});

app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use('/api/', rateLimit({
  windowMs: 60000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
}));

const MIME_TYPES = {
  '.pdf': 'application/pdf',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: MAX_UPLOAD_MB * 1024 * 1024,
    files: 1,
  },
  fileFilter: (_req, file, callback) => {
    const extension = path.extname(file.originalname || '').toLowerCase();
    if (!MIME_TYPES[extension]) {
      return callback(new Error('Formato inválido. Envie PDF, JPG, PNG ou WEBP.'));
    }
    callback(null, true);
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
      minItems: 8,
      maxItems: 8,
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

async function readEntirePdf(file) {
  console.log('[PDF] Iniciando leitura completa...');
  const pdf = await pdfParse(new Uint8Array(file.buffer));
  const text = String(pdf.text || '')
    .replace(/\r/g, '\n')
    .replace(/[ \t]+/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
  console.log(`[PDF] Total de páginas: ${pdf.numpages}`);
  console.log(`[PDF] Total de caracteres: ${text.length}`);
  console.log('[PDF] Nenhum corte de texto aplicado.');
  return { text, pages: pdf.numpages };
}

async function prepareInput(file, typedText, subject) {
  const input = [];
  const prompt = [
    'Você é um professor especializado em estudos.',
    'Analise TODO o material fornecido.',
    'Considere os conceitos do começo, meio e fim.',
    'Identifique os 8 conceitos mais importantes.',
    'Crie exatamente 8 flashcards em português.',
    'Cada flashcard deve conter pergunta, resposta e tópico.',
    'As perguntas devem ser claras.',
    'As respostas devem ser corretas e didáticas.',
    'Evite perguntas repetidas.',
    'Não invente informações.',
    `Matéria: ${subject || 'identifique pelo conteúdo'}.`,
    'Responda somente com JSON no formato solicitado.',
  ].join('\n');
  input.push({ type: 'text', text: prompt });

  if (file) {
    const extension = path.extname(file.originalname || '').toLowerCase();
    if (extension === '.pdf') {
      const pdf = await readEntirePdf(file);
      if (pdf.text.length >= 100) {
        input.push({
          type: 'text',
          text: `DOCUMENTO COMPLETO (${pdf.pages} páginas):\n\n${pdf.text}`,
        });
        console.log(`[Gemini] Enviando texto integral: ${pdf.text.length} caracteres.`);
      } else {
        console.log('[PDF] Texto insuficiente. Enviando PDF original.');
        input.push({
          type: 'document',
          data: file.buffer.toString('base64'),
          mime_type: 'application/pdf',
        });
      }
    } else {
      input.push({
        type: 'image',
        data: file.buffer.toString('base64'),
        mime_type: MIME_TYPES[extension],
      });
    }
  }

  const extraText = String(typedText || '').trim();
  if (extraText) {
    input.push({
      type: 'text',
      text: `Informações complementares:\n${extraText}`,
    });
  }
  if (!file && extraText.length < 30) {
    throw new Error('Envie um PDF, uma imagem ou pelo menos 30 caracteres de texto.');
  }
  return input;
}

function getResponseText(data) {
  const parts = data.candidates?.[0]?.content?.parts || [];
  return parts
    .filter(part => typeof part.text === 'string')
    .map(part => part.text)
    .join('\n')
    .trim();
}

function parseJson(text) {
  const cleaned = String(text)
    .trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/, '');
  try {
    return JSON.parse(cleaned);
  } catch (_) {
    const start = cleaned.indexOf('{');
    const end = cleaned.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return JSON.parse(cleaned.slice(start, end + 1));
    }
    throw new Error('A IA retornou uma resposta em formato inválido.');
  }
}

function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function retryDelayMs(attempt, retryAfterHeader) {
  if (retryAfterHeader != null && retryAfterHeader.trim() !== '') {
    const seconds = Number(retryAfterHeader);
    if (Number.isFinite(seconds) && seconds >= 0) {
      return Math.min(seconds * 1000, 30000);
    }
    const dateMs = Date.parse(retryAfterHeader);
    if (Number.isFinite(dateMs)) {
      return Math.min(Math.max(dateMs - Date.now(), 0), 30000);
    }
  }
  return Math.min(3000 * (2 ** (attempt - 1)), 12000);
}

function isTemporaryError(status, message) {
  return [429, 500, 502, 503, 504].includes(status) ||
    /high demand|overloaded|try again later/i.test(message);
}

async function generateWithGemini(input) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(MODEL)}:generateContent`;

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    console.log(`[Gemini] Tentativa ${attempt}/${MAX_ATTEMPTS}: ${MODEL}`);
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': API_KEY,
        },
        body: JSON.stringify({
          contents: [{
            role: 'user',
            parts: input.map(item => {
              if (item.type === 'text') return { text: item.text };
              if (item.type === 'image' || item.type === 'document') {
                return {
                  inlineData: {
                    mimeType: item.mime_type,
                    data: item.data,
                  },
                };
              }
              throw new Error(`Tipo de conteúdo não suportado: ${item.type}`);
            }),
          }],
          generationConfig: {
            responseMimeType: 'application/json',
            responseSchema: FLASHCARDS_SCHEMA,
            maxOutputTokens: 8192,
          },
        }),
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        const message = data.error?.message || `Erro HTTP ${response.status}`;
        console.warn('[Gemini] Falha na geração:', {
          status: response.status,
          model: MODEL,
          attempt,
          message,
          reason: data.error?.status || 'não informado',
        });

        if (isTemporaryError(response.status, message) && attempt < MAX_ATTEMPTS) {
          const delay = retryDelayMs(attempt, response.headers.get('retry-after'));
          console.warn(`[Gemini] Nova tentativa em ${delay} ms.`);
          await wait(delay);
          continue;
        }

        const error = new Error(message);
        error.statusCode = response.status;
        throw error;
      }

      const responseText = getResponseText(data);
      if (!responseText) {
        throw new Error('A Gemini retornou uma resposta vazia.');
      }
      console.log('[Gemini] Resposta recebida.');
      return parseJson(responseText);
    } catch (error) {
      const connectionError = ['TimeoutError', 'AbortError', 'TypeError'].includes(error.name);
      if (connectionError && attempt < MAX_ATTEMPTS) {
        console.warn('[Gemini] Falha de conexão:', error.message);
        await wait(retryDelayMs(attempt, null));
        continue;
      }
      if (connectionError) error.statusCode = 504;
      throw error;
    }
  }
}

app.get('/api/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'study-cards-ai',
    aiConfigured: Boolean(API_KEY),
    provider: 'gemini',
    model: MODEL,
    maxUploadMb: MAX_UPLOAD_MB,
    pdfMode: 'full-text',
    authRequired: true,
  });
});

app.post(
  '/api/materials/flashcards',
  requireFirebaseAuth,
  aiRateLimiter,
  upload.single('file'),
  async (req, res, next) => {
    try {
      if (!API_KEY) {
        return res.status(503).json({
          error: 'Configure GEMINI_API_KEY no arquivo .env.',
        });
      }

      console.log('[StudyCards] Nova solicitação de flashcards.');
      if (req.file) {
        console.log(`[StudyCards] Arquivo: ${req.file.originalname}`);
        console.log(`[StudyCards] Tamanho: ${(req.file.size / 1048576).toFixed(2)} MB`);
      }

      const input = await prepareInput(req.file, req.body.text, req.body.subject);
      const result = await generateWithGemini(input);

      if (!Array.isArray(result.cards)) {
        throw new Error('A IA não retornou uma lista de flashcards.');
      }

      const cards = result.cards
        .slice(0, 8)
        .map(card => ({
          question: String(card.question || '').trim(),
          answer: String(card.answer || '').trim(),
          topic: String(card.topic || '').trim(),
        }))
        .filter(card => card.question && card.answer);

      if (cards.length !== 8) {
        throw new Error(`A IA gerou ${cards.length} flashcards válidos em vez de 8.`);
      }

      console.log('[StudyCards] 8 flashcards gerados com sucesso!');

      return res.json({
        title: String(result.title || 'Novo material de estudo'),
        subject: String(result.subject || req.body.subject || 'Matéria'),
        summary: String(result.summary || ''),
        cards,
        notes: Array.isArray(result.notes) ? result.notes : [],
        sourceName: req.file?.originalname || 'Texto digitado',
        generatedAt: new Date().toISOString(),
      });
    } catch (error) {
      next(error);
    }
  }
);

app.use((error, _req, res, _next) => {
  console.error('[StudyCards] Erro:', error.message);

  if (error instanceof multer.MulterError) {
    return res.status(413).json({
      error: `Arquivo acima do limite de ${MAX_UPLOAD_MB} MB.`,
    });
  }

  const message = String(error.message || '');

  if (/high demand|overloaded|try again later/i.test(message)) {
    return res.status(503).json({
      error: 'A Gemini está sobrecarregada no momento. Tente novamente mais tarde.',
    });
  }

  if (error.statusCode === 504 || error.name === 'TimeoutError') {
    return res.status(504).json({
      error: 'A Gemini demorou muito para responder.',
    });
  }

  const status =
    Number.isInteger(error.statusCode) &&
    error.statusCode >= 400 &&
    error.statusCode <= 599
      ? error.statusCode
      : 400;

  return res.status(status).json({
    error: status >= 500
      ? 'Falha temporária ao gerar flashcards.'
      : (message || 'Erro ao gerar flashcards.'),
  });
});

app.listen(PORT, () => {
  console.log(`Study Cards AI backend ativo em http://localhost:${PORT}`);
  console.log(`[Gemini] Modelo: ${MODEL}`);
  console.log(`[Gemini] Chave configurada: ${API_KEY ? 'SIM' : 'NÃO'}`);
  console.log(`[StudyCards] Limite de upload: ${MAX_UPLOAD_MB} MB`);
  console.log('[PDF] Modo: leitura integral, sem truncamento.');
  console.log('[Auth] Firebase Admin inicializado.');
});
