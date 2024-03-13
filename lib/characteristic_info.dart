import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'data_parser.dart';

class CharacteristicInfo extends StatefulWidget {
  final BluetoothService service;
  final Map<String, List<int>> notifyDatas;

  CharacteristicInfo({
    required this.service,
    required this.notifyDatas,
  });

  @override
  _CharacteristicInfoState createState() => _CharacteristicInfoState();
}

class _CharacteristicInfoState extends State<CharacteristicInfo> {
  List<int> prevResultList = List.filled(5, 0);

  @override
  Widget build(BuildContext context) {
    String name = '';
    String properties = '';
    String data = '';
    List<int> datalist = [];
    List<int> resultlist = [];

    for (BluetoothCharacteristic c in widget.service.characteristics) {
      properties = '';
      data = '';
      name += '\t\t${c.uuid}\n';
      datalist = [];

      if (c.properties.write) {
        properties += 'Write ';
      }
      if (c.properties.read) {
        properties += 'Read ';
      }
      if (c.properties.notify) {
        properties += 'Notify ';
        if (widget.notifyDatas.containsKey(c.uuid.toString())) {
          if (widget.notifyDatas[c.uuid.toString()]!.isNotEmpty) {
            data = widget.notifyDatas[c.uuid.toString()].toString();
            datalist = parseData(data);
            resultlist.add((datalist[2].toUnsigned(16) << 8) + datalist[3].toUnsigned(16));
            resultlist.add((datalist[4].toUnsigned(16) << 8) + datalist[5].toUnsigned(16));
            resultlist.add((datalist[6].toUnsigned(16) << 8) + datalist[7].toUnsigned(16));
            resultlist.add((datalist[8].toUnsigned(16) << 8) + datalist[9].toUnsigned(16));
            resultlist.add((datalist[10].toUnsigned(16) << 8) + datalist[11].toUnsigned(16));
          }
        }
      }
      if (c.properties.writeWithoutResponse) {
        properties += 'WriteWR ';
      }
      if (c.properties.indicate) {
        properties += 'Indicate ';
      }
      name += '\t\t\tProperties: $properties\n';
      if (data.isNotEmpty) {
        name += '\t\t\t\t$data\n';
      }
    }

    if (resultlist.isEmpty) {
      return Container();
    }

    List<Widget> dataWidgets = [];
    for (int i = 0; i < resultlist.length; i++) {
      IconData icon;
      Color color;
      String unit;
      double divider;

      switch (i) {
        case 0:
          icon = Icons.thermostat;
          color = Colors.red;
          unit = '°C';
          divider = 100;
          break;
        case 1:
          icon = Icons.water_drop;
          color = Colors.blue;
          unit = '%';
          divider = 100;
          break;
        case 2:
          icon = Icons.speed;
          color = Colors.green;
          unit = 'mmHg';
          divider = 10;
          break;
        case 3:
          icon = Icons.navigation;
          color = Colors.orange;
          unit = '도';
          divider = 10;
          break;
        case 4:
          icon = Icons.wind_power;
          color = Colors.purple;
          unit = 'm/s';
          divider = 100;
          break;
        default:
          icon = Icons.error;
          color = Colors.grey;
          unit = '';
          divider = 1;
      }

      double currentValue = resultlist[i] / divider;
      double prevValue = prevResultList[i] / divider;
      double diff = currentValue - prevValue;
      String arrow = (diff > 0)
          ? '▲'
          : (diff < 0)
          ? '▼'
          : '━';
      Color diffColor = (diff > 0)
          ? Colors.red
          : (diff < 0)
          ? Colors.blue
          : Colors.grey;

      dataWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, size: 100, color: color),
              SizedBox(width: 10),
              Text(
                '$currentValue $unit',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              Row(
                children: [
                  Text(
                    arrow,
                    style: TextStyle(
                      fontSize: 50,
                      color: diffColor,
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    '${diff.abs().toStringAsFixed(2)} $unit',
                    style: TextStyle(
                      fontSize: 30,
                      color: diffColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    prevResultList = resultlist;

    return Padding(
      padding: const EdgeInsets.only(left: 30.0),
      child: Column(
        children: [
          Text(
            'Data',
            style: TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 70),
          ...dataWidgets,
        ],
      ),
    );
  }
}