import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/add_diaper_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/journal/journal_screen.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/add_medicine_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/add_nursing_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/add_pumping_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/sleep/add_sleep_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/add_solid_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/diaper_service.dart';
import 'package:mama_meow/service/activities/medicine_service.dart';
import 'package:mama_meow/service/activities/nursing_service.dart';
import 'package:mama_meow/service/activities/pumping_service.dart';
import 'package:mama_meow/service/activities/sleep_service.dart';
import 'package:mama_meow/service/activities/solid_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/permissions/alarm_policy.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

/// My Baby ekranındaki bir aktivite kartının tanımı.
class _ActivitySpec {
  const _ActivitySpec({
    required this.kind,
    required this.reportRoute,
    required this.countStream,
    required this.sheetBuilder,
  });

  /// Başlık, ikon ve kart zemini buradan gelir.
  final ActivityKind kind;
  final String reportRoute;

  /// Bugünkü kayıt sayısı (servis oturum ve gün değişimini kendisi izler).
  final Stream<int> Function() countStream;
  final WidgetBuilder sheetBuilder;
}

final List<_ActivitySpec> _activities = [
  _ActivitySpec(
    kind: ActivityKind.nursing,
    reportRoute: 'nursingReport',
    countStream: nursingService.todayNursingCountStream,
    sheetBuilder: (_) => const AddNursingBottomSheet(),
  ),
  _ActivitySpec(
    kind: ActivityKind.solid,
    reportRoute: 'solidReport',
    countStream: solidService.todaySolidCountStream,
    sheetBuilder: (_) => const AddSolidBottomSheet(),
  ),
  _ActivitySpec(
    kind: ActivityKind.sleep,
    reportRoute: 'sleepReport',
    countStream: sleepService.todaySleepCountStream,
    sheetBuilder: (_) => SleepExtendedMultiSliderBottomSheet(
      initialStartEnds: const [12 * 60, 15 * 60],
      sleepDate: DateTime.now(),
    ),
  ),
  _ActivitySpec(
    kind: ActivityKind.diaper,
    reportRoute: 'diaperReport',
    countStream: diaperService.todayDiaperCountStream,
    sheetBuilder: (_) => const AddDiaperBottomSheet(),
  ),
  _ActivitySpec(
    kind: ActivityKind.pumping,
    reportRoute: 'pumpingReport',
    countStream: pumpingService.todayPumpingCountStream,
    sheetBuilder: (_) => const AddPumpingBottomSheet(),
  ),
  _ActivitySpec(
    kind: ActivityKind.medicine,
    reportRoute: 'medicineReport',
    countStream: medicineService.todayMedicineCountStream,
    sheetBuilder: (_) => AddMedicineBottomSheet(selectedDate: DateTime.now()),
  ),
];

/// Kart içi küçük ikincil metin (sayaç, açıklama).
const TextStyle _metaStyle = TextStyle(
  fontSize: 13,
  height: 18 / 13,
  fontWeight: FontWeight.w600,
  color: AppColors.charcoalSoft,
);

class MyBabyScreen extends StatefulWidget {
  const MyBabyScreen({super.key});

  @override
  State<MyBabyScreen> createState() => _MyBabyScreenState();
}

class _MyBabyScreenState extends State<MyBabyScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    analyticService.screenView('my_baby_screen');
    updateTopUi();
    WidgetsBinding.instance.addObserver(this);
    AlarmPolicy.instance.refresh(); // sessiz kontrol
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AlarmPolicy.instance.refresh();
    }
  }

  void updateTopUi() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Theme.of(context).scaffoldBackgroundColor,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );
    });
  }

  Future<void> _openJournal() async {
    if (authenticationService.getUser() == null) {
      context.pushNamed("login");
      return;
    }
    await showActivitySheet(context, (_) => const JournalDiaryPage());
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cosyIvory,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const _BabyHeader(),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Quick log'),
            const SizedBox(height: 12),
            const _ActivityGrid(),
            const SizedBox(height: 12),
            _JournalTile(onTap: _openJournal),
            const SizedBox(height: 24),
            const _TipOfTheDay(),
          ],
        ),
      ),
    );
  }
}

/// Bebek fotoğrafı, günün saatine göre selamlama ve "ad · yaş aralığı" başlığı.
class _BabyHeader extends StatelessWidget {
  const _BabyHeader();

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String _title() {
    final name = currentMeowUser?.babyName?.trim() ?? '';
    final age = currentMeowUser?.ageRange?.trim() ?? '';
    if (name.isEmpty) return 'My Baby';
    return age.isEmpty ? name : '$name · $age';
  }

