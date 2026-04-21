//  OpenPlayer - Liberated Audio Experience
//  Copyright (C) 2024 [Tu Nombre o Alias]
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  Branding, logos and UI design are licensed under CC BY-NC-ND 4.0.
//  You should have received a copy of the GNU AGPL v3 along with this program.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_localeName(locale, l10n)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context, ref, l10n),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de OpenPlayer'),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  String _localeName(Locale locale, AppLocalizations l10n) {
    switch (locale.languageCode) {
      case 'es':
        return l10n.spanish;
      case 'en':
      default:
        return l10n.english;
    }
  }

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Locale>(
              title: Text(l10n.spanish),
              value: const Locale('es'),
              groupValue: ref.watch(localeProvider),
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale>(
              title: Text(l10n.english),
              value: const Locale('en'),
              groupValue: ref.watch(localeProvider),
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'OpenPlayer',
      applicationVersion: '1.0.0',
      applicationIcon:
          Image.asset('assets/OpenPlayer.png', width: 48, height: 48),
      applicationLegalese:
          '© 2026 Jheery Richard Barrientos Camacho (CYBER_ROOT).\n'
          'Licencia AGPLv3.\n'
          'Desarrollado con Flutter',
      children: [
        const SizedBox(height: 16),
        const Text('Creador: Jheery Richard Barrientos Camacho'),
        const Text('Alias: CYBER_ROOT'),
        const SelectableText('GitHub: @CYBER_ROOT'),
        const SelectableText('Mastodon / X: @CYBER_ROOT'),
        const SelectableText('Correo: j.barrientos.tech@gmail.com'),
      ],
    );
  }
}
