import 'package:drift/drift.dart';
import '../app_database.dart';

part 'sales_returns_dao.g.dart';

@DriftAccessor(tables: [SalesReturns, SalesReturnItems])
class SalesReturnsDao extends DatabaseAccessor<AppDatabase> with _$SalesReturnsDaoMixin {
  SalesReturnsDao(super.db);

  Future<int> insertSalesReturn(SalesReturnsCompanion companion) =>
      into(salesReturns).insert(companion);

  Future<void> insertSalesReturnItems(List<SalesReturnItemsCompanion> items) async {
    for (final item in items) {
      await into(salesReturnItems).insert(item);
    }
  }

  Future<SalesReturn?> getSalesReturnById(int id) =>
      (select(salesReturns)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<SalesReturn>> getAllSalesReturns() => select(salesReturns).get();

  Future<List<SalesReturnItem>> getSalesReturnItems(int returnId) =>
      (select(salesReturnItems)..where((t) => t.returnId.equals(returnId))).get();

  Future<bool> updateSalesReturn(SalesReturnsCompanion companion) =>
      (update(salesReturns)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deleteSalesReturn(int id) async {
    await (delete(salesReturnItems)..where((t) => t.returnId.equals(id))).go();
    return (await (delete(salesReturns)..where((t) => t.id.equals(id))).go()) > 0;
  }
}
