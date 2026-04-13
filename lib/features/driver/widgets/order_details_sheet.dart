import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../models/delivery_stop.dart';

/// Bottom sheet showing order details and checklist
class OrderDetailsSheet extends StatefulWidget {
  final DeliveryStop stop;
  final VoidCallback onComplete;

  const OrderDetailsSheet({
    super.key,
    required this.stop,
    required this.onComplete,
  });

  @override
  State<OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<OrderDetailsSheet> {
  // Map to track which items have been verified
  final Map<String, bool> _verifiedItems = {};

  @override
  void initState() {
    super.initState();
    // In a real app, this would be populated from the Stop's order items
    // For now, we simulate a few items for demonstration.
    _verifiedItems['Коробка с электроникой #123'] = false;
    _verifiedItems['Документы (Счет-фактура)'] = false;
    _verifiedItems['Хрупкий груз (Стекло)'] = false;
  }

  bool get _allVerified => _verifiedItems.values.every((v) => v);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(IOSTheme.radius2Xl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: IOSTheme.fill,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Детали заказа',
                    style: IOSTheme.title2,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.stop.customerName,
                        style: IOSTheme.bodyMedium.copyWith(
                          color: IOSTheme.labelSecondary,
                        ),
                      ),
                      Text(
                        '#${widget.stop.id.substring(0, 8)}',
                        style: IOSTheme.footnote,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: IOSTheme.systemBlue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.stop.address,
                          style: IOSTheme.bodyMedium.copyWith(color: IOSTheme.labelPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Checklist
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Чеклист позиций',
                style: IOSTheme.headline,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shrinkWrap: true,
                itemCount: _verifiedItems.length,
                itemBuilder: (context, index) {
                  final key = _verifiedItems.keys.elementAt(index);
                  final isChecked = _verifiedItems[key]!;
                  return _ChecklistItem(
                    title: key,
                    isChecked: isChecked,
                    onChanged: (val) {
                      IOSTheme.lightImpact();
                      setState(() {
                        _verifiedItems[key] = val ?? false;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: IOSButton(
                text: 'Перейти к подтверждению',
                isPrimary: true,
                onPressed: _allVerified ? () {
                  Navigator.pop(context);
                  widget.onComplete();
                } : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String title;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const _ChecklistItem({
    required this.title,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: IOSTheme.bgTertiary,
        borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
      ),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: onChanged,
        title: Text(
          title,
          style: IOSTheme.bodyMedium.copyWith(
            decoration: isChecked ? TextDecoration.lineThrough : null,
            color: isChecked ? IOSTheme.labelSecondary : IOSTheme.labelPrimary,
          ),
        ),
        activeColor: IOSTheme.systemBlue,
        checkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
