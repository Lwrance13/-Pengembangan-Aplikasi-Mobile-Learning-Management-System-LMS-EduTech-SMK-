import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/roles.dart';
import '../student/student_dashboard_page.dart';
import '../teacher/teacher_dashboard_page.dart';
import '../wali_kelas/wali_dashboard_page.dart';
import '../bk/bk_dashboard_page.dart';
import '../piket/piket_dashboard_page.dart';
import '../admin/admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (success && mounted) {
      _navigateByRole(auth.user!.role);
    }
  }

  void _navigateByRole(String role) {
    Widget destination;
    switch (role) {
      case AppRoles.siswa:
        destination = const StudentDashboardPage();
        break;
      case AppRoles.guruMapel:
        destination = const TeacherDashboardPage();
        break;
      case AppRoles.waliKelas:
        destination = const WaliDashboardPage();
        break;
      case AppRoles.guruBk:
        destination = const BkDashboardPage();
        break;
      case AppRoles.guruPiket:
        destination = const PiketDashboardPage();
        break;
      case AppRoles.admin:
        destination = const AdminDashboardPage();
        break;
      default:
        destination = const LoginPage();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Logo / Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.school, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'EduTech SMK',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Learning Management System',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 48),
              // Login Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Masuk ke Akun',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) =>
                              v == null || !v.contains('@') ? 'Masukkan email yang valid' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
                        ),
                        if (auth.error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              auth.error!,
                              style: const TextStyle(color: AppTheme.danger),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _login,
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            // Navigate to forgot password
                          },
                          child: const Text('Lupa Password?'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '© 2024 EduTech SMK. All rights reserved.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
