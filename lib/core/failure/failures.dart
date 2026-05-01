import 'package:equatable/equatable.dart';

/// Base class for all failures in the system
abstract class Failure extends Equatable {
  final String message;
  final String? arabicMessage;
  final String? errorCode;
  final Map<String, dynamic>? metadata;

  const Failure({
    required this.message,
    this.arabicMessage,
    this.errorCode,
    this.metadata,
  });

  @override
  List<Object?> get props => [message, arabicMessage, errorCode, metadata];

  @override
  String toString() => 
      '$runtimeType(message: $message, arabicMessage: $arabicMessage, errorCode: $errorCode)';
}

// ==================== Database Failures ====================

class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.arabicMessage,
    super.errorCode,
    super.metadata,
  });
}

class ForeignKeyViolationFailure extends DatabaseFailure {
  const ForeignKeyViolationFailure({
    required String table,
    required String foreignKey,
    required dynamic value,
  }) : super(
          message: 'Foreign key constraint failed: $foreignKey ($value) not found in $table',
          arabicMessage: 'فشل قيد المفتاح الأجنبي: القيمة ($value) غير موجودة في جدول $table',
          errorCode: 'DB_FK_001',
          metadata: {'table': table, 'foreignKey': foreignKey, 'value': value},
        );
}

class UniqueConstraintFailure extends DatabaseFailure {
  const UniqueConstraintFailure({
    required String table,
    required String field,
    required dynamic value,
  }) : super(
          message: 'Unique constraint failed: $field ($value) already exists in $table',
          arabicMessage: 'فشل قيد التكرار: القيمة ($value) موجودة مسبقاً في حقل $field بجدول $table',
          errorCode: 'DB_UQ_001',
          metadata: {'table': table, 'field': field, 'value': value},
        );
}

class NotNullViolationFailure extends DatabaseFailure {
  const NotNullViolationFailure({
    required String table,
    required String field,
  }) : super(
          message: 'NOT NULL constraint failed: $field in $table cannot be null',
          arabicMessage: 'فشل قيد عدم السماح بالفراغ: الحقل $field في جدول $table لا يمكن أن يكون فارغاً',
          errorCode: 'DB_NN_001',
          metadata: {'table': table, 'field': field},
        );
}

class CheckConstraintFailure extends DatabaseFailure {
  const CheckConstraintFailure({
    required String table,
    required String constraint,
    required String reason,
  }) : super(
          message: 'Check constraint failed: $constraint - $reason',
          arabicMessage: 'فشل قيد التحقق: $constraint - $reason',
          errorCode: 'DB_CHK_001',
          metadata: {'table': table, 'constraint': constraint, 'reason': reason},
        );
}

class DatabaseConnectionFailure extends DatabaseFailure {
  const DatabaseConnectionFailure({
    required String reason,
  }) : super(
          message: 'Database connection failed: $reason',
          arabicMessage: 'فشل الاتصال بقاعدة البيانات: $reason',
          errorCode: 'DB_CONN_001',
          metadata: {'reason': reason},
        );
}

class TransactionFailure extends DatabaseFailure {
  const TransactionFailure({
    required String reason,
  }) : super(
          message: 'Transaction failed: $reason',
          arabicMessage: 'فشل المعاملة: $reason',
          errorCode: 'DB_TXN_001',
          metadata: {'reason': reason},
        );
}

// ==================== Accounting Period Failures ====================

class AccountingPeriodFailure extends Failure {
  const AccountingPeriodFailure({
    required super.message,
    super.arabicMessage,
    super.errorCode,
    super.metadata,
  });
}

