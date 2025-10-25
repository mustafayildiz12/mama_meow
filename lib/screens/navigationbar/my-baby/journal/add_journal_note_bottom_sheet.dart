import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/models/activities/journal_model.dart';
import 'package:mama_meow/service/activities/journal_service.dart';

class AddJournalNoteBottomSheet extends StatefulWidget {
  const AddJournalNoteBottomSheet({super.key});

  @override
  State<AddJournalNoteBottomSheet> createState() =>
      _AddJournalNoteBottomSheetState();
}

class _AddJournalNoteBottomSheetState extends State<AddJournalNoteBottomSheet> {
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  JournalModel? _existingTodayNote; // varsa bugünün notu

  @override
  void initState() {
    super.initState();
    _loadTodayNote();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- Validation ---
  int get _characterCount => _noteController.text.length;
  bool get _isValid => _characterCount > 0 && _characterCount <= 500;

  // --- Data loading ---
  Future<void> _loadTodayNote() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final today = _formatDate(DateTime.now());
      final notes = await journalService.getNotesForDateOnce(today);
      if (notes.isNotEmpty) {
        // En yeni notu baz al
        _existingTodayNote = notes.first;
        _noteController.text = _existingTodayNote!.noteText;
      }
      // auto-focus (ilk açılış veya load sonrası)
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusNode.requestFocus(),
      );
    } catch (e) {
      _errorMessage = 'Failed to load today\'s note.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Actions ---
  Future<void> _save() async {
    if (!_isValid) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final text = _noteController.text.trim();

      if (_existingTodayNote != null) {
        // Güncelle
        final updated = _existingTodayNote!.copyWith(
          noteText: text,
          createdAt: DateTime.now().toIso8601String(),
          // noteDate & noteId aynı kalsın
        );
        await journalService.updateNote(updated);
        _existingTodayNote = updated;
      } else {
        // Ekle (tek günlük not mantığına sadık kalmak için create)
        final note = JournalModel.create(noteText: text);
        await journalService.addJournalNote(note);
        _existingTodayNote = note;
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save note. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (_existingTodayNote == null) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await journalService.deleteNote(_existingTodayNote!.noteId);
      _existingTodayNote = null;
      _noteController.clear();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to delete note.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Platform.isAndroid
            ? SafeArea(top: false, child: sheetBody(theme, context))
            : sheetBody(theme, context);
      },
    );
  }

  Container sheetBody(ThemeData theme, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade100, Colors.indigo.shade200],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black12)],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.purple, size: 24),
                const SizedBox(width: 8),
                Text(
                  _existingTodayNote == null
                      ? 'Add Journal Note'
                      : 'Edit Today\'s Note',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                const Spacer(),
                if (_existingTodayNote != null)
                  Text(
                    DateFormat(
                      'HH:mm',
                    ).format(DateTime.parse(_existingTodayNote!.createdAt)),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What happened today?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isValid
                                    ? Colors.purple.shade300
                                    : (_characterCount > 500
                                          ? Colors.red
                                          : Colors.grey.shade300),
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _noteController,
                              focusNode: _focusNode,
                              onTapOutside: (event) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                hintText:
                                    'Share your thoughts, observations, or special moments...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Error & char count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_errorMessage != null)
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            Text(
                              '$_characterCount/500',
                              style: TextStyle(
                                color: _characterCount > 500
                                    ? Colors.red
                                    : Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (_existingTodayNote != null) // Delete only when editing
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      onPressed: _isSaving ? null : _delete,
                      label: const Text('Delete'),
                    ),
                  ),
                if (_existingTodayNote != null) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    onPressed: (_isValid && !_isSaving) ? _save : null,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _existingTodayNote == null ? 'Save Note' : 'Update',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
