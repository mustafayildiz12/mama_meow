import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:mama_meow/utils/platform_info.dart';
import 'package:mama_meow/utils/url_utils.dart';

/// Paywall altındaki yasal bağlantılar: Terms, Privacy, (verilirse) About
/// Subscriptions ve (Android'de) Manage Subscription; aralarında "·".
class PaywallLegalFooter extends StatelessWidget {
  const PaywallLegalFooter({super.key, this.onAboutSubscriptions});

  /// Abonelik bilgi diyaloğunu açar; null ise bağlantı gösterilmez.
  final VoidCallback? onAboutSubscriptions;

  static const _privacyUrl =
      "https://kuyumcu-fd31a.firebaseapp.com/#/mamaMeowPolicy";
  static const _playSubscriptionsUrl =
      "https://play.google.com/store/account/subscriptions";

  /// Platform mağazasının kullanım koşulları; desteklenmeyen platformda null.
  static String? get _termsUrl {
    if (PlatformInfo.isIOS) {
      return "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";
    }
    if (PlatformInfo.isAndroid) {
      return "https://play.google.com/intl/ALL_tr/about/play-terms/";
    }
    return null;
  }

  static Future<void> _open(String url) async {
    if (!await UrlUtils.openExternal(url)) {
      customSnackBar.warning("Couldn't open this link");
    }
  }

  @override
  Widget build(BuildContext context) {
    final termsUrl = _termsUrl;
    final about = onAboutSubscriptions;
    final links = <Widget>[
      if (termsUrl != null) _FooterLink("Terms", () => _open(termsUrl)),
      _FooterLink("Privacy", () => _open(_privacyUrl)),
      if (about != null) _FooterLink("About Subscriptions", about),
      if (PlatformInfo.isAndroid)
        _FooterLink("Manage Subscription", () => _open(_playSubscriptionsUrl)),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < links.length; i++) ...[
          if (i > 0)
            const Text(
              "·",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoalSoft,
              ),
            ),
          links[i],
        ],
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.charcoalSoft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(40, 40),
        textStyle: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}
