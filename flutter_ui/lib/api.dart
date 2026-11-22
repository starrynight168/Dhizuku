import 'package:flutter/services.dart';

class DhizukuApi {
  static const _channel = MethodChannel('com.rosan.dhizuku/bridge');

  static void setNativeCallHandler(
    Future<dynamic> Function(MethodCall)? handler,
  ) => _channel.setMethodCallHandler(handler);

  static Future<Map<String, dynamic>> getInitialData() async =>
      Map<String, dynamic>.from(await _channel.invokeMethod('getInitialData'));

  static Future<void> acceptAgreement() =>
      _channel.invokeMethod<void>('acceptAgreement');

  static Future<Map<String, dynamic>> getSettings() async =>
      Map<String, dynamic>.from(await _channel.invokeMethod('getSettings'));

  static Future<Map<String, dynamic>> getAppearance() async =>
      Map<String, dynamic>.from(await _channel.invokeMethod('getAppearance'));

  static Future<Map<String, dynamic>> setAppearance({
    required String themeMode,
    required bool useSystemColor,
    required int seedColor,
    required String colorStyle,
  }) async => Map<String, dynamic>.from(
    await _channel.invokeMethod('setAppearance', {
      'themeMode': themeMode,
      'useSystemColor': useSystemColor,
      'seedColor': seedColor,
      'colorStyle': colorStyle,
    }),
  );

  static Future<Map<String, dynamic>> setSetting(
    String key,
    bool enabled,
  ) async => Map<String, dynamic>.from(
    await _channel.invokeMethod('setSetting', {'key': key, 'enabled': enabled}),
  );

  static Future<List<Map<String, dynamic>>> getApps() async =>
      _maps(await _channel.invokeMethod<List<dynamic>>('getApps'));

  static Future<void> setAppPermission(int uid, String key, bool value) =>
      _channel.invokeMethod<void>('setAppPermission', {
        'uid': uid,
        'key': key,
        'value': value,
      });

  static Future<List<Map<String, dynamic>>> getUsers() async =>
      _maps(await _channel.invokeMethod<List<dynamic>>('getUsers'));

  static Future<bool> removeUser(int userId) async =>
      await _channel.invokeMethod<bool>('removeUser', {'userId': userId}) ??
      false;

  static Future<Map<String, dynamic>> getAccountData(int userId) async {
    final value = Map<String, dynamic>.from(
      await _channel.invokeMethod('getAccountData', {'userId': userId}),
    );
    return {
      'accounts': _maps(value['accounts'] as List<dynamic>?),
      'authenticators': _maps(value['authenticators'] as List<dynamic>?),
    };
  }

  static Future<String> removeAccount(Map<String, dynamic> account) async =>
      await _channel.invokeMethod<String>('removeAccount', account) ?? 'failed';

  static Future<bool> openSystemAccountSettings() async =>
      await _channel.invokeMethod<bool>('openSystemAccountSettings') ?? false;

  static Future<bool> setAuthenticatorEnabled({
    required int userId,
    required String packageName,
    required String label,
    required String type,
    required bool enabled,
  }) async =>
      await _channel.invokeMethod<bool>('setAuthenticatorEnabled', {
        'userId': userId,
        'packageName': packageName,
        'label': label,
        'type': type,
        'enabled': enabled,
      }) ??
      false;

  static Future<List<Map<String, dynamic>>> getAdmins() async =>
      _maps(await _channel.invokeMethod<List<dynamic>>('getAdmins'));

  static Future<void> activateOwner({
    required String packageName,
    required String className,
    required String ownerType,
    required String mode,
  }) => _channel.invokeMethod<void>('activateOwner', {
    'packageName': packageName,
    'className': className,
    'ownerType': ownerType,
    'mode': mode,
  });

  static Future<void> cancelActivation() =>
      _channel.invokeMethod<void>('cancelActivation');

  static Future<void> openUrl(String url) =>
      _channel.invokeMethod<void>('openUrl', {'url': url});

  static Future<void> deactivateOwner() =>
      _channel.invokeMethod<void>('deactivateOwner');

  static Future<void> shutdown() => _channel.invokeMethod<void>('shutdown');

  static List<Map<String, dynamic>> _maps(List<dynamic>? values) =>
      values
          ?.map((value) => Map<String, dynamic>.from(value as Map))
          .toList() ??
      [];
}
