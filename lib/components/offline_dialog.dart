import 'package:flutter/material.dart';

class OfflineNoticeDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onAcknowledge;
  final bool isBlocked;

  const OfflineNoticeDialog({
    super.key,
    this.title = 'แจ้งเตือนโหมดออฟไลน์',
    required this.message,
    this.onAcknowledge,
    this.isBlocked = false,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'แจ้งเตือนโหมดออฟไลน์',
    required String message,
    VoidCallback? onAcknowledge,
    bool isBlocked = false,
  }) async {
    return showAdaptiveDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OfflineNoticeDialog(
        title: title,
        message: message,
        onAcknowledge: onAcknowledge,
        isBlocked: isBlocked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = isBlocked ? Colors.red : Colors.orange;
    final iconData = isBlocked ? Icons.cloud_off : Icons.wifi_off;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(iconData, color: iconColor, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isBlocked ? Colors.red.shade900 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isBlocked ? Colors.red.shade50 : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isBlocked ? Colors.red.shade200 : Colors.amber.shade300,
              ),
            ),
            child: Text(
              isBlocked
                  ? '⚠️ ฟีเจอร์นี้ต้องใช้งานตอนเชื่อมต่อเซิร์ฟเวอร์เท่านั้น'
                  : 'ℹ️ ระบบจะบันทึกข้อมูลไว้ในเครื่อง และรอซิงค์เมื่อกลับมาออนไลน์',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isBlocked ? Colors.red.shade800 : Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (!isBlocked && onAcknowledge != null) {
                onAcknowledge!();
              }
            },
            child: const Text(
              'รับทราบ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
