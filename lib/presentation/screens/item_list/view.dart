import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../../ui_components/edit_item_card.dart';
import '../../../ui_components/universal_widget/topbar.dart';
import '../add_product/view.dart';
import '../edit_item/view.dart';
// Remove this import
import '../homePage/sidebar/sidebar_drawer.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../../services/restaurant_info_service.dart';

class EditMenuView extends StatefulWidget {
  const EditMenuView({Key? key}) : super(key: key);

  @override
  State<EditMenuView> createState() => _EditMenuViewState();
}

class _EditMenuViewState extends State<EditMenuView> {
  late MenuItemsBloc _menuItemsBloc;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _menuItemsBloc = MenuItemsBloc()..add(const LoadMenuItemsEvent());
    
    // Add listener for search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
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
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FutureBuilder<Map<String, String>>(
          future: RestaurantInfoService.getRestaurantInfo(),
          builder: (context, snapshot) {
            final info = snapshot.data ?? {};
            return SidebarDrawer(
              activePage: 'products',
              restaurantName: info['name'],
              restaurantSlogan: info['slogan'],
              restaurantImageUrl: info['imageUrl'],
            );
          },
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
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
            // Navigate to edit product screen with the selected menu item
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditProductView(menuItem: state.menuItem),
              ),
            ).then((result) {
              // Refresh menu items when returning from edit screen if result is true
              if (result == true) {
                _menuItemsBloc.add(const RefreshMenuItemsEvent());
              }
            });
          } else if (state is MenuItemsError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.grey[100],
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: _buildBody(context, state),
                  ),
                ],
              ),
            ),
            floatingActionButton: _buildFloatingActionButton(context),
          );
        },
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
              const Text(
                'Menu Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
                      hintText: 'Search menu items',
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

  Widget _buildBody(BuildContext context, MenuItemsState state) {
    if (state is MenuItemsLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E22)),
        ),
      );
    } else if (state is MenuItemsLoaded) {
      if (state.menuItems.isEmpty) {
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
                        Icons.restaurant_menu,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No menu items found',
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
                                : 'Tap the + button to add your first menu item',
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
                itemCount: state.menuItems.length,
                itemBuilder: (context, index) {
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
                        builder: (dialogContext) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Delete Menu Item'),
                          content: Text(
                              'Are you sure you want to delete "${menuItem.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _menuItemsBloc.add(DeleteMenuItemEvent(menuItem.menuId));
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
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
      child: FloatingActionButton(
        onPressed: () {
          _menuItemsBloc.add(const AddNewMenuItemEvent());
        },
        backgroundColor: const Color(0xFFE67E22),
        elevation: 0,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}