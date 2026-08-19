# Changelog

## 0.1.0

Initial implementation.

- Lexer/parser/AST pipeline for a controlled Flutter-like widget DSL (strings, numbers,
  booleans, null, lists, maps, nested widget/constructor calls, trailing commas, comments,
  string interpolation with escapes).
- Safe, sandboxed expression language for `$variable.path` lookups, comparison/boolean/
  arithmetic operators, and ternary conditionals — no `eval`, no reflection, no dynamic code
  execution.
- Registry-driven resolution for widgets, value constructors, colors, enums, and named
  constants, with alias support and `fork()`-based composition for dependency injection.
- Broad built-in widget coverage: layout, scrolling, text, buttons, images/icons, Material
  components, and basic form/input widgets.
- Explicit `action(...)` registry so remote UI can only trigger host-registered callbacks —
  never arbitrary code.
- Structured, contextual errors (`LexerException`, `SyntaxException`, `ValidationException`,
  `WidgetResolutionException`, `PropertyResolutionException`, `ExpressionException`) with
  line/column/snippet and "did you mean?" suggestions.
- Configurable per-node error recovery (`throw` / `fallback` / `ignore`) via
  `DynamicParserConfig`.
- Resource limits (source length, AST depth, widget count, list length, expression depth,
  string length, parse time budget) to defend against pathological/adversarial input.
- LRU AST caching keyed by source text.
- Non-throwing `validate()` API returning structured `ValidationResult`/`ValidationIssue`s.
- Debug pretty-printing (`AstNode.prettyPrint()`) and optional debug logging.
- Comprehensive test suite: lexer, parser, resolver, expressions, widget rendering, security,
  performance/caching, and fuzz tests.
- Example Flutter app demonstrating a server-driven screen and a live source-editing
  playground.
