import 'package:flutter/material.dart';

class PreOrderScreen extends StatelessWidget {
  const PreOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('คำสั่งซื้อล่วงหน้า')),
      body: const Center(child: Text('รายการ Pre-Order ทั้งหมด')),
    );
  }
}