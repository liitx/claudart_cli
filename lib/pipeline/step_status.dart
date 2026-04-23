// step_status.dart — lifecycle state of a single pipeline step
//
// Produced by PipelineExecutor as each step transitions.
// Consumed by claudart CLI (spinner output) and zedup (workflow pane UI).

enum StepStatus { pending, running, done, failed }
