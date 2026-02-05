import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warungku_app/core/theme/app_colors.dart';
import 'package:warungku_app/core/theme/app_spacing.dart';
import 'package:warungku_app/core/utils/formatters.dart';
import 'package:warungku_app/core/widgets/loading_widget.dart';
import '../providers/operating_hours_provider.dart';

class OperatingHoursScreen extends ConsumerStatefulWidget {
  const OperatingHoursScreen({super.key});

  @override
  ConsumerState<OperatingHoursScreen> createState() => _OperatingHoursScreenState();
}

class _OperatingHoursScreenState extends ConsumerState<OperatingHoursScreen> {
  // Local state for editing, initialized from provider state
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final operatingHoursAsync = ref.watch(operatingHoursProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jam Operasional',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: operatingHoursAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (operatingHours) {
          if (!_isInitialized) {
            _openTime = operatingHours.open;
            _closeTime = operatingHours.close;
            _isInitialized = true;
          }

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTimePicker(
                  context,
                  label: 'Jam Buka',
                  time: _openTime,
                  onTimeChanged: (newTime) {
                    setState(() {
                      _openTime = newTime;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _buildTimePicker(
                  context,
                  label: 'Jam Tutup',
                  time: _closeTime,
                  onTimeChanged: (newTime) {
                    setState(() {
                      _closeTime = newTime;
                    });
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: _isSaving 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text('Simpan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required TimeOfDay? time,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    final timeStr = time != null ? Formatters.formatTimeOfDay(time) : '--:--';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time ?? TimeOfDay.now(),
            );
            if (picked != null) {
              onTimeChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textSecondary),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeStr, style: Theme.of(context).textTheme.bodyLarge),
                const Icon(Icons.access_time),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    if (_openTime == null || _closeTime == null) return;

    // Validation: Open < Close
    final openMinutes = _openTime!.hour * 60 + _openTime!.minute;
    final closeMinutes = _closeTime!.hour * 60 + _closeTime!.minute;

    if (openMinutes >= closeMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam buka harus lebih awal dari jam tutup'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(operatingHoursProvider.notifier).saveOperatingHours(_openTime!, _closeTime!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil disimpan'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
