import 'package:flutter/material.dart';

import 'package:h264_example/decoding_dialog.dart';
import 'package:h264_example/sample.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<Sample> _assets = [
    Sample("180206_120601_001_LO.MP4.thumbnail.h264", 768, 432),
    Sample("180304_163039_357.mov.thumbnail.h264", 1920, 1080),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('H264 sample decoder'),
        ),
        body: ListView.builder(
          itemBuilder: (context, index) {
            final a = _assets[index];
            return ListTile(
              title: Text("${a.name}"),
              onTap: () => showDialog(
                    context: context,
                    builder: (context) => DecodingDialog(asset: a),
                  ),
            );
          },
          itemCount: _assets.length,
        ),
      ),
    );
  }
}
