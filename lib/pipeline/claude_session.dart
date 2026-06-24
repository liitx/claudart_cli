// claude_session.dart — isolate claudart's `claude` runs by SESSION, not config.
//
// claudart shells out to the `claude` CLI. Without isolation, a background agent
// run shares the same session state as the user's interactive Claude Code session
// (Zed `claude-acp`), which can desync the panel.
//
// The isolation lever is a unique `--session-id` per run — NOT a separate
// `CLAUDE_CONFIG_DIR`. Verified 2026-06-19: config-dir isolation breaks auth, the
// live OAuth token rotates and lives in ~/.claude, so a copied/Keychain credential
// 401s. A unique session id keeps the live shared auth while giving each claudart
// run its own conversation session, distinct from the panel's.

import 'dart:math';

/// A fresh RFC-4122 v4 UUID for the `claude --session-id` flag, so each claudart
/// run gets its own session and never collides with the user's interactive one.
String newClaudeSessionId() {
  final r = Random.secure();
  String hex(int count) =>
      List.generate(count, (_) => r.nextInt(16).toRadixString(16)).join();
  // 8-4-4-4-12, version nibble = 4, variant nibble ∈ {8,9,a,b}.
  final variant = (8 + r.nextInt(4)).toRadixString(16);
  return '${hex(8)}-${hex(4)}-4${hex(3)}-$variant${hex(3)}-${hex(12)}';
}
