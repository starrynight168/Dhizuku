import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:prism_ui/icons/icons.dart' show Glyph, GlyphIcon, Glyphs;
import 'package:prism_ui/prism_ui.dart' as prism;

import 'api.dart';
import 'appearance.dart';
import 'glyphs.dart';
import 'press_feedback.dart';
import 'texts.dart';

Route<T> dhizukuPageRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 360),
  reverseTransitionDuration: const Duration(milliseconds: 280),
  pageBuilder: (context, _, _) => builder(context),
  transitionsBuilder: (context, animation, _, child) {
    final motion = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: motion,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.045, 0.02),
          end: Offset.zero,
        ).animate(motion),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.975, end: 1).animate(motion),
          child: child,
        ),
      ),
    );
  },
);

Future<T?> showDhizukuDialog<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool dismissible = true,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<T>(
    context: context,
    barrierColor: context.colorScheme.alertScrim,
    barrierDismissible: dismissible,
    barrierLabel: dismissible
        ? MaterialLocalizations.of(context).modalBarrierDismissLabel
        : null,
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 360),
    pageBuilder: (dialogContext, _, _) => SafeArea(
      child: Center(
        child: Builder(
          builder: (scopeContext) => prism.SurfaceScope(
            level: prism.SurfaceLevel.floatingOf(
              prism.Theme.of(scopeContext).colorScheme,
            ),
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final motion = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      return FadeTransition(
        opacity: motion,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(motion),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(motion),
            child: child,
          ),
        ),
      );
    },
  );
}

Widget _packageIcon(
  BuildContext context,
  Object? bytes, {
  required IconData fallback,
  double size = 48,
}) {
  final colors = Theme.of(context).colorScheme;
  return SizedBox.square(
    dimension: size,
    child: bytes is Uint8List
        ? ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.24),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Icon(
                fallback,
                size: size * 0.62,
                color: colors.onSurfaceVariant,
              ),
            ),
          )
        : Icon(fallback, size: size * 0.62, color: colors.onSurfaceVariant),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({
    required this.data,
    required this.active,
    required this.onRefresh,
    required this.onNavigate,
    super.key,
  });

  final Map<String, dynamic> data;
  final bool active;
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
    actions.insert(0, (
      glyph: DhizukuGlyphs.logs,
      title: tr(context, 'command_console'),
      subtitle: tr(context, 'command_console_subtitle'),
      onTap: () => Navigator.of(
        context,
      ).push<void>(dhizukuPageRoute<void>((_) => const CommandConsolePage())),
    ));
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
                _AnimatedEntry(
                  index: 0,
                  active: active,
                  child: _DashboardCard(
                    child: _StatusPanel(
                      owner: owner,
                      title: owner
                          ? tr(context, profile ? 'profile_owner' : 'owner')
                          : tr(context, 'not_activated'),
                      description: owner
                          ? null
                          : tr(context, 'activation_info'),
                      onOpenApps: () => onNavigate(1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedEntry(
                  index: 1,
                  active: active,
                  child: _DashboardCard(
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
                        for (
                          var index = 0;
                          index < actions.length;
                          index++
                        ) ...[
                          _AnimatedEntry(
                            index: index + 2,
                            active: active,
                            child: _HomeActionCard(
                              glyph: actions[index].glyph,
                              title: actions[index].title,
                              subtitle: actions[index].subtitle,
                              onTap: actions[index].onTap,
                            ),
                          ),
                          if (index < actions.length - 1)
                            const Divider(indent: 76, endIndent: 20),
                        ],
                      ],
                    ),
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
    showDhizukuDialog<void>(
      context,
      (context) => prism.AlertDialog(
        title: tr(context, 'adb_help'),
        actions: [
          DhizukuTextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'confirm')),
          ),
        ],
        child: SelectableText(
          'adb shell dpm set-device-owner ${_adminComponent()}',
        ),
      ),
    );
  }

  Future<void> _openActivation(BuildContext context, String mode) async {
    final activated = await Navigator.of(context).push<bool>(
      dhizukuPageRoute<bool>((_) => ActivationPage(initialMode: mode)),
    );
    if (activated == true) await onRefresh();
  }

  Future<void> _deactivate(BuildContext context) async {
    final confirm = await showDhizukuDialog<bool>(
      context,
      (context) => prism.AlertDialog(
        title: tr(context, 'deactivate'),
        destructive: true,
        actions: [
          DhizukuTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          DhizukuTextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'confirm')),
          ),
        ],
        child: Text(tr(context, 'deactivate_text')),
      ),
    );
    if (confirm == true) {
      try {
        await DhizukuApi.deactivateOwner();
        await onRefresh();
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${tr(context, 'error')}: $error')),
          );
        }
      }
    }
  }
}

class CommandConsolePage extends StatefulWidget {
  const CommandConsolePage({super.key});

  @override
  State<CommandConsolePage> createState() => _CommandConsolePageState();
}

