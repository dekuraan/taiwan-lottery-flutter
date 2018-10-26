import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String qrcode = "";

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
          appBar: new AppBar(
            title: new Text('Taiwan Lottery Checker'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: scan,
            backgroundColor: Colors.blue,
            child: Icon(Icons.add_photo_alternate),
          ),
          body: new Center(
            child: new Column(
              children: <Widget>[
                new Container(
                  // child: new MaterialButton(
                  //     onPressed: scan, child: new Text("Scan")),
                  padding: const EdgeInsets.all(8.0),
                ),
                new Text(qrcode),
              ],
            ),
          )),
    );
  }

  Future<String> getWinningNumbers({int month, int year}) async {
    String queryString = '''
    {
      getWinningNumbers(month: $month, year: $year) {
        special
        grand
        first
        additional
      }
    }
    ''';
    http.Response response = await http.post(
        'https://taiwan-recipt-lottery.now.sh/graphql',
        body: {"query": queryString});
    String body = response.body;
    setState(() => this.qrcode = response.body);
    print(body);
    return body;
  }

  Future scan() async {
    try {
      String qrcode = await BarcodeScanner.scan();
      String lottery;
      RegExp qrcodeRegExp =
          RegExp(r'^[A-Z]{2}[0-9]{19}.*.*==:[\*]{10}:[0-9]:[0-9]:[0-9]:');
      RegExp barcodeRegExp = RegExp(r'^[0-9]{5}[A-Z]{2}[0-9]{12}');
      if (qrcode.startsWith('**'))
        lottery = 'Please scan the left QR Code, not the right one.';
      else if (qrcodeRegExp.hasMatch(qrcode)) {
        int year = int.parse(qrcode.substring(10, 13)) + 1911;
        int month = int.parse(qrcode.substring(13, 15));
        lottery =
            'Lottery #: ${qrcode.substring(2, 10)} Year: $year Month: $month';
        lottery += '\n' + await getWinningNumbers(month: month, year: year);
      } else if (barcodeRegExp.hasMatch(qrcode)) {
        int year = int.parse(qrcode.substring(0, 3)) + 1911;
        int month = int.parse(qrcode.substring(3, 5));
        lottery =
            'Lottery #: ${qrcode.substring(7, 15)} Year: $year Month: $month';
        lottery += '\n' + await getWinningNumbers(month: month, year: year);
      } else
        lottery =
            'I don\'t think you scanned a recipt, the QR code or barcode is wrong.';
      setState(() => this.qrcode = lottery);
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this.qrcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this.qrcode = 'Unknown error: $e');
      }
    } on FormatException {
      setState(() => this.qrcode =
          'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this.qrcode = 'Unknown error: $e');
    }
  }
}
