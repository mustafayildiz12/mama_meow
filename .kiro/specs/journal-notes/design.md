# Design Document

## Overview

The journal notes feature extends the existing journal screen with comprehensive note-taking functionality. It follows the established patterns in the codebase for models, services, and UI components while integrating seamlessly with Firebase Realtime Database. The design maintains visual consistency with existing activity cards and provides an intuitive multi-step note creation process.

## Architecture

### Data Flow
```
User Input → JournalService → Firebase Realtime Database → Stream → UI Updates
```

### Component Hierarchy
```
JournalPage (existing)
├── Note Creation Interface (new)
│   ├── AddJournalNoteBottomSheet
│   └── Multi-step Note Form
├── Notes Display Section (new)
│   ├── Today's Notes List
│   └── Individual Note Cards
└── Summary Cards (existing - enhanced with colors)
```

### Firebase Database Structure
```
journal/
  {userId}/
    {timestamp}/
      noteText: string
      createdAt: string (ISO format)
      noteDate: string (yyyy-MM-dd)
      noteId: string
```

## Components and Interfaces

### JournalModel
Following the pattern established in `SleepModel`, the journal model will be simple and focused:

```dart
class JournalModel {
  final String noteText;
  final String createdAt; // ISO format timestamp
  final String noteDate; // yyyy-MM-dd format for grouping
  final String noteId;   // unique identifier

  JournalModel({
    required this.noteText,
    required this.createdAt,
    required this.noteDate,
    required this.noteId,
  });

  factory JournalModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### JournalService
Following the pattern from `SleepService`, implementing:

```dart
class JournalService {
  // Add new journal note
  Future<void> addJournalNote(JournalModel note);
  
  // Get all notes for a specific date
  Future<List<JournalModel>> getNotesForDate(String date);
  
  // Stream of today's note count (for summary card)
  Stream<int> todayNoteCountStream();
  
  // Stream of today's notes (for real-time display)
  Stream<List<JournalModel>> todayNotesStream();
}
```

### UI Components

#### AddJournalNoteBottomSheet
A multi-step bottom sheet following the pattern of existing bottom sheets:
- Step 1: Note text input with validation
- Step 2: Confirmation and save
- Consistent styling with other activity bottom sheets

#### Enhanced JournalPage
Updates to the existing journal screen:
- Add note creation interface
- Display today's notes in chronological order
- Update summary cards with matching gradient colors
- Real-time updates using streams

#### Note Display Cards
Individual note cards showing:
- Note text content
- Creation timestamp
- Consistent styling with activity cards

## Data Models

### JournalModel Properties
- `noteText`: The main content of the journal entry (required, 1-500 characters)
- `createdAt`: ISO timestamp for precise ordering and display
- `noteDate`: Date string for grouping and filtering (yyyy-MM-dd format)
- `noteId`: Unique identifier for the note (timestamp-based)

### Validation Rules
- Note text: Required, minimum 1 character, maximum 500 characters
- Automatic timestamp generation on creation
- Automatic date extraction from timestamp

## Error Handling

### Firebase Integration
- Network connectivity errors with user-friendly messages
- Database write failures with retry mechanisms
- Stream connection errors with automatic reconnection

### User Input Validation
- Empty note text prevention
- Character limit enforcement with visual feedback
- Form validation before submission

### UI Error States
- Loading states during note creation
- Error messages for failed operations
- Empty states when no notes exist

## Testing Strategy

### Unit Tests
- JournalModel serialization/deserialization
- JournalService Firebase operations
- Input validation logic
- Date formatting and filtering

### Widget Tests
- AddJournalNoteBottomSheet user interactions
- Note display components
- Form validation feedback
- Stream-based UI updates

### Integration Tests
- End-to-end note creation flow
- Real-time updates across multiple sessions
- Firebase database operations
- Error handling scenarios

## Visual Design Integration

### Color Scheme
Using the purple gradient theme from my_baby_screen.dart:
```dart
gradient: LinearGradient(
  colors: [Colors.purple.shade100, Colors.indigo.shade200],
),
textColor: Colors.purple.shade600,
bgColor: Colors.purple.shade50,
```

### Summary Card Updates
The existing journal summary cards in the journal screen will be updated to use the same gradient colors as the journal card in my_baby_screen.dart, ensuring visual consistency.

### Typography and Spacing
- Following existing text styles from the theme
- Consistent padding and margins with other activity cards
- Icon usage matching the existing lucide_icons pattern

## Performance Considerations

### Stream Optimization
- Efficient Firebase queries using date-based filtering
- Proper stream disposal to prevent memory leaks
- Debounced real-time updates to prevent excessive rebuilds

### Data Efficiency
- Minimal data structure to reduce Firebase costs
- Efficient date-based indexing for quick retrieval
- Pagination consideration for future scalability

## Security and Privacy

### Firebase Rules
- User-specific data access (journal/{userId}/)
- Authenticated user requirements
- Read/write permissions based on user ownership

### Data Validation
- Server-side validation through Firebase rules
- Client-side validation for user experience
- Sanitization of user input before storage