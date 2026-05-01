# 🧪 خطة الاختبار الشاملة (Testing Roadmap)

## الهدف
تحقيق **70%+ Test Coverage** للنظام المحاسبي والمخزني مع ضمان معالجة جميع الأخطاء المكتشفة.

---

## المرحلة 1: اختبار Failure Classes ✅

### الملفات المطلوبة
- `test/core/failure/failures_test.dart`

### حالات الاختبار
```dart
// 1. اختبار إنشاء جميع أنواع Failures
test('DatabaseFailure should create with correct properties', () {
  final failure = DatabaseFailure(
    code: 'DB_FK_001',
    messageAr: 'رسالة عربية',
    messageEn: 'English message',
    metadata: {'key': 'value'},
  );
  
  expect(failure.code, equals('DB_FK_001'));
  expect(failure.messageAr, contains('عربية'));
  expect(failure.messageEn, contains('English'));
  expect(failure.metadata['key'], equals('value'));
});

// 2. اختبار Equatable
test('Two DatabaseFailures with same properties should be equal', () {
  final failure1 = DatabaseFailure(code: 'DB_001', messageAr: 'test', messageEn: 'test');
  final failure2 = DatabaseFailure(code: 'DB_001', messageAr: 'test', messageEn: 'test');
  
  expect(failure1, equals(failure2));
});

// 3. اختبار جميع الأنواع الـ 39
group('All Failure Types', () {
  test('AccountingPeriodFailure creates correctly', () { ... });
  test('PostingFailure creates correctly', () { ... });
  test('OperationalFailure creates correctly', () { ... });
  // ... إلخ
});
```

---

## المرحلة 2: اختبار GlobalErrorHandler ✅

### الملفات المطلوبة
- `test/core/error/global_error_handler_test.dart`

### حالات الاختبار
```dart
group('GlobalErrorHandler', () {
  test('handleException converts Exception to Failure', () {
    final exception = Exception('Test error');
    final failure = GlobalErrorHandler.instance.handleException(exception);
    
    expect(failure, isA<UnexpectedException>());
    expect(failure.messageAr, isNotEmpty);
  });

  test('getArabicMessage returns correct Arabic message for DB_FK_001', () {
    final failure = DatabaseFailure(code: 'DB_FK_001', messageAr: 'خطأ مفتاح أجنبي', messageEn: 'FK Error');
    final message = GlobalErrorHandler.instance.getArabicMessage(failure);
    
    expect(message, contains('مفتاح أجنبي'));
  });

  test('tryCatch wrapper catches exceptions', () async {
    final result = await tryCatch(() async {
      throw Exception('Test');
    });
    
    expect(result.isLeft(), isTrue);
    expect(result.getOrElse(() => null), isA<Failure>());
  });
});
```

---

## المرحلة 3: اختبار Validators 🔧 (جديد)

### 3.1 InvoiceValidator
**الملف:** `test/core/validation/invoice_validator_test.dart`

```dart
group('InvoiceValidator', () {
  late InvoiceValidator validator;
  late MockItemRepository mockItemRepo;
  late MockInventoryRepository mockInvRepo;

  setUp(() {
    mockItemRepo = MockItemRepository();
    mockInvRepo = MockInventoryRepository();
    validator = InvoiceValidator(
      itemRepository: mockItemRepo,
      inventoryRepository: mockInvRepo,
    );
  });

  test('returns failure when items list is empty', () async {
    final result = await validator.validateInvoiceItems([], isSales: true);
    
    expect(result.isLeft(), true);
    final failure = result.fold(id, (_) => OperationalFailure(code: '', messageAr: '', messageEn: ''));
    expect(failure.code, equals('OP_EMPTY_001'));
  });

  test('returns failure when quantity is zero', () async {
    final items = [
      InvoiceItemEntity(itemId: 1, quantity: 0, price: 10),
    ];
    
    final result = await validator.validateInvoiceItems(items, isSales: true);
    
    expect(result.isLeft(), true);
    final failure = result.getLeft()! as OperationalFailure;
    expect(failure.code, equals('OP_QTY_001'));
  });

  test('returns failure when stock is insufficient', () async {
    final items = [
      InvoiceItemEntity(itemId: 1, quantity: 100, price: 10),
    ];
    
    when(mockItemRepo.getItemById(1)).thenAnswer((_) async => Right(ItemEntity(...)));
    when(mockInvRepo.getStockLevel(itemId: 1, warehouseId: 1, variantId: null))
        .thenAnswer((_) async => 50); // أقل من المطلوب
    
    final result = await validator.validateInvoiceItems(items, isSales: true, warehouseId: 1);
    
    expect(result.isLeft(), true);
    final failure = result.getLeft()! as OperationalFailure;
    expect(failure.code, equals('OP_STOCK_001'));
    expect(failure.messageAr, contains('الرصيد غير كافٍ'));
  });

  test('returns success when all validations pass', () async {
    final items = [
      InvoiceItemEntity(itemId: 1, quantity: 10, price: 10),
    ];
    
    when(mockItemRepo.getItemById(1)).thenAnswer((_) async => Right(ItemEntity(...)));
    when(mockInvRepo.getStockLevel(itemId: 1, warehouseId: 1, variantId: null))
        .thenAnswer((_) async => 100); // كافٍ
    
    final result = await validator.validateInvoiceItems(items, isSales: true, warehouseId: 1);
    
    expect(result.isRight(), true);
  });
});
```

