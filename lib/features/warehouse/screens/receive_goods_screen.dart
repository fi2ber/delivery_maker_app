import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';
import '../widgets/barcode_scanner_dialog.dart';

class ReceiveGoodsScreen extends StatefulWidget {
  const ReceiveGoodsScreen({super.key});

  @override
  State<ReceiveGoodsScreen> createState() => _ReceiveGoodsScreenState();
}

class _ReceiveGoodsScreenState extends State<ReceiveGoodsScreen> {
  final _apiService = ApiService();
  final _barcodeController = TextEditingController();
  final _supplierController = TextEditingController();
  final _invoiceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<ReceivedProduct> _products = [];
  ReceivedProduct? _currentProduct;
  int _currentQuantity = 0;
  List<String> _currentPhotos = [];
  bool _isDamaged = false;
  String _notes = '';
  double? _temperature;
  bool _isLoading = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    _supplierController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final barcode = await showDialog<String>(
      context: context,
      builder: (context) => const BarcodeScannerDialog(),
    );

    if (barcode != null && barcode.isNotEmpty) {
      _barcodeController.text = barcode;
      _searchProduct(barcode);
    }
  }

  Future<void> _searchProduct(String barcode) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/products/barcode/$barcode');
      
      if (response.data['found'] == true) {
        final product = response.data['product'];
        setState(() {
          _currentProduct = ReceivedProduct(
            id: product['id'],
            barcode: barcode,
            name: product['name'],
            expectedQty: 0,
            actualQty: 0,
          );
          _currentQuantity = 0;
          _currentPhotos = [];
          _isDamaged = false;
          _notes = '';
          _temperature = null;
        });
      } else {
        _showError('Товар не найден. Создайте новый товар.');
      }
    } catch (e) {
      _showError('Ошибка поиска: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photo != null) {
        // Convert to base64 for upload
        final bytes = await photo.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${bytes.toString()}';
        
        setState(() {
          _currentPhotos.add(base64Image);
        });
      }
    } catch (e) {
      _showError('Ошибка камеры: $e');
    }
  }

  void _addProduct() {
    if (_currentProduct == null || _currentQuantity <= 0) return;
    if (_currentPhotos.isEmpty) {
      _showError('Сделайте хотя бы одно фото товара');
      return;
    }

    setState(() {
      _products.add(ReceivedProduct(
        id: _currentProduct!.id,
        barcode: _currentProduct!.barcode,
        name: _currentProduct!.name,
        expectedQty: _currentProduct!.expectedQty,
        actualQty: _currentQuantity,
        photos: List.from(_currentPhotos),
        isDamaged: _isDamaged,
        notes: _notes,
        temperature: _temperature,
      ));
      
      _currentProduct = null;
      _currentQuantity = 0;
      _currentPhotos = [];
      _isDamaged = false;
      _notes = '';
      _temperature = null;
      _barcodeController.clear();
    });
  }

  Future<void> _submitReceipt() async {
    if (_products.isEmpty) return;
    if (_supplierController.text.isEmpty) {
      _showError('Укажите поставщика');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'supplier': {
          'name': _supplierController.text,
          'invoiceNumber': _invoiceController.text,
          'deliveryDate': DateTime.now().toIso8601String().split('T')[0],
        },
        'products': _products.map((p) => ({
          'productId': p.id,
          'quantity': p.actualQty,
          'photos': p.photos,
          'notes': p.notes,
          'isDamaged': p.isDamaged,
          'temperature': p.temperature,
        })).toList(),
      };

      await _apiService.post('/warehouse/receive', payload);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Приёмка завершена успешно!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Ошибка при сохранении: $e');
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
        title: const Text('Приёмка товара'),
      ),
      body: _currentProduct == null 
          ? _buildScanView() 
          : _buildProductDetailsView(),
    );
  }

  Widget _buildScanView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Supplier Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Информация о поставке',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _supplierController,
                    decoration: const InputDecoration(
                      labelText: 'Поставщик *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _invoiceController,
                    decoration: const InputDecoration(
                      labelText: 'Накладная №',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Scanner
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Отсканируйте штрих-код',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            hintText: 'Введите штрих-код...',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: _searchProduct,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.camera_alt, color: Colors.blue),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _searchProduct(_barcodeController.text),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Найти товар'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Products List
          if (_products.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Отсканировано: ${_products.length}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_products.any((p) => p.isDamaged))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_products.where((p) => p.isDamaged).length} повреждённых',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ..._products.map((p) => _buildProductCard(p)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Завершить приёмку (${_products.length})'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(ReceivedProduct p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: p.isDamaged ? Colors.red.withOpacity(0.05) : null,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: p.isDamaged ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            p.isDamaged ? Icons.warning : Icons.check,
            color: p.isDamaged ? Colors.red : Colors.blue,
          ),
        ),
        title: Text(p.name),
        subtitle: Text('${p.actualQty} шт • ${p.photos.length} фото'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _products.remove(p);
            });
          },
        ),
      ),
    );
  }

  Widget _buildProductDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentProduct!.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Штрих-код: ${_currentProduct!.barcode}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quantity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Количество',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_currentQuantity > 0) {
                            setState(() => _currentQuantity--);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                      ),
                      Container(
                        width: 100,
                        alignment: Alignment.center,
                        child: Text(
                          '$_currentQuantity',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _currentQuantity++);
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

          // Damaged checkbox
          CheckboxListTile(
            value: _isDamaged,
            onChanged: (v) => setState(() => _isDamaged = v ?? false),
            title: const Text('Есть повреждения / брак'),
            subtitle: const Text('Отметьте, если товар повреждён'),
            tileColor: Colors.red.withOpacity(0.05),
            activeColor: Colors.red,
            secondary: const Icon(Icons.warning, color: Colors.red),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Фото товара *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_currentPhotos.length} фото',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._currentPhotos.map((photo) => _buildPhotoThumbnail(photo)),
                      _buildAddPhotoButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Фото обязательны для контроля качества',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Temperature
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Температура при доставке (°C)',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Например: 4.5',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _temperature = double.tryParse(v),
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
                  hintText: 'Дополнительная информация...',
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
                  onPressed: () => setState(() => _currentProduct = null),
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
                  onPressed: _currentQuantity > 0 ? _addProduct : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Добавить товар'),
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
              image: NetworkImage(photo),
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
                _currentPhotos.remove(photo);
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
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: const Icon(Icons.camera_alt, color: Colors.grey),
      ),
    );
  }
}

class ReceivedProduct {
  final String id;
  final String barcode;
  final String name;
  final int expectedQty;
  final int actualQty;
  final List<String> photos;
  final bool isDamaged;
  final String? notes;
  final double? temperature;

  ReceivedProduct({
    required this.id,
    required this.barcode,
    required this.name,
    required this.expectedQty,
    required this.actualQty,
    this.photos = const [],
    this.isDamaged = false,
    this.notes,
    this.temperature,
  });
}
