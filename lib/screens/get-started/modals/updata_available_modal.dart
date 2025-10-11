import 'package:flutter/material.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 750, maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
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
                      '✨ New Update Available',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEC4899),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Update the app now for the best experience',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  color: const Color(0xFFFFF1F5),
                  border: Border.all(color: Color(0xFFFBCFE8)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📦', style: TextStyle(fontSize: 30)),
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
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEC4899),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Performance improvements, bug fixes, and new features for a smoother experience.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Değişiklikler kutusu (opsiyonel)
              if (highlights != null && highlights!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF1F5), Color(0xFFF3E8FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFFBCFE8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "🔎 What's new in this update?",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEC4899),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...highlights!.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•  '),
                              Expanded(
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
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

              const SizedBox(height: 24),

              // "Şimdi mi?" sorusu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F5),
                  border: Border.all(color: Color(0xFFFBCFE8)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Text('⏱️', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Would you like to update now?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFEC4899),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFBCFE8),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed:
                          onCancel ??
                          () {
                            Navigator.of(context).pop(false);
                          },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFFEC4899),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF472B6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed:
                          onUpdate ??
                          () {
                            Navigator.of(context).pop(true);
                          },
                      child: const Text(
                        'Update',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
