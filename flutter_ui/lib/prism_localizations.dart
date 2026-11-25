import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart' as prism;

class DhizukuPrismLocalizations extends prism.UiLocalizations {
  DhizukuPrismLocalizations({required this.isZh});

  final bool isZh;

  @override
  String get back => isZh ? '返回' : 'Back';

  @override
  String get cancel => isZh ? '取消' : 'Cancel';

  @override
  String get clearSearch => isZh ? '清除搜索' : 'Clear search';

  @override
  String get close => isZh ? '关闭' : 'Close';

  @override
  String get copy => isZh ? '复制' : 'Copy';

  @override
  String get cut => isZh ? '剪切' : 'Cut';

  @override
  String get dialog => isZh ? '对话框' : 'Dialog';

  @override
  String get hidePassword => isZh ? '隐藏密码' : 'Hide password';

  @override
  String get more => isZh ? '更多' : 'More';

  @override
  String get noSearchResults => isZh ? '没有搜索结果' : 'No search results';

  @override
  String get paste => isZh ? '粘贴' : 'Paste';

  @override
  String get reset => isZh ? '重置' : 'Reset';

  @override
  String get select => isZh ? '选择' : 'Select';

  @override
  String get search => isZh ? '搜索' : 'Search';

  @override
  String get selectAll => isZh ? '全选' : 'Select all';

  @override
  String get showLess => isZh ? '收起' : 'Show less';

  @override
  String get showMore => isZh ? '查看更多' : 'Show more';

  @override
  String get showPassword => isZh ? '显示密码' : 'Show password';

  @override
  String get sort => isZh ? '排序' : 'Sort';

  @override
  String get submit => isZh ? '提交' : 'Submit';
}

class DhizukuPrismLocalizationsDelegate
    extends LocalizationsDelegate<prism.UiLocalizations> {
  const DhizukuPrismLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'zh' || locale.languageCode == 'en';

  @override
  Future<prism.UiLocalizations> load(Locale locale) async =>
      DhizukuPrismLocalizations(isZh: locale.languageCode == 'zh');

  @override
  bool shouldReload(DhizukuPrismLocalizationsDelegate old) => false;
}
