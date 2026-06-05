import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lista_de_la_compra/l10n/app_localizations.dart';
import 'package:lista_de_la_compra/UI/sync/http/http_view.dart';
import 'package:lista_de_la_compra/UI/sync/open_connections_widget.dart';

import 'package:lista_de_la_compra_backend/lista_de_la_compra_backend.dart';


class SyncView extends StatefulWidget {
  final OpenConnectionManager openConnectionManager;

  const SyncView(this.openConnectionManager, {super.key});

  @override
  State<SyncView> createState() => _SyncViewState();
}

class _SyncViewState extends State<SyncView> {
  HttpServer? server;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLoc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLoc.syncronization, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(appLoc.pairings, style: Theme.of(context).textTheme.titleSmall),
            OpenConnectionsList(),
            HTTPView(widget.openConnectionManager),
          ],
        ),
      ),
    );
  }
}
