import 'package:flutter/material.dart';
import 'package:lista_de_la_compra/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:lista_de_la_compra_backend/lista_de_la_compra_backend.dart';
import '../../flutter_providers/flutter_providers.dart';

/// Amount derived from the recipes that are scheduled now or in the future and
/// contain this product. Returns null when there is none.
Future<String?> getDerivedAmountString(ScheduleProvider scheduleProvider, String productId) async {
  final recipes = await scheduleProvider.getFutureRecipesWithProduct(productId);
  if (recipes.isEmpty) {
    return null;
  }
  return recipes.map((recipe) => recipe.amount).join(" + ");
}

/// Opens a dialog to edit the manual amount of a product. The field is
/// pre-filled with the manual amount if set, otherwise with the recipe-derived
/// amount (which is only stored once the user saves).
Future<void> showProductAmountDialog(
  BuildContext context,
  ProductProvider productProvider,
  ScheduleProvider scheduleProvider,
  String productId,
) async {
  final product = await productProvider.getProductById(productId);
  final String? manual = (product?.amount != null && product!.amount!.trim().isNotEmpty) ? product.amount!.trim() : null;
  final String? derived = manual == null ? await getDerivedAmountString(scheduleProvider, productId) : null;

  if (!context.mounted) {
    return;
  }

  final AppLocalizations appLoc = AppLocalizations.of(context)!;
  final TextEditingController controller = TextEditingController(text: manual ?? derived ?? "");

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(appLoc.inputTheAmount),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(appLoc.cancel)),
          TextButton(
            onPressed: () {
              productProvider.setProductAmount(productId, controller.text);
              Navigator.of(context).pop();
            },
            child: Text(appLoc.save),
          ),
        ],
      );
    },
  );
}

/// Tappable amount display for a product. Shows the manual amount if set,
/// otherwise the recipe-derived amount, otherwise an "add amount" affordance.
/// Tapping opens [showProductAmountDialog].
class ProductAmount extends StatelessWidget {
  final String productId;

  const ProductAmount(this.productId, {super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLoc = AppLocalizations.of(context)!;
    final ProductProvider productProvider = context.watch<FlutterProductProvider>();
    final ScheduleProvider scheduleProvider = context.watch<FlutterScheduleProvider>();

    return FutureBuilder<List<Object?>>(
      future: Future.wait([
        productProvider.getProductById(productId),
        getDerivedAmountString(scheduleProvider, productId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final Product? product = snapshot.data![0] as Product?;
        final String? derived = snapshot.data![1] as String?;
        if (product == null) {
          return const SizedBox.shrink();
        }

        final String? manual = (product.amount != null && product.amount!.trim().isNotEmpty) ? product.amount!.trim() : null;
        final String? display = manual ?? derived;

        return InkWell(
          onTap: () => showProductAmountDialog(context, productProvider, scheduleProvider, productId),
          child: display == null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Theme.of(context).hintColor),
                    const SizedBox(width: 4),
                    Text(appLoc.inputTheAmount, style: TextStyle(color: Theme.of(context).hintColor)),
                  ],
                )
              : Text(display),
        );
      },
    );
  }
}
