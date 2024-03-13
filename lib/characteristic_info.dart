import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'data_parser.dart';


// 추출데이터 위젯
class CharacteristicInfo extends StatelessWidget {
  final BluetoothService service;
  final Map<String, List<int>> notifyDatas;
  final List<int> prevResultList;

  CharacteristicInfo({
    required this.service,
    required this.notifyDatas,
    required this.prevResultList,
  });

  @override
  Widget build(BuildContext context) {
    String name = '';
    String properties = '';
    String data = '';
    List<int> datalist = [];
    List<int> resultlist = [];

    for (BluetoothCharacteristic c in service.characteristics) {
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
        if (notifyDatas.containsKey(c.uuid.toString())) {
          if (notifyDatas[c.uuid.toString()]!.isNotEmpty) {
            data = notifyDatas[c.uuid.toString()].toString();
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

    List<int> diffList = List.generate(5, (index) => resultlist[index] - prevResultList[index]);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.thermostat, size: 100, color: Colors.red),
              SizedBox(width: 10),
              Text(
                '${resultlist[0] / 100} °C',
                style: TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              Text(
                '${diffList[0] / 100 >= 0 ? "+" : ""}${diffList[0] / 100}',
                style: TextStyle(
                  fontSize: 30,
                  color: diffList[0] >= 0 ? Colors.red : Colors.blue,
                ),
              ),
              SizedBox(width: 5),
              Icon(
                diffList[0] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: diffList[0] >= 0 ? Colors.red : Colors.blue,
              ),
            ],
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.water_drop, size: 100, color: Colors.blue),
              SizedBox(width: 10),
              Text(
                '${resultlist[1] / 100} %',
                style: TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              Text(
                '${diffList[1] / 100 >= 0 ? "+" : ""}${diffList[1] / 100}',
                style: TextStyle(
                  fontSize: 30,
                  color: diffList[1] >= 0 ? Colors.red : Colors.blue,
                ),
              ),
              SizedBox(width: 5),
              Icon(
                diffList[1] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: diffList[1] >= 0 ? Colors.red : Colors.blue,
              ),
            ],
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.speed, size: 100, color: Colors.green),
              SizedBox(width: 10),
              Text(
                '${resultlist[2] / 10} mmHg',
                style: TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              Text(
                '${diffList[2] / 100 >= 0 ? "+" : ""}${diffList[2] / 100}',
                style: TextStyle(
                  fontSize: 30,
                  color: diffList[2] >= 0 ? Colors.red : Colors.blue,
                ),
              ),
              SizedBox(width: 5),
              Icon(
                diffList[2] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: diffList[2] >= 0 ? Colors.red : Colors.blue,
              ),
            ],
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.navigation, size: 100, color: Colors.orange),
              SizedBox(width: 10),
              Text(
                '${resultlist[3] / 10} 도',
                style: TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              Text(
                '${diffList[3] / 100 >= 0 ? "+" : ""}${diffList[3] / 100}',
                style: TextStyle(
                  fontSize: 30,
                  color: diffList[3] >= 0 ? Colors.red : Colors.blue,
                ),
              ),
              SizedBox(width: 5),
              Icon(
                diffList[3] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: diffList[3] >= 0 ? Colors.red : Colors.blue,
              ),
            ],
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.wind_power, size: 100, color: Colors.purple),
              SizedBox(width: 10),
              Text(
                '${resultlist[4] / 100} m/s',
                style: TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              Text(
                '${diffList[4] / 100 >= 0 ? "+" : ""}${diffList[4] / 100}',
                style: TextStyle(
                  fontSize: 30,
                  color: diffList[4] >= 0 ? Colors.red : Colors.blue,
                ),
              ),
              SizedBox(width: 5),
              Icon(
                diffList[4] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: diffList[4] >= 0 ? Colors.red : Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}