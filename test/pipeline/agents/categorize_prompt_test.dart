// categorize_prompt_test.dart — verifies the categorize system
// prompt stays structurally tied to the enum taxonomy.
//
// Test surface iterates `CategorizeTag.values` and each tag's
// `.allowedValues`. Adding a CategorizeTag variant breaks the
// `allowedValues` switch in production; adding an enum variant on
// any axis (AgentCategory, IntentClass, ComplexityTier, AgentModel)
// shows up here automatically via .values iteration.

import 'package:claudart/pipeline/agent_model.dart';
import 'package:claudart/pipeline/agents/categorization.dart';
import 'package:test/test.dart';

void main() {
  // ── allowedValues per tag is sourced from the right axis enum ─────────────

  group('CategorizeTag.allowedValues mirrors the target enum', () {
    test('category → AgentCategory.values', () {
      expect(
        CategorizeTag.category.allowedValues,
        equals([for (final v in AgentCategory.values) v.name]),
      );
    });

    test('intent → IntentClass.values', () {
      expect(
        CategorizeTag.intent.allowedValues,
        equals([for (final v in IntentClass.values) v.name]),
      );
    });

    test('complexity → ComplexityTier.values', () {
      expect(
        CategorizeTag.complexity.allowedValues,
        equals([for (final v in ComplexityTier.values) v.name]),
      );
    });

    test('model → AgentModel.values', () {
      expect(
        CategorizeTag.model.allowedValues,
        equals([for (final v in AgentModel.values) v.name]),
      );
    });
  });

  // ── allowedValues invariants ──────────────────────────────────────────────

  group('CategorizeTag.allowedValues invariants', () {
    for (final tag in CategorizeTag.values) {
      test('${tag.name} declares at least one allowed value', () {
        expect(tag.allowedValues, isNotEmpty);
      });

      test('${tag.name} allowed values are unique', () {
        expect(
          tag.allowedValues.toSet().length,
          equals(tag.allowedValues.length),
        );
      });

      test('${tag.name} allowed values are non-empty strings', () {
        for (final value in tag.allowedValues) {
          expect(value, isNotEmpty);
        }
      });
    }
  });

  // ── buildCategorizePrompt embeds every tag + every allowed value ──────────

  group('buildCategorizePrompt is derived from the enum taxonomy', () {
    final prompt = buildCategorizePrompt();

    test('contains every tag\'s wire-format name', () {
      for (final tag in CategorizeTag.values) {
        expect(
          prompt,
          contains('<${tag.wireTag}>'),
          reason: 'missing tag <${tag.wireTag}> in prompt',
        );
      }
    });

    test('contains every allowed value across every tag', () {
      for (final tag in CategorizeTag.values) {
        for (final value in tag.allowedValues) {
          expect(
            prompt,
            contains(value),
            reason:
                '${tag.wireTag} value "$value" missing from prompt — '
                'prompt/parser would drift if LLM emitted it',
          );
        }
      }
    });

    test('is non-empty + carries the schema instruction', () {
      expect(prompt, isNotEmpty);
      // Documents the "no prose" expectation lives in the prompt.
      // Doesn't bake the exact wording (would be a bare-string test);
      // checks the structural claim only.
      expect(prompt.contains('only') || prompt.contains('Output'), isTrue);
      expect(prompt, contains('XML'));
    });
  });
}
