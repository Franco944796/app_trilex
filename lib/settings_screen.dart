import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/content.dart';
import 'core/i18n.dart';
import 'core/services.dart';
import 'course/course.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? updateMsg;
  bool updating = false;

  String get _time {
    final m = progress.reminderAt;
    return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }

  Future<void> scheduleReminder() async {
    if (!progress.reminderOn) return reminders.cancel();
    await reminders.schedule(progress.reminderAt, tr('reminderTitle'), tr('reminderBody', {'m': progress.goal}));
  }

  Future<void> _toggleReminder(bool on) async {
    if (on && !await reminders.askPermission()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('remindersDenied'))));
      return;
    }
    progress.reminderOn = on;
    await progress.save();
    await scheduleReminder();
    setState(() {});
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: progress.reminderAt ~/ 60, minute: progress.reminderAt % 60),
    );
    if (t == null) return;
    progress.reminderAt = t.hour * 60 + t.minute;
    await progress.save();
    await scheduleReminder();
    setState(() {});
  }

  Future<void> _update() async {
    setState(() {
      updating = true;
      updateMsg = tr('updatesChecking');
    });
    try {
      final n = await content.update();
      if (n > 0) {
        await course.load();
        i18n.refresh();
      }
      updateMsg = n == 0 ? tr('updatesNone') : tr('updatesDone', {'n': n});
    } catch (e) {
      updateMsg = tr('updatesError');
    }
    if (mounted) setState(() => updating = false);
  }

  Future<bool> _confirm(String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(text),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('delete'))),
          ],
        ),
      ) ??
      false;

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Kicker(title, color: Tx.blue),
          const SizedBox(height: 8),
          ...children,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return PageList(children: [
      PageHeader(kicker: 'Trilex', title: tr('settingsTitle')),
      _section(tr('languageH'), [
        DropdownButtonFormField<String>(
          initialValue: i18n.lang,
          items: [for (final l in I18n.names.entries) DropdownMenuItem(value: l.key, child: Text(l.value))],
          onChanged: (v) async {
            if (v == null) return;
            await i18n.setLang(v);
            await course.loadPacks();
            i18n.refresh();
            await scheduleReminder();
          },
        ),
      ]),
      _section(tr('themeH'), [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (value, icon) in [
            ('auto', Icons.brightness_auto_outlined),
            ('light', Icons.light_mode_outlined),
            ('dark', Icons.dark_mode_outlined),
          ])
            ChoiceChip(
              avatar: Icon(icon, size: 18),
              showCheckmark: false,
              label: Text(tr('theme${value[0].toUpperCase()}${value.substring(1)}')),
              selected: themePref.choice == value,
              onSelected: (_) => themePref.set(value),
            ),
        ]),
      ]),
      _section(tr('goalTitle'), [
        Wrap(spacing: 8, children: [
          for (final m in [10, 20, 30])
            ChoiceChip(
              label: Text('$m min'),
              selected: progress.goal == m,
              onSelected: (_) async {
                progress.course['goal'] = m;
                await progress.save();
                await scheduleReminder();
                setState(() {});
              },
            ),
        ]),
      ]),
      _section(tr('remindersH'), [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: progress.reminderOn,
          title: Text(tr('remindersOn')),
          onChanged: _toggleReminder,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: progress.reminderOn,
          title: Text(tr('reminderTime')),
          trailing: Text(_time, style: const TextStyle(fontFamily: Tx.mono, fontSize: 16)),
          onTap: progress.reminderOn ? _pickTime : null,
        ),
      ]),
      _section(tr('updatesH'), [
        Text('${tr('contentVersion')}: ${content.version}', style: TextStyle(color: Tx.muted, fontSize: 13)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: updating ? null : _update, child: Text(tr('updatesCheck'))),
        if (updateMsg != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(updateMsg!)),
      ]),
      _section(tr('resetH'), [
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton(
            onPressed: () async {
              if (await _confirm(tr('resetConfirm'))) {
                await progress.resetCourse();
                setState(() {});
              }
            },
            child: Text(tr('resetProgress')),
          ),
          OutlinedButton(
            onPressed: () async {
              if (await _confirm(tr('resetReadingConfirm'))) {
                await progress.resetReading();
                setState(() {});
              }
            },
            child: Text(tr('resetReading')),
          ),
        ]),
      ]),
      _section(tr('aboutH'), [
        Text(tr('aboutText'), style: const TextStyle(height: 1.45)),
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => launchUrl(Uri.parse(Content.siteUrl), mode: LaunchMode.externalApplication),
          child: Text(tr('openWeb')),
        ),
      ]),
    ]);
  }
}
