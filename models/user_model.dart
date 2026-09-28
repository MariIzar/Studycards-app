class UserModel {
  final String id;
  final String name;
  final String email;
  final String occupation;
  final bool isProfileVisible;
  final bool notifyStudyReminder;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.occupation = 'Estudante',
    this.isProfileVisible = true,
    this.notifyStudyReminder = true,
  });

  // Facilita a conversão do banco de dados (SQLite/Firebase) para o App
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      occupation: map['occupation'] ?? 'Estudante',
      isProfileVisible: map['is_profile_visible'] == 1,
      notifyStudyReminder: map['notify_study_reminder'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'occupation': occupation,
      'is_profile_visible': isProfileVisible ? 1 : 0,
      'notify_study_reminder': notifyStudyReminder ? 1 : 0,
    };
  }
}
