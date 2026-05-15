// path_heuristic.dart — classifies file paths into design vs. logic surfaces.
//
// Used by the planner to decide whether a scoped task should route through
// the GuiDesignAgent (AgentFlow.guiDesign). The classification is
// enum-driven so callers can iterate over every variant and reason about
// thresholds without bare strings sprinkled at decision sites.

/// Variant tags a scoped file lands in. The planner uses majority vote
/// across the input scope: if ≥ N files land in [DesignSurface.guiWidget]
/// or [DesignSurface.guiPainter] the work is routed through guiDesign.
enum DesignSurface {
  /// `**/widgets/**/*.dart` — Flutter/Dart widget definitions.
  guiWidget,

  /// `**/ui/**/*.dart` — generic UI layer.
  guiUi,

  /// `**/painter*.dart` or `**/painters/**/*.dart` — custom paint logic.
  guiPainter,

  /// `**/theme*.dart` or `**/style*.dart` — design tokens.
  guiTheme,

  /// Any other path — non-design surface.
  logic;

  /// Whether this surface counts toward "this work is design-heavy".
  bool get isDesignSurface => switch (this) {
        DesignSurface.guiWidget   => true,
        DesignSurface.guiUi       => true,
        DesignSurface.guiPainter  => true,
        DesignSurface.guiTheme    => true,
        DesignSurface.logic       => false,
      };

  /// Short label for log lines and the planner JSONL.
  String get tag => switch (this) {
        DesignSurface.guiWidget   => 'widget',
        DesignSurface.guiUi       => 'ui',
        DesignSurface.guiPainter  => 'painter',
        DesignSurface.guiTheme    => 'theme',
        DesignSurface.logic       => 'logic',
      };
}

/// Classifies a single path into a [DesignSurface] variant.
DesignSurface classifyPath(String path) {
  final lower = path.toLowerCase();
  if (lower.contains('/widgets/')) return DesignSurface.guiWidget;
  if (lower.contains('/painters/') ||
      RegExp(r'painter[^/]*\.dart$').hasMatch(lower)) {
    return DesignSurface.guiPainter;
  }
  if (lower.contains('/ui/')) return DesignSurface.guiUi;
  if (lower.contains('/theme/') ||
      lower.contains('/style/') ||
      RegExp(r'(theme|style)[^/]*\.dart$').hasMatch(lower)) {
    return DesignSurface.guiTheme;
  }
  return DesignSurface.logic;
}

/// Whether the supplied paths warrant routing to the GuiDesignAgent.
/// Threshold: at least half the paths classify as a design surface.
bool isDesignScope(List<String> paths) {
  if (paths.isEmpty) return false;
  final design = paths.where((p) => classifyPath(p).isDesignSurface).length;
  return design * 2 >= paths.length;
}
