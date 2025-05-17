// lib/presentation/screens/menu_items/menu_items_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui_components/edit_item_card.dart';
import '../../../ui_components/universal_widget/topbar.dart';
import '../add_product/view.dart';
import '../edit_item/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class EditMenuView extends StatelessWidget {
  const EditMenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MenuItemsBloc()..add(const LoadMenuItemsEvent()),
      child: BlocConsumer<MenuItemsBloc, MenuItemsState>(
        listener: (context, state) {
  if (state is NavigateToAddItem) {
    // Navigate to add product screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddProductScreen(),
      ),
    ).then((_) {
      // Refresh menu items when returning from add screen
      context.read<MenuItemsBloc>().add(const LoadMenuItemsEvent());
    });
  } else if (state is NavigateToEditItem) {
    // Navigate to edit product screen with the selected menu item
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProductView(menuItem: state.menuItem),
      ),
    ).then((result) {
      // Refresh menu items when returning from edit screen
      if (result == true) {
        context.read<MenuItemsBloc>().add(const LoadMenuItemsEvent());
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
        const AppBackHeader(title: 'Menu Items'),
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
                  onPressed: () {},
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
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ],
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
        return Center(
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
                'Tap the + button to add your first menu item',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),  // Added padding for better spacing
        itemCount: state.menuItems.length,
        itemBuilder: (context, index) {
          final menuItem = state.menuItems[index];
          return MenuItemCard(
            menuItem: menuItem,
            onToggleAvailability: (isAvailable) {
              context.read<MenuItemsBloc>().add(
                    ToggleItemAvailabilityEvent(
                      menuItem: menuItem,
                      isAvailable: isAvailable,
                    ),
                  );
            },
            onEdit: () {
              context.read<MenuItemsBloc>().add(EditMenuItemEvent(menuItem));
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
                        context
                            .read<MenuItemsBloc>()
                            .add(DeleteMenuItemEvent(menuItem.menuId));
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
      );
    } else {
      return Center(
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
                context.read<MenuItemsBloc>().add(const LoadMenuItemsEvent());
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
          context.read<MenuItemsBloc>().add(const AddNewMenuItemEvent());
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