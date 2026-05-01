import 'package:drift/drift.dart';
import '../app_database.dart';

part 'sales_orders_dao.g.dart';

@DriftAccessor(tables: [SalesOrders, SalesOrderItems])
class SalesOrdersDao extends DatabaseAccessor<AppDatabase> with _$SalesOrdersDaoMixin {
  SalesOrdersDao(super.db);

  Future<int> insertSalesOrder(SalesOrdersCompanion companion) =>
      into(salesOrders).insert(companion);

  Future<void> insertSalesOrderItems(List<SalesOrderItemsCompanion> items) async {
    for (final item in items) {
      await into(salesOrderItems).insert(item);
    }
  }

  Future<SalesOrder?> getSalesOrderById(int id) =>
      (select(salesOrders)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<SalesOrder>> getAllSalesOrders() => select(salesOrders).get();

  Future<List<SalesOrderItem>> getSalesOrderItems(int orderId) =>
      (select(salesOrderItems)..where((t) => t.orderId.equals(orderId))).get();

  Future<bool> updateSalesOrder(SalesOrdersCompanion companion) =>
      (update(salesOrders)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deleteSalesOrder(int id) async {
    await (delete(salesOrderItems)..where((t) => t.orderId.equals(id))).go();
    return (await (delete(salesOrders)..where((t) => t.id.equals(id))).go()) > 0;
  }
}