### 3.2 AccountingPeriodValidator
**الملف:** `test/core/validation/accounting_period_validator_test.dart`

```dart
group('AccountingPeriodValidator', () {
  test('returns failure when no open period exists', () async {
    final mockRepo = MockPeriodRepository();
    when(mockRepo.getOpenPeriodForDate(any)).thenAnswer((_) async => const None());
    
    final validator = AccountingPeriodValidator(periodRepository: mockRepo);
    final result = await validator.validateOpenPeriod(DateTime.now());
    
    expect(result.isLeft(), true);
    final failure = result.getLeft()! as AccountingPeriodFailure;
    expect(failure.code, equals('AP_OPEN_001'));
  });

  test('returns failure when period is closed', () async {
    final mockRepo = MockPeriodRepository();
    final closedPeriod = AccountingPeriodEntity(
      id: 1,
      name: 'يناير 2024',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 31),
      isClosed: true,
      closedDate: DateTime(2024, 2, 5),
    );
    
    when(mockRepo.getOpenPeriodForDate(any)).thenAnswer((_) async => Right(closedPeriod));
    
    final validator = AccountingPeriodValidator(periodRepository: mockRepo);
    final result = await validator.validateOpenPeriod(DateTime(2024, 1, 15));
    
    expect(result.isLeft(), true);
    final failure = result.getLeft()! as AccountingPeriodFailure;
    expect(failure.code, equals('AP_CLOSED_001'));
  });
});
```

### 3.3 JournalEntryValidator
**الملف:** `test/core/validation/journal_entry_validator_test.dart`

```dart
group('JournalEntryValidator', () {
  late JournalEntryValidator validator;

  setUp(() {
    validator = JournalEntryValidator();
  });

  test('returns failure when entry has no lines', () {
    final result = validator.validateEntryBalance(lines: []);
    
    expect(result.isLeft(), true);
    final failure = result.getLeft()! as PostingFailure;
    expect(failure.code, equals('PF_EMPTY_001'));
  });

  test('returns failure when entry is not balanced', () {
    final lines = [
      {'accountId': 1, 'amount': 100.0, 'isDebit': true},
      {'accountId': 2, 'amount': 50.0, 'isDebit': false}, // غير متوازن
    ];
    
    final result = validator.validateEntryBalance(lines: lines);
    
    expect(result.isLeft(), true);
    final failure = result.getLeft()! as PostingFailure;
    expect(failure.code, equals('PF_BALANCE_001'));
    expect(failure.messageAr, contains('غير متوازن'));
  });

  test('returns success when entry is balanced', () {
    final lines = [
      {'accountId': 1, 'amount': 100.0, 'isDebit': true},
      {'accountId': 2, 'amount': 100.0, 'isDebit': false}, // متوازن
    ];
    
    final result = validator.validateEntryBalance(lines: lines);
    
    expect(result.isRight(), true);
  });
});
```

---

## المرحلة 4: اختبار Integration Tests 🧪

### 4.1 Invoice Posting Flow
**الملف:** `test/integration/invoice_posting_test.dart`

