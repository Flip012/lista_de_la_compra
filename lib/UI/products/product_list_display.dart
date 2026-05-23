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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProductAmount(p.id),
                  if ((p.lastEditedBy ?? '').isNotEmpty)
                    Text(
                      p.lastEditedBy!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
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
            } else {
              productProvider.addProduct(name, isNeededList, enviromentId);
            }
          },
          elementCategories: (Product p) async {
            String? selectedSupermarket = await sharedPreferencesProvider.getSelectedSupermarket(enviromentId);

            if (selectedSupermarket == null) {
              return [];
            }

            var aisles = await productAisleProvider.getAisleOfProductInSupermarket(p.id, selectedSupermarket);
            return aisles.map((a) => (a.id, a.name)).toList();
          },
        );
      },
    );
  }
}
