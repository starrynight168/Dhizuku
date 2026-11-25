import 'package:flutter/physics.dart' as physics;
import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart' as prism;

abstract final class AppMotion {
  static const pageEnterDuration = Duration(milliseconds: 360);
  static const pageExitDuration = Duration(milliseconds: 280);
  static const dialogDuration = Duration(milliseconds: 300);
  static const dialogSpringDuration = Duration(milliseconds: 270);
  static const selectionSpringDuration = Duration(milliseconds: 420);
  static const appearanceSelectionDuration = Duration(milliseconds: 180);
  static const themePreviewDuration = Duration(milliseconds: 180);
  static const themeLabelDuration = Duration(milliseconds: 200);
  static const navigationTitleDuration = Duration(milliseconds: 220);
  static const contentSwitchDuration = Duration(milliseconds: 220);
  static const dashboardStatusDuration = Duration(milliseconds: 240);
  static const tabPageDuration = Duration(milliseconds: 360);
  static const activationExpandDuration = Duration(milliseconds: 360);
  static const activationModeDuration = Duration(milliseconds: 180);
  static const pressInDuration = Duration(milliseconds: 90);
  static const pressOutDuration = Duration(milliseconds: 280);
  static const entryFadeDuration = Duration(milliseconds: 300);
  static const entryTransformDuration = Duration(milliseconds: 360);
  static const entryStaggerStep = Duration(milliseconds: 32);
  static const listScrollDuration = Duration(milliseconds: 280);
  static const selectionCardDuration = Duration(milliseconds: 260);

  static const enterCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;
  static const sheetCurve = Curves.easeInOutCubic;
  static const appearanceSelectionCurve = Curves.easeInOutCubic;
  static const activationSelectionCurve = Curves.easeOutBack;
  static const pressInCurve = Curves.easeOutCubic;
  static const pressOutCurve = Curves.easeOutBack;

  static final dialogSpringCurve = prism.SpringCurve(
    physics.SpringDescription.withDurationAndBounce(
      duration: dialogSpringDuration,
      bounce: 0.15,
    ),
    seconds: 0.3,
  );

  static final selectionSpring =
      physics.SpringDescription.withDurationAndBounce(
        duration: selectionSpringDuration,
        bounce: 0.15,
      );

  static Duration durationFor(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
