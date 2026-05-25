import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/pre_order_model.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/providers/pre_order_provider.dart'; // [เพิ่ม] เพื่อ refresh provider
import 'package:brightmotor_store/screens/complete_screen.dart';
import 'package:brightmotor_store/services/pre_order_service.dart';
import 'package:brightmotor_store/services/sell_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';

class PreOrderDetailDialog extends ConsumerStatefulWidget {
  final int preOrderId;

  const PreOrderDetailDialog({super.key, required this.preOrderId});

  @override
  ConsumerState<PreOrderDetailDialog> createState() => _PreOrderDetailDialogState();
}

class _PreOrderDetailDialogState extends ConsumerState<PreOrderDetailDialog> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // ✅ 1. ห่อหน้าต่างเดิมด้วย Stack เพื่อทำเลเยอร์ซ้อนทับ
      child: Stack(
        children: [
          // --- เลเยอร์ที่ 1: เนื้อหาหน้าต่างเดิม ---
          IgnorePointer(
            ignoring: isProcessing, // ✅ 2. ตัดการรับสัมผัสทั้งหมด หากกำลังโหลด (ป้องกันกดเบิ้ล 100%)
            child: Container(
              constraints: const BoxConstraints(maxHeight: 600),
              child: FutureBuilder<PreOrder>(
                future: ref.read(preOrderServiceProvider).getPreOrderDetail(widget.preOrderId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text("Error: ${snapshot.error}"),
                          const SizedBox(height: 16),
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ปิด"))
                        ],
                      ),
                    );
                  }

                  final order = snapshot.data!;
                  final canConfirm = order.status == 'Pending';

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("รายละเอียดคำสั่งซื้อ", style: Theme.of(context).textTheme.titleLarge),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Content
                      Flexible(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          shrinkWrap: true,
                          children: [
                            _buildInfoRow("เลขที่บิล", order.billNo),
                            _buildInfoRow("ลูกค้า", _safeGetCustomerName(order)),
                            _buildInfoRow("สถานะ", order.status),
                            _buildInfoRow("ยอดรวม", "฿${order.totalSoldPrice}"),
                            
                            const SizedBox(height: 16),
                            const Text("รายการสินค้า:", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            
                            if (order.items.isEmpty)
                              const Text("- ไม่พบรายการสินค้า -", style: TextStyle(color: Colors.grey)),
                            
                            ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6), // เพิ่มช่องว่างระหว่างบรรทัดนิดนึง
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start, // ให้อักษรเริ่มชิดบนเสมอ
                                children: [
                                  // 1. ชื่อสินค้า และ ราคาต่อหน่วย
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _safeGetProductName(item), 
                                          maxLines: 2, 
                                          overflow: TextOverflow.ellipsis
                                        ),
                                        const SizedBox(height: 2),
                                        // ตัวหนังสือเล็กๆ แสดงราคาต่อหน่วย
                                        Text(
                                          "ราคา/หน่วย: ฿${_safeGetUnitPrice(item)}",
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 2. จำนวน
                                  SizedBox(
                                    width: 40,
                                    child: Text("x${item.quantity}", textAlign: TextAlign.right)
                                  ),
                                  // 3. ราคารวมทุกชิ้นของแถวนี้
                                  SizedBox(
                                    width: 85, // เผื่อที่ให้ราคารวมเยอะขึ้นหน่อย
                                    child: Text(
                                      "฿${_safeGetTotalPrice(item)}", 
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue)
                                    )
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),

                      // Actions
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // ปุ่มหลัก (ยืนยัน)
                            if (canConfirm) ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: isProcessing ? null : () => _handleConfirm(context, order.id, ref),
                                  // ✅ เอา Spinner จิ๋วในปุ่มออก เพราะมีอันใหญ่บังจอแล้ว 
                                  child: const Text("ยืนยันรายการ (ส่งของ)"),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // ปุ่มรอง (ยกเลิก & ปิด)
                            Row(
                              children: [
                                if (canConfirm) ...[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.delete_forever, size: 18),
                                      label: const Text("ยกเลิก"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                      onPressed: isProcessing ? null : () => _showCancelConfirmation(context, order.id, ref),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isProcessing ? null : () => Navigator.pop(context),
                                    child: const Text("ปิดหน้าต่าง"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ),

          // --- เลเยอร์ที่ 2: ม่านบังหน้าจอตอนกำลังโหลด ---
          if (isProcessing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75), // ทำพื้นหลังให้เป็นสีขาวจางๆ
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "กำลังบันทึกข้อมูล...",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- [เพิ่ม] Dialog ยืนยันการยกเลิก ---
  void _showCancelConfirmation(BuildContext context, int preOrderId, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ยืนยันการยกเลิก"),
        content: const Text(
          "หากยกเลิกแล้วจะไม่สามารถย้อนกลับได้ ต้องสร้างใหม่โดยโกดังเท่านั้น\n\nคุณแน่ใจหรือไม่?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ไม่ยกเลิก", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx); // ปิด Confirm Dialog
              _handleCancel(context, preOrderId, ref); // เรียกฟังก์ชันยกเลิกจริง
            },
            child: const Text("ยืนยันยกเลิก"),
          ),
        ],
      ),
    );
  }

  // --- [เพิ่ม] Logic การยกเลิกจริง ---
  Future<void> _handleCancel(BuildContext context, int preOrderId, WidgetRef ref) async {
    setState(() => isProcessing = true);
  try {
      // เรียก API Cancel (ต้องเพิ่ม method นี้ใน PreOrderService ด้วย ถ้ายังไม่มี)
      // สมมติว่า method ชื่อ cancelPreOrder
      await ref.read(preOrderServiceProvider).cancelPreOrder(preOrderId);

      if (mounted) {
        Navigator.pop(context); // ปิด Dialog รายละเอียด
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ยกเลิกใบงานเรียบร้อยแล้ว"), backgroundColor: Colors.orange),
        );
        // Refresh List หน้าหลัก
        ref.invalidate(preOrderProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  // --- Logic ยืนยันรายการ (เดิม) ---
  Future<void> _handleConfirm(BuildContext context, int preOrderId, WidgetRef ref) async {
    setState(() => isProcessing = true);

    try {
      // 1. Get Raw Data
      final rawJson = await ref.read(preOrderServiceProvider).getPreOrderRaw(preOrderId);

      // 2. Transform to Sell Log Payload
      final sellLogPayload = {
        "truckId": rawJson['truck_id'],
        "customerId": rawJson['customer_id'],
        "isCredit": (rawJson['is_credit'] == null || rawJson['is_credit'] == 'cash') ? 0 : 1,
        "totalDiscount": rawJson['total_discount'].toString(),
        "totalSoldPrice": rawJson['total_sold_price'].toString(),
        "isPreOrder": true,
        "items": (rawJson['items'] as List).map((item) {
          return {
            "productId": item['product_id'],
            "quantity": item['quantity'],
            "price": double.tryParse(item['price'].toString()) ?? 0,
            "discount": item['discount'].toString(),
            "sold_price": item['sold_price'].toString(),
            "is_paid": (item['is_paid'] == 1 || item['is_paid'] == true),
          };
        }).toList(),
      };

      // 3. Create Sell Log
      try {
        await ref.read(sellServiceProvider).createSellLogFromPreOrder(sellLogPayload);
      } catch (e) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("สร้างรายการขายไม่สำเร็จ"),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("ตกลง"),
                ),
              ],
            ),
          );
        }
        return; // Skip confirm
      }

      // 4. Confirm Status
      await ref.read(preOrderServiceProvider).confirmPreOrder(preOrderId);

      // 5. Prepare data for Print (Complete Screen)
      final customerData = rawJson['customer'] ?? {};

      final String custAddr = customerData['address'] ?? '-';
      final String custPhone = customerData['phone'] ?? customerData['tel'] ?? '-';

      final truckData = rawJson['truck'] ?? {};
      // final userData = truckData['user'] ?? rawJson['user'] ?? {};
      final currentTruck = ref.read(currentTruckProvider);
      final String saleName = currentTruck?.fullName ?? '-';

      final bool isCreditBool = (rawJson['is_credit'] != null && rawJson['is_credit'] != 'cash');

      final List<CartItem> cartItemsForPrint = (rawJson['items'] as List).map((item) {
        final productData = item['product'] ?? {};

        // 1. ดึงส่วนลด และ ราคาสุทธิ จาก API
        final discountFromApi = double.tryParse(item['discount']?.toString() ?? '0') ?? 0.0;
        final soldPriceFromApi = double.tryParse(item['sold_price']?.toString() ?? '0') ?? 0.0;
        
        // 2. คำนวณราคาเต็มตั้งต้นคืนมา (ป้องกันบัคเซฟข้อมูลผิด)
        final realBasePrice = soldPriceFromApi + discountFromApi;
        final finalSellPrice = soldPriceFromApi > 0 
            ? realBasePrice 
            : (double.tryParse(item['price']?.toString() ?? '0') ?? 0.0);
        
        final product = Product(
          id: item['product_id'],
          description: productData['description'] ?? 'สินค้า',
          brand: productData['brand'] ?? '',
          model: productData['model'] ?? '',
          category: productData['category'] ?? '',
          unit: productData['unit'] ?? '',
          costPrice: (productData['cost_price'] ?? '0').toString(), 
          sellPrice: finalSellPrice.toString(),
          quantity: 0
        );

        return CartItem(
          product: product,
          quantity: item['quantity'],
          discountValue: discountFromApi
        );
      }).toList();

      if (mounted) {
        Navigator.pop(context); // ปิด Dialog
        
        // Refresh List หน้าหลัก (เพื่อให้รายการหายไปจากหน้า Pending)
        ref.invalidate(preOrderProvider);

        // ไปหน้า Complete Screen
        await launchCheckoutCompleteScreen(
          context, 
          cartItemsForPrint, 
           _safeGetCustomerName(PreOrder.fromJson(rawJson)),
           customerAddress: custAddr,
          customerPhone: custPhone,
          salespersonName: saleName,
          isCredit: isCreditBool,
          billNo: rawJson['bill_no']?.toString(), 
          isPreorder: true,
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  // Helper Functions
  String _safeGetCustomerName(dynamic order) {
    try { return order.customer.name; } catch (_) { 
      try { return order.customerName; } catch (__) { return "-"; }
    }
  }

  String _safeGetProductName(dynamic item) {
    try { return item.productName; } catch (_) { 
      try { return item.product.description; } catch (__) { return "-"; }
    }
  }
 // --- ฟังก์ชันดึงราคาต่อหน่วย ---
  // --- ฟังก์ชันดึงราคาต่อหน่วย (เวอร์ชันกันพลาด 100%) ---
  String _safeGetUnitPrice(dynamic item) {
    // ลิสต์ของตัวแปรที่ "น่าจะเป็นราคา" ทั้งหมดใน Model และ JSON
    final possibleValues = [
      () => item.soldPrice,
      () => item.price,
      () => item.sellPrice,
      () => item.product.sellPrice, // เผื่อราคาซ่อนอยู่ในก้อน product
      () => item.product.price,
      () => item['sold_price'],     // เผื่อข้อมูลมาเป็น Map JSON ดิบๆ
      () => item['price'],
    ];

    for (var getVal in possibleValues) {
      try {
        final val = getVal();
        if (val != null) {
          final parsed = double.tryParse(val.toString());
          if (parsed != null && parsed > 0) return parsed.toStringAsFixed(2);
        }
      } catch (_) {} // ถ้า Error (ไม่มีตัวแปรชื่อนี้) ให้ข้ามไปลองชื่อถัดไปเงียบๆ
    }
    return "0.00";
  }

  // --- ฟังก์ชันคำนวณราคารวมของแถวนั้น (เวอร์ชันกันพลาด 100%) ---
  String _safeGetTotalPrice(dynamic item) {
    // ลองหาฟิลด์ราคารวมสำเร็จรูปก่อน
    final possibleValues = [
      () => item.totalSoldPrice,
      () => item.totalPrice,
      () => item['total_sold_price'],
      () => item['total_price'],
    ];

    for (var getVal in possibleValues) {
      try {
        final val = getVal();
        if (val != null) {
          final parsed = double.tryParse(val.toString());
          if (parsed != null && parsed > 0) return parsed.toStringAsFixed(2);
        }
      } catch (_) {}
    }

    // ไม้ตายสุดท้าย: ถ้าระบบไม่ได้คำนวณราคารวมมาให้ เราจับ (ราคา x จำนวน) เองเลย!
    try {
      final unitPrice = double.tryParse(_safeGetUnitPrice(item)) ?? 0;
      double qty = 0;
      try { qty = double.parse(item.quantity.toString()); } catch (_) {
        try { qty = double.parse(item['quantity'].toString()); } catch (_) {}
      }
      
      if (unitPrice > 0 && qty > 0) {
        return (unitPrice * qty).toStringAsFixed(2);
      }
    } catch (_) {}

    return "0.00";
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}