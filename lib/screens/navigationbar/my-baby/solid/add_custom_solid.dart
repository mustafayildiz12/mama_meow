import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/service/activities/add_custom_solid_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
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
  void initState() {
    super.initState();
    analyticService.screenView('add_custom_solid');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null || !mounted) return;

      if (kIsWeb) {
        // Servis yalnızca File yüklüyor; web'de şimdilik sadece önizleme.
        setState(() => _xfile = picked);
        _showMessage("Uploading food photos isn't supported on the web yet.");
      } else {
        setState(() {
          _file = File(picked.path);
          _xfile = picked;
        });
      }
    } catch (e) {
      debugPrint('pickImage failed: $e');
      if (mounted) _showMessage("The image couldn't be selected.");
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
    // Misafir kullanıcı: kayıt yerine giriş ekranına yönlendir.
    if (authenticationService.getUser() == null) {
      final router = GoRouter.of(context);
      Navigator.pop(context);
      router.pushNamed('login');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (kIsWeb) {
      _showMessage("Uploading food photos isn't supported on the web yet.");
      return;
    }
    if (_file == null) {
      _showMessage("Please pick an image.");
      return;
    }

    setState(() => _loading = true);

    try {
      final file = _file!;
      final ext = p.extension(_xfile?.name ?? file.path).replaceAll('.', '');
      final fileName = _safeFileName(_nameCtrl.text, ext);
      final contentType = lookupMimeType(file.path) ?? 'image/jpeg';

      final downloadUrl = await addCustomSolidService.uploadFile(
        file: file,
        fileName: fileName,
        contentType: contentType,
      );

      final model = CustomSolidModel(
        name: _nameCtrl.text.trim(),
        solidLink: downloadUrl,
      );

      await addCustomSolidService.addCustomSolid(model);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(const SnackBar(content: Text("Food added")));
    } catch (e) {
      debugPrint('addCustomSolid failed: $e');
      if (mounted) _showMessage("Couldn't save the food. Please try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Beyaz, 24 px köşeli diyalog (renkler temadan).
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconSquircle(
                background: ActivityKind.solid.tileColor,
                child: const ActivityIcon(kind: ActivityKind.solid),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Add New Food",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameCtrl,
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: "Food name"),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return "Please enter a food name";
                }

                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
          // İkincil buton: pembe zeminli hap.
          FilledButton.tonalIcon(
            onPressed: _loading ? null : _pickImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text("Pick image"),
          ),
          const SizedBox(height: 12),
          if (_xfile != null || _file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              child: kIsWeb ? Image.network(_xfile!.path) : Image.file(_file!),
            ),
          const SizedBox(height: 16),
          PrimaryPillButton(
            label: "Upload and save",
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
