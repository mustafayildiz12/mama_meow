import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _textDark = Color(0xFF1F2937);
const _textMuted = Color(0xFF6B7280);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Color(0xFFEEF2FF),
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
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFF3E8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildMiaHead(),
                  const SizedBox(height: 8),
                  const Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const Text(
                    "Manage your Coo Care Baby Tracker account",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 16),
                  _buildUserInfoCard(),
                  _buildBabyCard(),
                  _buildShareCard(),
                  _buildAboutCard(),
                  _buildPremiumCard(),
                  _buildSettingsCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return ProfileCard(
      child: Center(
        child: _isGuest
            ? ElevatedButton.icon(
                onPressed: _openLogin,
                icon: const Icon(Icons.login),
                label: const Text("Login / Sign Up"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink500,
                  foregroundColor: Colors.white,
                ),
              )
            : OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_outlined),
                label: const Text("Logout"),
              ),
      ),
    );
  }

  Future<void> _logout() async {
    final isSuccess = await authenticationService.logoutFromFirebase();
    if (isSuccess && mounted) context.goNamed('login');
  }

  Widget _buildMiaHead() {
    final pic = (currentMeowUser?.babyPicture ?? "").trim();
    const placeholder = Center(
      child: Image(image: AssetImage("assets/cat.png")),
    );

    return Semantics(
      button: true,
      label: _isGuest ? 'Sign in' : 'Change baby photo',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _uploadingBabyPic
            ? null
            : (_isGuest ? _openLogin : _showPickBabyPictureSheet),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.pink200, AppColors.pink300],
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              clipBehavior: Clip.antiAlias,
              child: pic.isEmpty
                  ? placeholder
                  : CachedNetworkImage(
                      imageUrl: pic,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => placeholder,
                      errorWidget: (_, _, _) => placeholder,
                    ),
            ),

            // sağ-alt köşeye küçük edit ikonu
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6),
                  ],
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.pink),
              ),
            ),

            if (_uploadingBabyPic)
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final isGuest = _isGuest;

    return ProfileCard(
      onTap: () async {
        if (isGuest) {
          _openLogin();
          return;
        }
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const UpdateEmailPasswordInfoModal(),
        );
        if (mounted) setState(() {});
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest
                      ? "Guest User"
                      : (currentMeowUser?.userName ?? "User"),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                Text(
                  isGuest
                      ? "Tap to login and save your progress"
                      : (currentMeowUser?.userEmail ?? ""),
                  style: const TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.pink500,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildBabyCard() {
    const labelStyle = TextStyle(
      fontWeight: FontWeight.w800,
      color: Colors.black87,
    );
    const valueStyle = TextStyle(
      fontWeight: FontWeight.w500,
      color: Colors.black87,
      fontSize: 12,
    );

    return ProfileCard(
      onTap: () async {
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
      },
      child: Row(
        children: [
          SvgPicture.asset("assets/baby.svg"),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("Baby Name: ", style: labelStyle),
                    Expanded(
                      child: Text(
                        currentMeowUser?.babyName ?? "?",
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Age Range: ", style: labelStyle),
                    Expanded(
                      child: Text(
                        currentMeowUser?.ageRange ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.pink500,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    if (currentMeowUser == null) return const SizedBox();

    return ProfileCard(
      child: _isUserPremium
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 20,
                      color: Color(0xFF16A34A),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Premium Features",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _FeatureBullet("Complete Baby Tracking"),
                _FeatureBullet("Expert Podcast Library"),
                _FeatureBullet("AI-Powered Assistant"),
                _FeatureBullet("Priority support"),
              ],
            )
          : Center(
              child: Semantics(
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: _openPaywall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Be Premium",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildShareCard() {
    const titleStyle = TextStyle(fontWeight: FontWeight.w600, color: _textDark);

    return ProfileCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (tileContext) => ListTile(
              leading: const Icon(
                Icons.favorite_border,
                color: AppColors.pink500,
              ),
              title: const Text("Tell a friend", style: titleStyle),
              subtitle: const Text(
                "Share Coo Care Baby Tracker with other parents 🐾",
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => globalFunctions.shareAppInvite(context: tileContext),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.star_border, color: Color(0xFFF59E0B)),
            title: const Text("Rate Coo Care Baby Tracker", style: titleStyle),
            subtitle: const Text("Love the app? Leave a quick review"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => reviewService.openStoreListing(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    const smallStyle = TextStyle(fontSize: 11, color: Color(0xFF9CA3AF));

    return ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite, size: 20, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  "About Coo Care Baby Tracker",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Coo Care Baby Tracker was created by parents, for parents. Our AI assistant Mia provides helpful guidance while you navigate the beautiful journey of parenthood.",
            style: TextStyle(fontSize: 13, color: _textMuted),
          ),
          const SizedBox(height: 8),
          if (_version.isNotEmpty) Text("Version $_version", style: smallStyle),
          Text(
            "© ${DateTime.now().year} Coo Care Baby Tracker. Made with 💖 for families.",
            style: smallStyle,
          ),
        ],
      ),
    );
  }

  Future<void> _showPickBabyPictureSheet() async {
    final hasPicture = (currentMeowUser?.babyPicture ?? "").isNotEmpty;
    final action = await showModalBottomSheet<_PictureAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
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
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Set baby photo",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text("Choose from gallery"),
                  onTap: () =>
                      Navigator.pop(sheetContext, _PictureAction.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text("Take a photo"),
                  onTap: () =>
                      Navigator.pop(sheetContext, _PictureAction.camera),
                ),
                if (hasPicture)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      "Remove photo",
                      style: TextStyle(color: Colors.red),
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

class _FeatureBullet extends StatelessWidget {
  final String text;
  const _FeatureBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF4ADE80),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
