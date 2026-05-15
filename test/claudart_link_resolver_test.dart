// claudart_link_resolver_test.dart — claudart's LinkResolver implementation
// routes zedup state at the linked workspace; falls back to profile dir
// when no link exists for the cwd.

import 'dart:io' as io;

import 'package:claudart/claudart_link_resolver.dart';
import 'package:claudart/registry.dart';
import 'package:test/test.dart';
import 'package:zedup/zedup.dart';

void main() {
  late io.Directory tempProjectDir;
  late io.Directory tempWorkspaceDir;

  setUp(() {
    tempProjectDir = io.Directory.systemTemp.createTempSync('claudart_proj_');
    tempWorkspaceDir = io.Directory.systemTemp.createTempSync('claudart_ws_');
  });

  tearDown(() {
    tempProjectDir.deleteSync(recursive: true);
    tempWorkspaceDir.deleteSync(recursive: true);
  });

  Registry _registryWith(String projectRoot, String workspacePath) {
    return Registry.empty().add(RegistryEntry(
      name: 'test-project',
      projectRoot: projectRoot,
      workspacePath: workspacePath,
      createdAt: '2026-05-15',
      lastSession: '2026-05-15',
    ));
  }

  test('resolves to <workspace>/zedup when cwd matches a registered project root', () {
    final registry = _registryWith(tempProjectDir.path, tempWorkspaceDir.path);
    final resolver = ClaudartLinkResolver(
      registry: registry,
      cwdOverride: tempProjectDir.path,
    );
    final dir = resolver.workspaceDir(ZedProfile.liitx);
    expect(dir, equals('${tempWorkspaceDir.path}/zedup'));
    expect(io.Directory(dir).existsSync(), isTrue);
  });

  test('creates the workspace zedup subdir if missing', () {
    final registry = _registryWith(tempProjectDir.path, tempWorkspaceDir.path);
    final resolver = ClaudartLinkResolver(
      registry: registry,
      cwdOverride: tempProjectDir.path,
    );
    expect(io.Directory('${tempWorkspaceDir.path}/zedup').existsSync(), isFalse);
    resolver.workspaceDir(ZedProfile.liitx);
    expect(io.Directory('${tempWorkspaceDir.path}/zedup').existsSync(), isTrue);
  });

  test('resolves for cwd inside a subdirectory of the project root', () {
    final subdir = io.Directory('${tempProjectDir.path}/some/nested/path');
    subdir.createSync(recursive: true);
    final registry = _registryWith(tempProjectDir.path, tempWorkspaceDir.path);
    final resolver = ClaudartLinkResolver(
      registry: registry,
      cwdOverride: subdir.path,
    );
    final dir = resolver.workspaceDir(ZedProfile.liitx);
    expect(dir, equals('${tempWorkspaceDir.path}/zedup'));
  });

  test('falls back to profile dir when cwd has no registered project', () {
    final registry = Registry.empty();
    final resolver = ClaudartLinkResolver(
      registry: registry,
      cwdOverride: tempProjectDir.path,
    );
    final dir = resolver.workspaceDir(ZedProfile.liitx);
    final home = io.Platform.environment['HOME'] ?? '';
    expect(dir, equals('$home/.config/liitx/zedup'));
  });

  test('falls back to profile dir when cwd does not match any registry entry', () {
    final unrelatedDir = io.Directory.systemTemp.createTempSync('unrelated_');
    addTearDown(() => unrelatedDir.deleteSync(recursive: true));
    final registry = _registryWith(tempProjectDir.path, tempWorkspaceDir.path);
    final resolver = ClaudartLinkResolver(
      registry: registry,
      cwdOverride: unrelatedDir.path,
    );
    final dir = resolver.workspaceDir(ZedProfile.liitx);
    final home = io.Platform.environment['HOME'] ?? '';
    expect(dir, equals('$home/.config/liitx/zedup'));
  });
}
