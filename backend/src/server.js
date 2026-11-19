
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const multer = require('multer');
const rateLimit = require('express-rate-limit');
const path = require('node:path');
const pdfParse = require('pdf-parse');

const app = express();

const PORT = Number(process.env.PORT || 3000);
const MAX_UPLOAD_MB = Number(process.env.MAX_UPLOAD_MB || 12);
const API_KEY = String(process.env.GEMINI_API_KEY || '').trim();
const MODEL = String(
  process.env.GEMINI_MODEL || 'gemini-3.5-flash-lite'
).trim().replace(/^models\//, '');

const TIMEOUT_MS = 180000;
const MAX_ATTEMPTS = 2;

app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.use('/api/', rateLimit({
  windowMs: 60000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
}));

// ========================================
// UPLOAD
// ========================================

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
    const extension = path.extname(
      file.originalname || ''
    ).toLowerCase();

    if (!MIME_TYPES[extension]) {
      return callback(new Error(
        'Formato inválido. Envie PDF, JPG, PNG ou WEBP.'
      ));
    }

    callback(null, true);
  },
});

// ========================================
// FORMATO DA RESPOSTA
// ========================================

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
    notes: {
      type: 'array',
      items: { type: 'string' },
    },
  },
  required: [
    'title',
    'subject',
    'summary',
    'cards',
    'notes',
  ],
};

// ========================================
// LER TODO O PDF
// ========================================

async function readEntirePdf(file) {
  console.log('[PDF] Iniciando leitura completa...');

  // Uint8Array puro: o pdf-parse falha com "bad XRef entry" em Buffer (Node novo)
  const pdf = await pdfParse(new Uint8Array(file.buffer));

  const text = String(pdf.text || '')
    .replace(/\r/g, '\n')
    .replace(/[ \t]+/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();

  console.log(`[PDF] Total de páginas: ${pdf.numpages}`);
  console.log(`[PDF] Total de caracteres: ${text.length}`);
  console.log('[PDF] Nenhum corte de texto aplicado.');

  return {
    text,
    pages: pdf.numpages,
  };
}

// ========================================
// PREPARAR MATERIAL PARA A IA
// ========================================

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

  input.push({
    type: 'text',
    text: prompt,
  });

  if (file) {
    const extension = path.extname(
      file.originalname || ''
    ).toLowerCase();

    if (extension === '.pdf') {
      const pdf = await readEntirePdf(file);

      if (pdf.text.length >= 100) {
        // Envia todo o texto extraído.
        // Não existe slice ou limite de caracteres aqui.
        input.push({
          type: 'text',
          text:
            `DOCUMENTO COMPLETO (${pdf.pages} páginas):\n\n` +
            pdf.text,
        });

        console.log(
          `[Gemini] Enviando texto integral: ${pdf.text.length} caracteres.`
        );
      } else {
        // PDF digitalizado: não há texto suficiente
        // para extrair com pdf-parse.
        console.log(
          '[PDF] Texto insuficiente. Enviando PDF original.'
        );

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
    throw new Error(
      'Envie um PDF, uma imagem ou pelo menos 30 caracteres de texto.'
    );
  }

  return input;
}

// ========================================
// EXTRAIR RESPOSTA DA GEMINI
// ========================================

function getResponseText(data) {
  if (
    typeof data.output_text === 'string' &&
    data.output_text.trim()
  ) {
    return data.output_text.trim();
  }

  const parts = [];

  for (const step of data.steps || []) {
    if (step.type !== 'model_output') continue;

    for (const item of step.content || []) {
      if (typeof item.text === 'string') {
        parts.push(item.text);
      }
    }
  }

  for (const output of data.outputs || []) {
    if (typeof output.text === 'string') {
      parts.push(output.text);
    }
  }

  return parts.join('\n').trim();
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

    throw new Error(
      'A IA retornou uma resposta em formato inválido.'
    );
  }
}

// ========================================
// CHAMADA À GEMINI
// ========================================

function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function isTemporaryError(status, message) {
  return [429, 500, 502, 503, 504].includes(status) ||
    /high demand|overloaded|try again later/i.test(message);
}

async function generateWithGemini(input) {
  const url =
    'https://generativelanguage.googleapis.com/v1beta/interactions';

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    console.log(
      `[Gemini] Tentativa ${attempt}/${MAX_ATTEMPTS}: ${MODEL}`
    );

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': API_KEY,
        },
        body: JSON.stringify({
          model: MODEL,
          input,
          response_format: {
            type: 'text',
            mime_type: 'application/json',
            schema: FLASHCARDS_SCHEMA,
          },
          generation_config: {
            max_output_tokens: 8192,
          },
          store: false,
        }),
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        const message = data.error?.message ||
          `Erro HTTP ${response.status}`;

        console.warn(
          `[Gemini] HTTP ${response.status}: ${message}`
        );

        if (
          isTemporaryError(response.status, message) &&
          attempt < MAX_ATTEMPTS
        ) {
          await wait(5000);
          continue;
        }

        const error = new Error(message);
        error.statusCode = response.status;
        throw error;
      }

      const responseText = getResponseText(data);

      if (!responseText) {
        throw new Error(
          'A Gemini retornou uma resposta vazia.'
        );
      }

      console.log('[Gemini] Resposta recebida.');

      return parseJson(responseText);
    } catch (error) {
      const connectionError = [
        'TimeoutError',
        'AbortError',
        'TypeError',
      ].includes(error.name);

      if (connectionError && attempt < MAX_ATTEMPTS) {
        console.warn(
          '[Gemini] Falha de conexão:', error.message
        );

        await wait(5000);
        continue;
      }

      if (connectionError) {
        error.statusCode = 504;
      }

      throw error;
    }
  }
}

