import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/screens/get-started/modals/update_baby_info_modal.dart';
import 'package:mama_meow/screens/get-started/modals/update_email_password.dart';
import 'package:mama_meow/screens/navigationbar/profile/baby_picture_storage.dart';
import 'package:mama_meow/screens/navigationbar/profile/widgets/profile_card.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/service/review_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Premium kartında listelenen özellikler.
const List<String> _premiumFeatures = [
  "Complete Baby Tracking",
  "Expert Podcast Library",
  "AI-Powered Assistant",
  "Priority support",
];

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: AppColors.cosyIvory,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  final ImagePicker _picker = ImagePicker();
  final BabyPictureStorage _pictureStorage = const BabyPictureStorage();
  final InAppPurchaseService _iap = InAppPurchaseService();
  StreamSubscription<User?>? _authSub;

  bool _isUserPremium = false;
  bool _authInitialized = false;
  bool _uploadingBabyPic = false;
  String _version = '';

  bool get _isGuest => authenticationService.getUser() == null;

  @override
  void initState() {
    super.initState();
    analyticService.screenView('profile_screen');
    // Sekme durumu korunduğu için giriş/çıkışta ekranı ve premium durumunu
    // yenile. İlk olay mevcut kullanıcıyla hemen gelir.
    _authSub = authenticationService.firebaseAuth.authStateChanges().listen(
      _onAuthChanged,
    );
    _iap.premiumNotifier.addListener(_onPremiumChanged);
    _loadVersion();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _iap.premiumNotifier.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onAuthChanged(User? user) {
    if (!mounted) return;
    final isInitial = !_authInitialized;
    _authInitialized = true;
    setState(() {});
    // Oturum içi girişte premium değişikliği premiumNotifier ile gelir
    // (bkz. AskMeowView._onAuthChanged).
    if (isInitial || user == null) {
      _checkUserPremium();
    } else {
      _onPremiumChanged();
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (e) {
      debugPrint('PackageInfo failed: $e');
    }
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    final premium = !_isGuest && _iap.premiumNotifier.value;
    if (premium != _isUserPremium) setState(() => _isUserPremium = premium);
  }

  Future<void> _checkUserPremium() async {
    var premium = false;
    if (!_isGuest) {
      try {
        premium = await _iap.isPremium();
      } catch (e) {
        debugPrint('isPremium failed: $e');
      }
    }
    if (mounted) setState(() => _isUserPremium = premium);
  }

  /// Misafir için giriş ekranını sekmelerin üstüne açar.
  void _openLogin() => context.pushNamed('login');

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: ColoredBox(
        color: AppColors.cosyIvory,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildBabyCard(),
                    if (currentMeowUser != null) ...[
                      const SizedBox(height: 20),
                      _buildPremiumCard(),
                    ],
                    const SizedBox(height: 20),
                    _buildShareCard(),
                    const SizedBox(height: 20),
                    _buildAboutCard(),
                    const SizedBox(height: 20),
                    _buildAccountCard(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          "Profile",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            height: 26 / 20,
            fontWeight: FontWeight.w800,
            color: AppColors.deepCharcoal,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Manage your Coo Care Baby Tracker account",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.charcoalSoft),
        ),
      ],
    );
  }

  /// Hesap kartı: kimlik bilgisi, giriş/çıkış ve hesap ayarları bağlantısı.
  Widget _buildAccountCard() {
    final isGuest = _isGuest;

    return ProfileCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openAccountSettings,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    const ProfileIconCircle(
                      icon: Icons.manage_accounts_outlined,
                      size: 44,
                      iconSize: 22,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGuest
                          ? "Guest User"
                          : (currentMeowUser?.userName ?? "User"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGuest
                          ? "Tap to login and save your progress"
                          : (currentMeowUser?.userEmail ?? ""),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.charcoalSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          isGuest
              ? FilledButton.tonalIcon(
                  onPressed: _openLogin,
                  icon: const Icon(
                    Icons.login_rounded,
                    color: AppColors.berryInk,
                  ),
                  label: const Text("Login / Sign Up"),
                )
              : FilledButton.tonalIcon(
                  onPressed: _logout,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.berryInk,
                  ),
                  label: const Text("Logout"),
                ),
          if (!isGuest) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _openAccountSettings,
                child: const Text(
                  "Update your information",
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// E-posta / şifre güncelleme ve hesap silme modalı (misafire giriş).
  Future<void> _openAccountSettings() async {
    if (_isGuest) {
      _openLogin();
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UpdateEmailPasswordInfoModal(),
    );
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    final isSuccess = await authenticationService.logoutFromFirebase();
    if (isSuccess && mounted) context.goNamed('login');
  }

  Widget _buildBabyPhoto() {
    final pic = (currentMeowUser?.babyPicture ?? "").trim();
    const placeholder = Center(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Image(image: AssetImage("assets/cat.png")),
      ),
    );

    return Semantics(
      button: true,
      label: _isGuest ? 'Sign in' : 'Change baby photo',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _uploadingBabyPic
            ? null
            : (_isGuest ? _openLogin : _showPickBabyPictureSheet),
        child: SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 4 px şeftali halka içinde yuvarlak fotoğraf
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.peachPastel,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: ColoredBox(
                    color: AppColors.pinkTint,
                    child: SizedBox.expand(
                      child: pic.isEmpty
                          ? placeholder
                          : CachedNetworkImage(
                              imageUrl: pic,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => placeholder,
                              errorWidget: (_, _, _) => placeholder,
                            ),
                    ),
                  ),
                ),
              ),

              if (_uploadingBabyPic)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.scrim,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cottonWhite,
                        ),
                      ),
                    ),
                  ),
                ),

              // sağ-alt köşede berry düzenleme rozeti
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.activeBerry,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cottonWhite, width: 2),
                    boxShadow: AppColors.berryGlow,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.cottonWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bebek bilgisini düzenleme modalını açar (misafire giriş).
  Future<void> _editBabyInfo() async {
    if (_isGuest) {
      _openLogin();
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UpdateBabyInfoModal(),
    );
    final user = currentMeowUser;
    if (saved != true || user == null) return;
    try {
      await databaseService.updateBaby(user);
    } catch (e) {
      debugPrint('updateBaby failed: $e');
      customSnackBar.error("Couldn't save your baby's info");
    }
    if (mounted) setState(() {});
  }

  Widget _buildBabyCard() {
    final babyName = (currentMeowUser?.babyName ?? "").trim();
    final ageRange = (currentMeowUser?.ageRange ?? "").trim();

    return ProfileCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        children: [
          _buildBabyPhoto(),
          const SizedBox(height: 12),
          // Ad ve bilgi satırları dokunulunca bebek bilgisi düzenlenir.
          Semantics(
            button: true,
            label: _isGuest ? 'Sign in' : 'Edit baby info',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _editBabyInfo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      babyName.isEmpty ? "?" : babyName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 32,
                        height: 38 / 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.deepCharcoal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          size: 20,
                          color: AppColors.activeBerry,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Age Range",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.charcoalSoft,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ageRange.isEmpty
                                ? const Text(
                                    "—",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.charcoalSoft,
                                    ),
                                  )
                                : _AgeRangePill(ageRange),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppColors.charcoalSoft,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    final premium = _isUserPremium;

    return TintCard(
      color: AppColors.peachTint,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconSquircle(
                size: 48,
                child: Icon(
                  premium
                      ? Icons.card_giftcard_rounded
                      : Icons.star_border_rounded,
                  size: 26,
                  color: AppColors.activeBerry,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Premium Features",
                      style: TextStyle(
                        fontSize: 20,
                        height: 26 / 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepCharcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final feature in _premiumFeatures)
                      _FeatureBullet(feature),
                  ],
                ),
              ),
            ],
          ),
          if (!premium) ...[
            const SizedBox(height: 20),
            PrimaryPillButton(
              label: "Be Premium",
              icon: Icons.arrow_forward_rounded,
              onPressed: _openPaywall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShareCard() {
    return ProfileCard(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (tileContext) => ProfileTile(
              icon: Icons.share_outlined,
              title: "Tell a friend",
              subtitle: "Share Coo Care Baby Tracker with other parents",
              onTap: () => globalFunctions.shareAppInvite(context: tileContext),
            ),
          ),
          const Divider(),
          ProfileTile(
            icon: Icons.favorite_border_rounded,
            title: "Rate Coo Care Baby Tracker",
            subtitle: "Love the app? Leave a quick review",
            onTap: () => reviewService.openStoreListing(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return const ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileIconCircle(icon: Icons.child_care_rounded),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "About Coo Care Baby Tracker",
                  style: TextStyle(
                    fontSize: 17,
                    height: 24 / 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepCharcoal,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "Coo Care Baby Tracker was created by parents, for parents. Our AI assistant Mia provides helpful guidance while you navigate the beautiful journey of parenthood.",
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: AppColors.charcoalSoft,
            ),
          ),
        ],
      ),
    );
  }

  /// Sürüm ve telif satırları.
  Widget _buildFooter() {
    const smallStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.charcoalSoft,
    );

    return Column(
      children: [
        if (_version.isNotEmpty) ...[
          Text(
            "Version $_version",
            textAlign: TextAlign.center,
            style: smallStyle,
          ),
          const SizedBox(height: 4),
        ],
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text:
                    "© ${DateTime.now().year} Coo Care Baby Tracker. Made with ",
              ),
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 12,
                  color: AppColors.activeBerry,
                  semanticLabel: 'love',
                ),
              ),
              const TextSpan(text: " for families."),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.charcoalSoft),
        ),
      ],
    );
  }

  Future<void> _showPickBabyPictureSheet() async {
    final hasPicture = (currentMeowUser?.babyPicture ?? "").isNotEmpty;
    // Zemin ve köşe yarıçapı temadan (bottomSheetTheme) gelir.
    final action = await showModalBottomSheet<_PictureAction>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Set baby photo",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.deepCharcoal,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const ProfileIconCircle(
                    icon: Icons.photo_library_outlined,
                  ),
                  title: const Text("Choose from gallery"),
                  onTap: () =>
                      Navigator.pop(sheetContext, _PictureAction.gallery),
                ),
                ListTile(
                  leading: const ProfileIconCircle(
                    icon: Icons.photo_camera_outlined,
                  ),
                  title: const Text("Take a photo"),
                  onTap: () =>
                      Navigator.pop(sheetContext, _PictureAction.camera),
                ),
                if (hasPicture)
                  ListTile(
                    leading: const ProfileIconCircle(
                      icon: Icons.delete_outline,
                      color: AppColors.berryInk,
                    ),
                    title: const Text(
                      "Remove photo",
                      style: TextStyle(color: AppColors.berryInk),
                    ),
                    onTap: () =>
                        Navigator.pop(sheetContext, _PictureAction.remove),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    switch (action) {
      case _PictureAction.gallery:
        await _pickAndUploadBabyPicture(ImageSource.gallery);
      case _PictureAction.camera:
        await _pickAndUploadBabyPicture(ImageSource.camera);
      case _PictureAction.remove:
        await _removeBabyPicture();
      case null:
        break;
    }
  }

  Future<void> _pickAndUploadBabyPicture(ImageSource source) async {
    final uid = currentMeowUser?.uid;
    if (uid == null) return;

    try {
      final XFile? xfile = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1024,
      );
      if (xfile == null || !mounted) return;

      setState(() => _uploadingBabyPic = true);
      final url = await _pictureStorage.upload(uid: uid, file: xfile);

      currentMeowUser = currentMeowUser?.copyWith(babyPicture: url);
      await databaseService.updateBabyPicture(currentMeowUser);
    } catch (e) {
      debugPrint("babyPicture upload error: $e");
      customSnackBar.error("Could not upload photo");
    } finally {
      if (mounted) setState(() => _uploadingBabyPic = false);
    }
  }

  Future<void> _removeBabyPicture() async {
    final uid = currentMeowUser?.uid;
    if (uid == null) return;

    setState(() => _uploadingBabyPic = true);
    try {
      await _pictureStorage.delete(uid);
      currentMeowUser = currentMeowUser?.copyWith(babyPicture: "");
      await databaseService.updateBabyPicture(currentMeowUser);
    } catch (e) {
      debugPrint("remove babyPicture error: $e");
      customSnackBar.error("Could not remove photo");
    } finally {
      if (mounted) setState(() => _uploadingBabyPic = false);
    }
  }

  Future<void> _openPaywall() async {
    final purchased = await context.pushNamed<bool>('premiumPaywall');
    if (purchased == true) await _checkUserPremium();
  }
}

enum _PictureAction { gallery, camera, remove }

/// Yaş aralığı değeri için pembe hap etiket.
class _AgeRangePill extends StatelessWidget {
  final String text;
  const _AgeRangePill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const ShapeDecoration(
        color: AppColors.pinkTint,
        shape: StadiumBorder(),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.berryInk,
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final String text;
  const _FeatureBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.activeBerry,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: AppColors.charcoalSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
