import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:prism_ui/prism_ui.dart' as prism;

import 'api.dart';
import 'appearance.dart';
import 'glyphs.dart';
import 'pages.dart';
import 'texts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DhizukuApp());
}

class DhizukuApp extends StatefulWidget {
  const DhizukuApp({super.key});

  @override
  State<DhizukuApp> createState() => _DhizukuAppState();
}

class _DhizukuAppState extends State<DhizukuApp> {
  final AppearanceSettings _appearance = AppearanceSettings();

  @override
  void initState() {
    super.initState();
    unawaited(_appearance.load());
  }

  @override
  void dispose() {
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appearance,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dhizuku',
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: _appearance.themeMode,
        themeAnimationDuration: const Duration(milliseconds: 420),
        themeAnimationCurve: Curves.easeInOutCubic,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en'), Locale('zh')],
        home: BootstrapPage(appearance: _appearance),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final prismScheme = prism.seededColorScheme(
      seedColor: _appearance.activeSeedColor,
      brightness: brightness,
      style: _colorStyle,
    );
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: prismScheme.primary,
      onPrimary: prismScheme.onPrimary,
      primaryContainer: prismScheme.primaryContainer,
      onPrimaryContainer: prismScheme.onPrimaryContainer,
      secondary: prismScheme.secondary,
      onSecondary: prismScheme.onSecondary,
      secondaryContainer: prismScheme.secondaryContainer,
      onSecondaryContainer: prismScheme.onSecondaryContainer,
      tertiary: prismScheme.tertiary,
      onTertiary: prismScheme.onTertiary,
      tertiaryContainer: prismScheme.tertiaryContainer,
      onTertiaryContainer: prismScheme.onTertiaryContainer,
      error: prismScheme.error,
      onError: prismScheme.onError,
      errorContainer: prismScheme.errorContainer,
      onErrorContainer: prismScheme.onErrorContainer,
      surface: prismScheme.surface,
      onSurface: prismScheme.onSurface,
      surfaceDim: prismScheme.surfaceDim,
      surfaceBright: prismScheme.surfaceBright,
      surfaceContainerLowest: prismScheme.surfaceContainerLowest,
      surfaceContainerLow: prismScheme.surfaceContainerLow,
      surfaceContainer: prismScheme.surfaceContainer,
      surfaceContainerHigh: prismScheme.surfaceContainerHigh,
      surfaceContainerHighest: prismScheme.surfaceContainerHighest,
      onSurfaceVariant: prismScheme.onSurfaceVariant,
      outline: prismScheme.outline,
      outlineVariant: prismScheme.outlineVariant,
      shadow: prismScheme.shadow,
      scrim: prismScheme.scrim,
      inverseSurface: prismScheme.inverseSurface,
      onInverseSurface: prismScheme.onInverseSurface,
      inversePrimary: prismScheme.inversePrimary,
      surfaceTint: prismScheme.surfaceTint,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: prism.AppShape.xxl,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  prism.ColorStyle get _colorStyle => prism.ColorStyle.values.firstWhere(
    (style) => style.name == _appearance.colorStyle,
    orElse: () => prism.ColorStyle.vivid,
  );
}

class BootstrapPage extends StatefulWidget {
  const BootstrapPage({required this.appearance, super.key});

  final AppearanceSettings appearance;

  @override
  State<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  late Future<Map<String, dynamic>> _initial;

  @override
  void initState() {
    super.initState();
    _initial = DhizukuApi.getInitialData();
    DhizukuApi.setNativeCallHandler((call) async {
      if (call.method != 'permissionRequestChanged' || !mounted) return;
      setState(() {
        _initial = Future.value({
          'screen': 'permission',
          'request': Map<String, dynamic>.from(call.arguments as Map),
        });
      });
    });
  }

  @override
  void dispose() {
    DhizukuApi.setNativeCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _initial,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('${tr(context, 'error')}: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        final data = snapshot.data!;
        if (data['screen'] == 'permission') {
          return PermissionRequestPage(
            key: ValueKey(
              (data['request'] as Map<String, dynamic>?)?['requestId'],
            ),
            data: data['request'] as Map<String, dynamic>? ?? const {},
          );
        }
        if (data['agreementAccepted'] != true) {
          return AgreementPage(appearance: widget.appearance);
        }
        return DhizukuShell(initialData: data, appearance: widget.appearance);
      },
    );
  }
}

class AgreementPage extends StatefulWidget {
  const AgreementPage({required this.appearance, super.key});

  final AppearanceSettings appearance;

  @override
  State<AgreementPage> createState() => _AgreementPageState();
}

class _AgreementPageState extends State<AgreementPage> {
  bool _saving = false;

