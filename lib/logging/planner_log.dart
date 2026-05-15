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
}

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
