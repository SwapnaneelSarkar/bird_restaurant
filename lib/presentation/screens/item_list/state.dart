import 'package:equatable/equatable.dart';
import '../../../models/restaurant_menu_model.dart';
import 'event.dart';

// Base class for all menu item states
abstract class MenuItemsState extends Equatable {
  const MenuItemsState();

  @override
  List<Object?> get props => [];
}

// Initial state
class MenuItemsInitial extends MenuItemsState {}

// Loading state
class MenuItemsLoading extends MenuItemsState {}

// Loaded state with menu items
class MenuItemsLoaded extends MenuItemsState {
  final List<MenuItem> menuItems;
  final RestaurantData restaurantData;
  final bool isFiltered;
  final FilterType? filterType;
  final String? searchQuery;
  final bool showVegOnly;
  final bool showNonVegOnly;

  const MenuItemsLoaded({
    required this.menuItems,
    required this.restaurantData,
    this.isFiltered = false,
    this.filterType,
    this.searchQuery,
    this.showVegOnly = false,
    this.showNonVegOnly = false,
  });

  @override
  List<Object?> get props => [
        menuItems,
        restaurantData,
        isFiltered,
        filterType,
        searchQuery,
        showVegOnly,
        showNonVegOnly,
      ];
}

// Error state
class MenuItemsError extends MenuItemsState {
  final String message;

  const MenuItemsError(this.message);

  @override
  List<Object> get props => [message];
}

// State for navigation to add item screen
class NavigateToAddItem extends MenuItemsState {}

// State for navigation to edit item screen
class NavigateToEditItem extends MenuItemsState {
  final MenuItem menuItem;

  const NavigateToEditItem(this.menuItem);

  @override
  List<Object> get props => [menuItem];
}

// State for updating item availability
class ItemAvailabilityUpdating extends MenuItemsState {
  final MenuItem menuItem;

  const ItemAvailabilityUpdating(this.menuItem);

  @override
  List<Object> get props => [menuItem];
}

// State for deleting a menu item
class ItemDeleting extends MenuItemsState {
  final String menuId;

  const ItemDeleting(this.menuId);

  @override
  List<Object> get props => [menuId];
}