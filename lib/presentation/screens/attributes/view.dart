// lib/presentation/screens/attributes/view.dart
import 'package:bird_restaurant/presentation/resources/colors.dart' show ColorManager;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../ui_components/attribute_card.dart';
import '../../../../ui_components/custom_button.dart';
import '../../../ui_components/custom_button_locatin.dart';
import '../../../ui_components/custom_textField.dart';
import '../../../ui_components/universal_widget/topbar.dart';
import '../../resources/font.dart';
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

  // lib/presentation/screens/attributes/view.dart (partial update)
@override
Widget build(BuildContext context) {
  return BlocProvider(
    create: (context) => AttributeBloc()..add(LoadAttributesEvent()),
    child: Scaffold(
      backgroundColor: ColorManager.background, // Using the background color from ColorManager
      body: SafeArea(
        child: Column(
          children: [
            const AppBackHeader(title: "Attributes"),
            Expanded(
              child: BlocBuilder<AttributeBloc, AttributeState>(
                builder: (context, state) {
                  if (state is AttributeLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (state is AttributeLoaded) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildNewAttributeSection(context, state),
                        const SizedBox(height: 24),
                        _buildExistingAttributesSection(context, state),
                      ],
                    );
                  } else if (state is AttributeError) {
                    return Center(
                      child: Text(
                        "Error: ${state.message}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildNewAttributeSection(BuildContext context, AttributeLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "New Attribute",
            style: TextStyle(
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.semiBold,
              color: ColorManager.black,
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            hintText: "Enter attribute name",
            controller: _attributeNameController,
          ),
          const SizedBox(height: 16),
          Text(
            "Add Values",
            style: TextStyle(
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.semiBold,
              color: ColorManager.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hintText: "Enter value",
                  controller: _valueController,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_valueController.text.isNotEmpty) {
                      context.read<AttributeBloc>().add(
                        AddValueToNewAttributeEvent(
                          value: _valueController.text,
                        ),
                      );
                      _valueController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCD6E32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Add Value"),
                ),
              ),
            ],
          ),
          if (state.newAttributeValues.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.newAttributeValues.map((value) {
                return Chip(
                  label: Text(value),
                  backgroundColor: Colors.grey[200],
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    final updatedValues = [...state.newAttributeValues];
                    updatedValues.remove(value);
                    context.read<AttributeBloc>().add(
                      EditAttributeValuesEvent(
                        attributeName: "", // Dummy name for new attribute
                        newValues: updatedValues,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          CustomButtonSlim(
            label: "Add Attribute",
            onPressed: () {
              if (_attributeNameController.text.isNotEmpty && 
                  state.newAttributeValues.isNotEmpty) {
                context.read<AttributeBloc>().add(
                  AddAttributeEvent(
                    name: _attributeNameController.text,
                    values: state.newAttributeValues,
                  ),
                );
                _attributeNameController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExistingAttributesSection(BuildContext context, AttributeLoaded state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Existing Attributes",
        style: TextStyle(
          fontSize: FontSize.s18,
          fontWeight: FontWeightManager.bold,
          color: ColorManager.black,
        ),
      ),
      const SizedBox(height: 16),
      // Remove the previous list and use this instead
      ...state.attributes.map((attribute) {
        return AttributeCard(
          title: attribute.name,
          values: attribute.values.join(", "),
          isActive: attribute.isActive,
          onEditValues: () {
            _showEditValuesDialog(context, attribute);
          },
          onToggleSwitch: (value) {
            context.read<AttributeBloc>().add(
              ToggleAttributeActiveEvent(
                attributeName: attribute.name,
                isActive: value,
              ),
            );
          },
        );
      }).toList(),
    ],
  );
}
  void _showEditValuesDialog(BuildContext context, Attribute attribute) {
    final TextEditingController editValueController = TextEditingController();
    List<String> updatedValues = [...attribute.values];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit ${attribute.name} Values"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add new value field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: editValueController,
                            decoration: const InputDecoration(
                              hintText: "Add new value",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (editValueController.text.isNotEmpty) {
                              setState(() {
                                updatedValues.add(editValueController.text);
                                editValueController.clear();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCD6E32),
                          ),
                          child: const Text("Add"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // List of current values with delete option
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: updatedValues.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(updatedValues[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    context.read<AttributeBloc>().add(
                      EditAttributeValuesEvent(
                        attributeName: attribute.name,
                        newValues: updatedValues,
                      ),
                    );
                    Navigator.pop(context);
                  },
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