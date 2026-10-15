import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/screens/get-started/widgets/baby_info_form.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';

/// Kayıt / ilk sosyal giriş sonrası bebek bilgisini soran modal.
/// Kaydedilirse `true` ile kapanır ve [currentMeowUser] güncellenir.
class BabyInfoModal extends StatelessWidget {
  const BabyInfoModal({super.key});

  /// Modalı gösterir ve onaylanırsa bilgiyi veritabanına yazar.
  static Future<void> showAndSave(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BabyInfoModal(),
    );
    final user = currentMeowUser;
    if (saved != true || user == null) return;
    try {
      await databaseService.updateBaby(user);
    } catch (e) {
      debugPrint('BabyInfoModal save failed: $e');
      customSnackBar.error(
        "Couldn't save your baby's info. You can update it later in Profile.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BabyInfoForm(
      onSubmit: (babyName, ageRange) {
        analyticService.onboardingComplete();
        currentMeowUser = currentMeowUser?.copyWith(
          babyName: babyName,
          ageRange: ageRange,
        );
        Navigator.pop(context, true);
      },
    );
  }
}
