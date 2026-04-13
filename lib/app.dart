import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/ios_theme.dart';
import 'features/driver/screens/route_screen.dart';
import 'features/sales/screens/sales_home_screen.dart';
import 'features/sales/screens/my_orders_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/accountant/screens/accountant_dashboard_screen.dart';
import 'features/accountant/screens/accountant_reports_screen.dart';
import 'features/accountant/screens/accountant_taxes_screen.dart';
import 'features/director/screens/director_dashboard_screen.dart';
import 'features/director/screens/live_tracking_screen.dart';
import 'features/director/screens/team_screen.dart';
import 'features/owner/screens/owner_dashboard_screen.dart';
import 'features/owner/screens/owner_analytics_screen.dart';
import 'features/owner/screens/owner_settings_screen.dart';
import 'features/driver/screens/earnings_screen.dart';
import 'features/driver/screens/kpi_screen.dart';
import 'features/sales/screens/sales_analytics_screen.dart';
import 'features/warehouse/warehouse_feature.dart';

/// Main app entry point with role-based navigation
class DeliveryApp extends StatefulWidget {
  final UserRole userRole;
  final bool isFirstRun;

  const DeliveryApp({
    super.key,
    required this.userRole,
    required this.isFirstRun,
  });

  @override
  State<DeliveryApp> createState() => _DeliveryAppState();
}

class _DeliveryAppState extends State<DeliveryApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.isFirstRun;
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for iOS look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: IOSTheme.bgSecondary,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'DeliveryMaker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // fontFamily: 'Manrope',
        scaffoldBackgroundColor: IOSTheme.bgPrimary,
        colorScheme: const ColorScheme.light(
          primary: IOSTheme.systemBlue,
          secondary: IOSTheme.systemIndigo,
          error: IOSTheme.systemRed,
          surface: IOSTheme.bgSecondary,
          background: IOSTheme.bgPrimary,
        ),
      ),
      home: _showOnboarding
          ? OnboardingScreen(
              userRole: widget.userRole,
              onCompleted: () => setState(() => _showOnboarding = false),
            )
          : RoleRouter(role: widget.userRole),
    );
  }
}

/// User roles in the system
enum UserRole {
  driver,
  sales,
  warehouse,
  accountant,
  director,
  owner,
}

/// Routes user to appropriate interface based on role
class RoleRouter extends StatelessWidget {
  final UserRole role;

  const RoleRouter({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.driver:
        return const DriverNavigation();
      case UserRole.sales:
        return const SalesNavigation();
      case UserRole.warehouse:
        return const WarehouseNavigation();
      case UserRole.accountant:
        return const AccountantNavigation();
      case UserRole.director:
        return const DirectorNavigation();
      case UserRole.owner:
        return const OwnerNavigation();
    }
  }
}

/// Driver navigation - map and deliveries
class DriverNavigation extends StatefulWidget {
  const DriverNavigation({super.key});

  @override
  State<DriverNavigation> createState() => _DriverNavigationState();
}

class _DriverNavigationState extends State<DriverNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    RouteScreen(),
    EarningsScreen(),
    DriverKpiScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map,
                  label: 'Маршрут',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                _NavItem(
                  icon: Icons.attach_money_outlined,
                  activeIcon: Icons.attach_money,
                  label: 'Заработок',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                _NavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: 'KPI',
                  isActive: _currentIndex == 2,
                  onTap: () => _onTap(2),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Профиль',
                  isActive: _currentIndex == 3,
                  onTap: () => _onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex != index) {
      IOSTheme.lightImpact();
      setState(() => _currentIndex = index);
    }
  }
}

/// Sales navigation - catalog and clients
class SalesNavigation extends StatefulWidget {
  const SalesNavigation({super.key});

  @override
  State<SalesNavigation> createState() => _SalesNavigationState();
}

class _SalesNavigationState extends State<SalesNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    SalesHomeScreen(),
    MyOrdersScreen(),
    SalesAnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Главная',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag,
                  label: 'Заказы',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  label: 'Аналитика',
                  isActive: _currentIndex == 2,
                  onTap: () => _onTap(2),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Профиль',
                  isActive: _currentIndex == 3,
                  onTap: () => _onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex != index) {
      IOSTheme.lightImpact();
      setState(() => _currentIndex = index);
    }
  }
}

