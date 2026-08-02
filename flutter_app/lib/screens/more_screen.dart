import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'loans_screen.dart';
import 'investments_screen.dart';
import 'subscriptions_screen.dart';
import 'goals_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MoreItem(icon: Icons.credit_card_rounded, label: 'Loans', screen: const LoansScreen()),
          _MoreItem(icon: Icons.trending_up_rounded, label: 'Investments', screen: const InvestmentsScreen()),
          _MoreItem(icon: Icons.subscriptions_rounded, label: 'Subscriptions', screen: const SubscriptionsScreen()),
          _MoreItem(icon: Icons.flag_rounded, label: 'Goals', screen: const GoalsScreen()),
          _MoreItem(icon: Icons.category_rounded, label: 'Categories', screen: const CategoriesScreen()),
          const SizedBox(height: 20),
          _MoreItem(icon: Icons.settings_rounded, label: 'Settings', screen: const SettingsScreen()),
        ],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget screen;
  const _MoreItem({required this.icon, required this.label, required this.screen});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surfaceAlt,
      child: ListTile(
        leading: Icon(icon, color: AppColors.accentPrimary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
