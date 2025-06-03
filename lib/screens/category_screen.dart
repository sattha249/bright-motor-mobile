import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  Map<String, List<dynamic>> groupedData = {};
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    loadJson();
  }

  Future<void> loadJson() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/grouped_data.json');
      final List<dynamic> rawList = json.decode(jsonStr);


      setState(() {
        groupedData = {
          for (var item in rawList)
            if (item['category'] != null && item['items'] != null)
              item['category'].toString(): item['items'] as List<dynamic>
          
        };
      });
    } catch (e) {
      debugPrint('Error loading JSON: $e');
      // Show a snackbar with the error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading data. Please make sure the JSON file exists.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สินค้า'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: groupedData.keys.map((category) {
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.blue : null,
                      foregroundColor: isSelected ? Colors.white : null,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: Text(category),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          // Item List
          Expanded(
            child: selectedCategory == null
                ? const Center(child: Text('กรุณาเลือกหมวดหมู่'))
                : ListView.builder(
                    itemCount: groupedData[selectedCategory]?.length ?? 0,
                    itemBuilder: (context, index) {
                      final item = groupedData[selectedCategory]![index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(item['รายละเอียด'] ?? '-'),
                          subtitle: Text(item['ยี่ห้อ'] ?? ''),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(item['รายการ'] ?? 'รายละเอียด'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('รายละเอียด: ${item['รายละเอียด'] ?? '-'}'),
                                    Text('ยี่ห้อ: ${item['ยี่ห้อ'] ?? '-'}'),
                                    Text('รุ่น.1: ${item['รุ่น.1'] ?? '-'}'),
                                    Text('หน่วยนับ: ${item['หน่วยนับ'] ?? '-'}'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('ปิด'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 