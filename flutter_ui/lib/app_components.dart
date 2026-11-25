import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:prism_ui/icons/icons.dart' show GlyphIcon, Glyphs;
import 'package:prism_ui/prism_ui.dart' as prism;

import 'app_motion.dart';
import 'app_typography.dart';
import 'press_feedback.dart';

class DhizukuScaffold extends StatelessWidget {
  const DhizukuScaffold({
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  final Widget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final colors = prism.Theme.of(context).colorScheme;
    final resolvedBackground =
        backgroundColor ?? prism.SurfaceLevel.page.colorOf(colors);
    final bottomInset = resizeToAvoidBottomInset
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;
    Widget content = appBar != null
        ? MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: body,
          )
        : body;
    if (resizeToAvoidBottomInset && bottomInset > 0) {
      content = Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: content,
        ),
      );
    }
    return prism.Surface(
      color: resolvedBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?appBar,
          Expanded(child: content),
        ],
      ),
    );
  }
}

class DhizukuAppBar extends StatelessWidget {
  const DhizukuAppBar({
    required this.title,
    this.actions = const [],
    this.leading,
    this.automaticallyImplyLeading = true,
    super.key,
  });

  final Widget title;
  final List<Widget> actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    final canPop = automaticallyImplyLeading && Navigator.of(context).canPop();
    final effectiveLeading =
        leading ??
        (canPop
            ? DhizukuIconButton(
                tooltip: prism.UiLocalizations.of(context).back,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const GlyphIcon(Glyphs.arrowBack),
              )
            : null);
    return prism.AppBar(
      leading: effectiveLeading,
      title: title,
      actions: actions,
    );
  }
}

class DhizukuCard extends StatelessWidget {
  const DhizukuCard({
    required this.child,
    this.margin,
    this.shape,
    this.onPressed,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final OutlinedBorder? shape;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final card = prism.Card(
      inert: onPressed == null,
      onPressed: onPressed,
      shape: shape ?? prism.AppShape.xxl,
      child: child,
    );
    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}

class DhizukuDivider extends StatelessWidget {
  const DhizukuDivider({
    this.height = 1,
    this.thickness = 1,
    this.indent = 0,
    this.endIndent = 0,
    super.key,
  });

  final double height;
  final double thickness;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final divider = prism.Divider(height: height, thickness: thickness);
    if (indent == 0 && endIndent == 0) return divider;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: divider,
    );
  }
}

class DhizukuTonalButton extends StatelessWidget {
  const DhizukuTonalButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.padding,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget label;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = prism.Theme.of(context).colorScheme;
    final style = prism.ButtonStyle.from(
      foregroundColor: colors.onSecondaryContainer,
      backgroundColor: colors.secondaryContainer,
      disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
      disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.12),
      shape: const StadiumBorder(),
      padding: padding,
    );
    return DhizukuPressFeedback(
      enabled: onPressed != null,
      child: icon == null
          ? prism.FilledButton(onPressed: onPressed, style: style, child: label)
          : prism.FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: icon!,
              label: label,
            ),
    );
  }
}

class DhizukuTonalIconButton extends StatelessWidget {
  const DhizukuTonalIconButton({
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.foregroundColor,
    this.backgroundColor,
    this.fixedSize = const Size(52, 40),
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Size fixedSize;

  @override
  Widget build(BuildContext context) {
    final colors = prism.Theme.of(context).colorScheme;
    final style = prism.ButtonStyle.from(
      foregroundColor: foregroundColor ?? colors.onSecondaryContainer,
      backgroundColor: backgroundColor ?? colors.secondaryContainer,
      disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
      disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.12),
      fixedSize: fixedSize,
      shape: const StadiumBorder(),
    );
    return DhizukuPressFeedback(
      enabled: onPressed != null,
      child: prism.IconButton.filled(
        onPressed: onPressed,
        icon: icon,
        tooltip: tooltip,
        style: style,
      ),
    );
  }
}

class DhizukuLabeledField extends StatelessWidget {
  const DhizukuLabeledField({
    this.labelText,
    required this.child,
    super.key,
  });

  final String? labelText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = labelText;
    if (label == null || label.isEmpty) return child;
    final colors = prism.Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: prism.AppTextStyle.footnote
                .of(context, emphasized: true)
                .copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        child,
      ],
    );
  }
}

