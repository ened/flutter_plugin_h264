import 'dart:io';

import 'package:flutter/material.dart';
import 'package:h264/h264.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:h264_example/sample.dart';
import 'package:path_provider/path_provider.dart';

class DecodingDialog extends StatefulWidget {
  final Sample asset;

  const DecodingDialog({
    Key? key,
    required this.asset,
  }) : super(key: key);

  @override
  _DecodingDialogState createState() => _DecodingDialogState();
}

class _DecodingDialogState extends State<DecodingDialog> {
  Future<String> _loadAndDecode() async {
    final loaded = await rootBundle.load("assets/samples/${widget.asset.name}");

    final tmp = await getTemporaryDirectory();
    final tmpAsset = File("${tmp.path}/cached-${widget.asset.name}");
    tmpAsset.writeAsBytesSync(loaded.buffer.asUint8List());

    final tmpOut = File("${tmp.path}/decoded-${widget.asset.name}.jpg");

    return H264
        .decodeFrame(
          tmpAsset.path,
          tmpOut.path,
          widget.asset.width,
          widget.asset.height,
        )
        .then((ignored) => tmpOut.path);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.asset.name),
      content: AspectRatio(
        aspectRatio: widget.asset.width / widget.asset.height,
        child: FutureBuilder<String>(
          future: _loadAndDecode(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "Decoding failed:",
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "${snapshot.error}",
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            return Image.file(File(snapshot.data!));
          },
        ),
      ),
    );
  }
}
