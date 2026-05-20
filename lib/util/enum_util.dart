// enum_util.dart — generic helpers over `Enum` values.
//
// Single source for cross-enum utilities so callers don't define
// private copies that drift. New helpers belong here; private
// reimplementations elsewhere are constraint violations (see the
// audit's slice 2 rationale in the claudart handoff).

/// Returns the variant in [values] whose [Enum.name] matches [name]
/// case-insensitively, or null when [name] is null / empty / doesn't
/// match any variant.
///
/// LLM-emitted output may capitalize differently than the enum
/// declarations (`'Sonnet'` vs `'sonnet'`), so the comparison folds
/// both sides to lower-case. Pure, no side effects.
///
/// Example:
///
///   enumByName(IntentClass.values, 'Explore') == IntentClass.explore
///   enumByName(IntentClass.values, 'spelunk') == null
T? enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null || name.isEmpty) return null;
  final lower = name.toLowerCase();
  for (final value in values) {
    if (value.name.toLowerCase() == lower) return value;
  }
  return null;
}
