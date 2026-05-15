// claudart_link_resolver.dart — claudart-aware LinkResolver for zedup
//
// Implements zedup's LinkResolver so zedup config + generated projection
// land at the claudart-linked workspace target. When no link exists for
// the current cwd, falls back to zedup's default ProfileDir behavior
// (solo zedup use).
//
// Design contract from the cross-package handoff synthesis:
//   - `claudart link` is the source of truth for which workspace is linked
//   - zedup reads/writes through this resolver
//   - Solo zedup with no claudart works because the fallback is the same
//     directory zedup's default resolver returns

import 'dart:io' as io;

import 'package:zedup/zedup.dart';

import 'registry.dart';

class ClaudartLinkResolver implements LinkResolver {
  ClaudartLinkResolver({Registry? registry, String? cwdOverride})
      : _registry = registry ?? Registry.load(),
        _cwdOverride = cwdOverride;

  final Registry _registry;
  final String? _cwdOverride;

  @override
  String workspaceDir(ZedProfile profile) {
    final cwd = _cwdOverride ?? io.Directory.current.path;
    final entry = _findEntryForCwd(cwd);
    if (entry != null) {
      final dir = '${entry.workspacePath}/zedup';
      io.Directory(dir).createSync(recursive: true);
      return dir;
    }
    // No claudart link for this repo → fall back to zedup's profile-dir
    // default. Solo zedup still works.
    return LinkResolver.profileDir().workspaceDir(profile);
  }

  RegistryEntry? _findEntryForCwd(String cwd) {
    // Walk up parents looking for a matching project root, so subdirectories
    // of a linked project still resolve.
    var dir = cwd;
    while (true) {
      final match = _registry.findByProjectRoot(dir);
      if (match != null) return match;
      final parent = io.Directory(dir).parent.path;
      if (parent == dir) return null;
      dir = parent;
    }
  }
}
