import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  final bool isEditing;
  final String? productId;
  final Map<String, dynamic>? existingData;

  const AddProductScreen({
    super.key,
    this.isEditing = false,
    this.productId,
    this.existingData,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  String selectedType = 'Drinks';
  String selectedStatus = 'Available';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingData != null) {
      nameController.text = widget.existingData!['name'] ?? '';
      priceController.text = widget.existingData!['price'].toString();
      selectedType = widget.existingData!['type'] ?? 'Drinks';
      selectedStatus = widget.existingData!['status'] ?? 'Available';
    }
  }

  Future<void> addOrUpdateProduct() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => isLoading = true);

    final productData = {
      'name': nameController.text.trim(),
      'price': double.parse(priceController.text.trim()),
      'type': selectedType,
      'status': selectedStatus,
      'created_at':
          widget.isEditing && widget.existingData?['created_at'] != null
              ? widget.existingData!['created_at']
              : Timestamp.now(),
    };

    try {
      if (widget.isEditing && widget.productId != null) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .update(productData);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product updated!')));
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('products')
            .add(productData);
        print("Product added with ID: ${doc.id}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product added!')));
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedType,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedType = value;
                  });
                }
              },
              items: const [
                DropdownMenuItem(value: 'Drinks', child: Text('Drinks')),
                DropdownMenuItem(value: 'Snacks', child: Text('Snacks')),
                DropdownMenuItem(value: 'Meals', child: Text('Meals')),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedStatus = value;
                  });
                }
              },
              items: const [
                DropdownMenuItem(value: 'Available', child: Text('Available')),
                DropdownMenuItem(
                  value: 'Unavailable',
                  child: Text('Unavailable'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: addOrUpdateProduct,
                  child: Text(isEditing ? 'Update Product' : 'Add Product'),
                ),
          ],
        ),
      ),
    );
  }
}
