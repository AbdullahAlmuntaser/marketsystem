import 'package:drift/drift.dart';
import '../app_database.dart';

part 'currencies_dao.g.dart';

@DriftAccessor(tables: [Currencies])
class CurrenciesDao extends DatabaseAccessor<AppDatabase> with _$CurrenciesDaoMixin {
  CurrenciesDao(super.db);

  Future<int> insertCurrency(CurrenciesCompanion companion) =>
      into(currencies).insert(companion);

  Future<Currency?> getCurrencyById(int id) =>
      (select(currencies)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Currency>> getAllCurrencies() => select(currencies).get();

  Future<bool> updateCurrency(CurrenciesCompanion companion) =>
      (update(currencies)..where((t) => t.id.equals(companion.id.value))).write(companion);

  Future<bool> deleteCurrency(int id) =>
      (delete(currencies)..where((t) => t.id.equals(id))).go().then((v) => v > 0);
}
