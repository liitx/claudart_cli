// model_for_categorize_output_test.dart — verifies the parser that
// turns categorize step output into a routed AgentModel.
//
// The full τ matrix (routeModel) is already covered by
// categorization_test.dart. This file exercises the parser layer:
// well-formed input routes correctly, missing/malformed input
// degrades to the fallback per the audit constraint.

import 'package:claudart/pipeline/agent_model.dart';
import 'package:claudart/pipeline/agents/categorization.dart';
import 'package:test/test.dart';

const _fallback = AgentModel.sonnet;

String _buildOutput({
  required String category,
  required String intent,
  required String complexity,
}) =>
    '<$kCategorizeCategoryTag>$category</$kCategorizeCategoryTag>\n'
    '<$kCategorizeIntentTag>$intent</$kCategorizeIntentTag>\n'
    '<$kCategorizeComplexityTag>$complexity</$kCategorizeComplexityTag>\n';

void main() {
  group('modelForCategorizeOutput — happy path routes via routeModel', () {
    // Spot-checks against the τ matrix declared in routeModel.
    // Adding a new rule to routeModel without adding a row here is
    // intentionally permitted (the matrix test in categorization_test
    // is the authoritative coverage); this is for anchor cases the
    // audit specifically relies on.

    test('atomic explore → haiku (the headline cost win)', () {
      final raw = _buildOutput(
        category: AgentCategory.feature.name,
        intent: IntentClass.explore.name,
        complexity: ComplexityTier.atomic.name,
      );
      expect(
        modelForCategorizeOutput(raw, fallback: _fallback),
        equals(AgentModel.haiku),
      );
    });

    test('systemic explore → opus (max capability)', () {
      final raw = _buildOutput(
        category: AgentCategory.research.name,
        intent: IntentClass.explore.name,
        complexity: ComplexityTier.systemic.name,
      );
      expect(
        modelForCategorizeOutput(raw, fallback: _fallback),
        equals(AgentModel.opus),
      );
    });

    test('atomic implement → sonnet (balanced reasoning)', () {
      final raw = _buildOutput(
        category: AgentCategory.feature.name,
        intent: IntentClass.implement.name,
        complexity: ComplexityTier.atomic.name,
      );
      expect(
        modelForCategorizeOutput(raw, fallback: _fallback),
        equals(AgentModel.sonnet),
      );
    });
  });

  group(
      'modelForCategorizeOutput — degrades to fallback on ambiguity '
      '(reasoner constraint)', () {
    test('empty input returns fallback', () {
      expect(
        modelForCategorizeOutput('', fallback: _fallback),
        equals(_fallback),
      );
    });

    test('missing CATEGORY tag returns fallback', () {
      final raw =
          '<$kCategorizeIntentTag>${IntentClass.explore.name}'
          '</$kCategorizeIntentTag>\n'
          '<$kCategorizeComplexityTag>${ComplexityTier.atomic.name}'
          '</$kCategorizeComplexityTag>\n';
      expect(
        modelForCategorizeOutput(raw, fallback: _fallback),
        equals(_fallback),
      );
    });

    test('missing INTENT tag returns fallback', () {
      final raw =
          '<$kCategorizeCategoryTag>${AgentCategory.feature.name}'
          '</$kCategorizeCategoryTag>\n'
          '<$kCategorizeComplexityTag>${ComplexityTier.atomic.name}'
          '</$kCategorizeComplexityTag>\n';
      expect(
        modelForCategorizeOutput(raw, fallback: _fallback),
        equals(_fallback),
      );
    });

    test('missing COMPLEXITY tag returns fallback', () {
      final raw =
          '<$kCategorizeCategoryTag>${AgentCategory.feature.name}'
          '</$kCategorizeCategoryTag>\n'
          '<$kCategorizeIntentTag>${IntentClass.explore.name}'
          '</$kCategorizeIntentTag>\n';
      expect(
        modelForCategorizeOutput(raw, fallback: _fallback),
        equals(_fallback),
      );
    });

    test('unknown enum variant (typo from LLM) returns fallback', () {
      final raw = _buildOutput(
        category: AgentCategory.feature.name,
        intent: 'spelunk', // not a real IntentClass
        complexity: ComplexityTier.atomic.name,
      );
      expect(
        modelForCategorizeOutput(raw, fallback: _fallback),
        equals(_fallback),
      );
    });

    test('different fallback honored (custom default)', () {
      expect(
        modelForCategorizeOutput('', fallback: AgentModel.opus),
        equals(AgentModel.opus),
      );
    });
  });

  group('modelForCategorizeOutput — tag-NAME case insensitivity', () {
    test('lower-case tag names parse (LLM may not honor upper-case prompt)',
        () {
      const raw =
          '<category>feature</category>\n'
          '<intent>explore</intent>\n'
          '<complexity>atomic</complexity>\n';
      expect(
        modelForCategorizeOutput(raw, fallback: _fallback),
        equals(AgentModel.haiku),
      );
    });

    test('mixed-case tag names parse', () {
      const raw =
          '<Category>feature</Category>\n'
          '<Intent>explore</Intent>\n'
          '<Complexity>atomic</Complexity>\n';
      expect(
        modelForCategorizeOutput(raw, fallback: _fallback),
        equals(AgentModel.haiku),
      );
    });
  });

  group('modelForCategorizeOutput — tag-VALUE case insensitivity', () {
    test('mixed-case enum names match (LLM may capitalize)', () {
      const raw =
          '<$kCategorizeCategoryTag>Feature</$kCategorizeCategoryTag>\n'
          '<$kCategorizeIntentTag>Explore</$kCategorizeIntentTag>\n'
          '<$kCategorizeComplexityTag>Atomic</$kCategorizeComplexityTag>\n';
      expect(
        modelForCategorizeOutput(raw, fallback: _fallback),
        equals(AgentModel.haiku),
      );
    });

    test('upper-case enum names match', () {
      const raw =
          '<$kCategorizeCategoryTag>FEATURE</$kCategorizeCategoryTag>\n'
          '<$kCategorizeIntentTag>EXPLORE</$kCategorizeIntentTag>\n'
          '<$kCategorizeComplexityTag>ATOMIC</$kCategorizeComplexityTag>\n';
      expect(
        modelForCategorizeOutput(raw, fallback: _fallback),
        equals(AgentModel.haiku),
      );
    });
  });
}
