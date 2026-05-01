import 'package:drift/drift.dart';
import '../app_database.dart';

part 'employees_dao.g.dart';

@DriftAccessor(tables: [Employees])
class EmployeesDao extends DatabaseAccessor<AppDatabase> with _$EmployeesDaoMixin {
  EmployeesDao(super.db);

  Future<int> insertEmployee(EmployeesCompanion companion) =>
      into(employees).insert(companion);

  Future<Employee?> getEmployeeById(int id) =>
      (select(employees)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Employee>> getAllEmployees() => select(employees).get();

  Future<bool> updateEmployee(EmployeesCompanion companion) =>
      (update(employees)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deleteEmployee(int id) =>
      (delete(employees)..where((t) => t.id.equals(id))).go().then((v) => v > 0);
}
