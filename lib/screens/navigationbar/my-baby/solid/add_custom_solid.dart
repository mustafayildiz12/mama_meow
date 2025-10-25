import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mama_meow/service/activities/add_custom_solid_service.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import 'package:mama_meow/models/activities/custom_solid_model.dart';

class AddCustomSolidBottomSheet extends StatefulWidget {
  const AddCustomSolidBottomSheet({super.key});

  @override
  State<AddCustomSolidBottomSheet> createState() =>
      _AddCustomSolidBottomSheetState();
}

class _AddCustomSolidBottomSheetState extends State<AddCustomSolidBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _picker = ImagePicker();

  File? _file;
  XFile? _xfile; // UI önizleme için Web/dosya ayrımı
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null) return;

      if (kIsWeb) {
        // Web: Servis şu an File bekliyor. Web’i desteklemek için
        // AddCustomSolidService’e uploadBytes(...) gibi bir metod eklemelisin.
        // Şimdilik sadece önizleme yapalım ve kullanıcıyı uyaralım.
        setState(() => _xfile = picked);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web için yükleme: servise uploadBytes ekleyin.'),
          ),
        );
      } else {
        setState(() {
          _file = File(picked.path);
          _xfile = picked;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image could not be selected: $e")),
      );
    }
  }

  String _safeFileName(String name, String? ext) {
    final base = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9ğüşöçıİĞÜŞÖÇ\s\-_.]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final extension = (ext != null && ext.isNotEmpty) ? ext : 'jpg';
    return "${base}_$ts.$extension";
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!kIsWeb && _file == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please pick an image.")));
      return;
    }

    setState(() => _loading = true);

    try {
      String downloadUrl;

      if (kIsWeb) {
        // Not: Şu an servis sadece File kabul ediyor.
        // Web desteği için servise şunu ekleyebilirsin:
        // Future<String> uploadBytes({required Uint8List bytes, required String fileName, String? contentType})
        // Sonra burada _xfile.readAsBytes() ile bytes alıp onu çağırırsın.
        throw Exception("Web yükleme için servise uploadBytes(...) eklenmeli.");
      } else {
        final ext = p
            .extension(_xfile?.name ?? _file!.path)
            .replaceAll('.', '');
        final fileName = _safeFileName(_nameCtrl.text, ext);
        final contentType = lookupMimeType(_file!.path) ?? 'image/jpeg';

        downloadUrl = await addCustomSolidService.uploadFile(
          file: _file!,
          fileName: fileName,
          contentType: contentType,
        );
      }

      final model = CustomSolidModel(
        name: _nameCtrl.text.trim(),
        solidLink: downloadUrl,
      );

      await addCustomSolidService.addCustomSolid(model);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Success")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Text(
              "Add New Food",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameCtrl,
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Food Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "input food name";
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text("Pick Image"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_xfile != null || _file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Image.network(_xfile!.path)
                    : Image.file(_file!),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Upload and Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
