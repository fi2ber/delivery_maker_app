import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';

class WriteOffScreen extends StatefulWidget {
  const WriteOffScreen({super.key});

  @override
  State<WriteOffScreen> createState() => _WriteOffScreenState();
}

class _WriteOffScreenState extends State<WriteOffScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<WriteOffItem> _items = [];
  WriteOffItem? _currentItem;
  List<String> _searchResults = [];
  bool _isLoading = false;

  // Form fields
  WriteOffReason _reason = WriteOffReason.expired;
  int _quantity = 0;
  List<String> _photos = [];
  String _notes = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchProduct(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/warehouse/stock/search?query=$query');
      setState(() {
        _searchResults = (response as List).map((item) => item['product']['name'] as String).toList();
      });
    } catch (e) {
      _showError('Ошибка поиска: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectProduct(dynamic product) {
    setState(() {
      _currentItem = WriteOffItem(
        productId: product['product']['id'],
        productName: product['product']['name'],
        batchCode: product['batch']?['batchCode'],
      );
      _reason = WriteOffReason.expired;
      _quantity = 0;
      _photos = [];
      _notes = '';
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photo != null) {
        setState(() {
          _photos.add(photo.path);
        });
      }
    } catch (e) {
      _showError('Ошибка камеры: $e');
    }
  }

  void _addItem() {
    if (_currentItem == null) return;
    if (_quantity <= 0) {
      _showError('Укажите количество');
      return;
    }
    if (_photos.isEmpty) {
      _showError('Сделайте фото для доказательства');
      return;
    }

    setState(() {
      _items.add(WriteOffItem(
        productId: _currentItem!.productId,
        productName: _currentItem!.productName,
        batchCode: _currentItem!.batchCode,
        quantity: _quantity,
        reason: _reason,
        photos: List.from(_photos),
        notes: _notes,
      ));
      
      _currentItem = null;
      _reason = WriteOffReason.expired;
      _quantity = 0;
      _photos = [];
      _notes = '';
    });
  }

  Future<void> _submitWriteOff() async {
    if (_items.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final payload = {
        'items': _items.map((i) => ({
          'productId': i.productId,
          'batchCode': i.batchCode,
          'quantity': i.quantity,
          'reason': i.reason.name,
          'photos': i.photos,
          'notes': i.notes,
        })).toList(),
      };

      await _apiService.post('/warehouse/write-off', payload);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Списание оформлено успешно!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Ошибка при списании: $e');
    } finally {
      setState(() => _isLoading = false);
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
        title: const Text('Списание товара'),
      ),
      body: _currentItem == null 
          ? _buildSearchView() 
          : _buildItemDetailsView(),
    );
  }

  Widget _buildSearchView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.search, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Найдите товар для списания',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Введите штрих-код или название...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () {
                          // TODO: Implement barcode scanner
                        },
                      ),
                    ),
                    onSubmitted: _searchProduct,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _searchProduct(_searchController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Найти'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_items.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Добавлено: ${_items.length}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._items.map((item) => _buildItemCard(item)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitWriteOff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Оформить списание'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(WriteOffItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.red.withOpacity(0.05),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.delete_forever, color: Colors.red),
        ),
        title: Text(item.productName),
        subtitle: Text('${item.reason.label} • ${item.quantity} шт'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _items.remove(item);
            });
          },
        ),
      ),
    );
  }

  Widget _buildItemDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentItem!.productName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (_currentItem!.batchCode != null)
                    Text(
                      'Партия: ${_currentItem!.batchCode}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Reason
          const Text(
            'Причина списания *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...WriteOffReason.values.map((r) => RadioListTile<WriteOffReason>(
            value: r,
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v!),
            title: Text(r.label),
            secondary: Text(r.emoji, style: const TextStyle(fontSize: 24)),
          )),

          const SizedBox(height: 16),

          // Quantity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Количество для списания',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_quantity > 0) {
                            setState(() => _quantity--);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                      ),
                      Container(
                        width: 100,
                        alignment: Alignment.center,
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _quantity++);
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 36),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Photos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Фото доказательств *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ОБЯЗАТЕЛЬНО',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._photos.map((photo) => _buildPhotoThumbnail(photo)),
                      _buildAddPhotoButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Заметки',
                  hintText: 'Опишите состояние товара...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _notes = v,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentItem = null),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _quantity > 0 && _photos.isNotEmpty ? _addItem : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Добавить к списанию'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(String photo) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: AssetImage(photo),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _photos.remove(photo);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.camera_alt, color: Colors.grey),
      ),
    );
  }
}

enum WriteOffReason {
  expired('Просрочен', '⏰'),
  damaged('Повреждён', '💔'),
  defective('Брак', '⚠️'),
  lost('Утрачен', '❓'),
  other('Другое', '📝');

  final String label;
  final String emoji;

  const WriteOffReason(this.label, this.emoji);
}

class WriteOffItem {
  final String productId;
  final String productName;
  final String? batchCode;
  final int quantity;
  final WriteOffReason reason;
  final List<String> photos;
  final String? notes;

  WriteOffItem({
    required this.productId,
    required this.productName,
    this.batchCode,
    this.quantity = 0,
    this.reason = WriteOffReason.expired,
    this.photos = const [],
    this.notes,
  });
}
