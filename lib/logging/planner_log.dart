// planner_log.dart — append-only JSONL of planner routing decisions.
//
// Each decision the planner makes (categorize → routeModel → flow) emits
// one record so post-hoc analysis can see what got routed where and why.
// Records carry the DesignSurface tag when path heuristics influenced the
// flow choice.

import 'dart:convert';
import 'dart:io' as io;

import '../pipeline/agent_flow.dart';
import '../pipeline/agent_model.dart';
import '../pipeline/agents/categorization.dart';
import '../pipeline/agents/path_heuristic.dart';
import '../pipeline/xml_tags.dart';

/// XML tag names emitted by the categorize step. Lives at the top of the
/// module so the parser and any future consumer reference a single source
/// for the tag wire-format.
const String _kCategoryTag    = 'CATEGORY';
const String _kIntentTag      = 'INTENT';
const String _kComplexityTag  = 'COMPLEXITY';
const String _kModelTag       = 'MODEL';

/// Stderr line emitted when [PlannerLog.record] throws (disk full, perms,
/// missing parent dir). Production callers swallow the exception and emit
/// this line so the flow continues — planner logging is best-effort and
/// must never block the categorize step.
///
/// Exposed as a const so production and tests reference the same string.
const String plannerLogRecordFailureWarning =
    'planner_log: record failed; continuing flow (best-effort logging).';

class PlannerDecision {
  const PlannerDecision({
    required this.timestamp,
    required this.flow,
    required this.category,
    required this.intent,
    required this.complexity,
    required this.model,
    required this.designSurfaceCounts,
    this.note,
  });

  final DateTime timestamp;
  final AgentFlow flow;
  final AgentCategory category;
  final IntentClass intent;
  final ComplexityTier complexity;
  final AgentModel model;
  final Map<DesignSurface, int> designSurfaceCounts;
  final String? note;

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'flow': flow.name,
        'category': category.name,
        'intent': intent.name,
        'complexity': complexity.name,
        'model': model.name,
        'surfaces': {
          for (final entry in designSurfaceCounts.entries)
            entry.key.tag: entry.value,
        },
        if (note != null) 'note': note,
      };

  /// Parses the categorize step's raw output (XML-tagged classification)
  /// into a typed [PlannerDecision]. Returns null when any required tag is
  /// missing or maps to an unknown enum variant — callers skip logging
  /// rather than crash the flow.
  ///
  /// Expected input shape (whitespace tolerated):
  /// ```
  /// <CATEGORY>feature</CATEGORY>
  /// <INTENT>explore</INTENT>
  /// <COMPLEXITY>compound</COMPLEXITY>
  /// <MODEL>sonnet</MODEL>
  /// ```
  static PlannerDecision? fromCategorizeOutput(
    String raw, {
    required Map<DesignSurface, int> designSurfaceCounts,
    AgentFlow flow = AgentFlow.flow,
    String? note,
    DateTime Function() now = _systemNow,
  }) {
    final category = _enumByName(AgentCategory.values, tagOrNull(raw, _kCategoryTag));
    final intent = _enumByName(IntentClass.values, tagOrNull(raw, _kIntentTag));
    final complexity =
        _enumByName(ComplexityTier.values, tagOrNull(raw, _kComplexityTag));
    final model = _enumByName(AgentModel.values, tagOrNull(raw, _kModelTag));
    if (category == null ||
        intent == null ||
        complexity == null ||
        model == null) {
      return null;
    }
    return PlannerDecision(
      timestamp: now(),
      flow: flow,
      category: category,
      intent: intent,
      complexity: complexity,
      model: model,
      designSurfaceCounts: designSurfaceCounts,
      note: note,
    );
  }
}

/// Looks up an enum variant by [Enum.name]. Case-insensitive comparison
/// since the LLM may capitalize ('Sonnet' vs 'sonnet'). Returns null
/// when [name] is null or doesn't match any variant.
T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  final lower = name.toLowerCase();
  for (final value in values) {
    if (value.name.toLowerCase() == lower) return value;
  }
  return null;
}

/// Default clock for planner records. UTC so JSONL streams from
/// different machines or timezones sort and diff cleanly. Matches the
/// convention used by `SessionLogger` and downstream analytics.
DateTime _systemNow() => DateTime.now().toUtc();

class PlannerLog {
  PlannerLog({String? path, this.appender = _defaultAppend})
      : _path = path ?? _defaultPath();

  final String _path;
  final void Function(String path, String line) appender;

  static String _defaultPath() {
    final home = io.Platform.environment['HOME'] ?? '.';
    return '$home/.claudart/planner.jsonl';
  }

  static void _defaultAppend(String path, String line) {
    final file = io.File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('$line\n', mode: io.FileMode.append);
  }

  void record(PlannerDecision decision) {
    appender(_path, jsonEncode(decision.toJson()));
  }

  Map<DesignSurface, int> tallySurfaces(List<String> paths) {
    final counts = {for (final v in DesignSurface.values) v: 0};
    for (final path in paths) {
      final surface = classifyPath(path);
      counts[surface] = counts[surface]! + 1;
    }
    return counts;
  }
}
