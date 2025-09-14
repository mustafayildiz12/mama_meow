# Requirements Document

## Introduction

This feature adds comprehensive note-taking functionality to the existing journal screen in the baby tracking app. Users will be able to create, view, and manage daily journal entries with multiple notes per day. The feature integrates with Firebase Realtime Database and maintains visual consistency with the existing activity cards using matching gradient colors.

## Requirements

### Requirement 1

**User Story:** As a parent, I want to add multiple journal notes throughout the day, so that I can record important moments and observations about my baby.

#### Acceptance Criteria

1. WHEN I access the journal screen THEN I SHALL see an "Add Note" button or interface
2. WHEN I tap the add note button THEN I SHALL see a step-by-step note creation interface
3. WHEN I create a note THEN the system SHALL save it to Firebase Realtime Database at path `journal/{userId}/noteDetails`
4. WHEN I add multiple notes in a day THEN the system SHALL display all notes for that day
5. WHEN I view the journal screen THEN I SHALL see today's notes displayed in real-time

### Requirement 2

**User Story:** As a parent, I want the journal interface to match the visual design of other activity cards, so that the app feels cohesive and familiar.

#### Acceptance Criteria

1. WHEN I view journal summary cards THEN they SHALL use the same gradient colors as defined in my_baby_screen.dart
2. WHEN I see the journal card THEN it SHALL match the visual style of Sleep, Solid, Pumping, and Diaper cards
3. WHEN I interact with journal elements THEN they SHALL follow the same design patterns as other activities
4. WHEN I view the journal screen THEN the color scheme SHALL be consistent with the purple gradient theme

### Requirement 3

**User Story:** As a parent, I want to see my journal notes organized by date, so that I can easily find and review past entries.

#### Acceptance Criteria

1. WHEN I open the journal screen THEN I SHALL see today's date prominently displayed
2. WHEN I have notes for today THEN they SHALL be displayed in chronological order
3. WHEN I have no notes for today THEN I SHALL see an appropriate empty state message
4. WHEN notes are added THEN the display SHALL update in real-time without requiring a refresh
5. WHEN I view a note THEN I SHALL see the timestamp when it was created

### Requirement 4

**User Story:** As a developer, I want a proper data model and service layer for journal functionality, so that the code is maintainable and follows existing patterns.

#### Acceptance Criteria

1. WHEN implementing the journal feature THEN I SHALL create a JournalModel class following existing model patterns
2. WHEN implementing the journal feature THEN I SHALL create a JournalService class following existing service patterns
3. WHEN saving journal data THEN it SHALL use Firebase Realtime Database with proper error handling
4. WHEN retrieving journal data THEN it SHALL provide real-time streams like other activity services
5. WHEN the journal service is created THEN it SHALL include methods for adding, retrieving, and streaming journal entries

### Requirement 5

**User Story:** As a parent, I want an intuitive note creation process, so that I can quickly capture important moments without friction.

#### Acceptance Criteria

1. WHEN I start creating a note THEN I SHALL see a multi-step interface that guides me through the process
2. WHEN I'm writing a note THEN I SHALL have a text input field with appropriate validation
3. WHEN I complete a note THEN I SHALL be able to save it with a single action
4. WHEN I cancel note creation THEN I SHALL be returned to the journal screen without saving
5. WHEN I save a note THEN I SHALL see immediate confirmation and the note SHALL appear in the list