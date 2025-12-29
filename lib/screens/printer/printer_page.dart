import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:brightmotor_store/printer/print_service.dart';
import 'package:brightmotor_store/providers/printer_provider.dart'; // อย่าลืม import provider ที่สร้าง
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PrinterPage extends ConsumerStatefulWidget {
  const PrinterPage({super.key});

  @override
  _PrinterPageState createState() => _PrinterPageState();
}

class _PrinterPageState extends ConsumerState<PrinterPage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> devices = [];

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    // 1. ดึงรายชื่ออุปกรณ์
    await _getDevices();
    
    // 2. เช็คสถานะจริงจาก Hardware ว่าต่ออยู่ไหม
    bool? isConnected = await bluetooth.isConnected;
    
    // อัปเดตสถานะลง Provider
    ref.read(isPrinterConnectedProvider.notifier).state = isConnected ?? false;

    // 3. ฟังสถานะการเชื่อมต่อ (เผื่อหลุดเอง)
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Printer Disconnected")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ดึงค่าจาก Provider
    final selectedDevice = ref.watch(selectedPrinterProvider);
    final isConnected = ref.watch(isPrinterConnectedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Thermal Printer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.print, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              "Printer Settings",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Status Indicator
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
            
            // Dropdown เลือก Printer
            DropdownButtonFormField<BluetoothDevice>(
              decoration: const InputDecoration(
                labelText: "Select Printer",
                border: OutlineInputBorder(),
              ),
              value: selectedDevice,
              // [Logic 1 & 2] จำค่าจาก Provider และ ล็อคถ้า Connected
              items: devices.map((device) {
                return DropdownMenuItem(
                  value: device,
                  child: Text(device.name ?? "Unknown Device"),
                );
              }).toList(),
              onChanged: isConnected 
                  ? null // ถ้าต่ออยู่ ให้เป็น null (Disabled/Locked)
                  : (device) {
                      // ถ้ายังไม่ต่อ ให้เลือกได้ และอัปเดต Provider
                      ref.read(selectedPrinterProvider.notifier).state = device;
                    },
            ),
            
            const SizedBox(height: 16),
            
            // ปุ่ม Connect / Disconnect
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  // ถ้าต่ออยู่ ห้ามกด Connect ซ้ำ
                  onPressed: isConnected ? null : _connectToPrinter,
                  icon: const Icon(Icons.link),
                  label: const Text("Connect"),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  // ถ้ายังไม่ต่อ ห้ามกด Disconnect
                  onPressed: !isConnected ? null : _disconnectPrinter,
                  icon: const Icon(Icons.link_off),
                  label: const Text("Disconnect"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white, // สีตัวหนังสือ
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            Divider(),
            const SizedBox(height: 16),
            
            // ปุ่ม Test Print
            ElevatedButton.icon(
              onPressed: isConnected 
                  ? () => PrintService().testPrinter() 
                  : null, // ถ้าไม่ต่อ กดไม่ได้
              icon: const Icon(Icons.receipt_long),
              label: const Text("Test Print Receipt"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}