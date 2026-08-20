import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/notification_trigger_service.dart';
import '../shared/notification_list_page.dart';
import 'upload_material_page.dart';
import 'kuis_questions_page.dart';
import 'tugas_submissions_page.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _TeacherHomeTab(),
      const _TeacherMateriTab(),
      const _TeacherKuisTab(),
      const _TeacherMonitoringTab(),
      const _TeacherAbsensiTab(),
      const _TeacherProfilTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK — Guru Mapel'),
        backgroundColor: AppTheme.guruMapelColor,
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
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Materi'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), label: 'Kuis'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Monitoring'),
          NavigationDestination(icon: Icon(Icons.how_to_reg_outlined), label: 'Absensi'),
          NavigationDestination(icon: Icon(Icons.person_outlined), label: 'Profil'),
        ],
      ),
    );
  }
}

class _TeacherHomeTab extends StatelessWidget {
  const _TeacherHomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppTheme.guruMapelColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: AppTheme.guruMapelColor, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Guru',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Mapel: ${user?.mapel ?? '-'}',
                            style: const TextStyle(color: Colors.white70)),
                        Text('NIP: ${user?.nip ?? '-'}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruMapelColor),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UploadMaterialPage()),
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Materi'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                  onPressed: () => _createTugas(context, user?.mapel ?? ''),
                  icon: const Icon(Icons.assignment_add),
                  label: const Text('Buat Tugas'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Tugas Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.tugasCollection)
                .where('guru_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid).limit(10).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) return const LinearProgressIndicator();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Card(child: ListTile(title: Text('Belum ada tugas dibuat.')));
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment_outlined, color: AppTheme.guruMapelColor),
                      title: Text(d['judul'] ?? ''),
                      subtitle: Text(d['kelas'] ?? ''),
                      trailing: TextButton.icon(
                        icon: const Icon(Icons.people_outline, size: 16),
                        label: Text('${d['submission_count'] ?? 0}'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TugasSubmissionsPage(
                              tugasId: doc.id,
                              tugasJudul: d['judul'] ?? '',
                            ),
                          ),
                        ),
                      ),
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

  void _createTugas(BuildContext context, String mapel) {
    final judulCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    final kelasCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Tugas Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: judulCtrl, decoration: const InputDecoration(labelText: 'Judul Tugas')),
            const SizedBox(height: 8),
            TextField(controller: kelasCtrl, decoration: const InputDecoration(labelText: 'Kelas')),
            const SizedBox(height: 8),
            TextField(controller: deskripsiCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              final judul = judulCtrl.text.trim();
              final kelas = kelasCtrl.text.trim();
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.tugasCollection)
                  .add({
                'judul': judul,
                'deskripsi': deskripsiCtrl.text.trim(),
                'kelas': kelas,
                'mapel': mapel,
                'guru_id': uid,
                'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
                'created_at': FieldValue.serverTimestamp(),
                'submission_count': 0,
              });
              // 🔔 Trigger FCM notifikasi ke semua siswa kelas ini
              await NotificationTriggerService.notifyTugasBaru(
                kelas: kelas,
                judulTugas: judul,
                mapel: mapel,
                guruId: uid ?? '',
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _TeacherMateriTab extends StatelessWidget {
  const _TeacherMateriTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UploadMaterialPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Upload Materi'),
        backgroundColor: AppTheme.guruMapelColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.materiCollection)
            .where('guru_id', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError) return const Center(child: Text("Belum ada data.", style: TextStyle(color: Color(0xFF6B7280))));
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada materi diunggah.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: Icon(
                    d['type'] == 'video' ? Icons.play_circle : Icons.picture_as_pdf,
                    color: AppTheme.guruMapelColor,
                  ),
                  title: Text(d['judul'] ?? ''),
                  subtitle: Text(d['kelas'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
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
}

class _TeacherAbsensiTab extends StatelessWidget {
  const _TeacherAbsensiTab();

  @override
  Widget build(BuildContext context) {
    final kelasCtrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: AppTheme.guruMapelColor,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.how_to_reg, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Input Absensi Real-time',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: kelasCtrl,
            decoration: const InputDecoration(
              labelText: 'Masukkan Kelas',
              prefixIcon: Icon(Icons.class_outlined),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruMapelColor),
            onPressed: () => _openAbsensi(context, kelasCtrl.text.trim()),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Mulai Absensi'),
          ),
        ],
      ),
    );
  }

  void _openAbsensi(BuildContext context, String kelas) {
    if (kelas.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _AbsensiInputPage(kelas: kelas)),
    );
  }
}

