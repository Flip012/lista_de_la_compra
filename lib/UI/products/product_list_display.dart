import 'package:flutter/material.dart';
import 'package:lista_de_la_compra/UI/common/needed_checkbox.dart';
import 'package:lista_de_la_compra/UI/common/searchable_list_view.dart';
import 'package:lista_de_la_compra/UI/products/common.dart';
import 'package:lista_de_la_compra/UI/products/product_detail.dart';
import 'package:lista_de_la_compra/l10n/app_localizations.dart';
import 'package:lista_de_la_compra/shared_preference_providers/persistant_shared_preferences_provider.dart';
import 'package:lista_de_la_compra_backend/lista_de_la_compra_backend.dart';
import 'package:provider/provider.dart';
import '../../flutter_providers/flutter_providers.dart';

class ProductListDisplay extends StatelessWidget {
  final List<Product> products;
  final bool isNeededList;
  final String enviromentId;

  const ProductListDisplay(this.products, this.isNeededList, this.enviromentId, {super.key});

  @override
  Widget build(BuildContext context) {
    final ProductProvider productProvider = context.watch<FlutterProductProvider>();
    final SharedPreferencesProvider sharedPreferencesProvider = context.watch<PersistantSharedPreferencesProvider>();
    final ProductAisleProvider productAisleProvider = context.watch<FlutterProductAisleProvider>();
    final AisleProvider aisleProvider = context.watch<FlutterAisleProvider>();

    var filteredProducts = isNeededList ? products.where((e) => e.needed).toList() : products;

    return FutureBuilder<String?>(
      future: sharedPreferencesProvider.getSelectedSupermarket(enviromentId),
      builder: (context, supermarketSnapshot) {
        final AppLocalizations appLoc = AppLocalizations.of(context)!;
        final String? uncategorizedLabel = supermarketSnapshot.data != null ? appLoc.noAisleAssigned : null;

        return Searchablelistview<Product>(
          uncategorizedLabel: uncategorizedLabel,
          elements: filteredProducts,
          elementsOnSearch: products,
          elementToListTile: (Product p, RichText tag) {
            return ListTile(
              title: tag,
              subtitle: Row(
                children: [
                  ProductAmount(p.id),
                  if ((p.lastEditedBy ?? '').isNotEmpty)
                    Expanded(
                      child: Text(
                        " - ${p.lastEditedBy!}",
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeededCheckbox(p.id, delay: isNeededList ? Duration(milliseconds: 200) : null),
                  IconButton(
                    icon: const Icon(Icons.arrow_outward),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetail(p.id)));
                    },
                  ),
                ],
              ),
            );
          },
          elementToTag: (Product p) => p.name,
          newElement: (String name) async {
            var allProducts = await productProvider.getDisplayProductList(enviromentId);
            if (allProducts.any((e) => e.name.toLowerCase() == name.toLowerCase())) {
              var referenced = allProducts.firstWhere((e) => e.name.toLowerCase() == name.toLowerCase());
              productProvider.setProductNeededness(referenced.id, isNeededList);
              return;
            }

            String? selectedSupermarket = await sharedPreferencesProvider.getSelectedSupermarket(enviromentId);
            List<Aisle> aisles = selectedSupermarket == null
                ? const []
                : await aisleProvider.getAislesBySupermarket(selectedSupermarket);

            if (aisles.isEmpty || !context.mounted) {
              productProvider.addProduct(name, isNeededList, enviromentId);
              return;
            }

            final Set<String> selectedAisleIds = {};
            final Set<String>? picked = await showDialog<Set<String>>(
              context: context,
              builder: (dialogContext) {
                return StatefulBuilder(
                  builder: (dialogContext, setLocalState) {
                    return AlertDialog(
                      title: Text(name),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final a in aisles)
                              CheckboxListTile(
                                title: Text(a.name),
                                value: selectedAisleIds.contains(a.id),
                                onChanged: (v) => setLocalState(() {
                                  if (v == true) {
                                    selectedAisleIds.add(a.id);
                                  } else {
                                    selectedAisleIds.remove(a.id);
                                  }
                                }),
                              ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(null),
                          child: Text(appLoc.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(selectedAisleIds),
                          child: Text(appLoc.add),
                        ),
                      ],
                    );
                  },
                );
              },
            );

            if (picked == null) return;

            final productId = await productProvider.addProduct(name, isNeededList, enviromentId);
            for (final aisleId in picked) {
              await productAisleProvider.addProductAisle(productId, aisleId, enviromentId);
            }
          },
          elementCategories: (Product p) async {
            String? selectedSupermarket = await sharedPreferencesProvider.getSelectedSupermarket(enviromentId);

            if (selectedSupermarket == null) {
              return [];
            }

            var aisles = await productAisleProvider.getAisleOfProductInSupermarket(p.id, selectedSupermarket);
            return aisles.map((a) => (a.id, a.name, a.sortOrder)).toList();
          },
        );
      },
    );
  }
}