class NoOpenPeriodFailure extends AccountingPeriodFailure {
  const NoOpenPeriodFailure({
    required DateTime transactionDate,
  }) : super(
          message: 'No open accounting period found for date: ${transactionDate.toIso8601String()}',
          arabicMessage: 'لا توجد فترة محاسبية مفتوحة لتاريخ: ${_formatDate(transactionDate)}',
          errorCode: 'AP_OPEN_001',
          metadata: {'transactionDate': transactionDate.toIso8601String()},
        );

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class ClosedPeriodFailure extends AccountingPeriodFailure {
  const ClosedPeriodFailure({
    required String periodName,
    required DateTime startDate,
    required DateTime endDate,
  }) : super(
          message: 'Accounting period $periodName is closed (${startDate.toIso8601String()} to ${endDate.toIso8601String()})',
          arabicMessage: 'الفترة المحاسبية "$periodName" مغلقة (من ${_formatDate(startDate)} إلى ${_formatDate(endDate)})',
          errorCode: 'AP_CLOSED_001',
          metadata: {
            'periodName': periodName,
            'startDate': startDate.toIso8601String(),
            'endDate': endDate.toIso8601String(),
          },
        );

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class PeriodNotFoundFailure extends AccountingPeriodFailure {
  const PeriodNotFoundFailure({
    required String periodId,
  }) : super(
          message: 'Accounting period with ID $periodId not found',
          arabicMessage: 'الفترة المحاسبية برمز $periodId غير موجودة',
          errorCode: 'AP_NOTFOUND_001',
          metadata: {'periodId': periodId},
        );
}

class PeriodDateRangeFailure extends AccountingPeriodFailure {
  const PeriodDateRangeFailure({
    required String reason,
  }) : super(
          message: 'Invalid period date range: $reason',
          arabicMessage: 'نطاق تواريخ الفترة المحاسبية غير صالح: $reason',
          errorCode: 'AP_RANGE_001',
          metadata: {'reason': reason},
        );
}

// ==================== Posting Failures ====================

class PostingFailure extends Failure {
  const PostingFailure({
    required super.message,
    super.arabicMessage,
    super.errorCode,
    super.metadata,
  });
}

class InvoicePostingFailure extends PostingFailure {
  const InvoicePostingFailure({
    required String invoiceNumber,
    required String reason,
  }) : super(
          message: 'Failed to post invoice $invoiceNumber: $reason',
          arabicMessage: 'فشل ترحيل الفاتورة رقم $invoiceNumber: $reason',
          errorCode: 'POST_INV_001',
          metadata: {'invoiceNumber': invoiceNumber, 'reason': reason},
        );
}

class JournalEntryPostingFailure extends PostingFailure {
  const JournalEntryPostingFailure({
    required String entryNumber,
    required String reason,
  }) : super(
          message: 'Failed to post journal entry $entryNumber: $reason',
          arabicMessage: 'فشل ترحيل القيد اليومي رقم $entryNumber: $reason',
          errorCode: 'POST_JE_001',
          metadata: {'entryNumber': entryNumber, 'reason': reason},
        );
}

class UnbalancedEntryFailure extends PostingFailure {
  const UnbalancedEntryFailure({
    required double debitTotal,
    required double creditTotal,
    required double difference,
  }) : super(
          message: 'Journal entry is unbalanced. Debit: $debitTotal, Credit: $creditTotal, Difference: $difference',
          arabicMessage: 'القيد اليومي غير متوازن. المدين: $debitTotal، الدائن: $creditTotal، الفرق: $difference',
          errorCode: 'POST_BAL_001',
          metadata: {
            'debitTotal': debitTotal,
            'creditTotal': creditTotal,
            'difference': difference,
          },
        );
}

class MissingAccountFailure extends PostingFailure {
  const MissingAccountFailure({
    required String accountCode,
    required String context,
  }) : super(
          message: 'Account $accountCode not found for $context',
          arabicMessage: 'الحساب $accountCode غير موجود لـ $context',
          errorCode: 'POST_ACC_001',
          metadata: {'accountCode': accountCode, 'context': context},
        );
}

class DuplicatePostingFailure extends PostingFailure {
  const DuplicatePostingFailure({
    required String documentType,
    required String documentNumber,
  }) : super(
          message: 'Document $documentType $documentNumber has already been posted',
          arabicMessage: 'المستند $documentType رقم $documentNumber تم ترحيله مسبقاً',
          errorCode: 'POST_DUP_001',
          metadata: {'documentType': documentType, 'documentNumber': documentNumber},
        );
}

// ==================== Operational Failures ====================

class OperationalFailure extends Failure {
  const OperationalFailure({
    required super.message,
    super.arabicMessage,
    super.errorCode,
    super.metadata,
  });
}

class InvalidQuantityFailure extends OperationalFailure {
  const InvalidQuantityFailure({
    required double quantity,
    required String itemName,
    required String reason,
  }) : super(
          message: 'Invalid quantity $quantity for item $itemName: $reason',
          arabicMessage: 'الكمية $quantity غير صالحة للصنف $itemName: $reason',
          errorCode: 'OP_QTY_001',
          metadata: {'quantity': quantity, 'itemName': itemName, 'reason': reason},
        );
}

class InvalidPriceFailure extends OperationalFailure {
  const InvalidPriceFailure({
    required double price,
    required String itemName,
    required String reason,
  }) : super(
          message: 'Invalid price $price for item $itemName: $reason',
          arabicMessage: 'السعر $price غير صالح للصنف $itemName: $reason',
          errorCode: 'OP_PRD_001',
          metadata: {'price': price, 'itemName': itemName, 'reason': reason},
        );
}

class InsufficientStockFailure extends OperationalFailure {
  const InsufficientStockFailure({
    required String itemName,
    required double requestedQuantity,
    required double availableQuantity,
    required String warehouseName,
  }) : super(
          message: 'Insufficient stock for $itemName. Requested: $requestedQuantity, Available: $availableQuantity in $warehouseName',
          arabicMessage: 'المخزون غير كافٍ للصنف $itemName. المطلوب: $requestedQuantity، المتوفر: $availableQuantity في مستودع $warehouseName',
          errorCode: 'OP_STK_001',
          metadata: {
            'itemName': itemName,
            'requestedQuantity': requestedQuantity,
            'availableQuantity': availableQuantity,
            'warehouseName': warehouseName,
          },
        );
}

class UnitMismatchFailure extends OperationalFailure {
  const UnitMismatchFailure({
    required String fromUnit,
    required String toUnit,
    required String itemName,
  }) : super(
          message: 'Unit mismatch for $itemName: cannot convert from $fromUnit to $toUnit',
          arabicMessage: 'عدم توافق الوحدات للصنف $itemName: لا يمكن التحويل من $fromUnit إلى $toUnit',
          errorCode: 'OP_UNIT_001',
          metadata: {'fromUnit': fromUnit, 'toUnit': toUnit, 'itemName': itemName},
        );
}

class NegativeStockFailure extends OperationalFailure {
  const NegativeStockFailure({
    required String itemName,
    required double resultingQuantity,
  }) : super(
          message: 'Operation would result in negative stock for $itemName: $resultingQuantity',
          arabicMessage: 'العملية ستؤدي إلى مخزون سالب للصنف $itemName: $resultingQuantity',
          errorCode: 'OP_NEG_001',
          metadata: {'itemName': itemName, 'resultingQuantity': resultingQuantity},
        );
}

// ==================== Integration Failures ====================

class IntegrationFailure extends Failure {
  const IntegrationFailure({
    required super.message,
    super.arabicMessage,
    super.errorCode,
    super.metadata,
  });
}

class InvoiceWarehouseSyncFailure extends IntegrationFailure {
  const InvoiceWarehouseSyncFailure({
    required String invoiceNumber,
    required String reason,
  }) : super(
          message: 'Failed to sync invoice $invoiceNumber with warehouse: $reason',
          arabicMessage: 'فشل مزامنة الفاتورة رقم $invoiceNumber مع المستودع: $reason',
          errorCode: 'INT_WH_001',
          metadata: {'invoiceNumber': invoiceNumber, 'reason': reason},
        );
}

class PurchaseOrderInvoiceFailure extends IntegrationFailure {
  const PurchaseOrderInvoiceFailure({
    required String poNumber,
    required String invoiceNumber,
    required String reason,
  }) : super(
          message: 'Failed to link invoice $invoiceNumber to purchase order $poNumber: $reason',
          arabicMessage: 'فشل ربط الفاتورة $invoiceNumber بأمر الشراء $poNumber: $reason',
          errorCode: 'INT_PO_001',
          metadata: {
            'poNumber': poNumber,
            'invoiceNumber': invoiceNumber,
            'reason': reason,
          },
        );
}

class SalesOrderInvoiceFailure extends IntegrationFailure {
  const SalesOrderInvoiceFailure({
    required String soNumber,
    required String invoiceNumber,
    required String reason,
  }) : super(
          message: 'Failed to link invoice $invoiceNumber to sales order $soNumber: $reason',
          arabicMessage: 'فشل ربط الفاتورة $invoiceNumber بأمر البيع $soNumber: $reason',
          errorCode: 'INT_SO_001',
          metadata: {
            'soNumber': soNumber,
            'invoiceNumber': invoiceNumber,
            'reason': reason,
          },
        );
}

class InventoryAccountingSyncFailure extends IntegrationFailure {
  const InventoryAccountingSyncFailure({
    required String operationType,
    required String reason,
  }) : super(
          message: 'Failed to sync $operationType between inventory and accounting: $reason',
          arabicMessage: 'فشل مزامنة $operationType بين المخزون والمحاسبة: $reason',
          errorCode: 'INT_IA_001',
          metadata: {'operationType': operationType, 'reason': reason},
        );
}

// ==================== UI/UX Failures ====================

class UIFailure extends Failure {
  const UIFailure({
    required super.message,
    super.arabicMessage,
    super.errorCode,
    super.metadata,
  });
}

class MissingFormFieldFailure extends UIFailure {
  const MissingFormFieldFailure({
    required String fieldName,
    required String screenName,
  }) : super(
          message: 'Required form field "$fieldName" is missing on screen "$screenName"',
          arabicMessage: 'حقل النموذج المطلوب "$fieldName" مفقود في شاشة "$screenName"',
          errorCode: 'UI_FIELD_001',
          metadata: {'fieldName': fieldName, 'screenName': screenName},
        );
}

class UnlinkedWidgetFailure extends UIFailure {
  const UnlinkedWidgetFailure({
    required String widgetName,
    required String screenName,
  }) : super(
          message: 'Widget "$widgetName" on screen "$screenName" is not linked to any logic',
          arabicMessage: 'العنصر "$widgetName" في شاشة "$screenName" غير مرتبط بأي منطق برمجي',
          errorCode: 'UI_LINK_001',
          metadata: {'widgetName': widgetName, 'screenName': screenName},
        );
}

class NavigationFailure extends UIFailure {
  const NavigationFailure({
    required String fromScreen,
    required String toScreen,
    required String reason,
  }) : super(
          message: 'Navigation from $fromScreen to $toScreen failed: $reason',
          arabicMessage: 'فشل الانتقال من $fromScreen إلى $toScreen: $reason',
          errorCode: 'UI_NAV_001',
          metadata: {
            'fromScreen': fromScreen,
            'toScreen': toScreen,
            'reason': reason,
          },
        );
}

// ==================== Unexpected Exceptions ====================

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.message,
    super.arabicMessage,
    super.errorCode,
    super.metadata,
  });
}

