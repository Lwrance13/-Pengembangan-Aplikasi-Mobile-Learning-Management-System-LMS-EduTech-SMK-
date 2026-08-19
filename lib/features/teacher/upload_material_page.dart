import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

class UploadMaterialPage extends StatefulWidget {
  const UploadMaterialPage({super.key});

  @override
  State<UploadMaterialPage> createState() => _UploadMaterialPageState();
}

class _UploadMaterialPageState extends State<UploadMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _kelasCtrl = TextEditingController();
  final _mapelCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  String _type = 'pdf';
  PlatformFile? _selectedFile;
  bool _uploading = false;
  double _progress = 0;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: _type == 'pdf' ? FileType.custom : FileType.media,
      allowedExtensions: _type == 'pdf' ? ['pdf'] : null,
      withData: true,
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file terlebih dahulu!')),
      );
      return;
    }
    setState(() { _uploading = true; _progress = 0; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      String? fileUrl;

      final bytes = _selectedFile!.bytes;
      if (bytes != null) {
        final contentType = _type == 'pdf' ? 'application/pdf' : 'video/mp4';
        fileUrl = await StorageService().uploadBytes(
          bytes: bytes,
          storagePath: FirebaseConstants.materiStoragePath,
          customFileName: '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}',
          contentType: contentType,
        );
      }

      await FirebaseFirestore.instance
          .collection(FirebaseConstants.materiCollection)
          .add({
        'judul': _judulCtrl.text.trim(),
        'kelas': _kelasCtrl.text.trim(),
        'mapel': _mapelCtrl.text.trim(),
        'deskripsi': _deskripsiCtrl.text.trim(),
        'type': _type,
        'file_url': fileUrl,
        'file_name': _selectedFile!.name,
        'guru_id': uid,
        'guru_name': FirebaseAuth.instance.currentUser?.displayName ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Materi berhasil diunggah!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Materi'),
        backgroundColor: AppTheme.guruMapelColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _judulCtrl,
                decoration: const InputDecoration(labelText: 'Judul Materi', prefixIcon: Icon(Icons.title)),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kelasCtrl,
                decoration: const InputDecoration(labelText: 'Kelas Tujuan', prefixIcon: Icon(Icons.class_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mapelCtrl,
                decoration: const InputDecoration(labelText: 'Mata Pelajaran', prefixIcon: Icon(Icons.book_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi', prefixIcon: Icon(Icons.description_outlined)),
              ),
              const SizedBox(height: 16),
              const Text('Tipe File:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'pdf', label: Text('PDF'), icon: Icon(Icons.picture_as_pdf_outlined)),
                  ButtonSegment(value: 'video', label: Text('Video'), icon: Icon(Icons.video_file_outlined)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() { _type = s.first; _selectedFile = null; }),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: Icon(_type == 'pdf' ? Icons.picture_as_pdf : Icons.video_file),
                label: Text(_selectedFile != null
                    ? _selectedFile!.name
                    : 'Pilih File ${_type.toUpperCase()}'),
              ),
              const SizedBox(height: 24),
              if (_uploading) ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                const Text('Mengunggah...', textAlign: TextAlign.center),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _upload,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Materi'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruMapelColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
