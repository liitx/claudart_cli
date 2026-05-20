// xml_tags.dart — XML tag extraction utilities for agent output parsing.
//
// Pipeline steps output structured XML tags. These functions extract
// content between `<TAG>` and `</TAG>` by direct string scan — no
// regex, no compiled patterns, no allocation overhead per call. Pure
// functions, no side effects.
//
// Two parsers:
//   tagOr            — case-sensitive; returns a fallback when absent.
//   tagOrNull        — case-sensitive; returns null when absent.
//   tagOrNullIgnoreCase — tag-name is matched case-insensitively for
//                         LLM-emitted output that may not honor the
//                         system prompt's UPPER_SNAKE_CASE convention.
//
// The captured content is whitespace-trimmed but otherwise verbatim —
// the caller normalizes the value.

const String _kDefaultFallback = '_Not determined._';

/// Extracts the trimmed content between `<TAG>` and `</TAG>` in [text].
/// Returns [fallback] when the tag is absent. Case-sensitive.
String tagOr(String text, String tag, [String fallback = _kDefaultFallback]) =>
    _extractTag(text, tag, caseInsensitive: false) ?? fallback;

/// Case-sensitive [tagOr] variant that returns null when absent.
String? tagOrNull(String text, String tag) =>
    _extractTag(text, tag, caseInsensitive: false);

/// Case-insensitive variant. Use this for LLM-emitted output where
/// the tag name's case is unreliable.
String? tagOrNullIgnoreCase(String text, String tag) =>
    _extractTag(text, tag, caseInsensitive: true);

/// Single tag-extraction primitive. Scans [text] for `<tag>...</tag>`
/// via [String.indexOf], skipping the regex engine entirely.
///
/// When [caseInsensitive] is true the haystack + needles are folded
/// to lower-case once before searching; the captured substring is
/// sliced from the original [text] so the returned value preserves
/// the producer's case.
String? _extractTag(String text, String tag, {required bool caseInsensitive}) {
  final haystack = caseInsensitive ? text.toLowerCase() : text;
  final openNeedle = caseInsensitive ? '<${tag.toLowerCase()}>' : '<$tag>';
  final closeNeedle =
      caseInsensitive ? '</${tag.toLowerCase()}>' : '</$tag>';

  final openIndex = haystack.indexOf(openNeedle);
  if (openIndex < 0) return null;

  final contentStart = openIndex + openNeedle.length;
  final closeIndex = haystack.indexOf(closeNeedle, contentStart);
  if (closeIndex < 0) return null;

  return text.substring(contentStart, closeIndex).trim();
}
