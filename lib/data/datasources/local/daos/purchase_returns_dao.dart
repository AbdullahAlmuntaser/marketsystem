import 'package:drift/drift.dart';
import '../app_database.dart';

part 'purchase_returns_dao.g.dart';

@DriftAccessor(tables: [PurchaseReturns, PurchaseReturnItems])
class PurchaseReturnsDao extends DatabaseAccessor<AppDatabase> with _$PurchaseReturnsDaoMixin {
  PurchaseReturnsDao(super.db);

  Future<int> insertPurchaseReturn(PurchaseReturnsCompanion companion) =>
      into(purchaseReturns).insert(companion);

  Future<void> insertPurchaseReturnItems(List<PurchaseReturnItemsCompanion> items) async {
    for (final item in items) {
      await into(purchaseReturnItems).insert(item);
    }
  }

  Future<PurchaseReturn?> getPurchaseReturnById(int id) =>
      (select(purchaseReturns)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<PurchaseReturn>> getAllPurchaseReturns() => select(purchaseReturns).get();

  Future<List<PurchaseReturnItem>> getPurchaseReturnItems(int returnId) =>
      (select(purchaseReturnItems)..where((t) => t.returnId.equals(returnId))).get();

  Future<bool> updatePurchaseReturn(PurchaseReturnsCompanion companion) =>
      (update(purchaseReturns)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deletePurchaseReturn(int id) async {
    await (delete(purchaseReturnItems)..where((t) => t.returnId.equals(id))).go();
    return (await (delete(purchaseReturns)..where((t) => t.id.equals(id))).go()) > 0;
  }
}
