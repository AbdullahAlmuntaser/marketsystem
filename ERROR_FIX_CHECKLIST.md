# ✅ قائمة التحقق من إصلاح الأخطاء - ERROR FIX CHECKLIST

## 📋 نظرة عامة

هذه القائمة تحتوي على جميع الخطوات العملية لإصلاح الأخطاء المكتشفة في النظام المحاسبي والمخزني.

---

## المرحلة 1: الأساسيات ✅ (مكتملة)

### 1.1 إنشاء Failure Classes
- [x] إنشاء `Failure` base class
- [x] إضافة رسائل عربية وإنجليزية
- [x] إضافة error codes
- [x] إضافة metadata للتتبع

**الملفات المنشأة:**
- `/workspace/lib/core/failure/failures.dart` (524 سطر)

**الأصناف المنشأة (39 Failure class):**

#### Database Failures (6)
- [x] `ForeignKeyViolationFailure`
- [x] `UniqueConstraintFailure`
- [x] `NotNullViolationFailure`
- [x] `CheckConstraintFailure`
- [x] `DatabaseConnectionFailure`
- [x] `TransactionFailure`

#### Accounting Period Failures (4)
- [x] `NoOpenPeriodFailure`
- [x] `ClosedPeriodFailure`
- [x] `PeriodNotFoundFailure`
- [x] `PeriodDateRangeFailure`

#### Posting Failures (5)
- [x] `InvoicePostingFailure`
- [x] `JournalEntryPostingFailure`
- [x] `UnbalancedEntryFailure`
- [x] `MissingAccountFailure`
- [x] `DuplicatePostingFailure`

#### Operational Failures (5)
- [x] `InvalidQuantityFailure`
- [x] `InvalidPriceFailure`
- [x] `InsufficientStockFailure`
- [x] `UnitMismatchFailure`
- [x] `NegativeStockFailure`

#### Integration Failures (4)
- [x] `InvoiceWarehouseSyncFailure`
- [x] `PurchaseOrderInvoiceFailure`
- [x] `SalesOrderInvoiceFailure`
- [x] `InventoryAccountingSyncFailure`

#### UI/UX Failures (3)
- [x] `MissingFormFieldFailure`
- [x] `UnlinkedWidgetFailure`
- [x] `NavigationFailure`

#### Unexpected Exceptions (4)
- [x] `NullValueFailure`
- [x] `TypeCastFailure`
- [x] `RuntimeFailure`
- [x] `UnknownFailure`

---

### 1.2 إنشاء Global Error Handler
- [x] إنشاء singleton `GlobalErrorHandler`
- [x] إضافة `handleException()` method
- [x] إضافة `getArabicMessage()` method
- [x] إضافة `logFailure()` method
- [x] إضافة `showError()` method
- [x] إضافة extension `ExceptionToFailure`
- [x] إضافة helper functions `tryCatch` و `tryCatchSync`

**الملفات المنشأة:**
- `/workspace/lib/core/error/global_error_handler.dart` (151 سطر)

**الميزات المطبقة:**
```dart
// مثال استخدام:
final result = await tryCatch(
  () => invoiceService.postInvoice(invoice),
  'Posting Invoice',
);

result.fold(
  (failure) => GlobalErrorHandler().showError(
    failure,
    onShow: (message) => showSnackBar(message),
  ),
  (success) => showSuccess('تم الترحيل بنجاح'),
);
```

---

## المرحلة 2: التطبيق 🔧 (قيد التنفيذ)

### 2.1 تطبيق tryCatch في الخدمات

#### Accounting Service
- [ ] إضافة tryCatch لـ `postInvoice()`
- [ ] إضافة tryCatch لـ `createJournalEntry()`
- [ ] إضافة tryCatch لـ `validateAccountingPeriod()`
- [ ] إضافة tryCatch لـ `postToGL()`

**مثال التطبيق:**
```dart
Future<Either<Failure, bool>> postInvoice(Invoice invoice) async {
  return tryCatch(() async {
    // 1. Check accounting period
    final periodValid = await validateAccountingPeriod(invoice.date);
    if (!periodValid) {
      return Left(NoOpenPeriodFailure(transactionDate: invoice.date));
    }
    
    // 2. Validate accounts
    final accountsValid = await validateAccounts(invoice);
    if (!accountsValid) {
      return Left(MissingAccountFailure(
        accountCode: 'unknown',
        context: 'Invoice posting',
      ));
    }
    
    // 3. Create journal entry
    await createJournalEntry(invoice);
    
    // 4. Update inventory
    await updateInventory(invoice);
    
    // 5. Mark as posted
    invoice.status = 'posted';
    await invoiceRepository.update(invoice);
    
    return Right(true);
  }, 'Posting Invoice ${invoice.invoiceNumber}');
}
```

