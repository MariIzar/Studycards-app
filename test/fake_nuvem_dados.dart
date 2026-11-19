// Nuvem de dados falsa (em memória), compartilhada entre "aparelhos" nos testes.
import 'dart:async';

import 'package:study_cards/services/nuvem_dados.dart';

class FakeNuvemDados implements NuvemDados {
  /// uid -> coleção -> id -> dados (inclui 'syncedAt' interno)
  final Map<String, Map<String, Map<String, Map<String, dynamic>>>> docs = {};
  final _mudou = StreamController<void>.broadcast();
  int _relogio = 0;
  bool semInternet = false;

  Map<String, Map<String, dynamic>> _c(String uid, String col) =>
      docs.putIfAbsent(uid, () => {}).putIfAbsent(col, () => {});

  /// Edita direto na nuvem, como se fosse outro aparelho.
  void edita(String uid, String col, String id, Map<String, dynamic> campos) {
    final d = _c(uid, col)[id]!;
    d.addAll(campos);
    d['syncedAt'] = ++_relogio;
    _mudou.add(null);
  }

  Iterable<String> ids(String uid, String col) => _c(uid, col).keys;
  Map<String, dynamic> doc(String uid, String col, String id) =>
      _c(uid, col)[id]!;

  @override
  Future<void> enviaLote(String uid, String colecao,
      Map<String, Map<String, dynamic>> novos) async {
    if (semInternet) throw Exception('sem internet');
    novos.forEach((id, d) {
      _c(uid, colecao)[id] = {...d, 'syncedAt': ++_relogio};
    });
    _mudou.add(null);
  }

  @override
  Future<List<DocNuvem>> busca(String uid, String colecao,
      {int? depoisDe}) async {
    if (semInternet) throw Exception('sem internet');
    final r = <DocNuvem>[];
    _c(uid, colecao).forEach((id, d) {
      final t = d['syncedAt'] as int;
      if (depoisDe == null || t > depoisDe) {
        r.add(DocNuvem(id, Map.of(d)..remove('syncedAt'), t));
      }
    });
    r.sort((a, b) => a.sincronizadoEm.compareTo(b.sincronizadoEm));
    return r;
  }

  @override
  Stream<void> ouveMudancas(String uid) => _mudou.stream;
}
