import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:brightmotor_store/printer/print_service.dart';
import 'package:brightmotor_store/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PrinterPage extends ConsumerStatefulWidget {
  const PrinterPage({super.key});

  @override
  _PrinterPageState createState() => _PrinterPageState();
}

class _PrinterPageState extends ConsumerState<PrinterPage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _getDevices();
    _checkConnection();
  }

  Future<void> _getDevices() async {
    try {
      List<BluetoothDevice> availableDevices =
          await bluetooth.getBondedDevices();
      setState(() {
        devices = availableDevices;
      });
    } catch (e) {
      print("Error getting devices: $e");
    }
  }

  Future<void> _checkConnection() async {
    bool connected = await bluetooth.isConnected ?? false;
    setState(() {
      isConnected = connected;
    });
  }

  Future<void> _connectToPrinter() async {
    if (selectedDevice == null) return;
    try {
      await bluetooth.connect(selectedDevice!);
      setState(() {
        isConnected = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to [200m${selectedDevice!.name}[0m")),
      );
    } catch (e) {
      setState(() {
        isConnected = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to connect: $e")));
    }
  }

  Future<void> _disconnectPrinter() async {
    await bluetooth.disconnect();
    setState(() {
      isConnected = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Printer Disconnected")));
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: (device) => setState(() => selectedDevice = device),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _connectToPrinter,
                  icon: const Icon(Icons.link),
                  label: const Text("Connect"),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _disconnectPrinter,
                  icon: const Icon(Icons.link_off),
                  label: const Text("Disconnect"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Divider(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                PrintService().testPrinter();
              },
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