class DhizukuRefreshView extends StatefulWidget {
  const DhizukuRefreshView({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<DhizukuRefreshView> createState() => _DhizukuRefreshViewState();
}

class _DhizukuRefreshViewState extends State<DhizukuRefreshView> {
  static const _triggerOffset = 72.0;

  double _pullExtent = 0;
  bool _dragging = false;
  bool _armed = false;
  bool _refreshing = false;

  Future<void> _triggerRefresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _pullExtent = 0;
      _dragging = false;
      _armed = false;
    });
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (_refreshing) return false;
    if (notification is ScrollStartNotification) {
      final atTop =
          notification.metrics.pixels <= notification.metrics.minScrollExtent + 1;
      _dragging = notification.dragDetails != null && atTop;
      _armed = false;
      if (_pullExtent != 0) {
        setState(() => _pullExtent = 0);
      }
    } else if (notification is ScrollUpdateNotification) {
      if (!_dragging || notification.dragDetails == null) {
        if (_dragging) {
          _dragging = false;
        }
        if (_pullExtent != 0 && !_armed) {
          setState(() => _pullExtent = 0);
        }
        return false;
      }
      final over = notification.metrics.minScrollExtent - notification.metrics.pixels;
      if (over > 0) {
        _armed = over >= _triggerOffset;
        if (over != _pullExtent) {
          setState(() => _pullExtent = over);
        }
      } else if (_pullExtent != 0) {
        _armed = false;
        setState(() => _pullExtent = 0);
      }
    } else if (notification is OverscrollNotification) {
      if (_dragging &&
          notification.dragDetails != null &&
          notification.overscroll < 0) {
        final next = _pullExtent + (-notification.overscroll);
        _armed = next >= _triggerOffset;
        setState(() => _pullExtent = next);
      } else if (notification.dragDetails == null && _dragging) {
        _dragging = false;
      }
    } else if (notification is ScrollEndNotification) {
      final shouldRefresh = _armed;
      _dragging = false;
      _armed = false;
      if (shouldRefresh) {
        unawaited(_triggerRefresh());
      } else if (_pullExtent != 0) {
        setState(() => _pullExtent = 0);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final showBar = _refreshing || _pullExtent > 20;
    return Column(
      children: [
        AnimatedContainer(
          duration: AppMotion.contentSwitchDuration,
          curve: AppMotion.enterCurve,
          height: showBar ? 36 : 0,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: showBar
              ? Center(
                  child: prism.ActivityIndicator(
                    size: 18,
                    color: prism.Theme.of(context).colorScheme.primary,
                  ),
                )
              : null,
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

void showDhizukuBanner(
  BuildContext context,
  String message, {
  prism.BannerLevel level = prism.BannerLevel.info,
}) {
  prism.BannerHost.maybeOf(context)?.show(message, level: level);
}

class DhizukuListRow extends StatelessWidget {
  const DhizukuListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onPressed,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => DhizukuPressSurface(
    fill: prism.Colors.transparent,
    shape: prism.AppShape.xl,
    look: prism.PressLook.tint,
    onPressed: onPressed,
    childFills: true,
    child: prism.ListRow(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      minHeight: subtitle == null ? 64 : 72,
    ),
  );
}

class DhizukuSwitchRow extends StatelessWidget {
  const DhizukuSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: subtitle == null ? 64 : 76),
      child: DhizukuPressSurface(
        fill: prism.Colors.transparent,
        shape: prism.AppShape.xl,
        look: prism.PressLook.tint,
        onPressed: enabled ? () => onChanged(!value) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        childFills: true,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 16)],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.itemTitle(context)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: AppTypography.itemSubtitle(context).copyWith(
                        color: prism.Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            prism.Switch(value: value, onChanged: enabled ? onChanged : null),
          ],
        ),
      ),
    ),
  );
}

class DhizukuSectionTitle extends StatelessWidget {
  const DhizukuSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
    child: Text(text, style: AppTypography.sectionTitle(context)),
  );
}

class DhizukuDescribedSectionTitle extends StatelessWidget {
  const DhizukuDescribedSectionTitle({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DhizukuSectionTitle(title),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            description,
            style: AppTypography.supportingText(context).copyWith(
              color: prism.Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

class DhizukuAnimatedEntry extends StatefulWidget {
  const DhizukuAnimatedEntry({
    required this.index,
    required this.child,
    this.animate = true,
    this.active = true,
    super.key,
  });

  final int index;
  final Widget child;
  final bool animate;
  final bool active;

  @override
  State<DhizukuAnimatedEntry> createState() => _DhizukuAnimatedEntryState();
}

class _DhizukuAnimatedEntryState extends State<DhizukuAnimatedEntry> {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _visible = false;
      _scheduleEntry();
    }
  }

  void _scheduleEntry() {
    _timer = Timer(AppMotion.entryStaggerStep * widget.index.clamp(0, 8), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void didUpdateWidget(covariant DhizukuAnimatedEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active && !widget.active) {
      _timer?.cancel();
      _visible = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppMotion.entryFadeDuration,
      curve: AppMotion.enterCurve,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.035),
        duration: AppMotion.entryTransformDuration,
        curve: AppMotion.enterCurve,
        child: AnimatedScale(
          scale: _visible ? 1 : 0.985,
          duration: AppMotion.entryTransformDuration,
          curve: AppMotion.enterCurve,
          child: widget.child,
        ),
      ),
    );
  }
}
