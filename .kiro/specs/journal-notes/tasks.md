# Implementation Plan

- [x] 1. Create JournalModel class
  - Create lib/models/activities/journal_model.dart following the SleepModel pattern
  - Implement noteText, createdAt, noteDate, and noteId properties
  - Add fromJson and toJson methods for Firebase serialization
  - Include proper validation in the model constructor
  - _Requirements: 4.1, 4.2_

- [x] 2. Create JournalService class
  - Create lib/service/activities/journal_service.dart following the SleepService pattern
  - Implement addJournalNote method for Firebase database writes
  - Implement getNotesForDate method for retrieving notes by date
  - Implement todayNoteCountStream for real-time count updates
  - Implement todayNotesStream for real-time note list updates
  - Add proper error handling and user authentication checks
  - _Requirements: 4.3, 4.4, 4.5_

- [x] 3. Create AddJournalNoteBottomSheet component
  - Create lib/screens/navigationbar/my-baby/journal/add_journal_note_bottom_sheet.dart
  - Implement multi-step note creation interface with text input validation
  - Add character count display and limit enforcement (1-500 characters)
  - Include save and cancel functionality with proper navigation
  - Style consistently with existing bottom sheet components
  - _Requirements: 1.1, 1.2, 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 4. Update JournalPage with note creation interface
  - Add "Add Note" button to the existing journal_screen.dart
  - Integrate AddJournalNoteBottomSheet with proper modal presentation
  - Update the UI layout to accommodate the new note creation interface
  - Ensure the add note functionality is easily accessible
  - _Requirements: 1.1, 1.2_

- [x] 5. Implement notes display section in JournalPage
  - Add today's notes list display to journal_screen.dart
  - Create individual note card widgets with timestamp and content
  - Implement real-time updates using todayNotesStream
  - Add empty state handling when no notes exist for today
  - Style note cards consistently with existing activity cards
  - _Requirements: 1.4, 1.5, 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 6. Update summary cards with matching gradient colors
  - Modify the _SummaryCard widgets in journal_screen.dart to use purple gradient colors
  - Apply the same color scheme as defined in my_baby_screen.dart journal card
  - Ensure visual consistency between journal summary and main journal card
  - Update background colors, text colors, and icon container colors
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 7. Add journal note count to summary cards
  - Integrate JournalService.todayNoteCountStream into the journal summary display
  - Add a new summary card specifically for journal notes count
  - Display "Today: X notes" format matching other activity cards
  - Ensure real-time updates when notes are added or modified
  - _Requirements: 1.5, 3.4_

- [x] 8. Implement proper error handling and validation
  - Add form validation to AddJournalNoteBottomSheet with user feedback
  - Implement error states for Firebase operations with retry mechanisms
  - Add loading states during note creation and data fetching
  - Include proper error messages for network and database failures
  - _Requirements: 5.2, 5.3, 5.5_

- [x] 9. Add journal service to global service instances
  - Create global journalService instance following the pattern of other services
  - Import and initialize JournalService in the appropriate service files
  - Ensure the service is available throughout the application
  - _Requirements: 4.2, 4.5_

- [-] 10. Test and integrate the complete journal notes feature
  - Test note creation flow from start to finish
  - Verify real-time updates work correctly across the application
  - Test error handling scenarios and edge cases
  - Ensure visual consistency with existing UI components
  - Verify Firebase database operations work correctly
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5_