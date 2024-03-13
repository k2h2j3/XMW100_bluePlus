import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'characteristic_info.dart';
import 'list_item.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  String stateText = 'Connecting';
  String connectButtonText = 'Disconnect';
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;
  StreamSubscription<BluetoothDeviceState>? _stateListener;
  List<BluetoothService> bluetoothService = [];
  Map<String, List<int>> notifyDatas = {};
  List<int> prevResultList = List.filled(5, 0);

  @override
  void initState() {
    super.initState();
    _stateListener = widget.device.state.listen((event) {
      debugPrint('event :  $event');
      if (deviceState == event) {
        return;
      }
      setBleConnectionState(event);
    });
    connect();
  }

  @override
  void dispose() {
    _stateListener?.cancel();
    disconnect();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  setBleConnectionState(BluetoothDeviceState event) {
    switch (event) {
      case BluetoothDeviceState.disconnected:
        stateText = 'Disconnected';
        connectButtonText = 'Connect';
        showReconnectDialog();
        break;
      case BluetoothDeviceState.disconnecting:
        stateText = 'Disconnecting';
        break;
      case BluetoothDeviceState.connected:
        stateText = 'Connected';
        connectButtonText = 'Disconnect';
        notifyDatas.clear();
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
      stateText = 'Connecting';
    });

    await widget.device
        .connect(autoConnect: false)
        .timeout(Duration(milliseconds: 15000000), onTimeout: () {
      returnValue = Future.value(false);
      debugPrint('timeout failed');
      setBleConnectionState(BluetoothDeviceState.disconnected);
    }).then((data) async {
      bluetoothService.clear();
      if (returnValue == null) {
        debugPrint('connection successful');
        print('start discover service');
        List<BluetoothService> bleServices = await widget.device.discoverServices();
        setState(() {
          bluetoothService = bleServices;
        });
        for (BluetoothService service in bleServices) {
          print('============================================');
          print('Service UUID: ${service.uuid}');
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.properties.notify && c.descriptors.isNotEmpty) {
              for (BluetoothDescriptor d in c.descriptors) {
                print('BluetoothDescriptor uuid ${d.uuid}');
                if (d.uuid == BluetoothDescriptor.cccd) {
                  print('d.lastValue: ${d.lastValue}');
                }
              }

              if (!c.isNotifying) {
                try {
                  await c.setNotifyValue(true);
                  notifyDatas[c.uuid.toString()] = List.empty();
                  c.value.listen((value) {
                    print('${c.uuid}: $value');
                    setState(() {
                      notifyDatas[c.uuid.toString()] = value;
                    });
                  });
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

  Future<void> showReconnectDialog() async {
    bool? reconnect = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('연결 끊김'),
          content: Text('디바이스와의 연결이 끊어졌습니다. 재연결하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('아니오'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('예'),
            ),
          ],
        );
      },
    );

    if (reconnect ?? false) {
      await connect();
    }
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
        title: Text(widget.device.name),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('$stateText'),
                OutlinedButton(
                  onPressed: () {
                    if (deviceState == BluetoothDeviceState.connected) {
                      disconnect();
                    } else if (deviceState == BluetoothDeviceState.disconnected) {
                      connect();
                    }
                  },
                  child: Text(connectButtonText),
                ),
              ],
            ),
            Expanded(
              child: ListView.separated(
                itemCount: bluetoothService.length,
                itemBuilder: (context, index) {
                  return ListItem(
                    service: bluetoothService[index],
                    notifyDatas: notifyDatas,
                    prevResultList: prevResultList,
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return Divider();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}