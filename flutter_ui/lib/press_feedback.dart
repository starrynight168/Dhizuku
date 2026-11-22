import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:material_ui/material_ui.dart';
import 'package:prism_ui/prism_ui.dart' as prism;

import 'app_motion.dart';

class DhizukuPressFeedback extends StatefulWidget {
  const DhizukuPressFeedback({
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  State<DhizukuPressFeedback> createState() => _DhizukuPressFeedbackState();
}

class _DhizukuPressFeedbackState extends State<DhizukuPressFeedback> {
  bool _pressed = false;
  Offset? _pointerOrigin;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled
        ? (event) {
            _pointerOrigin = event.position;
            _setPressed(true);
          }
        : null,
    onPointerMove: widget.enabled
        ? (event) {
            final origin = _pointerOrigin;
            if (origin != null &&
                (event.position - origin).distance > kTouchSlop) {
              _pointerOrigin = null;
              _setPressed(false);
            }
          }
        : null,
    onPointerUp: widget.enabled
        ? (_) {
            _pointerOrigin = null;
            _setPressed(false);
          }
        : null,
    onPointerCancel: widget.enabled
        ? (_) {
            _pointerOrigin = null;
            _setPressed(false);
          }
        : null,
    child: AnimatedScale(
      scale: _pressed && !MediaQuery.disableAnimationsOf(context) ? 0.975 : 1,
      duration: _pressed
          ? AppMotion.pressInDuration
          : AppMotion.pressOutDuration,
      curve: _pressed ? AppMotion.pressInCurve : AppMotion.pressOutCurve,
      child: widget.child,
    ),
  );
}

class DhizukuPressSurface extends StatelessWidget {
  const DhizukuPressSurface({
    required this.fill,
    required this.shape,
    required this.child,
    this.look = prism.PressLook.tint,
    this.side = BorderSide.none,
    this.selected = false,
    this.childFills = false,
    this.clipsChild = false,
    this.padding = EdgeInsets.zero,
    this.minimum = const BoxConstraints(),
    this.onPressed,
    super.key,
  });

  final Color fill;
  final OutlinedBorder shape;
  final Widget child;
  final prism.PressLook look;
  final BorderSide side;
  final bool selected;
  final bool childFills;
  final bool clipsChild;
  final EdgeInsets padding;
  final BoxConstraints minimum;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => DhizukuPressFeedback(
    enabled: onPressed != null,
    child: prism.PressSurface(
      fill: fill,
      shape: shape,
      look: look,
      side: side,
      selected: selected,
      childFills: childFills,
      clipsChild: clipsChild,
      padding: padding,
      minimum: minimum,
      onPressed: onPressed,
      child: child,
    ),
  );
}

class DhizukuTextButton extends StatelessWidget {
  const DhizukuTextButton({
    required this.onPressed,
    required this.child,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => DhizukuPressFeedback(
    enabled: onPressed != null,
    child: prism.TextButton(onPressed: onPressed, child: child),
  );
}

class DhizukuIconButton extends StatelessWidget {
  const DhizukuIconButton({
    required this.onPressed,
    required this.icon,
    this.tooltip,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => DhizukuPressFeedback(
    enabled: onPressed != null,
    child: IconButton(onPressed: onPressed, tooltip: tooltip, icon: icon),
  );
}
