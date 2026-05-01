import 'package:drift/drift.dart';
import '../app_database.dart';

part 'supplier_payments_dao.g.dart';

@DriftAccessor(tables: [SupplierPayments])
class SupplierPaymentsDao extends DatabaseAccessor<AppDatabase> with _$SupplierPaymentsDaoMixin {
  SupplierPaymentsDao(super.db);

  Future<int> insertSupplierPayment(SupplierPaymentsCompanion companion) =>
      into(supplierPayments).insert(companion);

  Future<SupplierPayment?> getSupplierPaymentById(int id) =>
      (select(supplierPayments)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<SupplierPayment>> getAllSupplierPayments() => select(supplierPayments).get();

  Future<List<SupplierPayment>> getPaymentsBySupplierId(int supplierId) =>
      (select(supplierPayments)..where((t) => t.supplierId.equals(supplierId))).get();

  Future<bool> updateSupplierPayment(SupplierPaymentsCompanion companion) =>
      (update(supplierPayments)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deleteSupplierPayment(int id) =>
      (delete(supplierPayments)..where((t) => t.id.equals(id))).go().then((v) => v > 0);
}
