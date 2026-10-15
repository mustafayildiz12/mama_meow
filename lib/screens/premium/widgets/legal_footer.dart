import 'package:flutter/material.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:mama_meow/utils/platform_info.dart';
import 'package:mama_meow/utils/url_utils.dart';

/// Paywall altındaki yasal bağlantılar: Terms, Privacy ve (Android'de)
/// Manage Subscription.
class PaywallLegalFooter extends StatelessWidget {
  const PaywallLegalFooter({super.key});

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
    const linkStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );
    const separator = Icon(Icons.circle, size: 4);
    final termsUrl = _termsUrl;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (termsUrl != null) ...[
          TextButton(
            onPressed: () => _open(termsUrl),
            child: const Text("Terms", style: linkStyle),
          ),
          separator,
        ],
        TextButton(
          onPressed: () => _open(_privacyUrl),
          child: const Text("Privacy", style: linkStyle),
        ),
        if (PlatformInfo.isAndroid) ...[
          separator,
          TextButton(
            onPressed: () => _open(_playSubscriptionsUrl),
            child: const Text(
              "Manage Subscription",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
