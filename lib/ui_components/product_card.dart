import 'package:flutter/material.dart';
import '../models/restaurant_menu_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onToggleAvailability;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    Key? key,
    required this.product,
    this.onToggleAvailability,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if product has low stock (less than 5)
    final bool isLowStock = product.isLowStock;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLowStock 
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      color: isLowStock ? Colors.orange.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: product.hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.displayImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.inventory_2_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.inventory_2_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
            ),
            const SizedBox(width: 16),
            
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Brand
                  if (product.brand.isNotEmpty)
                    Text(
                      'Brand: ${product.brand}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  
                  // Weight and Unit
                  Text(
                    product.displayWeight,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  // Category and Subcategory
                  Text(
                    '${product.category.name} > ${product.subcategory.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price and Quantity
                  Row(
                    children: [
                      Text(
                        product.displayPrice,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Quantity with low stock warning
                      Row(
                        children: [
                          if (isLowStock) ...[
                            Icon(
                              Icons.warning_rounded,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            'Qty: ${product.quantity}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isLowStock ? Colors.orange[700] : Colors.grey[700],
                              fontWeight: isLowStock ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (isLowStock) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'LOW STOCK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Column(
              children: [
                // Availability Toggle
                Switch(
                  value: product.available,
                  onChanged: (value) => onToggleAvailability?.call(),
                  activeColor: const Color(0xFFE67E22),
                ),
                
                const SizedBox(height: 8),
                
                // Edit Button
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFFE67E22),
                  ),
                  tooltip: 'Edit',
                ),
                
                // Delete Button
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 