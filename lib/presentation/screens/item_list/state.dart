// lib/presentation/screens/menu_items/menu_items_state.dart
import 'package:equatable/equatable.dart';
import '../../../models/restaurant_menu_model.dart';

abstract class MenuItemsState extends Equatable {
  const MenuItemsState();

  @override
  List<Object?> get props => [];
}

class MenuItemsInitial extends MenuItemsState {}

class MenuItemsLoading extends MenuItemsState {}

class MenuItemsLoaded extends MenuItemsState {
  final List<MenuItem> menuItems;
  final RestaurantData restaurantData;

  const MenuItemsLoaded({
    required this.menuItems,
    required this.restaurantData,
  });

  @override
  List<Object?> get props => [menuItems, restaurantData];

  MenuItemsLoaded copyWith({
    List<MenuItem>? menuItems,
    RestaurantData? restaurantData,
  }) {
    return MenuItemsLoaded(
      menuItems: menuItems ?? this.menuItems,
      restaurantData: restaurantData ?? this.restaurantData,
    );
  }
}

class MenuItemsError extends MenuItemsState {
  final String message;

  const MenuItemsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ItemAvailabilityUpdating extends MenuItemsState {
  final MenuItem menuItem;

  const ItemAvailabilityUpdating(this.menuItem);

  @override
  List<Object?> get props => [menuItem];
}

class ItemDeleting extends MenuItemsState {
  final String menuId;

  const ItemDeleting(this.menuId);

  @override
  List<Object?> get props => [menuId];
}

class NavigateToAddItem extends MenuItemsState {}

class NavigateToEditItem extends MenuItemsState {
  final MenuItem menuItem;

  const NavigateToEditItem(this.menuItem);

  @override
  List<Object?> get props => [menuItem];
}