/// Warehouse Manager navigation — receiving, picking, write-off, inventory
class WarehouseNavigation extends StatefulWidget {
  const WarehouseNavigation({super.key});

  @override
  State<WarehouseNavigation> createState() => _WarehouseNavigationState();
}

class _WarehouseNavigationState extends State<WarehouseNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    WarehouseDashboardScreen(),
    ReceiveGoodsScreen(),
    PickingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.warehouse_outlined,
                  activeIcon: Icons.warehouse,
                  label: 'Склад',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                _NavItem(
                  icon: Icons.input_outlined,
                  activeIcon: Icons.input,
                  label: 'Приёмка',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                _NavItem(
                  icon: Icons.checklist_outlined,
                  activeIcon: Icons.checklist,
                  label: 'Сборка',
                  isActive: _currentIndex == 2,
                  onTap: () => _onTap(2),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Профиль',
                  isActive: _currentIndex == 3,
                  onTap: () => _onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex != index) {
      IOSTheme.lightImpact();
      setState(() => _currentIndex = index);
    }
  }
}

/// Accountant navigation — invoices, taxes, reports, profile
class AccountantNavigation extends StatefulWidget {
  const AccountantNavigation({super.key});

  @override
  State<AccountantNavigation> createState() => _AccountantNavigationState();
}

class _AccountantNavigationState extends State<AccountantNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    AccountantDashboardScreen(),
    AccountantReportsScreen(),
    AccountantTaxesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Главная',
                isActive: _currentIndex == 0,
                onTap: () => _onTap(0),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Отчёты',
                isActive: _currentIndex == 1,
                onTap: () => _onTap(1),
              ),
              _NavItem(
                icon: Icons.account_balance_outlined,
                activeIcon: Icons.account_balance,
                label: 'Налоги',
                isActive: _currentIndex == 2,
                onTap: () => _onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Профиль',
                isActive: _currentIndex == 3,
                onTap: () => _onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex != index) {
      IOSTheme.lightImpact();
      setState(() => _currentIndex = index);
    }
  }
}

/// Director navigation — KPIs, live map, team, reports
class DirectorNavigation extends StatefulWidget {
  const DirectorNavigation({super.key});

  @override
  State<DirectorNavigation> createState() => _DirectorNavigationState();
}

class _DirectorNavigationState extends State<DirectorNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    DirectorDashboardScreen(),
    LiveTrackingScreen(),
    TeamScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.speed_outlined,
                activeIcon: Icons.speed,
                label: 'KPI',
                isActive: _currentIndex == 0,
                onTap: () => _onTap(0),
              ),
              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'Карта',
                isActive: _currentIndex == 1,
                onTap: () => _onTap(1),
              ),
              _NavItem(
                icon: Icons.people_outlined,
                activeIcon: Icons.people,
                label: 'Команда',
                isActive: _currentIndex == 2,
                onTap: () => _onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Профиль',
                isActive: _currentIndex == 3,
                onTap: () => _onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex != index) {
      IOSTheme.lightImpact();
      setState(() => _currentIndex = index);
    }
  }
}

/// Owner navigation — financial overview, employees, settings, profile
class OwnerNavigation extends StatefulWidget {
  const OwnerNavigation({super.key});

  @override
  State<OwnerNavigation> createState() => _OwnerNavigationState();
}

class _OwnerNavigationState extends State<OwnerNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    OwnerDashboardScreen(),
    OwnerAnalyticsScreen(),
    OwnerSettingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Обзор',
                isActive: _currentIndex == 0,
                onTap: () => _onTap(0),
              ),
              _NavItem(
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics,
                label: 'Аналитика',
                isActive: _currentIndex == 1,
                onTap: () => _onTap(1),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Настройки',
                isActive: _currentIndex == 2,
                onTap: () => _onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Профиль',
                isActive: _currentIndex == 3,
                onTap: () => _onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex != index) {
      IOSTheme.lightImpact();
      setState(() => _currentIndex = index);
    }
  }
}

/// Bottom navigation item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? IOSTheme.systemBlue.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? IOSTheme.systemBlue : IOSTheme.labelSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? IOSTheme.systemBlue : IOSTheme.labelSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for unimplemented screens
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: IOSTheme.title2,
        ),
      ),
    );
  }
}
