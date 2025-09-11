import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../ui_components/edit_item_card.dart';
import '../../../ui_components/shimmer_loading.dart';
import '../../../ui_components/product_card.dart';
import '../../../ui_components/confirmation_dialog.dart';
import '../add_product/view.dart';
import '../edit_item/view.dart';
import '../update_product_from_catalog/view.dart';
import '../add_product_from_catalog/view.dart';
import '../homePage/sidebar/sidebar_drawer.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../../services/restaurant_info_service.dart';
import '../../../services/token_service.dart';
import '../../resources/router/router.dart';
import '../../../constants/api_constants.dart';
import '../../../models/restaurant_menu_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditMenuView extends StatefulWidget {
  const EditMenuView({Key? key}) : super(key: key);

  @override
  State<EditMenuView> createState() => _EditMenuViewState();
}

class _EditMenuViewState extends State<EditMenuView> {
  final MenuItemsBloc _menuItemsBloc = MenuItemsBloc();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Track the last loaded state
  MenuItemsLoaded? _lastLoadedState;
  
  // Restaurant info state
  Map<String, String>? _restaurantInfo;
  bool _isRestaurantInfoLoaded = false;

  @override
  void initState() {
    super.initState();
    _menuItemsBloc.add(const LoadMenuItemsEvent());
    
    // Add listener for search
    _searchController.addListener(_onSearchChanged);
    
    // Load restaurant info
    _loadRestaurantInfo();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _menuItemsBloc.close();
    super.dispose();
  }

