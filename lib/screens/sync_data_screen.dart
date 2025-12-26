import 'package:flutter/material.dart';

class SyncDataScreen extends StatelessWidget {
  const SyncDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('อัพเดทข้อมูล')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sync, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: ใส่ Logic การ Sync ข้อมูลที่นี่
              },
              child: const Text('เริ่มการ Sync ข้อมูล'),
            ),
          ],
        ),
      ),
    );
  }
}