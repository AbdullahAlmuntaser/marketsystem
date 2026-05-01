import 'package:dartz/dartz.dart';
import '../failure/failures.dart';

/// Global Error Handler for the entire application
/// Handles all types of failures and provides user-friendly messages
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  /// Convert an exception to a Failure object
  Failure handleException(Object error, String context) {
    // If it's already a Failure, return it
    if (error is Failure) {
      return error;
    }

    final errorStr = error.toString();

    // Handle SQLite FOREIGN KEY exceptions
    if (errorStr.contains('FOREIGN KEY constraint failed')) {
      // Try to extract table and key info from error message
      final regex = RegExp(r'FOREIGN KEY constraint failed');
      if (regex.hasMatch(errorStr)) {
        return const ForeignKeyViolationFailure(
          table: 'unknown',
          foreignKey: 'unknown',
          value: 'unknown',
        );
      }
    }

    // Handle SQLite UNIQUE exceptions
    if (errorStr.contains('UNIQUE constraint failed')) {
      return const UniqueConstraintFailure(
        table: 'unknown',
        field: 'unknown',
        value: 'unknown',
      );
    }

    // Handle SQLite NOT NULL exceptions
    if (errorStr.contains('NOT NULL constraint failed')) {
      return const NotNullViolationFailure(
        table: 'unknown',
        field: 'unknown',
      );
    }

    // Handle SQLite CHECK exceptions
    if (errorStr.contains('CHECK constraint failed')) {
      return const CheckConstraintFailure(
        table: 'unknown',
        constraint: 'unknown',
        reason: 'Constraint violation',
      );
    }

    // Handle null values
    if (error is Null || 
        errorStr.contains('Null check operator used on a null value') ||
        errorStr.contains('NoSuchMethodError')) {
      return NullValueFailure(
        fieldName: 'unknown',
        context: context,
      );
    }

    // Handle type cast errors
    if (error is TypeError || 
        errorStr.contains('type') && errorStr.contains('is not a subtype')) {
      return TypeCastFailure(
        expectedType: 'unknown',
        actualType: 'unknown',
        context: context,
      );
    }

    // Default to unknown failure
    return UnknownFailure(
      message: errorStr,
      error: error,
    );
  }

  /// Get user-friendly Arabic message for a failure
  String getArabicMessage(Failure failure) {
    return failure.arabicMessage ?? failure.message;
  }

  /// Get error code for logging/tracking
  String? getErrorCode(Failure failure) {
    return failure.errorCode;
  }

  /// Log failure for debugging
  void logFailure(Failure failure, {String? additionalContext}) {
    print('[ERROR] ${failure.runtimeType}');
    print('  Message: ${failure.message}');
    print('  Arabic: ${failure.arabicMessage}');
    print('  Code: ${failure.errorCode}');
    if (failure.metadata != null) {
      print('  Metadata: ${failure.metadata}');
    }
    if (additionalContext != null) {
      print('  Context: $additionalContext');
    }
    print('---');
  }

  /// Show error dialog/message to user
  /// This should be integrated with your UI framework (Provider/Bloc)
  void showError(Failure failure, {required Function(String) onShow}) {
    final message = getArabicMessage(failure);
    onShow(message);
    logFailure(failure);
  }
}

/// Extension to easily convert exceptions to Failures
extension ExceptionToFailure on Object {
  Failure toFailure(String context) {
    return GlobalErrorHandler().handleException(this, context);
  }
}

/// Helper function to wrap async operations with error handling
Future<Either<Failure, T>> tryCatch<T>(
  Future<T> Function() operation,
  String context,
) async {
  try {
    final result = await operation();
    return Right(result);
  } catch (e) {
    final failure = e.toFailure(context);
    return Left(failure);
  }
}

/// Helper function to wrap sync operations with error handling
Either<Failure, T> tryCatchSync<T>(
  T Function() operation,
  String context,
) {
  try {
    final result = operation();
    return Right(result);
  } catch (e) {
    final failure = e.toFailure(context);
    return Left(failure);
  }
}