  // Debounce method for search
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _menuItemsBloc.add(SearchMenuItemsEvent(_searchController.text));
    });
  }

  // Function to handle refresh
  Future<void> _handleRefresh() async {
    _menuItemsBloc.add(const RefreshMenuItemsEvent());
    // Wait for the refresh to complete
    return Future.delayed(const Duration(seconds: 1));
  }

  void _openSidebar() {
    // Use the scaffold's built-in drawer instead of pushing a new route
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      // Force refresh from API to get the latest restaurant info
      final info = await RestaurantInfoService.refreshRestaurantInfo();
      if (mounted) {
        setState(() {
          _restaurantInfo = info;
          _isRestaurantInfoLoaded = true;
        });
        debugPrint('🔄 ItemListPage: Loaded restaurant info - Name: ${info['name']}, Slogan: ${info['slogan']}, Image: ${info['imageUrl']}');
      }
    } catch (e) {
      debugPrint('Error loading restaurant info: $e');
    }
  }

  // Toggle product availability using PUT API
  Future<void> _toggleProductAvailability(Product product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final partnerId = prefs.getString('user_id');
      
      if (token == null || partnerId == null) {
        throw Exception('Authentication information not found. Please login again.');
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/update-product');
      
      final body = {
        'partner_id': partnerId,
        'product_id': product.productId,
        'quantity': product.quantity,
        'price': double.tryParse(product.price) ?? 0.0,
        'available': !product.available, // Toggle the availability
      };
      
      debugPrint('🔍 Toggling product availability for: ${product.name}');
      debugPrint('🔍 Request body: ${json.encode(body)}');
      
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      
      debugPrint('🔍 Toggle response status: ${response.statusCode}');
      debugPrint('🔍 Toggle response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'SUCCESS') {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} is now ${!product.available ? 'available' : 'unavailable'}'),
                backgroundColor: Colors.green,
              ),
            );
          }
          // Refresh the menu items to show updated data
          _menuItemsBloc.add(const RefreshMenuItemsEvent());
        } else {
          throw Exception(responseData['message'] ?? 'Failed to update product availability');
        }
      } else {
        throw Exception('Failed to update product availability. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error toggling product availability: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete product using DELETE API
  Future<void> _deleteProduct(Product product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final partnerId = prefs.getString('user_id');
      
      if (token == null || partnerId == null) {
        throw Exception('Authentication information not found. Please login again.');
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/delete-product');
      
      final body = {
        'partner_id': partnerId,
        'product_id': product.productId,
      };
      
      debugPrint('🔍 Deleting product: ${product.name}');
      debugPrint('🔍 Request body: ${json.encode(body)}');
      
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      
      debugPrint('🔍 Delete response status: ${response.statusCode}');
      debugPrint('🔍 Delete response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'SUCCESS') {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} has been deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          // Refresh the menu items to show updated data
          _menuItemsBloc.add(const RefreshMenuItemsEvent());
        } else {
          throw Exception(responseData['message'] ?? 'Failed to delete product');
        }
      } else {
        throw Exception('Failed to delete product. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check if current supercategory is Food
  Future<bool> _isFoodSupercategory() async {
    try {
      // Get the current state to check if we're showing products or menu items
      final currentState = _menuItemsBloc.state;
      if (currentState is MenuItemsLoaded) {
        // Use the same logic as the bloc to determine supercategory
        return currentState.isFoodSupercategory;
      }
      
      // Fallback: check supercategory from token service
      final supercategoryId = await TokenService.getSupercategoryId();
      final prefs = await SharedPreferences.getInstance();
      final supercategoryName = prefs.getString('supercategory_name');
      
      debugPrint('🔍 View _isFoodSupercategory - ID: $supercategoryId, Name: $supercategoryName');
      
      // Check if it's Food by ID or name
      return supercategoryId == '7acc47a2fa5a4eeb906a753b3' || 
             supercategoryName == 'Food';
    } catch (e) {
      debugPrint('Error checking supercategory: $e');
      return false; // Default to non-Food behavior
    }
  }

  // Navigate to appropriate edit page based on supercategory
  Future<void> _navigateToEditPage(dynamic item) async {
    final isFood = await _isFoodSupercategory();
    
    if (isFood) {
      // For Food supercategory, use regular EditProductView
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditProductView(menuItem: item),
        ),
      ).then((result) {
        // Refresh menu items when returning from edit screen if result is true
        if (result == true) {
          _menuItemsBloc.add(const RefreshMenuItemsEvent());
        }
      });
    } else {
      // For non-Food supercategories, use UpdateProductFromCatalogScreen with product details
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UpdateProductFromCatalogScreen(product: item),
        ),
      ).then((result) {
        // Refresh menu items when returning from edit screen if result is true
        if (result == true) {
          _menuItemsBloc.add(const RefreshMenuItemsEvent());
        }
      });
    }
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
        value: _menuItemsBloc,
        child: BlocConsumer<MenuItemsBloc, MenuItemsState>(
          listenWhen: (previous, current) {
            // Only listen for navigation events
            return current is NavigateToAddItem || 
                   current is NavigateToEditItem || 
                   current is MenuItemsError;
          },
          listener: (context, state) {
            if (state is NavigateToAddItem) {
              // Navigate to add product screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddProductScreen(),
                ),
              ).then((_) {
                // Refresh menu items when returning from add screen
                _menuItemsBloc.add(const RefreshMenuItemsEvent());
              });
            } else if (state is NavigateToEditItem) {
              // Conditionally navigate to appropriate edit page based on supercategory
              _navigateToEditPage(state.menuItem);
            } else if (state is MenuItemsError) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            // Track the last loaded state
            if (state is MenuItemsLoaded) {
              _lastLoadedState = state;
            }
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.grey[100],
              drawer: SidebarDrawer(
                activePage: 'products',
                restaurantName: _restaurantInfo?['name'] ?? 'Products',
                restaurantSlogan: _restaurantInfo?['slogan'] ?? 'Manage your menu',
                restaurantImageUrl: _restaurantInfo?['imageUrl'],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: _buildBodyWithLastLoaded(context, state),
                    ),
                  ],
                ),
              ),
              floatingActionButton: _buildFloatingActionButton(context),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Custom header with sidebar opener
        Container(
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
              BlocBuilder<MenuItemsBloc, MenuItemsState>(
                builder: (context, state) {
                  final isFoodSupercategory = state is MenuItemsLoaded ? state.isFoodSupercategory : true;
                  return Text(
                    isFoodSupercategory ? 'Menu Items' : 'Products',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Container(
          height: 64,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintStyle: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.black87),
                  onPressed: () {
                    _showFilterOptions(context);
                  },
                ),
              ),
            ],
          ),
        ),
        // Veg/NonVeg Filter Toggles - Only show for food supercategories
        BlocBuilder<MenuItemsBloc, MenuItemsState>(
          builder: (context, state) {
            final isFoodSupercategory = state is MenuItemsLoaded ? state.isFoodSupercategory : true;
            if (!isFoodSupercategory) {
              return const SizedBox.shrink(); // Hide for non-food supercategories
            }
            
            final showVegOnly = state is MenuItemsLoaded ? state.showVegOnly : false;
            final showNonVegOnly = state is MenuItemsLoaded ? state.showNonVegOnly : false;
            
            return Container(
              height: 60,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Veg Toggle
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _menuItemsBloc.add(ToggleVegFilterEvent(
                          showVegOnly: !showVegOnly,
                          showNonVegOnly: showNonVegOnly,
                        ));
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: showVegOnly ? Colors.green.withValues(alpha: 0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: showVegOnly ? Colors.green : Colors.grey[300]!,
                            width: showVegOnly ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.circle,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Veg',
                              style: TextStyle(
                                color: showVegOnly ? Colors.green : Colors.black54,
                                fontWeight: showVegOnly ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // NonVeg Toggle
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _menuItemsBloc.add(ToggleVegFilterEvent(
                          showVegOnly: showVegOnly,
                          showNonVegOnly: !showNonVegOnly,
                        ));
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: showNonVegOnly ? Colors.red.withValues(alpha: 0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: showNonVegOnly ? Colors.red : Colors.grey[300]!,
                            width: showNonVegOnly ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.stop,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Non-Veg',
                              style: TextStyle(
                                color: showNonVegOnly ? Colors.red : Colors.black54,
                                fontWeight: showNonVegOnly ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Menu Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildFilterOption(
                context,
                'Price: Low to High',
                () {
                  _menuItemsBloc.add(const FilterMenuItemsEvent(FilterType.priceLowToHigh));
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                context,
                'Price: High to Low',
                () {
                  _menuItemsBloc.add(const FilterMenuItemsEvent(FilterType.priceHighToLow));
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                context,
                'Name: A to Z',
                () {
                  _menuItemsBloc.add(const FilterMenuItemsEvent(FilterType.nameAZ));
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                context,
                'Name: Z to A',
                () {
                  _menuItemsBloc.add(const FilterMenuItemsEvent(FilterType.nameZA));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              _buildFilterOption(
                context,
                'Reset Filters',
                () {
                  _menuItemsBloc.add(const RefreshMenuItemsEvent());
                  Navigator.pop(context);
                },
                isReset: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(BuildContext context, String title, VoidCallback onTap, {bool isReset = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isReset ? Colors.grey[100] : Colors.transparent,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isReset ? FontWeight.w500 : FontWeight.normal,
            color: isReset ? const Color(0xFFE67E22) : null,
          ),
        ),
      ),
    );
  }

  // New function to handle error state with fallback to last loaded data
  Widget _buildBodyWithLastLoaded(BuildContext context, MenuItemsState state) {
    if (state is MenuItemsLoading) {
      return const ShimmerProductsContent();
    } else if (state is MenuItemsLoaded) {
      return _buildBody(context, state);
    } else if (state is MenuItemsError) {
      if (_lastLoadedState != null && _lastLoadedState!.menuItems.isNotEmpty) {
        // Show the last loaded data, error is shown as Snackbar in listener
        return _buildBody(context, _lastLoadedState!);
      } else {
        // No data at all, show error UI
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: const Color(0xFFE67E22),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load menu items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _menuItemsBloc.add(const LoadMenuItemsEvent(forceRefresh: true));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE67E22),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Fallback: show shimmer loading
      return const ShimmerProductsContent();
    }
  }

  Widget _buildBody(BuildContext context, MenuItemsState state) {
    if (state is MenuItemsLoading) {
      return const ShimmerProductsContent();
    } else if (state is MenuItemsLoaded) {
      final itemsEmpty = state.isFoodSupercategory ? state.menuItems.isEmpty : state.products.isEmpty;
      if (itemsEmpty) {
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: const Color(0xFFE67E22),
          child: ListView(  // Wrap in ListView to make refresh work with empty content
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        state.isFoodSupercategory ? Icons.restaurant_menu : Icons.inventory_2_outlined,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.isFoodSupercategory ? 'No menu items found' : 'No products found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                                              Text(
                          state.isFiltered && (state.searchQuery?.isNotEmpty ?? false)
                              ? 'No results found for "${state.searchQuery}". Try a different search.'
                              : state.isFiltered
                                  ? 'No results found with the current filter.'
                                  : state.isFoodSupercategory
                                      ? 'Tap the + button to add your first menu item'
                                      : 'Tap the + button to add your first product',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (state.isFiltered) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _searchController.clear();
                            _menuItemsBloc.add(const RefreshMenuItemsEvent());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE67E22),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
      
      // Display header if filtered
      Widget? filterHeader;
      if (state.isFiltered) {
        String filterText = '';
        if (state.searchQuery?.isNotEmpty ?? false) {
          filterText = 'Search: "${state.searchQuery}"';
        } else if (state.filterType != null) {
          switch (state.filterType!) {
            case FilterType.priceLowToHigh:
              filterText = 'Price: Low to High';
              break;
            case FilterType.priceHighToLow:
              filterText = 'Price: High to Low';
              break;
            case FilterType.nameAZ:
              filterText = 'Name: A to Z';
              break;
            case FilterType.nameZA:
              filterText = 'Name: Z to A';
              break;
          }
        }
        
        if (filterText.isNotEmpty) {
          filterHeader = Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  filterText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _menuItemsBloc.add(const RefreshMenuItemsEvent());
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Color(0xFFE67E22),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
      
      return Column(
        children: [
          if (filterHeader != null) filterHeader,
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _handleRefresh,
              color: const Color(0xFFE67E22),
                          child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 80),  // Added padding for better spacing
              itemCount: state.isFoodSupercategory ? state.menuItems.length : state.products.length,
              itemBuilder: (context, index) {
                if (state.isFoodSupercategory) {
                  // Show menu items for food supercategory
                  final menuItem = state.menuItems[index];
                  return MenuItemCard(
                    menuItem: menuItem,
                    onToggleAvailability: (isAvailable) {
                      _menuItemsBloc.add(
                        ToggleItemAvailabilityEvent(
                          menuItem: menuItem,
                          isAvailable: isAvailable,
                        ),
                      );
                    },
                    onEdit: () {
                      _menuItemsBloc.add(EditMenuItemEvent(menuItem));
                    },
                    onDelete: () {
                      // Show confirmation dialog before deleting
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return ConfirmationDialog(
                            title: 'Delete Menu Item',
                            message: 'Are you sure you want to delete "${menuItem.name}"? This action cannot be undone.',
                            confirmText: 'Delete',
                            cancelText: 'Cancel',
                            icon: Icons.delete_outline,
                            confirmColor: Colors.red,
                            onConfirm: () {
                              _menuItemsBloc.add(DeleteMenuItemEvent(menuItem.menuId));
                            },
                          );
                        },
                      );
                    },
                  );
                } else {
                  // Show products for non-food supercategory
                  final product = state.products[index];
                  return ProductCard(
                    product: product,
                    onToggleAvailability: () {
                      // Implement product availability toggle using the same PUT API
                      _toggleProductAvailability(product);
                    },
                    onEdit: () {
                      // Navigate to update product from catalog screen with product details
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UpdateProductFromCatalogScreen(product: product),
                        ),
                      ).then((result) {
                        // Refresh products when returning from edit screen if result is true
                        if (result == true) {
                          _menuItemsBloc.add(const RefreshMenuItemsEvent());
                        }
                      });
                    },
                    onDelete: () {
                      // Show confirmation dialog before deleting
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return ConfirmationDialog(
                            title: 'Delete Product',
                            message: 'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
                            confirmText: 'Delete',
                            cancelText: 'Cancel',
                            icon: Icons.delete_outline,
                            confirmColor: Colors.red,
                            onConfirm: () {
                              _deleteProduct(product);
                            },
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
            ),
          ),
        ],
      );
    } else {
      return RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        color: const Color(0xFFE67E22),
        child: ListView(  // Wrap in ListView to make refresh work with error state
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load menu items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _menuItemsBloc.add(const LoadMenuItemsEvent(forceRefresh: true));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BlocBuilder<MenuItemsBloc, MenuItemsState>(
        builder: (context, state) {
          final isFoodSupercategory = state is MenuItemsLoaded ? state.isFoodSupercategory : true;
          return FloatingActionButton(
            onPressed: () {
              if (isFoodSupercategory) {
                _menuItemsBloc.add(const AddNewMenuItemEvent());
              } else {
                // Navigate to add product from catalog screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddProductFromCatalogScreen(),
                  ),
                ).then((result) {
                  // Refresh products when returning from add screen if result is true
                  if (result == true) {
                    _menuItemsBloc.add(const RefreshMenuItemsEvent());
                  }
                });
              }
            },
            backgroundColor: const Color(0xFFE67E22),
            elevation: 0,
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          );
        },
      ),
    );
  }
}