```dart
group('Invoice Posting Integration', () {
  test('complete invoice posting flow with validation', () async {
    // 1. إنشاء فترة محاسبية مفتوحة
    final period = await createOpenPeriod();
    
    // 2. إنشاء أصناف ومخزون
    final item = await createItemWithStock(quantity: 100);
    
    // 3. إنشاء فاتورة بيع
    final invoice = SalesInvoice(
      date: DateTime.now(),
      items: [
        InvoiceItemEntity(itemId: item.id, quantity: 10, price: 50),
      ],
      warehouseId: 1,
    );
    
    // 4. التحقق من الفاتورة
    final validationResult = await invoiceValidator.validateInvoiceItems(
      invoice.items,
      isSales: true,
      warehouseId: invoice.warehouseId,
    );
    
    expect(validationResult.isRight(), true);
    
    // 5. الترحيل
    final postResult = await accountingService.postInvoice(invoice);
    
    expect(postResult.isRight(), true);
    
    // 6. التحقق من خصم المخزون
    final newStock = await inventoryRepository.getStockLevel(itemId: item.id, warehouseId: 1);
    expect(newStock, equals(90));
    
    // 7. التحقق من إنشاء القيد المحاسبي
    final glEntry = await glRepository.getBySource('invoice', invoice.id);
    expect(glEntry, isNotNull);
    expect(glEntry!.lines.length, greaterThan(0));
  });

  test('invoice posting fails when period is closed', () async {
    // إنشاء فترة مغلقة
    final closedPeriod = await createClosedPeriod();
    
    final invoice = SalesInvoice(date: closedPeriod.endDate, items: [...]);
    
    final result = await accountingService.postInvoice(invoice);
    
    expect(result.isLeft(), true);
    final failure = result.getLeft()!;
    expect(failure.code, equals('AP_CLOSED_001'));
  });
});
```

---

## المرحلة 5: اختبار UI/UX

### 5.1 Widget Tests
**الملف:** `test/widgets/error_dialog_test.dart`

```dart
testWidgets('ErrorDialog displays Arabic message correctly', (tester) async {
  final failure = DatabaseFailure(
    code: 'DB_FK_001',
    messageAr: 'هذا الحقل مطلوب',
    messageEn: 'This field is required',
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ErrorDialog(failure: failure),
      ),
    ),
  );
  
  expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
  expect(find.byIcon(Icons.error), findsOneWidget);
});
```

---

## ✅ Checklist التنفيذ

| المهمة | الحالة | الملفات | الأولوية |
|--------|--------|---------|----------|
| كتابة اختبار Failure Classes | ⬜ | `failures_test.dart` | 🔴 عالي |
| كتابة اختبار GlobalErrorHandler | ⬜ | `global_error_handler_test.dart` | 🔴 عالي |
| كتابة اختبار InvoiceValidator | ⬜ | `invoice_validator_test.dart` | 🔴 عالي |
| كتابة اختبار AccountingPeriodValidator | ⬜ | `accounting_period_validator_test.dart` | 🟠 متوسط |
| كتابة اختبار JournalEntryValidator | ⬜ | `journal_entry_validator_test.dart` | 🟠 متوسط |
| كتابة Integration Tests | ⬜ | `invoice_posting_test.dart` | 🟡 منخفض |
| كتابة Widget Tests | ⬜ | `error_dialog_test.dart` | 🟡 منخفض |
| تحقيق 70% Coverage | ⬜ | تقرير coverage | 🟢 اختياري |

---

## 📊 أدوات الاختبار الموصى بها

```yaml
dev_dependencies:
  mockito: ^5.4.4
  build_runner: ^2.4.8
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

### تشغيل الاختبارات
```bash
# تشغيل كل الاختبارات
flutter test

# تشغيل اختبار محدد
flutter test test/core/validation/invoice_validator_test.dart

# توليد Mocks
flutter pub run build_runner build --delete-conflicting-outputs

# قياس التغطية
flutter test --coverage

# عرض التقرير
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🎯 معايير النجاح

1. ✅ **جميع الـ 39 Failure class** مختبرة
2. ✅ **GlobalErrorHandler** يغطي 100% من الحالات
3. ✅ **Validators الثلاثة** تغطي 90%+ من الحالات
4. ✅ **Integration tests** تغطي السيناريوهات الرئيسية
5. ✅ **لا توجد أخطاء unhandled** في logs
6. ✅ **70%+ coverage** إجمالي
