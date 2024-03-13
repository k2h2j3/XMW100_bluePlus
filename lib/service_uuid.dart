import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// 디바이스 식별자
class ServiceUUID extends StatelessWidget {
  final BluetoothService service;

  ServiceUUID({required this.service});

  @override
  Widget build(BuildContext context) {
    String name = service.uuid.toString();
    return Text(name);
  }
}