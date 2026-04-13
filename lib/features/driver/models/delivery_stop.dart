import 'package:latlong2/latlong.dart';
import '../../../data/entities/order_entity.dart';

enum StopStatus {
  pending,
  inProgress,
  completed,
  failed,
}

class DeliveryStop {
  final String id;
  final String orderId;
  final String orderCode;
  final String customerName;
  final String? phone;
  final String address;
  final String? comment;
  final LatLng location;
  final StopStatus status;
  final int sequence;

  const DeliveryStop({
    required this.id,
    required this.orderId,
    required this.orderCode,
    required this.customerName,
    this.phone,
    required this.address,
    this.comment,
    required this.location,
    required this.status,
    required this.sequence,
  });

  factory DeliveryStop.fromOrder(OrderEntity order) {
    StopStatus status;
    if (order.status == 'delivered') {
      status = StopStatus.completed;
    } else if (order.status == 'in_transit') {
      status = StopStatus.inProgress;
    } else if (order.status == 'cancelled') {
      status = StopStatus.failed;
    } else {
      status = StopStatus.pending;
    }

    return DeliveryStop(
      id: order.id.toString(),
      orderId: order.serverId ?? order.id.toString(),
      orderCode: order.orderCode,
      customerName: order.customerName,
      phone: order.customerPhone,
      address: order.address,
      comment: order.addressComment,
      location: LatLng(
        order.latitude ?? 41.2995,
        order.longitude ?? 69.2401,
      ),
      status: status,
      sequence: 0, // TODO: Add sequence to OrderEntity
    );
  }

  factory DeliveryStop.fromJson(Map<String, dynamic> json) {
    // Map status string to enum
    StopStatus mapStatus(String? status) {
      switch (status?.toUpperCase()) {
        case 'DELIVERED':
          return StopStatus.completed;
        case 'IN_TRANSIT':
          return StopStatus.inProgress;
        case 'CANCELLED':
        case 'FAILED':
          return StopStatus.failed;
        default:
          return StopStatus.pending;
      }
    }

    return DeliveryStop(
      id: json['orderId'] ?? '',
      orderId: json['orderId'] ?? '',
      orderCode: json['orderCode'] ?? '',
      customerName: json['customerName'] ?? 'Unknown',
      phone: json['phone'],
      address: json['address'] ?? '',
      comment: json['comment'],
      location: json['lat'] != null && json['lng'] != null
          ? LatLng(json['lat'].toDouble(), json['lng'].toDouble())
          : const LatLng(41.2995, 69.2401),
      status: mapStatus(json['status']),
      sequence: json['sequence'] ?? 0,
    );
  }

  bool get isPending => status == StopStatus.pending || status == StopStatus.inProgress;
  bool get isInTransit => status == StopStatus.inProgress;
  bool get isDelivered => status == StopStatus.completed;
}
