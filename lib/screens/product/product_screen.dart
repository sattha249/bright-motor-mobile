

import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/screens/category_screen.dart';
import 'package:flutter/material.dart';

class ProductScreen extends StatelessWidget {

  final Customer customer;

  const ProductScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return CategoryScreen(customer: customer);
  }
}
