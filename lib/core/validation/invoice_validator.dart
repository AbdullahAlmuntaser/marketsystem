import 'package:dartz/dartz.dart';
import '../failure/failures.dart';
import '../../entities/invoice_item_entity.dart';
import '../../entities/item_entity.dart';
import '../../../repositories/item_repository.dart';
import '../../../repositories/inventory_repository.dart';

/// خدمة التحقق من صحة بيانات الفواتير قبل الترحيل
/// تعالج: أخطاء العمليات، أخطاء الربط، وأخطاء البيانات الناقصة
class InvoiceValidator {
  final ItemRepository itemRepository;
  final InventoryRepository inventoryRepository;

  InvoiceValidator({
    required this.itemRepository,
    required this.inventoryRepository,
  });

  /// التحقق الشامل من قائمة أصناف الفاتورة
  /// يعود بـ Left(Failure) في حال وجود خطأ، أو Right(true) عند النجاح
  Future<Either<Failure, bool>> validateInvoiceItems(
    List<InvoiceItemEntity> items, {
    required bool isSales,
    int? warehouseId,
  }) async {
    if (items.isEmpty) {
      return Left(OperationalFailure(
        code: 'OP_EMPTY_001',
        messageAr: 'الفاتورة لا تحتوي على أي أصناف.',
        messageEn: 'Invoice contains no items.',
        metadata: {'item_count': 0},
      ));
    }

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      
      // 1. التحقق من عدم وجود قيم سالبة أو صفرية
      if (item.quantity <= 0) {
        return Left(OperationalFailure(
          code: 'OP_QTY_001',
          messageAr: 'الكمية في الصنف رقم ${i + 1} يجب أن تكون أكبر من صفر.',
          messageEn: 'Quantity in item #${i + 1} must be greater than zero.',
          metadata: {'index': i, 'quantity': item.quantity},
        ));
      }

      if (item.price < 0) {
        return Left(OperationalFailure(
          code: 'OP_PRICE_001',
          messageAr: 'السعر في الصنف رقم ${i + 1} لا يمكن أن يكون سالباً.',
          messageEn: 'Price in item #${i + 1} cannot be negative.',
          metadata: {'index': i, 'price': item.price},
        ));
      }

      // 2. التحقق من وجود الصنف في قاعدة البيانات
      final itemExists = await itemRepository.getItemById(item.itemId);
      if (itemExists.isNone()) {
        return Left(DatabaseFailure(
          code: 'DB_FK_002',
          messageAr: 'الصنف رقم ${item.itemId} غير موجود في قاعدة البيانات.',
          messageEn: 'Item ID ${item.itemId} not found in database.',
          metadata: {'item_id': item.itemId},
        ));
      }

      final itemData = itemExists.getOrElse(() => null);
      if (itemData == null) continue;

      // 3. التحقق من المخزون (للبيع فقط)
      if (isSales && warehouseId != null) {
        final currentStock = await inventoryRepository.getStockLevel(
          itemId: item.itemId,
          warehouseId: warehouseId,
          variantId: item.variantId,
        );

        if (currentStock < item.quantity) {
          return Left(OperationalFailure(
            code: 'OP_STOCK_001',
            messageAr: 'الرصيد غير كافٍ للصنف "${itemData.name}". المتاح: $currentStock، المطلوب: ${item.quantity}',
            messageEn: 'Insufficient stock for "${itemData.name}". Available: $currentStock, Required: ${item.quantity}',
            metadata: {
              'item_id': item.itemId,
              'item_name': itemData.name,
              'available': currentStock,
              'required': item.quantity,
              'warehouse_id': warehouseId,
            },
          ));
        }
      }

      // 4. التحقق من تاريخ الصلاحية (إذا كان الصنف يدار بالصلاحية)
      if (itemData.hasExpiry && item.expiryDate != null) {
        if (item.expiryDate!.isBefore(DateTime.now())) {
          return Left(OperationalFailure(
            code: 'OP_EXP_001',
            messageAr: 'تاريخ صلاحية الصنف "${itemData.name}" منتهي أو غير صالح.',
            messageEn: 'Expiry date for "${itemData.name}" is expired or invalid.',
            metadata: {
              'item_id': item.itemId,
              'expiry_date': item.expiryDate.toString(),
            },
          ));
        }
      }
    }

    return const Right(true);
  }

  /// التحقق من إجماليات الفاتورة
  Either<Failure, bool> validateInvoiceTotals({
    required double totalAmount,
    required double taxAmount,
    required double discountAmount,
    required List<InvoiceItemEntity> items,
  }) {
    if (totalAmount < 0) {
      return Left(OperationalFailure(
        code: 'OP_TOTAL_001',
        messageAr: 'إجمالي الفاتورة لا يمكن أن يكون سالباً.',
        messageEn: 'Invoice total cannot be negative.',
        metadata: {'total': totalAmount},
      ));
    }

    // حساب مجموع الأصناف للتأكد من تطابقه مع الإجمالي
    double calculatedSubtotal = items.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.price),
    );

    double calculatedTotal = calculatedSubtotal - discountAmount + taxAmount;
    
    // نسمح بهامش خطأ بسيط جداً بسبب الفواصل العشرية
    if ((calculatedTotal - totalAmount).abs() > 0.05) {
      return Left(OperationalFailure(
        code: 'OP_CALC_001',
        messageAr: 'توجد اختلافات في حسابات الفاتورة. المحسوب: $calculatedTotal، المدخل: $totalAmount',
        messageEn: 'Invoice calculation mismatch. Calculated: $calculatedTotal, Entered: $totalAmount',
        metadata: {
          'calculated': calculatedTotal,
          'entered': totalAmount,
          'diff': (calculatedTotal - totalAmount).abs(),
        },
      ));
    }

    return const Right(true);
  }
}
