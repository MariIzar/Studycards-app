import 'package:flutter/material.dart';
import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';
import 'banco_de_dados/ai_storage_helper.dart';
import 'services/material_storage_service.dart';

class GeneratedFlashcardsScreen extends StatefulWidget {
  const GeneratedFlashcardsScreen({super.key});
  @override
  State<GeneratedFlashcardsScreen> createState() => _GeneratedFlashcardsScreenState();
}

class _GeneratedFlashcardsScreenState extends State<GeneratedFlashcardsScreen> {
  static const purple = Color(0xFF6C4DFF);
  bool _saving = false;
  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _cards = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _data = Map<String, dynamic>.from(args);
        final raw = _data['cards'];
        if (raw is List) _cards = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
  }

  Future<void> _save() async {
    if (_cards.isEmpty) return;
    final deckId = await Navigator.pushNamed(context, '/select-deck');
    if (deckId is! int || !mounted) return;
    setState(() => _saving = true);
    try {
      await SQLHelper.adicionaFlashcardsEmLote(
        deckId,
        _cards.map<Map<String, String>>((c) => {
          'question': c['question']?.toString() ?? '',
          'answer': c['answer']?.toString() ?? '',
        }).toList(),
      );
      final localPath = await MaterialStorageService.saveCopy(_data['localFilePath']?.toString());
      await AIStorageHelper.salvaMaterial(
        titulo: (_data['title'] ?? 'Material de estudo').toString(),
        nomeArquivo: _data['sourceName']?.toString(),
        caminhoArquivo: localPath,
        tipo: (_data['sourceName']?.toString().toLowerCase().endsWith('.pdf') ?? false) ? 'pdf' : 'image_or_text',
        resumo: _data['summary']?.toString(), usuarioId: Sessao.usuarioId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flashcards salvos no deck com sucesso!')));
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F9FE),
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Flashcards gerados', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: Colors.black)),
    body: _cards.isEmpty ? const Center(child: Text('Nenhum flashcard válido foi recebido.')) : SafeArea(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18), child: Column(children: [
        Text((_data['title'] ?? 'Seu novo material').toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4), Text('${_cards.length} cards gerados • ${_data['subject'] ?? 'Matéria identificada pela IA'}', style: const TextStyle(color: Colors.black54)),
        if ((_data['summary'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(_data['summary'].toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))),
        Expanded(child: ListView.builder(itemCount: _cards.length, itemBuilder: (context, index) {
          final card = _cards[index];
          return Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PERGUNTA ${index + 1}', style: const TextStyle(color: purple, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 6), Text(card['question']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const Divider(height: 22), const Text('RESPOSTA', style: TextStyle(color: purple, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 5), Text(card['answer']?.toString() ?? ''),
            if ((card['topic'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Assunto: ${card['topic']}', style: const TextStyle(color: Colors.black45, fontSize: 12))),
          ])));
        })),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(onPressed: _saving ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))), icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_alt), label: Text(_saving ? 'Salvando...' : 'Salvar no deck'))),
        const SizedBox(height: 14),
      ]),
    )),
  );
}
