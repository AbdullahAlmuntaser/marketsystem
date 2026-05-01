import 'package:drift/drift.dart';
import '../app_database.dart';

part 'price_lists_dao.g.dart';

@DriftAccessor(tables: [PriceLists, PriceListItems])
class PriceListsDao extends DatabaseAccessor<AppDatabase> with _$PriceListsDaoMixin {
  PriceListsDao(super.db);

  Future<int> insertPriceList(PriceListsCompanion companion) =>
      into(priceLists).insert(companion);

  Future<void> insertPriceListItems(List<PriceListItemsCompanion> items) async {
    for (final item in items) {
      await into(priceListItems).insert(item);
    }
  }

  Future<PriceList?> getPriceListById(int id) =>
      (select(priceLists)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<PriceList>> getAllPriceLists() => select(priceLists).get();

  Future<List<PriceListItem>> getPriceListItems(int priceListId) =>
      (select(priceListItems)..where((t) => t.priceListId.equals(priceListId))).get();

  Future<bool> updatePriceList(PriceListsCompanion companion) =>
      (update(priceLists)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deletePriceList(int id) async {
    await (delete(priceListItems)..where((t) => t.priceListId.equals(id))).go();
    return (await (delete(priceLists)..where((t) => t.id.equals(id))).go()) > 0;
  }
}