class NullValueFailure extends UnexpectedFailure {
  const NullValueFailure({
    required String fieldName,
    required String context,
  }) : super(
          message: 'Unexpected null value for field "$fieldName" in $context',
          arabicMessage: 'قيمة فارغة غير متوقعة للحقل "$fieldName" في $context',
          errorCode: 'EX_NULL_001',
          metadata: {'fieldName': fieldName, 'context': context},
        );
}

class TypeCastFailure extends UnexpectedFailure {
  const TypeCastFailure({
    required String expectedType,
    required String actualType,
    required String context,
  }) : super(
          message: 'Type cast failed: expected $expectedType but got $actualType in $context',
          arabicMessage: 'فشل تحويل النوع: المتوقع $expectedType لكن تم الحصول على $actualType في $context',
          errorCode: 'EX_TYPE_001',
          metadata: {
            'expectedType': expectedType,
            'actualType': actualType,
            'context': context,
          },
        );
}

class RuntimeFailure extends UnexpectedFailure {
  const RuntimeFailure({
    required String exceptionType,
    required String message,
    required String context,
  }) : super(
          message: 'Runtime exception ($exceptionType): $message in $context',
          arabicMessage: 'استثناء وقت التشغيل ($exceptionType): $message في $context',
          errorCode: 'EX_RUNTIME_001',
          metadata: {
            'exceptionType': exceptionType,
            'message': message,
            'context': context,
          },
        );
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    required String message,
    Object? error,
  }) : super(
          message: message,
          arabicMessage: 'حدث خطأ غير معروف: $message',
          errorCode: 'EX_UNKNOWN_001',
          metadata: {'error': error?.toString()},
        );
}
