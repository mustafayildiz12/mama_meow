import 'package:flutter/material.dart';

class MealPlansPage extends StatelessWidget {
  const MealPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFAF0), Color(0xFFFFF3CD)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.restaurant_menu,
                size: 48,
                color: Color(0xFFFB923C),
              ),
              const SizedBox(height: 8),
              const Text(
                "Meal Plans",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                "Nutrition guidance for your baby",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Baby's Age",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ageButton("0-6mo"),
                        _ageButton("6-8mo", selected: true),
                        _ageButton("9-12mo"),
                        _ageButton("12+mo"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _mealCard("6-8 Months: First Foods", [
                _mealBlock("Breakfast", [
                  "Iron-fortified cereal",
                  "Pureed fruits (banana, apple)",
                  "Breast milk or formula",
                ]),
                _mealBlock("Lunch", [
                  "Pureed vegetables (sweet potato, carrots)",
                  "Soft finger foods",
                  "Breast milk or formula",
                ]),
                _mealBlock("Dinner", [
                  "Pureed meats or beans",
                  "Mashed vegetables",
                  "Breast milk or formula",
                ]),
                _mealBlock("Snacks", ["Breast milk or formula between meals"]),
              ]),
              const SizedBox(height: 16),
              _tipsCard("Feeding Tips", [
                "Start with single-ingredient foods",
                "Introduce new foods one at a time",
                "Let baby self-feed with appropriate finger foods",
              ]),
              const SizedBox(height: 16),
              _safetyCard(),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Remember: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            "Every baby is different. These are general guidelines. Always consult with your pediatrician for personalized advice.",
                      ),
                    ],
                  ),
                  style: TextStyle(fontSize: 13, color: Color(0xFFFB923C)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ageButton(String label, {bool selected = false}) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF97316) : const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFFB923C),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _mealCard(String title, List<Widget> sections) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.child_friendly, color: Color(0xFFFB923C)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sections,
        ],
      ),
    );
  }

  Widget _mealBlock(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFFB923C), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (e) => Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFB923C),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    e,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipsCard(String title, List<String> tips) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tip,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFFFCA5A5), width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "⚠️ Safety Reminders",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFFB91C1C),
            ),
          ),
          SizedBox(height: 12),
          Text(
            "• Always supervise your baby during feeding",
            style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
          ),
          Text(
            "• Cut foods to appropriate sizes to prevent choking",
            style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
          ),
          Text(
            "• Introduce new foods one at a time",
            style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
          ),
          Text(
            "• Watch for allergic reactions",
            style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
          ),
          Text(
            "• Consult your pediatrician before starting solids",
            style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
