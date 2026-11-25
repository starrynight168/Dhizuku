import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:prism_ui/icons/icons.dart' show Glyph, GlyphIcon;
import 'package:prism_ui/prism_ui.dart' as prism;

import 'api.dart';
import 'app_components.dart';
import 'app_motion.dart';
import 'app_navigation.dart';
import 'app_typography.dart';
import 'appearance.dart';
import 'glyphs.dart';
import 'pages.dart';
import 'press_feedback.dart';
import 'prism_localizations.dart';
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

class _DhizukuAppState extends State<DhizukuApp> with WidgetsBindingObserver {
  final AppearanceSettings _appearance = AppearanceSettings();
  late final Listenable _rebuildListenable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rebuildListenable = Listenable.merge([
      _appearance,
      AppTypography.weightAdjustment,
    ]);
    unawaited(_appearance.load());
    unawaited(AppTypography.refreshSystemWeightAdjustment());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AppTypography.refreshSystemWeightAdjustment());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rebuildListenable,
      builder: (context, _) => prism.PrismApp(
        debugShowCheckedModeBanner: false,
        title: 'Dhizuku',
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: _appearance.themeMode,
        liquidGlass: prism.LiquidGlassQuality.standard,
        localizationsDelegates: const [
          DhizukuPrismLocalizationsDelegate(),
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('zh')],
        home: BootstrapPage(appearance: _appearance),
      ),
    );
  }

  prism.ThemeData _theme(Brightness brightness) {
    final scheme = prism.seededColorScheme(
      seedColor: _appearance.activeSeedColor,
      brightness: brightness,
      style: _colorStyle,
    );
    return prism.ThemeData(
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamilyFor(defaultTargetPlatform),
      fontWeightDelta: AppTypography.fontWeightDelta,
      fontSizeFactor: AppTypography.fontSizeScale,
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
          return DhizukuScaffold(
            body: Center(
              child: Text('${tr(context, 'error')}: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const DhizukuScaffold(
            body: Center(child: prism.ActivityIndicator.page()),
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
    final color = prism.Theme.of(context).colorScheme;
    return DhizukuScaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DhizukuCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlyphIcon(
                        DhizukuGlyphs.adminShield,
                        size: 36,
                        color: color.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        tr(context, 'agreement_title'),
                        style: prism.AppTextStyle.title2.of(
                          context,
                          emphasized: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr(context, 'agreement_text'),
                        style: prism.AppTextStyle.body.of(context),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          DhizukuTextButton(
                            onPressed: () => DhizukuApi.openUrl(
                              'https://iamr0s.github.io/Dhizuku/TERMS.html',
                            ),
                            child: Text(tr(context, 'terms')),
                          ),
                          DhizukuTextButton(
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
                        child: DhizukuPressFeedback(
                          enabled: !_saving,
                          child: prism.FilledButton(
                            onPressed: _saving ? null : _agree,
                            child: _saving
                                ? prism.ActivityIndicator(
                                    size: 18,
                                    color: color.onPrimary,
                                  )
                                : Text(tr(context, 'agree')),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: DhizukuTextButton(
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
        : const DhizukuScaffold(
            body: Center(child: prism.ActivityIndicator.page()),
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
  OverlayEntry? _backPromptEntry;
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
        duration: AppMotion.tabPageDuration,
        curve: AppMotion.sheetCurve,
      ),
    );
  }

  void _handleBackPress() {
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) <= const Duration(seconds: 1)) {
      _clearBackExitPrompt();
      SystemNavigator.pop();
      return;
    }
    _clearBackExitPrompt();
    _lastBackPress = now;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final bottomOffset = wide ? 16.0 : prism.NavigationDock.insetOf(context) + 16;
    final promptText = tr(context, 'press_back_again_to_exit');
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: bottomOffset,
        child: IgnorePointer(
          child: _BackExitPromptCard(text: promptText),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    _backPromptEntry = entry;
    _backPromptTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || _lastBackPress != now) return;
      _clearBackExitPrompt();
    });
  }

  void _clearBackExitPrompt() {
    _lastBackPress = null;
    _backPromptTimer?.cancel();
    _backPromptTimer = null;
    _backPromptEntry?.remove();
    _backPromptEntry = null;
  }

  @override
  void dispose() {
    _clearBackExitPrompt();
    _pageController.dispose();
    _dockSelected.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['home', 'apps', 'users', 'settings'];
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
    final colors = prism.Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final title = tr(context, labels[_selected]);
    final scaffold = DhizukuScaffold(
      appBar: DhizukuAppBar(
        automaticallyImplyLeading: false,
        title: AnimatedSwitcher(
          duration: AppMotion.navigationTitleDuration,
          switchInCurve: AppMotion.enterCurve,
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
              icon: const GlyphIcon(DhizukuGlyphs.heart),
            ),
          if (_selected == 0)
            DhizukuIconButton(
              tooltip: tr(context, 'shutdown'),
              onPressed: _confirmShutdown,
              icon: const GlyphIcon(DhizukuGlyphs.power),
            ),
        ],
      ),
      body: Row(
        children: [
          if (wide) ...[
            SizedBox(
              width: 88,
              child: SafeArea(
                right: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: Column(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < labels.length; i++)
                        _SideRailItem(
                          glyph: glyphs[i],
                          label: tr(context, labels[i]),
                          selected: i == _selected,
                          onPressed: () => _selectPage(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Container(width: 1, color: colors.outlineVariant),
          ],
          Expanded(
            child: prism.Surface(
              color: prism.SurfaceLevel.page.colorOf(colors),
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
    showDhizukuBanner(
      context,
      '${tr(context, 'error')}: $error',
      level: prism.BannerLevel.error,
    );
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

class _SideRailItem extends StatelessWidget {
  const _SideRailItem({
    required this.glyph,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final Glyph glyph;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = prism.Theme.of(context).colorScheme;
    final foreground = selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;
    return DhizukuPressSurface(
      fill: selected ? colors.secondaryContainer : prism.Colors.transparent,
      shape: prism.AppShape.xl,
      look: selected ? prism.PressLook.none : prism.PressLook.tint,
      selected: selected,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            GlyphIcon(glyph, size: 22, color: foreground),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: prism.AppTextStyle.caption2
                  .of(context, emphasized: selected)
                  .copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

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
  )..animateWith(SpringSimulation(AppMotion.selectionSpring, 0.88, 1, 0));

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
              style: prism.AppTextStyle.body.of(context).copyWith(
                color: colors.onSurface,
                fontWeight: AppTypography.adjustFontWeight(FontWeight.w600),
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
