// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';

void main() {
  runApp(
    const GetMaterialApp(
      home: KakaoMap(),
    ),
  );
}

class KakaoMap extends StatefulWidget {
  const KakaoMap({Key? key}) : super(key: key);

  @override
  _KakaoMapState createState() => _KakaoMapState();
}

class _KakaoMapState extends State<KakaoMap> {
  void Function(JavascriptMessage)? onTapMarker;
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  late WebViewController _myController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    permission();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _webview(),
            Row(
              children: [
                _startButton(),
                _stopButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _webview() {
    return Expanded(
      child: WebView(
        initialUrl: 'https://foreverspring98.com/map_match/custom_index.html',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller.complete(webViewController);
          _myController = webViewController;
        },
        javascriptChannels: {
          JavascriptChannel(
              name: 'onTapMarker',
              onMessageReceived: (message) {
                print(message.message);
              }),
          JavascriptChannel(
              name: 'mouseTouch',
              onMessageReceived: (message) {
                print(message.message);
              }),
        },
        debuggingEnabled: true,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory(() => EagerGestureRecognizer()),
        },
      ),
    );
  }

  Widget _startButton() {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          /// 5개 씩 뽑아서 평균내는 테스트 진행 하면 될 듯?
          List<double> longitudeList = [];
          List<double> latitudeList = [];

          int count = 1;
          double preLongitude = 0;
          double preLatitude = 0;

          _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
            Position position = await getCurrentLocation();
            double longitude = position.longitude;
            double latitude = position.latitude;

            longitudeList.add(longitude);
            latitudeList.add(latitude);

            print('count : $count, 경도 : $longitude , 위도 : $latitude');

            if (count >= 5) {
              double sumLongitude = 0;
              double sumLatitude = 0;
              for (int i = 0; i < longitudeList.length; i++) {
                sumLongitude += longitudeList[i];
              }
              for (int i = 0; i < latitudeList.length; i++) {
                sumLatitude += latitudeList[i];
              }
              longitudeList.removeAt(0);
              latitudeList.removeAt(0);

              await _myController.runJavascript(
                  'appToWeb("${sumLongitude / 5}", "${sumLatitude / 5}", "$longitude", "$latitude", "$preLongitude", "$preLatitude")');
              preLongitude = sumLongitude / 5;
              preLatitude = sumLatitude / 5;
              print(
                  'count : ❤️, 경도 : ${sumLongitude / 5} , 위도 : ${sumLatitude / 5}');
              // count = 0;
            }
            count++;
          });
        },
        child: Container(
          alignment: Alignment.center,
          width: 100,
          height: 70,
          child: Text(
            'GPS 측정 시작',
            style: TextStyle(color: Colors.white),
          ),
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _stopButton() {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          _timer?.cancel();
        },
        child: Container(
          alignment: Alignment.center,
          width: 100,
          height: 70,
          child: Text(
            'GPS 측정 중지',
            style: TextStyle(color: Colors.white),
          ),
          color: Colors.black,
        ),
      ),
    );
  }

  Future<Position> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  Future<void> permission() async {
    await [Permission.camera, Permission.storage, Permission.location]
        .request();
  }
}
