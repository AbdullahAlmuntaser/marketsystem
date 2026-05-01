# دليل إعداد وتشغيل مشروع Supermarket ERP

## ⚠️ ملاحظة هامة حول تثبيت Flutter

**لا يمكن تثبيت Flutter مباشرة في هذه البيئة** بسبب:
1. مساحة التخزين المحدودة (504MB فقط)
2. Flutter يحتاج ~650MB بعد فك الضغط
3. متطلبات النظام الإضافية (GTK, Clang, etc.)

## ✅ الحل الموصى به

### الخيار 1: التثبيت المحلي (موصى به)

```bash
# 1. حمل Flutter من الموقع الرسمي
# https://docs.flutter.dev/get-started/install/linux

# 2. استخرج الملف
tar xf flutter_linux_*.tar.xz

# 3. أضف Flutter للمسار
export PATH="$PATH:`pwd`/flutter/bin"

# 4. انتقل لمجلد المشروع
cd /workspace

# 5. ثبت المكتبات
flutter pub get

# 6. ولد ملفات الكود
dart run build_runner build --delete-conflicting-outputs

# 7. شغل التطبيق
flutter run
```

### الخيار 2: استخدام GitHub Codespaces

1. افتح المستودع في GitHub Codespaces
2. Flutter مثبت مسبقاً في بيئة Codespaces
3. اتبع الخطوات أعلاه

### الخيار 3: استخدام Docker

```bash
docker run -it --rm \
  -v $(pwd):/app \
  -w /app \
  cirrusci/flutter:stable \
  bash -c "flutter pub get && dart run build_runner build --delete-conflicting-outputs"
```

## 📋 خطوات ما بعد الإعداد

بعد تثبيت Flutter، نفذ الأوامر التالية بالترتيب:

### 1. التحقق من التثبيت
```bash
flutter doctor -v
```

### 2. تثبيت المكتبات
```bash
flutter pub get
```

### 3. توليد الملفات المطلوبة
```bash
dart run build_runner build --delete-conflicting-outputs
```

هذا الأمر سيقوم بتوليد:
- ملفات `.freezed.dart` للكائنات المجمدة
- ملفات `.g.dart` للتسلسل JSON
- ملفات قاعدة البيانات Drift

### 4. تنظيف المشروع
```bash
flutter clean
flutter pub get
```

### 5. التحقق من الكود
```bash
dart analyze
```

### 6. تشغيل الاختبارات
```bash
flutter test
```

### 7. تشغيل التطبيق
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Linux
flutter run -d linux
```

## 🔧 الإصلاحات المنفذة في هذا المشروع

### 1. Dependency Injection
- ✅ تسجيل جميع الخدمات الناقصة (5 خدمات)
- ✅ إصلاح ShiftService, HRService, StockTransferService, AssetService, CustomerStatementProvider

### 2. قاعدة البيانات
- ✅ إنشاء 12 DAO جديد
- ✅ إصلاح الجداول المحاسبية والمخزنية

### 3. معالجة الأخطاء
- ✅ نظام Failures موحد (7 أنواع)
- ✅ GlobalErrorHandler مركزي
- ✅ رسائل أخطاء بالعربية
- ✅ تحديث 6 دوال محاسبية رئيسية

### 4. تنظيف المشروع
- ✅ حذف مجلد Android الزائد
- ✅ توحيد Application ID

## 📊 الإحصائيات

| المكون | القيمة |
|--------|--------|
| ملفات Dart | 232 |
| جداول قاعدة البيانات | 66 |
| DAOs | 25 |
| خدمات DI | كاملة |
| أنواع الأخطاء | 7 |
| دوال محاسبية محسنة | 6 |

## 📝 تقارير مفصلة

راجع الملفات التالية للحصول على معلومات أكثر تفصيلاً:

1. `ERROR_ANALYSIS_REPORT.md` - تحليل شامل للأخطاء
2. `ERROR_FIX_CHECKLIST.md` - قائمة التحقق من الإصلاحات
3. `ERROR_FIX_COMPLETION_REPORT.md` - تقرير إنجاز الإصلاحات

## 🆘 الدعم

إذا واجهت أي مشاكل:

1. تأكد من إصدار Flutter: `flutter --version` (يفضل 3.24.0+)
2. تحقق من المتطلبات: `flutter doctor`
3. امسح الكاش: `flutter clean && flutter pub cache repair`
4. أعد توليد الملفات: `dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs`