  Future<void> _agree() async {
    setState(() => _saving = true);
    await DhizukuApi.acceptAgreement();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        dhizukuPageRoute<void>(
          (_) => _AcceptedShell(appearance: widget.appearance),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 36,
                        color: color.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        tr(context, 'agreement_title'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr(context, 'agreement_text'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => DhizukuApi.openUrl(
                              'https://iamr0s.github.io/Dhizuku/TERMS.html',
                            ),
                            child: Text(tr(context, 'terms')),
                          ),
                          TextButton(
                            onPressed: () => DhizukuApi.openUrl(
                              'https://iamr0s.github.io/Dhizuku/PRIVACY.html',
                            ),
                            child: Text(tr(context, 'privacy')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _agree,
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(tr(context, 'agree')),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: SystemNavigator.pop,
                          child: Text(tr(context, 'cancel')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AcceptedShell extends StatelessWidget {
  const _AcceptedShell({required this.appearance});

  final AppearanceSettings appearance;

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: DhizukuApi.getInitialData(),
    builder: (context, snapshot) => snapshot.hasData
        ? DhizukuShell(initialData: snapshot.data!, appearance: appearance)
        : const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          ),
  );
}

class DhizukuShell extends StatefulWidget {
  const DhizukuShell({
    required this.initialData,
    required this.appearance,
    super.key,
  });

  final Map<String, dynamic> initialData;
  final AppearanceSettings appearance;

  @override
  State<DhizukuShell> createState() => _DhizukuShellState();
}

class _DhizukuShellState extends State<DhizukuShell> {
  int _selected = 0;
  final PageController _pageController = PageController();
  late Map<String, dynamic> _homeData = widget.initialData;
  late Map<String, dynamic> _settings = Map<String, dynamic>.from(
    widget.initialData['settings'] as Map? ?? const {},
  );

  Future<void> _refresh() async {
    final values = await DhizukuApi.getInitialData();
    if (mounted) {
      setState(() {
        _homeData = values;
        _settings = Map<String, dynamic>.from(
          values['settings'] as Map? ?? const {},
        );
      });
    }
  }

  void _selectPage(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['home', 'apps', 'users', 'settings'];
    final icons = [
      Icons.dashboard_outlined,
      Icons.apps_outlined,
      Icons.group_outlined,
      Icons.settings_outlined,
    ];
    final glyphs = [
      DhizukuGlyphs.dashboard,
      DhizukuGlyphs.apps,
      DhizukuGlyphs.users,
      DhizukuGlyphs.settings,
    ];
    final pages = [
      HomePage(data: _homeData, onRefresh: _refresh, onNavigate: _selectPage),
      AppManagementPage(onError: (error) => _showError(error)),
      UserManagementPage(onError: (error) => _showError(error)),
      SettingsPage(
        settings: _settings,
        appearance: widget.appearance,
        onChanged: (value) => setState(() => _settings = value),
      ),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final title = tr(context, labels[_selected]);
    return Scaffold(
      extendBody: !wide,
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.14),
                end: Offset.zero,
              ).animate(animation),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
                child: child,
              ),
            ),
          ),
          child: Text(title, key: ValueKey(_selected)),
        ),
        actions: [
          if (_selected == 0 && _settings['donateButtonHidden'] != true)
            IconButton(
              tooltip: tr(context, 'donate'),
              onPressed: () => DhizukuApi.openUrl(tr(context, 'donation_url')),
              icon: const Icon(Icons.favorite_outline),
            ),
          if (_selected == 0)
            IconButton(
              tooltip: tr(context, 'shutdown'),
              onPressed: _confirmShutdown,
              icon: const Icon(Icons.power_settings_new),
            ),
        ],
      ),
      body: Row(
        children: [
          if (wide) ...[
            NavigationRail(
              selectedIndex: _selected,
              onDestinationSelected: _selectPage,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationRailDestination(
                    icon: Icon(icons[i]),
                    label: Text(tr(context, labels[i])),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: prism.Theme(
              data: prism.ThemeData(
                colorScheme: prism.seededColorScheme(
                  seedColor: widget.appearance.activeSeedColor,
                  brightness: Theme.of(context).brightness,
                  style: _colorStyle,
                ),
              ),
              child: prism.Surface(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: wide
                              ? 0
                              : prism.NavigationDock.insetOf(context),
                        ),
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (var index = 0; index < pages.length; index++)
                              _RetainedTab(
                                key: ValueKey(index),
                                active: index == _selected,
                                child: pages[index],
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (!wide)
                      PositionedDirectional(
                        start: 0,
                        end: 0,
                        bottom: 0,
                        child: prism.NavigationDock(
                          destinations: [
                            for (var index = 0; index < labels.length; index++)
                              prism.NavigationDockDestination(
                                glyph: glyphs[index],
                                label: tr(context, labels[index]),
                              ),
                          ],
                          selectedIndex: _selected,
                          onSelected: _selectPage,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${tr(context, 'error')}: $error')));
  }

  prism.ColorStyle get _colorStyle => prism.ColorStyle.values.firstWhere(
    (style) => style.name == widget.appearance.colorStyle,
    orElse: () => prism.ColorStyle.vivid,
  );

  Future<void> _confirmShutdown() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'shutdown')),
        content: Text(tr(context, 'home_shutdown_dsp')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'confirm')),
          ),
        ],
      ),
    );
    if (confirm == true) await DhizukuApi.shutdown();
  }
}

class _RetainedTab extends StatefulWidget {
  const _RetainedTab({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_RetainedTab> createState() => _RetainedTabState();
}

class _RetainedTabState extends State<_RetainedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return TickerMode(enabled: widget.active, child: widget.child);
  }
}
