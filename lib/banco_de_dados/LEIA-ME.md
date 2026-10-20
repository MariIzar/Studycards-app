# banco_de_dados — Persistência local do StudyCards

Feito no padrão das aulas LDDM08 (SharedPreferences), LDDM09 (SQLite) e LDDM10 (SQLite + ListView).

| Arquivo | O que faz |
|---|---|
| `sql_helper.dart` | Banco SQLite (`sqflite`): cria as tabelas e tem todo o CRUD em métodos `static` |
| `repeticao_espacada.dart` | Algoritmo SM-2: calcula quando cada card volta a aparecer |
| `preferencias_helper.dart` | SharedPreferences: usuário logado, onboarding, tema, idioma e horário do lembrete |
| `teste_banco.dart` | App separado só para testar o banco (não mexe no `main.dart`) |

## 1. Dependências (único ajuste fora desta pasta)

No terminal, na raiz do projeto:

```
flutter pub add sqflite path shared_preferences
```

(Esse comando só acrescenta três linhas em `dependencies:` no `pubspec.yaml`.)

## 2. Testar

```
flutter run -t lib/banco_de_dados/teste_banco.dart
```

Para testar:
1. Crie um deck pelo botão **+**.
2. Abra o deck e toque em ✨ para gerar 3 cards em lote (simulando a IA).
3. Toque no 🎓 para revisar e responda com Errei / Difícil / Fácil / Muito fácil.
4. Veja o intervalo e a próxima revisão mudarem na lista. Feche o app, abra de novo e confira que os dados continuam lá.
5. O botão ⟲ no topo zera o banco e as preferências.

Use um emulador ou celular Android/iOS. O `sqflite` não roda no Chrome (web).

## 3. Tabelas

As colunas têm os **mesmos nomes dos models que já estão no repositório**. Por isso, o `Map` devolvido pelo helper pode ir direto para o `fromMap()` de cada model.

- **users**: id, name, email (único), occupation, google_id, photo_url, is_profile_visible, notify_study_reminder, createdAt
- **decks**: id, user_id → users, title, description, createdAt
- **flashcards**: id, deck_id → decks, question, answer, is_mastered, ease_factor, interval_days, repetitions, next_review, last_review, createdAt
- **revisoes**: id, flashcard_id → flashcards, quality, reviewed_at

Apagar um deck apaga também os cards e as revisões dele (`ON DELETE CASCADE`).

Os booleanos são gravados como INTEGER (0/1) e as datas como TEXT no formato ISO 8601, porque o SQLite só tem TEXT, INTEGER e REAL.

## 4. Principais métodos (`SQLHelper`)

| Ação | Método |
|---|---|
| Login Google | `pegaOuCriaUsuario(nome, email, googleId:, fotoUrl:)` |
| Decks | `adicionaDeck`, `pegaDecks` (já traz `cards_count` e `pending_count`), `pegaUmDeck`, `atualizaDeck`, `apagaDeck` |
| Cards | `adicionaFlashcard`, `adicionaFlashcardsEmLote` (para os cards da IA), `pegaFlashcardsDoDeck`, `pegaFlashcardsPendentes`, `atualizaFlashcard`, `apagaFlashcard` |
| Revisão | `registraRevisao(cardId, Avaliacao.facil)`, que devolve em quantos dias o card volta |
| Progresso | `pegaEstatisticas()`, que devolve um Map no formato do `ProgressModel` |

Exemplo de uso numa tela:

```dart
import 'banco_de_dados/sql_helper.dart';

final decks = await SQLHelper.pegaDecks();
setState(() => _decks = decks);
```

## 5. Repetição espaçada (SM-2)

- **Errei**: o card volta amanhã e as repetições voltam para 0.
- **Acertos seguidos**: 1 dia → 6 dias → intervalo anterior × fator de facilidade.
- O fator começa em 2,5. Respostas fáceis aumentam o fator e respostas difíceis diminuem (o mínimo é 1,3).
- Um card é marcado como **dominado** (`is_mastered = 1`) quando o aluno acerta o card (Difícil/Fácil/Muito fácil contam como acerto; Errei tira o status). A repetição espaçada continua: o card volta a aparecer no intervalo calculado pelo SM-2.
