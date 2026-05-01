import 'package:dartz/dartz.dart';
import '../failure/failures.dart';

/// خدمة التحقق من صحة القيود المحاسبية (Journal Entries)
/// تعالج: أخطاء الترحيل، أخطاء التوازن، وأخطاء البيانات الناقصة
class JournalEntryValidator {
  
  /// التحقق من توازن القيد المحاسبي
  /// يجب أن يكون مجموع المدين = مجموع الدائن
  Either<Failure, bool> validateEntryBalance({
    required List<Map<String, dynamic>> lines,
  }) {
    if (lines.isEmpty) {
      return Left(PostingFailure(
        code: 'PF_EMPTY_001',
        messageAr: 'القيد المحاسبي لا يحتوي على أي أسطر.',
        messageEn: 'Journal entry contains no lines.',
        metadata: {'lines_count': 0},
      ));
    }

    if (lines.length < 2) {
      return Left(PostingFailure(
        code: 'PF_LINES_001',
        messageAr: 'القيد المحاسبي يجب أن يحتوي على سطرین على الأقل (مدين ودائن).',
        messageEn: 'Journal entry must have at least two lines (debit and credit).',
        metadata: {'lines_count': lines.length},
      ));
    }

    double totalDebit = 0.0;
    double totalCredit = 0.0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // التحقق من وجود الحساب
      if (line['accountId'] == null || line['accountId'] <= 0) {
        return Left(DatabaseFailure(
          code: 'DB_FK_004',
          messageAr: 'السطر رقم ${i + 1} لا يحتوي على حساب صالح.',
          messageEn: 'Line #${i + 1} does not contain a valid account.',
          metadata: {'line_index': i, 'account_id': line['accountId']},
        ));
      }

      // التحقق من وجود مبلغ
      if (line['amount'] == null || line['amount'] <= 0) {
        return Left(PostingFailure(
          code: 'PF_AMOUNT_001',
          messageAr: 'السطر رقم ${i + 1} لا يحتوي على مبلغ صالح.',
          messageEn: 'Line #${i + 1} does not contain a valid amount.',
          metadata: {'line_index': i, 'amount': line['amount']},
        ));
      }

      // التحقق من نوع الحركة (مدين/دائن)
      final isDebit = line['isDebit'] ?? true;
      final amount = line['amount'] as double;

      if (isDebit) {
        totalDebit += amount;
      } else {
        totalCredit += amount;
      }
    }

    // التحقق من التوازن مع هامش خطأ بسيط جداً
    if ((totalDebit - totalCredit).abs() > 0.01) {
      return Left(PostingFailure(
        code: 'PF_BALANCE_001',
        messageAr: 'القيد غير متوازن. مجموع المدين: $totalDebit، مجموع الدائن: $totalCredit، الفرق: ${(totalDebit - totalCredit).abs()}',
        messageEn: 'Entry is out of balance. Total Debit: $totalDebit, Total Credit: $totalCredit, Difference: ${(totalDebit - totalCredit).abs()}',
        metadata: {
          'total_debit': totalDebit,
          'total_credit': totalCredit,
          'difference': (totalDebit - totalCredit).abs(),
        },
      ));
    }

    return const Right(true);
  }

  /// التحقق من صحة الحسابات في القيد
  Future<Either<Failure, bool>> validateAccounts(
    List<Map<String, dynamic>> lines,
    dynamic accountRepository, // سيتم استبداله بـ AccountRepository
  ) async {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final accountId = line['accountId'];

      // التحقق من وجود الحساب
      final accountExists = await accountRepository.getAccountById(accountId);
      if (accountExists.isNone()) {
        return Left(DatabaseFailure(
          code: 'DB_FK_005',
          messageAr: 'الحساب رقم $accountId في السطر ${i + 1} غير موجود.',
          messageEn: 'Account ID $accountId in line #${i + 1} not found.',
          metadata: {'line_index': i, 'account_id': accountId},
        ));
      }

      final account = accountExists.getOrElse(() => null);
      if (account == null) continue;

      // التحقق من أن الحساب نشط
      if (!account.isActive) {
        return Left(DatabaseFailure(
          code: 'DB_INACTIVE_001',
          messageAr: 'الحساب "${account.name}" (رقم $accountId) غير نشط ولا يمكن استخدامه في القيود.',
          messageEn: 'Account "${account.name}" (ID $accountId) is inactive and cannot be used in entries.',
          metadata: {'line_index': i, 'account_id': accountId, 'account_name': account.name},
        ));
      }

      // التحقق من نوع الحساب (أصول، خصوم، إلخ)
      if (line['expectedType'] != null && account.accountType != line['expectedType']) {
        return Left(PostingFailure(
          code: 'PF_TYPE_001',
          messageAr: 'نوع الحساب "${account.name}" (${account.accountType}) لا يتوافق مع النوع المتوقع (${line['expectedType']}).',
          messageEn: 'Account type "${account.name}" (${account.accountType}) does not match expected type (${line['expectedType']}).',
          metadata: {
            'line_index': i,
            'account_id': accountId,
            'account_name': account.name,
            'actual_type': account.accountType,
            'expected_type': line['expectedType'],
          },
        ));
      }
    }

    return const Right(true);
  }

  /// التحقق من وجود مراجع ضرورية (مثل رقم الفاتورة، أمر الشراء، إلخ)
  Either<Failure, bool> validateReferences({
    String? referenceNumber,
    String? sourceDocument,
    required bool requireReference,
  }) {
    if (requireReference && (referenceNumber == null || referenceNumber.trim().isEmpty)) {
      return Left(PostingFailure(
        code: 'PF_REF_001',
        messageAr: 'يجب إدخال رقم مرجعي للمستند المصدر.',
        messageEn: 'Reference number for source document is required.',
        metadata: {
          'source_document': sourceDocument,
          'require_reference': requireReference,
        },
      ));
    }

    return const Right(true);
  }
}
