// lib/presentation/screens/add_product/view.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/catagory_model.dart';
import '../../../models/food_type_model.dart';
import '../../../ui_components/custom_textField.dart';
import '../../../ui_components/image_picker.dart';
import '../../../ui_components/image_picker_with_crop.dart';
import '../../../ui_components/timing_schedule_widget.dart';
import '../../../presentation/resources/colors.dart';
import '../../../presentation/resources/font.dart';
import '../homePage/sidebar/sidebar_drawer.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../../services/restaurant_info_service.dart';
import '../../../services/currency_service.dart';
import '../../resources/router/router.dart';
import 'package:collection/collection.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Character limits
  final int _nameMaxLength = 30;
  final int _descriptionMaxLength = 100;
  final int _tagsMaxLength = 100;
  final double _maxPrice = 9999.99;
  
  // Restaurant info state
  Map<String, String>? _restaurantInfo;
  bool _isRestaurantInfoLoaded = false;

  @override
  void initState() {
    super.initState();
    // REMOVED: Subscription check - handled by sidebar now
    _loadRestaurantInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      final info = await RestaurantInfoService.refreshRestaurantInfo();
      if (mounted) {
        setState(() {
          _restaurantInfo = info;
          _isRestaurantInfoLoaded = true;
        });
        debugPrint('🔄 AddProductPage: Loaded restaurant info - Name: ${info['name']}, Slogan: ${info['slogan']}, Image: ${info['imageUrl']}');
      }
    } catch (e) {
      debugPrint('Error loading restaurant info: $e');
    }
  }

  void _openSidebar() {
    _scaffoldKey.currentState?.openDrawer();
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
      child: BlocProvider(
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
                
                // Navigate to HomePage after showing success message
                Future.delayed(const Duration(seconds: 1), () {
                  Navigator.of(context).pushReplacementNamed('/home');
                });
              }
            }
          },
          builder: (context, state) {
            debugPrint('AddProductScreen: BlocConsumer builder state = \u001b[36m'+state.runtimeType.toString()+'\u001b[0m');
            if (state is AddProductFormState) {
              return Scaffold(
                key: _scaffoldKey,
                backgroundColor: ColorManager.background,
                drawer: SidebarDrawer(
                  activePage: 'addProduct',
                  restaurantName: _restaurantInfo?['name'] ?? 'Restaurant',
                  restaurantSlogan: _restaurantInfo?['slogan'] ?? 'Add new product',
                  restaurantImageUrl: _restaurantInfo?['imageUrl'],
                ),
                body: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: _openSidebar,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.menu_rounded,
                color: Colors.black87,
                size: 24.0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Add New Product',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, AddProductFormState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Required fields note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fields marked with * are required',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Product Name
          _buildFormLabel('Product Name *'),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Enter product name (required, upto 30 characters)',
            controller: _nameController,
            maxLength: _nameMaxLength,
            errorText: state.nameError,
            counterText: '${_nameController.text.length}/$_nameMaxLength',
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'^[0-9\s]+$')), // Deny only numbers and spaces
            ],
            onChanged: (value) {
              context.read<AddProductBloc>().add(ProductNameChangedEvent(value));
              // Also validate on change for immediate feedback
              context.read<AddProductBloc>().add(ValidateNameEvent(value));
            },
            onEditingComplete: () {
              context.read<AddProductBloc>().add(ValidateNameEvent(_nameController.text));
            },
          ),
          const SizedBox(height: 16),
          
          // Short Description
          _buildFormLabel('Short Description *'),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Enter product description (required, upto 100 characters, must contain at least one alphabet character)',
            controller: _descriptionController,
            maxLines: 3,
            maxLength: _descriptionMaxLength,
            errorText: state.descriptionError,
            counterText: '${_descriptionController.text.length}/$_descriptionMaxLength',
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'^[0-9\s]+$')), // Deny only numbers and spaces
            ],
            onChanged: (value) {
              context.read<AddProductBloc>().add(ProductDescriptionChangedEvent(value));
              // Also validate on change for immediate feedback
              context.read<AddProductBloc>().add(ValidateDescriptionEvent(value));
            },
            onEditingComplete: () {
              context.read<AddProductBloc>().add(ValidateDescriptionEvent(_descriptionController.text));
            },
          ),
          const SizedBox(height: 16),
          
          // Category
          _buildFormLabel('Category'),
          const SizedBox(height: 8),
          _buildCategoryDropdown(context, state),
          const SizedBox(height: 16),
          
          // Food Type
          _buildFormLabel('Food Type'),
          const SizedBox(height: 8),
          _buildFoodTypeDropdown(context, state),
          const SizedBox(height: 16),
          
          // Availability Timing
          _buildFormLabel('Availability Timing'),
          const SizedBox(height: 8),
          TimingScheduleWidget(
            timingSchedule: state.product.timingSchedule,
            timingEnabled: state.product.timingEnabled,
            timezone: state.product.timezone,
            timingError: state.timingError,
            onTimingEnabledChanged: (enabled) {
              context.read<AddProductBloc>().add(ToggleTimingEnabledEvent(enabled));
              // Trigger timing validation after toggle
              Future.delayed(const Duration(milliseconds: 100), () {
                context.read<AddProductBloc>().add(const ValidateTimingScheduleEvent());
              });
            },
            onDayScheduleChanged: (day, enabled, start, end) {
              context.read<AddProductBloc>().add(UpdateDayScheduleEvent(
                day: day,
                enabled: enabled,
                start: start,
                end: end,
              ));
              // Trigger timing validation after update
              Future.delayed(const Duration(milliseconds: 100), () {
                context.read<AddProductBloc>().add(const ValidateTimingScheduleEvent());
              });
            },
            onTimezoneChanged: (timezone) {
              context.read<AddProductBloc>().add(UpdateTimezoneEvent(timezone));
              // Trigger timing validation after timezone change
              Future.delayed(const Duration(milliseconds: 100), () {
                context.read<AddProductBloc>().add(const ValidateTimingScheduleEvent());
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Vegetarian toggle
          _buildToggleOption(
            context,
            'Vegetarian',
            state.product.codAllowed,
            (value) => context.read<AddProductBloc>().add(ToggleCodAllowedEvent(value)),
          ),
          
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
          ImagePickerWithCropWidget(
            selectedImage: state.product.image,
            onImageSelected: (file) {
              context.read<AddProductBloc>().add(ProductImageSelectedEvent(file));
            },
            title: 'Product Image',
            subtitle: 'Click to upload or drag and drop',
            maxSizeText: 'PNG, JPG up to 5MB',
            aspectRatio: 1.0, // Square aspect ratio for product images
            enableCrop: true,
          ),
          const SizedBox(height: 16),
          
          // Tags
          _buildFormLabel('Tags'),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Enter tags separated by commas',
            controller: _tagsController,
            maxLength: _tagsMaxLength,
            errorText: state.tagsError,
            counterText: '${_tagsController.text.length}/$_tagsMaxLength',
            onChanged: (value) {
              context.read<AddProductBloc>().add(ProductTagsChangedEvent(value));
              // Also validate on change for immediate feedback
              context.read<AddProductBloc>().add(ValidateTagsEvent(value));
            },
            onEditingComplete: () {
              context.read<AddProductBloc>().add(ValidateTagsEvent(_tagsController.text));
            },
          ),
          const SizedBox(height: 16),
          
          // Product Price
          _buildFormLabel('Product Price *'),
          const SizedBox(height: 8),
          _buildPriceField(context),
          if (state.priceError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 16),
              child: Text(
                state.priceError!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () {
                          // Validate all fields before submission
                          context.read<AddProductBloc>().add(const ValidateAllFieldsEvent());
                          if (_isFormValid(state)) {
                            context.read<AddProductBloc>().add(const SubmitProductEvent());
                          } else {
                            // Show error message for validation failures
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all required fields'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
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

  // Check if the entire form is valid
  bool _isFormValid(AddProductFormState state) {
    return state.nameError == null && 
           state.descriptionError == null && 
           state.priceError == null &&
           state.tagsError == null &&
           _nameController.text.isNotEmpty &&
           _descriptionController.text.isNotEmpty &&
           _priceController.text.isNotEmpty;
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
    final selectedCategory = state.categories.firstWhereOrNull(
      (category) => category.id == state.product.categoryId,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CategoryModel>(
          isExpanded: true,
          value: selectedCategory,
          hint: const Text('Select category'),
          items: state.categories.map((CategoryModel category) {
            return DropdownMenuItem<CategoryModel>(
              value: category,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (CategoryModel? newValue) {
            if (newValue != null) {
              context.read<AddProductBloc>().add(
                ProductCategoryChangedEvent(newValue.name, newValue.id),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildFoodTypeDropdown(BuildContext context, AddProductFormState state) {
    if (state.isLoadingFoodTypes) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading food types...'),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FoodTypeModel>(
          isExpanded: true,
          value: state.selectedFoodType,
          hint: const Text('Select food type'),
          items: state.foodTypes.map((FoodTypeModel foodType) {
            return DropdownMenuItem<FoodTypeModel>(
              value: foodType,
              child: Text(foodType.name),
            );
          }).toList(),
          onChanged: (FoodTypeModel? newValue) {
            if (newValue != null) {
              context.read<AddProductBloc>().add(
                FoodTypeChangedEvent(newValue),
              );
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
            child: CurrencyService.currencySymbolWidget(
              style: TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0.00 (required)',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final price = double.tryParse(value) ?? 0.0;
                context.read<AddProductBloc>().add(ProductPriceChangedEvent(price));
                // Also validate on change for immediate feedback
                context.read<AddProductBloc>().add(ValidatePriceEvent(value));
              },
              onEditingComplete: () {
                context.read<AddProductBloc>().add(ValidatePriceEvent(_priceController.text));
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