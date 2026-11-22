import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:prism_ui/prism_ui.dart' as prism;

import 'app_motion.dart';
import 'app_typography.dart';
import 'press_feedback.dart';

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
    fill: Colors.transparent,
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
        fill: Colors.transparent,
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
            Switch(value: value, onChanged: enabled ? onChanged : null),
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
            style: AppTypography.supportingText(
              context,
            ).copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
