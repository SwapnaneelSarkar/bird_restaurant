// lib/presentation/screens/menu_items/menu_items_event.dart
import 'package:equatable/equatable.dart';
import '../../../models/restaurant_menu_model.dart';

abstract class MenuItemsEvent extends Equatable {
  const MenuItemsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenuItemsEvent extends MenuItemsEvent {
  const LoadMenuItemsEvent();
}

class ToggleItemAvailabilityEvent extends MenuItemsEvent {
  final MenuItem menuItem;
  final bool isAvailable;

  const ToggleItemAvailabilityEvent({
    required this.menuItem,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [menuItem, isAvailable];
}

class DeleteMenuItemEvent extends MenuItemsEvent {
  final String menuId;

  const DeleteMenuItemEvent(this.menuId);

  @override
  List<Object?> get props => [menuId];
}

class EditMenuItemEvent extends MenuItemsEvent {
  final MenuItem menuItem;

  const EditMenuItemEvent(this.menuItem);

  @override
  List<Object?> get props => [menuItem];
}

class AddNewMenuItemEvent extends MenuItemsEvent {
  const AddNewMenuItemEvent();
}