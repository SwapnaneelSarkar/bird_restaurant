import 'package:equatable/equatable.dart';
import '../../../models/restaurant_menu_model.dart';

// Base class for all menu item events
abstract class MenuItemsEvent extends Equatable {
  const MenuItemsEvent();

  @override
  List<Object> get props => [];
}

// Event to load menu items from the API or cache
class LoadMenuItemsEvent extends MenuItemsEvent {
  final bool forceRefresh;

  const LoadMenuItemsEvent({this.forceRefresh = false});

  @override
  List<Object> get props => [forceRefresh];
}

// Event to refresh menu items
class RefreshMenuItemsEvent extends MenuItemsEvent {
  const RefreshMenuItemsEvent();

  @override
  List<Object> get props => [];
}

// Event to toggle the availability of a menu item
class ToggleItemAvailabilityEvent extends MenuItemsEvent {
  final MenuItem menuItem;
  final bool isAvailable;

  const ToggleItemAvailabilityEvent({
    required this.menuItem,
    required this.isAvailable,
  });

  @override
  List<Object> get props => [menuItem, isAvailable];
}

// Event to delete a menu item
class DeleteMenuItemEvent extends MenuItemsEvent {
  final String menuId;

  const DeleteMenuItemEvent(this.menuId);

  @override
  List<Object> get props => [menuId];
}

// Event to edit a menu item
class EditMenuItemEvent extends MenuItemsEvent {
  final MenuItem menuItem;

  const EditMenuItemEvent(this.menuItem);

  @override
  List<Object> get props => [menuItem];
}

// Event to add a new menu item
class AddNewMenuItemEvent extends MenuItemsEvent {
  const AddNewMenuItemEvent();

  @override
  List<Object> get props => [];
}

// Enum to represent different filter types
enum FilterType {
  priceLowToHigh,
  priceHighToLow,
  nameAZ,
  nameZA,
}

// Event to filter menu items
class FilterMenuItemsEvent extends MenuItemsEvent {
  final FilterType filterType;

  const FilterMenuItemsEvent(this.filterType);

  @override
  List<Object> get props => [filterType];
}

// Event to search menu items
class SearchMenuItemsEvent extends MenuItemsEvent {
  final String query;

  const SearchMenuItemsEvent(this.query);

  @override
  List<Object> get props => [query];
}