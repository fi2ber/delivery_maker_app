import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../services/driver_api_service.dart';
import '../../../core/di/service_locator.dart';

/// Driver KPI Dashboard Screen
class DriverKpiScreen extends StatelessWidget {
  const DriverKpiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Моя статистика',
                      style: IOSTheme.title1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Февраль 2024',
                      style: IOSTheme.caption,
                    ),
                  ],
                ),
              ),
            ),

            // Bonus Card
            SliverToBoxAdapter(
              child: _buildBonusCard(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // KPI Metrics
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Показатели',
                  style: IOSTheme.headline,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: _buildKpiGrid(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // AI Insights
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'AI-анализ',
                  style: IOSTheme.headline,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: _buildAIInsights(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Recommendations
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Рекомендации',
                  style: IOSTheme.headline,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: _buildRecommendations(),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Бонус за месяц',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+23% к прошлому',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '850,000 сум',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Вы в топ-3! Продолжайте в том же духе',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    final metrics = [
      _KPIMetric(
        label: 'Успешность',
        value: '94%',
        target: '95%',
        progress: 0.94,
        color: IOSTheme.systemGreen,
        icon: Icons.check_circle,
      ),
      _KPIMetric(
        label: 'Вовремя',
        value: '89%',
        target: '95%',
        progress: 0.89,
        color: IOSTheme.systemOrange,
        icon: Icons.timer,
      ),
      _KPIMetric(
        label: 'Доставок',
        value: '156',
        target: '150',
        progress: 1.04,
        color: IOSTheme.systemBlue,
        icon: Icons.local_shipping,
      ),
      _KPIMetric(
        label: 'Рейтинг',
        value: '4.8',
        target: '5.0',
        progress: 0.96,
        color: IOSTheme.systemPurple,
        icon: Icons.star,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: metrics.map((m) => _KpiCard(metric: m)).toList(),
      ),
    );
  }

  Widget _buildAIInsights() {
    final insights = [
      _AIInsight(
        type: 'strength',
        title: 'Отличная успешность доставок',
        description: 'Ваша успешность 94% - выше среднего по команде',
        icon: Icons.thumb_up,
        color: IOSTheme.systemGreen,
      ),
      _AIInsight(
        type: 'warning',
        title: 'Нужно улучшить пунктуальность',
        description: 'Только 89% доставок вовремя. Цель: 95%',
        icon: Icons.warning,
        color: IOSTheme.systemOrange,
      ),
    ];

    return Column(
      children: insights.map((i) => _InsightCard(insight: i)).toList(),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = [
      _Recommendation(
        priority: 1,
        title: 'Начинайте маршрут раньше',
        description: 'Выезд в 8:30 вместо 9:00 поможет избежать пробок',
        impact: '+6% к пунктуальности',
        difficulty: 'easy',
      ),
      _Recommendation(
        priority: 2,
        title: 'Звоните клиентам заранее',
        description: 'Предупреждайте за 10 минут до прибытия',
        impact: '-30% возвратов',
        difficulty: 'easy',
      ),
    ];

    return Column(
      children: recommendations.map((r) => _RecommendationCard(rec: r)).toList(),
    );
  }
}

// Data classes
class _KPIMetric {
  final String label;
  final String value;
  final String target;
  final double progress;
  final Color color;
  final IconData icon;

  _KPIMetric({
    required this.label,
    required this.value,
    required this.target,
    required this.progress,
    required this.color,
    required this.icon,
  });
}

class _AIInsight {
  final String type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _AIInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _Recommendation {
  final int priority;
  final String title;
  final String description;
  final String impact;
  final String difficulty;

  _Recommendation({
    required this.priority,
    required this.title,
    required this.description,
    required this.impact,
    required this.difficulty,
  });
}

// Widgets
class _KpiCard extends StatelessWidget {
  final _KPIMetric metric;

  const _KpiCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: metric.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  metric.icon,
                  color: metric.color,
                  size: 20,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.value,
            style: IOSTheme.title1.copyWith(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            style: IOSTheme.caption,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: metric.progress.clamp(0, 1),
              backgroundColor: IOSTheme.separator,
              valueColor: AlwaysStoppedAnimation(metric.color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Цель: ${metric.target}',
            style: IOSTheme.caption.copyWith(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final _AIInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: insight.color.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              insight.icon,
              color: insight.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: IOSTheme.headline.copyWith(
                    color: insight.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: IOSTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final _Recommendation rec;

  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rec.priority == 1 
                    ? IOSTheme.systemRed.withOpacity(0.1)
                    : IOSTheme.systemOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rec.priority == 1 ? 'Приоритет' : 'Рекомендация',
                  style: TextStyle(
                    color: rec.priority == 1 
                      ? IOSTheme.systemRed
                      : IOSTheme.systemOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: IOSTheme.systemGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rec.impact,
                  style: TextStyle(
                    color: IOSTheme.systemGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rec.title,
            style: IOSTheme.headline,
          ),
          const SizedBox(height: 4),
          Text(
            rec.description,
            style: IOSTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
