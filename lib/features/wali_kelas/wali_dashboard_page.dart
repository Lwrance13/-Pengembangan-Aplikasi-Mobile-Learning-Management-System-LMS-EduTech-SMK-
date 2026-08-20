import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/firebase_constants.dart';
import '../shared/notification_list_page.dart';
import 'alert_system_widget.dart';

class WaliDashboardPage extends StatefulWidget {
  const WaliDashboardPage({super.key});

  @override
  State<WaliDashboardPage> createState() => _WaliDashboardPageState();
}

class _WaliDashboardPageState extends State<WaliDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _WaliHomeTab(),
      _WaliAbsensiTab(),
      _WaliPelanggaranTab(),
      _WaliBukuPenghubungTab(),
      _WaliProfilTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK â€” Wali Kelas'),
        backgroundColor: AppTheme.waliKelasColor,
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
          NavigationDestination(icon: Icon(Icons.how_to_reg_outlined), label: 'Absensi'),
          NavigationDestination(icon: Icon(Icons.warning_amber_outlined), label: 'Pelanggaran'),
          NavigationDestination(icon: Icon(Icons.book_outlined), label: 'Buku'),
          NavigationDestination(icon: Icon(Icons.person_outlined), label: 'Profil'),
        ],
      ),
    );
  }
}

class _WaliHomeTab extends StatelessWidget {
  const _WaliHomeTab();

