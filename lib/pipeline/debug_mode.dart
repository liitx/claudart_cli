// debug_mode.dart — runtime + env toggle for claudart's debug log.
//
// `claudart --debug <command>` flips [setDebugEnabled] at CLI entry so
// every downstream pipeline step writes a structured trace to disk.
// `CLAUDART_DEBUG=1` is the env-var equivalent for scripts that can't
// shape argv (CI runners, wrappers). The two sources OR together — if
// either is true, the log writes.
//
// The log path defaults to `/tmp/claudart_debug.log` and can be
// overridden via `CLAUDART_DEBUG_PATH=...`.
//
// Testability: [debugEnabled] and [debugLogFile] accept an optional
// `environment` map so tests drive both the runtime flag and the env
// var without mutating `Platform.environment`.

import 'dart:io';

/// Env var that enables debug-log writes when set to `1`.
const String kClaudartDebugEnvVar = 'CLAUDART_DEBUG';

/// Env var that overrides the default log destination.
const String kClaudartDebugPathEnvVar = 'CLAUDART_DEBUG_PATH';

/// Default destination when no override is provided.
const String kDefaultClaudartDebugLogPath = '/tmp/claudart_debug.log';

/// Value the env var must hold to enable debug mode.
const String kClaudartDebugEnabledValue = '1';

bool _runtimeDebugEnabled = false;

/// Toggled by the CLI when `--debug` is present in argv. Persists for
/// the lifetime of the process so every pipeline step picks it up
/// without an env-var dance.
void setDebugEnabled(bool value) {
  _runtimeDebugEnabled = value;
}

/// True when either the CLI flag was set or the env var equals
/// [kClaudartDebugEnabledValue]. [environment] defaults to the
/// process env; tests inject a clean map.
bool debugEnabled({Map<String, String>? environment}) {
  if (_runtimeDebugEnabled) return true;
  final env = environment ?? Platform.environment;
  return env[kClaudartDebugEnvVar] == kClaudartDebugEnabledValue;
}

/// Returns the debug log file when debug mode is on, null when off.
/// Callers pass `null` straight through their conditional writes.
File? debugLogFile({Map<String, String>? environment}) {
  if (!debugEnabled(environment: environment)) return null;
  final env = environment ?? Platform.environment;
  final path = env[kClaudartDebugPathEnvVar] ?? kDefaultClaudartDebugLogPath;
  return File(path);
}
