import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:prism_ui/icons/icons.dart' show Glyph, GlyphIcon, Glyphs;
import 'package:prism_ui/prism_ui.dart' as prism;

import 'api.dart';
import 'glyphs.dart';
import 'texts.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    required this.data,
    required this.onRefresh,
    required this.onNavigate,
    super.key,
  });

  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final owner = data['isOwner'] == true;
    final profile = data['isProfileOwner'] == true;
    final actions =
        <({Glyph glyph, String title, String? subtitle, VoidCallback onTap})>[];
    if (owner) {
      actions.addAll([
        (
          glyph: DhizukuGlyphs.apps,
          title: tr(context, 'manage_apps'),
          subtitle: tr(context, 'api_access'),
          onTap: () => onNavigate(1),
        ),
        (
          glyph: DhizukuGlyphs.users,
          title: tr(context, 'manage_users'),
          subtitle: tr(context, 'accounts'),
          onTap: () => onNavigate(2),
        ),
        (
          glyph: DhizukuGlyphs.settings,
          title: tr(context, 'open_settings'),
          subtitle: null,
          onTap: () => onNavigate(3),
        ),
        (
          glyph: DhizukuGlyphs.swap,
          title: tr(context, 'activate_dhizuku'),
          subtitle: tr(context, 'activation_info'),
          onTap: () => _openActivation(context, 'dhizuku'),
        ),
        (
          glyph: DhizukuGlyphs.verified,
          title: tr(context, 'deactivate'),
          subtitle: null,
          onTap: () => _deactivate(context),
        ),
      ]);
    } else {
      actions.addAll([
        (
          glyph: DhizukuGlyphs.verified,
          title: tr(context, 'activate_shizuku'),
          subtitle: tr(context, 'activation_info'),
          onTap: () => _openActivation(context, 'shizuku'),
        ),
        (
          glyph: DhizukuGlyphs.logs,
          title: tr(context, 'adb_help'),
          subtitle: tr(context, 'adb_command'),
          onTap: () => _showAdbHelp(context),
        ),
        (
          glyph: DhizukuGlyphs.users,
          title: tr(context, 'manage_users'),
          subtitle: tr(context, 'accounts'),
          onTap: () => onNavigate(2),
        ),
      ]);
    }
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth >= 720 ? 28 : 16,
                12,
                constraints.maxWidth >= 720 ? 28 : 16,
                24,
              ),
              children: [
                _DashboardCard(
                  child: _StatusPanel(
                    owner: owner,
                    title: owner
                        ? tr(context, profile ? 'profile_owner' : 'owner')
                        : tr(context, 'not_activated'),
                    description: owner
                        ? tr(context, 'activated')
                        : tr(context, 'activation_info'),
                    onRefresh: onRefresh,
                  ),
                ),
                const SizedBox(height: 12),
                _DashboardCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                        child: Row(
                          spacing: 8,
                          children: [
                            GlyphIcon(
                              DhizukuGlyphs.dashboard,
                              size: 18,
                              color: prism.Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            Expanded(
                              child: Text(
                                tr(context, 'quick_actions'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (var index = 0; index < actions.length; index++) ...[
                        _HomeActionCard(
                          glyph: actions[index].glyph,
                          title: actions[index].title,
                          subtitle: actions[index].subtitle,
                          onTap: actions[index].onTap,
                        ),
                        if (index < actions.length - 1)
                          const Divider(indent: 76, endIndent: 20),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _adminComponent() => 'com.rosan.dhizuku/.server.DhizukuDAReceiver';

  void _showAdbHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'adb_help')),
        content: SelectableText(
          'adb shell dpm set-device-owner ${_adminComponent()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _openActivation(BuildContext context, String mode) async {
    final activated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ActivationPage(initialMode: mode),
      ),
    );
    if (activated == true) await onRefresh();
  }

  Future<void> _deactivate(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'deactivate')),
        content: Text(tr(context, 'deactivate_text')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'confirm')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DhizukuApi.deactivateOwner();
      await onRefresh();
    }
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = prism.Theme.of(context).colorScheme;
    final shadows = colorScheme.brightness == Brightness.dark
        ? const [
            BoxShadow(
              color: Color(0x80000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Color(0x8c000000),
              offset: Offset(0, 10),
              blurRadius: 23.8,
              spreadRadius: -6,
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x0d000000),
              offset: Offset(0, 0.5),
              blurRadius: 0.37,
            ),
            BoxShadow(
              color: Color(0x0a000000),
              offset: Offset(0, 2),
              blurRadius: 4.7,
            ),
            BoxShadow(
              color: Color(0x17000000),
              offset: Offset(0, 12),
              blurRadius: 26.8,
              spreadRadius: -6,
            ),
          ];
    return Container(
      decoration: ShapeDecoration(
        color: prism.SurfaceLevel.card.colorOf(colorScheme),
        shape: prism.AppShape.all(34),
        shadows: shadows,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.owner,
    required this.title,
    required this.description,
    required this.onRefresh,
  });

  final bool owner;
  final String title;
  final String description;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = prism.Theme.of(context).colorScheme;
    final foreground = colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(18),
              ),
              child: GlyphIcon(
                owner ? DhizukuGlyphs.verified : DhizukuGlyphs.dashboard,
                color: colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dhizuku',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 3),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      title,
                      key: ValueKey(title),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              tooltip: tr(context, 'retry'),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Align(
              alignment: Alignment.centerLeft,
              key: ValueKey(description),
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlyphIcon(
              owner ? DhizukuGlyphs.verified : DhizukuGlyphs.logs,
              size: 16,
              color: owner ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Text(
              owner ? tr(context, 'activated') : tr(context, 'not_activated'),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.glyph,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final Glyph glyph;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = prism.Theme.of(context).colorScheme;
    return prism.PressSurface(
      fill: Colors.transparent,
      shape: prism.AppShape.xl,
      onPressed: onTap,
      childFills: true,
      child: prism.ListRow(
        leading: GlyphIcon(
          glyph,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: GlyphIcon(
          Glyphs.chevronForward,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        minHeight: subtitle == null ? 64 : 72,
      ),
    );
  }
}

class _InteractiveListRow extends StatelessWidget {
  const _InteractiveListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onPressed,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => prism.PressSurface(
    fill: Colors.transparent,
    shape: prism.AppShape.xl,
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

class _AnimatedSwitchRow extends StatelessWidget {
  const _AnimatedSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => prism.PressSurface(
    fill: Colors.transparent,
    shape: prism.AppShape.xl,
    onPressed: enabled ? () => onChanged(!value) : null,
    childFills: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: subtitle == null ? 64 : 76),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 16)],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class AppManagementPage extends StatefulWidget {
  const AppManagementPage({required this.onError, super.key});

  final void Function(Object error) onError;

  @override
  State<AppManagementPage> createState() => _AppManagementPageState();
}

class _AppManagementPageState extends State<AppManagementPage> {
  late Future<List<Map<String, dynamic>>> _apps = DhizukuApi.getApps();
  String _query = '';

  void _reload() => setState(() => _apps = DhizukuApi.getApps());

  Future<void> _set(Map<String, dynamic> app, String key, bool value) async {
    try {
      await DhizukuApi.setAppPermission(app['uid'] as int, key, value);
      _reload();
    } catch (error) {
      widget.onError(error);
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _apps,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(error: snapshot.error!, onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final apps = snapshot.data!.where((app) {
            final query = _query.toLowerCase();
            return app['label'].toString().toLowerCase().contains(query) ||
                app['packageName'].toString().toLowerCase().contains(query);
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SearchBar(
                  leading: const Icon(Icons.search),
                  hintText: tr(context, 'search'),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: apps.isEmpty
                    ? Center(child: Text(tr(context, 'no_apps')))
                    : RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                          itemCount: apps.length,
                          itemBuilder: (context, index) {
                            final app = apps[index];
                            final blocked = app['blocked'] == true;
                            final icon = app['icon'];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: prism.ListRow(
                                      leading: icon is Uint8List
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.memory(
                                                icon,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(
                                                      Icons.android,
                                                      size: 40,
                                                    ),
                                              ),
                                            )
                                          : const CircleAvatar(
                                              child: Icon(Icons.android),
                                            ),
                                      title: Text(app['label'].toString()),
                                      subtitle: Text(
                                        app['packageName'].toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      minHeight: 80,
                                    ),
                                  ),
                                  const Divider(indent: 20, endIndent: 20),
                                  _AnimatedSwitchRow(
                                    title: tr(context, 'api_access'),
                                    value: app['enabled'] == true && !blocked,
                                    enabled: !blocked,
                                    onChanged: (value) =>
                                        _set(app, 'enabled', value),
                                  ),
                                  _AnimatedSwitchRow(
                                    title: tr(context, 'blocked'),
                                    value: blocked,
                                    onChanged: (value) =>
                                        _set(app, 'blocked', value),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      );
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({required this.onError, super.key});

  final void Function(Object error) onError;

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late Future<List<Map<String, dynamic>>> _users = DhizukuApi.getUsers();

  void _reload() => setState(() => _users = DhizukuApi.getUsers());

  Future<void> _remove(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'remove_user')),
        content: Text(
          '${user['name']}\n\n${tr(context, 'delete_user_warning')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'remove')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await DhizukuApi.removeUser(user['id'] as int);
      _reload();
    } catch (error) {
      widget.onError(error);
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(error: snapshot.error!, onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final user = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _InteractiveListRow(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(user['name'].toString()),
                    subtitle: Text('ID ${user['id']}'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AccountManagementPage(user: user),
                      ),
                    ),
                    trailing: user['current'] == true
                        ? Text(
                            tr(context, 'current_user'),
                            style: Theme.of(context).textTheme.labelMedium,
                          )
                        : IconButton(
                            tooltip: tr(context, 'remove'),
                            onPressed: () => _remove(user),
                            icon: const Icon(Icons.delete_outline),
                          ),
                  ),
                );
              },
            ),
          );
        },
      );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.settings,
    required this.onChanged,
    super.key,
  });

  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onChanged;

  Future<void> _toggle(String key, bool value) async {
    try {
      onChanged(await DhizukuApi.setSetting(key, value));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
    children: [
      _SectionTitle(tr(context, 'preferences_group')),
      Card(
        child: Column(
          children: [
            _AnimatedSwitchRow(
              title: tr(context, 'dhizuku_enabled'),
              value: settings['dhizukuEnabled'] == true,
              onChanged: (value) => _toggle('dhizukuEnabled', value),
            ),
            const Divider(indent: 16, endIndent: 16),
            _AnimatedSwitchRow(
              title: tr(context, 'whitelist'),
              subtitle: tr(context, 'api_access'),
              value: settings['whitelistMode'] == true,
              onChanged: (value) => _toggle('whitelistMode', value),
            ),
            const Divider(indent: 16, endIndent: 16),
            _AnimatedSwitchRow(
              title: tr(context, 'hide_donate'),
              value: settings['donateButtonHidden'] == true,
              onChanged: (value) => _toggle('donateButtonHidden', value),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _SectionTitle(tr(context, 'about_group')),
      Card(
        child: Column(
          children: [
            _InteractiveListRow(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(tr(context, 'notifications')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onPressed: () =>
                  const MethodChannel('com.rosan.dhizuku/bridge')
                      .invokeMethod('requestNotificationPermission'),
            ),
            const Divider(indent: 16, endIndent: 16),
            _InteractiveListRow(
              leading: const Icon(Icons.battery_saver_outlined),
              title: Text(tr(context, 'battery_optimization')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onPressed: () =>
                  const MethodChannel('com.rosan.dhizuku/bridge')
                      .invokeMethod('requestIgnoreBatteryOptimization'),
            ),
            const Divider(indent: 16, endIndent: 16),
            _InteractiveListRow(
              leading: const Icon(Icons.favorite_outline),
              title: Text(tr(context, 'donate')),
              trailing: const Icon(Icons.open_in_new_rounded),
              onPressed: () => DhizukuApi.openUrl(tr(context, 'donation_url')),
            ),
            const Divider(indent: 16, endIndent: 16),
            _InteractiveListRow(
              leading: const Icon(Icons.description_outlined),
              title: Text(tr(context, 'terms')),
              trailing: const Icon(Icons.open_in_new_rounded),
              onPressed: () => DhizukuApi.openUrl(
                'https://iamr0s.github.io/Dhizuku/TERMS.html',
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            _InteractiveListRow(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(tr(context, 'privacy')),
              trailing: const Icon(Icons.open_in_new_rounded),
              onPressed: () => DhizukuApi.openUrl(
                'https://iamr0s.github.io/Dhizuku/PRIVACY.html',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  late Future<Map<String, dynamic>> _data = _load();

  Future<Map<String, dynamic>> _load() =>
      DhizukuApi.getAccountData(widget.user['id'] as int);

  void _reload() => setState(() => _data = _load());

  Future<void> _toggleAuthenticator(
    Map<String, dynamic> item,
    bool enabled,
  ) async {
    await DhizukuApi.setAuthenticatorEnabled(
      userId: widget.user['id'] as int,
      packageName: item['packageName'].toString(),
      label: item['label'].toString(),
      type: item['type'].toString(),
      enabled: enabled,
    );
    _reload();
  }

  Future<void> _removeAccount(Map<String, dynamic> account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'remove_account')),
        content: Text(account['name'].toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'remove')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DhizukuApi.removeAccount(account);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.user['name'].toString())),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LoadError(error: snapshot.error!, onRetry: _reload);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        final value = snapshot.data!;
        final accounts = value['accounts'] as List<Map<String, dynamic>>;
        final authenticators =
            value['authenticators'] as List<Map<String, dynamic>>;
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _SectionTitle(tr(context, 'accounts')),
              if (accounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(tr(context, 'no_data')),
                ),
              for (final account in accounts)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _InteractiveListRow(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(account['name'].toString()),
                    subtitle: Text(account['type'].toString()),
                    trailing: IconButton(
                      onPressed: () => _removeAccount(account),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _SectionTitle(tr(context, 'authenticators')),
              if (authenticators.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(tr(context, 'no_data')),
                ),
              for (final item in authenticators)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _AnimatedSwitchRow(
                    leading: const Icon(Icons.extension_outlined),
                    title: item['label'].toString(),
                    subtitle: item['packageName'].toString(),
                    value: item['frozen'] != true,
                    onChanged: (enabled) => _toggleAuthenticator(item, enabled),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class ActivationPage extends StatefulWidget {
  const ActivationPage({required this.initialMode, super.key});

  final String initialMode;

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  late Future<List<Map<String, dynamic>>> _admins = DhizukuApi.getAdmins();
  String? _selected;
  String _ownerType = 'device';
  late String _mode = widget.initialMode;
  bool _busy = false;

  void _reload() => setState(() => _admins = DhizukuApi.getAdmins());

  Future<void> _chooseOwnerType(String value) async {
    if (value != 'profile') {
      setState(() => _ownerType = value);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(tr(context, 'profile_owner_warning_title')),
        content: Text(tr(context, 'profile_owner_warning_dsp')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _ownerType = value);
    }
  }

  Future<void> _activate(List<Map<String, dynamic>> admins) async {
    final key = _selected;
    final matches = admins.where(
      (item) => '${item['packageName']}/${item['className']}' == key,
    );
    final selected = matches.isEmpty ? null : matches.first;
    if (selected == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'activate')),
        content: Text(tr(context, 'activation_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'confirm')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _busy = true);
    var cancelRequested = false;
    var progressOpen = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(tr(dialogContext, 'activate')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(tr(dialogContext, 'activation_running')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (cancelRequested) return;
                  cancelRequested = true;
                  progressOpen = false;
                  try {
                    await DhizukuApi.cancelActivation();
                  } catch (_) {}
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(tr(dialogContext, 'cancel')),
              ),
            ],
          ),
        ),
      ),
    );
    try {
      await DhizukuApi.activateOwner(
        packageName: selected['packageName'].toString(),
        className: selected['className'].toString(),
        ownerType: _ownerType,
        mode: _mode,
      );
      if (progressOpen && mounted) {
        progressOpen = false;
        Navigator.of(context).pop();
      }
      if (cancelRequested) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr(context, 'activation_cancelled'))),
          );
          _reload();
        }
        return;
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(tr(dialogContext, 'activated')),
          content: Text(tr(dialogContext, 'activation_success')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr(dialogContext, 'finish')),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        if (progressOpen) {
          progressOpen = false;
          Navigator.of(context).pop();
        }
        if (cancelRequested) {
          _reload();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr(context, 'error')}: $error'),
            action: SnackBarAction(
              label: tr(context, 'retry'),
              onPressed: () => _activate(admins),
            ),
          ),
        );
      }
    } finally {
      if (progressOpen && mounted) Navigator.of(context).pop();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr(context, 'activate'))),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _admins,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LoadError(error: snapshot.error!, onRetry: _reload);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        final admins = snapshot.data!;
        if (admins.isEmpty) {
          return Center(child: Text(tr(context, 'no_admins')));
        }
        final currentSelection =
            admins.any(
              (item) =>
                  '${item['packageName']}/${item['className']}' == _selected,
            )
            ? _selected
            : '${admins.first['packageName']}/${admins.first['className']}';
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              tr(context, 'activation_info'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _SectionTitle(tr(context, 'admin')),
            DropdownButtonFormField<String>(
              initialValue: currentSelection,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                for (final item in admins)
                  DropdownMenuItem(
                    value: '${item['packageName']}/${item['className']}',
                    child: Text(
                      item['label'].toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _selected = value),
            ),
            if (_mode == 'shizuku') ...[
              const SizedBox(height: 20),
              _SectionTitle(tr(context, 'owner_type')),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'device',
                    label: Text(tr(context, 'device')),
                  ),
                  ButtonSegment(
                    value: 'profile',
                    label: Text(tr(context, 'profile')),
                  ),
                ],
                selected: {_ownerType},
                onSelectionChanged: (value) => _chooseOwnerType(value.first),
              ),
            ],
            const SizedBox(height: 20),
            _SectionTitle(tr(context, 'activation_mode')),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'dhizuku',
                  label: Text(tr(context, 'dhizuku_mode')),
                ),
                ButtonSegment(
                  value: 'shizuku',
                  label: Text(tr(context, 'shizuku_mode')),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (value) => setState(() {
                _mode = value.first;
                if (_mode == 'dhizuku') _ownerType = 'device';
              }),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : () => _activate(admins),
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(tr(context, 'activate')),
            ),
          ],
        );
      },
    ),
  );
}

class PermissionRequestPage extends StatefulWidget {
  const PermissionRequestPage({required this.data, super.key});

  final Map<String, dynamic> data;

  @override
  State<PermissionRequestPage> createState() => _PermissionRequestPageState();
}

class _PermissionRequestPageState extends State<PermissionRequestPage> {
  static const _channel = MethodChannel('com.rosan.dhizuku/bridge');
  static const _duration = 15;
  late int _remaining = _duration;
  Timer? _timer;
  bool _responded = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _responded) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _respond(false);
    });
  }

  Future<void> _respond(bool allow) async {
    if (_responded) return;
    _responded = true;
    _timer?.cancel();
    await _channel.invokeMethod<void>('respondPermission', {'allow': allow});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.privacy_tip_outlined, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      tr(context, 'permission_request'),
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.data['label']?.toString() ??
                          widget.data['packageName']?.toString() ??
                          '',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            value: _remaining / _duration,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('$_remaining ${tr(context, 'auto_deny')}'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _responded ? null : () => _respond(true),
                        child: Text(tr(context, 'allow')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: _responded ? null : () => _respond(false),
                        child: Text(tr(context, 'deny')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36),
          const SizedBox(height: 12),
          Text(error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(tr(context, 'retry')),
          ),
        ],
      ),
    ),
  );
}
