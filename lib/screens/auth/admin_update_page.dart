import 'package:flutter/material.dart';
import 'package:mama_meow/screens/get-started/modals/updata_available_modal.dart';
import 'package:mama_meow/service/update_service.dart';

class AdminUpdatePage extends StatefulWidget {
  const AdminUpdatePage({super.key});

  @override
  State<AdminUpdatePage> createState() => _AdminUpdatePageState();
}

class _AdminUpdatePageState extends State<AdminUpdatePage> {
  final _formKey = GlobalKey<FormState>();

  // Form alanları
  final TextEditingController _versionCtrl = TextEditingController();
  final TextEditingController _minBuildCtrl = TextEditingController();

  // Dinamik highlight listesi
  final List<TextEditingController> _highlightCtrls = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _versionCtrl.dispose();
    _minBuildCtrl.dispose();
    for (final c in _highlightCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _collectHighlights() {
    return _highlightCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final version = _versionCtrl.text.trim();
    final highlights = _collectHighlights();

    setState(() => _isSubmitting = true);
    try {
      await UpdateService.instance.publishUpdate(
        version: version,
        highlights: highlights,
        forceUpdate: false,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Yayınlandı / güncellendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Hata: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _unpublish() async {
    final version = _versionCtrl.text.trim();
    if (version.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Versiyon girilmeden unpublish yapılamaz'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await UpdateService.instance.unpublish(version);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📴 $version yayından kaldırıldı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Hata: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _previewModal() async {
    final version = _versionCtrl.text.trim();
    final highlights = _collectHighlights();
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UpdateAvailableModal(
        version: version.isEmpty ? null : version,
        highlights: highlights.isEmpty ? null : highlights,
        onCancel: () => Navigator.pop(ctx, false),
        onUpdate: () => Navigator.pop(ctx, true),
      ),
    );
  }

  void _addHighlight() {
    setState(() {
      _highlightCtrls.add(TextEditingController());
    });
  }

  void _removeHighlight(int index) {
    setState(() {
      final c = _highlightCtrls.removeAt(index);
      c.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pink = const Color(0xFFEC4899);
    final pinkLight = const Color(0xFFFBCFE8);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Publish Update')),
      body: AbsorbPointer(
        absorbing: _isSubmitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Başlık
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F5),
                        border: Border.all(color: pinkLight),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Yeni sürümü ve öne çıkanları ekleyip yayınlayın. '
                        'Publish ettiğinizde kullanıcılar uygulamayı açtıklarında update modalını görür.',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Version + Min Build
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _versionCtrl,
                            onTapOutside: (event) {
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            decoration: InputDecoration(
                              labelText: 'Version (ör. 1.0.5)',
                              hintText: '1.0.5',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: pink, width: 2),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Versiyon zorunlu';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Highlights Header
                    Row(
                      children: [
                        const Text(
                          'Highlights',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Önizleme',
                          onPressed: _previewModal,
                          icon: const Icon(Icons.visibility),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _addHighlight,
                          icon: const Icon(Icons.add),
                          label: const Text('Madde Ekle'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Reorderable highlights
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _highlightCtrls.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final item = _highlightCtrls.removeAt(oldIndex);
                          _highlightCtrls.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        return Dismissible(
                          key: ValueKey(_highlightCtrls[index]),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.redAccent,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _removeHighlight(index),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 14.0, right: 8),
                                  child: Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey,
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _highlightCtrls[index],
                                    onTapOutside: (event) {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    },
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Örn. Bildirim hatası düzeltildi',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: pink,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Sil',
                                  onPressed: () => _removeHighlight(index),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _unpublish,
                            icon: const Icon(Icons.block),
                            label: const Text('Unpublish'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _publish,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload),
                            label: Text(
                              _isSubmitting ? 'Yükleniyor...' : 'Publish',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'Not: publishedAt Sunucu zamanı ile otomatik eklenir.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
