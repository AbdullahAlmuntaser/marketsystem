import 'package:drift/drift.dart';
import '../app_database.dart';

part 'inventory_audits_dao.g.dart';

@DriftAccessor(tables: [InventoryAudits, InventoryAuditItems])
class InventoryAuditsDao extends DatabaseAccessor<AppDatabase> with _$InventoryAuditsDaoMixin {
  InventoryAuditsDao(super.db);

  Future<int> insertInventoryAudit(InventoryAuditsCompanion companion) =>
      into(inventoryAudits).insert(companion);

  Future<void> insertInventoryAuditItems(List<InventoryAuditItemsCompanion> items) async {
    for (final item in items) {
      await into(inventoryAuditItems).insert(item);
    }
  }

  Future<InventoryAudit?> getInventoryAuditById(int id) =>
      (select(inventoryAudits)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<InventoryAudit>> getAllInventoryAudits() => select(inventoryAudits).get();

  Future<List<InventoryAuditItem>> getInventoryAuditItems(int auditId) =>
      (select(inventoryAuditItems)..where((t) => t.auditId.equals(auditId))).get();

  Future<bool> updateInventoryAudit(InventoryAuditsCompanion companion) =>
      (update(inventoryAudits)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deleteInventoryAudit(int id) async {
    await (delete(inventoryAuditItems)..where((t) => t.auditId.equals(id))).go();
    return (await (delete(inventoryAudits)..where((t) => t.id.equals(id))).go()) > 0;
  }
}