// ========================================
// VERIFICAR SERVIDOR
// ========================================

app.get('/api/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'study-cards-ai',
    aiConfigured: Boolean(API_KEY),
    provider: 'gemini',
    model: MODEL,
    maxUploadMb: MAX_UPLOAD_MB,
    pdfMode: 'full-text',
  });
});

// ========================================
// GERAR OS 8 FLASHCARDS
// ========================================

app.post(
  '/api/materials/flashcards',
  upload.single('file'),
  async (req, res, next) => {
    try {
      if (!API_KEY) {
        return res.status(503).json({
          error: 'Configure GEMINI_API_KEY no arquivo .env.',
        });
      }

      console.log(
        '[StudyCards] Nova solicitação de flashcards.'
      );

      if (req.file) {
        console.log(
          `[StudyCards] Arquivo: ${req.file.originalname}`
        );

        console.log(
          `[StudyCards] Tamanho: ${(req.file.size / 1048576).toFixed(2)} MB`
        );
      }

      const input = await prepareInput(
        req.file,
        req.body.text,
        req.body.subject
      );

      const result = await generateWithGemini(input);

      if (!Array.isArray(result.cards)) {
        throw new Error(
          'A IA não retornou uma lista de flashcards.'
        );
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
        throw new Error(
          `A IA gerou ${cards.length} flashcards válidos em vez de 8.`
        );
      }

      console.log(
        '[StudyCards] 8 flashcards gerados com sucesso!'
      );

      return res.json({
        title: String(
          result.title || 'Novo material de estudo'
        ),
        subject: String(
          result.subject ||
          req.body.subject ||
          'Matéria'
        ),
        summary: String(result.summary || ''),
        cards,
        notes: Array.isArray(result.notes)
          ? result.notes
          : [],
        sourceName: req.file?.originalname ||
          'Texto digitado',
        generatedAt: new Date().toISOString(),
      });
    } catch (error) {
      next(error);
    }
  }
);

// ========================================
// TRATAMENTO DE ERROS
// ========================================

app.use((error, _req, res, _next) => {
  console.error('[StudyCards] Erro:', error.message);

  if (error instanceof multer.MulterError) {
    return res.status(413).json({
      error:
        `Arquivo acima do limite de ${MAX_UPLOAD_MB} MB.`,
    });
  }

  const message = String(error.message || '');

  if (/high demand|overloaded|try again later/i.test(message)) {
    return res.status(503).json({
      error:
        'A Gemini está sobrecarregada no momento. Tente novamente mais tarde.',
    });
  }

  if (
    error.statusCode === 504 ||
    error.name === 'TimeoutError'
  ) {
    return res.status(504).json({
      error:
        'A Gemini demorou muito para responder.',
    });
  }

  const status =
    Number.isInteger(error.statusCode) &&
    error.statusCode >= 400 &&
    error.statusCode <= 599
      ? error.statusCode
      : 400;

  return res.status(status).json({
    error: message || 'Erro ao gerar flashcards.',
  });
});

// ========================================
// INICIAR BACKEND
// ========================================

app.listen(PORT, () => {
  console.log(
    `Study Cards AI backend ativo em http://localhost:${PORT}`
  );

  console.log(`[Gemini] Modelo: ${MODEL}`);
  console.log(
    `[Gemini] Chave configurada: ${API_KEY ? 'SIM' : 'NÃO'}`
  );
  console.log(
    `[StudyCards] Limite de upload: ${MAX_UPLOAD_MB} MB`
  );
  console.log(
    '[PDF] Modo: leitura integral, sem truncamento.'
  );
});
