import 'package:get_it/get_it.dart';
import 'core/auth/auth_provider.dart';
import 'core/services/permission_service.dart';
import 'core/services/inventory_service.dart';
import 'core/services/accounting_service.dart';
import 'core/services/event_bus_service.dart';
import 'core/services/financial_control_service.dart';
import 'core/services/grn_service.dart';
import 'core/utils/drive_backup_service.dart';
import 'core/theme/theme_provider.dart';
import 'data/datasources/local/app_database.dart';
import 'data/datasources/local/daos/products_dao.dart';
import 'core/services/posting_engine.dart';
import 'core/services/inventory_costing_service.dart';
import 'data/datasources/local/daos/stock_movement_dao.dart';
import 'data/datasources/local/daos/audit_dao.dart';
import 'core/services/audit_service.dart';
import 'data/repositories/inventory_repository_impl.dart';
import 'data/repositories/item_repository_impl.dart';
import 'domain/repositories/inventory_repository.dart';
import 'domain/repositories/item_repository.dart';
import 'domain/usecases/create_item.dart';
import 'domain/usecases/add_stock.dart';
import 'core/services/bom_service.dart';
import 'core/services/sales_service.dart';
import 'core/services/purchase_service.dart';
import 'core/services/reorder_service.dart';
import 'core/services/supplier_analytics_service.dart';
import 'core/services/statement_service.dart';
import 'core/services/report_service.dart';
import 'core/services/pricing_service.dart';
import 'core/services/transaction_engine.dart';
import 'core/services/shift_service.dart';
import 'core/services/hr_service.dart';
import 'core/services/stock_transfer_service.dart';
import 'core/services/asset_service.dart';
import 'presentation/features/pos/bloc/pos_bloc.dart';
import 'presentation/features/products/products_provider.dart';
import 'presentation/features/accounting/shifts_provider.dart';
import 'presentation/features/hr/hr_provider.dart';
import 'presentation/features/hr/payroll_provider.dart';
import 'presentation/features/inventory/stock_transfer_provider.dart';
import 'presentation/features/accounting/asset_provider.dart';
import 'presentation/features/customers/customer_statement_provider.dart';
import 'data/datasources/local/daos/sales_returns_dao.dart';
import 'data/datasources/local/daos/purchase_returns_dao.dart';
import 'data/datasources/local/daos/customer_payments_dao.dart';
import 'data/datasources/local/daos/supplier_payments_dao.dart';
import 'data/datasources/local/daos/stock_transfers_dao.dart';
import 'data/datasources/local/daos/employees_dao.dart';
import 'data/datasources/local/daos/inventory_audits_dao.dart';
import 'data/datasources/local/daos/price_lists_dao.dart';
import 'data/datasources/local/daos/currencies_dao.dart';
import 'data/datasources/local/daos/purchase_orders_dao.dart';
import 'data/datasources/local/daos/sales_orders_dao.dart';
import 'data/datasources/local/daos/gl_entries_dao.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final db = AppDatabase();
  sl.registerLazySingleton<AppDatabase>(() => db);
  sl.registerLazySingleton<AuditDao>(() => AuditDao(db));
  sl.registerLazySingleton<StockMovementDao>(() => StockMovementDao(db));
  sl.registerLazySingleton<ProductsDao>(() => ProductsDao(db));
  
  // Register new DAOs
  sl.registerLazySingleton<SalesReturnsDao>(() => SalesReturnsDao(db));
  sl.registerLazySingleton<PurchaseReturnsDao>(() => PurchaseReturnsDao(db));
  sl.registerLazySingleton<CustomerPaymentsDao>(() => CustomerPaymentsDao(db));
  sl.registerLazySingleton<SupplierPaymentsDao>(() => SupplierPaymentsDao(db));
  sl.registerLazySingleton<StockTransfersDao>(() => StockTransfersDao(db));
  sl.registerLazySingleton<EmployeesDao>(() => EmployeesDao(db));
  sl.registerLazySingleton<InventoryAuditsDao>(() => InventoryAuditsDao(db));
  sl.registerLazySingleton<PriceListsDao>(() => PriceListsDao(db));
  sl.registerLazySingleton<CurrenciesDao>(() => CurrenciesDao(db));
  sl.registerLazySingleton<PurchaseOrdersDao>(() => PurchaseOrdersDao(db));
  sl.registerLazySingleton<SalesOrdersDao>(() => SalesOrdersDao(db));
  sl.registerLazySingleton<GLEntriesDao>(() => GLEntriesDao(db));

  sl.registerLazySingleton<AccountingService>(
    () => AccountingService(db, sl<EventBusService>()),
  );
  sl.registerLazySingleton<PostingEngine>(
    () => PostingEngine(db, costingService: sl<InventoryCostingService>()),
  );
  sl.registerLazySingleton<InventoryCostingService>(
    () => InventoryCostingService(sl<StockMovementDao>(), sl<AppDatabase>()),
  );
  sl.registerLazySingleton<PermissionService>(() => PermissionService(db));
  sl.registerLazySingleton<AuditService>(() => AuditService(db));
  sl.registerLazySingleton<InventoryService>(() => InventoryService(db));
  sl.registerLazySingleton<EventBusService>(() => EventBusService());
  sl.registerLazySingleton<PurchaseService>(
    () =>
        PurchaseService(db, sl<PostingEngine>(), sl<InventoryCostingService>()),
  );
  sl.registerLazySingleton<SalesService>(
    () => SalesService(sl<PostingEngine>(), sl<InventoryService>()),
  );
  sl.registerLazySingleton<StatementService>(
    () => StatementService(sl<PostingEngine>()),
  );
  sl.registerLazySingleton<ReportService>(
    () => ReportService(sl<PostingEngine>()),
  );

  sl.registerLazySingleton<AuthProvider>(
    () => AuthProvider(sl<AppDatabase>(), sl<PermissionService>()),
  );

  sl.registerLazySingleton<ItemRepository>(
    () => ItemRepositoryImpl(sl<ProductsDao>()),
  );
  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(sl<StockMovementDao>(), sl<ProductsDao>()),
  );

  sl.registerLazySingleton<CreateItemUseCase>(
    () => CreateItemUseCase(sl<ItemRepository>()),
  );
  sl.registerLazySingleton<AddStockUseCase>(
    () => AddStockUseCase(sl<InventoryRepository>()),
  );
  sl.registerLazySingleton<ThemeProvider>(() => ThemeProvider());
  sl.registerLazySingleton(() => BomService(db, sl<AccountingService>()));
  sl.registerLazySingleton<GrnService>(() => GrnService(db));
  sl.registerLazySingleton<ReorderService>(() => ReorderService(db));
  sl.registerLazySingleton<SupplierAnalyticsService>(() => SupplierAnalyticsService(db));
  sl.registerLazySingleton<DriveBackupService>(() => DriveBackupService(db));
  sl.registerLazySingleton<FinancialControlService>(
    () => FinancialControlService(
      db,
      costingService: sl<InventoryCostingService>(),
    ),
  );

  // New Services
  sl.registerLazySingleton<PricingService>(() => PricingService(db));
  sl.registerLazySingleton<TransactionEngine>(() {
    final engine = TransactionEngine(db, sl<EventBusService>());
    engine.setCostingService(sl<InventoryCostingService>());
    return engine;
  });

  // Providers & Blocs
  sl.registerLazySingleton<ProductsProvider>(() => ProductsProvider(db));
  sl.registerFactory<PosBloc>(
    () => PosBloc(db, sl<PricingService>(), sl<TransactionEngine>()),
  );
  
  // Missing Services Registration
  sl.registerLazySingleton<ShiftService>(() => ShiftService(db));
  sl.registerLazySingleton<HRService>(() => HRService(db, sl<PostingEngine>()));
  sl.registerLazySingleton<StockTransferService>(() => StockTransferService(db));
  sl.registerLazySingleton<AssetService>(() => AssetService(db));
  sl.registerLazySingleton<CustomerStatementProvider>(() => CustomerStatementProvider());
}
