import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:brightmotor_store/printer/print_service.dart';
import 'package:brightmotor_store/providers/printer_provider.dart'; // อย่าลืม import provider ที่สร้าง
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:brightmotor_store/utils/preferences.dart';

class PrinterPage extends ConsumerStatefulWidget {
  const PrinterPage({super.key});

  @override
  _PrinterPageState createState() => _PrinterPageState();
}

class _PrinterPageState extends ConsumerState<PrinterPage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> devices = [];
  final Preferences preferences = Preferences();
  final TextEditingController _codePageController = TextEditingController(text: '22');
  bool _isImageMode = false;
  double _fontSize = 18.0;
  @override
  void initState() {
    super.initState();
    _initPrinter();
    _getPrinterSettings();
  }

  Future<void> _getPrinterSettings() async {
    bool imageMode = await preferences.getPrinterImageMode();
    double fontSize = await preferences.getPrinterFontSize(); // โหลด Font Size
    setState(() {
      _isImageMode = imageMode;
      _fontSize = fontSize;
    });
  }

  Future<void> _initPrinter() async {
    // 1. ดึงรายชื่ออุปกรณ์ Bluetooth ทั้งหมดที่เคย Pair ไว้
    await _getDevices();

    final savedCodePage = await preferences.getPrinterCodePage();
    final savedImageMode = await preferences.getPrinterImageMode();

    setState(() {
      _codePageController.text = savedCodePage.toString();
      _isImageMode = savedImageMode;
    });

    // 2. เช็คว่ามีค่าที่บันทึกไว้ไหม (Saved Printer)
    final savedPrinter = await preferences.getSavedPrinter();

    if (savedPrinter != null) {
      final savedAddress = savedPrinter['address'];
      
      // ค้นหาใน list devices ว่ามีตัวที่ตรงกับ savedAddress ไหม
      try {
        final device = devices.firstWhere((d) => d.address == savedAddress);
        
        // ถ้าเจอ: เซ็ตค่าลง Provider เพื่อให้ Dropdown โชว์ชื่อ
        ref.read(selectedPrinterProvider.notifier).state = device;

        // 3. ลองเชื่อมต่ออัตโนมัติ (Auto Connect)
        bool? isConnected = await bluetooth.isConnected;
        if (isConnected != true) {
          try {
            await bluetooth.connect(device);
            ref.read(isPrinterConnectedProvider.notifier).state = true;
            print("Auto connected to ${device.name}");
          } catch (e) {
            print("Auto connect failed: $e");
            // ถ้าต่อไม่ได้ (เช่น ปิดเครื่องปริ้นอยู่) ก็ไม่เป็นไร แค่ค้างชื่อไว้ใน Dropdown
          }
        } else {
           ref.read(isPrinterConnectedProvider.notifier).state = true;
        }
      } catch (e) {
        print("Saved printer not found in bonded devices");
      }
    } else {
      // ถ้าไม่มีค่าบันทึก ก็เช็คสถานะปกติตามเดิม
      bool? isConnected = await bluetooth.isConnected;
      ref.read(isPrinterConnectedProvider.notifier).state = isConnected ?? false;
    }

    // 4. Listener เดิม (เผื่อหลุดเอง)
    bluetooth.onStateChanged().listen((state) {
      if (mounted) {
        if (state == BlueThermalPrinter.CONNECTED) {
          ref.read(isPrinterConnectedProvider.notifier).state = true;
        } else if (state == BlueThermalPrinter.DISCONNECTED) {
          ref.read(isPrinterConnectedProvider.notifier).state = false;
        }
      }
    });
  }
  Future<void> _getDevices() async {
    try {
      List<BluetoothDevice> availableDevices = await bluetooth.getBondedDevices();
      setState(() {
        devices = availableDevices;
      });

      // [Fix] ป้องกัน Error กรณี Object ไม่ตรงกัน
      // เช็คว่าอุปกรณ์ที่เคยเลือกไว้ (ใน Provider) ยังมีอยู่ในรายการใหม่ไหม
      final currentSelected = ref.read(selectedPrinterProvider);
      if (currentSelected != null) {
        final found = devices.firstWhere(
          (d) => d.address == currentSelected.address, 
          orElse: () => currentSelected
        );
        // อัปเดต object ให้ตรงกับ list ปัจจุบัน
        if (devices.contains(found)) {
           ref.read(selectedPrinterProvider.notifier).state = found;
        }
      }

    } catch (e) {
      print("Error getting devices: $e");
    }
  }

  Future<void> _connectToPrinter() async {
    final selectedDevice = ref.read(selectedPrinterProvider);
    if (selectedDevice == null) return;

    try {
      // ถ้าสถานะเก่าบอกว่าต่ออยู่ ลอง Disconnect ก่อนเพื่อความชัวร์
      if (ref.read(isPrinterConnectedProvider)) {
        await bluetooth.disconnect();
      }
      
      await bluetooth.connect(selectedDevice);
      
      // อัปเดต Provider
      ref.read(isPrinterConnectedProvider.notifier).state = true;
      await preferences.savePrinter(selectedDevice.name ?? "", selectedDevice.address ?? "");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to ${selectedDevice.name}")),
      );
    } catch (e) {
      ref.read(isPrinterConnectedProvider.notifier).state = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect: $e")),
      );
    }
  }

  Future<void> _disconnectPrinter() async {
    await bluetooth.disconnect();
    ref.read(isPrinterConnectedProvider.notifier).state = false;
    await preferences.clearPrinter();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Printer Disconnected")),
    );
  }

  Future<void> _saveCodePage() async {
    final code = int.tryParse(_codePageController.text) ?? 255;
    await preferences.savePrinterCodePage(code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved Code Page: $code")),
      );
      // Hide keyboard
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _toggleImageMode(bool value) async {
    setState(() {
      _isImageMode = value;
    });
    await preferences.savePrinterImageMode(value);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = ref.watch(selectedPrinterProvider);
    final isConnected = ref.watch(isPrinterConnectedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Thermal Printer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ... (Icons, Status, Dropdown, Connect Buttons - same as before) ...
            Icon(Icons.print, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              "Printer Settings",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.cancel,
                  color: isConnected ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? 'Connected' : 'Not Connected',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<BluetoothDevice>(
              decoration: const InputDecoration(
                labelText: "Select Printer",
                border: OutlineInputBorder(),
              ),
              value: selectedDevice,
              items: devices.map((device) {
                return DropdownMenuItem(
                  value: device,
                  child: Text(device.name ?? "Unknown Device"),
                );
              }).toList(),
              onChanged: isConnected 
                  ? null 
                  : (device) {
                      ref.read(selectedPrinterProvider.notifier).state = device;
                    },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: isConnected ? null : _connectToPrinter,
                  icon: const Icon(Icons.link),
                  label: const Text("Connect"),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: !isConnected ? null : _disconnectPrinter,
                  icon: const Icon(Icons.link_off),
                  label: const Text("Disconnect"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            
            const SizedBox(height: 16),
            Text(
              "ตั้งค่าขั้นสูงสำหรับเครื่องพิมพ์",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // Code Page Input (Disable if Image Mode is ON to avoid confusion)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codePageController,
                    keyboardType: TextInputType.number,
                    enabled: !_isImageMode, // Disable when Image Mode is on
                    decoration: InputDecoration(
                      labelText: "รหัสภาษาไทย (e.g. 255, 22, 17)",
                      border: const OutlineInputBorder(),
                      helperText: _isImageMode 
                          ? "ไม่ได้ใช้งานในโหมดรูปภาพ" 
                          : "สำหรับโหมดข้อความ (Text Mode)",
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isImageMode ? null : _saveCodePage,
                  child: const Text("Save"),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              onPressed: (isConnected && !_isImageMode) 
                  ? () => PrintService().findThaiCodePage(context)
                  : null,
              icon: const Icon(Icons.flag),
              label: const Text("ทดสอบหาค่า Code Page ภาษาไทย"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            // [New] Image Mode Switch
            SwitchListTile(
              title: const Text("พิมพ์แบบรูปภาพ (Image Mode)"),
              subtitle: const Text("ใช้เมื่อภาษาไทยพิมพ์ไม่ออก หรือต้องการฟอนต์สวยงาม (พิมพ์ช้ากว่าเล็กน้อย)"),
              value: _isImageMode,
              onChanged: _toggleImageMode,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
             Card(
              color: _isImageMode ? Colors.white : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "ขนาดตัวอักษร (Font Size): ${_fontSize.toInt()}", 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isImageMode ? Colors.black : Colors.grey,
                          ),
                        ),
                        if (!_isImageMode)
                          const Text("(ใช้ได้เฉพาะโหมดรูปภาพ)", style: TextStyle(fontSize: 10, color: Colors.red)),
                      ],
                    ),
                    Slider(
                      value: _fontSize,
                      min: 14.0, 
                      max: 30.0, 
                      divisions: 16, 
                      label: _fontSize.round().toString(),
                      onChanged: _isImageMode 
                          ? (double value) {
                              setState(() {
                                _fontSize = value;
                              });
                            }
                          : null, 
                      onChangeEnd: _isImageMode 
                          ? (double value) {
                              preferences.setPrinterFontSize(value);
                            }
                          : null,
                    ),
                    Text(
                      "ปรับขนาดตัวอักษรสำหรับโหมดรูปภาพ (Image Mode)", 
                      style: TextStyle(
                        fontSize: 12, 
                        color: _isImageMode ? Colors.grey : Colors.grey.shade400
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isConnected 
                  ? () => PrintService().printReceipt(
                      context, 
                      [
                        // Creating dummy items for test
                        CartItem(
                          product: Product(
                            id: 999, 
                            description: "ทดสอบสินค้า A", 
                            sellPrice: "100.00", 
                            category: "", brand: "", model: "", costPrice: "", unit: "ชิ้น",
                          ),
                          quantity: 1, 
                          discountValue: 0.0
                        ),
                        CartItem(
                          product: Product(
                            id: 888, 
                            description: "ทดสอบสินค้า B", 
                            sellPrice: "50.00", 
                            category: "", brand: "", model: "", costPrice: "", unit: "อัน",
                          ),
                          quantity: 2, 
                          discountValue: 0.0
                        ),
                      ], 
                      customerName: "ลูกค้าทดสอบ (Mock)",
                      customerAddress: "123 ถ.สุขุมวิท กรุงเทพฯ",
                      customerPhone: "081-234-5678",
                      salespersonName: "พนักงานทดสอบ",
                      isCredit: true
                    )
                  : null, 
              icon: const Icon(Icons.receipt_long),
              label: const Text("Test Print Receipt (Full)"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}