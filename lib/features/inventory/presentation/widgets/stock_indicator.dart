import 'package:flutter/material.dart';
import '../../data/models/item_model.dart';

/// Stock indicator widget for displaying stock status visually
/// Shows colored badge based on stock level vs threshold
///
/// Colors:
/// - Green (#10B981): stock > threshold (normal)
/// - Yellow (#F59E0B): 0 < stock <= threshold (low)
/// - Red (#EF4444): stock = 0 (out of stock)
class StockIndicator extends StatelessWidget {
  /// The item to display stock status for
  final Item item;

  /// Whether to show only the icon without text
  final bool iconOnly;

  /// Whether to show compact version (just count)
  final bool compact;

  const StockIndicator({
    super.key,
    required this.item,
    this.iconOnly = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.stockStatus;
    final color = status.color;

    // Icon only mode
    if (iconOnly) {
      return Icon(
        status.icon,
        size: 16,
        color: color,
      );
    }

    // Build the stock text
    String stockText;
    if (item.stock == 0) {
      stockText = 'Habis';
    } else if (compact) {
      stockText = '${item.stock}';
    } else {
      stockText = 'Stok: ${item.stock}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            stockText,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini stock indicator showing just the colored dot
/// Useful for list items with limited space
class StockDot extends StatelessWidget {
  final Item item;
  final double size;

  const StockDot({
    super.key,
    required this.item,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: item.stockStatus.color,
        shape: BoxShape.circle,
      ),
    );
  }
}
