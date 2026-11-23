<div align="center">

<img src="assets/images/studycards_logo.png" alt="Logo do StudyCards" width="180" />

# StudyCards

**Estude de forma mais prática com flashcards e inteligência artificial.**

Projeto acadêmico desenvolvido na disciplina **Projeto Integrado I**, da **PUC Minas**.

![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Autentica%C3%A7%C3%A3o%20e%20sincroniza%C3%A7%C3%A3o-FFCA28?logo=firebase&logoColor=black)
![Node.js](https://img.shields.io/badge/Node.js-Backend-339933?logo=nodedotjs&logoColor=white)
![Gemini](https://img.shields.io/badge/Google%20Gemini-IA-8E75B2)

</div>

## Sobre o projeto

O **StudyCards** é um aplicativo de apoio aos estudos que permite organizar conteúdos em decks e revisar conhecimentos por meio de flashcards. O projeto combina a criação manual de cartões com a geração assistida por inteligência artificial, buscando facilitar a transformação de materiais de estudo em perguntas e respostas.

O aplicativo é desenvolvido em **Flutter**, utiliza armazenamento local para os cartões e integra recursos de autenticação e sincronização com o **Firebase**. A geração por IA é realizada por um backend em **Node.js**, que se comunica com a API do **Google Gemini**.

## Funcionalidades

- **Criação manual de flashcards:** cadastro de perguntas e respostas, com seleção do deck em que serão salvas.
- **Geração de flashcards com IA:** geração de oito cartões a partir de materiais enviados ao backend.
- **Importação de materiais:** envio de PDFs e imagens para processamento pela IA.
- **Organização por decks:** agrupamento dos cartões por tema ou matéria.
- **Estudo e revisão:** acesso aos flashcards armazenados no aplicativo.
- **Armazenamento local:** persistência dos dados do aplicativo em SQLite.
- **Autenticação e sincronização:** integração com serviços Firebase.
- **Personalização:** suporte a temas e idiomas no aplicativo.

> **Estado atual:** a geração com IA já foi testada em um iPhone físico. No ambiente de desenvolvimento, o backend ainda é executado localmente no computador. A hospedagem na nuvem está prevista como próxima etapa.

## Tecnologias utilizadas

| Camada | Tecnologias | Finalidade |
| --- | --- | --- |
| Aplicativo | Flutter e Dart | Interface e lógica do app |
| Armazenamento local | SQLite | Persistência de decks e flashcards |
| Serviços em nuvem | Firebase | Autenticação e sincronização |
| Backend | Node.js e Express | API de processamento de materiais |
| Inteligência artificial | Google Gemini | Geração de perguntas e respostas |
| Processamento de arquivos | Multer e pdf-parse | Recebimento de arquivos e extração de texto de PDFs |

## Arquitetura simplificada

```text
                  +---------------------+
                  |  StudyCards Flutter |
                  |  Interface e estudo |
                  +----------+----------+
                             |
              +--------------+--------------+
              |                             |
     +--------v---------+         +---------v----------+
     | SQLite / Firebase|         | Backend Node.js    |
     | Dados e sync     |         | API REST           |
     +------------------+         +---------+----------+
                                            |
                                  +---------v----------+
                                  | Google Gemini API  |
                                  | Geração de cards   |
                                  +--------------------+
```

## Estrutura do repositório

```text
StudyCards/
├── android/                 # Projeto Android
├── assets/                  # Imagens e recursos visuais
├── backend/
│   ├── src/
│   │   └── server.js        # API de geração de flashcards
│   ├── .env.example         # Exemplo de variáveis de ambiente
│   ├── package.json
│   └── README.md            # Detalhes do backend
├── ios/                     # Projeto iOS
├── lib/                     # Código Flutter
│   ├── banco_de_dados/      # Persistência local
│   ├── services/            # Serviços e integrações
│   └── main.dart            # Entrada do aplicativo
├── test/                    # Testes
├── pubspec.yaml             # Dependências Flutter
└── README.md
```

## Como executar o projeto

### Pré-requisitos

- Flutter SDK instalado e configurado;
- Ambiente de desenvolvimento compatível com a plataforma desejada (Android ou iOS);
- Node.js **20 ou superior**;
- Configuração Firebase compatível com o aplicativo;
- Chave de API Gemini para utilizar a geração por IA.

### 1. Obter o código

```bash
git clone https://github.com/MariIzar/Studycards-app.git
cd Studycards-app
```

### 2. Instalar dependências Flutter

```bash
flutter pub get
```

### 3. Configurar e iniciar o backend

```bash
cd backend
npm ci
cp .env.example .env
```

Abra o arquivo `backend/.env` e preencha a variável `GEMINI_API_KEY` com sua própria chave. Confira as demais opções no arquivo de exemplo e em [`backend/README.md`](backend/README.md).

```bash
npm start
```

Por padrão, o backend utiliza a porta `3000`. Para verificar a inicialização, acesse:

```text
http://localhost:3000/api/health
```

### 4. Executar o aplicativo

Em outro terminal, na raiz do projeto:

```bash
flutter run
```

**Atenção:** enquanto o backend estiver rodando localmente, o endereço utilizado pelo aplicativo para acessar a API deve apontar para o computador que executa o servidor. Em um dispositivo físico, `localhost` refere-se ao próprio dispositivo, não ao Mac. A configuração do endereço deve ser ajustada conforme o ambiente de desenvolvimento.

## Segurança e configuração

- **Nunca publique o arquivo `backend/.env` nem a chave real da API Gemini.**
- Utilize `backend/.env.example` somente como modelo, com valores fictícios.
- Mantenha credenciais sensíveis no servidor, não no código Flutter.
- Antes de disponibilizar a API publicamente, implemente controles de autenticação, autorização e limites de uso adequados.
- Configure as regras de segurança do Firebase conforme as permissões dos usuários.

## Próximas etapas

- [ ] Hospedar o backend em um serviço de nuvem com HTTPS.
- [ ] Atualizar o aplicativo para consumir a URL pública do backend.
- [ ] Reforçar a autenticação e a proteção dos endpoints da IA.
- [ ] Ampliar os testes e a documentação do projeto.
- [ ] Adicionar capturas de tela reais do aplicativo ao README.

## Equipe

Projeto desenvolvido por:

- **Mariana Almeida Izar**
- **Lucas Ricardo Souza**
- **Lucas Antonio Silveira Faria**
- **Luíza Ayumi Sommer Miyashiro**
- **Bárbara Urquisa Bambirra Freitas Bernardes**

**Instituição:** PUC Minas
**Disciplina:** Projeto Integrado I

---

<div align="center">
  <strong>StudyCards</strong> — tecnologia para apoiar a aprendizagem.
</div>
