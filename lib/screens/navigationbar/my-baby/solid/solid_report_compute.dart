class SolidReportComputed {
  final int totalAmount;
  final int mealCount;
  final String lastEatTime;

  final Map<String, int> distEatHourAmount; // "00".."23" -> amount
  final Map<String, int> byFoodAmount; // solidName -> amount
  final Map<String, int> reactionCounts; // reactionText -> count

  SolidReportComputed({
    required this.totalAmount,
    required this.mealCount,
    required this.lastEatTime,
    required this.distEatHourAmount,
    required this.byFoodAmount,
    required this.reactionCounts,
  });
}
