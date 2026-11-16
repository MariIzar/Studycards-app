import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MaterialStorageService {
  static Future<String?> saveCopy(String? sourcePath) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    final source = File(sourcePath);
    if (!await source.exists()) return null;
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(path.join(documents.path, 'study_materials'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final extension = path.extension(sourcePath);
    final name = 'material_${DateTime.now().microsecondsSinceEpoch}$extension';
    final destination = path.join(folder.path, name);
    await source.copy(destination);
    return destination;
  }
}
