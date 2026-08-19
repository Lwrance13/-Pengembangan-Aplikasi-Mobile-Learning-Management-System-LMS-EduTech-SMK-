import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/notification_trigger_service.dart';
import '../shared/notification_list_page.dart';
import '../auth/login_page.dart';
import 'upload_material_page.dart';

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
                      trailing: Text('${d['submission_count'] ?? 0} Submit'),
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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
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
