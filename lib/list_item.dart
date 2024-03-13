import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'characteristic_info.dart';

class ListItem extends StatelessWidget {
  final BluetoothService service;
  final Map<String, List<int>> notifyDatas;

  ListItem({
    required this.service,
    required this.notifyDatas,
  });

  @override
  Widget build(BuildContext context) {
    return CharacteristicInfo(
      service: service,
      notifyDatas: notifyDatas,
    );
  }
}