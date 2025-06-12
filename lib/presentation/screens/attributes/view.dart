// lib/presentation/screens/attributes/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../ui_components/custom_textField.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../homePage/sidebar/sidebar_drawer.dart';
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

  @override
  void dispose() {
    _attributeNameController.dispose();
    _valueController.dispose();
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
    return BlocProvider(
      create: (context) => AttributeBloc()..add(LoadAttributesEvent()),
      child: Scaffold(
        backgroundColor: ColorManager.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: BlocConsumer<AttributeBloc, AttributeState>(
                  listener: (context, state) {
                    if (state is AttributeLoaded && 
                        state.newAttributeValues.isEmpty && 
                        _attributeNameController.text.isNotEmpty) {
                      // Clear the attribute name field when attribute is successfully added
                      _attributeNameController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Attribute added successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is AttributeLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFCD6E32),
                        ),
                      );
                    } else if (state is AttributeLoaded) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNewAttributeSection(context, state),
                            const SizedBox(height: 32),
                            _buildExistingAttributesSection(context, state),
                          ],
                        ),
                      );
                    } else if (state is AttributeError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading attributes',
                              style: TextStyle(
                                fontSize: FontSize.s18,
                                fontWeight: FontWeightManager.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: TextStyle(
                                fontSize: FontSize.s14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                context.read<AttributeBloc>().add(LoadAttributesEvent());
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
                    return const SizedBox.shrink();
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

  Widget _buildNewAttributeSection(BuildContext context, AttributeLoaded state) {
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
          Text(
            "Attribute Name",
            style: TextStyle(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.medium,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: "e.g., Size, Color, Spice Level",
            controller: _attributeNameController,
          ),
          const SizedBox(height: 20),
          
          // Values Section
          Text(
            "Attribute Values",
            style: TextStyle(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.medium,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hintText: "Enter a value",
                  controller: _valueController,
                  // onSubmitted: (value) {
                  //   _addValue(context, value);
                  // },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _addValue(context, _valueController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCD6E32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Add"),
              ),
            ],
          ),
          
          // Display Added Values
          if (state.newAttributeValues.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.newAttributeValues.map((value) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCD6E32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFCD6E32).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFCD6E32),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeValue(context, value),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xFFCD6E32),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Create Attribute Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isFormValid(state) ? () => _createAttribute(context, state) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCD6E32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
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

  Widget _buildExistingAttributesSection(BuildContext context, AttributeLoaded state) {
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
              "${state.attributes.length} attributes",
              style: TextStyle(
                fontSize: FontSize.s12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (state.attributes.isEmpty)
          _buildEmptyState()
        else
          ...state.attributes.asMap().entries.map((entry) {
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
                    Text(
                      attribute.name,
                      style: TextStyle(
                        fontSize: FontSize.s16,
                        fontWeight: FontWeightManager.semiBold,
                        color: ColorManager.black,
                      ),
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
                  Switch(
                    value: attribute.isActive,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      context.read<AttributeBloc>().add(
                        ToggleAttributeActiveEvent(
                          attributeName: attribute.name,
                          isActive: value,
                        ),
                      );
                    },
                    activeColor: const Color(0xFFCD6E32),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
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

  void _addValue(BuildContext context, String value) {
    if (value.trim().isNotEmpty) {
      context.read<AttributeBloc>().add(
        AddValueToNewAttributeEvent(value: value.trim()),
      );
      _valueController.clear();
    }
  }

  void _removeValue(BuildContext context, String value) {
    final currentState = context.read<AttributeBloc>().state;
    if (currentState is AttributeLoaded) {
      final updatedValues = currentState.newAttributeValues.where((v) => v != value).toList();
      context.read<AttributeBloc>().add(
        EditAttributeValuesEvent(
          attributeName: "", // Dummy name for new attribute
          newValues: updatedValues,
        ),
      );
    }
  }

  void _createAttribute(BuildContext context, AttributeLoaded state) {
    if (_attributeNameController.text.isNotEmpty && state.newAttributeValues.isNotEmpty) {
      context.read<AttributeBloc>().add(
        AddAttributeEvent(
          name: _attributeNameController.text.trim(),
          values: state.newAttributeValues,
        ),
      );
    }
  }

  bool _isFormValid(AttributeLoaded state) {
    return _attributeNameController.text.trim().isNotEmpty && 
           state.newAttributeValues.isNotEmpty;
  }

  void _showEditDialog(BuildContext context, Attribute attribute) {
    final TextEditingController editValueController = TextEditingController();
    List<String> updatedValues = [...attribute.values];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    // Add new value section
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: editValueController,
                            decoration: const InputDecoration(
                              hintText: "Add new value",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty && !updatedValues.contains(value.trim())) {
                                setState(() {
                                  updatedValues.add(value.trim());
                                  editValueController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (editValueController.text.trim().isNotEmpty && 
                                !updatedValues.contains(editValueController.text.trim())) {
                              setState(() {
                                updatedValues.add(editValueController.text.trim());
                                editValueController.clear();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCD6E32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Add"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Current values
                    if (updatedValues.isNotEmpty) ...[
                      const Text(
                        "Current Values:",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: updatedValues.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              dense: true,
                              title: Text(updatedValues[index]),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    updatedValues.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ] else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "No values added yet",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: updatedValues.isNotEmpty ? () {
                    context.read<AttributeBloc>().add(
                      EditAttributeValuesEvent(
                        attributeName: attribute.name,
                        newValues: updatedValues,
                      ),
                    );
                    Navigator.pop(dialogContext);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCD6E32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}