import 'package:flutter/material.dart';
import '../app.dart';
import '../core/theme/ios_theme.dart';
import '../core/di/service_locator.dart';
import '../services/auth_service.dart';

/// Login screen with Telegram and Phone options
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = getIt<AuthService>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loginWithPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Введите номер телефона');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _authService.login(phone: phone);
      
      if (result.success && result.role != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DeliveryApp(userRole: result.role!),
            ),
          );
        }
      } else {
        setState(() => _error = result.error ?? 'Ошибка входа');
      }
    } catch (e) {
      setState(() => _error = 'Ошибка сети: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginAsDriver() async {
    // Demo login for testing
    await _authService.setUserRole(UserRole.driver);
    if (mounted) {
      Navigator.of(context).pushReplacement(
         MaterialPageRoute(
          builder: (_) => DeliveryApp(userRole: UserRole.driver),
        ),
      );
    }
  }

  Future<void> _loginAsSales() async {
    // Demo login for testing
    await _authService.setUserRole(UserRole.sales);
    if (mounted) {
      Navigator.of(context).pushReplacement(
         MaterialPageRoute(
          builder: (_) => DeliveryApp(userRole: UserRole.sales),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: IOSTheme.systemBlue,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: IOSTheme.shadowMd,
                ),
                child: const Icon(
                  Icons.local_shipping,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'DeliveryMaker',
                style: IOSTheme.title1.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Вход в систему',
                style: IOSTheme.body.copyWith(
                  color: IOSTheme.labelSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Phone input
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: IOSTheme.radiusLg,
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: IOSTheme.body,
                  decoration: InputDecoration(
                    hintText: '+998 90 123 45 67',
                    hintStyle: TextStyle(color: IOSTheme.labelTertiary),
                    border: InputBorder.none,
                    icon: Icon(Icons.phone, color: IOSTheme.labelSecondary),
                  ),
                ),
              ),
              
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: IOSTheme.systemRed,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Login button
              IOSButton(
                onPressed: _isLoading ? null : _loginWithPhone,
                isLoading: _isLoading,
                child: const Text('Войти'),
              ),
              
              const SizedBox(height: 32),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: IOSTheme.separator)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'или',
                      style: TextStyle(color: IOSTheme.labelSecondary),
                    ),
                  ),
                  Expanded(child: Divider(color: IOSTheme.separator)),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Demo buttons
              Text(
                'Демо вход:',
                style: TextStyle(
                  color: IOSTheme.labelSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: IOSButton.secondary(
                      onPressed: _loginAsDriver,
                      child: const Text('Курьер'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: IOSButton.secondary(
                      onPressed: _loginAsSales,
                      child: const Text('Продавец'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS-style button
class IOSButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isSecondary;

  const IOSButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  }) : isSecondary = false;

  const IOSButton.secondary({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  }) : isSecondary = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSecondary 
            ? IOSTheme.bgSecondary 
            : IOSTheme.systemBlue,
          borderRadius: BorderRadius.circular(12),
          border: isSecondary
            ? Border.all(color: IOSTheme.separator)
            : null,
        ),
        child: Center(
          child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isSecondary ? IOSTheme.systemBlue : Colors.white,
                  ),
                ),
              )
            : DefaultTextStyle(
                style: TextStyle(
                  color: isSecondary ? IOSTheme.systemBlue : Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
        ),
      ),
    );
  }
}
