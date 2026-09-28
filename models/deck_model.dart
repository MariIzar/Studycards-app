class DeckModel {
  final String id;
  final String title;
  final int cardsCount;

  DeckModel({required this.id, required this.title, required this.cardsCount});

  factory DeckModel.fromMap(Map<String, dynamic> map) {
    return DeckModel(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      cardsCount: map['cards_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'cards_count': cardsCount};
  }
}
