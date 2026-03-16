import 'dart:io';

/// Abstraction over file system operations.
/// Swap in [MemoryFileIO] in tests to avoid touching disk.
abstract class FileIO {
  String read(String path);
  void write(String path, String content);
  bool fileExists(String path);
  bool dirExists(String path);
  void createDir(String path);
  List<String> listFiles(String dirPath, {String? extension});
}

/// Production implementation backed by dart:io.
class RealFileIO implements FileIO {
  const RealFileIO();

  @override
  String read(String path) {
    final f = File(path);
    return f.existsSync() ? f.readAsStringSync() : '';
  }

  @override
  void write(String path, String content) {
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  @override
  bool fileExists(String path) => File(path).existsSync();

  @override
  bool dirExists(String path) => Directory(path).existsSync();

  @override
  void createDir(String path) => Directory(path).createSync(recursive: true);

  @override
  List<String> listFiles(String dirPath, {String? extension}) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .where((p) => extension == null || p.endsWith(extension))
        .toList();
  }
}
