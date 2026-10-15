import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
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

/// My Baby ekranındaki bir aktivite kartının tanımı.
class _ActivitySpec {
  const _ActivitySpec({
    required this.emoji,
    required this.title,
    required this.colors,
    required this.textColor,
    required this.reportRoute,
    required this.countStream,
    required this.sheetBuilder,
  });

  final String emoji;
  final String title;
  final List<Color> colors;
  final Color textColor;
  final String reportRoute;

  /// Bugünkü kayıt sayısı (servis oturum ve gün değişimini kendisi izler).
  final Stream<int> Function() countStream;
  final WidgetBuilder sheetBuilder;
}

final List<_ActivitySpec> _activities = [
  _ActivitySpec(
    emoji: '🍼',
    title: 'Nursing',
    colors: const [Color(0xFFFF9AA2), Color(0xFFFFB3BA)],
    textColor: Colors.green.shade700,
    reportRoute: 'nursingReport',
    countStream: nursingService.todayNursingCountStream,
    sheetBuilder: (_) => const AddNursingBottomSheet(),
  ),
  _ActivitySpec(
    emoji: '🍛',
    title: 'Solid',
    colors: const [Color(0xFFA8E6CF), Color(0xFF88D8C0)],
    textColor: Colors.orange.shade700,
    reportRoute: 'solidReport',
    countStream: solidService.todaySolidCountStream,
    sheetBuilder: (_) => const AddSolidBottomSheet(),
  ),
  _ActivitySpec(
    emoji: '😴',
    title: 'Sleep',
    colors: [Colors.blue.shade200, Colors.purple.shade200],
    textColor: Colors.blue.shade700,
    reportRoute: 'sleepReport',
    countStream: sleepService.todaySleepCountStream,
    sheetBuilder: (_) => SleepExtendedMultiSliderBottomSheet(
      initialStartEnds: const [12 * 60, 15 * 60],
      sleepDate: DateTime.now(),
    ),
  ),
  _ActivitySpec(
    emoji: '👶',
    title: 'Diaper',
    colors: [Colors.green.shade200, Colors.tealAccent.shade200],
    textColor: Colors.green.shade700,
    reportRoute: 'diaperReport',
    countStream: diaperService.todayDiaperCountStream,
    sheetBuilder: (_) => const AddDiaperBottomSheet(),
  ),
  _ActivitySpec(
    emoji: '👩‍🍼',
    title: 'Pumping',
    colors: const [Color(0xFFFFCAB0), Color(0xFFFFD3A5)],
    textColor: Colors.pink.shade700,
    reportRoute: 'pumpingReport',
    countStream: pumpingService.todayPumpingCountStream,
    sheetBuilder: (_) => const AddPumpingBottomSheet(),
  ),
  _ActivitySpec(
    emoji: '💊',
    title: 'Medicine',
    colors: const [Color(0xFFB5E2D6), Color(0xFFA8D5BA)],
    textColor: Colors.red.shade700,
    reportRoute: 'medicineReport',
    countStream: medicineService.todayMedicineCountStream,
    sheetBuilder: (_) => AddMedicineBottomSheet(selectedDate: DateTime.now()),
  ),
];

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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 12),
                SvgPicture.asset("assets/baby.svg", width: 64, height: 64),
                const SizedBox(height: 8),
                const Text(
                  "My Baby 👶",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "I may be small, but my stories are big! Don't miss a meowment! 🐾✨",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          for (final spec in _activities) ...[
            _ActivityCard(spec: spec),
            const SizedBox(height: 16),
          ],
          _JournalCard(onTap: _openJournal),
          const SizedBox(height: 32),
          const _TipOfTheDay(),
        ],
      ),
    );
  }
}

/// Bugünkü sayaçlı aktivite kartı (rapor + ekle butonları).
class _ActivityCard extends StatefulWidget {
  const _ActivityCard({required this.spec});

  final _ActivitySpec spec;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  // Kart her oluşturulduğunda taze stream; ListView kartı yeniden
  // oluşturduğunda tek-abonelik stream'i iki kez dinleme hatası olmaz.
  late final Stream<int> _count = widget.spec.countStream();

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final textColor = spec.textColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: spec.colors),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(spec.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spec.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  StreamBuilder<int>(
                    stream: _count,
                    builder: (context, snapshot) => Text(
                      'Today: ${snapshot.data ?? 0} times',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => context.pushNamed(spec.reportRoute),
                  icon: Icon(Icons.bar_chart, color: textColor),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () =>
                      showActivitySheet(context, spec.sheetBuilder),
                  icon: Icon(Icons.add, color: textColor, size: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  const _JournalCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade100, Colors.indigo.shade200],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📔', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Text(
              'Journal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipOfTheDay extends StatelessWidget {
  const _TipOfTheDay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow.shade100, Colors.orange.shade100],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Tips for Today',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amberAccent, width: 2),
            ),
            child: const Text(
              '💡 Tip of the day: Babies typically need 8-12 feedings per day. Watch for hunger cues like rooting or sucking motions!',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
