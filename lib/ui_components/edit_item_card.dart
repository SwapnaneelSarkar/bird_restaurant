// lib/ui_components/menu_item_card.dart
import 'package:flutter/material.dart';
import '../models/restaurant_menu_model.dart';
import '../services/currency_service.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;
  final Function(bool) onToggleAvailability;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuItemCard({
    Key? key,
    required this.menuItem,
    required this.onToggleAvailability,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        children: [
          // Item Details Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Food Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: menuItem.imageUrl != null
                        ? Image.network(
                            menuItem.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menuItem.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<String>(
                        future: CurrencyService().getCurrencySymbol(),
                        builder: (context, snapshot) {
                          final symbol = snapshot.data ?? '';
                          return Text(
                            '$symbol${_formatPrice(menuItem.price)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        menuItem.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Availability Switch
                Switch(
                  value: menuItem.available,
                  onChanged: onToggleAvailability,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFFE67E22),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey[300],
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Edit Button
                Expanded(
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: Colors.indigo[400],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.indigo[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Divider
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey[200],
                ),
                
                // Delete Button
                Expanded(
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red[400],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.restaurant,
          color: Colors.grey[400],
          size: 30,
        ),
      ),
    );
  }

  String _formatPrice(String price) {
    try {
      final double numPrice = double.parse(price);
      return numPrice.toStringAsFixed(2);
    } catch (e) {
      return price;
    }
  }
}