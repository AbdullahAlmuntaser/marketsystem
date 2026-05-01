import 'package:drift/drift.dart';
import '../app_database.dart';

part 'customer_payments_dao.g.dart';

@DriftAccessor(tables: [CustomerPayments])
class CustomerPaymentsDao extends DatabaseAccessor<AppDatabase> with _$CustomerPaymentsDaoMixin {
  CustomerPaymentsDao(super.db);

  Future<int> insertCustomerPayment(CustomerPaymentsCompanion companion) =>
      into(customerPayments).insert(companion);

  Future<CustomerPayment?> getCustomerPaymentById(int id) =>
      (select(customerPayments)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<CustomerPayment>> getAllCustomerPayments() => select(customerPayments).get();

  Future<List<CustomerPayment>> getPaymentsByCustomerId(int customerId) =>
      (select(customerPayments)..where((t) => t.customerId.equals(customerId))).get();

  Future<bool> updateCustomerPayment(CustomerPaymentsCompanion companion) =>
      (update(customerPayments)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deleteCustomerPayment(int id) =>
      (delete(customerPayments)..where((t) => t.id.equals(id))).go().then((v) => v > 0);
}
