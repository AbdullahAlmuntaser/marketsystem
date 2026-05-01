import 'package:drift/drift.dart';
import '../app_database.dart';

part 'purchase_orders_dao.g.dart';

@DriftAccessor(tables: [PurchaseOrders, PurchaseOrderItems])
class PurchaseOrdersDao extends DatabaseAccessor<AppDatabase> with _$PurchaseOrdersDaoMixin {
  PurchaseOrdersDao(super.db);

  Future<int> insertPurchaseOrder(PurchaseOrdersCompanion companion) =>
      into(purchaseOrders).insert(companion);

  Future<void> insertPurchaseOrderItems(List<PurchaseOrderItemsCompanion> items) async {
    for (final item in items) {
      await into(purchaseOrderItems).insert(item);
    }
  }

  Future<PurchaseOrder?> getPurchaseOrderById(int id) =>
      (select(purchaseOrders)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<PurchaseOrder>> getAllPurchaseOrders() => select(purchaseOrders).get();

  Future<List<PurchaseOrderItem>> getPurchaseOrderItems(int orderId) =>
      (select(purchaseOrderItems)..where((t) => t.orderId.equals(orderId))).get();

  Future<bool> updatePurchaseOrder(PurchaseOrdersCompanion companion) =>
      (update(purchaseOrders)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deletePurchaseOrder(int id) async {
    await (delete(purchaseOrderItems)..where((t) => t.orderId.equals(id))).go();
    return (await (delete(purchaseOrders)..where((t) => t.id.equals(id))).go()) > 0;
  }
}
