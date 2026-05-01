import 'package:drift/drift.dart';
import '../app_database.dart';

part 'stock_transfers_dao.g.dart';

@DriftAccessor(tables: [StockTransfers, StockTransferItems])
class StockTransfersDao extends DatabaseAccessor<AppDatabase> with _$StockTransfersDaoMixin {
  StockTransfersDao(super.db);

  Future<int> insertStockTransfer(StockTransfersCompanion companion) =>
      into(stockTransfers).insert(companion);

  Future<void> insertStockTransferItems(List<StockTransferItemsCompanion> items) async {
    for (final item in items) {
      await into(stockTransferItems).insert(item);
    }
  }

  Future<StockTransfer?> getStockTransferById(int id) =>
      (select(stockTransfers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<StockTransfer>> getAllStockTransfers() => select(stockTransfers).get();

  Future<List<StockTransferItem>> getStockTransferItems(int transferId) =>
      (select(stockTransferItems)..where((t) => t.transferId.equals(transferId))).get();

  Future<bool> updateStockTransfer(StockTransfersCompanion companion) =>
      (update(stockTransfers)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deleteStockTransfer(int id) async {
    await (delete(stockTransferItems)..where((t) => t.transferId.equals(id))).go();
    return (await (delete(stockTransfers)..where((t) => t.id.equals(id))).go()) > 0;
  }
}
