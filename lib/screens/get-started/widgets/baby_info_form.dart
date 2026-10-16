import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/auth/widgets/auth_text_field.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

/// Bebek yaş aralığı seçenekleri. Boş değer "seçilmedi" anlamına gelir.
const List<String> babyAgeOptions = [
  '',
  'Newborn (0-3 months)',
  'Infant (3-12 months)',
  'Toddler (1-3 years)',
  'Preschooler (3-5 years)',
  'School age (5+ years)',
  'Expecting mama 🤱',
];

/// Bebek adı + yaş aralığı formu (diyalog olarak). Hem kayıt sonrası
/// ([BabyInfoModal]) hem profilden güncelleme ([UpdateBabyInfoModal]) bunu
/// kullanır.
class BabyInfoForm extends StatefulWidget {
  const BabyInfoForm({
    super.key,
    this.initialName,
    this.initialAgeRange,
    required this.onSubmit,
    this.onBack,
  });

  final String? initialName;
  final String? initialAgeRange;

  /// Devam'a basıldığında (trim'lenmiş ad, seçili yaş aralığı).
  final void Function(String babyName, String? ageRange) onSubmit;

  /// Verilirse "Back" düğmesi gösterilir.
  final VoidCallback? onBack;

  @override
  State<BabyInfoForm> createState() => _BabyInfoFormState();
}

class _BabyInfoFormState extends State<BabyInfoForm> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialName ?? '',
  );

  // Listede olmayan eski bir değer dropdown'ı kırmasın.
  late String? _selectedAge = babyAgeOptions.contains(widget.initialAgeRange)
      ? widget.initialAgeRange
      : null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() => widget.onSubmit(_nameController.text.trim(), _selectedAge);

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.deepCharcoal,
    );
    const fieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

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
              const Text(
                'Tell me about your little one',
                style: TextStyle(
                  fontSize: 20,
                  height: 26 / 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepCharcoal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Let's personalize Coo Care Baby Tracker for your family",
                style: TextStyle(fontSize: 14, color: AppColors.charcoalSoft),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const _IntroBox(),
              const SizedBox(height: 24),

              const Text("Baby's name", style: labelStyle),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _nameController,
                maxLength: 30,
                hintText: "Enter your baby's name...",
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                contentPadding: fieldPadding,
              ),
              const SizedBox(height: 4),
              const Text(
                'You can always change this later in settings',
                style: TextStyle(fontSize: 12, color: AppColors.charcoalSoft),
              ),
              const SizedBox(height: 24),

              const Text("Baby's age (optional)", style: labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedAge,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: AppColors.cottonWhite,
                decoration: AuthTextField.decoration(
                  contentPadding: fieldPadding,
                ),
                hint: const Text('Select age range...'),
                items: [
                  for (final age in babyAgeOptions)
                    DropdownMenuItem(
                      value: age,
                      child: Text(age.isEmpty ? 'Select age range...' : age),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedAge = value),
              ),

              const SizedBox(height: 24),
              const _BenefitsBox(),
              const SizedBox(height: 24),

              if (widget.onBack != null)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: widget.onBack,
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Continue'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroBox extends StatelessWidget {
  const _IntroBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.peachTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconSquircle(child: ActivityIcon(kind: ActivityKind.nursing)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What's your baby's name?",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepCharcoal,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This helps me give more personalized advice and suggestions tailored to your little one',
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
    );
  }
}

class _BenefitsBox extends StatelessWidget {
  const _BenefitsBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pinkTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'With this info, I can help you with:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.deepCharcoal,
            ),
          ),
          SizedBox(height: 12),
          _BenefitRow(
            icon: Icons.event_outlined,
            text: 'Age-appropriate milestone tracking',
          ),
          _BenefitRow(
            icon: Icons.restaurant_outlined,
            text: 'Personalized feeding schedules',
          ),
          _BenefitRow(
            icon: Icons.bedtime_outlined,
            text: 'Customized sleep routines',
          ),
          _BenefitRow(
            icon: Icons.palette_outlined,
            text: 'Fun activities for your little one',
          ),
        ],
      ),
    );
  }
}

/// Fayda listesinde berry çizgi ikonlu tek satır.
class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.activeBerry),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.deepCharcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
