import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

class QuickScanPage extends StatefulWidget {
  const QuickScanPage({super.key});

  @override
  State<QuickScanPage> createState() => _QuickScanPageState();
}

class _QuickScanPageState extends State<QuickScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedNisn;
  String? _resultMessage;
  bool _resultSuccess = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processBarcode(String nisn) async {
    if (_isProcessing || nisn == _lastScannedNisn) return;
    setState(() { _isProcessing = true; _lastScannedNisn = nisn; });

    try {
      // Cari siswa berdasarkan NISN
      final snap = await FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .where('nisn', isEqualTo: nisn)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        setState(() {
          _resultMessage = 'NISN $nisn tidak ditemukan!';
          _resultSuccess = false;
          _isProcessing = false;
        });
        return;
      }

      final studentDoc = snap.docs.first;
      final studentData = studentDoc.data();
      final now = DateTime.now();

      // Catat absensi
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.absensiCollection)
          .add({
        'student_id': studentDoc.id,
        'student_name': studentData['name'],
        'kelas': studentData['kelas'],
        'nisn': nisn,
        'status': 'hadir',
        'tanggal': Timestamp.fromDate(now),
        'piket_id': FirebaseAuth.instance.currentUser?.uid,
        'scan_type': 'qr',
        'mapel': 'PIKET',
      });

      setState(() {
        _resultMessage = '✅ ${studentData['name']} — Kelas ${studentData['kelas']}\nAbsensi berhasil dicatat!';
        _resultSuccess = true;
        _isProcessing = false;
      });

      // Reset setelah 3 detik
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() { _lastScannedNisn = null; _resultMessage = null; });
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Error: $e';
        _resultSuccess = false;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final value = barcode.rawValue;
                    if (value != null) _processBarcode(value);
                  }
                },
              ),
              // Scan overlay
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.guruPiketColor, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Text(
                  'Arahkan kamera ke QR Code / Barcode NISN',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Result area
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                if (_resultMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _resultSuccess
                          ? AppTheme.success.withValues(alpha: 0.1)
                          : AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _resultSuccess ? AppTheme.success : AppTheme.danger,
                      ),
                    ),
                    child: Text(
                      _resultMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _resultSuccess ? AppTheme.success : AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const Column(
                    children: [
                      Icon(Icons.qr_code_scanner, size: 48, color: AppTheme.guruPiketColor),
                      SizedBox(height: 8),
                      Text('Siap menscan...', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                const SizedBox(height: 16),
                // Manual input
                const Divider(),
                const Text('Atau input NISN manual:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                _ManualNisnInput(onSubmit: _processBarcode),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualNisnInput extends StatefulWidget {
  final Function(String) onSubmit;
  const _ManualNisnInput({required this.onSubmit});

  @override
  State<_ManualNisnInput> createState() => _ManualNisnInputState();
}

class _ManualNisnInputState extends State<_ManualNisnInput> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ketik NISN...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.guruPiketColor, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          onPressed: () {
            final nisn = _ctrl.text.trim();
            if (nisn.isNotEmpty) {
              widget.onSubmit(nisn);
              _ctrl.clear();
            }
          },
          child: const Text('Cari'),
        ),
      ],
    );
  }
}
