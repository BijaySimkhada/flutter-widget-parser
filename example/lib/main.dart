import 'package:dynamic_widget_parser/dynamic_widget_parser.dart';
import 'package:flutter/material.dart';

void main() {
  registerActions();
  runApp(const DemoApp());
}

/// Actions are registered once, at app startup, against the package's
/// shared default registry. Remote UI can only ever trigger callbacks
/// registered here by name — see the README's "Security model" section.
///
/// Exposed (not private) so widget tests can call it too, since tests
/// drive [DemoApp] directly without going through [main].
void registerActions() {
  DynamicWidgetParser.defaultActions
    ..register('openProfile', (
      BuildContext context,
      Map<String, Object?> args,
    ) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Opening profile…')));
    })
    ..register('login', (BuildContext context, Map<String, Object?> args) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logging in…')));
    })
    ..register('showMessage', (
      BuildContext context,
      Map<String, Object?> args,
    ) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${args['text']}')));
    });
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dynamic_widget_parser example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _HomeTabs(),
    );
  }
}

class _HomeTabs extends StatefulWidget {
  const _HomeTabs();

  @override
  State<_HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<_HomeTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dynamic_widget_parser'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Tab>[
            Tab(text: 'Server-driven screen'),
            Tab(text: 'Live playground'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[_ServerDrivenScreenDemo(), _PlaygroundDemo()],
      ),
    );
  }
}

/// Simulates receiving a screen definition from a server and rendering it —
/// exactly the "String source -> real Flutter Widget" flow described in the
/// package README. [DynamicDataContext] stands in for whatever the app
/// already knows locally (current user, theme, etc.) that remote UI is
/// allowed to reference via `$variable.path` expressions.
class _ServerDrivenScreenDemo extends StatelessWidget {
  const _ServerDrivenScreenDemo();

  static const String _serverResponse = r'''
Padding(
  padding: EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        "Welcome",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
      SizedBox(height: 16),
      Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.indigo,
                child: Icon(Icons.person, size: 36, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text("John Doe"),
              SizedBox(height: 4),
              Text($user.isLoggedIn ? "Signed in" : "Signed out"),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: action("openProfile", {"userId": $user.id}),
                child: Text("View Profile"),
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: 16),
      Text("This screen was rendered from a plain Dart string — see example/lib/main.dart."),
    ],
  ),
)
''';

  @override
  Widget build(BuildContext context) {
    final DynamicDataContext data = DynamicDataContext(
      values: <String, Object?>{
        'user': <String, Object?>{'id': 42, 'isLoggedIn': true},
      },
    );

    return SingleChildScrollView(
      child: DynamicWidgetParser.parse(
        source: _serverResponse,
        context: context,
        data: data,
        config: const DynamicParserConfig(
          errorBehavior: DynamicErrorBehavior.fallback,
        ),
      ),
    );
  }
}

/// A live editor for trying out the DSL: type source text, see it validated
/// and rendered immediately, with structured errors surfaced inline instead
/// of a crash — this is [DynamicWidgetParser.validate] and
/// [DynamicErrorBehavior.fallback] in action.
class _PlaygroundDemo extends StatefulWidget {
  const _PlaygroundDemo();

  @override
  State<_PlaygroundDemo> createState() => _PlaygroundDemoState();
}

class _PlaygroundDemoState extends State<_PlaygroundDemo> {
  static const String _initialSource = '''
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.amber.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.amber, width: 2),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.info, color: Colors.amber),
      SizedBox(width: 12),
      Expanded(
        child: Text("Edit the source on the left and watch this update."),
      ),
    ],
  ),
)
''';

  late final TextEditingController _controller = TextEditingController(
    text: _initialSource,
  );
  String _source = _initialSource;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ValidationResult validation = DynamicWidgetParser.validate(_source);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'DSL source',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String value) =>
                        setState(() => _source = value),
                  ),
                ),
                if (!validation.isValid) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    validation.errors
                        .map((ValidationIssue i) => i.toString())
                        .join('\n'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Rendered result',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: DynamicWidgetParser.parse(
                      source: _source,
                      context: context,
                      config: const DynamicParserConfig(
                        errorBehavior: DynamicErrorBehavior.fallback,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
