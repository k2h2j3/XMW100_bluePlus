import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final title = 'BLE Scan & Connection';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      home: MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key? key,
    required this.title
  }) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  // final String targetDeviceName = 'XMW100 1A7A7';

  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResultList = [];
  bool _isScanning = false;

  @override
  initState() {
    super.initState();
    // 초기화
    initBle();
    scan();
  }

  void initBle() {
    // BLE 스캔 상태 리스너
    flutterBlue.isScanning.listen((isScanning) {
      // 스캔상태를 감지할때마다 상태변경
      _isScanning = isScanning;
      // 리스너를 받을 때마다 상태 변경
      setState(() {});
    });
  }

  scan() async {
    if (!_isScanning) {
      // 스캔 중이 아니라면
      // 기존에 스캔된 리스트 삭제
      scanResultList.clear();

      // 스캔 시작
      flutterBlue.startScan(
         // timeout: Duration(seconds: 10)
      );
      // 스캔 결과가 바뀔때마다 스트림을 등록하고 결과가 수신될때마다 해당함수 호출
      flutterBlue.scanResults.listen((results) {
        // 스캔 결과 목록을 순회
        results.forEach((element) {
          //찾는 장치명인지 확인
          if (element.device.name.startsWith('XMW')) { // 이 부분을 수정합니다
            // 장치의 ID를 비교해 이미 등록된 장치인지 확인
            if (scanResultList
                .indexWhere((e) => e.device.id == element.device.id) <
                0) {
              // 찾는 장치명이고 scanResultList에 등록된적이 없는 장치라면 리스트에 추가 후 스캔정지
              scanResultList.add(element);
              flutterBlue.stopScan();
            }
          }
        });
        // UI 갱신
        setState(() {});
      });
    } else {
      // 스캔 중이라면 스캔 정지
      flutterBlue.stopScan();
      _isScanning = false;
    }
  }

  /*  장치의 신호세기 표시 위젯  */
  Widget deviceSignal(ScanResult r) {
    return Text(r.rssi.toString());
  }

  /* 장치의 MAC(id) 주소 위젯  */
  Widget deviceMacAddress(ScanResult r) {
    return Text(r.device.id.id);
  }

  /* 장치 이름 위젯  */
  Widget deviceName(ScanResult r) {
    String name = '';

    if (r.device.name.isNotEmpty) {
      // device.name에 값이 있다면
      name = r.device.name;
    } else if (r.advertisementData.localName.isNotEmpty) {
      // advertisementData.localName에 값이 있다면
      name = r.advertisementData.localName;
    } else {
      // 둘다 없다면 이름 알 수 없음...
      name = 'N/A';
    }
    return Text(name);
  }

  /* BLE 아이콘 위젯 */
  Widget leading(ScanResult r) {
    return CircleAvatar(
      child: Icon(
        Icons.bluetooth,
        color: Colors.white,
      ),
      backgroundColor: Colors.cyan,
    );
  }

  /* 장치 아이템을 탭 했을때 호출 되는 함수 */
  void onTap(ScanResult r) {
    // 단순히 이름만 출력
    print('${r.device.name}');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceScreen(device: r.device)),
    );
  }

  /* 장치 아이템 위젯 */
  Widget listItem(ScanResult r) {
    return ListTile(
      onTap: () => onTap(r),
      leading: leading(r), // icon
      title: deviceName(r), //이름
      subtitle: deviceMacAddress(r), //id
      trailing: deviceSignal(r), //신호세기
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        /* 장치 리스트 출력 */
        child: ListView.separated(
          itemCount: scanResultList.length,
          itemBuilder: (context, index) {
            return listItem(scanResultList[index]);
          },
          separatorBuilder: (BuildContext context, int index) {
            return Divider();
          },
        ),
      ),
      /* 장치 검색 or 검색 중지  */
    );
  }
}