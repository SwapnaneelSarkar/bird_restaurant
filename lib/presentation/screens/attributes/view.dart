// lib/presentation/screens/attributes/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../ui_components/custom_textField.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../homePage/sidebar/sidebar_drawer.dart';
import '../item_list/bloc.dart';
import '../item_list/event.dart';
import '../item_list/state.dart';
import '../../../models/restaurant_menu_model.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class AttributesScreen extends StatefulWidget {
  const AttributesScreen({Key? key}) : super(key: key);

  @override
  State<AttributesScreen> createState() => _AttributesScreenState();
}

class _AttributesScreenState extends State<AttributesScreen> {
  final TextEditingController _attributeNameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  String _selectedType = 'radio';
  bool _isRequired = true;
  MenuItem? _selectedMenuItem;

  @override
  void dispose() {
    _attributeNameController.dispose();
    _valueController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _openSidebar() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SidebarDrawer(
          activePage: 'add_attributes',
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AttributeBloc(),
        ),
        BlocProvider(
          create: (context) => MenuItemsBloc()..add(const LoadMenuItemsEvent()),
        ),
      ],
      child: Scaffold(
        backgroundColor: ColorManager.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: BlocConsumer<AttributeBloc, AttributeState>(
                  listener: (context, state) {
                    if (state is AttributeCreationSuccess) {
                      _attributeNameController.clear();
                      _valueController.clear();
                      _priceController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else if (state is AttributeError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMenuItemSelector(context),
                          const SizedBox(height: 24),
                          if (_selectedMenuItem != null) ...[
                            _buildNewAttributeSection(context, state),
                            const SizedBox(height: 32),
                            _buildExistingAttributesSection(context, state),
                          ] else
                            _buildSelectMenuItemPrompt(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
          Text(
            'Attributes',
            style: TextStyle(
              fontSize: FontSize.s18,
              fontWeight: FontWeightManager.bold,
              color: ColorManager.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCD6E32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Color(0xFFCD6E32),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Select Menu Item",
                style: TextStyle(
                  fontSize: FontSize.s18,
                  fontWeight: FontWeightManager.bold,
                  color: ColorManager.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<MenuItemsBloc, MenuItemsState>(
            builder: (context, menuState) {
              if (menuState is MenuItemsLoading) {
                return Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFCD6E32),
                    ),
                  ),
                );
              } else if (menuState is MenuItemsLoaded) {
                if (menuState.menuItems.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      'No menu items found. Please add menu items first.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: FontSize.s14,
                      ),
                    ),
                  );
                }
                
                return DropdownButtonFormField<MenuItem>(
                  value: _selectedMenuItem,
                  decoration: InputDecoration(
                    hintText: 'Choose a menu item',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCD6E32)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  isExpanded: true, // This helps prevent render box size issues
                  items: menuState.menuItems.map((MenuItem item) {
                    return DropdownMenuItem<MenuItem>(
                      value: item,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.isVeg ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${item.price}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: FontSize.s12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (MenuItem? newValue) {
                    setState(() {
                      _selectedMenuItem = newValue;
                    });
                    if (newValue != null) {
                      context.read<AttributeBloc>().add(
                        LoadAttributesEvent(menuId: newValue.menuId),
                      );
                    }
                  },
                );
              } else if (menuState is MenuItemsError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Error loading menu items: ${menuState.message}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: FontSize.s14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          context.read<MenuItemsBloc>().add(const LoadMenuItemsEvent(forceRefresh: true));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCD6E32),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectMenuItemPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.touch_app,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a menu item',
            style: TextStyle(
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.medium,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a menu item from the dropdown above to manage its attributes',
            style: TextStyle(
              fontSize: FontSize.s14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNewAttributeSection(BuildContext context, AttributeState state) {
    final attributeState = state is AttributeLoaded ? state : null;
    final isLoading = state is AttributeOperationInProgress;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCD6E32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFFCD6E32),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Create New Attribute",
                style: TextStyle(
                  fontSize: FontSize.s18,
                  fontWeight: FontWeightManager.bold,
                  color: ColorManager.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Attribute Name Input
          _buildFormField(
            "Attribute Name",
            CustomTextField(
              hintText: "e.g., Size, Color, Spice Level",
              controller: _attributeNameController,
              enabled: !isLoading,
            ),
          ),
          
          // Attribute Type Selection
          _buildFormField(
            "Attribute Type",
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              isExpanded: true, // Prevent render box size issues
              items: const [
                DropdownMenuItem(value: 'radio', child: Text('Single Choice (Radio)')),
                DropdownMenuItem(value: 'checkbox', child: Text('Multiple Choice (Checkbox)')),
              ],
              onChanged: isLoading ? null : (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ),
          
          // Required Switch
          Row(
            children: [
              Expanded(
                child: Text(
                  "Required Attribute",
                  style: TextStyle(
                    fontSize: FontSize.s14,
                    fontWeight: FontWeightManager.medium,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Switch(
                value: _isRequired,
                onChanged: isLoading ? null : (value) {
                  setState(() {
                    _isRequired = value;
                  });
                },
                activeColor: const Color(0xFFCD6E32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Values Section
          _buildFormField(
            "Attribute Values",
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        hintText: "Value name",
                        controller: _valueController,
                        enabled: !isLoading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomTextField(
                        hintText: "Price (₹)",
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        enabled: !isLoading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isLoading ? null : () => _addValueToAttribute(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCD6E32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Add"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Display Added Values
          if (attributeState?.newAttributeValues.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity, // Explicit width to prevent render box issues
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Added Values:",
                    style: TextStyle(
                      fontSize: FontSize.s12,
                      fontWeight: FontWeightManager.medium,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...attributeState!.newAttributeValues.map((value) {
                    return Container(
                      width: double.infinity, // Prevent sizing issues
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  value.name,
                                  style: TextStyle(
                                    fontWeight: FontWeightManager.medium,
                                    fontSize: FontSize.s14,
                                  ),
                                ),
                                Text(
                                  'Price: ₹${value.priceAdjustment}',
                                  style: TextStyle(
                                    fontSize: FontSize.s12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (value.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: FontSize.s10,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: isLoading ? null : () => _removeValueFromAttribute(context, value.name),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: isLoading ? Colors.grey : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Create Attribute Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading || !_isFormValid(attributeState) 
                  ? null 
                  : () => _createAttribute(context, attributeState!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCD6E32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: isLoading && state is AttributeOperationInProgress
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(state.operation),
                      ],
                    )
                  : Text(
                      "Create Attribute",
                      style: TextStyle(
                        fontSize: FontSize.s16,
                        fontWeight: FontWeightManager.medium,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: FontSize.s14,
            fontWeight: FontWeightManager.medium,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        field,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExistingAttributesSection(BuildContext context, AttributeState state) {
    final attributeState = state is AttributeLoaded ? state : null;
    final isLoading = state is AttributeLoading;
    
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFCD6E32),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.list_alt,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Existing Attributes",
              style: TextStyle(
                fontSize: FontSize.s18,
                fontWeight: FontWeightManager.bold,
                color: ColorManager.black,
              ),
            ),
            const Spacer(),
            Text(
              "${attributeState?.attributes.length ?? 0} attributes",
              style: TextStyle(
                fontSize: FontSize.s12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (attributeState?.attributes.isEmpty == true)
          _buildEmptyState()
        else if (attributeState?.attributes.isNotEmpty == true)
          ...attributeState!.attributes.asMap().entries.map((entry) {
            final index = entry.key;
            final attribute = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildAttributeCard(context, attribute, index),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.label_off_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No attributes yet',
            style: TextStyle(
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.medium,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first attribute above to get started',
            style: TextStyle(
              fontSize: FontSize.s14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeCard(BuildContext context, Attribute attribute, int index) {
    return Container(
      width: double.infinity, // Explicit width to prevent render box issues
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          attribute.name,
                          style: TextStyle(
                            fontSize: FontSize.s16,
                            fontWeight: FontWeightManager.semiBold,
                            color: ColorManager.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: attribute.type == 'radio' 
                                ? Colors.blue[100] 
                                : Colors.purple[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            attribute.type == 'radio' ? 'Single' : 'Multiple',
                            style: TextStyle(
                              fontSize: FontSize.s10,
                              color: attribute.type == 'radio' 
                                  ? Colors.blue[700] 
                                  : Colors.purple[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${attribute.values.length} values",
                      style: TextStyle(
                        fontSize: FontSize.s12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min, // Prevent overflow
                children: [
                  IconButton(
                    onPressed: () => _showEditDialog(context, attribute),
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    tooltip: 'Edit values',
                  ),
                  IconButton(
                    onPressed: () => _showDeleteAttributeDialog(context, attribute),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    tooltip: 'Delete attribute',
                  ),
                  Switch(
                    value: attribute.isActive,
                    onChanged: (value) {
                      if (attribute.attributeId != null && _selectedMenuItem != null) {
                        HapticFeedback.lightImpact();
                        context.read<AttributeBloc>().add(
                          ToggleAttributeActiveEvent(
                            menuId: _selectedMenuItem!.menuId,
                            attributeId: attribute.attributeId!,
                            isActive: value,
                          ),
                        );
                      }
                    },
                    activeColor: const Color(0xFFCD6E32),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (attribute.values.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: attribute.values.map((value) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: attribute.isActive
                        ? const Color(0xFFCD6E32).withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: attribute.isActive
                          ? const Color(0xFFCD6E32).withOpacity(0.3)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      color: attribute.isActive
                          ? const Color(0xFFCD6E32)
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _addValueToAttribute(BuildContext context) {
    if (_valueController.text.trim().isNotEmpty) {
      final priceAdjustment = int.tryParse(_priceController.text.trim()) ?? 0;
      
      context.read<AttributeBloc>().add(
        AddValueToNewAttributeEvent(
          name: _valueController.text.trim(),
          priceAdjustment: priceAdjustment,
          isDefault: false, // You can add UI to set default value if needed
        ),
      );
      
      _valueController.clear();
      _priceController.clear();
    }
  }

  void _removeValueFromAttribute(BuildContext context, String valueName) {
    context.read<AttributeBloc>().add(
      RemoveValueFromNewAttributeEvent(valueName: valueName),
    );
  }

  void _createAttribute(BuildContext context, AttributeLoaded state) {
    if (_attributeNameController.text.isNotEmpty && 
        state.newAttributeValues.isNotEmpty && 
        _selectedMenuItem != null) {
      context.read<AttributeBloc>().add(
        AddAttributeEvent(
          menuId: _selectedMenuItem!.menuId,
          name: _attributeNameController.text.trim(),
          type: _selectedType,
          isRequired: _isRequired,
          values: state.newAttributeValues,
        ),
      );
    }
  }

  bool _isFormValid(AttributeLoaded? state) {
    return _attributeNameController.text.trim().isNotEmpty && 
           state?.newAttributeValues.isNotEmpty == true &&
           _selectedMenuItem != null;
  }

  void _showEditDialog(BuildContext context, Attribute attribute) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: const Color(0xFFCD6E32),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Edit ${attribute.name}",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Note: Editing attribute values requires backend implementation.",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Current Values:",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: attribute.values.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        title: Text(attribute.values[index]),
                        trailing: const Icon(Icons.info_outline, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAttributeDialog(BuildContext context, Attribute attribute) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
              SizedBox(width: 8),
              Text("Delete Attribute"),
            ],
          ),
          content: Text(
            "Are you sure you want to delete the '${attribute.name}' attribute? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (attribute.attributeId != null && _selectedMenuItem != null) {
                  context.read<AttributeBloc>().add(
                    DeleteAttributeEvent(
                      menuId: _selectedMenuItem!.menuId,
                      attributeId: attribute.attributeId!,
                    ),
                  );
                }
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}