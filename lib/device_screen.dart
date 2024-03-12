import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScreen extends StatefulWidget {
  // 블루투스 장치
  final BluetoothDevice device;

  DeviceScreen({
    Key? key,
    required this.device
  }) : super(key: key);

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  // flutterBluePlus
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  String stateText = 'Connecting';

  String connectButtonText = 'Disconnect';

  // 현재 연결 상태 저장용
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  // 연결 상태 리스너 핸들 화면 종료시 리스너 해제를 위함
  StreamSubscription<BluetoothDeviceState>? _stateListener;

  // 블루투스 서비스의 data를 검색하고 특성을 읽거나 쓰기위해 사용
  List<BluetoothService> bluetoothService = [];

  Map<String, List<int>> notifyDatas = {};


  @override
  initState() {
    super.initState();
    // 상태 연결 리스너 등록
    _stateListener = widget.device.state.listen((event) {
      // disconnect 출력
      debugPrint('event :  $event');
      if (deviceState == event) {
        // 상태가 동일하다면 무시
        return;
      }
      // 연결 상태 정보 변경
      setBleConnectionState(event);
    });
    // 연결 시작
    connect();
  }

  @override
  void dispose() {
    // 상태 리스너 해제
    _stateListener?.cancel();
    // 연결 해제
    disconnect();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      // 위젯이 화면에 추가 되었을때만 업데이트 되게 함
      super.setState(fn);
    }
  }

  /* 연결 상태 갱신 */
  setBleConnectionState(BluetoothDeviceState event) {
    switch (event) {
      case BluetoothDeviceState.disconnected:
        stateText = 'Disconnected';
        connectButtonText = 'Connect';
        break;
      case BluetoothDeviceState.disconnecting:
        stateText = 'Disconnecting';
        break;
      case BluetoothDeviceState.connected:
        stateText = 'Connected';
        connectButtonText = 'Disconnect';
        notifyDatas.clear(); // notifyDatas 초기화
        break;
      case BluetoothDeviceState.connecting:
        stateText = 'Connecting';
        break;
    }
    deviceState = event;
    setState(() {});
  }

  Future<void> writePassword() async {
    String password = "101010";
    List<int> passwordBytes = List<int>.filled(20, 0);

    for (int i = 0; i < password.length; i++) {
      passwordBytes[i + 1] = password.codeUnitAt(i);
    }

    passwordBytes[0] = 0x01;

    bool characteristicFound = false;

    for (BluetoothService service in bluetoothService) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == "0000fff3-0000-1000-8000-00805f9b34fb") {
          print('식별자확인');
          try {
            await characteristic.write(passwordBytes);
            print('Password written successfully');
            characteristicFound = true;
            break;
          } catch (e) {
            print('Failed to write password: $e');
            return;
          }
        }
      }
      if (characteristicFound) break;
    }

    if (!characteristicFound) {
      print('Failed to find characteristic to write password');
    }
  }

  Future<bool> connect() async {
    Future<bool>? returnValue;
    setState(() {
      /* 상태 표시를 Connecting으로 변경 */
      stateText = 'Connecting';
    });

    await widget.device
        .connect(autoConnect: false)
        .timeout(Duration(milliseconds: 15000000), onTimeout: () {
      //타임아웃 발생
      //returnValue를 false로 설정
      returnValue = Future.value(false);
      debugPrint('timeout failed');

      //연결 상태 disconnected로 변경
      setBleConnectionState(BluetoothDeviceState.disconnected);
    }).then((data) async {
      bluetoothService.clear();
      if (returnValue == null) {
        //returnValue가 null이면 timeout이 발생한 것이 아니므로 연결 성공
        debugPrint('connection successful');
        print('start discover service');
        // 블루투스 device에서 서비스를 검색하는 작업 수행
        List<BluetoothService> bleServices = await widget.device.discoverServices();
        setState(() {
          bluetoothService = bleServices;
        });
        // 각 속성을 디버그에 출력
        for (BluetoothService service in bleServices) {
          print('============================================');
          print('Service UUID: ${service.uuid}');
          for (BluetoothCharacteristic c in service.characteristics) {
            // notify나 indicate가 true면 디바이스에서 데이터를 보낼 수 있는 캐릭터리스틱이니 활성화 한다.
            // 단, descriptors가 비었다면 notify를 할 수 없으므로 패스!
            if (c.properties.notify && c.descriptors.isNotEmpty) {
              // 진짜 0x2902 가 있는지 단순 체크용!
              for (BluetoothDescriptor d in c.descriptors) {
                print('BluetoothDescriptor uuid ${d.uuid}');
                if (d.uuid == BluetoothDescriptor.cccd) {
                  print('d.lastValue: ${d.lastValue}');
                }
              }

              // notify가 설정 안되었다면...
              if (!c.isNotifying) {
                try {
                  await c.setNotifyValue(true);
                  // 받을 데이터 변수 Map 형식으로 키 생성
                  notifyDatas[c.uuid.toString()] = List.empty();
                  c.value.listen((value) {
                    // 데이터 읽기 처리!
                    print('${c.uuid}: $value');
                    setState(() {
                      // 받은 데이터 저장 화면 표시용
                      notifyDatas[c.uuid.toString()] = value;
                    });
                  });

                  // 설정 후 일정시간 지연
                  // await Future.delayed(const Duration(milliseconds: 500));
                } catch (e) {
                  print('error ${c.uuid} $e');
                }
              }
            }
          }
        }
        returnValue = Future.value(true);
        await writePassword();
      }
    });

    return returnValue ?? Future.value(false);
  }

  void disconnect() {
    try {
      setState(() {
        stateText = 'Disconnecting';
      });
      widget.device.disconnect();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /* 장치명 */
        title: Text(widget.device.name),
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  /* 연결 상태 */
                  Text('$stateText'),
                  /* 연결 및 해제 버튼 */
                  OutlinedButton(
                      onPressed: () {
                        if (deviceState == BluetoothDeviceState.connected) {
                          /* 연결된 상태라면 연결 해제 */
                          disconnect();
                        } else if (deviceState ==
                            BluetoothDeviceState.disconnected) {
                          /* 연결 해재된 상태라면 연결 */
                          connect();
                        }
                      },
                      child: Text(connectButtonText)),
                ],
              ),

              /* 연결된 BLE의 서비스 정보 출력 */
              Expanded(
                child: ListView.separated(
                  itemCount: bluetoothService.length,
                  itemBuilder: (context, index) {
                    return listItem(bluetoothService[index]);
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Divider();
                  },
                ),
              ),
            ],
          )),
    );
  }

  /* 각 캐릭터리스틱 정보 표시 위젯 */
  Widget characteristicInfo(BluetoothService r) {
    String name = '';
    String properties = '';
    String data = '';
    List<int> datalist = [];
    List<int> resultlist = [];

    // 캐릭터리스틱을 한개씩 꺼내서 표시
    for (BluetoothCharacteristic c in r.characteristics) {
      properties = '';
      data = '';
      name += '\t\t${c.uuid}\n';
      datalist = []; // 데이터 리스트 초기화

      if (c.properties.write) {
        properties += 'Write ';
      }
      if (c.properties.read) {
        properties += 'Read ';
      }
      if (c.properties.notify) {
        properties += 'Notify ';
        if (notifyDatas.containsKey(c.uuid.toString())) {
          // notify 데이터가 존재한다면
          if (notifyDatas[c.uuid.toString()]!.isNotEmpty) {
            data = notifyDatas[c.uuid.toString()].toString();
            datalist = parseData(data);
            // 데이터가 있는 경우에만 resultlist에 추가
            resultlist.add((datalist[2].toUnsigned(16) << 8) + datalist[3].toUnsigned(16)); // temp
            resultlist.add((datalist[4].toUnsigned(16) << 8) + datalist[5].toUnsigned(16)); // unhumi
            resultlist.add((datalist[6].toUnsigned(16) << 8) + datalist[7].toUnsigned(16)); // unairp
            resultlist.add((datalist[8].toUnsigned(16) << 8) + datalist[9].toUnsigned(16)); // unwd
            resultlist.add((datalist[10].toUnsigned(16) << 8) + datalist[11].toUnsigned(16)); // unws
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
        // 받은 데이터 화면에 출력!
        name += '\t\t\t\t$data\n';
      }
    }

    // resultList가 비어 있으면 에러를 방지하기 위해 빈 컨테이너를 반환
    if (resultlist.isEmpty) {
      return Container();
    }

    return Column(
      children: [
        Text(
          'temp : ${resultlist[0]/100} °C',
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        Text('unHumi : ${resultlist[1]/100} %',
        style: TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          color: Colors.lightBlueAccent,
        ),),
        Text('unAirPressure : ${resultlist[2]/10} mmHg',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.greenAccent,
        ),),
        Text('unWD : ${resultlist[3]/10} 도',
        style: TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          color: Colors.yellow,
        ),),
        Text('unWS : ${resultlist[4]} m/s',
        style: TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          color: Colors.deepOrange,
        ),),
      ],
    );
  }

  List<int> parseData(String jsonData) {
    // 문자열에서 대괄호 제거 및 공백 제거
    String cleanData = jsonData.replaceAll(RegExp(r'[\[\] ]'), '');

    // 콤마로 문자열을 분할하여 정수 리스트로 변환
    List<int> dataList = cleanData.split(',').map(int.parse).toList();

    return dataList;
  }

  /* Service UUID 위젯  */
  Widget serviceUUID(BluetoothService r) {
    String name = '';
    name = r.uuid.toString();
    return Text(name);
  }

  /* Service 정보 아이템 위젯 */
  Widget listItem(BluetoothService r) {
    return ListTile(
      onTap: null,
      title: characteristicInfo(r),
    );
  }
}




