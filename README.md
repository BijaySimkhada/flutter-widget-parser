# dynamic_widget_parser

A production-grade, security-first **dynamic Flutter widget parser** for server-driven UI.

It turns a controlled, Flutter-like DSL string — or an already-parsed AST, so a future JSON
input format can share the same pipeline — into a real Flutter `Widget` tree, via a proper
lexer → parser → AST → resolver → widget-factory pipeline. It never executes arbitrary Dart
code, never uses reflection, and never instantiates anything that wasn't explicitly registered
by your app.

```dart
final Widget widget = DynamicWidgetParser.parse(
  source: incomingString,
  context: context,
);
```

## Table of contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Architecture](#architecture)
- [Supported syntax](#supported-syntax)
- [Supported widgets](#supported-widgets)
- [Widget registration](#widget-registration)
- [Property registration](#property-registration)
- [Custom values, colors, and enums](#custom-values-colors-and-enums)
- [Expressions and variables](#expressions-and-variables)
- [Actions](#actions)
- [Stateful widgets and keys](#stateful-widgets-and-keys)
- [Theme integration](#theme-integration)
- [Security model](#security-model)
- [Caching and performance](#caching-and-performance)
- [Error handling](#error-handling)
- [Validation API](#validation-api)
- [Debugging](#debugging)
- [Server-driven UI / JSON](#server-driven-ui--json)
- [Testing](#testing)
- [Limitations](#limitations)
- [Extending the parser](#extending-the-parser)
- [Dependencies](#dependencies)

## Installation

This package is not (yet) published to pub.dev. Depend on it by path or git:

```yaml
dependencies:
  dynamic_widget_parser:
    path: ../dynamic_widget_parser
```

## Quick start

```dart
import 'package:dynamic_widget_parser/dynamic_widget_parser.dart';
import 'package:flutter/material.dart';

void main() {
  // Actions are the only way remote UI can trigger app behavior — see
  // "Security model" below. Register them once, at startup.
  DynamicWidgetParser.defaultActions.register('openProfile', (context, args) {
    Navigator.of(context).pushNamed('/profile', arguments: args['userId']);
  });
  runApp(const MyApp());
}

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  static const String source = '''
Scaffold(
  appBar: AppBar(title: Text("Dynamic UI")),
  body: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Welcome",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: action("openProfile", {"userId": 42}),
          child: Text("View Profile"),
        ),
      ],
    ),
  ),
)
''';

  @override
  Widget build(BuildContext context) {
    return DynamicWidgetParser.parse(source: source, context: context);
  }
}
```

## Architecture

```text
Incoming String
      |
      v
  DynamicLexer      lib/src/lexer/       tokens: identifiers, numbers, strings
      |                                  (with interpolation/escapes), punctuation,
      v                                  operators, comments — pure Dart, no Flutter.
  DynamicParser      lib/src/parser/      recursive-descent parser -> immutable AST.
      |                                  Pure Dart; enforces DynamicParserLimits.
      v
     AST             lib/src/ast/        WidgetNode / PropertyNode / ValueNode /
      |                                  ExpressionNode hierarchy. Depends on nothing
      |                                  but itself — no Flutter, no registry.
      v
  SemanticValidator   lib/src/validation/ optional pre-flight check against a registry,
      |                                  without building anything (no BuildContext
      |                                  needed) — see `DynamicWidgetParser.validate`.
      v
DynamicWidgetRegistry  lib/src/registry/ the allowlist: widgets, value constructors,
      |                                  colors/enums/constants, aliases.
      v
  ValueResolver        lib/src/resolver/ walks the AST, evaluates expressions,
      |                                  dispatches calls to the registry, applies
      |                                  per-node error recovery.
      v
  WidgetFactory        lib/src/widgets/  thin public entry point wrapping ValueResolver
      |                                  (`buildFromAst`).
      v
  Flutter Widget tree
```

Parsing (lexer/parser/AST) has **zero Flutter imports** — it's pure, independently testable
Dart. Only the registry/resolver/widget layers know about Flutter, which is what makes
`parseToAst` (parse once) and `buildFromAst` (build many times, with different data/registries)
useful as separate operations — see [Caching and performance](#caching-and-performance).

## Supported syntax

This is a **controlled subset** of Dart/Flutter syntax, not a Dart parser. What's supported:

- Widget/constructor calls: `Name(...)` and `Name.constructorName(...)`, with positional and
  named arguments, trailing commas optional, to an arbitrary depth bounded by
  `DynamicParserLimits.maxAstDepth`.
- Literals: `String` (single or double quoted, with `\n \t \r \b \f \v \\ \' \" \$ \uXXXX`
  escapes), `int`, `double` (including `0xFF...` hex and `1e3` exponent forms), `bool`, `null`.
- String interpolation: `"Hello $user.name"` (bare dotted path) and `"Total: ${$a + $b}"`
  (braced, full expression — note the `$` is still required inside `${}` for variables).
- Collections: `[a, b, c]` lists and `{"key": value}` maps, trailing commas optional.
- Dotted identifier paths with no call: `Colors.blue`, `MainAxisAlignment.center`,
  `Colors.blue.shade200`.
- The safe expression language (see [Expressions](#expressions-and-variables)) anywhere a
  `$`, `!`, `(`, or unary `-` can unambiguously start one.
- `//` line comments and `/* ... */` block comments (nesting-aware).

**Explicitly not supported** (any of these produce a `SyntaxException`, not a crash):

- Arbitrary Dart expressions, statements, control flow, function/method definitions.
- Method calls on values (`$x.foo()`), only dotted *path lookups*.
- Implicit adjacent string-literal concatenation (`"a" "b"` — a real-Dart-only feature).
- `import`, `class`, `extends`, or any other declaration-level syntax.
- Cascades, spread operators, generic type arguments, `is`/`as`, `late`/`const`/`final`.

## Supported widgets

Registered out of the box by `createStandardRegistry()` (see
`lib/src/widgets/builtin/register_builtins.dart`):

- **Layout**: `Container`, `SizedBox`, `ConstrainedBox`, `LimitedBox`, `FractionallySizedBox`,
  `OverflowBox`, `Padding`, `Align`, `Center`, `Expanded`, `Flexible`, `Spacer`, `AspectRatio`,
  `FittedBox`, `Transform.rotate/scale/translate`, `DecoratedBox`, `ColoredBox`, `Opacity`,
  `Visibility`, `Offstage`, `ClipRect`, `ClipRRect`, `ClipOval`.
- **Multi-child layout**: `Row`, `Column`, `Stack`, `Wrap`, `IndexedStack`.
- **Scrolling**: `ListView`, `SingleChildScrollView`, `GridView.count`, `PageView`.
- **Text**: `Text`, `RichText` (+ `TextSpan` constructor), `SelectableText`, `DefaultTextStyle`.
- **Buttons**: `ElevatedButton`, `FilledButton`, `OutlinedButton`, `TextButton`, `IconButton`,
  `FloatingActionButton`, `DropdownButton`.
- **Images/Icons**: `Image.network`, `Image.asset`, `CircleAvatar`, `Icon` (with an allowlisted
  `Icons.*` registry — see `built_in_icons.dart`).
- **Material**: `Card`, `ListTile`, `Divider`, `VerticalDivider`, `AppBar`, `Scaffold`,
  `CircularProgressIndicator`, `LinearProgressIndicator`, `Chip`, `Tooltip`, `Badge`.
- **Form/input**: `TextField`, `TextFormField`, `Checkbox`, `Switch`, `Slider`,
  `Radio<String>` (see [Limitations](#limitations) for controller caveats).

Value constructors: `EdgeInsets.all/symmetric/only/fromLTRB`, `BorderRadius.circular/all/only`,
`Radius.circular`, `Size`, `Offset`, `Alignment`, `BoxConstraints`, `Color` (+
`.fromARGB`/`.fromRGBO`), `Duration`, `BorderSide`, `Border`/`Border.all`, `BoxShadow`,
`LinearGradient`/`RadialGradient`/`SweepGradient`, `BoxDecoration`, `TextStyle`, `TextSpan`,
`Key`/`ValueKey`.

Not registered by default but easy to add via the registry: `CustomScrollView` (slivers),
`ListView.builder`/`GridView.builder` (need an `itemBuilder` closure — see
[Limitations](#limitations)), `NavigationBar`, `BottomNavigationBar`, `Drawer`.

## Widget registration

Two ways to register a widget, from lightest to most rigorous:

```dart
// 1. Lightweight — for simple app widgets.
registry.registerWidget('UserCard', (context, properties, children) {
  return UserCard(
    name: properties['name'] as String?,
    avatar: properties['avatar'] as String?,
  );
});

// 2. Full control — validated properties, positional args, defaults.
registry.registerWidgetDefinition(WidgetDefinition(
  name: 'UserCard',
  properties: [
    PropertyDefinition(name: 'name', type: String, isRequired: true),
    PropertyDefinition.withDefault(name: 'avatar', type: String, defaultValue: 'default.png'),
  ],
  builder: (context, args) => UserCard(
    name: args.get<String>('name')!,
    avatar: args.getOr<String>('avatar', 'default.png'),
  ),
));
```

Adding a widget **never requires touching the lexer, parser, or resolver** — that's the whole
point of the registry layer. Aliases work the same way for both widgets and constructors:

```dart
registry.registerAlias('PrimaryButton', 'AppPrimaryButton');
```

For dependency injection, `builder` closures can capture app services directly, and
`DynamicWidgetRegistry.fork()` creates a child registry that layers app- or screen-specific
widgets on top of the shared built-ins without mutating them:

```dart
final DynamicWidgetRegistry appRegistry = DynamicWidgetParser.defaultRegistry.fork()
  ..registerWidget('UserCard', (context, props, children) => UserCard(repo: myUserRepo, ...));
```

## Property registration

Every `PropertyDefinition` can declare a required-ness, default, converter, and validator:

```dart
PropertyDefinition(
  name: 'opacity',
  type: double,
  converter: ValueConverter.toDouble,       // centralizes num -> double, string parsing, etc.
  validator: (v) => (v as double) < 0 || v > 1 ? 'opacity must be between 0.0 and 1.0' : null,
)
```

The resolver detects, before a single widget is built: unknown properties (with a "did you
mean?" suggestion), missing required properties, duplicate named arguments, and too
many/too few positional arguments — all as structured `PropertyResolutionException`s with
`widget`, `property`, `expected`, `actual`, and a source `span`.

## Custom values, colors, and enums

```dart
// A custom named constant.
registry.registerValue('AppColors.primary', () => AppColors.primary);

// A whole Dart enum, registered generically (no hardcoded switch statement).
registry.registerEnum<MyEnum>('MyEnum', MyEnum.values);
```

Colors accept `Colors.red`, `Colors.blueAccent`, numbered shades (`Colors.blue.shade200`), the
`Color(0xFF...)` / `Color.fromARGB(...)` / `Color.fromRGBO(...)` constructors, and hex/functional
strings via `ValueConverter.toColor` (`"#RRGGBB"`, `"#AARRGGBB"`, `rgb(r, g, b)`,
`rgba(r, g, b, a)` — see `ColorParser`).

## Expressions and variables

Property values can reference host-supplied data via a small, closed expression language —
**not** `eval`, not reflection, nothing beyond what you explicitly expose:

```text
$user.name                                   variable path lookup
$user.isLoggedIn ? "Logout" : "Login"        ternary
$screen.width > 600 ? 24 : 16                responsive breakpoints
$screen.width * 0.8                          arithmetic
$a == $b, !=, >, <, >=, <=, &&, ||, !, ??, +, -, *, /
```

Expose data via `DynamicDataContext`:

```dart
DynamicWidgetParser.parse(
  source: source,
  context: context,
  data: DynamicDataContext(values: {
    'user': {'name': 'Ada', 'isLoggedIn': true},
    'screen': {'width': MediaQuery.sizeOf(context).width},
  }),
);
```

Values can be `Map<String, Object?>`, `List` (indexable: `$items.0.name`), primitives, or a
class implementing `DynamicExposable` (`toDynamicValues()`) — the *only* sanctioned way to
expose a plain Dart object without reflection. A missing path resolves to `null` (so
`$user.nickname ?? "Guest"` works) rather than throwing; a type mismatch (comparing a string
with `>`, `&&` on a non-bool, ...) throws `ExpressionException` with full source context, since
that indicates a malformed payload rather than expected data variability. `&&`/`||`/ternary all
short-circuit.

## Actions

Dynamic strings cannot safely contain Dart closures, so callbacks go through an explicit
allowlist:

```dart
ActionRegistry.register('login', (context, arguments) { ... }); // or DynamicWidgetParser.defaultActions
```

```text
onPressed: action("login")
onPressed: action("openProfile", {"userId": $user.id})
```

`onPressed`/`onTap`/`onDeleted` bind to `VoidCallback`; `onChanged`/`onSubmitted` bind to
`ValueChanged<T>` (the new value is merged into `arguments` under the key `"value"`) — see
`CallbackResolver`. Referencing an unregistered action fails immediately, with a "did you
mean?" suggestion, at the point `action(...)` is resolved — never silently, never by falling
back to any kind of dynamic dispatch.

## Stateful widgets and keys

`Key("user-$id")` / `ValueKey("user-$id")` are supported as ordinary constructor calls and map
to a real `ValueKey<String>`, so list items and conditionally-rendered subtrees can preserve
Flutter element/state identity across rebuilds exactly like hand-written keyed widgets do.

Beyond that, see [Limitations](#limitations) — the DSL has no representation for a
`TextEditingController`, `AnimationController`, or any other object with a lifecycle a `State`
would normally own, since AST->Widget resolution is a stateless, repeatable transform. Widgets
needing one (`TextField`, `Slider`, ...) are exposed as **controlled components**: `value` is a
plain property (typically read from `DynamicDataContext`) and `onChanged` is an `action(...)`
that the host uses to update its own state and re-render — the same pattern any declarative UI
system without local mutable widget state uses.

## Theme integration

Generated widgets are ordinary Flutter widgets built with the real `BuildContext` you passed
in, so `Theme.of(context)`, `MediaQuery.of(context)`, `Localizations`, and `Directionality` all
work exactly as they would in hand-written code — nothing is duplicated or shadowed. To let
remote UI *reference* the current theme, expose it explicitly through `DynamicDataContext`
(e.g. `'theme': {'primaryColor': Theme.of(context).colorScheme.primary}`) the same way you'd
expose any other host data; there's no special theme-path syntax.

## Security model

Every one of these is a structural guarantee of the architecture, not a convention to remember:

- **No code execution.** No `eval`, `dart:mirrors`, or runtime compilation anywhere in this
  package. Grep the source — it isn't there.
- **Allowlists everywhere.** Widgets, value constructors, colors/enums/constants, and actions
  are only reachable if explicitly registered. An unregistered name — however it's spelled —
  fails with a `WidgetResolutionException`, never a guess.
- **No reflection.** Host objects are exposed to expressions only via `DynamicExposable`, an
  explicit opt-in interface — never via `dart:mirrors` or field enumeration.
- **No filesystem/network/shell access** originates from the parser itself. (`Image.network`
  is a widget an app can *choose* to register, exactly like `<img src>` in server-rendered
  HTML — see the security note in `image_icon_widgets.dart` if that's outside your threat
  model.)
- **Resource limits** bound untrusted input: `maxSourceLength`, `maxAstDepth` (prevents stack
  exhaustion from pathological nesting — see the fuzz tests), `maxWidgetCount`,
  `maxListLength`, `maxExpressionDepth`, `maxStringLength`, and a best-effort
  `maxParseDuration`, all on `DynamicParserLimits`.
- **Deterministic expression evaluation.** The expression evaluator is a small, total,
  tree-walking interpreter over a closed operator set — see `ExpressionEvaluator`.

See `test/security/` for the tests exercising this directly, and `test/fuzz/` for
mutation/random-input fuzzing that asserts the parser only ever throws a
`DynamicParserException` (or succeeds) — never crashes with an unrelated Dart error.

## Caching and performance

`DynamicWidgetParser.parse`/`parseToAst` cache parsed ASTs by exact source text (LRU, default
100 entries, configurable via `DynamicParserConfig.astCacheMaxEntries` or an explicit
`DynamicParserCache`). AST nodes are immutable, so a cached tree is safe to reuse — and even
share — across builds with different `DynamicDataContext`s; only the build step depends on
runtime data, not the parse. Disable caching per-call with
`DynamicParserConfig(enableAstCache: false)`.

```dart
final cache = DynamicParserCache(maxEntries: 200);
final widget = DynamicWidgetParser.parse(source: source, context: context, cache: cache);
```

Since `parseToAst`/`buildFromAst` are separate calls, a server-driven-UI screen that re-renders
frequently (e.g. on a data stream) only pays the resolve/build cost per frame, not the
lex/parse cost.

## Error handling

Every error in the pipeline is a typed `DynamicParserException` subclass —
`LexerException`, `SyntaxException`, `ValidationException`, `WidgetResolutionException`,
`PropertyResolutionException`, `ExpressionException` — carrying as much context as is known:
`message`, `span` (line/column/offset + a caret-annotated source snippet), `widget`,
`property`, `expected`, `actual`, and a Levenshtein-based `suggestion`:

```text
PropertyResolutionException: Invalid type for property "fontSize" of "TextStyle".
  Widget: TextStyle
  Property: fontSize
  Expected: double
  Actual: String
  Did you mean: fontSize?
  Location: line 4, column 12
  ---
    fontSiz: "20",
             ^
  ---
```

`DynamicParserConfig.errorBehavior` controls what happens when *building* (not parsing) hits a
problem:

| Mode | Behavior |
|---|---|
| `throwError` (default) | Rethrows — best for development and `validate()`. |
| `fallback` | Replaces the failing subtree with `fallbackWidgetBuilder`'s result (default `SizedBox.shrink()`) and calls `onError`. |
| `ignore` | Same substitution, but never calls `onError` — the failure is swallowed except for optional debug logging. |

Recovery is applied **per widget node**, not just at the root — a malformed card three levels
deep inside a `children: [...]` list only replaces that card; siblings render normally. Parse
errors (`LexerException`/`SyntaxException`) always throw, since there's no widget tree yet to
substitute a fallback into — use [`validate`](#validation-api) if you want a non-throwing
pre-flight check.

## Validation API

```dart
final ValidationResult result = DynamicWidgetParser.validate(source);
if (!result.isValid) {
  for (final issue in result.errors) print(issue);
}
```

`validate` requires no `BuildContext` and builds no widgets, so it's suitable for checking a
payload the moment it arrives from a server. It collects **every** issue it finds (unknown
widgets/constructors/values, unknown/missing/duplicate properties, unregistered action names
when the name is a literal string), not just the first — see `SemanticValidator`. It can't
evaluate `$expression`s (no `DynamicDataContext` yet) or run property-level
converters/validators; those still run at build time.

## Debugging

```dart
final AstNode ast = DynamicWidgetParser.parseToAst(source);
print(ast.prettyPrint());
```

```text
Column
 ├── mainAxisAlignment: center
 ├── Text
 │    ├── "Hello"
 │    └── style
 │         ├── fontSize: 20
 │         └── fontWeight: bold
 └── SizedBox
      └── height: 16
```

Set `DynamicParserConfig(enableDebugLogging: true)` to trace cache hits/misses and recovered
errors via `debugPrint`.

## Server-driven UI / JSON

The core requirement is parsing the Flutter-like DSL, but the AST (`WidgetNode`/`PropertyNode`/
`ValueNode`) is deliberately format-agnostic: nothing about `DynamicWidgetRegistry`,
`ValueResolver`, or `WidgetFactory` knows the AST came from text. A JSON payload like

```json
{"type": "Column", "properties": {"mainAxisAlignment": "center"},
 "children": [{"type": "Text", "properties": {"text": "Welcome"}}]}
```

maps mechanically onto the same `WidgetNode` shape (`type` -> `name`, `properties` -> a list of
`PropertyNode`s, `children` -> a `children` property whose value is a list of `WidgetNode`s) —
a JSON front end is a separate translator that produces the existing AST types, not a
parallel pipeline. This package ships the string DSL only; adding a JSON decoder is additive.

## Testing

```bash
flutter test
```

`test/` mirrors the pipeline: `lexer/` (tokens, escapes, interpolation, comments, errors),
`parser/` (widgets, nesting, lists/maps, trailing commas, syntax errors, resource limits),
`resolver/` (colors, enums, constructors, decorations, property validation), `expressions/`
(every operator, precedence, short-circuiting, type errors), `widgets/` (rendering via
`WidgetTester`, including action-triggered taps), `security/` (rejection of unregistered
names/actions, resource-limit enforcement, fallback recovery), `performance/` (LRU cache
behavior, parse timing), and `fuzz/` (random and mutation-based inputs, asserting the parser
never throws anything other than `DynamicParserException`). `example/` has its own
widget-tested demo app.

## Limitations

Read this section before depending on this package for something it wasn't designed for.

- **Not a Dart parser.** Only the subset in [Supported syntax](#supported-syntax) works — by
  design, not by omission. Anything else is a `SyntaxException`, never a silent
  misinterpretation.
- **No item-builder widgets.** `ListView.builder`/`GridView.builder` take an `itemBuilder`
  closure, which has no safe DSL representation; only the eagerly-materialized `children:`
  form is registered. For large lists, build the list of `Text`/`Card`/... nodes server-side
  (or client-side before parsing) instead.
- **No `TextEditingController`/`AnimationController`/etc.** See
  [Stateful widgets and keys](#stateful-widgets-and-keys) — controlled-component pattern only.
- **`Radio` uses the deprecated direct `groupValue`/`onChanged` API** rather than
  `RadioGroup`, because there's no way to declare an ancestor that injects group state from
  source text. Still functional; see the `// ignore: deprecated_member_use` comments in
  `input_widgets.dart` for the reasoning.
- **`CustomScrollView`/slivers, `NavigationBar`, `BottomNavigationBar`, `Drawer`** are not
  registered by default (not because they're hard — they just weren't prioritized). Add them
  via `registerWidget`/`registerWidgetDefinition` following the patterns in
  `lib/src/widgets/builtin/`.
- **The AST cache key is the source string only**, not the `DynamicParserLimits` used to
  parse it. If you call `parse` with different limits for identical source text across calls
  (unusual — limits are normally constant for an app), you may see a result parsed under
  whichever limits were in effect on the first call.
- **`maxParseDuration` is checked between parser productions, not preemptively** (there's no
  isolate/timer interrupting mid-token) — it bounds pathological inputs but isn't a hard
  real-time guarantee under extreme adversarial input.
- **`Image.network` fetches whatever URL is in the payload** the moment it's built, same as
  `<img src>` in server-rendered HTML — see the security note in `image_icon_widgets.dart`.

## Extending the parser

Everything below is additive — none of it touches `lib/src/lexer/`, `lib/src/parser/`, or
`lib/src/ast/`:

1. **New widget**: `registry.registerWidget(...)` or `registerWidgetDefinition(...)`.
2. **New value constructor** (like `EdgeInsets.all`): `registry.registerConstructor(...)`.
3. **New enum**: `registry.registerEnum<T>('Name', T.values)`.
4. **New named constant/color**: `registry.registerValue('Path.name', () => value)`.
5. **New action**: `ActionRegistry.register('name', callback)`.
6. **Alias**: `registry.registerAlias('Alias', 'Target')`.

For a fully isolated set of customizations (per test, per app variant), fork the shared
registry: `createStandardRegistry().fork()`.

## Dependencies

Runtime: only the Flutter SDK itself (`package:flutter`). No third-party packages — the lexer,
parser, expression evaluator, and registries are all hand-written; there was nothing here that
justified an external dependency. Dev-only: `flutter_test` and `flutter_lints`.
