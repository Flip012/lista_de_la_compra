import 'package:flutter/material.dart';
import 'package:lista_de_la_compra/UI/supermarket/add_products_to_isle.dart';
import 'package:lista_de_la_compra/flutter_providers/flutter_providers.dart';
import 'package:lista_de_la_compra/l10n/app_localizations.dart';
import 'package:lista_de_la_compra_backend/lista_de_la_compra_backend.dart';
import 'package:provider/provider.dart';

class Aisles extends StatefulWidget {
  final String supermarketId;

  const Aisles(this.supermarketId, {super.key});

  @override
  State<Aisles> createState() => _AislesState();
}

class _AislesState extends State<Aisles> {
  final TextEditingController _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AisleProvider aisleProvider = context.watch<FlutterAisleProvider>();
    final ProductAisleProvider productAisleProvider = context.watch<FlutterProductAisleProvider>();
    final AppLocalizations appLoc = AppLocalizations.of(context)!;

    Future<List<Aisle>> aisleFuture = aisleProvider.getAislesBySupermarket(widget.supermarketId);

    return FutureBuilder(
      future: aisleFuture,
      builder: (context, asyncSnapshot) {
        if (!asyncSnapshot.hasData) {
          return Text(appLoc.loading);
        }

        final aisles = asyncSnapshot.data!;

        void submitAdd() {
          final name = _addController.text.trim();
          if (name.isEmpty) return;
          aisleProvider.addAisle(name, widget.supermarketId);
          _addController.clear();
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: appLoc.add,
                          ),
                          onSubmitted: (_) => submitAdd(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.add), onPressed: submitAdd),
                    ],
                  ),
                ),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final ids = aisles.map((a) => a.id).toList();
                    final moved = ids.removeAt(oldIndex);
                    ids.insert(newIndex, moved);
                    aisleProvider.reorderAisles(ids);
                  },
                  children: [
                    for (int i = 0; i < aisles.length; i++)
                      ListTile(
                        key: ValueKey(aisles[i].id),
                        leading: ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_handle),
                        ),
                        title: Text(aisles[i].name),
                        subtitle: FutureBuilder(
                          future: productAisleProvider.getProductsByAisle(aisles[i].id),
                          builder: (context, snap) {
                            if (!snap.hasData) return Text(appLoc.loading);
                            return Text(appLoc.numberOfProducts(snap.data!.length));
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => aisleProvider.deleteById(aisles[i].id),
                              icon: const Icon(Icons.delete),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                final textController = TextEditingController(text: aisles[i].name);
                                final aisleId = aisles[i].id;
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(appLoc.editName),
                                      content: TextField(
                                        decoration: InputDecoration(labelText: appLoc.name),
                                        controller: textController,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text(appLoc.cancel),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            aisleProvider.setAisleName(aisleId, textController.text);
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(appLoc.save),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            IconButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddProductsToIsle(aisles[i].id)),
                              ),
                              icon: const Icon(Icons.format_list_bulleted_add),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SupermarketDetail extends StatelessWidget {
  final String supermarketId;

  const SupermarketDetail(this.supermarketId, {super.key});

  @override
  Widget build(BuildContext context) {
    final SuperMarketProvider superMarketProvider = context.watch<FlutterSuperMarketProvider>();

    final AppLocalizations appLoc = AppLocalizations.of(context)!;

    Future<SuperMarket?> supermarketFuture = superMarketProvider.getSuperMarketById(supermarketId);

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (s) {},
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  child: Row(children: [Icon(Icons.delete), SizedBox(width: 8), Text(appLoc.delete)]),
                  onTap: () {
                    Navigator.pop(context);
                    superMarketProvider.deleteById(supermarketId);
                  },
                ),
                PopupMenuItem(
                  child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text(appLoc.editName)]),
                  onTap: () {
                    TextEditingController textEditingController = TextEditingController();
                    supermarketFuture.then((supermarket) {
                      textEditingController.text = supermarket?.name ?? "";
                    });
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        Widget cancelButton = TextButton(
                          child: Text(appLoc.cancel),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        );
                        Widget continueButton = ElevatedButton(
                          child: Text(appLoc.save),
                          onPressed: () {
                            superMarketProvider.updateSuperMarketName(supermarketId, textEditingController.text);
                            Navigator.of(context).pop();
                          },
                        );

                        return AlertDialog(
                          title: Text(appLoc.inputTheAmount),
                          content: TextField(controller: textEditingController),
                          actions: [cancelButton, continueButton],
                        );
                      },
                    );
                  },
                ),
              ];
            },
          ),
        ],
        title: FutureBuilder(
          future: supermarketFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!.name);
            }
            if (snapshot.hasError) {
              return Text("$snapshot");
            }
            return Text(appLoc.loading);
          },
        ),

        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Text(appLoc.aisles, style: Theme.of(context).textTheme.titleSmall),
            ),
            Aisles(supermarketId),
          ],
        ),
      ),
    );
  }
}
