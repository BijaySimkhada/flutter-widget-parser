import '../../registry/dynamic_widget_registry.dart';
import '../../resolver/built_in_colors.dart';
import '../../resolver/built_in_constructors.dart';
import '../../resolver/built_in_enums.dart';
import '../../resolver/built_in_icons.dart';
import 'button_widgets.dart';
import 'image_icon_widgets.dart';
import 'input_widgets.dart';
import 'layout_widgets.dart';
import 'material_widgets.dart';
import 'scroll_widgets.dart';
import 'text_widgets.dart';

/// Populates [registry] with every built-in value (colors, enums, icons),
/// constructor (`EdgeInsets.all`, `TextStyle`, ...), and widget this
/// package ships. This is the one function that knows about the *whole*
/// built-in set — everything it calls is a plain, independent registration
/// function, so adding a new built-in widget/value never means editing the
/// lexer, parser, or resolver.
void registerBuiltIns(DynamicWidgetRegistry registry) {
  registerBuiltInEnums(registry);
  registerBuiltInColors(registry);
  registerBuiltInIcons(registry);
  registerBuiltInConstructors(registry);

  registerLayoutWidgets(registry);
  registerScrollWidgets(registry);
  registerTextWidgets(registry);
  registerButtonWidgets(registry);
  registerImageAndIconWidgets(registry);
  registerMaterialWidgets(registry);
  registerInputWidgets(registry);
}

/// Creates a fresh [DynamicWidgetRegistry] pre-populated with every
/// built-in. Applications typically call this once and [DynamicWidgetRegistry.fork]
/// it to layer app-specific widgets/values on top without mutating the
/// shared base:
/// ```dart
/// final DynamicWidgetRegistry appRegistry = createStandardRegistry().fork()
///   ..registerWidget('UserCard', (context, props, children) => UserCard(...));
/// ```
DynamicWidgetRegistry createStandardRegistry() {
  final DynamicWidgetRegistry registry = DynamicWidgetRegistry();
  registerBuiltIns(registry);
  return registry;
}
