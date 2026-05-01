import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

/// فشل عام في النظام
abstract class Failure {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  Failure({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// فشل في قاعدة البيانات
class DatabaseFailure extends Failure {
  DatabaseFailure({
    required String message,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message: _mapDatabaseError(message, error),
          code: _mapDatabaseCode(message, error),
          originalError: error,
          stackTrace: stackTrace,
        );

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

  static String? _mapDatabaseCode(String message, dynamic error) {
    if (error.toString().contains('FOREIGN KEY')) return 'DB_FK_VIOLATION';
    if (error.toString().contains('UNIQUE')) return 'DB_UNIQUE_VIOLATION';
    if (error.toString().contains('NOT NULL')) return 'DB_NULL_VIOLATION';
    return 'DB_UNKNOWN_ERROR';
  }
}

/// فشل في الفترة المحاسبية
class AccountingPeriodFailure extends Failure {
  AccountingPeriodFailure({
    required String message,
    dynamic error,
  }) : super(
          message: message.isEmpty 
              ? 'لا توجد فترة محاسبية مفتوحة. يرجى فتح فترة محاسبية قبل تسجيل العمليات.' 
              : message,
          code: 'ACC_PERIOD_CLOSED',
          originalError: error,
        );
}

/// فشل في الترحيل
class PostingFailure extends Failure {
  PostingFailure({
    required String message,
    dynamic error,
  }) : super(
          message: 'فشل الترحيل: $message',
          code: 'POSTING_FAILED',
          originalError: error,
        );
}

/// فشل في التحقق من البيانات
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  ValidationFailure({
    required String message,
    this.fieldErrors,
    dynamic error,
  }) : super(
          message: message,
          code: 'VALIDATION_ERROR',
          originalError: error,
        );
}

/// فشل في التكامل
class IntegrationFailure extends Failure {
  IntegrationFailure({
    required String message,
    required String module,
    dynamic error,
  }) : super(
          message: 'فشل التكامل بين $module: $message',
          code: 'INTEGRATION_ERROR',
          originalError: error,
        );
}

/// معالج الأخطاء العالمي
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  final _errorController = StreamController<Failure>.broadcast();
  Stream<Failure> get errorStream => _errorController.stream;

  void handleFailure(Failure failure) {
    debugPrint('❌ [GLOBAL ERROR] ${failure.code}: ${failure.message}');
    if (kDebugMode && failure.stackTrace != null) {
      debugPrint('StackTrace: ${failure.stackTrace}');
    }
    _errorController.add(failure);
  }

  Either<Failure, T> catchFailure<T>(T Function() operation) {
    try {
      return Right(operation());
    } catch (e, stack) {
      final failure = _mapExceptionToFailure(e, stack);
      handleFailure(failure);
      return Left(failure);
    }
  }

  Future<Either<Failure, T>> catchFailureAsync<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      return Right(result);
    } catch (e, stack) {
      final failure = _mapExceptionToFailure(e, stack);
      handleFailure(failure);
      return Left(failure);
    }
  }

  Failure _mapExceptionToFailure(dynamic exception, StackTrace stack) {
    if (exception is Failure) return exception;
    
    final errorMsg = exception.toString();
    
    if (errorMsg.contains('FOREIGN KEY') || errorMsg.contains('UNIQUE') || 
        errorMsg.contains('NOT NULL') || errorMsg.contains('SQL')) {
      return DatabaseFailure(message: errorMsg, error: exception, stackTrace: stack);
    }
    
    if (errorMsg.contains('period') || errorMsg.contains('فترة')) {
      return AccountingPeriodFailure(message: errorMsg, error: exception);
    }
    
    if (errorMsg.contains('posting') || errorMsg.contains('ترحيل')) {
      return PostingFailure(message: errorMsg, error: exception);
    }

    return Failure(
      message: 'حدث خطأ غير متوقع: $errorMsg',
      code: 'UNKNOWN_EXCEPTION',
      originalError: exception,
      stackTrace: stack,
    );
  }

  void dispose() {
    _errorController.close();
  }
}

// Extension methods لاستخدام أسهل
extension EitherExtension<T> on Either<Failure, T> {
  Future<Either<Failure, R>> flatMap<R>(Either<Failure, R> Function(T value) mapper) async {
    return fold(
      (failure) => Left(failure),
      (value) => mapper(value),
    );
  }
}
