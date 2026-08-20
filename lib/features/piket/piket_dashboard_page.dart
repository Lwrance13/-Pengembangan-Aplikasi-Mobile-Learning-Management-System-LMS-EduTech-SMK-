import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/notification_trigger_service.dart';
import '../shared/notification_list_page.dart';

class PiketDashboardPage extends StatefulWidget {
  const PiketDashboardPage({super.key});

  @override
  State<PiketDashboardPage> createState() => _PiketDashboardPageState();
}

class _PiketDashboardPageState extends State<PiketDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _PiketHomeTab(),
      const QuickScanPage(),
      const _PiketCatatanTab(),
      const _PiketProfilTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK — Guru Piket'),
        backgroundColor: AppTheme.guruPiketColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationListPage()),
            ),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan QR'),
          NavigationDestination(icon: Icon(Icons.book_outlined), label: 'Catatan'),
          NavigationDestination(icon: Icon(Icons.person_outlined), label: 'Profil'),
        ],
      ),
    );
  }
}

class _PiketHomeTab extends StatelessWidget {
  const _PiketHomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final now = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppTheme.guruPiketColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.access_time, color: AppTheme.guruPiketColor, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user?.name ?? 'Guru Piket',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Piket ${now.day}/${now.month}/${now.year}',
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruPiketColor),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuickScanPage()),
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Absensi'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
                  onPressed: () => _broadcastDialog(context),
                  icon: const Icon(Icons.campaign),
                  label: const Text('Broadcast'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Siswa Terlambat Hari Ini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.piketCollection)
                .where('jenis', isEqualTo: 'terlambat')
                .where('tanggal_str',
                    isEqualTo: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) return const SizedBox.shrink();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: AppTheme.success),
                    title: Text('Tidak ada siswa terlambat hari ini.'),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: AppTheme.warning),
                      title: Text(d['student_name'] ?? ''),
                      subtitle: Text('Kelas: ${d['kelas'] ?? '-'} â€¢ ${d['jam'] ?? ''}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _broadcastDialog(BuildContext context) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Broadcast Darurat'),
          ],
        ),
        content: TextField(
          controller: msgCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ketik pesan darurat...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () async {
              final msg = msgCtrl.text.trim();
              if (msg.isEmpty) return;
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              // 🔔 Broadcast via NotificationTriggerService (kirim ke semua user)
              await NotificationTriggerService.broadcastDarurat(
                judul: '⚠️ Pengumuman Darurat',
                pesan: msg,
                senderId: uid,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.send),
            label: const Text('Kirim'),
          ),
        ],
      ),
    );
  }
}

