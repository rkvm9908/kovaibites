import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryApplication {
  final String uid;
  final String name;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final String licenseNumber;
  final String area;
  final String idProofUrl;
  final String status; // pending | approved | rejected
  final String rejectReason;
  final DateTime? createdAt;

  const DeliveryApplication({
    required this.uid,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.licenseNumber,
    required this.area,
    required this.idProofUrl,
    required this.status,
    this.rejectReason = '',
    this.createdAt,
  });

  factory DeliveryApplication.fromMap(String uid, Map<String, dynamic> m) =>
      DeliveryApplication(
        uid: uid,
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        vehicleType: m['vehicleType'] ?? '',
        vehicleNumber: m['vehicleNumber'] ?? '',
        licenseNumber: m['licenseNumber'] ?? '',
        area: m['area'] ?? '',
        idProofUrl: m['idProofUrl'] ?? '',
        status: m['status'] ?? 'pending',
        rejectReason: m['rejectReason'] ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}