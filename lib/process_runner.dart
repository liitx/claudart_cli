import 'dart:io';

/// Abstraction over Process.run.
/// Swap in [MockProcessRunner] in tests to avoid spawning real processes.
abstract class ProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  });

  ProcessResult runSync(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  });
}

/// Production implementation backed by dart:io.
class RealProcessRunner implements ProcessRunner {
  const RealProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) =>
      Process.run(executable, arguments, workingDirectory: workingDirectory);

  @override
  ProcessResult runSync(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) =>
      Process.runSync(executable, arguments, workingDirectory: workingDirectory);
}
