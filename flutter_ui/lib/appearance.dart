import 'package:material_ui/material_ui.dart';

import 'api.dart';

class AppearanceSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useSystemColor = true;
  int _seedColor = 0xff007aff;
  int? _systemSeedColor;
  String _colorStyle = 'vivid';

  ThemeMode get themeMode => _themeMode;
  bool get useSystemColor => _useSystemColor;
  int get seedColor => _seedColor;
  int? get systemSeedColor => _systemSeedColor;
  String get colorStyle => _colorStyle;
  Color get activeSeedColor => Color(
    _useSystemColor && _systemSeedColor != null
        ? _systemSeedColor!
        : _seedColor,
  );

  Future<void> load() async {
    try {
      _apply(await DhizukuApi.getAppearance());
      notifyListeners();
    } catch (_) {}
  }

  Future<void> update({
    ThemeMode? themeMode,
    bool? useSystemColor,
    int? seedColor,
    String? colorStyle,
  }) async {
    final previous = (
      mode: _themeMode,
      system: _useSystemColor,
      seed: _seedColor,
      style: _colorStyle,
    );
    _themeMode = themeMode ?? _themeMode;
    _useSystemColor = useSystemColor ?? _useSystemColor;
    _seedColor = seedColor ?? _seedColor;
    _colorStyle = colorStyle ?? _colorStyle;
    notifyListeners();
    try {
      final changed = _apply(
        await DhizukuApi.setAppearance(
          themeMode: _themeMode.name,
          useSystemColor: _useSystemColor,
          seedColor: _seedColor,
          colorStyle: _colorStyle,
        ),
      );
      if (changed) notifyListeners();
    } catch (_) {
      _themeMode = previous.mode;
      _useSystemColor = previous.system;
      _seedColor = previous.seed;
      _colorStyle = previous.style;
      notifyListeners();
      rethrow;
    }
  }

  bool _apply(Map<String, dynamic> values) {
    final previous = (
      mode: _themeMode,
      system: _useSystemColor,
      seed: _seedColor,
      systemSeed: _systemSeedColor,
      style: _colorStyle,
    );
    _themeMode = switch (values['themeMode']) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _seedColor = (values['seedColor'] as num?)?.toInt() ?? _seedColor;
    _systemSeedColor = (values['systemSeedColor'] as num?)?.toInt();
    _useSystemColor =
        values['useSystemColor'] != false && _systemSeedColor != null;
    _colorStyle = values['colorStyle']?.toString() ?? _colorStyle;
    return previous.mode != _themeMode ||
        previous.system != _useSystemColor ||
        previous.seed != _seedColor ||
        previous.systemSeed != _systemSeedColor ||
        previous.style != _colorStyle;
  }
}
