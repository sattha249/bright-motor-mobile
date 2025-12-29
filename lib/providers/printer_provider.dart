import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// เก็บข้อมูลเครื่องพิมพ์ที่เลือกล่าสุด
final selectedPrinterProvider = StateProvider<BluetoothDevice?>((ref) => null);

// เก็บสถานะการเชื่อมต่อ (เพื่อเอาไปล็อค Dropdown)
final isPrinterConnectedProvider = StateProvider<bool>((ref) => false);