import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A full-width "Download Invoice" button that opens the web shop tracking
/// page for the given [code] in the device's browser.
///
/// The invoice PDF itself is generated and served by the web app
/// (`warungku_web`) from the tracking page, so this button only needs to
/// launch the public tracking URL — keeping all invoice/PDF logic in one place.
///
/// Works for both POS transactions (`TRX-…`) and online orders (`WRG-…`) since
/// the web tracking route resolves both code formats.
class DownloadInvoiceButton extends StatelessWidget {
  /// Order/transaction code, e.g. `TRX-20260711-0001` or `WRG-20260630-0001`.
  final String code;

  const DownloadInvoiceButton({super.key, required this.code});

  Future<void> _openTracking(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(AppConstants.trackingUrl(code));

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showError(messenger);
      }
    } catch (_) {
      if (context.mounted) {
        _showError(messenger);
      }
    }
  }

  void _showError(ScaffoldMessengerState messenger) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Gagal membuka halaman invoice. Coba lagi.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openTracking(context),
        icon: const Icon(Icons.download_outlined, size: 20),
        label: const Text('Download Invoice'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
