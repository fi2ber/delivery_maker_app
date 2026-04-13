import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;
  List<dynamic> _counts = [];
  dynamic _activeCount;
  String _barcode = '';

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/warehouse/inventory-counts');
      setState(() {
        _counts = response as List? ?? [];
      });
    } catch (e) {
      _showError('Ошибка загрузки: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createCount() async {
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая инвентаризация'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Название',
            hintText: 'Например: Инвентаризация января',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final response = await _apiService.post('/warehouse/inventory-counts', {
          'name': nameController.text,
          'warehouseId': 'main',
        });
        await _startCount(response.data['id']);
      } catch (e) {
        _showError('Ошибка создания: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startCount(String countId) async {
    try {
      await _apiService.post('/warehouse/inventory-counts/$countId/start', {});
      final response = await _apiService.get('/warehouse/inventory-counts/$countId');
      setState(() {
        _activeCount = response;
      });
    } catch (e) {
      _showError('Ошибка запуска: $e');
    }
  }

  Future<void> _submitCount(String itemId, int actualQty) async {
    if (_activeCount == null) return;

    try {
      await _apiService.post('/warehouse/inventory-counts/${_activeCount['id']}/submit', {
        'items': [{'itemId': itemId, 'actualQuantity': actualQty}],
      });

      setState(() {
        final items = _activeCount['items'] as List? ?? [];
        final index = items.indexWhere((i) => i['id'] == itemId);
        if (index != -1) {
          items[index]['actualQuantity'] = actualQty;
          items[index]['counted'] = true;
        }
      });
    } catch (e) {
      _showError('Ошибка сохранения: $e');
    }
  }

  Future<void> _completeCount() async {
    if (_activeCount == null) return;

    final items = _activeCount['items'] as List? ?? [];
    final uncounted = items.where((i) => i['counted'] != true).length;

    if (uncounted > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Не все товары учтены'),
          content: Text('$uncounted товаров без учёта. Завершить?'),
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
      await _apiService.post('/warehouse/inventory-counts/${_activeCount['id']}/complete', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Инвентаризация завершена!')),
        );
        setState(() {
          _activeCount = null;
        });
        _loadCounts();
      }
    } catch (e) {
      _showError('Ошибка: $e');
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
        title: const Text('Инвентаризация'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeCount != null
              ? _buildActiveCountView()
              : _buildCountsListView(),
      floatingActionButton: _activeCount == null
          ? FloatingActionButton(
              onPressed: _createCount,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCountsListView() {
    final activeCounts = _counts.where((c) => c['status'] == 'in_progress').toList();
    final completedCounts = _counts.where((c) => c['status'] == 'completed').toList();

    return RefreshIndicator(
      onRefresh: _loadCounts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeCounts.isNotEmpty) ...[
            const Text(
              'Активные',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...activeCounts.map((c) => _buildCountCard(c, isActive: true)),
            const SizedBox(height: 24),
          ],
          if (completedCounts.isNotEmpty) ...[
            const Text(
              'Завершённые',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...completedCounts.take(5).map((c) => _buildCountCard(c)),
          ],
          if (_counts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Нет инвентаризаций'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountCard(dynamic count, {bool isActive = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isActive ? Colors.blue.withOpacity(0.05) : null,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isActive ? Icons.hourglass_top : Icons.check,
            color: isActive ? Colors.blue : Colors.green,
          ),
        ),
        title: Text(count['name'] ?? 'Без названия'),
        subtitle: Text('${count['items']?.length ?? 0} позиций'),
        trailing: isActive
            ? ElevatedButton(
                onPressed: () => _loadActiveCount(count['id']),
                child: const Text('Продолжить'),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _loadActiveCount(String id) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/warehouse/inventory-counts/$id');
      setState(() {
        _activeCount = response;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildActiveCountView() {
    final items = (_activeCount['items'] as List? ?? []);
    final countedCount = items.where((i) => i['counted'] == true).length;
    final totalCount = items.length;
    final progress = totalCount > 0 ? countedCount / totalCount : 0.0;

    return Column(
      children: [
        // Progress Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.purple.withOpacity(0.1),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _activeCount['name'] ?? 'Инвентаризация',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$countedCount / $totalCount',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(Colors.purple),
              ),
            ],
          ),
        ),

        // Scanner
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск товара...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () {
                  // TODO: Implement barcode scanner
                },
              ),
            ),
            onChanged: (v) => _barcode = v,
          ),
        ),

        // Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isCounted = item['counted'] == true;
              final hasDiscrepancy = isCounted && 
                  item['actualQuantity'] != null &&
                  item['actualQuantity'] != item['expectedQuantity'];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isCounted
                    ? hasDiscrepancy
                        ? Colors.orange.withOpacity(0.05)
                        : Colors.green.withOpacity(0.05)
                    : null,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCounted
                          ? hasDiscrepancy
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCounted ? Icons.check : Icons.circle_outlined,
                      color: isCounted
                          ? hasDiscrepancy ? Colors.orange : Colors.green
                          : Colors.grey,
                    ),
                  ),
                  title: Text(
                    item['productName'] ?? '',
                    style: TextStyle(
                      decoration: isCounted ? TextDecoration.lineThrough : null,
                      color: isCounted ? Colors.grey : Colors.black,
                    ),
                  ),
                  subtitle: isCounted
                      ? Text(
                          'Ожидалось: ${item['expectedQuantity']}, Факт: ${item['actualQuantity']}',
                          style: TextStyle(
                            color: hasDiscrepancy ? Colors.orange : Colors.green,
                          ),
                        )
                      : Text('Ожидается: ${item['expectedQuantity']}'),
                  trailing: isCounted
                      ? null
                      : TextButton(
                          onPressed: () => _showCountDialog(item),
                          child: const Text('Учесть'),
                        ),
                  onTap: isCounted ? null : () => _showCountDialog(item),
                ),
              );
            },
          ),
        ),

        // Complete Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completeCount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Завершить инвентаризацию'),
            ),
          ),
        ),
      ],
    );
  }

  void _showCountDialog(dynamic item) {
    final controller = TextEditingController(
      text: item['expectedQuantity']?.toString() ?? '0',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['productName'] ?? 'Товар'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ожидается: ${item['expectedQuantity']}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Фактическое количество',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final qty = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              _submitCount(item['id'], qty);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
