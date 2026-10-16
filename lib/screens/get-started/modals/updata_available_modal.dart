import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

class UpdateAvailableModal extends StatelessWidget {
  final VoidCallback? onUpdate;
  final VoidCallback? onCancel;
  final String? version; // örn: "v1.3.0"
  final List<String>? highlights; // mini değişiklik listesi (opsiyonel)

  const UpdateAvailableModal({
    super.key,
    this.onUpdate,
    this.onCancel,
    this.version,
    this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    // Zemin (beyaz) ve 24 px köşe yarıçapı dialogTheme'den gelir.
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 750, maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık & Alt Başlık
              const Center(
                child: Column(
                  children: [
                    Text(
                      'New update available',
                      style: TextStyle(
                        fontSize: 20,
                        height: 26 / 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepCharcoal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Update the app now for the best experience',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.charcoalSoft,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bilgi Banner'ı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.peachTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconSquircle(
                      child: Icon(
                        Icons.system_update_rounded,
                        color: AppColors.activeBerry,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            version != null
                                ? "New version ready: ${version!}"
                                : "New version ready",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepCharcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Performance improvements, bug fixes, and new features for a smoother experience.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 18 / 13,
                              color: AppColors.charcoalSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Değişiklikler kutusu (opsiyonel)
              if (highlights != null && highlights!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.pinkTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 18,
                            color: AppColors.activeBerry,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "What's new in this update?",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepCharcoal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ...highlights!.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(
                                  top: 6,
                                  right: 10,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.activeBerry,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 18 / 13,
                                    color: AppColors.deepCharcoal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // "Şimdi mi?" sorusu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cosyIvory,
                  border: Border.all(color: AppColors.hairline),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 22,
                      color: AppColors.activeBerry,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Would you like to update now?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.deepCharcoal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Butonlar: ikincil tonal, birincil berry hap
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed:
                          onCancel ??
                          () {
                            Navigator.of(context).pop(false);
                          },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          onUpdate ??
                          () {
                            Navigator.of(context).pop(true);
                          },
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
