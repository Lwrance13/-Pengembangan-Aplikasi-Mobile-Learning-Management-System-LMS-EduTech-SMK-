import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/firebase_constants.dart';
import '../shared/notification_list_page.dart';
import '../auth/login_page.dart';
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
      _WaliProfilTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK — Wali Kelas'),
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
          NavigationDestination(icon: Icon(Icons.person_outlined), label: 'Profil'),
        ],
      ),
    );
  }
}

class _WaliHomeTab extends StatelessWidget {
  const _WaliHomeTab();

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
                      onTap: () {},
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.pelanggaranCollection)
          .where('kelas', isEqualTo: kelas).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text("Belum ada data.", style: TextStyle(color: Color(0xFF6B7280))));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Tidak ada catatan pelanggaran.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
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
                subtitle: Text(d['deskripsi'] ?? ''),
                trailing: Text(d['jenis'] ?? '',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ),
            );
          },
        );
      },
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
