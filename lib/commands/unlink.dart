import 'dart:io';
import 'package:path/path.dart' as p;
import '../ui/render.dart' as render;

void runUnlink() {
  print(render.header('CLAUDART UNLINK'));

  final cwd = Directory.current.path;
  var removed = 0;

  for (final name in ['.claude', 'CLAUDE.md']) {
    final path = p.join(cwd, name);
    final type = FileSystemEntity.typeSync(path, followLinks: false);

    if (type == FileSystemEntityType.link) {
      Link(path).deleteSync();
      print('✓ Removed symlink: $name');
      removed++;
    } else if (type != FileSystemEntityType.notFound) {
      print('⚠  $name exists but is not a symlink — skipped (not safe to delete)');
    }
  }

  if (removed == 0) {
    print('\nNo claudart symlinks found in ${Directory.current.path}');
  } else {
    print('\nProject directory is clean.\n');
  }
}
