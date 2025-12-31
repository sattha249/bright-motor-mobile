import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerServiceImpl();
  bool _isSaving = false;

  // Controllers
  final _customerNoController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postCodeController = TextEditingController();

  @override
  void dispose() {
    _customerNoController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _telController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _postCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newCustomer = Customer(
        customerNo: _customerNoController.text,
        name: _nameController.text,
        email: _emailController.text,
        tel: _telController.text,
        address: _addressController.text,
        district: _districtController.text,
        province: _provinceController.text,
        postCode: _postCodeController.text,
        country: 'ไทย',
      );

      await _customerService.createCustomer(newCustomer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลลูกค้าเรียบร้อย')),
        );
        Navigator.pop(context, true); // ส่งค่า true กลับไปเพื่อบอกให้รีเฟรชหน้า List
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มลูกค้าใหม่')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField("รหัสลูกค้า *", _customerNoController, required: true),
            _buildTextField("ชื่อ-นามสกุล *", _nameController, required: true),
            _buildTextField("เบอร์โทรศัพท์ *", _telController, required: true, inputType: TextInputType.phone),
            _buildTextField("อีเมล", _emailController, inputType: TextInputType.emailAddress),
            const Divider(height: 30),
            _buildTextField("ที่อยู่", _addressController),
            Row(
              children: [
                Expanded(child: _buildTextField("อำเภอ/เขต", _districtController)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField("จังหวัด", _provinceController)),
              ],
            ),
            _buildTextField("รหัสไปรษณีย์", _postCodeController, inputType: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCustomer,
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, TextInputType? inputType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: required 
          ? (value) => (value == null || value.isEmpty) ? 'กรุณากรอกข้อมูล' : null
          : null,
      ),
    );
  }
}