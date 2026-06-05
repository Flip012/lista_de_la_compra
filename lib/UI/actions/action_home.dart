import 'package:flutter/material.dart';
import 'package:lista_de_la_compra/UI/actions/export_controls.dart';
import 'package:lista_de_la_compra/UI/sync/sync_view.dart';
import 'package:lista_de_la_compra/l10n/app_localizations.dart';
import 'package:lista_de_la_compra/shared_preference_providers/persistant_shared_preferences_provider.dart';
import 'package:provider/provider.dart';

import 'package:lista_de_la_compra_backend/lista_de_la_compra_backend.dart';

class ActionHome extends StatelessWidget {
  final String enviromentId;
  final OpenConnectionManager openConnectionManager;

  const ActionHome(this.enviromentId, this.openConnectionManager, {super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLoc = AppLocalizations.of(context)!;
    final SharedPreferencesProvider sharedPreferencesProvider = context.watch<PersistantSharedPreferencesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLoc.actions, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            FutureBuilder<String>(
              future: sharedPreferencesProvider.getLocalNick(),
              builder: (context, snap) {
                final currentNick = snap.data ?? appLoc.loading;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(appLoc.nick),
                    subtitle: Text(currentNick),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      final controller = TextEditingController(text: snap.data ?? '');
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(appLoc.changeNick),
                          content: TextField(
                            decoration: InputDecoration(labelText: appLoc.nick),
                            controller: controller,
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(appLoc.cancel),
                            ),
                            TextButton(
                              onPressed: () async {
                                await sharedPreferencesProvider.setLocalNick(controller.text.trim());
                                if (context.mounted) Navigator.of(context).pop();
                                openConnectionManager.triggerHandshakePush();
                              },
                              child: Text(appLoc.save),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              child: Row(children: [Icon(Icons.swap_horiz), SizedBox(width: 8), Text(appLoc.switchEnvironment)]),
              onPressed: () {
                sharedPreferencesProvider.clearSelectedEnvironment();
              },
            ),

            OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SyncView(openConnectionManager)));
              },
              child: Row(children: [Icon(Icons.add_link), SizedBox(width: 8), Text(appLoc.syncronization)]),
            ),
            ExporControls(enviromentId),
          ],
        ),
      ),
    );
  }
}