  void _showStudentDetail(BuildContext context, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(d['name'] ?? 'Siswa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('NISN', d['nisn'] ?? '-'),
            _DetailRow('Email', d['email'] ?? '-'),
            _DetailRow('Kelas', d['kelas'] ?? '-'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, String kelas, String waliName) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menyiapkan laporan PDF...')),
    );

    // Fetch data
    final db = FirebaseFirestore.instance;
    final siswaSnap = await db
        .collection(FirebaseConstants.usersCollection)
        .where('role', isEqualTo: 'SISWA')
        .where('kelas', isEqualTo: kelas)
        .get();
    final absensiSnap = await db
        .collection(FirebaseConstants.absensiCollection)
        .where('kelas', isEqualTo: kelas)
        .get();
    final pelanggaranSnap = await db
        .collection(FirebaseConstants.pelanggaranCollection)
        .where('kelas', isEqualTo: kelas)
        .get();

    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Text('LAPORAN KELAS $kelas',
            style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text('Wali Kelas: $waliName',
            style: const pw.TextStyle(fontSize: 12)),
        pw.Text(
            'Tanggal: ${now.day}/${now.month}/${now.year}',
            style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 16),

        // â”€â”€ Daftar Siswa â”€â”€
        pw.Text('Daftar Siswa (${siswaSnap.docs.length} siswa)',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['No', 'Nama', 'NISN', 'Email'],
          data: List.generate(siswaSnap.docs.length, (i) {
            final d = siswaSnap.docs[i].data();
            return [
              '${i + 1}',
              d['name'] ?? '-',
              d['nisn'] ?? '-',
              d['email'] ?? '-',
            ];
          }),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.all(4),
        ),
        pw.SizedBox(height: 16),

        // â”€â”€ Rekap Absensi â”€â”€
        pw.Text('Rekap Absensi Kelas',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        () {
          final hadir = absensiSnap.docs
              .where((d) => (d.data())['status'] == 'hadir')
              .length;
          final alpha = absensiSnap.docs
              .where((d) => (d.data())['status'] == 'alpha')
              .length;
          final izin = absensiSnap.docs
              .where((d) => (d.data())['status'] == 'izin')
              .length;
          final sakit = absensiSnap.docs
              .where((d) => (d.data())['status'] == 'sakit')
              .length;
          return pw.TableHelper.fromTextArray(
            headers: ['Hadir', 'Alpha', 'Izin', 'Sakit', 'Total'],
            data: [
              ['$hadir', '$alpha', '$izin', '$sakit',
                '${absensiSnap.docs.length}']
            ],
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold),
          );
        }(),
        pw.SizedBox(height: 16),

        // â”€â”€ Catatan Pelanggaran â”€â”€
        if (pelanggaranSnap.docs.isNotEmpty) ...[
          pw.Text(
              'Catatan Pelanggaran (${pelanggaranSnap.docs.length})',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Nama Siswa', 'Jenis', 'Poin', 'Deskripsi'],
            data: pelanggaranSnap.docs.map((doc) {
              final d = doc.data();
              return [
                d['student_name'] ?? '-',
                d['jenis'] ?? '-',
                '${d['poin'] ?? 0}',
                d['deskripsi'] ?? '-',
              ];
            }).toList(),
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
      ],
    ));

    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'Laporan_Kelas_${kelas}_${now.year}${now.month}${now.day}.pdf',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final kelas = user?.kelas ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppTheme.waliKelasColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.supervisor_account, color: AppTheme.waliKelasColor, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '-',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Wali Kelas: $kelas',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const AlertSystemWidget(),
          const SizedBox(height: 16),
          // Export PDF button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.waliKelasColor),
              onPressed: () => _exportPdf(context, kelas, user?.name ?? 'Wali Kelas'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Export Laporan Kelas (PDF)'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Daftar Siswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.usersCollection)
                .where('role', isEqualTo: 'SISWA')
                .where('kelas', isEqualTo: kelas)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) return const SizedBox.shrink();
              final students = snapshot.data!.docs;
              if (students.isEmpty) {
                return const Card(child: ListTile(title: Text('Belum ada siswa di kelas ini.')));
              }
              return Column(
                children: students.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(d['name'] ?? ''),
                      subtitle: Text('NISN: ${d['nisn'] ?? '-'}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _showStudentDetail(context, d),
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
}

class _WaliAbsensiTab extends StatelessWidget {
  const _WaliAbsensiTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kelas = auth.user?.kelas ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.absensiCollection)
          .where('kelas', isEqualTo: kelas).limit(50).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text("Belum ada data.", style: TextStyle(color: Color(0xFF6B7280))));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Belum ada data absensi.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final status = d['status'] ?? '';
            Color color;
            switch (status) {
              case 'hadir': color = AppTheme.success; break;
              case 'alpha': color = AppTheme.danger; break;
              case 'izin': color = AppTheme.warning; break;
              default: color = AppTheme.accent;
            }
            return Card(
              child: ListTile(
                leading: Icon(Icons.person_outlined, color: color),
                title: Text(d['student_name'] ?? d['student_id'] ?? ''),
                subtitle: Text(d['mapel'] ?? ''),
                trailing: Chip(
                  label: Text(status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                  backgroundColor: color,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WaliPelanggaranTab extends StatelessWidget {
  const _WaliPelanggaranTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kelas = auth.user?.kelas ?? '';

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _inputPelanggaran(context, kelas, auth.user?.name ?? ''),
        icon: const Icon(Icons.add),
        label: const Text('Catat Pelanggaran'),
        backgroundColor: AppTheme.waliKelasColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.pelanggaranCollection)
            .where('kelas', isEqualTo: kelas).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text("Belum ada data.", style: TextStyle(color: Color(0xFF6B7280))));
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.warning_amber_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Tidak ada catatan pelanggaran.', style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.waliKelasColor),
                  onPressed: () => _inputPelanggaran(context, kelas, auth.user?.name ?? ''),
                  icon: const Icon(Icons.add),
                  label: const Text('Catat Pelanggaran Pertama'),
                ),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final poin = d['poin'] ?? 0;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: poin >= 80 ? AppTheme.danger : AppTheme.warning,
                    child: Text('$poin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(d['student_name'] ?? ''),
                  subtitle: Text('${d['jenis'] ?? ''} • ${d['deskripsi'] ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 18),
                    onPressed: () => docs[i].reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _inputPelanggaran(BuildContext context, String kelas, String waliName) {
    final namaCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    final poinCtrl = TextEditingController(text: '10');
    String jenis = 'Tata Tertib';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Catat Pelanggaran Siswa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: namaCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Siswa')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: jenis,
                  items: const [
                    DropdownMenuItem(value: 'Tata Tertib', child: Text('Tata Tertib')),
                    DropdownMenuItem(value: 'Akademik', child: Text('Akademik')),
                    DropdownMenuItem(value: 'Sosial', child: Text('Sosial')),
                    DropdownMenuItem(value: 'Disiplin', child: Text('Disiplin')),
                  ],
                  onChanged: (v) => setS(() => jenis = v!),
                  decoration: const InputDecoration(labelText: 'Jenis'),
                ),
                const SizedBox(height: 8),
                TextField(controller: deskripsiCtrl, maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Deskripsi')),
                const SizedBox(height: 8),
                TextField(
                  controller: poinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Poin (0–100)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.waliKelasColor),
              onPressed: () async {
                if (namaCtrl.text.trim().isEmpty) return;
                final poin = int.tryParse(poinCtrl.text.trim()) ?? 10;
                await FirebaseFirestore.instance
                    .collection(FirebaseConstants.pelanggaranCollection)
                    .add({
                  'student_name': namaCtrl.text.trim(),
                  'kelas': kelas,
                  'jenis': jenis,
                  'deskripsi': deskripsiCtrl.text.trim(),
                  'poin': poin,
                  'input_by': 'wali_kelas',
                  'dicatat_oleh': waliName,
                  'tanggal': FieldValue.serverTimestamp(),
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

class _WaliBukuPenghubungTab extends StatelessWidget {
  const _WaliBukuPenghubungTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kelas = auth.user?.kelas ?? '';
    return Scaffold(
      appBar: null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _kirimPesan(context, auth.user?.name ?? 'Wali Kelas', kelas),
        icon: const Icon(Icons.send),
        label: const Text('Kirim Pesan'),
        backgroundColor: AppTheme.waliKelasColor,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.waliKelasColor.withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(Icons.book, color: AppTheme.waliKelasColor),
                SizedBox(width: 8),
                Text('Buku Penghubung Digital',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.waliKelasColor)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirebaseConstants.bukuPenghubungCollection)
                  .where('kelas', isEqualTo: kelas)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Belum ada pesan.\nKlik tombol + untuk kirim pesan ke orang tua.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ]),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final ts = (d['timestamp'] as Timestamp?)?.toDate();
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.waliKelasColor,
                          child: Icon(Icons.mail_outline, color: Colors.white),
                        ),
                        title: Text(d['student_name'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['pesan'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (ts != null)
                              Text('${ts.day}/${ts.month}/${ts.year}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(d['status'] ?? 'terkirim',
                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                          backgroundColor: AppTheme.success,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _kirimPesan(BuildContext context, String waliName, String kelas) {
    final namaCtrl = TextEditingController();
    final pesanCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim Pesan ke Orang Tua'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Siswa')),
            const SizedBox(height: 8),
            TextField(controller: pesanCtrl, maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Pesan untuk Orang Tua',
                  hintText: 'contoh: Kehadiran ananda perlu ditingkatkan...',
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.waliKelasColor),
            onPressed: () async {
              if (namaCtrl.text.trim().isEmpty || pesanCtrl.text.trim().isEmpty) return;
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.bukuPenghubungCollection)
                  .add({
                'student_name': namaCtrl.text.trim(),
                'kelas': kelas,
                'pesan': pesanCtrl.text.trim(),
                'wali_name': waliName,
                'status': 'terkirim',
                'timestamp': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('âœ… Pesan berhasil dikirim!'), backgroundColor: AppTheme.success),
                );
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Kirim'),
          ),
        ],
      ),
    );
  }
}

class _WaliProfilTab extends StatelessWidget {
  const _WaliProfilTab();

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
            backgroundColor: AppTheme.waliKelasColor,
            child: Icon(Icons.supervisor_account, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '-',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '-', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          _WaliInfoRow(label: 'Kelas', value: user?.kelas ?? '-'),
          _WaliInfoRow(label: 'NIP', value: user?.nip ?? '-'),
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

class _WaliInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _WaliInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary))),
          const Text(': '),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}