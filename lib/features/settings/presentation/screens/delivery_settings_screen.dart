import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../providers/delivery_settings_provider.dart';

class DeliverySettingsScreen extends ConsumerStatefulWidget {
  const DeliverySettingsScreen({super.key});

  @override
  ConsumerState<DeliverySettingsScreen> createState() => _DeliverySettingsScreenState();
}

class _DeliverySettingsScreenState extends ConsumerState<DeliverySettingsScreen> {
  final _phoneController = TextEditingController();
  bool _isDeliveryEnabled = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeData(bool enabled, String number) {
    if (!_isInitialized) {
      _isDeliveryEnabled = enabled;
      _phoneController.text = number;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(deliverySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery & WhatsApp'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: settingsAsync.when(
        data: (settings) {
          // If the provider updates (e.g. toggle switch), we need to reflect that.
          // However, we don't want to overwrite the text field if the user is typing.
          // But for the toggle, it should sync.
          if (_isInitialized && settings.isDeliveryEnabled != _isDeliveryEnabled) {
             _isDeliveryEnabled = settings.isDeliveryEnabled;
          }
          
          _initializeData(settings.isDeliveryEnabled, settings.whatsappNumber);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Section
                _buildSectionTitle('Delivery'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aktifkan Delivery',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Izinkan pembeli memilih opsi pengiriman',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isDeliveryEnabled,
                        onChanged: (value) {
                          // Update local state immediately for UI responsiveness
                          setState(() {
                            _isDeliveryEnabled = value;
                          });
                          // Call provider to update DB immediately
                          ref.read(deliverySettingsProvider.notifier).updateDeliveryStatus(value).catchError((e) {
                             if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text('Gagal mengubah status: $e')),
                               );
                               // Revert state if failed
                               setState(() {
                                 _isDeliveryEnabled = !value;
                               });
                             }
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),

                // WhatsApp Section
                _buildSectionTitle('WhatsApp Contact'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nomor WhatsApp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Contoh: 628123456789',
                          border: OutlineInputBorder(),
                          helperText: 'Gunakan format 62 (bukan 08)',
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => AppErrorWidget(message: error.toString()),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ), // uppercase removed as per style guide usually or keep simple
    );
  }

  void _saveSettings() {
    final number = _phoneController.text.trim();

    // Validation
    if (!number.startsWith('62')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor WhatsApp harus diawali dengan 62'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (number.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor WhatsApp terlalu pendek'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Save - saves both to be sure, but user knows toggle is immediate
    ref.read(deliverySettingsProvider.notifier).saveSettings(
      isEnabled: _isDeliveryEnabled,
      number: number,
    ).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil disimpan'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }).catchError((error) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }
}
