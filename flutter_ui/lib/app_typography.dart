import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

  static String? fontFamilyFor(foundation.TargetPlatform platform) =>
      platform == foundation.TargetPlatform.android ? 'sans-serif' : null;

  static FontWeight adjustFontWeight(FontWeight weight) {
    final target = (weight.value + fontWeightDelta).clamp(100, 900).toInt();
    return FontWeight(target);
  }

  static TextStyle sectionTitle(BuildContext context) =>
      prism.AppTextStyle.headline.of(context);

  static TextStyle itemTitle(BuildContext context) =>
      prism.AppTextStyle.body.of(context);

  static TextStyle itemSubtitle(BuildContext context) =>
      prism.AppTextStyle.subheadline.of(context);

  static TextStyle supportingText(BuildContext context) =>
      prism.AppTextStyle.footnote.of(context);
}
