// =============================================================================
// repeticao_espacada.dart — Algoritmo SM-2 (o mesmo que o Anki usa como base)
// -----------------------------------------------------------------------------
// Decide QUANDO cada card volta a aparecer, de acordo com a resposta do aluno:
//   - errou       -> o card volta amanhã e o progresso dele é zerado
//   - acertou     -> o intervalo cresce: 1 dia, 6 dias, depois x fator
//   - o "fator de facilidade" sobe com respostas fáceis e desce com difíceis
// Um card é considerado DOMINADO quando o intervalo chega a 21 dias ou mais.
// =============================================================================

/// Botões que aparecem na tela de revisão.
/// `qualidade` é a nota de 0 a 5 que o SM-2 usa internamente.
enum Avaliacao {
  errei(1, 'Errei'),
  dificil(3, 'Difícil'),
  facil(4, 'Fácil'),
  muitoFacil(5, 'Muito fácil');

  final int qualidade;
  final String rotulo;
  const Avaliacao(this.qualidade, this.rotulo);
}

class ResultadoRevisao {
  final double fatorFacilidade;
  final int intervaloDias;
  final int repeticoes;

  const ResultadoRevisao({
    required this.fatorFacilidade,
    required this.intervaloDias,
    required this.repeticoes,
  });

  bool get dominado => intervaloDias >= RepeticaoEspacada.diasParaDominar;

  DateTime proximaRevisao(DateTime agora) =>
      agora.add(Duration(days: intervaloDias));
}

class RepeticaoEspacada {
  static const double fatorMinimo = 1.3;
  static const int diasParaDominar = 21;

  static ResultadoRevisao calcula({
    required Avaliacao avaliacao,
    required double fatorFacilidade,
    required int intervaloDias,
    required int repeticoes,
  }) {
    final q = avaliacao.qualidade;

    // Novo fator de facilidade (fórmula original do SM-2)
    var novoFator = fatorFacilidade + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (novoFator < fatorMinimo) novoFator = fatorMinimo;

    // Errou: recomeça a sequência e revê amanhã
    if (q < 3) {
      return ResultadoRevisao(
        fatorFacilidade: novoFator,
        intervaloDias: 1,
        repeticoes: 0,
      );
    }

    // Acertou: aumenta o intervalo
    final novasRepeticoes = repeticoes + 1;
    int novoIntervalo;
    if (novasRepeticoes == 1) {
      novoIntervalo = 1;
    } else if (novasRepeticoes == 2) {
      novoIntervalo = 6;
    } else {
      novoIntervalo = (intervaloDias * novoFator).round();
    }

    return ResultadoRevisao(
      fatorFacilidade: double.parse(novoFator.toStringAsFixed(2)),
      intervaloDias: novoIntervalo,
      repeticoes: novasRepeticoes,
    );
  }
}
