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

  @override
  void initState() {
    super.initState();
    _getDevices();
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

  Future<void> _connectToPrinter() async {
    if (selectedDevice == null) return;
    try {
      await bluetooth.connect(selectedDevice!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to ${selectedDevice!.name}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to connect: $e")));
    }
  }

  Future<void> _disconnectPrinter() async {
    await bluetooth.disconnect();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Printer Disconnected")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thermal Printer")),
      body: Column(
        children: [
          DropdownButton<BluetoothDevice>(
            hint: Text("Select Printer"),
            value: selectedDevice,
            onChanged: (device) => setState(() => selectedDevice = device),
            items:
                devices.map((device) {
                  return DropdownMenuItem(
                    value: device,
                    child: Text(device.name ?? "Unknown Device"),
                  );
                }).toList(),
          ),
          ElevatedButton(onPressed: _connectToPrinter, child: Text("Connect")),
          ElevatedButton(
            onPressed: _disconnectPrinter,
            child: Text("Disconnect"),
          ),
          ElevatedButton(
            onPressed: () {
              PrintService().testPrinter();
            },
            child: Text("Test Print Receipt"),
          ),
        ],
      ),
    );
  }
}
