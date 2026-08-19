import 'package:flutter/material.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  static const _roleData = [
    {'role': AppRoles.siswa, 'icon': Icons.person_outlined, 'color': AppTheme.siswaColor},
    {'role': AppRoles.guruMapel, 'icon': Icons.menu_book_outlined, 'color': AppTheme.guruMapelColor},
    {'role': AppRoles.waliKelas, 'icon': Icons.supervisor_account_outlined, 'color': AppTheme.waliKelasColor},
    {'role': AppRoles.guruBk, 'icon': Icons.psychology_outlined, 'color': AppTheme.guruBkColor},
    {'role': AppRoles.guruPiket, 'icon': Icons.access_time_outlined, 'color': AppTheme.guruPiketColor},
    {'role': AppRoles.admin, 'icon': Icons.admin_panel_settings_outlined, 'color': AppTheme.adminColor},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Role Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: _roleData.map((data) {
            final role = data['role'] as String;
            final icon = data['icon'] as IconData;
            final color = data['color'] as Color;
            return _RoleCard(
              role: role,
              icon: icon,
              color: color,
              onTap: () => _demoLogin(context, role),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _demoLogin(BuildContext context, String role) {
    // Demo: show selected role info
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Role: ${AppRoles.getDisplayName(role)}'),
        content: Text('Untuk demo, login menggunakan akun ${AppRoles.getDisplayName(role).toLowerCase()} yang sudah terdaftar di Firebase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              AppRoles.getDisplayName(role),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