class _PiketCatatanTab extends StatelessWidget {
  const _PiketCatatanTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCatatan(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Catatan'),
        backgroundColor: AppTheme.guruPiketColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.piketCollection)
            .limit(30).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text("Belum ada data.", style: TextStyle(color: Color(0xFF6B7280))));
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada catatan.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final jenis = d['jenis'] ?? '';
              return Card(
                child: ListTile(
                  leading: Icon(
                    jenis == 'terlambat' ? Icons.access_time :
                    jenis == 'izin_pulang' ? Icons.exit_to_app :
                    Icons.event_note,
                    color: jenis == 'terlambat' ? AppTheme.warning :
                           jenis == 'izin_pulang' ? AppTheme.accent :
                           AppTheme.primary,
                  ),
                  title: Text(d['student_name'] ?? ''),
                  subtitle: Text(d['keterangan'] ?? ''),
                  trailing: Text(jenis,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _addCatatan(BuildContext context) {
    final nameCtrl = TextEditingController();
    final kelasCtrl = TextEditingController();
    final ketCtrl = TextEditingController();
    String jenis = 'terlambat';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Tambah Catatan Harian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Siswa')),
                const SizedBox(height: 8),
                TextField(controller: kelasCtrl,
                    decoration: const InputDecoration(labelText: 'Kelas')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: jenis,
                  items: const [
                    DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                    DropdownMenuItem(value: 'izin_pulang', child: Text('Izin Pulang')),
                    DropdownMenuItem(value: 'kejadian_khusus', child: Text('Kejadian Khusus')),
                  ],
                  onChanged: (v) => setState(() => jenis = v!),
                  decoration: const InputDecoration(labelText: 'Jenis'),
                ),
                const SizedBox(height: 8),
                TextField(controller: ketCtrl, maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Keterangan')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final now = DateTime.now();
                await FirebaseFirestore.instance
                    .collection(FirebaseConstants.piketCollection)
                    .add({
                  'student_name': nameCtrl.text.trim(),
                  'kelas': kelasCtrl.text.trim(),
                  'jenis': jenis,
                  'keterangan': ketCtrl.text.trim(),
                  'piket_id': FirebaseAuth.instance.currentUser?.uid,
                  'timestamp': FieldValue.serverTimestamp(),
                  'tanggal_str': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                  'jam': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PiketProfilTab extends StatelessWidget {
  const _PiketProfilTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.guruPiketColor,
            child: Icon(Icons.access_time, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '-', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          ),
        ],
      ),
    );
  }
}


class QuickScanPage extends StatefulWidget {
  const QuickScanPage({super.key});

  @override
  State<QuickScanPage> createState() => _QuickScanPageState();
}

class _QuickScanPageState extends State<QuickScanPage> {
  bool _isProcessing = false;
  bool _cameraActive = false;
  String? _resultMessage;
  bool _resultSuccess = false;
  MobileScannerController? _cameraController;

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _startCamera() {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan QR hanya tersedia di Android/iOS. Gunakan input NISN manual.')),
      );
      return;
    }
    setState(() {
      _cameraController = MobileScannerController();
      _cameraActive = true;
    });
  }

  void _stopCamera() {
    _cameraController?.dispose();
    setState(() { _cameraController = null; _cameraActive = false; });
  }

  Future<void> _processNisn(String nisn) async {
    if (_isProcessing || nisn.isEmpty) return;
    _stopCamera();
    setState(() => _isProcessing = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .where('nisn', isEqualTo: nisn)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        setState(() { _resultMessage = 'NISN $nisn tidak ditemukan!'; _resultSuccess = false; _isProcessing = false; });
        return;
      }
      final studentDoc = snap.docs.first;
      final studentData = studentDoc.data();
      await FirebaseFirestore.instance.collection(FirebaseConstants.absensiCollection).add({
        'student_id': studentDoc.id,
        'student_name': studentData['name'],
        'kelas': studentData['kelas'],
        'nisn': nisn,
        'status': 'hadir',
        'tanggal': Timestamp.fromDate(DateTime.now()),
        'piket_id': FirebaseAuth.instance.currentUser?.uid,
        'scan_type': _cameraActive ? 'qr_scan' : 'manual',
        'mapel': 'PIKET',
      });
      setState(() {
        _resultMessage = '✅ ${studentData['name']} — Kelas ${studentData['kelas']}\nAbsensi berhasil dicatat!';
        _resultSuccess = true; _isProcessing = false;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _resultMessage = null);
      });
    } catch (e) {
      setState(() { _resultMessage = 'Error: $e'; _resultSuccess = false; _isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Camera / QR scanner area
          if (_cameraActive && _cameraController != null)
            Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 260,
                  child: MobileScanner(
                    controller: _cameraController!,
                    onDetect: (capture) {
                      final code = capture.barcodes.firstOrNull?.rawValue ?? '';
                      if (code.isNotEmpty) _processNisn(code);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _stopCamera,
                icon: const Icon(Icons.close),
                label: const Text('Tutup Kamera'),
              ),
            ])
          else
            Container(
              height: 160, width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.guruPiketColor.withValues(alpha: 0.4), width: 2),
              ),
              child: InkWell(
                onTap: _startCamera,
                borderRadius: BorderRadius.circular(12),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.qr_code_scanner, size: 56, color: AppTheme.guruPiketColor),
                  SizedBox(height: 8),
                  Text('Ketuk untuk Scan QR Absensi',
                      style: TextStyle(color: AppTheme.guruPiketColor, fontWeight: FontWeight.w600)),
                  Text('(NISN siswa harus ter-encode di QR)',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ]),
              ),
            ),
          const SizedBox(height: 16),
          if (_resultMessage != null) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _resultSuccess ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _resultSuccess ? AppTheme.success : AppTheme.danger),
              ),
              child: Text(_resultMessage!, textAlign: TextAlign.center,
                  style: TextStyle(color: _resultSuccess ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
          ],
          const Text('Atau Input NISN Manual:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          _NisnInput(onSubmit: _processNisn, isProcessing: _isProcessing),
        ],
      ),
    );
  }
}

class _NisnInput extends StatefulWidget {
  final Function(String) onSubmit;
  final bool isProcessing;
  const _NisnInput({required this.onSubmit, required this.isProcessing});
  @override State<_NisnInput> createState() => _NisnInputState();
}
class _NisnInputState extends State<_NisnInput> {
  final _ctrl = TextEditingController();
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: TextField(
        controller: _ctrl, keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Masukkan NISN siswa...', prefixIcon: const Icon(Icons.person_search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onSubmitted: (v) { if (v.trim().isNotEmpty) { widget.onSubmit(v.trim()); _ctrl.clear(); } },
      )),
      const SizedBox(width: 8),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruPiketColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
        onPressed: widget.isProcessing ? null : () {
          if (_ctrl.text.trim().isNotEmpty) { widget.onSubmit(_ctrl.text.trim()); _ctrl.clear(); }
        },
        child: widget.isProcessing
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Cari'),
      ),
    ]);
  }
}
