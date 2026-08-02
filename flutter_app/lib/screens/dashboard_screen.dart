import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_text.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.instance.getDashboardSummary();
      setState(() { _summary = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentSecondary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accentSecondary,
                  backgroundColor: AppColors.surface,
                  child: Stack(
                    children: [
                      // Subtle background glow effect
                      Positioned(
                        top: -100, right: -50,
                        child: Container(
                          width: 300, height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentPrimary.withOpacity(0.15),
                            boxShadow: [BoxShadow(blurRadius: 100, color: AppColors.accentPrimary.withOpacity(0.15))],
                          ),
                        ),
                      ),
                      ListView(
                        padding: const EdgeInsets.fromLTRB(24, 120, 24, 100),
                        children: [
                          _NetWorthHero(summary: _summary!).animate().fade(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
                          const SizedBox(height: 24),
                          _MonthSummaryRow(summary: _summary!).animate(delay: 100.ms).fade(duration: 500.ms).slideY(begin: 0.1),
                          const SizedBox(height: 32),
                          const _SectionHeader('Spending by Category').animate(delay: 200.ms).fade(),
                          const SizedBox(height: 16),
                          _CategoryPieChart(data: _summary!['spending_by_category']).animate(delay: 250.ms).fade(duration: 500.ms).scaleXY(begin: 0.95),
                          const SizedBox(height: 32),
                          const _SectionHeader('Monthly Trends').animate(delay: 300.ms).fade(),
                          const SizedBox(height: 16),
                          _MonthlyBarChart(data: _summary!['monthly_expenses']).animate(delay: 350.ms).fade(duration: 500.ms).slideY(begin: 0.1),
                          const SizedBox(height: 32),
                          const _SectionHeader('Your Accounts').animate(delay: 400.ms).fade(),
                          const SizedBox(height: 16),
                          _AccountsList(accounts: _summary!['accounts']).animate(delay: 450.ms).fade(duration: 500.ms).slideY(begin: 0.1),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _NetWorthHero extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _NetWorthHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final netWorth = summary['net_worth'] as num;
    
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Total Net Worth', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          GradientText(
            fmt.format(netWorth),
            gradient: AppGradients.primaryGradient,
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1.5),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeroStat(label: 'Assets', value: fmt.format(summary['total_balance'] + summary['total_current_value']), color: AppColors.success),
              Container(width: 1, height: 40, color: AppColors.border),
              _HeroStat(label: 'Liabilities', value: fmt.format(summary['total_debt']), color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _HeroStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

class _MonthSummaryRow extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _MonthSummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 1);
    return Row(
      children: [
        Expanded(child: _StatGlassCard(
          label: 'Income', icon: Icons.arrow_downward_rounded,
          value: fmt.format(summary['month_income']), color: AppColors.success,
        )),
        const SizedBox(width: 16),
        Expanded(child: _StatGlassCard(
          label: 'Spent', icon: Icons.arrow_upward_rounded,
          value: fmt.format(summary['month_expense']), color: AppColors.error,
        )),
        const SizedBox(width: 16),
        Expanded(child: _StatGlassCard(
          label: 'Saved', icon: Icons.savings_rounded,
          value: fmt.format(summary['month_savings']), color: AppColors.accentSecondary,
        )),
      ],
    );
  }
}

class _StatGlassCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  
  const _StatGlassCard({required this.label, required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        const Spacer(),
        Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withOpacity(0.5)),
      ],
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<dynamic> data;
  const _CategoryPieChart({required this.data});

  static const _colors = [
    AppColors.accentPrimary, AppColors.accentSecondary, AppColors.success,
    AppColors.warning, Color(0xFFF06292), Color(0xFF4FC3F7),
    Color(0xFFFFB74D), Color(0xFFAED581), Color(0xFF9575CD), Color(0xFF4DB6AC),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyState(message: 'No expenses this month');
    
    final total = data.fold<double>(0, (s, d) => s + (d['total'] as num));
    return GlassCard(
      height: 240,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                  sections: data.asMap().entries.map((e) {
                    final color = _colors[e.key % _colors.length];
                    final val = (e.value['total'] as num).toDouble();
                    return PieChartSectionData(
                      value: val,
                      color: color,
                      radius: 20,
                      showTitle: false,
                    );
                  }).toList(),
                  sectionsSpace: 4,
                  centerSpaceRadius: 50,
                )),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text(
                      NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹').format(total),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.asMap().entries.take(5).map((e) {
                final color = _colors[e.key % _colors.length];
                final pct = ((e.value['total'] as num) / total * 100).toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value['category'] ?? 'Other', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                    Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<dynamic> data;
  const _MonthlyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyState(message: 'No transaction data yet');
    final maxVal = data.fold<double>(0, (m, d) => m < (d['expense'] as num) ? (d['expense'] as num).toDouble() : m);
    
    return GlassCard(
      height: 220,
      padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
      child: BarChart(BarChartData(
        maxY: (maxVal * 1.2 > 0) ? maxVal * 1.2 : 100,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx < 0 || idx >= data.length) return const SizedBox();
              final month = data[idx]['month'] as String;
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(month.length >= 7 ? month.substring(5) : month, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              );
            },
          )),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: data.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [BarChartRodData(
            toY: (e.value['expense'] as num).toDouble(),
            gradient: AppGradients.primaryGradient,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: (maxVal * 1.2 > 0) ? maxVal * 1.2 : 100,
              color: AppColors.surfaceLight,
            ),
          )],
        )).toList(),
      )),
    );
  }
}

class _AccountsList extends StatelessWidget {
  final List<dynamic> accounts;
  const _AccountsList({required this.accounts});

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const _EmptyState(message: 'No accounts added yet');
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    
    return Column(
      children: accounts.map((a) {
        final balance = a['balance'] ?? 0;
        final isNegative = balance < 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.accentSecondary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${a['type'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ])),
              Text(fmt.format(balance), style: TextStyle(fontWeight: FontWeight.w700, color: isNegative ? AppColors.error : AppColors.textPrimary, fontSize: 16, letterSpacing: -0.5)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    alignment: Alignment.center,
    child: Column(
      children: [
        Icon(Icons.inbox_rounded, color: AppColors.textSecondary.withOpacity(0.3), size: 48),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 48),
      const SizedBox(height: 16),
      const Text('Connection Failed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 8),
      Text('Ensure the backend is running and URL is correct.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
    ]));
  }
}
