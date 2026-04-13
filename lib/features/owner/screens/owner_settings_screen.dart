import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../core/di/service_locator.dart';

/// Owner settings screen — company profile, integrations, notifications, security
class OwnerSettingsScreen extends StatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen> {
  final _api = getIt<ApiService>();
  final _auth = getIt<AuthService>();

  bool _isLoading = true;
  Map<String, dynamic> _companyData = {};
  Map<String, dynamic> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/tenants/current');
      if (mounted) {
        setState(() {
          _companyData = response.data as Map<String, dynamic>? ?? {};
          _settings = _companyData['settings'] as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _companyData = _getMockCompanyData();
          _settings = _companyData['settings'] as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getMockCompanyData() {
    return {
      'name': 'DeliveryMaker Demo',
      'phone': '+998901234567',
      'address': 'г. Ташкент, ул. Навои 100',
      'logo': null,
      'subscription': {
        'plan': 'Business',
        'status': 'active',
        'expiresAt': '2026-12-31',
      },
      'settings': {
        'notificationsEnabled': true,
        'telegramBotEnabled': true,
        'autoAssignDrivers': false,
        'requirePhotoOnDelivery': true,
        'workingHoursStart': '08:00',
        'workingHoursEnd': '20:00',
        'currency': 'UZS',
        'language': 'ru',
        'verificationMethod': 'telegram',
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildCompanyCard(),
                  const SizedBox(height: 20),
                  _buildSubscriptionCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Настройки доставки'),
                  const SizedBox(height: 10),
                  _buildToggleSetting(
                    icon: Icons.auto_awesome,
                    title: 'Авто-назначение водителей',
                    subtitle: 'Автоматически назначать ближайшего водителя',
                    value: _settings['autoAssignDrivers'] ?? false,
                    onChanged: (v) =>
                        setState(() => _settings['autoAssignDrivers'] = v),
                  ),
                  const SizedBox(height: 8),
                  _buildToggleSetting(
                    icon: Icons.camera_alt,
                    title: 'Фото при доставке',
                    subtitle: 'Требовать фото подтверждение доставки',
                    value: _settings['requirePhotoOnDelivery'] ?? true,
                    onChanged: (v) =>
                        setState(() => _settings['requirePhotoOnDelivery'] = v),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Рабочие часы'),
                  const SizedBox(height: 10),
                  _buildWorkingHours(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Уведомления'),
                  const SizedBox(height: 10),
                  _buildToggleSetting(
                    icon: Icons.notifications,
                    title: 'Push-уведомления',
                    subtitle: 'Получать уведомления о заказах',
                    value: _settings['notificationsEnabled'] ?? true,
                    onChanged: (v) =>
                        setState(() => _settings['notificationsEnabled'] = v),
                  ),
                  const SizedBox(height: 8),
                  _buildToggleSetting(
                    icon: Icons.telegram,
                    title: 'Telegram бот',
                    subtitle: 'Уведомления через Telegram',
                    value: _settings['telegramBotEnabled'] ?? false,
                    onChanged: (v) =>
                        setState(() => _settings['telegramBotEnabled'] = v),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Интеграции'),
                  const SizedBox(height: 10),
                  _buildIntegrationItem(
                    icon: Icons.telegram,
                    title: 'Telegram Bot',
                    subtitle: 'Подключён',
                    isConnected: true,
                  ),
                  const SizedBox(height: 8),
                  _buildIntegrationItem(
                    icon: Icons.payment,
                    title: 'Payme',
                    subtitle: 'Не подключён',
                    isConnected: false,
                  ),
                  const SizedBox(height: 8),
                  _buildIntegrationItem(
                    icon: Icons.payment,
                    title: 'Click',
                    subtitle: 'Не подключён',
                    isConnected: false,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Верификация'),
                  const SizedBox(height: 10),
                  _buildVerificationSelector(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('Настройки', style: IOSTheme.title2),
      ],
    );
  }

  Widget _buildCompanyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [IOSTheme.systemBlue, IOSTheme.systemIndigo],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                (_companyData['name'] ?? 'D').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _companyData['name'] ?? 'Компания',
                  style: IOSTheme.headline,
                ),
                const SizedBox(height: 2),
                Text(
                  _companyData['phone'] ?? '',
                  style: IOSTheme.subheadline
                      .copyWith(color: IOSTheme.labelSecondary),
                ),
                Text(
                  _companyData['address'] ?? '',
                  style: IOSTheme.caption1
                      .copyWith(color: IOSTheme.labelTertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.edit, color: IOSTheme.systemBlue, size: 20),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final sub =
        _companyData['subscription'] as Map<String, dynamic>? ?? {};
    final plan = sub['plan'] ?? 'Free';
    final status = sub['status'] ?? 'inactive';
    final isActive = status == 'active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [
                  IOSTheme.systemBlue.withOpacity(0.15),
                  IOSTheme.systemIndigo.withOpacity(0.08),
                ]
              : [
                  IOSTheme.systemRed.withOpacity(0.1),
                  IOSTheme.systemRed.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? IOSTheme.systemBlue.withOpacity(0.3)
              : IOSTheme.systemRed.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium,
            color: isActive ? IOSTheme.systemBlue : IOSTheme.systemRed,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Тариф: $plan', style: IOSTheme.headline),
                Text(
                  isActive ? 'Активен' : 'Неактивен',
                  style: IOSTheme.caption1.copyWith(
                    color: isActive
                        ? IOSTheme.systemGreen
                        : IOSTheme.systemRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (sub['expiresAt'] != null)
            Text(
              'до ${sub['expiresAt']}',
              style: IOSTheme.caption1
                  .copyWith(color: IOSTheme.labelSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: IOSTheme.headline.copyWith(fontSize: 16),
    );
  }

  Widget _buildToggleSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: IOSTheme.systemBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: IOSTheme.systemBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: IOSTheme.subheadline),
                Text(
                  subtitle,
                  style: IOSTheme.caption1
                      .copyWith(color: IOSTheme.labelSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (v) {
              IOSTheme.lightImpact();
              onChanged(v);
            },
            activeColor: IOSTheme.systemGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHours() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: IOSTheme.systemOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.access_time, color: IOSTheme.systemOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            '${_settings['workingHoursStart'] ?? '08:00'} — ${_settings['workingHoursEnd'] ?? '20:00'}',
            style: IOSTheme.headline,
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: IOSTheme.labelTertiary, size: 20),
        ],
      ),
    );
  }

  Widget _buildIntegrationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isConnected,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isConnected ? IOSTheme.systemGreen : IOSTheme.labelTertiary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color:
                  isConnected ? IOSTheme.systemGreen : IOSTheme.labelTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: IOSTheme.subheadline),
                Text(
                  subtitle,
                  style: IOSTheme.caption1.copyWith(
                    color: isConnected
                        ? IOSTheme.systemGreen
                        : IOSTheme.labelSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected
                  ? IOSTheme.systemGreen.withOpacity(0.1)
                  : IOSTheme.systemBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isConnected ? 'Подключён' : 'Подключить',
              style: IOSTheme.caption1.copyWith(
                color: isConnected ? IOSTheme.systemGreen : IOSTheme.systemBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSelector() {
    final methods = ['telegram', 'sms', 'whatsapp', 'disabled'];
    final labels = {
      'telegram': 'Telegram',
      'sms': 'SMS',
      'whatsapp': 'WhatsApp',
      'disabled': 'Отключена',
    };
    final current = _settings['verificationMethod'] ?? 'telegram';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Метод верификации клиентов', style: IOSTheme.subheadline),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: methods.map((m) {
              final isActive = current == m;
              return GestureDetector(
                onTap: () {
                  IOSTheme.lightImpact();
                  setState(
                      () => _settings['verificationMethod'] = m);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? IOSTheme.systemBlue
                        : IOSTheme.bgPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[m] ?? m,
                    style: IOSTheme.caption1.copyWith(
                      color: isActive
                          ? Colors.white
                          : IOSTheme.labelPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: () async {
        IOSTheme.mediumImpact();
        try {
          await _api.put('/tenants/current/settings', _settings);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Настройки сохранены'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: IOSTheme.systemBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'Сохранить настройки',
            style: IOSTheme.headline.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
