import 'package:flutter/material.dart';

class NewOrderNotificationBanner extends StatelessWidget {
  final String customerName;
  final VoidCallback onTap;

  const NewOrderNotificationBanner({
    Key? key,
    required this.customerName,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Ensure it's transparent to allow stacking
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.green.shade700, // Green for new order notification
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8.0),
              bottomRight: Radius.circular(8.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: SafeArea(
            bottom: false, // Avoid padding on the bottom if used with SafeArea
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    '🛒 Pesanan baru dari $customerName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