class _AbsensiInputPage extends StatelessWidget {
  final String kelas;

  const _AbsensiInputPage({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Absensi Kelas $kelas'),
        backgroundColor: AppTheme.guruMapelColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.usersCollection)
            .where('role', isEqualTo: 'SISWA')
            .where('kelas', isEqualTo: kelas)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError) return const Center(child: Text("Belum ada data.", style: TextStyle(color: Color(0xFF6B7280))));
          final students = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, i) {
              final d = students[i].data() as Map<String, dynamic>;
              return _AbsensiRow(
                studentId: students[i].id,
                studentName: d['name'] ?? '',
                kelas: kelas,
              );
            },
          );
        },
      ),
    );
  }
}

class _AbsensiRow extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String kelas;

  const _AbsensiRow({required this.studentId, required this.studentName, required this.kelas});

  @override
  State<_AbsensiRow> createState() => _AbsensiRowState();
}

class _AbsensiRowState extends State<_AbsensiRow> {
  String _status = 'hadir';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_outlined),
        title: Text(widget.studentName),
        trailing: DropdownButton<String>(
          value: _status,
          onChanged: (val) {
            if (val == null) return;
            setState(() => _status = val);
            FirebaseFirestore.instance
                .collection(FirebaseConstants.absensiCollection)
                .add({
              'student_id': widget.studentId,
              'kelas': widget.kelas,
              'status': val,
              'tanggal': Timestamp.fromDate(DateTime.now()),
              'guru_id': FirebaseAuth.instance.currentUser?.uid,
            });
          },
          items: const [
            DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
            DropdownMenuItem(value: 'alpha', child: Text('Alpha')),
            DropdownMenuItem(value: 'izin', child: Text('Izin')),
            DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
          ],
        ),
      ),
    );
  }
}

