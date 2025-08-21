import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/catagory_model.dart';
import '../../../models/subcategory_model.dart';
import '../../../models/product_selection_model.dart';
import '../../../ui_components/custom_textField.dart';
import '../../../presentation/resources/colors.dart';
import '../../../presentation/resources/font.dart';
import '../homePage/sidebar/sidebar_drawer.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../../services/restaurant_info_service.dart';
import '../../../services/currency_service.dart';
import '../../resources/router/router.dart';

class UpdateProductFromCatalogScreen extends StatefulWidget {
  const UpdateProductFromCatalogScreen({Key? key}) : super(key: key);

  @override
  State<UpdateProductFromCatalogScreen> createState() => _UpdateProductFromCatalogScreenState();
}

class _UpdateProductFromCatalogScreenState extends State<UpdateProductFromCatalogScreen> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Character limits
  final double _maxPrice = 9999.99;
  
  // Restaurant info state
  Map<String, String>? _restaurantInfo;
  bool _isRestaurantInfoLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();
    _quantityController.text = '1';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
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
        debugPrint('🔄 UpdateProductFromCatalogPage: Loaded restaurant info - Name: ${info['name']}, Slogan: ${info['slogan']}, Image: ${info['imageUrl']}');
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
        create: (context) => UpdateProductFromCatalogBloc()..add(const UpdateProductFromCatalogInitEvent()),
        child: BlocConsumer<UpdateProductFromCatalogBloc, UpdateProductFromCatalogState>(
          listener: (context, state) {
            if (state is UpdateProductFromCatalogFormState) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!)),
                );
              }
              
              if (state.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product updated successfully!')),
                );
                
                // Navigate to HomePage after showing success message
                Future.delayed(const Duration(seconds: 1), () {
                  Navigator.of(context).pushReplacementNamed('/home');
                });
              }
            }
          },
          builder: (context, state) {
            debugPrint('UpdateProductFromCatalogScreen: BlocConsumer builder state = \u001b[36m'+state.runtimeType.toString()+'\u001b[0m');
            if (state is UpdateProductFromCatalogFormState) {
              return Scaffold(
                key: _scaffoldKey,
                backgroundColor: ColorManager.background,
                drawer: SidebarDrawer(
                  activePage: 'updateProductFromCatalog',
                  restaurantName: _restaurantInfo?['name'] ?? 'Restaurant',
                  restaurantSlogan: _restaurantInfo?['slogan'] ?? 'Update product from catalog',
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
            'Update Product From Catalog',
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

  Widget _buildForm(BuildContext context, UpdateProductFromCatalogFormState state) {
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
                    'Select a product from the catalog and update its price and quantity',
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
          
          // Category Selection
          _buildFormLabel('Category *'),
          const SizedBox(height: 8),
          _buildCategoryDropdown(context, state),
          const SizedBox(height: 16),
          
          // Subcategory Selection
          if (state.selectedCategory != null) ...[
            _buildFormLabel('Subcategory *'),
            const SizedBox(height: 8),
            _buildSubcategoryDropdown(context, state),
            const SizedBox(height: 16),
          ],
          
          // Product Selection
          if (state.selectedSubcategory != null) ...[
            _buildFormLabel('Product *'),
            const SizedBox(height: 8),
            _buildProductDropdown(context, state),
            const SizedBox(height: 16),
          ],
          
          // Product Details (if product is selected)
          if (state.selectedProduct != null) ...[
            _buildProductDetails(context, state),
            const SizedBox(height: 16),
            
            // Quantity
            _buildFormLabel('Quantity *'),
            const SizedBox(height: 8),
            CustomTextField(
              hintText: 'Enter quantity (required)',
              controller: _quantityController,
              keyboardType: TextInputType.number,
              errorText: state.quantityError,
              onChanged: (value) {
                final quantity = int.tryParse(value) ?? 0;
                context.read<UpdateProductFromCatalogBloc>().add(QuantityChangedEvent(quantity));
                context.read<UpdateProductFromCatalogBloc>().add(ValidateQuantityEvent(quantity));
              },
            ),
            const SizedBox(height: 16),
            
            // Price
            _buildFormLabel('Price *'),
            const SizedBox(height: 8),
            _buildPriceField(context, state),
            const SizedBox(height: 16),
            
            // Available Toggle
            _buildToggleOption(
              context,
              'Available',
              state.available,
              (value) => context.read<UpdateProductFromCatalogBloc>().add(ToggleAvailableEvent(value)),
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
                            context.read<UpdateProductFromCatalogBloc>().add(ValidateAllFieldsEvent());
                            if (_isFormValid(state)) {
                              context.read<UpdateProductFromCatalogBloc>().add(UpdateProductEvent());
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
                        : const Text('Update Product'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<UpdateProductFromCatalogBloc>().add(ResetFormEvent());
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
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Check if the entire form is valid
  bool _isFormValid(UpdateProductFromCatalogFormState state) {
    return state.selectedProduct != null && 
           state.quantity > 0 && 
           state.price > 0 &&
           state.quantityError == null &&
           state.priceError == null;
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

  Widget _buildCategoryDropdown(BuildContext context, UpdateProductFromCatalogFormState state) {
    if (state.isLoadingCategories) {
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
            Text('Loading categories...'),
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
        child: DropdownButton<CategoryModel>(
          isExpanded: true,
          value: state.selectedCategory,
          hint: const Text('Select category'),
          items: state.categories.map((CategoryModel category) {
            return DropdownMenuItem<CategoryModel>(
              value: category,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (CategoryModel? newValue) {
            if (newValue != null) {
              context.read<UpdateProductFromCatalogBloc>().add(CategorySelectedEvent(newValue));
            }
          },
        ),
      ),
    );
  }

  Widget _buildSubcategoryDropdown(BuildContext context, UpdateProductFromCatalogFormState state) {
    if (state.isLoadingSubcategories) {
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
            Text('Loading subcategories...'),
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
        child: DropdownButton<SubcategoryModel>(
          isExpanded: true,
          value: state.selectedSubcategory,
          hint: const Text('Select subcategory'),
          items: state.subcategories.map((SubcategoryModel subcategory) {
            return DropdownMenuItem<SubcategoryModel>(
              value: subcategory,
              child: Text(subcategory.name),
            );
          }).toList(),
          onChanged: (SubcategoryModel? newValue) {
            if (newValue != null) {
              context.read<UpdateProductFromCatalogBloc>().add(SubcategorySelectedEvent(newValue));
            }
          },
        ),
      ),
    );
  }

  Widget _buildProductDropdown(BuildContext context, UpdateProductFromCatalogFormState state) {
    if (state.isLoadingProducts) {
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
            Text('Loading products...'),
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
        child: DropdownButton<ProductSelectionModel>(
          isExpanded: true,
          value: state.selectedProduct,
          hint: const Text('Select product'),
          items: state.products.map((ProductSelectionModel product) {
            return DropdownMenuItem<ProductSelectionModel>(
              value: product,
              child: Text(product.name),
            );
          }).toList(),
          onChanged: (ProductSelectionModel? newValue) {
            if (newValue != null) {
              context.read<UpdateProductFromCatalogBloc>().add(ProductSelectedEvent(newValue));
            }
          },
        ),
      ),
    );
  }

  Widget _buildProductDetails(BuildContext context, UpdateProductFromCatalogFormState state) {
    final product = state.selectedProduct!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Details',
            style: TextStyle(
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.bold,
              color: ColorManager.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Name', product.name),
          if (product.description != null && product.description!.isNotEmpty)
            _buildDetailRow('Description', product.description!),
          _buildDetailRow('Brand', product.brand),
          _buildDetailRow('Weight', '${product.weight} ${product.unit}'),
          _buildDetailRow('Category', product.category.name),
          _buildDetailRow('Subcategory', product.subcategory.name),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: FontSize.s14,
                fontWeight: FontWeightManager.medium,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: FontSize.s14,
                color: ColorManager.black,
              ),
            ),
          ),
        ],
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

  Widget _buildPriceField(BuildContext context, UpdateProductFromCatalogFormState state) {
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
                context.read<UpdateProductFromCatalogBloc>().add(PriceChangedEvent(price));
                context.read<UpdateProductFromCatalogBloc>().add(ValidatePriceEvent(price));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _resetControllers() {
    _quantityController.text = '1';
    _priceController.clear();
  }
} 