class _CommandConsolePageState extends State<CommandConsolePage> {
  final _commandController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _favorites = [];
  Map<String, dynamic>? _result;
  String? _error;
  bool _loadingFavorites = true;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await DhizukuApi.getCommandFavorites();
      if (mounted) setState(() => _favorites = favorites);
    } catch (error) {
      if (mounted) _showMessage('$error');
    } finally {
      if (mounted) setState(() => _loadingFavorites = false);
    }
  }

  Future<void> _saveFavorites(List<Map<String, dynamic>> favorites) async {
    final stored = favorites
        .map(
          (favorite) => <String, String>{
            'id': favorite['id'].toString(),
            'name': favorite['name'].toString(),
            'command': favorite['command'].toString(),
          },
        )
        .toList();
    try {
      await DhizukuApi.saveCommandFavorites(stored);
      if (mounted) setState(() => _favorites = favorites);
    } catch (error) {
      if (mounted) _showMessage('$error');
    }
  }

  Future<void> _run([String? command]) async {
    final value = (command ?? _commandController.text).trim();
    if (value.isEmpty || _running) return;
    setState(() {
      _running = true;
      _result = null;
      _error = null;
    });
    try {
      final result = await DhizukuApi.runShellCommand(value);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<Map<String, String>?> _editFavorite({
    Map<String, dynamic>? favorite,
  }) async {
    final nameController = TextEditingController(
      text: favorite?['name']?.toString() ?? '',
    );
    final commandController = TextEditingController(
      text: favorite?['command']?.toString() ?? _commandController.text,
    );
    final formKey = GlobalKey<FormState>();
    final value = await showDhizukuDialog<Map<String, String>>(
      context,
      (dialogContext) => prism.AlertDialog(
        title: tr(
          dialogContext,
          favorite == null ? 'command_save_favorite' : 'command_edit_favorite',
        ),
        actions: [
          DhizukuTextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(dialogContext, 'cancel')),
          ),
          DhizukuTextButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dialogContext, {
                'name': nameController.text.trim(),
                'command': commandController.text.trim(),
              });
            },
            child: Text(tr(dialogContext, 'save')),
          ),
        ],
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.55,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: favorite == null,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: tr(dialogContext, 'command_name'),
                      hintText: tr(dialogContext, 'command_name_hint'),
                    ),
                    validator: (text) => text?.trim().isNotEmpty == true
                        ? null
                        : tr(dialogContext, 'command_required'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: commandController,
                    minLines: 2,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: tr(dialogContext, 'command_input'),
                    ),
                    validator: (text) => text?.trim().isNotEmpty == true
                        ? null
                        : tr(dialogContext, 'command_required'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    nameController.dispose();
    commandController.dispose();
    return value;
  }

  Future<void> _saveCurrentCommand({Map<String, dynamic>? favorite}) async {
    final value = await _editFavorite(favorite: favorite);
    if (value == null) return;
    final id =
        favorite?['id']?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final updated = [..._favorites];
    final index = updated.indexWhere((item) => item['id'] == id);
    final item = <String, dynamic>{
      'id': id,
      'name': value['name'],
      'command': value['command'],
    };
    if (index < 0) {
      updated.insert(0, item);
    } else {
      updated[index] = item;
    }
    await _saveFavorites(updated);
    if (mounted) _showMessage(tr(context, 'command_favorite_saved'));
  }

  Future<void> _deleteFavorite(Map<String, dynamic> favorite) async {
    final confirmed = await showDhizukuDialog<bool>(
      context,
      (dialogContext) => prism.AlertDialog(
        title: tr(dialogContext, 'command_delete_title'),
        destructive: true,
        actions: [
          DhizukuTextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(dialogContext, 'cancel')),
          ),
          DhizukuTextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(dialogContext, 'command_delete_favorite')),
          ),
        ],
        child: Text(tr(dialogContext, 'command_delete_body')),
      ),
    );
    if (confirmed != true) return;
    await _saveFavorites(
      _favorites.where((item) => item['id'] != favorite['id']).toList(),
    );
    if (mounted) _showMessage(tr(context, 'command_favorite_deleted'));
  }

  Future<void> _showFavoriteActions(Map<String, dynamic> favorite) async {
    final action = await showDhizukuDialog<String>(
      context,
      (dialogContext) => prism.AlertDialog(
        title: tr(dialogContext, 'more_options'),
        actions: [
          DhizukuTextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(dialogContext, 'cancel')),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InteractiveListRow(
              leading: const Icon(Icons.edit_outlined),
              title: Text(tr(dialogContext, 'command_edit_favorite')),
              onPressed: () => Navigator.pop(dialogContext, 'edit'),
            ),
            const Divider(height: 1),
            _InteractiveListRow(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(dialogContext).colorScheme.error,
              ),
              title: Text(
                tr(dialogContext, 'command_delete_favorite'),
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error,
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _saveCurrentCommand(favorite: favorite);
    } else if (action == 'delete') {
      await _deleteFavorite(favorite);
    }
  }

  void _selectFavorite(Map<String, dynamic> favorite) {
    final command = favorite['command'].toString();
    setState(() {
      _commandController.value = TextEditingValue(
        text: command,
        selection: TextSelection.collapsed(offset: command.length),
      );
      _result = null;
      _error = null;
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    _showMessage(tr(context, 'command_select_favorite'));
  }

  String _outputText() {
    if (_error != null) return _error!;
    final stdout = (_result?['stdout']?.toString() ?? '').trimRight();
    final stderr = (_result?['stderr']?.toString() ?? '').trimRight();
    return [
      if (stdout.isNotEmpty) stdout,
      if (stderr.isNotEmpty) '${tr(context, 'command_stderr')}:\n$stderr',
      if (stdout.isEmpty && stderr.isEmpty) tr(context, 'command_empty_output'),
    ].join('\n\n');
  }

  Future<void> _copyOutput() async {
    final exitCode = _result?['exitCode'];
    final errorLines = _error == null ? null : <String>[_error!];
    final content = [
      ...?errorLines,
      if (_result?['stdout']?.toString().isNotEmpty == true)
        _result!['stdout'].toString(),
      if (_result?['stderr']?.toString().isNotEmpty == true)
        '${tr(context, 'command_stderr')}:\n${_result!['stderr']}',
      if (exitCode != null)
        tr(context, 'command_exit_code').replaceAll('{code}', '$exitCode'),
    ].join('\n\n');
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) _showMessage(tr(context, 'command_output_copied'));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = prism.Theme.of(context).colorScheme;
    final output = _outputText();
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'command_console'))),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr(context, 'command_requirements'),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(context, 'command_security_note'),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _commandController,
                  onChanged: (_) => setState(() {}),
                  minLines: 2,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    labelText: tr(context, 'command_input'),
                    hintText: tr(context, 'command_hint'),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DhizukuPressSurface(
                  fill: colors.primary,
                  shape: prism.AppShape.all(28),
                  onPressed: _running || _commandController.text.trim().isEmpty
                      ? null
                      : _run,
                  childFills: true,
                  minimum: const BoxConstraints(minHeight: 54),
                  child: Center(
                    child: _running
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox.square(
                                dimension: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                tr(context, 'command_running'),
                                style: TextStyle(color: colors.onPrimary),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: colors.onPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr(context, 'command_run'),
                                style: TextStyle(color: colors.onPrimary),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: DhizukuTextButton(
                    onPressed: _commandController.text.trim().isEmpty
                        ? null
                        : _saveCurrentCommand,
                    child: Text(tr(context, 'command_add_favorite')),
                  ),
                ),
              ],
            ),
          ),
          if (_result != null || _error != null) ...[
            const SizedBox(height: 12),
            _DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(context, 'command_output'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      DhizukuIconButton(
                        tooltip: tr(context, 'command_copy_output'),
                        onPressed: _copyOutput,
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                  if (_result?['exitCode'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        tr(
                          context,
                          'command_exit_code',
                        ).replaceAll('{code}', '${_result!['exitCode']}'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: (_result!['exitCode'] as num) == 0
                              ? colors.onSurfaceVariant
                              : colors.error,
                        ),
                      ),
                    ),
                  SelectableText(
                    output,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: _error == null ? colors.onSurface : colors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _DashboardCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(context, 'command_favorites'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      DhizukuIconButton(
                        tooltip: tr(context, 'command_add_favorite'),
                        onPressed: _saveCurrentCommand,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                if (_loadingFavorites)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                else if (_favorites.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        tr(context, 'command_favorites_empty'),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  for (var index = 0; index < _favorites.length; index++) ...[
                    _InteractiveListRow(
                      leading: Icon(
                        Icons.bookmark_outline_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                      title: Text(_favorites[index]['name'].toString()),
                      subtitle: Text(
                        _favorites[index]['command'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DhizukuIconButton(
                            tooltip: tr(context, 'command_run'),
                            onPressed: () =>
                                _run(_favorites[index]['command'].toString()),
                            icon: const Icon(Icons.play_arrow_rounded),
                          ),
                          DhizukuIconButton(
                            tooltip: tr(context, 'more_options'),
                            onPressed: () =>
                                _showFavoriteActions(_favorites[index]),
                            icon: const Icon(Icons.more_vert_rounded),
                          ),
                        ],
                      ),
                      onPressed: () => _selectFavorite(_favorites[index]),
                    ),
                    if (index < _favorites.length - 1)
                      const Divider(indent: 72, endIndent: 20, height: 1),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
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
    required this.onOpenApps,
  });

  final bool owner;
  final String title;
  final String? description;
  final VoidCallback onOpenApps;

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
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 20),
          Text(
            description!,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 16),
        DhizukuPressSurface(
          fill: owner ? colorScheme.primaryContainer : Colors.transparent,
          shape: prism.AppShape.xl,
          look: owner ? prism.PressLook.tint : prism.PressLook.none,
          onPressed: owner ? onOpenApps : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              GlyphIcon(
                owner ? DhizukuGlyphs.verified : DhizukuGlyphs.logs,
                size: 18,
                color: owner
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner
                          ? tr(context, 'activated')
                          : tr(context, 'not_activated'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: owner
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (owner)
                      Text(
                        tr(context, 'view_authorized_apps'),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onPrimaryContainer),
                      ),
                  ],
                ),
              ),
              if (owner)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onPrimaryContainer,
                ),
            ],
          ),
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
    return DhizukuPressSurface(
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
  Widget build(BuildContext context) {
    Widget row({Widget? rowTrailing}) => prism.ListRow(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: rowTrailing,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      minHeight: subtitle == null ? 64 : 72,
    );

    return DhizukuPressSurface(
      fill: Colors.transparent,
      shape: prism.AppShape.xl,
      look: prism.PressLook.tint,
      onPressed: onPressed,
      childFills: true,
      child: row(rowTrailing: trailing),
    );
  }
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
  const AppManagementPage({
    required this.active,
    required this.onError,
    super.key,
  });

  final bool active;
  final void Function(Object error) onError;

  @override
  State<AppManagementPage> createState() => _AppManagementPageState();
}

class _AppManagementPageState extends State<AppManagementPage> {
  late Future<List<Map<String, dynamic>>> _apps = DhizukuApi.getApps();
  String _query = '';
  final Set<String> _pendingChanges = {};

  void _reload() => setState(() => _apps = DhizukuApi.getApps());

  Future<void> _set(Map<String, dynamic> app, String key, bool value) async {
    final operation = '${app['uid']}:$key';
    if (_pendingChanges.contains(operation)) return;
    final previous = app[key] == true;
    setState(() {
      _pendingChanges.add(operation);
      app[key] = value;
    });
    try {
      await DhizukuApi.setAppPermission(app['uid'] as int, key, value);
    } catch (error) {
      if (mounted) {
        setState(() => app[key] = previous);
        widget.onError(error);
      }
    } finally {
      if (mounted) setState(() => _pendingChanges.remove(operation));
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
              _AnimatedEntry(
                index: 0,
                active: widget.active,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SearchBar(
                    leading: const Icon(Icons.search),
                    hintText: tr(context, 'search'),
                    onChanged: (value) => setState(() => _query = value),
                  ),
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
                            return _AnimatedEntry(
                              key: ValueKey(app['packageName']),
                              index: index + 1,
                              active: widget.active,
                              animate: index < 8,
                              child: Card(
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
                                                  gaplessPlayback: true,
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
                                      enabled:
                                          !blocked &&
                                          !_pendingChanges.contains(
                                            '${app['uid']}:enabled',
                                          ),
                                      onChanged: (value) =>
                                          _set(app, 'enabled', value),
                                    ),
                                    _AnimatedSwitchRow(
                                      title: tr(context, 'blocked'),
                                      value: blocked,
                                      enabled: !_pendingChanges.contains(
                                        '${app['uid']}:blocked',
                                      ),
                                      onChanged: (value) =>
                                          _set(app, 'blocked', value),
                                    ),
                                  ],
                                ),
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
  const UserManagementPage({
    required this.active,
    required this.onError,
    super.key,
  });

  final bool active;
  final void Function(Object error) onError;

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late Future<List<Map<String, dynamic>>> _users = DhizukuApi.getUsers();

  void _reload() => setState(() => _users = DhizukuApi.getUsers());

  Future<void> _remove(Map<String, dynamic> user) async {
    final failedMessage = tr(context, 'operation_failed');
    final confirm = await showDhizukuDialog<bool>(
      context,
      (context) => prism.AlertDialog(
        title: tr(context, 'remove_user'),
        destructive: true,
        actions: [
          DhizukuTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          DhizukuTextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'remove')),
          ),
        ],
        child: Text('${user['name']}\n\n${tr(context, 'delete_user_warning')}'),
      ),
    );
    if (confirm != true) return;
    try {
      final removed = await DhizukuApi.removeUser(user['id'] as int);
      if (!removed) {
        if (mounted) _showActionError(context, failedMessage);
        return;
      }
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
          final users = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _AnimatedEntry(
                      index: 0,
                      active: widget.active,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: ShapeDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  shape: prism.AppShape.lg,
                                ),
                                child: Icon(
                                  Icons.people_alt_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr(context, 'users_title'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tr(context, 'users_description'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: ShapeDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  shape: prism.AppShape.full,
                                ),
                                child: Text(
                                  tr(context, 'user_count').replaceAll(
                                    '{count}',
                                    users.length.toString(),
                                  ),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle(tr(context, 'users_list')),
                    if (users.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(child: Text(tr(context, 'no_users'))),
                        ),
                      ),
                    for (var index = 0; index < users.length; index++)
                      _userCard(context, users[index], index),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _userCard(BuildContext context, Map<String, dynamic> user, int index) {
    final current = user['current'] == true;
    final id = user['id'] as int;
    return _AnimatedEntry(
      key: ValueKey(id),
      index: index + 1,
      active: widget.active,
      animate: index < 8,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Row(
            children: [
              Expanded(
                child: _InteractiveListRow(
                  leading: CircleAvatar(
                    backgroundColor: current
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor: current
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    child: const Icon(Icons.person_outline_rounded),
                  ),
                  title: Text(user['name'].toString()),
                  subtitle: Text(
                    tr(context, 'user_id').replaceAll('{id}', id.toString()),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    dhizukuPageRoute<void>(
                      (_) => AccountManagementPage(user: user),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (current)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: ShapeDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            shape: prism.AppShape.full,
                          ),
                          child: Text(
                            tr(context, 'current_user'),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                          ),
                        ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              if (!current)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Tooltip(
                    message: tr(context, 'remove_user_action'),
                    child: DhizukuPressSurface(
                      fill: Colors.transparent,
                      shape: prism.AppShape.full,
                      look: prism.PressLook.tint,
                      onPressed: () => _remove(user),
                      minimum: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.settings,
    required this.appearance,
    required this.active,
    required this.onChanged,
    super.key,
  });

  final Map<String, dynamic> settings;
  final AppearanceSettings appearance;
  final bool active;
  final ValueChanged<Map<String, dynamic>> onChanged;

  Future<void> _toggle(BuildContext context, String key, bool value) async {
    try {
      onChanged(await DhizukuApi.setSetting(key, value));
    } catch (error) {
      if (context.mounted) _showActionError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
    children: [
      _AnimatedEntry(
        index: 0,
        active: active,
        child: Card(
          child: _InteractiveListRow(
            leading: const Icon(Icons.palette_outlined),
            title: Text(tr(context, 'appearance_group')),
            subtitle: Text(tr(context, 'appearance_summary')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onPressed: () => Navigator.of(context).push(
              dhizukuPageRoute<void>(
                (_) => AppearanceSettingsPage(appearance: appearance),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      _AnimatedEntry(
        index: 1,
        active: active,
        child: Card(
          child: _InteractiveListRow(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(tr(context, 'user_guide')),
            subtitle: Text(tr(context, 'guide_intro')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onPressed: () =>
                Navigator.of(context)
                    .push(dhizukuPageRoute<void>((_) => const UserGuidePage())),
          ),
        ),
      ),
      const SizedBox(height: 24),
      _SectionTitle(tr(context, 'preferences_group')),
      _AnimatedEntry(
        index: 2,
        active: active,
        child: Card(
          child: Column(
            children: [
              _AnimatedSwitchRow(
                title: tr(context, 'dhizuku_enabled'),
                value: settings['dhizukuEnabled'] == true,
                onChanged: (value) => _toggle(context, 'dhizukuEnabled', value),
              ),
              const Divider(indent: 16, endIndent: 16),
              _AnimatedSwitchRow(
                title: tr(context, 'whitelist'),
                subtitle: tr(context, 'api_access'),
                value: settings['whitelistMode'] == true,
                onChanged: (value) => _toggle(context, 'whitelistMode', value),
              ),
              const Divider(indent: 16, endIndent: 16),
              _AnimatedSwitchRow(
                title: tr(context, 'hide_donate'),
                value: settings['donateButtonHidden'] == true,
                onChanged: (value) =>
                    _toggle(context, 'donateButtonHidden', value),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      _SectionTitle(tr(context, 'about_group')),
      _AnimatedEntry(
        index: 3,
        active: active,
        child: Card(
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
                onPressed: () =>
                    DhizukuApi.openUrl(tr(context, 'donation_url')),
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
      ),
    ],
  );
}

class UserGuidePage extends StatelessWidget {
  const UserGuidePage({super.key});

  Future<void> _openAccounts(BuildContext context) async {
    try {
      final opened = await DhizukuApi.openSystemAccountSettings();
      if (!opened && context.mounted) {
        _showActionError(context, tr(context, 'system_accounts_unavailable'));
      }
    } catch (error) {
      if (context.mounted) _showActionError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr(context, 'user_guide'))),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _GuideSection(
          index: 0,
          title: tr(context, 'guide_apps_title'),
          body: tr(context, 'guide_apps_body'),
        ),
        _GuideSection(
          index: 1,
          title: tr(context, 'guide_accounts_title'),
          body: tr(context, 'guide_accounts_body'),
          action: FilledButton.tonalIcon(
            onPressed: () => _openAccounts(context),
            icon: const Icon(Icons.settings_outlined),
            label: Text(tr(context, 'guide_open_accounts')),
          ),
        ),
        _GuideSection(
          index: 2,
          title: tr(context, 'guide_activation_title'),
          body: tr(context, 'guide_activation_body'),
        ),
      ],
    ),
  );
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.index,
    required this.title,
    required this.body,
    this.action,
  });

  final int index;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _AnimatedEntry(
    index: index,
    child: Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    ),
  );
}

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({required this.appearance, super.key});

  final AppearanceSettings appearance;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr(context, 'appearance_group'))),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _AnimatedEntry(
              index: 0,
              child: _AppearanceSettingsCard(appearance: appearance),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AppearanceSettingsCard extends StatelessWidget {
  const _AppearanceSettingsCard({required this.appearance});

  final AppearanceSettings appearance;

  Future<void> _update(
    BuildContext context,
    Future<void> Function() change,
  ) async {
    try {
      await change();
    } catch (error) {
      if (context.mounted) _showActionError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final colorStyle = prism.ColorStyle.values.firstWhere(
      (style) => style.name == appearance.colorStyle,
      orElse: () => prism.ColorStyle.vivid,
    );
    final preview = prism.seededColorScheme(
      seedColor: appearance.activeSeedColor,
      brightness: colors.brightness,
      style: colorStyle,
    );
    final colorOptions = <({String label, int color, bool system})>[
      if (appearance.systemSeedColor case final systemColor?)
        (label: 'theme_system', color: systemColor, system: true),
      (label: 'theme_blue', color: 0xff007aff, system: false),
      (label: 'theme_purple', color: 0xff6750a4, system: false),
      (label: 'theme_teal', color: 0xff008c8c, system: false),
      (label: 'theme_green', color: 0xff386a20, system: false),
      (label: 'theme_orange', color: 0xffa05b00, system: false),
      (label: 'theme_rose', color: 0xffb3265e, system: false),
    ];
    return Card(
      shape: prism.AppShape.xxl.copyWith(
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              decoration: ShapeDecoration(
                color: preview.primaryContainer,
                shape: prism.AppShape.xl,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    width: 42,
                    height: 42,
                    decoration: ShapeDecoration(
                      color: preview.primary,
                      shape: prism.AppShape.lg,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: preview.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'theme_preview'),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: preview.onPrimaryContainer),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tr(context, 'theme_preview_subtitle'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: preview.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: ShapeDecoration(
                      color: preview.primary,
                      shape: prism.AppShape.lg,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text(
                        tr(context, 'theme_preview_button'),
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: preview.onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(tr(context, 'theme_mode')),
            SizedBox(
              width: double.infinity,
              child: _ThemeSegmentedControl<ThemeMode>(
                segments: [
                  (ThemeMode.system, tr(context, 'theme_system')),
                  (ThemeMode.light, tr(context, 'theme_light')),
                  (ThemeMode.dark, tr(context, 'theme_dark')),
                ],
                value: appearance.themeMode,
                onChanged: (value) => unawaited(
                  _update(context, () => appearance.update(themeMode: value)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(tr(context, 'theme_color')),
            _ThemeColorSelector(
              options: [
                for (final option in colorOptions)
                  (
                    label: tr(context, option.label),
                    color: Color(option.color),
                    icon: option.system ? Icons.auto_awesome_rounded : null,
                  ),
              ],
              selectedIndex: colorOptions.indexWhere(
                (option) => option.system
                    ? appearance.useSystemColor
                    : !appearance.useSystemColor &&
                          appearance.seedColor == option.color,
              ),
              onSelected: (index) {
                final option = colorOptions[index];
                unawaited(
                  _update(
                    context,
                    () => appearance.update(
                      useSystemColor: option.system,
                      seedColor: option.color,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _SectionTitle(tr(context, 'theme_color_style')),
            SizedBox(
              width: double.infinity,
              child: _ThemeSegmentedControl<String>(
                segments: [
                  for (final style in prism.ColorStyle.values)
                    (style.name, tr(context, 'style_${style.name}')),
                ],
                value: appearance.colorStyle,
                onChanged: (value) => unawaited(
                  _update(context, () => appearance.update(colorStyle: value)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSegmentedControl<T> extends StatelessWidget {
  const _ThemeSegmentedControl({
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String)> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final count = segments.length;
    final index = segments.indexWhere((segment) => segment.$1 == value);
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHigh,
        shape: prism.AppShape.full.copyWith(
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Stack(
        children: [
          if (index >= 0)
            AnimatedAlign(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              alignment: AlignmentDirectional(
                count == 1 ? 0 : index * 2 / (count - 1) - 1,
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: colors.primary,
                    shape: prism.AppShape.full,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (final (option, label) in segments)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final selected = option == value;
                      return DhizukuPressSurface(
                        fill: Colors.transparent,
                        shape: prism.AppShape.full,
                        look: selected
                            ? prism.PressLook.none
                            : prism.PressLook.tint,
                        childFills: true,
                        onPressed: selected ? null : () => onChanged(option),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style:
                                (Theme.of(context).textTheme.labelLarge ??
                                        const TextStyle())
                                    .copyWith(
                                      color: selected
                                          ? colors.onPrimary
                                          : colors.onSurfaceVariant,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeColorSelector extends StatelessWidget {
  const _ThemeColorSelector({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<({String label, Color color, IconData? icon})> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final count = options.length;
    final selected = selectedIndex.clamp(0, count - 1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minContentWidth = count * 76.0;
        final contentWidth = constraints.maxWidth > minContentWidth
            ? constraints.maxWidth
            : minContentWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            height: 88,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: ShapeDecoration(
                color: colors.surfaceContainerHigh,
                shape: prism.AppShape.full.copyWith(
                  side: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    alignment: AlignmentDirectional(
                      count == 1 ? 0 : selected * 2 / (count - 1) - 1,
                      0,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 1 / count,
                      heightFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: colors.primary,
                            shape: prism.AppShape.full,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var index = 0; index < count; index++)
                        Expanded(
                          child: _ThemeColorOption(
                            option: options[index],
                            selected: index == selected,
                            onPressed: () => onSelected(index),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThemeColorOption extends StatelessWidget {
  const _ThemeColorOption({
    required this.option,
    required this.selected,
    required this.onPressed,
  });

  final ({String label, Color color, IconData? icon}) option;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DhizukuPressSurface(
      fill: Colors.transparent,
      shape: prism.AppShape.full,
      look: prism.PressLook.none,
      minimum: const BoxConstraints(minHeight: 76),
      onPressed: selected ? null : onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOutCubic,
            scale: selected ? 1 : 0.88,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeInOutCubic,
              width: 30,
              height: 30,
              decoration: ShapeDecoration(
                color: option.color,
                shape: prism.AppShape.circle.copyWith(
                  side: BorderSide(
                    color: selected ? colors.onPrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: option.icon == null
                  ? null
                  : Icon(
                      option.icon,
                      size: 16,
                      color: selected
                          ? colors.onPrimary
                          : ThemeData.estimateBrightnessForColor(
                                  option.color,
                                ) ==
                                Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOutCubic,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage>
    with WidgetsBindingObserver {
  late Future<Map<String, dynamic>> _data = _load();
  bool _refreshOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _refreshOnResume && mounted) {
      _refreshOnResume = false;
      _reload();
    }
  }

  Future<Map<String, dynamic>> _load() =>
      DhizukuApi.getAccountData(widget.user['id'] as int);

  void _reload() => setState(() => _data = _load());

  String _accountProviderLabel(Map<String, dynamic> account) {
    final provider = account['providerLabel']?.toString() ?? '';
    if (provider.isNotEmpty && provider.toLowerCase() != 'null') {
      return tr(context, 'account_from').replaceAll('{provider}', provider);
    }
    final type = account['type']?.toString() ?? '';
    return tr(
      context,
      'account_type',
    ).replaceAll('{type}', type.isEmpty ? '—' : type);
  }

  String _accountName(Map<String, dynamic> account) {
    final name = account['name']?.toString() ?? '';
    return _isMaskedAccountName(name)
        ? tr(context, 'account_name_hidden')
        : name;
  }

  bool _isMaskedAccountName(String name) => RegExp(
    r'^(?:x{3,}|[*•·]{3,})$',
    caseSensitive: false,
  ).hasMatch(name.trim());

  String _authenticatorLabel(Map<String, dynamic> item) {
    final label = item['label']?.toString() ?? '';
    final cleanLabel = label
        .replaceFirst(RegExp(r'\s*-\s*null$', caseSensitive: false), '')
        .trim();
    return cleanLabel.isEmpty || cleanLabel.toLowerCase() == 'null'
        ? item['packageName'].toString()
        : cleanLabel;
  }

  Future<void> _openSystemAccounts() async {
    _refreshOnResume = true;
    try {
      final opened = await DhizukuApi.openSystemAccountSettings();
      if (!opened) {
        _refreshOnResume = false;
        if (mounted) {
          _showActionError(context, tr(context, 'system_accounts_unavailable'));
        }
      }
    } catch (error) {
      _refreshOnResume = false;
      if (mounted) _showActionError(context, error);
    }
  }

  Future<void> _toggleAuthenticator(
    Map<String, dynamic> item,
    bool enabled,
  ) async {
    final failedMessage = tr(context, 'operation_failed');
    try {
      final updated = await DhizukuApi.setAuthenticatorEnabled(
        userId: widget.user['id'] as int,
        packageName: item['packageName'].toString(),
        label: item['label'].toString(),
        type: item['type'].toString(),
        enabled: enabled,
      );
      if (!updated) throw StateError(failedMessage);
      _reload();
    } catch (error) {
      if (mounted) _showActionError(context, error);
    }
  }

  Future<void> _removeAccount(Map<String, dynamic> account) async {
    if (_isMaskedAccountName(account['name']?.toString() ?? '')) {
      final openSettings = await showDhizukuDialog<bool>(
        context,
        (context) => prism.AlertDialog(
          title: tr(context, 'account_name_hidden_title'),
          actions: [
            DhizukuTextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr(context, 'cancel')),
            ),
            DhizukuTextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr(context, 'guide_open_accounts')),
            ),
          ],
          child: Text(tr(context, 'account_name_hidden_body')),
        ),
      );
      if (openSettings == true) await _openSystemAccounts();
      return;
    }
    final failedMessage = tr(context, 'operation_failed');
    final confirm = await showDhizukuDialog<bool>(
      context,
      (context) => prism.AlertDialog(
        title: tr(context, 'remove_account'),
        destructive: true,
        actions: [
          DhizukuTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          DhizukuTextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'remove')),
          ),
        ],
        child: Text(
          '${account['name']}\n\n${tr(context, 'remove_account_warning')}',
        ),
      ),
    );
    if (confirm == true) {
      try {
        final status = await DhizukuApi.removeAccount(account);
        if (status == 'removed') {
          _refreshOnResume = false;
          _reload();
        } else if (status == 'confirmation_required') {
          _refreshOnResume = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(tr(context, 'account_confirmation_pending')),
              ),
            );
          }
        } else {
          if (mounted) _showActionError(context, failedMessage);
        }
      } catch (error) {
        if (mounted) _showActionError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.user['name'].toString()),
      actions: [
        DhizukuIconButton(
          tooltip: tr(context, 'open_system_accounts'),
          onPressed: _openSystemAccounts,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
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
              _DescribedSectionTitle(
                title: tr(context, 'authenticators'),
                description: tr(context, 'authenticators_description'),
              ),
              if (authenticators.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(tr(context, 'no_data')),
                ),
              for (var index = 0; index < authenticators.length; index++)
                _AnimatedEntry(
                  key: ValueKey(
                    'authenticator-${authenticators[index]['packageName']}',
                  ),
                  index: index,
                  animate: index < 8,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _AnimatedSwitchRow(
                      leading: _packageIcon(
                        context,
                        authenticators[index]['icon'],
                        fallback: Icons.extension_outlined,
                        size: 44,
                      ),
                      title: _authenticatorLabel(authenticators[index]),
                      subtitle: authenticators[index]['packageName'].toString(),
                      value: authenticators[index]['frozen'] != true,
                      onChanged: (enabled) =>
                          _toggleAuthenticator(authenticators[index], enabled),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _DescribedSectionTitle(
                title: tr(context, 'accounts'),
                description: tr(context, 'accounts_description'),
              ),
              if (accounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(tr(context, 'no_data')),
                ),
              for (var index = 0; index < accounts.length; index++)
                _AnimatedEntry(
                  key: ValueKey('account-${accounts[index]['name']}-$index'),
                  index: authenticators.length + index,
                  animate: index < 8,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _InteractiveListRow(
                      leading: _packageIcon(
                        context,
                        accounts[index]['icon'],
                        fallback: Icons.account_circle_outlined,
                        size: 44,
                      ),
                      title: Text(_accountName(accounts[index])),
                      subtitle: Text(_accountProviderLabel(accounts[index])),
                      trailing: DhizukuPressFeedback(
                        child: IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            fixedSize: const Size(52, 40),
                            shape: const StadiumBorder(),
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .error,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .errorContainer,
                          ),
                          tooltip: tr(context, 'remove_account_tooltip'),
                          onPressed: () => _removeAccount(accounts[index]),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

final _activationSpring = SpringDescription.withDurationAndBounce(
  duration: const Duration(milliseconds: 420),
  bounce: 0.15,
);

class _ActivationChoiceCards<T> extends StatefulWidget {
  const _ActivationChoiceCards({
    required this.choices,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String, IconData)> choices;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  State<_ActivationChoiceCards<T>> createState() =>
      _ActivationChoiceCardsState<T>();
}

class _ActivationChoiceCardsState<T> extends State<_ActivationChoiceCards<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _selectionScale =
      AnimationController.unbounded(vsync: this, value: 1);

  @override
  void didUpdateWidget(covariant _ActivationChoiceCards<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectionScale.value = 0.92;
      _selectionScale.animateWith(
        SpringSimulation(_activationSpring, _selectionScale.value, 1, 0),
      );
    }
  }

  @override
  void dispose() {
    _selectionScale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var index = 0; index < widget.choices.length; index++) ...[
          if (index > 0) const SizedBox(width: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: _selectionScale,
              builder: (context, child) => Transform.scale(
                scale: widget.choices[index].$1 == widget.value
                    ? _selectionScale.value
                    : 1,
                child: child,
              ),
              child: Builder(
                builder: (context) {
                  final (value, label, icon) = widget.choices[index];
                  final selected = value == widget.value;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    decoration: ShapeDecoration(
                      color: selected
                          ? colors.primaryContainer
                          : colors.surfaceContainerLow,
                      shape: prism.AppShape.xl,
                      shadows: selected
                          ? [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.12),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : const [],
                    ),
                    child: DhizukuPressSurface(
                      fill: Colors.transparent,
                      shape: prism.AppShape.xl,
                      look: selected
                          ? prism.PressLook.none
                          : prism.PressLook.tint,
                      selected: selected,
                      childFills: true,
                      onPressed: selected
                          ? () {}
                          : () {
                              HapticFeedback.selectionClick();
                              widget.onChanged(value);
                            },
                      padding: const EdgeInsets.all(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 76),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedScale(
                                    scale: selected ? 1.08 : 1,
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      icon,
                                      size: 24,
                                      color: selected
                                          ? colors.onPrimaryContainer
                                          : colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: selected
                                              ? colors.onPrimaryContainer
                                              : colors.onSurface,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional.topEnd,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                      scale: animation,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    ),
                                child: selected
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        key: const ValueKey(true),
                                        size: 18,
                                        color: colors.primary,
                                      )
                                    : const SizedBox.square(
                                        key: ValueKey(false),
                                        dimension: 18,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
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

  String _adminKey(Map<String, dynamic> admin) =>
      '${admin['packageName']}/${admin['className']}';

  String? _currentAdminKey(List<Map<String, dynamic>> admins) {
    if (admins.isEmpty) return null;
    return admins.any((admin) => _adminKey(admin) == _selected)
        ? _selected
        : _adminKey(admins.first);
  }

  Future<void> _chooseAdmin(List<Map<String, dynamic>> admins) async {
    final selectedKey = _currentAdminKey(admins);
    if (selectedKey == null) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 360),
              reverseDuration: Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            ),
      builder: (context) =>
          _AdminPickerSheet(admins: admins, selectedKey: selectedKey),
    );
    if (selected != null && mounted) {
      setState(() => _selected = selected);
    }
  }

  Future<void> _chooseOwnerType(String value) async {
    if (value != 'profile') {
      setState(() => _ownerType = value);
      return;
    }
    final confirmed = await showDhizukuDialog<bool>(
      context,
      (context) => prism.AlertDialog(
        title: tr(context, 'profile_owner_warning_title'),
        trailing: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        actions: [
          DhizukuTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          DhizukuTextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'confirm')),
          ),
        ],
        child: Text(tr(context, 'profile_owner_warning_dsp')),
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _ownerType = value);
    }
  }

  Future<void> _activate(List<Map<String, dynamic>> admins) async {
    if (_busy) return;
    final selectedKey = _currentAdminKey(admins);
    if (selectedKey == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr(context, 'no_admins'))));
      return;
    }
    final selected = admins.firstWhere(
      (item) => _adminKey(item) == selectedKey,
    );
    setState(() => _busy = true);
    bool? confirmed;
    try {
      confirmed = await showDhizukuDialog<bool>(
        context,
        (context) => prism.AlertDialog(
          title: tr(context, 'activate'),
          actions: [
            DhizukuTextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr(context, 'cancel')),
            ),
            DhizukuTextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr(context, 'confirm')),
            ),
          ],
          child: Text(
            tr(
              context,
              _mode == 'dhizuku'
                  ? 'activation_warning_dhizuku'
                  : _ownerType == 'profile'
                  ? 'activation_warning_shizuku_profile'
                  : 'activation_warning_shizuku_device',
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, 'error')}: $error')),
        );
      }
      return;
    }
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _busy = false);
      return;
    }
    var cancelRequested = false;
    var progressOpen = true;
    var retryAfterFailure = false;
    var openGuideAfterFailure = false;
    var openAccountsAfterFailure = false;
    unawaited(
      showDhizukuDialog<void>(
        context,
        (dialogContext) => PopScope(
          canPop: false,
          child: prism.AlertDialog(
            title: tr(dialogContext, 'activate'),
            actions: [
              DhizukuTextButton(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(tr(dialogContext, 'activation_running')),
              ],
            ),
          ),
        ),
        dismissible: false,
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
      await showDhizukuDialog<void>(
        context,
        (dialogContext) => prism.AlertDialog(
          title: tr(dialogContext, 'activated'),
          actions: [
            DhizukuTextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr(dialogContext, 'finish')),
            ),
          ],
          child: Text(tr(dialogContext, 'activation_success')),
        ),
        dismissible: false,
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
        final details = error.toString();
        final normalized = details.toLowerCase();
        final accountsRemain =
            normalized.contains('already some accounts') ||
            normalized.contains('accounts on the device');
        final action = await showDhizukuDialog<String>(
          context,
          (dialogContext) => prism.AlertDialog(
            title: tr(dialogContext, 'activation_failed'),
            actions: [
              DhizukuTextButton(
                onPressed: () => Navigator.pop(dialogContext, 'close'),
                child: Text(tr(dialogContext, 'cancel')),
              ),
              if (accountsRemain)
                DhizukuTextButton(
                  onPressed: () => Navigator.pop(dialogContext, 'accounts'),
                  child: Text(tr(dialogContext, 'guide_open_accounts')),
                ),
              DhizukuTextButton(
                onPressed: () => Navigator.pop(dialogContext, 'guide'),
                child: Text(tr(dialogContext, 'user_guide')),
              ),
              DhizukuTextButton(
                onPressed: () => Navigator.pop(dialogContext, 'retry'),
                child: Text(tr(dialogContext, 'retry')),
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountsRemain
                      ? tr(dialogContext, 'activation_accounts_blocked')
                      : tr(
                          dialogContext,
                          _mode == 'dhizuku'
                              ? 'activation_dhizuku_troubleshoot'
                              : 'activation_shizuku_troubleshoot',
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr(dialogContext, 'error_details'),
                  style: Theme.of(dialogContext).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.22,
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      details,
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: DhizukuTextButton(
                    onPressed: () => Navigator.pop(dialogContext, 'copy'),
                    child: Text(tr(dialogContext, 'copy_error')),
                  ),
                ),
              ],
            ),
          ),
        );
        retryAfterFailure = action == 'retry';
        openGuideAfterFailure = action == 'guide';
        openAccountsAfterFailure = action == 'accounts';
        if (action == 'copy') {
          await Clipboard.setData(ClipboardData(text: details));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr(context, 'error_copied'))),
            );
          }
        }
      }
    } finally {
      if (progressOpen && mounted) Navigator.of(context).pop();
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (openAccountsAfterFailure) {
      final unavailableMessage = tr(context, 'system_accounts_unavailable');
      try {
        final opened = await DhizukuApi.openSystemAccountSettings();
        if (!opened && mounted) {
          _showActionError(context, unavailableMessage);
        }
      } catch (error) {
        if (mounted) _showActionError(context, error);
      }
    }
    if (!mounted) return;
    if (openGuideAfterFailure) {
      await Navigator.of(context)
          .push<void>(dhizukuPageRoute<void>((_) => const UserGuidePage()));
    }
    if (retryAfterFailure) await _activate(admins);
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
        final currentSelection = _currentAdminKey(admins)!;
        final selectedAdmin = admins.firstWhere(
          (item) => _adminKey(item) == currentSelection,
        );
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AnimatedEntry(
              index: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'activation_info'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _AnimatedEntry(
              index: 1,
              child: Column(
                children: [
                  _SectionTitle(tr(context, 'admin')),
                  Card(
                    child: _InteractiveListRow(
                      leading: _packageIcon(
                        context,
                        selectedAdmin['icon'],
                        fallback: Icons.admin_panel_settings_outlined,
                        size: 44,
                      ),
                      title: Text(selectedAdmin['label'].toString()),
                      subtitle: Text(
                        selectedAdmin['packageName'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.expand_more_rounded),
                      onPressed: () => _chooseAdmin(admins),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              child: _mode == 'shizuku'
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _AnimatedEntry(
                        index: 2,
                        child: Column(
                          children: [
                            _SectionTitle(tr(context, 'owner_type')),
                            _ActivationChoiceCards<String>(
                              choices: [
                                (
                                  'device',
                                  tr(context, 'device'),
                                  Icons.phone_android_rounded,
                                ),
                                (
                                  'profile',
                                  tr(context, 'profile'),
                                  Icons.workspaces_rounded,
                                ),
                              ],
                              value: _ownerType,
                              onChanged: _chooseOwnerType,
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            _AnimatedEntry(
              index: 3,
              child: Column(
                children: [
                  _SectionTitle(tr(context, 'activation_mode')),
                  _ActivationChoiceCards<String>(
                    choices: [
                      (
                        'dhizuku',
                        tr(context, 'dhizuku_mode'),
                        Icons.shield_rounded,
                      ),
                      (
                        'shizuku',
                        tr(context, 'shizuku_mode'),
                        Icons.terminal_rounded,
                      ),
                    ],
                    value: _mode,
                    onChanged: (value) => setState(() {
                      _mode = value;
                      if (_mode == 'dhizuku') _ownerType = 'device';
                    }),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      tr(
                        context,
                        _mode == 'dhizuku'
                            ? 'activation_dhizuku_detail'
                            : 'activation_shizuku_detail',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _AnimatedEntry(
              index: 4,
              child: DhizukuPressFeedback(
                enabled: !_busy,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _activate(admins),
                  style: const ButtonStyle(
                    shape: WidgetStatePropertyAll(StadiumBorder()),
                  ),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _busy
                        ? const SizedBox.square(
                            key: ValueKey('busy'),
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, key: ValueKey('ready')),
                  ),
                  label: Text(tr(context, 'activate')),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _AdminPickerSheet extends StatelessWidget {
  const _AdminPickerSheet({required this.admins, required this.selectedKey});

  final List<Map<String, dynamic>> admins;
  final String selectedKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 32,
                height: 4,
                decoration: ShapeDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  shape: prism.AppShape.full,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(context, 'choose_admin_app'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    DhizukuIconButton(
                      tooltip: tr(context, 'cancel'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: admins.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final admin = admins[index];
                    final key = '${admin['packageName']}/${admin['className']}';
                    final selected = key == selectedKey;
                    return _AnimatedEntry(
                      index: index,
                      animate: index < 8,
                      child: DhizukuPressSurface(
                        fill: selected
                            ? colors.secondaryContainer
                            : Colors.transparent,
                        shape: prism.AppShape.xl,
                        look: prism.PressLook.tint,
                        onPressed: () => Navigator.pop(context, key),
                        childFills: true,
                        child: prism.ListRow(
                          leading: _packageIcon(
                            context,
                            admin['icon'],
                            fallback: Icons.admin_panel_settings_outlined,
                            size: 44,
                          ),
                          title: Text(
                            admin['label'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            admin['packageName'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: selected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: colors.onSecondaryContainer,
                                )
                              : null,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minHeight: 72,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            child: _AnimatedEntry(
              index: 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.data['icon'] is Uint8List)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            widget.data['icon'] as Uint8List,
                            width: 48,
                            height: 48,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.privacy_tip_outlined,
                              size: 40,
                            ),
                          ),
                        )
                      else
                        const Icon(Icons.privacy_tip_outlined, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        '${widget.data['label'] ?? widget.data['packageName']} '
                        '${tr(context, 'permission_request_suffix')}',
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
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.25),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: Text(
                              '$_remaining ${tr(context, 'auto_deny')}',
                              key: ValueKey(_remaining),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: DhizukuPressFeedback(
                          enabled: !_responded,
                          child: FilledButton(
                            onPressed: _responded ? null : () => _respond(true),
                            child: Text(tr(context, 'allow')),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: DhizukuPressFeedback(
                          enabled: !_responded,
                          child: FilledButton.tonal(
                            onPressed: _responded
                                ? null
                                : () => _respond(false),
                            child: Text(tr(context, 'deny')),
                          ),
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
    ),
  );
}

class _AnimatedEntry extends StatefulWidget {
  const _AnimatedEntry({
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
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _scheduleEntry();
  }

  void _scheduleEntry() {
    _timer = Timer(Duration(milliseconds: widget.index.clamp(0, 8) * 32), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void didUpdateWidget(covariant _AnimatedEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _timer?.cancel();
      _visible = false;
      _scheduleEntry();
    } else if (oldWidget.active && !widget.active) {
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.035),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: _visible ? 1 : 0.985,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
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

class _DescribedSectionTitle extends StatelessWidget {
  const _DescribedSectionTitle({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
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

void _showActionError(BuildContext context, Object error) {
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text('${tr(context, 'error')}: $error')));
}
