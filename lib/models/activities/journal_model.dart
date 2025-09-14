class JournalModel {
  final String noteText;
  final String createdAt; // ISO format timestamp
  final String noteDate; // yyyy-MM-dd format for grouping
  final String noteId; // unique identifier

  JournalModel({
    required this.noteText,
    required this.createdAt,
    required this.noteDate,
    required this.noteId,
  }) : assert(noteText.isNotEmpty && noteText.length <= 500, 
              'Note text must be between 1 and 500 characters');

  factory JournalModel.fromJson(Map<String, dynamic> json) {
    return JournalModel(
      noteText: json['noteText'],
      createdAt: json['createdAt'],
      noteDate: json['noteDate'],
      noteId: json['noteId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noteText': noteText,
      'createdAt': createdAt,
      'noteDate': noteDate,
      'noteId': noteId,
    };
  }

  /// Creates a new JournalModel with current timestamp
  factory JournalModel.create({required String noteText}) {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    
    return JournalModel(
      noteText: noteText,
      createdAt: now.toIso8601String(),
      noteDate: _formatDate(now),
      noteId: timestamp,
    );
  }

  /// Formats DateTime to yyyy-MM-dd string
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  /// Gets formatted time for display (HH:mm)
  String get formattedTime {
    final dateTime = DateTime.parse(createdAt);
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}