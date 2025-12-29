import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/pre_order_model.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/screens/complete_screen.dart';
import 'package:brightmotor_store/services/pre_order_service.dart';
import 'package:brightmotor_store/services/sell_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(_safeGetProductName(item), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text("x${item.quantity}"),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isProcessing ? null : () => Navigator.pop(context),
                          child: const Text("ปิด"),
                        ),
                      ),
                      if (canConfirm) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: isProcessing ? null : () => _handleConfirm(context, order.id, ref),
                            child: isProcessing 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("ยืนยันรายการ"),
                          ),
                        ),
                      ]
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Logic ยืนยันรายการ ---
  Future<void> _handleConfirm(BuildContext context, int preOrderId, WidgetRef ref) async {
    setState(() => isProcessing = true);

    try {
      // 1. Confirm Status
      await ref.read(preOrderServiceProvider).confirmPreOrder(preOrderId);

      // 2. Get Raw Data
      final rawJson = await ref.read(preOrderServiceProvider).getPreOrderRaw(preOrderId);

      // 3. Transform to Sell Log Payload
      final sellLogPayload = {
        "truckId": rawJson['truck_id'],
        "customerId": rawJson['customer_id'],
        "isCredit": (rawJson['is_credit'] == null || rawJson['is_credit'] == 'cash') ? 0 : 1,
        "totalDiscount": rawJson['total_discount'].toString(),
        "totalSoldPrice": rawJson['total_sold_price'].toString(),
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

      // 4. Create Sell Log
      await ref.read(sellServiceProvider).createSellLogFromPreOrder(sellLogPayload);

      // 5. Prepare data for Print (Complete Screen)
      final List<CartItem> cartItemsForPrint = (rawJson['items'] as List).map((item) {
        final productData = item['product'] ?? {};
        
        // [แก้ไขให้ตรงกับ Model Product]
        // 1. ตัด productCode/code ทิ้ง เพราะไม่มีใน Model
        // 2. costPrice/sellPrice ต้องเป็น String (ตาม Model)
        final product = Product(
          id: item['product_id'],
          
          description: productData['description'] ?? 'สินค้า',
          brand: productData['brand'] ?? '',
          model: productData['model'] ?? '',
          category: productData['category'] ?? '',
          unit: productData['unit'] ?? '',
          
          // แปลงเป็น String ตาม Model
          costPrice: (productData['cost_price'] ?? '0').toString(), 
          sellPrice: (item['sold_price'] ?? '0').toString(), 
          
          quantity: 0
        );

        // CartItem ยังต้องการค่า discountValue เป็น double
        return CartItem(
          product: product,
          quantity: item['quantity'],
          discountValue: double.tryParse(item['discount'].toString()) ?? 0.0,
        );
      }).toList();

      if (mounted) {
        Navigator.pop(context); // ปิด Dialog
        
        // ไปหน้า Complete Screen
        await launchCheckoutCompleteScreen(
          context, 
          cartItemsForPrint
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