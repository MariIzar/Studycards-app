# Study Cards

Aplicativo Flutter de flashcards com armazenamento local SQLite e geração de flashcards por IA.

## Funcionalidades

- Criar e organizar decks.
- Criar, editar e revisar flashcards.
- Acompanhar as métricas originais de revisão e domínio dos cards.
- Gerar **8 flashcards fixos** a partir de texto, imagem ou PDF usando a Gemini.
- Salvar os cards gerados em um deck existente.

O projeto não inclui gerador de provas, tela de realização/correção de provas, métricas de provas ou análise de desempenho com IA.

## Iniciar o backend da IA

Consulte [`backend/README.md`](backend/README.md). Resumo no Windows:

1. Crie `backend/.env` copiando `backend/.env.example`.
2. Preencha `GEMINI_API_KEY` e mantenha `GEMINI_MODEL=gemini-3.5-flash-lite`.
3. Abra um terminal na pasta `backend` e execute:

```bash
npm install
npm run dev
```

No emulador Android, o Flutter usa `http://10.0.2.2:3000` por padrão. Para iOS Simulator, use `http://127.0.0.1:3000` quando o backend estiver no mesmo Mac. Para celular físico, use o IP do computador na rede local.

## Preparar o Flutter

Na pasta principal do projeto, execute:

```bash
flutter pub get
flutter run
```

O arquivo `.env` e a chave Gemini não fazem parte deste ZIP. Crie o `.env` localmente seguindo as instruções acima.