class _TeacherKuisTab extends StatelessWidget {
  const _TeacherKuisTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createKuis(context),
        icon: const Icon(Icons.add),
        label: const Text('Buat Kuis'),
        backgroundColor: AppTheme.guruMapelColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.kuisCollection)
            .where('guru_id', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Belum ada kuis dibuat.'));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada kuis. Klik tombol + untuk buat kuis baru.'),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final deadline = (d['deadline'] as Timestamp?)?.toDate();
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.guruMapelColor,
                    child: Icon(Icons.quiz, color: Colors.white),
                  ),
                  title: Text(d['judul'] ?? ''),
                  subtitle: Text(
                    'Kelas: ${d['kelas'] ?? '-'}'
                    '${deadline != null ? '\nDeadline: ${deadline.day}/${deadline.month}/${deadline.year}' : ''}',
                  ),
                  isThreeLine: deadline != null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: AppTheme.guruMapelColor),
                        tooltip: 'Kelola Soal',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KuisQuestionsPage(
                              kuisId: docs[i].id,
                              kuisJudul: d['judul'] ?? '',
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                        onPressed: () => docs[i].reference.delete(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _createKuis(BuildContext context) {
    final judulCtrl = TextEditingController();
    final kelasCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Kuis Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: judulCtrl,
              decoration: const InputDecoration(labelText: 'Judul Kuis'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: kelasCtrl,
              decoration: const InputDecoration(labelText: 'Kelas', hintText: 'XII-TKJ-1'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              final auth = context.read<AuthProvider>();
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.kuisCollection)
                  .add({
                'judul': judulCtrl.text.trim(),
                'kelas': kelasCtrl.text.trim(),
                'mapel': auth.user?.mapel ?? '',
                'guru_id': uid,
                'guru_name': auth.user?.name ?? '',
                'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
                'created_at': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Kuis berhasil dibuat!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }
}

class _TeacherMonitoringTab extends StatelessWidget {
  const _TeacherMonitoringTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mapel = auth.user?.mapel ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Statistik Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          // Statistik absensi
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.absensiCollection)
                .where('guru_id', isEqualTo: uid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
              final docs = snap.data?.docs ?? [];
              final hadir = docs.where((d) => (d.data() as Map)['status'] == 'hadir').length;
              final alpha = docs.where((d) => (d.data() as Map)['status'] == 'alpha').length;
              final total = docs.length;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📊 Absensi Kelas Saya', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatBox('Total', total, AppTheme.primary),
                          _StatBox('Hadir', hadir, AppTheme.success),
                          _StatBox('Alpha', alpha, AppTheme.danger),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Input nilai manual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Input Nilai Siswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruMapelColor),
                onPressed: () => _inputNilai(context, mapel, uid),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Input Nilai'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Daftar nilai yang sudah diinput
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.nilaiCollection)
                .where('guru_id', isEqualTo: uid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Card(child: ListTile(
                  leading: Icon(Icons.grade_outlined),
                  title: Text('Belum ada nilai diinput.'),
                ));
              }
              return Column(
                children: docs.take(10).map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final nilai = (d['nilai'] as num?)?.toDouble() ?? 0;
                  final Color c;
                  if (nilai >= 80) { c = AppTheme.success; }
                  else if (nilai >= 60) { c = AppTheme.warning; }
                  else { c = AppTheme.danger; }
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: c,
                        child: Text('${nilai.round()}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(d['student_name'] ?? ''),
                      subtitle: Text('${d['judul'] ?? ''} • ${d['jenis'] ?? ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 18),
                        onPressed: () => doc.reference.delete(),
                      ),
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

  void _inputNilai(BuildContext context, String mapel, String? uid) {
    final namaCtrl = TextEditingController();
    final studentIdCtrl = TextEditingController();
    final judulCtrl = TextEditingController();
    final nilaiCtrl = TextEditingController();
    String jenis = 'tugas';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Input Nilai Siswa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: namaCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Siswa')),
                const SizedBox(height: 8),
                TextField(controller: judulCtrl,
                    decoration: const InputDecoration(labelText: 'Judul Tugas/Kuis')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: jenis,
                  items: const [
                    DropdownMenuItem(value: 'tugas', child: Text('Tugas')),
                    DropdownMenuItem(value: 'kuis', child: Text('Kuis')),
                    DropdownMenuItem(value: 'ulangan', child: Text('Ulangan')),
                    DropdownMenuItem(value: 'ujian', child: Text('Ujian')),
                  ],
                  onChanged: (v) => setState(() => jenis = v!),
                  decoration: const InputDecoration(labelText: 'Jenis'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nilaiCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nilai (0-100)',
                    hintText: '85',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final nilai = double.tryParse(nilaiCtrl.text.trim());
                if (nilai == null || nilai < 0 || nilai > 100) return;
                await FirebaseFirestore.instance
                    .collection(FirebaseConstants.nilaiCollection)
                    .add({
                  'student_name': namaCtrl.text.trim(),
                  'student_id': studentIdCtrl.text.trim(),
                  'judul': judulCtrl.text.trim(),
                  'jenis': jenis,
                  'mapel': mapel,
                  'nilai': nilai,
                  'guru_id': uid,
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

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _TeacherProfilTab extends StatelessWidget {
  const _TeacherProfilTab();

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
            backgroundColor: AppTheme.guruMapelColor,
            child: Icon(Icons.person, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '-',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '-', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          _InfoRow(label: 'NIP', value: user?.nip ?? '-'),
          _InfoRow(label: 'Mapel', value: user?.mapel ?? '-'),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label, style: const TextStyle(color: AppTheme.textSecondary))),
          const Text(': '),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
