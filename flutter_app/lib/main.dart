import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/loans_screen.dart';
import 'screens/investments_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/more_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.loadBaseUrl();
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    const _NavItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
    const _NavItem(icon: Icons.receipt_long_rounded, label: 'Transactions'),
    const _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Accounts'),
    const _NavItem(icon: Icons.trending_up_rounded, label: 'Invest'),
    const _NavItem(icon: Icons.more_horiz_rounded, label: 'More'),
  ];

  // We group the extra screens into a 'More' menu for mobile, but show them all on desktop.
  final List<_NavItem> _allNavItems = [
    const _NavItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
    const _NavItem(icon: Icons.receipt_long_rounded, label: 'Transactions'),
    const _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Accounts'),
    const _NavItem(icon: Icons.credit_card_rounded, label: 'Loans'),
    const _NavItem(icon: Icons.trending_up_rounded, label: 'Invest'),
    const _NavItem(icon: Icons.subscriptions_rounded, label: 'Subs'),
    const _NavItem(icon: Icons.flag_rounded, label: 'Goals'),
    const _NavItem(icon: Icons.category_rounded, label: 'Category'),
    const _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    LoansScreen(),
    InvestmentsScreen(),
    SubscriptionsScreen(),
    GoalsScreen(),
    CategoriesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 750;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.border, width: 1)),
                color: AppColors.surface,
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      backgroundColor: Colors.transparent,
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                      labelType: NavigationRailLabelType.all,
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: _AppLogo(),
                      ),
                      destinations: _allNavItems
                          .map((n) => NavigationRailDestination(
                                icon: Icon(n.icon),
                                label: Text(n.label),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _screens[_selectedIndex],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile: Floating Glass Pill
    return Scaffold(
      extendBody: true, // Allows body to flow under the floating nav bar
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedIndex < 4 
            ? _screens[_selectedIndex] 
            : const MoreScreen(), // opens list of other screens
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: AppGradients.glassGradient,
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _navItems.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  final isSelected = _selectedIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentPrimary.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        item.icon,
                        color: isSelected ? AppColors.accentSecondary : AppColors.textSecondary,
                        size: 26,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ).animate().slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppGradients.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPrimary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        const Text('Oasis', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5)),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
