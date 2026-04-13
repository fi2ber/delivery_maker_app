import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class PickingScreen extends StatefulWidget {
  const PickingScreen({super.key});

  @override
  State<PickingScreen> createState() => _PickingScreenState();
}

class _PickingScreenState extends State<PickingScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;
  dynamic _activeWave;
  dynamic _currentItem;
  String _barcode = '';

  @override
  void initState() {
    super.initState();
    _loadActiveWave();
  }

  Future<void> _loadActiveWave() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/warehouse/picking/active');
      setState(() {
        _activeWave = response.data['wave'];
      });
    } catch (e) {
      // No active wave
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createWave() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.post('/warehouse/picking/waves', {
        'priority': 'medium',
        'maxOrders': 10,
      });
      setState(() {
        _activeWave = response;
      });
    } catch (e) {
      _showError('Нет заказов для сборки');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scanItem(String barcode) async {
    if (_activeWave == null) return;

    final items = _activeWave['items'] as List? ?? [];
    final item = items.firstWhere(
      (i) => i['productId'] == barcode && !i['picked'],
      orElse: () => null,
    );

    if (item != null) {
      setState(() {
        _currentItem = item;
      });
    } else {
      _showError('Товар не найден в текущей волне');
    }
  }

  Future<void> _markPicked(String itemId) async {
    try {
      await _apiService.post('/warehouse/picking/items/$itemId/pick', {});
      
      setState(() {
        if (_activeWave != null) {
          final items = _activeWave['items'] as List? ?? [];
          final index = items.indexWhere((i) => i['id'] == itemId);
          if (index != -1) {
            items[index]['picked'] = true;
          }
        }
        _currentItem = null;
      });
    } catch (e) {
      _showError('Ошибка: $e');
    }
  }

  Future<void> _completeWave() async {
    if (_activeWave == null) return;

    final items = _activeWave['items'] as List? ?? [];
    final unpicked = items.where((i) => !i['picked']).length;

    if (unpicked > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Не все товары собраны'),
          content: Text('$unpicked товаров осталось. Завершить волну?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Завершить'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await _apiService.post('/warehouse/picking/waves/${_activeWave['id']}/complete', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Волна сборки завершена!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Ошибка при завершении: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сборка заказов'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeWave == null
              ? _buildEmptyView()
              : _buildPickingView(),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет активной волны сборки',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте новую волну для начала сборки заказов',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createWave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Создать волну сборки'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickingView() {
    final items = (_activeWave['items'] as List? ?? []);
    final pickedCount = items.where((i) => i['picked'] == true).length;
    final totalCount = items.length;
    final progress = totalCount > 0 ? pickedCount / totalCount : 0.0;
    final nextItem = items.firstWhere(
      (i) => i['picked'] != true,
      orElse: () => null,
    );

    return Column(
      children: [
        // Progress Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.withOpacity(0.1),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Волна #${_activeWave['id'].toString().substring(0, 6)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$pickedCount / $totalCount',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(Colors.blue),
              ),
            ],
          ),
        ),

        // Scanner or Next Item
        if (_currentItem != null)
          _buildCurrentItemCard()
        else if (nextItem != null)
          _buildNextItemCard(nextItem)
        else
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Все товары собраны!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          ),

        // Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isPicked = item['picked'] == true;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isPicked ? Colors.green.withOpacity(0.05) : null,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPicked ? Colors.green.withOpacity(0.1) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPicked ? Icons.check : Icons.circle_outlined,
                      color: isPicked ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Text(
                    item['productName'] ?? '',
                    style: TextStyle(
                      decoration: isPicked ? TextDecoration.lineThrough : null,
                      color: isPicked ? Colors.grey : Colors.black,
                    ),
                  ),
                  subtitle: item['location'] != null
                      ? Text('📍 ${item['location']}')
                      : null,
                  trailing: Text(
                    '${item['quantity']} ${item['unit'] ?? 'шт'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: isPicked
                      ? null
                      : () => setState(() => _currentItem = item),
                ),
              );
            },
          ),
        ),

        // Complete Button
        if (pickedCount > 0)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeWave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Завершить волну'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNextItemCard(dynamic item) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  'Следующий товар',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item['productName'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Количество',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${item['quantity']} ${item['unit'] ?? 'шт'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item['location'] != null) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Локация',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          item['location'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _currentItem = item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Начать сборку'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentItemCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.green,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _currentItem['productName'] ?? '',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currentItem['quantity']} ${_currentItem['unit'] ?? 'шт'}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentItem = null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _markPicked(_currentItem['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                    ),
                    child: const Text('Подтвердить сборку'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
