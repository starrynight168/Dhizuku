import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:prism_ui/prism_ui.dart' as prism;

import 'api.dart';
import 'appearance.dart';
import 'glyphs.dart';
import 'pages.dart';
import 'press_feedback.dart';
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
        themeAnimationDuration: Duration.zero,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en'), Locale('zh')],
        home: BootstrapPage(appearance: _appearance),
        builder: (context, child) {
          final scheme = prism.seededColorScheme(
            seedColor: _appearance.activeSeedColor,
            brightness: Theme.of(context).brightness,
            style: _colorStyle,
          );
          return prism.Theme(
            data: prism.ThemeData(colorScheme: scheme),
            child: prism.LiquidGlassScope(
              enabled: true,
              quality: prism.LiquidGlassQuality.standard,
              child: prism.LiquidGlassHost(
                enabled: true,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
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
        backgroundColor: colorScheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        actionTextColor: colorScheme.primary,
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
                          DhizukuPressFeedback(
                            child: TextButton(
                              onPressed: () => DhizukuApi.openUrl(
                                'https://iamr0s.github.io/Dhizuku/TERMS.html',
                              ),
                              child: Text(tr(context, 'terms')),
                            ),
                          ),
                          DhizukuPressFeedback(
                            child: TextButton(
                              onPressed: () => DhizukuApi.openUrl(
                                'https://iamr0s.github.io/Dhizuku/PRIVACY.html',
                              ),
                              child: Text(tr(context, 'privacy')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: DhizukuPressFeedback(
                          enabled: !_saving,
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
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: DhizukuPressFeedback(
                          child: TextButton(
                            onPressed: SystemNavigator.pop,
                            child: Text(tr(context, 'cancel')),
                          ),
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
  DateTime? _lastBackPress;
  Timer? _backPromptTimer;
  bool _programmaticPageChange = false;
  final PageController _pageController = PageController();
  final ValueNotifier<int> _dockSelected = ValueNotifier(0);
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
    if (index < 0 || index >= 4) return;
    if (_selected != index) {
      _clearBackExitPrompt();
    }
    if (!_pageController.hasClients) return;
    if (_pageController.page?.round() == index) return;
    _programmaticPageChange = true;
    _dockSelected.value = index;
    unawaited(
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  void _handleBackPress() {
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) <= const Duration(seconds: 1)) {
      _clearBackExitPrompt();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemNavigator.pop();
      return;
    }
    _backPromptTimer?.cancel();
    _lastBackPress = now;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          content: _BackExitPromptCard(
            text: tr(context, 'press_back_again_to_exit'),
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            wide ? 16 : prism.NavigationDock.insetOf(context) + 16,
          ),
        ),
      );
    _backPromptTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || _lastBackPress != now) return;
      _clearBackExitPrompt();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  void _clearBackExitPrompt() {
    _lastBackPress = null;
    _backPromptTimer?.cancel();
    _backPromptTimer = null;
  }

  @override
  void dispose() {
    _backPromptTimer?.cancel();
    _pageController.dispose();
    _dockSelected.dispose();
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
      HomePage(
        data: _homeData,
        active: _selected == 0,
        onRefresh: _refresh,
        onNavigate: _selectPage,
      ),
      AppManagementPage(
        active: _selected == 1,
        onError: (error) => _showError(error),
      ),
      UserManagementPage(
        active: _selected == 2,
        onError: (error) => _showError(error),
      ),
      SettingsPage(
        settings: _settings,
        appearance: widget.appearance,
        active: _selected == 3,
        onChanged: (value) => setState(() => _settings = value),
      ),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final title = tr(context, labels[_selected]);
    final scaffold = Scaffold(
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
            DhizukuIconButton(
              tooltip: tr(context, 'donate'),
              onPressed: () => DhizukuApi.openUrl(tr(context, 'donation_url')),
              icon: const Icon(Icons.favorite_outline),
            ),
          if (_selected == 0)
            DhizukuIconButton(
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
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          final metrics = notification.metrics;
                          if (metrics is! PageMetrics) return false;
                          if (notification is ScrollStartNotification &&
                              notification.dragDetails != null) {
                            _programmaticPageChange = false;
                          }
                          if (notification is! ScrollEndNotification) {
                            return false;
                          }
                          final index = metrics.page?.round();
                          if (index == null) return false;
                          _programmaticPageChange = false;
                          if (_dockSelected.value != index) {
                            _dockSelected.value = index;
                          }
                          if (index == _selected) return false;
                          _clearBackExitPrompt();
                          setState(() => _selected = index);
                          return false;
                        },
                        child: PageView(
                          controller: _pageController,
                          physics: const PageScrollPhysics(),
                          onPageChanged: (index) {
                            if (!_programmaticPageChange &&
                                _dockSelected.value != index) {
                              _dockSelected.value = index;
                            }
                          },
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
                  ),
                  if (!wide)
                    PositionedDirectional(
                      start: 0,
                      end: 0,
                      bottom: 0,
                      child: ValueListenableBuilder<int>(
                        valueListenable: _dockSelected,
                        builder: (context, selectedIndex, _) =>
                            prism.NavigationDock(
                              destinations: [
                                for (
                                  var index = 0;
                                  index < labels.length;
                                  index++
                                )
                                  prism.NavigationDockDestination(
                                    glyph: glyphs[index],
                                    label: tr(context, labels[index]),
                                  ),
                              ],
                              selectedIndex: selectedIndex,
                              onSelected: _selectPage,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPress();
      },
      child: scaffold,
    );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${tr(context, 'error')}: $error')));
  }

  Future<void> _confirmShutdown() async {
    final confirm = await showDhizukuDialog<bool>(
      context,
      (context) => prism.AlertDialog(
        title: tr(context, 'shutdown'),
        destructive: true,
        actions: [
          DhizukuTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          DhizukuTextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'confirm')),
          ),
        ],
        child: Text(tr(context, 'home_shutdown_dsp')),
      ),
    );
    if (confirm == true) {
      try {
        await DhizukuApi.shutdown();
      } catch (error) {
        if (mounted) _showError(error);
      }
    }
  }
}

final _backPromptSpring = SpringDescription.withDurationAndBounce(
  duration: const Duration(milliseconds: 420),
  bounce: 0.15,
);

class _BackExitPromptCard extends StatefulWidget {
  const _BackExitPromptCard({required this.text});

  final String text;

  @override
  State<_BackExitPromptCard> createState() => _BackExitPromptCardState();
}

class _BackExitPromptCardState extends State<_BackExitPromptCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 0.88,
  )..animateWith(SpringSimulation(_backPromptSpring, 0.88, 1, 0));

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = prism.Theme.of(context).colorScheme;
    return Center(
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 8 * (1 - _scale.value)),
          child: Transform.scale(scale: _scale.value, child: child),
        ),
        child: prism.LiquidGlass(
          style: prism.LiquidGlassStyle.banner(colors),
          borderRadius: BorderRadius.circular(24),
          steadyFrost: true,
          shadows: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
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
