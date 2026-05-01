import 'package:dartz/dartz.dart';
import '../failure/failures.dart';

/// خدمة التحقق من الفترات المحاسبية
/// تعالج: أخطاء الفترات المحاسبية وأخطاء الترحيل
class AccountingPeriodValidator {
  final dynamic _periodRepository; // سيتم استبداله بـ AccountingPeriodRepository

  AccountingPeriodValidator({
    required dynamic periodRepository,
  }) : _periodRepository = periodRepository;

  /// التحقق من وجود فترة محاسبية مفتوحة لتاريخ معين
  Future<Either<Failure, int>> validateOpenPeriod(DateTime transactionDate) async {
    try {
      // البحث عن فترة محاسبية تحتوي التاريخ ومفتوحة للترحيل
      final openPeriod = await _periodRepository.getOpenPeriodForDate(transactionDate);
      
      if (openPeriod.isNone()) {
        return Left(AccountingPeriodFailure(
          code: 'AP_OPEN_001',
          messageAr: 'لا توجد فترة محاسبية مفتوحة لتاريخ ${_formatDate(transactionDate)}. يرجى فتح فترة محاسبية أولاً.',
          messageEn: 'No open accounting period found for date ${_formatDate(transactionDate)}. Please open an accounting period first.',
          metadata: {
            'transaction_date': transactionDate.toIso8601String(),
          },
        ));
      }

      final period = openPeriod.getOrElse(() => null);
      if (period == null) {
        return Left(AccountingPeriodFailure(
          code: 'AP_OPEN_002',
          messageAr: 'حدث خطأ غير متوقع في جلب الفترة المحاسبية.',
          messageEn: 'Unexpected error while fetching accounting period.',
          metadata: {'transaction_date': transactionDate.toIso8601String()},
        ));
      }

      // التحقق من أن الفترة ليست مغلقة
      if (period.isClosed) {
        return Left(AccountingPeriodFailure(
          code: 'AP_CLOSED_001',
          messageAr: 'الفترة المحاسبية "${period.name}" مغلقة ولا يمكن الترحيل فيها. تاريخ الإغلاق: ${_formatDate(period.closedDate)}',
          messageEn: 'Accounting period "${period.name}" is closed and cannot be posted to. Closed date: ${_formatDate(period.closedDate)}',
          metadata: {
            'period_id': period.id,
            'period_name': period.name,
            'closed_date': period.closedDate?.toIso8601String(),
          },
        ));
      }

      // التحقق من أن التاريخ ضمن نطاق الفترة
      if (transactionDate.isBefore(period.startDate) || 
          transactionDate.isAfter(period.endDate)) {
        return Left(AccountingPeriodFailure(
          code: 'AP_RANGE_001',
          messageAr: 'تاريخ العملية (${_formatDate(transactionDate)}) خارج نطاق الفترة المحاسبية "${period.name}" (${_formatDate(period.startDate)} - ${_formatDate(period.endDate)})',
          messageEn: 'Transaction date (${_formatDate(transactionDate)}) is outside the range of accounting period "${period.name}" (${_formatDate(period.startDate)} - ${_formatDate(period.endDate)})',
          metadata: {
            'transaction_date': transactionDate.toIso8601String(),
            'period_start': period.startDate.toIso8601String(),
            'period_end': period.endDate.toIso8601String(),
          },
        ));
      }

      return Right(period.id);
    } catch (e) {
      return Left(UnexpectedException(
        code: 'UE_DB_001',
        messageAr: 'حدث خطأ أثناء التحقق من الفترة المحاسبية: $e',
        messageEn: 'Error occurred while validating accounting period: $e',
        exception: e,
        metadata: {'transaction_date': transactionDate.toIso8601String()},
      ));
    }
  }

  /// التحقق من إمكانية الترحيل لفترة معينة
  Future<Either<Failure, bool>> canPostToPeriod(int periodId) async {
    try {
      final period = await _periodRepository.getPeriodById(periodId);
      
      if (period.isNone()) {
        return Left(DatabaseFailure(
          code: 'DB_FK_003',
          messageAr: 'الفترة المحاسبية رقم $periodId غير موجودة.',
          messageEn: 'Accounting period ID $periodId not found.',
          metadata: {'period_id': periodId},
        ));
      }

      final periodData = period.getOrElse(() => null);
      if (periodData == null) {
        return const Right(false);
      }

      if (periodData.isClosed) {
        return Left(AccountingPeriodFailure(
          code: 'AP_CLOSED_002',
          messageAr: 'لا يمكن الترحيل للفترة "${periodData.name}" لأنها مغلقة.',
          messageEn: 'Cannot post to period "${periodData.name}" because it is closed.',
          metadata: {'period_id': periodId, 'period_name': periodData.name},
        ));
      }

      return const Right(true);
    } catch (e) {
      return Left(UnexpectedException(
        code: 'UE_DB_002',
        messageAr: 'حدث خطأ أثناء التحقق من إمكانية الترحيل: $e',
        messageEn: 'Error occurred while checking posting permission: $e',
        exception: e,
        metadata: {'period_id': periodId},
      ));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