  @override
  Widget build(BuildContext context) {
    // currentMeowUser bir global (dinlenebilir değil). Sekme ya da üstteki
    // sayfa (ör. login) değişip ekran yeniden görünür olduğunda TickerMode
    // değişir; bu bağımlılık sayesinde başlık güncel bilgiyle yeniden çizilir.
    TickerMode.valuesOf(context);

    return Row(
      children: [
        _BabyAvatar(url: currentMeowUser?.babyPicture?.trim() ?? ''),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(DateTime.now()), style: _metaStyle),
              const SizedBox(height: 2),
              Text(
                _title(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 56 px yuvarlak bebek fotoğrafı (şeftali halkalı); yoksa ikon.
class _BabyAvatar extends StatelessWidget {
  const _BabyAvatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const fallback = IconSquircle(
      background: AppColors.pinkTint,
      size: 50,
      radius: 25,
      child: Icon(Icons.child_care, size: 28, color: AppColors.activeBerry),
    );

    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: AppColors.peachPastel,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

/// Altı aktivite kartı, iki sütun. Satırlar Row ile kurulur; böylece kart
/// yüksekliği yazı boyutuna göre büyür ve taşma olmaz.
class _ActivityGrid extends StatelessWidget {
  const _ActivityGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _activities.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ActivityTile(spec: _activities[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < _activities.length
                    ? _ActivityTile(spec: _activities[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Bugünkü sayaçlı aktivite kartı: gövde rapora, "+" ekleme sheet'ine gider.
class _ActivityTile extends StatefulWidget {
  const _ActivityTile({required this.spec});

  final _ActivitySpec spec;

  @override
  State<_ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<_ActivityTile> {
  // Kart her oluşturulduğunda taze stream; ListView kartı yeniden
  // oluşturduğunda tek-abonelik stream'i iki kez dinleme hatası olmaz.
  late final Stream<int> _count = widget.spec.countStream();

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final kind = spec.kind;

    return TintCard(
      color: kind.tileColor,
      padding: const EdgeInsets.all(16),
      onTap: () => context.pushNamed(spec.reportRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconSquircle(child: ActivityIcon(kind: kind)),
              const Spacer(),
              _RoundAddButton(
                tooltip: 'Add ${kind.label.toLowerCase()}',
                onPressed: () => showActivitySheet(context, spec.sheetBuilder),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            kind.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          StreamBuilder<int>(
            stream: _count,
            builder: (context, snapshot) => Text(
              '${snapshot.data ?? 0} today',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _metaStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// 40 px yuvarlak "+" butonu (dokunma alanı 48 px).
class _RoundAddButton extends StatelessWidget {
  const _RoundAddButton({
    required this.tooltip,
    required this.onPressed,
    this.background = AppColors.activeBerry,
    this.foreground = AppColors.cottonWhite,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        padding: EdgeInsets.zero,
      ),
      icon: const Icon(Icons.add, size: 22),
    );
  }
}

class _JournalTile extends StatelessWidget {
  const _JournalTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TintCard(
      color: ActivityKind.journal.tileColor,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          const IconSquircle(
            child: ActivityIcon(kind: ActivityKind.journal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ActivityKind.journal.label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Text("Write today's little story", style: _metaStyle),
              ],
            ),
          ),
          _RoundAddButton(
            tooltip: 'Open journal',
            onPressed: onTap,
            background: AppColors.cottonWhite,
            foreground: AppColors.activeBerry,
          ),
        ],
      ),
    );
  }
}

class _TipOfTheDay extends StatelessWidget {
  const _TipOfTheDay();

  @override
  Widget build(BuildContext context) {
    return TintCard(
      color: AppColors.peachTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: AppColors.activeBerry),
              SizedBox(width: 6),
              Text(
                'AI TIP FOR TODAY',
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.berryInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Feeding cues',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Babies typically need 8-12 feedings per day. Watch for hunger '
            'cues like rooting or sucking motions!',
            style: TextStyle(
              fontSize: 15,
              height: 22 / 15,
              color: AppColors.deepCharcoal,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.goNamed('askMeow'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cottonWhite,
              foregroundColor: AppColors.berryInk,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              side: const BorderSide(color: AppColors.hairline),
              textStyle: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(
              Icons.chat_bubble_outline,
              size: 18,
              color: AppColors.activeBerry,
            ),
            label: const Text('Ask Meow'),
          ),
        ],
      ),
    );
  }
}