#### Inventory Service
- [ ] إضافة tryCatch لـ `deductStock()`
- [ ] إضافة tryCatch لـ `addStock()`
- [ ] إضافة tryCatch لـ `transferStock()`
- [ ] إضافة tryCatch لـ `adjustStock()`

**مثال التطبيق:**
```dart
Future<Either<Failure, bool>> deductStock(
  String itemId,
  double quantity,
  String warehouseId,
) async {
  return tryCatch(() async {
    // 1. Check current stock
    final currentStock = await getStock(itemId, warehouseId);
    
    // 2. Validate quantity
    if (quantity <= 0) {
      return Left(InvalidQuantityFailure(
        quantity: quantity,
        itemName: itemId,
        reason: 'Quantity must be positive',
      ));
    }
    
    // 3. Check sufficient stock
    if (currentStock < quantity) {
      return Left(InsufficientStockFailure(
        itemName: itemId,
        requestedQuantity: quantity,
        availableQuantity: currentStock,
        warehouseName: warehouseId,
      ));
    }
    
    // 4. Deduct stock
    await stockRepository.deduct(itemId, warehouseId, quantity);
    
    return Right(true);
  }, 'Deducting Stock for item $itemId');
}
```

#### Invoice Service
- [ ] إضافة tryCatch لـ `createInvoice()`
- [ ] إضافة tryCatch لـ `updateInvoice()`
- [ ] إضافة tryCatch لـ `deleteInvoice()`
- [ ] إضافة tryCatch لـ `linkToPurchaseOrder()`
- [ ] إضافة tryCatch لـ `linkToSalesOrder()`

---

### 2.2 إضافة Validation في Domain Layer

#### Invoice Validation
```dart
class InvoiceValidator {
  static Either<Failure, bool> validate(Invoice invoice) {
    // 1. Validate date
    if (invoice.date.isAfter(DateTime.now())) {
      return Left(OperationalFailure(
        message: 'Invoice date cannot be in the future',
        arabicMessage: 'تاريخ الفاتورة لا يمكن أن يكون في المستقبل',
      ));
    }
    
    // 2. Validate customer/supplier
    if (invoice.customerId == null && invoice.supplierId == null) {
      return Left(NotNullViolationFailure(
        table: 'invoices',
        field: 'customer_id or supplier_id',
      ));
    }
    
    // 3. Validate items
    if (invoice.items.isEmpty) {
      return Left(OperationalFailure(
        message: 'Invoice must have at least one item',
        arabicMessage: 'يجب أن تحتوي الفاتورة على صنف واحد على الأقل',
      ));
    }
    
    // 4. Validate quantities
    for (var item in invoice.items) {
      if (item.quantity <= 0) {
        return Left(InvalidQuantityFailure(
          quantity: item.quantity,
          itemName: item.itemName,
          reason: 'Quantity must be positive',
        ));
      }
      
      if (item.price < 0) {
        return Left(InvalidPriceFailure(
          price: item.price,
          itemName: item.itemName,
          reason: 'Price cannot be negative',
        ));
      }
    }
    
    // 5. Validate totals
    final calculatedTotal = invoice.items.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.price),
    );
    
    if ((calculatedTotal - invoice.total).abs() > 0.01) {
      return Left(OperationalFailure(
        message: 'Invoice total does not match items total',
        arabicMessage: 'إجمالي الفاتورة لا يتطابق مع مجموع الأصناف',
      ));
    }
    
    return Right(true);
  }
}
```

#### Accounting Period Validation
```dart
class AccountingPeriodValidator {
  static Future<Either<Failure, bool>> validatePeriodForDate(
    DateTime date,
    AccountingPeriodRepository repo,
  ) async {
    return tryCatch(() async {
      // 1. Find period for date
      final period = await repo.findByDate(date);
      
      if (period == null) {
        return Left(NoOpenPeriodFailure(transactionDate: date));
      }
      
      // 2. Check if open
      if (!period.isOpen) {
        return Left(ClosedPeriodFailure(
          periodName: period.name,
          startDate: period.startDate,
          endDate: period.endDate,
        ));
      }
      
      return Right(true);
    }, 'Validating accounting period for date $date');
  }
}
```

---

### 2.3 تحسين رسائل الخطأ في UI

