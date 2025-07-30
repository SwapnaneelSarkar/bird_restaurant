// lib/presentation/screens/add_product/view.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/catagory_model.dart';
import '../../../models/food_type_model.dart';
import '../../../ui_components/custom_textField.dart';
import '../../../ui_components/image_picker.dart';
import '../../../ui_components/universal_widget/topbar.dart';
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
  
  // Validation error text
  String? _nameError;
  String? _descriptionError;
  String? _priceError;
  String? _tagsError;

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
          // Product Name
          _buildFormLabel('Product Name'),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Enter product name (upto 30 characters)',
            controller: _nameController,
            maxLength: _nameMaxLength,
            errorText: _nameError,
            counterText: '${_nameController.text.length}/$_nameMaxLength',
            onChanged: (value) {
              setState(() {
                if (value.isEmpty) {
                  _nameError = 'Product name is required';
                } else if (value.length > _nameMaxLength) {
                  _nameError = 'Maximum $_nameMaxLength characters allowed';
                } else {
                  _nameError = null;
                }
              });
              context.read<AddProductBloc>().add(ProductNameChangedEvent(value));
            },
          ),
          const SizedBox(height: 16),
          
          // Short Description
          _buildFormLabel('Short Description'),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Enter product description (upto 100 characters)',
            controller: _descriptionController,
            maxLines: 3,
            maxLength: _descriptionMaxLength,
            errorText: _descriptionError,
            counterText: '${_descriptionController.text.length}/$_descriptionMaxLength',
            onChanged: (value) {
              setState(() {
                if (value.length > _descriptionMaxLength) {
                  _descriptionError = 'Maximum $_descriptionMaxLength characters allowed';
                } else {
                  _descriptionError = null;
                }
              });
              context.read<AddProductBloc>().add(ProductDescriptionChangedEvent(value));
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
            maxLength: _tagsMaxLength,
            errorText: _tagsError,
            counterText: '${_tagsController.text.length}/$_tagsMaxLength',
            onChanged: (value) {
              setState(() {
                if (value.length > _tagsMaxLength) {
                  _tagsError = 'Maximum $_tagsMaxLength characters allowed';
                } else {
                  _tagsError = null;
                }
              });
              context.read<AddProductBloc>().add(ProductTagsChangedEvent(value));
            },
          ),
          const SizedBox(height: 16),
          
          // Product Price
          _buildFormLabel('Product Price'),
          const SizedBox(height: 8),
          _buildPriceField(context),
          if (_priceError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 16),
              child: Text(
                _priceError!,
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
                  onPressed: state.isSubmitting || !_isFormValid()
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

  // Check if the entire form is valid
  bool _isFormValid() {
    return _nameError == null && 
           _descriptionError == null && 
           _priceError == null &&
           _tagsError == null &&
           _nameController.text.isNotEmpty;
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
                hintText: '0.00',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final price = double.tryParse(value) ?? 0.0;
                setState(() {
                  if (value.isEmpty) {
                    _priceError = 'Price is required';
                  } else if (price <= 0) {
                    _priceError = 'Price must be greater than 0';
                  } else if (price > _maxPrice) {
                    _priceError = 'Price cannot exceed \$$_maxPrice';
                  } else {
                    _priceError = null;
                  }
                });
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
    setState(() {
      _nameError = null;
      _descriptionError = null;
      _priceError = null;
      _tagsError = null;
    });
  }
}