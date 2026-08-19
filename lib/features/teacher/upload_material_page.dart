import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
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
  final _urlCtrl = TextEditingController();
  String _type = 'pdf';
  bool _uploading = false;

  @override
  void dispose() {
    _judulCtrl.dispose();
    _kelasCtrl.dispose();
    _mapelCtrl.dispose();
    _deskripsiCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _uploading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.materiCollection)
          .add({
        'judul': _judulCtrl.text.trim(),
        'kelas': _kelasCtrl.text.trim(),
        'mapel': _mapelCtrl.text.trim(),
        'deskripsi': _deskripsiCtrl.text.trim(),
        'type': _type,
        'file_url': _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
        'file_name': _judulCtrl.text.trim(),
        'guru_id': uid,
        'guru_name': FirebaseAuth.instance.currentUser?.displayName ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Materi berhasil disimpan!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Color(0xFFC62828)),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gunakan link Google Drive, YouTube, atau URL file langsung.',
                        style: TextStyle(color: AppTheme.primary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _judulCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Materi *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kelasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kelas Tujuan *',
                  prefixIcon: Icon(Icons.class_outlined),
                  hintText: 'contoh: XII-TKJ-1',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mapelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mata Pelajaran *',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Tipe Materi:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'pdf', label: Text('PDF'), icon: Icon(Icons.picture_as_pdf_outlined)),
                  ButtonSegment(value: 'video', label: Text('Video'), icon: Icon(Icons.video_file_outlined)),
                  ButtonSegment(value: 'link', label: Text('Link'), icon: Icon(Icons.link)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlCtrl,
                decoration: InputDecoration(
                  labelText: _type == 'video' ? 'Link YouTube / Google Drive Video'
                      : _type == 'pdf' ? 'Link Google Drive / PDF URL'
                      : 'Link Materi',
                  prefixIcon: const Icon(Icons.link),
                  hintText: 'https://drive.google.com/...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              const Text(
                'Cara: Upload ke Google Drive ? Klik kanan ? Bagikan ? "Semua orang dengan link" ? Copy link',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _simpan,
                  icon: _uploading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_uploading ? 'Menyimpan...' : 'Simpan Materi'),
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