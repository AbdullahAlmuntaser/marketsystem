import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const Failure(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
    List properties = const <dynamic>[],
  });
}

/// فشل في قاعدة البيانات
class DatabaseFailure extends Failure {
  const DatabaseFailure(
    String message, {
    super.code,
    super.originalError,
    super.stackTrace,
  }) : super(_mapDatabaseError(message, originalError));

  static String _mapDatabaseError(String message, dynamic error) {
    if (error.toString().contains('FOREIGN KEY constraint failed')) {
      return 'خطأ في المرجعية: البيانات المرتبطة غير موجودة. تأكد من وجود السجل المرتبط أولاً.';
    }
    if (error.toString().contains('UNIQUE constraint failed')) {
      return 'تكرار غير مسموح: هذه القيمة مسجلة مسبقاً.';
    }
    if (error.toString().contains('NOT NULL constraint failed')) {
      return 'بيانات ناقصة: يجب تعبئة جميع الحقول المطلوبة.';
    }
    if (error.toString().contains('no such table')) {
      return 'خطأ هيكلي: الجدول غير موجود. قد تحتاج إلى ترقية قاعدة البيانات.';
    }
    return message;
  }

  @override
  List<Object?> get props => [message, code];
}

/// فشل في الفترة المحاسبية
class AccountingPeriodFailure extends Failure {
  const AccountingPeriodFailure([
    String message = '',
  ]) : super(
          message.isEmpty
              ? 'لا توجد فترة محاسبية مفتوحة. يرجى فتح فترة محاسبية قبل تسجيل العمليات.'
              : message,
          code: 'ACC_PERIOD_CLOSED',
        );

  @override
  List<Object?> get props => [message, code];
}

/// فشل في الترحيل
class PostingFailure extends Failure {
  const PostingFailure(
    String message, {
    super.originalError,
  }) : super('فشل الترحيل: $message', code: 'POSTING_FAILED');

  @override
  List<Object?> get props => [message, code];
}

/// فشل في التحقق من البيانات
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(
    String message, {
    this.fieldErrors,
    super.originalError,
  }) : super(message, code: 'VALIDATION_ERROR');

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// فشل في التكامل
class IntegrationFailure extends Failure {
  const IntegrationFailure({
    required String message,
    required String module,
    super.originalError,
  }) : super('فشل التكامل بين $module: $message', code: 'INTEGRATION_ERROR');

  @override
  List<Object?> get props => [message, code];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure([
    String message = 'حدث خطأ في الخادم',
  ]) : super(message, code: 'SERVER_ERROR');

  @override
  List<Object?> get props => [message, code];
}

class CacheFailure extends Failure {
  const CacheFailure([
    String message = 'فشل الوصول للذاكرة المؤقتة',
  ]) : super(message, code: 'CACHE_ERROR');

  @override
  List<Object?> get props => [message, code];
}
