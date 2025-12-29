import 'dart:typed_data';

class Tis620Helper {
  // แปลง String เป็น Bytes TIS-620
  static List<int> toTis620(String text) {
    List<int> buffer = [];
    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);
      if (charCode >= 0x0E01 && charCode <= 0x0E5B) {
        // ไทย: ลบส่วนต่าง Unicode ให้เหลือ byte เดียว (เริ่มที่ 0xA0)
        buffer.add(charCode - 0x0E00 + 0xA0);
      } else {
        // อังกฤษ/ตัวเลข: ใช้ค่าเดิม
        buffer.add(charCode);
      }
    }
    return buffer;
  }

  // รวมคำสั่ง ESC/POS สำหรับจัดหน้า + ตัวหนา + แปลงภาษา + ขึ้นบรรทัดใหม่
  static Uint8List text(String text, {bool isBold = false, int align = 0}) {
    // Command: ESC a n (Align: 0=Left, 1=Center, 2=Right)
    List<int> bytes = [0x1B, 0x61, align];

    // Command: ESC ! n (Bold) หรือ ESC E n
    if (isBold) {
      bytes.addAll([0x1B, 0x45, 0x01]); // Bold On
    } else {
      bytes.addAll([0x1B, 0x45, 0x00]); // Bold Off
    }

    // แปลงข้อความเป็น TIS-620
    bytes.addAll(toTis620(text));
    
    // ขึ้นบรรทัดใหม่ (Line Feed)
    bytes.add(0x0A); 

    return Uint8List.fromList(bytes);
  }
}