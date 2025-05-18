// lib/presentation/screens/add_product/view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../ui_components/custom_textField.dart';
import '../../../ui_components/image_picker.dart';
import '../../../ui_components/universal_widget/topbar.dart';
import '../../../presentation/resources/colors.dart';
import '../../../presentation/resources/font.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddProductBloc()..add(AddProductInitEvent()),
      child: BlocConsumer<AddProductBloc, AddProductState>(
        listener: (context, state) {
          if (state is AddProductFormState) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
            
            if (state.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product added successfully!')),
              );
              
              // Reset the form after showing success message
              Future.delayed(const Duration(seconds: 1), () {
                context.read<AddProductBloc>().add(const ResetFormEvent());
                _resetControllers();
              });
            }
          }
        },
        builder: (context, state) {
          if (state is AddProductFormState) {
            return Scaffold(
              backgroundColor: ColorManager.background,
              body: SafeArea(
                child: Column(
                  children: [
                    const AppBackHeader(title: 'Add New Product'),
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

  Widget _buildForm(BuildContext context, AddProductFormState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          _buildFormLabel('Product Name'),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Enter product name',
            controller: _nameController,
            onChanged: (value) {
              context.read<AddProductBloc>().add(ProductNameChangedEvent(value));
            },
          ),
          const SizedBox(height: 16),
          
          // Short Description
          _buildFormLabel('Short Description'),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Enter product description',
            controller: _descriptionController,
            maxLines: 3,
            onChanged: (value) {
              context.read<AddProductBloc>().add(ProductDescriptionChangedEvent(value));
            },
          ),
          const SizedBox(height: 16),
          
          // Category
          _buildFormLabel('Category'),
          const SizedBox(height: 8),
          _buildCategoryDropdown(context, state),
          const SizedBox(height: 16),
          
          _buildToggleOption(
            context,
            'Tax Included in Price',
            state.product.taxIncluded,
            (value) => context.read<AddProductBloc>().add(ToggleTaxIncludedEvent(value)),
          ),
          
          _buildToggleOption(
            context,
            'Is Cancellable',
            state.product.isCancellable,
            (value) => context.read<AddProductBloc>().add(ToggleCancellableEvent(value)),
          ),
          
          // Main Image
          _buildFormLabel('Main Image'),
          const SizedBox(height: 8),
          ImagePickerWidget(
            selectedImage: state.product.image,
            onImageSelected: (file) {
              context.read<AddProductBloc>().add(ProductImageSelectedEvent(file));
            },
            title: 'Product Image',
            subtitle: 'Click to upload or drag and drop',
            maxSizeText: 'PNG, JPG up to 5MB',
          ),
          const SizedBox(height: 16),
          
          // Tags
          _buildFormLabel('Tags'),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Enter tags separated by commas',
            controller: _tagsController,
            onChanged: (value) {
              context.read<AddProductBloc>().add(ProductTagsChangedEvent(value));
            },
          ),
          const SizedBox(height: 16),
          
          // Product Price
          _buildFormLabel('Product Price'),
          const SizedBox(height: 8),
          _buildPriceField(context),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => context.read<AddProductBloc>().add(const SubmitProductEvent()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCD6E32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add Product'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AddProductBloc>().add(const ResetFormEvent());
                    _resetControllers();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: FontSize.s16,
        fontWeight: FontWeightManager.medium,
        color: ColorManager.black,
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context, AddProductFormState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: state.product.category.isEmpty ? null : state.product.category,
          hint: const Text('Select category'),
          items: state.categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              context.read<AddProductBloc>().add(ProductCategoryChangedEvent(newValue));
            }
          },
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    BuildContext context,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.medium,
              color: ColorManager.black,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF5D5FEF),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 55,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
            child: const Text(
              '\$',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final price = double.tryParse(value) ?? 0.0;
                context.read<AddProductBloc>().add(ProductPriceChangedEvent(price));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _resetControllers() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _tagsController.clear();
  }
}