#### Dialog Helper
```dart
class ErrorDialog {
  static void show(BuildContext context, Failure failure) {
    final errorHandler = GlobalErrorHandler();
    final arabicMessage = errorHandler.getArabicMessage(failure);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('خطأ'),
          ],
        ),
        content: Text(arabicMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق'),
          ),
        ],
      ),
    );
    
    // Log for debugging
    errorHandler.logFailure(failure);
  }
  
  static void showSnackBar(BuildContext context, Failure failure) {
    final errorHandler = GlobalErrorHandler();
    final arabicMessage = errorHandler.getArabicMessage(failure);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(arabicMessage),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
```

#### Form Validation Widgets
```dart
class ValidatedFormField extends StatelessWidget {
  final String label;
  final dynamic value;
  final Failure Function(dynamic)? validator;
  
  const ValidatedFormField({
    required this.label,
    required this.value,
    this.validator,
  });
  
  @override
  Widget build(BuildContext context) {
    final errorText = validator != null ? validator!(value) : null;
    
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText?.arabicMessage,
      ),
      onChanged: (value) {
        // Clear error when user types
      },
    );
  }
}
```

---

### 2.4 إضافة Logging شامل

#### Logger Service
```dart
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();
  
  final List<LogEntry> _logs = [];
  
  void logFailure(Failure failure, {String? context}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.error,
      type: failure.runtimeType.toString(),
      message: failure.message,
      arabicMessage: failure.arabicMessage,
      errorCode: failure.errorCode,
      metadata: failure.metadata,
      context: context,
    );
    
    _logs.add(entry);
    
    // Also print to console
    print('[${entry.timestamp}] ${entry.level}: ${entry.type}');
    print('  Message: ${entry.message}');
    print('  Arabic: ${entry.arabicMessage}');
    print('  Code: ${entry.errorCode}');
    print('---');
    
    // TODO: Send to remote logging service
  }
  
  void logInfo(String message, {Map<String, dynamic>? metadata}) {
    // Similar implementation for info logs
  }
  
  void logWarning(String message, {Map<String, dynamic>? metadata}) {
    // Similar implementation for warning logs
  }
  
  List<LogEntry> getLogs({DateTime? from, DateTime? to}) {
    return _logs.where((log) {
      if (from != null && log.timestamp.isBefore(from)) return false;
      if (to != null && log.timestamp.isAfter(to)) return false;
      return true;
    }).toList();
  }
  
  void clearLogs() {
    _logs.clear();
  }
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String type;
  final String message;
  final String? arabicMessage;
  final String? errorCode;
  final Map<String, dynamic>? metadata;
  final String? context;
  
  LogEntry({
    required this.timestamp,
    required this.level,
    required this.type,
    required this.message,
    this.arabicMessage,
    this.errorCode,
    this.metadata,
    this.context,
  });
}

enum LogLevel { info, warning, error }
```

---

## المرحلة 3: الاختبار 🧪

### 3.1 Unit Tests لكل Failure Type

#### Example Test File
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/core/failure/failures.dart';

void main() {
  group('Database Failures', () {
    test('ForeignKeyViolationFailure should have correct properties', () {
      const failure = ForeignKeyViolationFailure(
        table: 'suppliers',
        foreignKey: 'supplier_id',
        value: 999,
      );
      
      expect(failure.errorCode, 'DB_FK_001');
      expect(failure.arabicMessage, contains('فشل قيد المفتاح الأجنبي'));
      expect(failure.metadata?['table'], 'suppliers');
    });
    
    test('UniqueConstraintFailure should have correct properties', () {
      const failure = UniqueConstraintFailure(
        table: 'invoices',
        field: 'invoice_number',
        value: 'INV-001',
      );
      
      expect(failure.errorCode, 'DB_UQ_001');
      expect(failure.arabicMessage, contains('فشل قيد التكرار'));
    });
  });
  
  group('Accounting Period Failures', () {
    test('NoOpenPeriodFailure should format date correctly', () {
      const failure = NoOpenPeriodFailure(
        transactionDate: DateTime(2024, 1, 15),
      );
      
      expect(failure.arabicMessage, contains('15/1/2024'));
      expect(failure.errorCode, 'AP_OPEN_001');
    });
  });
  
  // Add more tests for each failure type...
}
```

### 3.2 Integration Tests للسيناريوهات

#### Invoice Flow Test
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Invoice creation with validation', (tester) async {
    // 1. Navigate to invoice screen
    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('الفواتير'));
    await tester.pumpAndSettle();
    
    // 2. Try to create invoice without items
    await tester.tap(find.text('جديد'));
    await tester.pumpAndSettle();
    
    // 3. Fill customer but no items
    await tester.enterText(
      find.byKey(Key('customer_field')),
      'Customer 1',
    );
    
    // 4. Try to save
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    
    // 5. Expect error message
    expect(
      find.textContaining('يجب أن تحتوي الفاتورة على صنف واحد على الأقل'),
      findsOneWidget,
    );
  });
}
```

