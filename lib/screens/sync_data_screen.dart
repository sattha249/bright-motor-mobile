import 'package:brightmotor_store/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Enum เพื่อจัดการสถานะหน้าจอ
enum SyncStatus { idle, loading, success, error }

class SyncDataScreen extends ConsumerStatefulWidget {
  const SyncDataScreen({super.key});

  @override
  ConsumerState<SyncDataScreen> createState() => _SyncDataScreenState();
}

class _SyncDataScreenState extends ConsumerState<SyncDataScreen> {
  // เริ่มต้นเป็น idle
  SyncStatus _status = SyncStatus.idle; 

  Future<void> _startSync() async {
    setState(() {
      _status = SyncStatus.loading; // เริ่มหมุน
    });

    // เรียก Service
    final isSuccess = await ref.read(syncServiceProvider).syncData();

    // อัปเดตผลลัพธ์
    setState(() {
      _status = isSuccess ? SyncStatus.success : SyncStatus.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('อัพเดทข้อมูล')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- ส่วนแสดงไอคอนตามสถานะ ---
            _buildStatusIcon(),
            
            const SizedBox(height: 24),
            
            // --- ข้อความสถานะ ---
            Text(
              _getStatusMessage(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 32),

            // --- ปุ่มกด ---
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: _status == SyncStatus.loading ? null : _startSync, // ปิดปุ่มตอนโหลด
                child: _status == SyncStatus.loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.blue),
                      )
                    : const Text('เริ่มการ Sync ข้อมูล'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันเลือก Icon ตามสถานะ
  Widget _buildStatusIcon() {
    switch (_status) {
      case SyncStatus.loading:
        return const SizedBox(
          height: 100,
          width: 100,
          child: CircularProgressIndicator(strokeWidth: 8),
        );
      case SyncStatus.success:
        return const Icon(Icons.check_circle, size: 100, color: Colors.green);
      case SyncStatus.error:
        return const Icon(Icons.error, size: 100, color: Colors.red);
      case SyncStatus.idle:
      default:
        return const Icon(Icons.cloud_sync, size: 100, color: Colors.blue);
    }
  }

  // ฟังก์ชันเลือกข้อความ
  String _getStatusMessage() {
    switch (_status) {
      case SyncStatus.loading:
        return 'กำลังเชื่อมต่อ Server...';
      case SyncStatus.success:
        return 'อัพเดทข้อมูลสำเร็จ!';
      case SyncStatus.error:
        return 'การเชื่อมต่อล้มเหลว';
      case SyncStatus.idle:
      default:
        return 'กดปุ่มเพื่อเริ่มอัพเดท';
    }
  }
}