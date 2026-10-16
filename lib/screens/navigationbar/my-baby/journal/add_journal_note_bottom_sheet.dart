import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/models/activities/journal_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/journal_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

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
    analyticService.screenView('add_journal_sheet');
    _loadTodayNote();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- Validation ---
  // Kaydedilen metin trim'lendiği için doğrulama da trim'li uzunlukla yapılır.
  int get _characterCount => _noteController.text.trim().length;
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

    return ActivitySheetFrame(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      decoration: sheetDecoration(),
      builder: (context, _) => _sheetBody(theme, context),
    );
  }

  Widget _sheetBody(ThemeData theme, BuildContext context) {
    final savedAt = DateTime.tryParse(_existingTodayNote?.createdAt ?? '');
    return Column(
      children: [
        // Başlık (tutamaç + journal ikonu + kapat)
        ActivitySheetHeader(
          title: _existingTodayNote == null
              ? 'Add journal note'
              : 'Edit today\'s note',
          kind: ActivityKind.journal,
          subtitle: savedAt == null
              ? null
              : 'Last saved ${DateFormat('HH:mm').format(savedAt)}',
        ),

        const Divider(height: 1),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _editor(theme),
          ),
        ),

        _actionBar(),
      ],
    );
  }

  Widget _editor(ThemeData theme) {
    final tooLong = _characterCount > 500;
    // Geçerli → warmPink, 500'ü aştı → berryInk, boş → nötr çizgi.
    final borderColor = tooLong
        ? AppColors.berryInk
        : (_isValid ? AppColors.warmPink : AppColors.outline);
    final radius = BorderRadius.circular(AppTheme.radiusInput);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What happened today?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),

        Expanded(
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
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: borderColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(
                  color: tooLong ? AppColors.berryInk : AppColors.activeBerry,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
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
                  style: const TextStyle(
                    color: AppColors.berryInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              '$_characterCount/500',
              style: TextStyle(
                color: tooLong ? AppColors.berryInk : AppColors.charcoalSoft,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Alt butonlar: (düzenlemede) Delete, Cancel, Save/Update.
  Widget _actionBar() {
    final editing = _existingTodayNote != null;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cottonWhite,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            if (editing) ...[
              // Yer kazanmak için ikon buton; "Delete" etiketi tooltip'te.
              IconButton.outlined(
                tooltip: 'Delete',
                onPressed: _isSaving ? null : _delete,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(52),
                  foregroundColor: AppColors.berryInk,
                  side: const BorderSide(color: AppColors.outline, width: 1.5),
                ),
                icon: const Icon(Icons.delete_outline),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton.tonal(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryPillButton(
                label: editing ? 'Update' : 'Save note',
                height: 52,
                loading: _isSaving,
                onPressed: _isValid ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
