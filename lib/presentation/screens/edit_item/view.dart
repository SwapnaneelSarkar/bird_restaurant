// lib/presentation/screens/edit_product/edit_product_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/restaurant_menu_model.dart';
import '../../../ui_components/custom_button_slim.dart';
import '../../../ui_components/custom_textField.dart';
import '../../../ui_components/image_picker.dart';

import '../../../presentation/resources/colors.dart';
import '../../../ui_components/universal_widget/topbar.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class EditProductView extends StatefulWidget {
  final MenuItem menuItem;

  const EditProductView({
    Key? key,
    required this.menuItem,
  }) : super(key: key);

  @override
  State<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<EditProductView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditProductBloc()..add(EditProductInitEvent(widget.menuItem)),
      child: BlocConsumer<EditProductBloc, EditProductState>(
        listener: (context, state) {
          if (state is EditProductFormState) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
            
            if (state.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product updated successfully!')),
              );
              
              // Go back to previous screen after showing success message
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.of(context).pop(true); // Return true to indicate success
              });
            }
          }
        },
        builder: (context, state) {
          if (state is EditProductFormState) {
            // Initialize controllers if values changed
            if (_nameController.text != state.name) {
              _nameController.text = state.name;
            }
            if (_descriptionController.text != state.description) {
              _descriptionController.text = state.description;
            }
            if (_priceController.text != state.price) {
              _priceController.text = state.price;
            }
            
            return Scaffold(
              backgroundColor: Colors.grey[100],
              body: SafeArea(
                child: Column(
                  children: [
                    const AppBackHeader(title: 'Edit Menu Item'),
                    Expanded(
                      child: _buildForm(context, state),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, EditProductFormState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Image
          // lib/presentation/screens/edit_product/edit_product_view.dart
// Just fix the ImagePickerWidget part in the _buildForm method

// Main Image
Text(
  'Main Image',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ColorManager.black,
  ),
),
const SizedBox(height: 8),
Stack(
  children: [
    // Show existing image if available
    if (state.imageUrl != null && state.image == null)
      Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(state.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Overlay to make it clear you can change it
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tap to change image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    
    // Standard image picker for new uploads
    ImagePickerWidget(
      selectedImage: state.image,
      onImageSelected: (file) {
        context.read<EditProductBloc>().add(ProductImageSelectedEvent(file));
      },
      title: state.imageUrl != null && state.image == null ? '' : 'Product Image',
      subtitle: state.imageUrl != null && state.image == null ? '' : 'Click to upload or drag and drop',
      maxSizeText: state.imageUrl != null && state.image == null ? '' : 'PNG, JPG up to 5MB',
    ),
  ],
),
const SizedBox(height: 20),
          
          // Product Name
          CustomTextField(
            label: 'Product Name',
            hintText: 'Enter product name',
            controller: _nameController,
            onChanged: (value) {
              context.read<EditProductBloc>().add(ProductNameChangedEvent(value));
            },
          ),
          const SizedBox(height: 16),
          
          // Product Price
          CustomTextField(
            label: 'Price',
            hintText: 'Enter price',
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              context.read<EditProductBloc>().add(ProductPriceChangedEvent(value));
            },
          ),
          const SizedBox(height: 16),
          
          // Category
          Text(
            'Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ColorManager.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorManager.grey),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: state.category.isEmpty ? null : state.category,
                hint: const Text('Select category'),
                items: state.categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category.toLowerCase().replaceAll(' ', '-'),
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    context.read<EditProductBloc>().add(ProductCategoryChangedEvent(newValue));
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          CustomTextField(
            label: 'Description',
            hintText: 'Enter product description',
            controller: _descriptionController,
            maxLines: 3,
            onChanged: (value) {
              context.read<EditProductBloc>().add(ProductDescriptionChangedEvent(value));
            },
          ),
          const SizedBox(height: 16),
          
          // Is Veg Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorManager.grey),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vegetarian Item',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ColorManager.black,
                  ),
                ),
                Switch(
                  value: state.isVeg,
                  onChanged: (value) {
                    context.read<EditProductBloc>().add(ProductIsVegChangedEvent(value));
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF4CAF50),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey[300],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Submit Button
          NextButton(
            label: state.isSubmitting ? 'Updating...' : 'Update Menu Item',
            onPressed: state.isSubmitting
                ? null
                : () => context.read<EditProductBloc>().add(const SubmitEditProductEvent()),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}