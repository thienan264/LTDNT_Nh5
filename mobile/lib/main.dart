import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'data/repositories/member_repository.dart';
import 'data/datasources/cart_service.dart';
import 'data/models/user_model.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/devices/device_list_screen.dart';
import 'presentation/screens/home/dashboard_screen.dart';
import 'presentation/screens/rentals/rental_list_screen.dart';
import 'presentation/screens/scanner/qr_scanner_demo_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CartService.loadCartFromLocalDb();
  runApp(const EquipmentRentalApp());
}

class EquipmentRentalApp extends StatelessWidget {
  const EquipmentRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Cho thuê Thiết bị',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      home: ValueListenableBuilder<UserModel?>(
        valueListenable: MemberRepository.currentUserNotifier,
        builder: (context, user, _) {
          if (user == null) {
            return LoginScreen(onLoginSuccess: () {});
          }
          return const MainNavigationScreen();
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    DeviceListScreen(),
    QrScannerDemoScreen(),
    RentalListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
            label: 'Thiết bị',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner, color: AppColors.primary),
            label: 'Quét QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'Hợp đồng',
          ),
        ],
      ),
    );
  }
}
