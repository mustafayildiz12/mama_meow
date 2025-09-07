// ignore_for_file: use_build_context_synchronously

import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mama_meow/models/podcast_model.dart';
import 'package:mama_meow/service/podcast_service.dart';

class PodcastFormPage extends StatefulWidget {
  const PodcastFormPage({super.key});

  @override
  State<PodcastFormPage> createState() => _PodcastFormPageState();
}

class _PodcastFormPageState extends State<PodcastFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _idCtrl = TextEditingController(
    text: DateTime.now().millisecondsSinceEpoch.toString(),
  );
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'sleep');
  final _descriptionCtrl = TextEditingController();

  // Seçilen dosyalar
  PlatformFile? _audio;
  PlatformFile? _thumb;
  PlatformFile? _cover;
  PlatformFile? _icon;

  bool _saving = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _durationCtrl.dispose();
    _categoryCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = const [
      'sleep',
      'feeding',
      'diaper',
      'growth',
      'journal',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F3FF),
        title: const Text('Yeni Podcast Ekle'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F3FF), Color(0xFFE0F2FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: AbsorbPointer(
          absorbing: _saving,
          child: Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _idCtrl,
                      decoration: const InputDecoration(labelText: 'ID'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'ID gerekli' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title gerekli'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subtitleCtrl,
                      decoration: const InputDecoration(labelText: 'Subtitle'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _durationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Duration (örn: 8 min)',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category (Dropdown gibi)
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: categories.contains(_categoryCtrl.text)
                              ? _categoryCtrl.text
                              : categories.first,
                          items: categories
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _categoryCtrl.text = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Audio
                    _fileTile(
                      title: 'Audio',
                      fileName: _audio?.name,
                      onPick: _pickAudio,
                      preview: const Icon(Icons.audio_file, size: 28),
                    ),
                    const SizedBox(height: 8),

                    // Thumbnail
                    _fileTile(
                      title: 'Thumbnail',
                      fileName: _thumb?.name,
                      onPick: _pickThumb,
                      preview: _imagePreview(_thumb),
                    ),
                    const SizedBox(height: 8),

                    // CoverArt
                    _fileTile(
                      title: 'Cover Art',
                      fileName: _cover?.name,
                      onPick: _pickCover,
                      preview: _imagePreview(_cover),
                    ),
                    const SizedBox(height: 8),

                    // Icon
                    _fileTile(
                      title: 'Icon',
                      fileName: _icon?.name,
                      onPick: _pickIcon,
                      preview: _imagePreview(_icon),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Kaydet'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              if (_saving)
                const Center(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Yükleniyor, lütfen bekleyin...'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fileTile({
    required String title,
    required String? fileName,
    required VoidCallback onPick,
    Widget? preview,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(fileName ?? 'Seçilmedi'),
      trailing: ElevatedButton(onPressed: onPick, child: const Text('Seç')),
      leading: preview == null
          ? const Icon(Icons.attach_file)
          : SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: preview,
              ),
            ),
    );
  }

  Widget? _imagePreview(PlatformFile? f) {
    if (f == null) return null;
    if (kIsWeb) {
      return Image.memory(f.bytes!, fit: BoxFit.cover);
    } else {
      return Image.file(File(f.path!), fit: BoxFit.cover);
    }
  }

  // Basit içerik tipi eşlemesi
  String _guessContentType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'm4a':
      case 'aac':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        // Son çare
        return 'application/octet-stream';
    }
  }

  Future<PlatformFile?> _pickSingle({
    required List<String> allowedExtensions,
  }) async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      withData: kIsWeb, // web'de bytes gerekir
      allowedExtensions: allowedExtensions,
    );
    if (res != null && res.files.isNotEmpty) {
      return res.files.single;
    }
    return null;
  }

  Future<void> _pickAudio() async {
    final f = await _pickSingle(
      allowedExtensions: ['m4a', 'aac', 'mp3', 'wav'],
    );
    if (f != null) setState(() => _audio = f);
  }

  Future<void> _pickThumb() async {
    final f = await _pickSingle(
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (f != null) setState(() => _thumb = f);
  }

  Future<void> _pickCover() async {
    final f = await _pickSingle(
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (f != null) setState(() => _cover = f);
  }

  Future<void> _pickIcon() async {
    final f = await _pickSingle(
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (f != null) setState(() => _icon = f);
  }

  Future<String> _uploadPlatformFile({
    required PlatformFile file,
    required String storagePath,
  }) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    final metadata = SettableMetadata(
      contentType: _guessContentType(file.name),
    );

    if (kIsWeb) {
      final Uint8List bytes = file.bytes!;
      final snap = await ref.putData(bytes, metadata);
      return await snap.ref.getDownloadURL();
    } else {
      final snap = await ref.putFile(File(file.path!), metadata);
      return await snap.ref.getDownloadURL();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_audio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir ses dosyası seçin.')),
      );
      return;
    }

    setState(() => _saving = true);

    final id = _idCtrl.text.trim();
    try {
      // 1) Dosyaları Storage'a yükle
      // Yol: podcasts/{id}/...
      final List<Future<String>> uploads = [];

      // Audio
      final audioPath = 'podcasts/$id/audio.${_audio!.extension ?? 'm4a'}';
      uploads.add(_uploadPlatformFile(file: _audio!, storagePath: audioPath));

      // Thumbnail (opsiyonel)
      String? thumbUrl;
      if (_thumb != null) {
        final p = 'podcasts/$id/thumbnail.${_thumb!.extension ?? 'png'}';
        uploads.add(_uploadPlatformFile(file: _thumb!, storagePath: p));
      }

      // CoverArt (opsiyonel)
      String? coverUrl;
      if (_cover != null) {
        final p = 'podcasts/$id/coverArt.${_cover!.extension ?? 'png'}';
        uploads.add(_uploadPlatformFile(file: _cover!, storagePath: p));
      }

      // Icon (opsiyonel)
      String? iconUrl;
      if (_icon != null) {
        final p = 'podcasts/$id/icon.${_icon!.extension ?? 'png'}';
        uploads.add(_uploadPlatformFile(file: _icon!, storagePath: p));
      }

      // Sonuçları sırayla okuyabilmek için indexleri bil
      // Index 0: audio
      // Sonraki varsa: thumb -> cover -> icon (varsa)
      final results = await Future.wait(uploads);
      final audioUrl = results[0];

      int idx = 1;
      if (_thumb != null) {
        thumbUrl = results[idx++];
      }
      if (_cover != null) {
        coverUrl = results[idx++];
      }
      if (_icon != null) {
        iconUrl = results[idx++];
      }

      // 2) Podcast modelini oluştur
      final podcast = Podcast(
        id: id,
        title: _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim(),
        duration: _durationCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        thumbnail: thumbUrl ?? '',
        coverArt: coverUrl ?? '',
        description: _descriptionCtrl.text.trim(),
        audioUrl: audioUrl,
        icon: iconUrl ?? '',
      );

      // 3) Realtime Database'e yaz (YENİ: tekrar yükleme yok)
      await podcastService.addPodcastToRealtime(podcast);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Podcast başarıyla kaydedildi!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydetme sırasında hata: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
