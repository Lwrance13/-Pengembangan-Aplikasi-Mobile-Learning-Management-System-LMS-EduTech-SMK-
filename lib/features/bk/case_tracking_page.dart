import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

class CaseTrackingPage extends StatelessWidget {
  const CaseTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard Kasus BK',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          const _CaseSummaryCards(),
          const SizedBox(height: 20),
          const Text('Tren Kasus per Kategori',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          const _CaseBarChart(),
          const SizedBox(height: 20),
          const Text('Daftar Kasus Aktif',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const _ActiveCaseList(),
        ],
      ),
    );
  }
}

class _CaseSummaryCards extends StatelessWidget {
  const _CaseSummaryCards();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.konselingCollection)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;
        final pending = docs.where((d) => (d.data() as Map)['status'] == 'pending').length;
        final approved = docs.where((d) => (d.data() as Map)['status'] == 'approved').length;
        final done = docs.where((d) => (d.data() as Map)['status'] == 'done').length;

        return Row(
          children: [
            _StatCard(label: 'Total', value: total, color: AppTheme.primary),
            _StatCard(label: 'Pending', value: pending, color: AppTheme.warning),
            _StatCard(label: 'Aktif', value: approved, color: AppTheme.success),
            _StatCard(label: 'Selesai', value: done, color: AppTheme.textSecondary),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text('$value',
                  style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseBarChart extends StatelessWidget {
  const _CaseBarChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 20,
          barGroups: [
            _bar(0, 8, AppTheme.primary),
            _bar(1, 5, AppTheme.warning),
            _bar(2, 12, AppTheme.danger),
            _bar(3, 3, AppTheme.success),
            _bar(4, 6, AppTheme.accent),
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  const labels = ['Akademik', 'Sosial', 'Pribadi', 'Karir', 'Pelanggaran'];
                  if (value.toInt() >= labels.length) return const SizedBox();
                  return Text(labels[value.toInt()],
                      style: const TextStyle(fontSize: 9));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: color, width: 18, borderRadius: BorderRadius.circular(4))],
    );
  }
}

class _ActiveCaseList extends StatelessWidget {
  const _ActiveCaseList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.konselingCollection)
          .where('status', whereIn: ['pending', 'approved']).limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Card(child: ListTile(title: Text('Tidak ada kasus aktif.')));
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final tanggal = (d['tanggal'] as Timestamp?)?.toDate();
            final status = d['status'] ?? 'pending';
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline, color: AppTheme.guruBkColor),
                title: Text(d['student_name'] ?? ''),
                subtitle: Text('${d['kategori'] ?? '-'} • ${tanggal != null ? '${tanggal.day}/${tanggal.month}/${tanggal.year}' : '-'}'),
                trailing: status == 'approved'
                    ? ElevatedButton(
                        onPressed: () => doc.reference.update({'status': 'done'}),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(horizontal: 10)),
                        child: const Text('Selesai', style: TextStyle(fontSize: 11)),
                      )
                    : const Chip(
                        label: Text('Pending',
                            style: TextStyle(color: Colors.white, fontSize: 10)),
                        backgroundColor: AppTheme.warning,
                      ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
