import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:prism_ui/typography.dart' as prism;

abstract final class AppTypography {
  static const double fontSizeScale = 1.0;
  static const int appFontWeightDelta = 100;
  static final foundation.ValueNotifier<int> _weightAdjustment =
      foundation.ValueNotifier(0);

  static foundation.ValueListenable<int> get weightAdjustment =>
      _weightAdjustment;

  static int get fontWeightDelta =>
      appFontWeightDelta + _weightAdjustment.value;

  static Future<void> refreshSystemWeightAdjustment() async {
    try {
      final adjustment = await const MethodChannel('com.rosan.dhizuku/bridge')
          .invokeMethod<int>('getSystemFontWeightAdjustment');
      _weightAdjustment.value = adjustment ?? 0;
    } on MissingPluginException {
      _weightAdjustment.value = 0;
    } on PlatformException {
      _weightAdjustment.value = 0;
    }
  }

  static String? fontFamilyFor(material.TargetPlatform platform) =>
      platform == material.TargetPlatform.android ? 'sans-serif' : null;

  static double scaleFontSize(double size) => size * fontSizeScale;

  static material.FontWeight adjustFontWeight(material.FontWeight weight) {
    final target = (weight.value + fontWeightDelta).clamp(100, 900).toInt();
    return material.FontWeight(target);
  }

  static material.TextStyle appBarTitle(material.Color color) =>
      material.TextStyle(
        color: color,
        fontSize: scaleFontSize(24),
        fontWeight: adjustFontWeight(material.FontWeight.w600),
      );

  static material.TextStyle sectionTitle(material.BuildContext context) =>
      prism.AppTextStyle.headline.of(context);

  static material.TextStyle itemTitle(material.BuildContext context) =>
      prism.AppTextStyle.body.of(context);

  static material.TextStyle itemSubtitle(material.BuildContext context) =>
      prism.AppTextStyle.subheadline.of(context);

  static material.TextStyle supportingText(material.BuildContext context) =>
      prism.AppTextStyle.footnote.of(context);

  static material.TextStyle? adjustTextStyle(material.TextStyle? style) {
    if (style == null) return null;
    return style.copyWith(
      fontSize: style.fontSize == null ? null : scaleFontSize(style.fontSize!),
      fontWeight: adjustFontWeight(
        style.fontWeight ?? material.FontWeight.w400,
      ),
    );
  }

  static material.TextTheme adjustTextTheme(material.TextTheme theme) =>
      theme.copyWith(
        displayLarge: adjustTextStyle(theme.displayLarge),
        displayMedium: adjustTextStyle(theme.displayMedium),
        displaySmall: adjustTextStyle(theme.displaySmall),
        headlineLarge: adjustTextStyle(theme.headlineLarge),
        headlineMedium: adjustTextStyle(theme.headlineMedium),
        headlineSmall: adjustTextStyle(theme.headlineSmall),
        titleLarge: adjustTextStyle(theme.titleLarge),
        titleMedium: adjustTextStyle(theme.titleMedium),
        titleSmall: adjustTextStyle(theme.titleSmall),
        bodyLarge: adjustTextStyle(theme.bodyLarge),
        bodyMedium: adjustTextStyle(theme.bodyMedium),
        bodySmall: adjustTextStyle(theme.bodySmall),
        labelLarge: adjustTextStyle(theme.labelLarge),
        labelMedium: adjustTextStyle(theme.labelMedium),
        labelSmall: adjustTextStyle(theme.labelSmall),
      );
}