### 3.3 UI Tests للشاشات الحرجة

#### POS Screen Test
```dart
testWidgets('POS screen handles insufficient stock', (tester) async {
  // Setup mock with low stock
  when(mockInventoryService.getStock('item1', 'warehouse1'))
    .thenAnswer((_) async => 5.0);
  
  await tester.pumpWidget(MyApp());
  
  // Add 10 items to cart (more than available)
  await tester.tap(find.text('Item 1'));
  await tester.enterText(find.byType(QuantityField), '10');
  await tester.tap(find.text('إضافة للسلة'));
  await tester.pumpAndSettle();
  
  // Try to checkout
  await tester.tap(find.text('دفع'));
  await tester.pumpAndSettle();
  
  // Expect insufficient stock error
  expect(
    find.textContaining('المخزون غير كافٍ'),
    findsOneWidget,
  );
});
```

---

## المرحلة 4: التحسين 📈

### 4.1 Dashboard للأخطاء الشائعة

#### Error Analytics Widget
```dart
class ErrorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('لوحة أخطاء النظام')),
      body: Column(
        children: [
          // Summary cards
          ErrorSummaryCard(
            title: 'أخطاء قاعدة البيانات',
            count: 45,
            icon: Icons.database,
          ),
          ErrorSummaryCard(
            title: 'أخطاء الفترات المحاسبية',
            count: 12,
            icon: Icons.calendar_today,
          ),
          
          // Chart
          ErrorChartWidget(),
          
          // Recent errors list
          RecentErrorsList(),
        ],
      ),
    );
  }
}
```

### 4.2 تقارير دورية

#### Daily Error Report
```dart
class DailyErrorReport {
  static Future<String> generate(DateTime date) async {
    final logs = LoggerService().getLogs(
      from: DateTime(date.year, date.month, date.day),
      to: DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
    
    final report = StringBuffer();
    report.writeln('تقرير الأخطاء اليومي');
    report.writeln('التاريخ: ${date.day}/${date.month}/${date.year}');
    report.writeln('---');
    
    // Group by type
    final byType = <String, int>{};
    for (var log in logs) {
      byType[log.type] = (byType[log.type] ?? 0) + 1;
    }
    
    for (var entry in byType.entries) {
      report.writeln('${entry.key}: ${entry.value}');
    }
    
    return report.toString();
  }
}
```

### 4.3 Auto-fix للأخطاء البسيطة

#### Auto-fix Service
```dart
class AutoFixService {
  static Future<bool> tryAutoFix(Failure failure) async {
    switch (failure.runtimeType) {
      case NoOpenPeriodFailure:
        // Suggest opening a new period
        return await suggestOpenPeriod(failure as NoOpenPeriodFailure);
        
      case MissingAccountFailure:
        // Suggest creating missing account
        return await suggestCreateAccount(failure as MissingAccountFailure);
        
      case InsufficientStockFailure:
        // Suggest transfer from another warehouse
        return await suggestStockTransfer(failure as InsufficientStockFailure);
        
      default:
        return false;
    }
  }
}
```

---

## 📊 إحصائيات التقدم

| المرحلة | العناصر | المكتمل | النسبة |
|---------|---------|---------|--------|
| المرحلة 1: الأساسيات | 40 | 40 | 100% ✅ |
| المرحلة 2: التطبيق | 25 | 0 | 0% 🔧 |
| المرحلة 3: الاختبار | 15 | 0 | 0% 🧪 |
| المرحلة 4: التحسين | 10 | 0 | 0% 📈 |
| **الإجمالي** | **90** | **40** | **44%** |

---

## 🎯 الخطوات التالية الموصى بها

1. **فوراً**: 
   - [ ] استيراد `failures.dart` و `global_error_handler.dart` في الخدمات
   - [ ] تطبيق tryCatch في `AccountingService`
   - [ ] تطبيق tryCatch في `InventoryService`

2. **هذا الأسبوع**:
   - [ ] إضافة validation في جميع النماذج
   - [ ] تحسين رسائل الخطأ في الـ UI
   - [ ] كتابة unit tests للـ Failure classes

3. **هذا الشهر**:
   - [ ] تغطية اختبارية 70%+
   - [ ] Dashboard للأخطاء
   - [ ] تقارير أسبوعية

---

*آخر تحديث: 2024*
*الحالة: المرحلة 1 مكتملة ✅*
