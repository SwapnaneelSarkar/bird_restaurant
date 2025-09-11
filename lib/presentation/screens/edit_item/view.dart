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
import '../../../ui_components/image_picker_with_crop.dart';
import '../../../ui_components/timing_schedule_widget.dart';
import '../../../presentation/resources/colors.dart';
import '../../../ui_components/universal_widget/topbar.dart';
import '../../../presentation/resources/router/router.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../../models/catagory_model.dart';
import '../../../models/food_type_model.dart';

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

  late EditProductBloc _editProductBloc;

  @override
  void initState() {
    super.initState();
    _editProductBloc = EditProductBloc();
    // Initialize the bloc after the widget is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editProductBloc.add(EditProductInitEvent(widget.menuItem));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _editProductBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.homePage,
          (route) => false,
        );
        return false;
      },
      child: BlocProvider.value(
        value: _editProductBloc,
        child: BlocConsumer<EditProductBloc, EditProductState>(
        listener: (context, state) {
          if (state is EditProductFormState) {
            if (state.errorMessage != null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
            
            if (state.isSuccess) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product updated successfully!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // Go back to previous screen after showing success message
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(true); // Return true to indicate success
                  }
                });
              }
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
              ImagePickerWithCropWidget(
                selectedImage: state.image,
                onImageSelected: (file) {
                  if (mounted) {
                    context.read<EditProductBloc>().add(ProductImageSelectedEvent(file));
                  }
                },
                title: state.imageUrl != null && state.image == null ? '' : 'Product Image',
                subtitle: state.imageUrl != null && state.image == null ? '' : 'Click to upload or drag and drop',
                maxSizeText: state.imageUrl != null && state.image == null ? '' : 'PNG, JPG up to 5MB',
                aspectRatio: 1.0, // Square aspect ratio for product images
                enableCrop: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Product Name
          CustomTextField(
            label: 'Product Name',
            hintText: 'Enter product name',
            controller: _nameController,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'^[0-9\s]+$')), // Deny only numbers and spaces
            ],
            onChanged: (value) {
              if (mounted) {
                context.read<EditProductBloc>().add(ProductNameChangedEvent(value));
              }
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
              if (mounted) {
                context.read<EditProductBloc>().add(ProductPriceChangedEvent(value));
              }
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
          Builder(
            builder: (context) {
              // Build a list that always includes the current categoryId
              final List<CategoryModel> allCategories = List<CategoryModel>.from(state.categories);
              final String? currentCategoryId = state.categoryId;
              debugPrint('Dropdown: state.categories = ' + state.categories.map((c) => '[id: ' + c.id + ', name: ' + c.name + ']').toList().toString());
              debugPrint('Dropdown: currentCategoryId = $currentCategoryId');
              if (currentCategoryId != null &&
                  currentCategoryId.isNotEmpty &&
                  !allCategories.any((cat) => cat.id == currentCategoryId)) {
                debugPrint('Dropdown: Adding unknown category for id $currentCategoryId');
                allCategories.add(CategoryModel(
                  id: currentCategoryId,
                  name: 'Unknown (id: $currentCategoryId)',
                ));
              }
              debugPrint('Dropdown: allCategories = ' + allCategories.map((c) => '[id: ' + c.id + ', name: ' + c.name + ']').toList().toString());
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ColorManager.grey),
                ),
                child: allCategories.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Loading categories...'),
                          ],
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: (currentCategoryId != null && currentCategoryId.isNotEmpty) ? currentCategoryId : null,
                          hint: const Text('Select category'),
                          items: allCategories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (String? newId) {
                            if (newId != null && mounted) {
                              final selected = allCategories.firstWhere((cat) => cat.id == newId);
                              debugPrint('Dropdown: User selected id $newId, name ${selected.name}');
                              context.read<EditProductBloc>().add(ProductCategoryChangedEvent(selected.name, selected.id));
                            }
                          },
                        ),
                      ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Food Type - Commented out as not supported by API
          // Text(
          //   'Food Type',
          //   style: TextStyle(
          //     fontSize: 16,
          //     fontWeight: FontWeight.w500,
          //     color: ColorManager.black,
          //   ),
          // ),
          // const SizedBox(height: 8),
          // _buildFoodTypeDropdown(context, state),
          // const SizedBox(height: 16),
          
          // Timing Schedule
          Text(
            'Availability Timing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ColorManager.black,
            ),
          ),
          const SizedBox(height: 8),
          TimingScheduleWidget(
            timingSchedule: state.timingSchedule,
            timingEnabled: state.timingEnabled,
            timezone: state.timezone,
            timingError: state.timingError,
            onTimingEnabledChanged: (enabled) {
              if (mounted) {
                context.read<EditProductBloc>().add(ToggleTimingEnabledEvent(enabled));
                // Trigger timing validation after toggle
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    context.read<EditProductBloc>().add(const ValidateTimingScheduleEvent());
                  }
                });
              }
            },
            onDayScheduleChanged: (day, enabled, start, end) {
              if (mounted) {
                context.read<EditProductBloc>().add(UpdateDayScheduleEvent(
                  day: day,
                  enabled: enabled,
                  start: start,
                  end: end,
                ));
                // Trigger timing validation after update
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    context.read<EditProductBloc>().add(const ValidateTimingScheduleEvent());
                  }
                });
              }
            },
            onTimezoneChanged: (timezone) {
              if (mounted) {
                context.read<EditProductBloc>().add(UpdateTimezoneEvent(timezone));
                // Trigger timing validation after timezone change
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    context.read<EditProductBloc>().add(const ValidateTimingScheduleEvent());
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Description
          CustomTextField(
            label: 'Description',
            hintText: 'Enter product description (must contain at least one alphabet character)',
            controller: _descriptionController,
            maxLines: 3,
            errorText: state.descriptionError,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'^[0-9\s]+$')), // Deny only numbers and spaces
            ],
            onChanged: (value) {
              if (mounted) {
                context.read<EditProductBloc>().add(ProductDescriptionChangedEvent(value));
                // Also validate on change for immediate feedback
                context.read<EditProductBloc>().add(ValidateDescriptionEvent(value));
              }
            },
            onEditingComplete: () {
              context.read<EditProductBloc>().add(ValidateDescriptionEvent(_descriptionController.text));
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
                    if (mounted) {
                      context.read<EditProductBloc>().add(ProductIsVegChangedEvent(value));
                    }
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
            onPressed: (state.isSubmitting || state.name.isEmpty || state.categoryId == null || state.categoryId!.isEmpty || state.price.isEmpty || state.descriptionError != null)
                ? null
                : () {
                    if (mounted) {
                      context.read<EditProductBloc>().add(const SubmitEditProductEvent());
                    }
                  },
          ),
          
          // Show retry info if there's an error
          if (state.errorMessage != null && state.errorMessage!.contains('timeout'))
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Network issue detected. The app will automatically retry.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Widget _buildFoodTypeDropdown(BuildContext context, EditProductFormState state) {
  //   // Commented out as food type is not supported by the API
  //   return Container();
  // }
}