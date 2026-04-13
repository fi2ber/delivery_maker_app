import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/auth_service.dart';
import '../../../app.dart';

class OnboardingScreen extends StatefulWidget {
  final UserRole userRole;
  final VoidCallback onCompleted;

  const OnboardingScreen({
    super.key,
    required this.userRole,
    required this.onCompleted,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRequestingPermission = false;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Добро пожаловать в DeliveryMaker',
      description: 'Ваш надежный помощник в доставке и логистике.',
      icon: Icons.local_shipping_rounded,
      color: IOSTheme.systemBlue,
    ),
    OnboardingData(
      title: 'Геолокация и Карты',
      description: 'Для работы карты и отслеживания маршрутов нам нужен доступ к вашему местоположению.',
      icon: Icons.map_rounded,
      color: IOSTheme.systemGreen,
      needsPermission: true,
    ),
    OnboardingData(
      title: 'Все готово!',
      description: 'Теперь вы можете приступить к выполнению заказов.',
      icon: Icons.check_circle_rounded,
      color: IOSTheme.systemIndigo,
    ),
  ];

  Future<void> _handleNext() async {
    if (_pages[_currentPage].needsPermission) {
      setState(() => _isRequestingPermission = true);
      
      final status = await Permission.location.request();
      
      setState(() => _isRequestingPermission = false);

      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Для работы карты необходимо разрешение на геолокацию'),
              backgroundColor: IOSTheme.systemRed,
            ),
          );
        }
        return;
      }
    }

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final authService = getIt<AuthService>();
    await authService.markFirstRunCompleted();
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 60,
                            color: page.color,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: IOSTheme.title1,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: IOSTheme.body.copyWith(
                            color: IOSTheme.labelSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? IOSTheme.systemBlue
                              : IOSTheme.labelQuaternary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: IOSButton(
                      text: _currentPage == _pages.length - 1 ? 'Начать' : 'Далее',
                      onPressed: _isRequestingPermission ? null : _handleNext,
                      isLoading: _isRequestingPermission,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool needsPermission;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.needsPermission = false,
  });
}
