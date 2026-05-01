# 🧪 خطة تطوير الاختبارات - Supermarket ERP

## الحالة الحالية
- **عدد ملفات الاختبار**: 7 ملفات
- **التغطية المقدرة**: < 20%
- **نوع الاختبارات**: Unit, Integration, Widget

## ✅ الاختبارات المنشأة حديثاً

### 1. `test/unit/error_handling_test.dart`
**الهدف**: اختبار فئات الأخطاء الموحدة (Failures)
**الحالة**: ⏳ قيد التطوير (TODOs)

**الاختبارات المطلوبة**:
- [ ] DatabaseFailure properties
- [ ] AccountingPeriodFailure properties
- [ ] ValidationFailure properties
- [ ] PostingFailure properties
- [ ] IntegrationFailure properties
- [ ] ServerFailure properties
- [ ] CacheFailure properties

### 2. `test/integration/error_handling_integration_test.dart`
**الهدف**: اختبار معالجة الأخطاء في السيناريوهات المتكاملة
**الحالة**: ⏳ قيد التطوير (TODOs)

**الاختبارات المطلوبة**:
- [ ] GlobalErrorHandler error handling
- [ ] Exception to Failure conversion
- [ ] Error stream emission
- [ ] postSale with closed period
- [ ] postSale with empty items
- [ ] postPurchase with missing account
- [ ] recordCustomerPayment validation
- [ ] Complete sales flow
- [ ] Complete purchase flow
- [ ] Sales return validation

## 📋 الخطوات التالية لتنفيذ الاختبارات

### المرحلة 1: إعداد Mocks (أولوية عالية)

```bash
# 1. تثبيت mockito
flutter pub add dev:mockito dev:build_runner --dev

# 2. إنشاء ملف mocks
# أضف @GenerateMocks في test/unit/error_handling_test.dart

# 3. توليد mocks
dart run build_runner build --delete-conflicting-outputs
```

**Mocks المطلوبة**:
- `MockAppDatabase`
- `MockAccountingService`
- `MockInventoryService`
- `MockSalesService`
- `MockPurchaseService`
- `MockGlobalErrorHandler`

### المرحلة 2: تنفيذ اختبارات Unit

#### 2.1 اختبارات Failures
```dart
// test/unit/failures_test.dart
test('DatabaseFailure should have correct message and code', () {
  final failure = DatabaseFailure(
    message: 'Test error',
    code: 'DB_TEST_ERROR'
  );
  expect(failure.message, equals('Test error'));
  expect(failure.code, equals('DB_TEST_ERROR'));
});
```

#### 2.2 اختبارات GlobalErrorHandler
```dart
// test/unit/global_error_handler_test.dart
test('Should convert DatabaseException to DatabaseFailure', () {
  // Implement test
});

test('Should emit errors to errorStream', () async {
  // Implement test
});
```

### المرحلة 3: تنفيذ اختبارات Integration

#### 3.1 اختبارات Accounting Service
```dart
// test/integration/accounting_service_test.dart
test('postSale returns Failure when period is closed', () async {
  // Setup: Create closed accounting period
  // Act: Call postSale
  // Assert: Returns AccountingPeriodFailure
});

test('postSale returns Failure when items are empty', () async {
  // Setup: Create sale with empty items
  // Act: Call postSale
  // Assert: Returns ValidationFailure
});
```

#### 3.2 اختبارات ERP Flow
```dart
// test/integration/erp_flow_test.dart
test('Complete sales flow with proper error handling', () async {
  // 1. Create customer account
  // 2. Post sale (success)
  // 3. Try post sale with closed period (failure)
  // 4. Try post sale with empty items (failure)
  // 5. Record payment (success)
  // 6. Verify all transactions
});
```

### المرحلة 4: اختبارات Performance

```dart
// test/performance/database_performance_test.dart
test('Should handle 1000 invoices in reasonable time', () async {
  // Insert 1000 invoices
  // Measure time
  // Assert: Time < threshold
});
```

## 🎯 معايير القبول

### للتغطية (Coverage)
- [ ] **Unit Tests**: ≥ 70% تغطية للكود
- [ ] **Integration Tests**: ≥ 50% تغطية للسيناريوهات الرئيسية
- [ ] **Widget Tests**: ≥ 30% تغطية للشاشات الحرجة

### للجودة (Quality)
- [ ] جميع الاختبارات تمر بنجاح
- [ ] لا توجد اختبارات معلقة (TODO) في الفرع الرئيسي
- [ ] وقت تشغيل الاختبارات < 5 دقائق
- [ ] اختبارات Deterministic (لا تعتمد على التوقيت)

## 📊 تتبع التقدم

| المرحلة | الحالة | النسبة |
|---------|--------|--------|
| إعداد Mocks | ⏳ لم يبدأ | 0% |
| Unit Tests - Failures | ⏳ لم يبدأ | 0% |
| Unit Tests - Services | ⏳ لم يبدأ | 0% |
| Integration Tests | ⏳ لم يبدأ | 0% |
| Widget Tests | ⏳ لم يبدأ | 0% |
| Performance Tests | ⏳ لم يبدأ | 0% |
| **الإجمالي** | **⏳ لم يبدأ** | **0%** |

## 🔧 أدوات مساعدة

### تشغيل الاختبارات
```bash
# كل الاختبارات
flutter test

# مع التغطية
flutter test --coverage

# ملف محدد
flutter test test/unit/error_handling_test.dart

# مجلد محدد
flutter test test/unit/

# مع تقرير JSON
flutter test --file-reporter=json:results.json
```

### عرض التغطية
```bash
# توليد تقرير HTML
genhtml coverage/lcov.info -o coverage/html

# فتح التقرير
open coverage/html/index.html
```

## 📝 ملاحظات مهمة

1. **لا تشغل الاختبارات بدون Flutter**: تحتاج لتثبيت Flutter أولاً
2. **رتّب الأولويات**: ابدأ بالاختبارات الحرجة (Critical Path)
3. **استخدم Fixtures**: أنشئ بيانات اختبار قابلة لإعادة الاستخدام
4. **تجنب الاعتماد على الشبكة**: استخدم Mocks لكل الاتصالات الخارجية
5. **اكتب اختبارات قابلة للقراءة**: اتبع نمط Arrange-Act-Assert

## 🆘 الدعم

لتنفيذ هذه الاختبارات:
1. ثبّت Flutter محلياً (راجع `SETUP_GUIDE.md`)
2. نفّذ الأوامر المذكورة في كل مرحلة
3. راجع النتائج وأصلح أي failures
4. حسّن التغطية تدريجياً

---

**تاريخ الإنشاء**: 2024
**آخر تحديث**: 2024
**الحالة**: مسودة - بانتظار تنفيذ الاختبارات
