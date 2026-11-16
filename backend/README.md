# Study Cards — backend de IA

Backend Node.js/Express que mantém a chave da Gemini fora do aplicativo Flutter. O SQLite continua no aparelho; o backend recebe o arquivo apenas para processá-lo e não grava o upload em disco.

## Requisitos

- Node.js 20 ou superior
- Uma chave da Gemini Developer API criada no Google AI Studio

## Configuração e execução no Windows

1. Copie `backend/.env.example` e crie uma cópia chamada `.env` na mesma pasta `backend`.
2. Abra `backend/.env` e preencha `GEMINI_API_KEY` com sua chave real. Mantenha `GEMINI_MODEL=gemini-3.5-flash-lite` sem aspas e sem o prefixo `models/`.
3. No terminal, dentro da pasta `backend`, execute:

```bash
npm install
npm run dev
```

O serviço inicia em `http://localhost:3000`. Verifique `GET /api/health`. O campo `api` deve indicar `interactions`, e `aiConfigured` deve ser `true`.

## Funcionalidade de IA disponível

- `POST /api/materials/flashcards` — multipart/form-data com `file` (PDF/JPG/PNG/WEBP), `text` opcional e `subject` opcional. O backend sempre solicita exatamente 8 flashcards; não há seletor de quantidade nem de dificuldade.
- `GET /api/health` — status do serviço e modelo configurado, sem expor a chave.

Não há geração, realização ou correção de provas, nem análise de desempenho com IA.

## API Gemini e leitura de arquivos

O backend usa a **Interactions API** da Gemini com o modelo `gemini-3.5-flash-lite`. PDFs são enviados como conteúdo `document` para leitura nativa do modelo, incluindo texto, tabelas, diagramas e páginas escaneadas. Imagens JPG, PNG e WEBP são enviadas como conteúdo visual. O limite padrão de upload é 20 MB (`MAX_UPLOAD_MB`).

## Configurar o endereço no Flutter

O endereço padrão é `http://10.0.2.2:3000`, para o emulador Android acessar o computador host.

- Android Emulator: mantenha `http://10.0.2.2:3000`.
- iOS Simulator no mesmo Mac onde o backend está rodando: use `http://127.0.0.1:3000`.
- Aparelho físico: use o IP local do computador que está executando o backend, na mesma rede Wi-Fi.

É possível substituir o endereço ao executar o aplicativo:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000
```

Para produção, publique o backend em HTTPS e passe a URL HTTPS por `API_BASE_URL`.

## Segurança

- Nunca coloque `GEMINI_API_KEY` no Flutter, em repositório Git ou em `.env.example` com valor real.
- O arquivo `backend/.env` é ignorado pelo Git.
- O backend não armazena PDFs ou imagens enviados.
- A API do Gemini recebe o conteúdo do material para gerar os flashcards. A chamada usa `store: false` na Interactions API.
- Configure `CORS_ORIGIN` para o ambiente de produção e adicione autenticação/limites por usuário antes de disponibilizar publicamente.

## Links oficiais

- Criar/consultar chave: https://aistudio.google.com/app/apikey
- Interactions API: https://ai.google.dev/gemini-api/docs/interactions-overview
- Entrada de PDFs: https://ai.google.dev/gemini-api/docs/file-input-methods
- Preços e limites: https://ai.google.dev/gemini-api/docs/pricing
