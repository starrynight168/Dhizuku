import 'package:flutter/widgets.dart';
import 'package:prism_ui/color.dart' show ColorSchemeExtension;
import 'package:prism_ui/context.dart' show BuildContextExtension;
import 'package:prism_ui/prism_ui.dart' as prism;

import 'app_motion.dart';

Route<T> dhizukuPageRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  transitionDuration: AppMotion.pageEnterDuration,
  reverseTransitionDuration: AppMotion.pageExitDuration,
  pageBuilder: (context, _, _) => builder(context),
  transitionsBuilder: (context, animation, _, child) {
    final motion = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enterCurve,
      reverseCurve: AppMotion.exitCurve,
    );
    return FadeTransition(
      opacity: motion,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.045, 0.02),
          end: Offset.zero,
        ).animate(motion),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.975, end: 1).animate(motion),
          child: child,
        ),
      ),
    );
  },
);

Future<T?> showDhizukuDialog<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool dismissible = true,
}) => showGeneralDialog<T>(
  context: context,
  barrierColor: context.colorScheme.alertScrim,
  barrierDismissible: dismissible,
  barrierLabel: dismissible ? prism.UiLocalizations.of(context).close : null,
  transitionDuration: AppMotion.durationFor(context, AppMotion.dialogDuration),
  pageBuilder: (dialogContext, _, _) => SafeArea(
    child: Center(
      child: Builder(
        builder: (scopeContext) => prism.SurfaceScope(
          level: prism.SurfaceLevel.floatingOf(
            prism.Theme.of(scopeContext).colorScheme,
          ),
          child: Builder(builder: builder),
        ),
      ),
    ),
  ),
  transitionBuilder: (context, animation, _, child) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enterCurve,
      reverseCurve: AppMotion.exitCurve,
    );
    final spring = CurvedAnimation(
      parent: animation,
      curve: AppMotion.dialogSpringCurve,
      reverseCurve: AppMotion.dialogSpringCurve.flipped,
    );
    return prism.LiquidGlassFade(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(spring),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(spring),
          child: child,
        ),
      ),
    );
  },
);

Future<T?> showDhizukuBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
}) => showGeneralDialog<T>(
  context: context,
  barrierColor: context.colorScheme.modalScrim,
  barrierDismissible: true,
  barrierLabel: prism.UiLocalizations.of(context).close,
  transitionDuration: AppMotion.durationFor(
    context,
    AppMotion.bottomSheetDuration,
  ),
  pageBuilder: (sheetContext, _, _) {
    final content = Builder(
      builder: (scopeContext) => prism.SurfaceScope(
        level: prism.SurfaceLevel.floatingOf(
          prism.Theme.of(scopeContext).colorScheme,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Builder(builder: builder),
        ),
      ),
    );
    return useSafeArea ? SafeArea(bottom: false, child: content) : content;
  },
  transitionBuilder: (context, animation, _, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enterCurve,
      reverseCurve: AppMotion.exitCurve,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
);
