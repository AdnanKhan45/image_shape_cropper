import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ResultPage extends StatefulWidget {
  final Uint8List bytes;
  const ResultPage({super.key, required this.bytes});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  GlobalKey _repaintKey = GlobalKey();
  Uint8List _byteImage = Uint8List(0);

  Future<Uint8List?> convertWidgetToImage(GlobalKey key) async {
    RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary != null && boundary.isRepaintBoundary) {
      ui.Image boxImage = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await boxImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        Uint8List imageData = byteData.buffer.asUint8List();
        print('Image data length: ${imageData.length}');
        setState(() {
          _byteImage = imageData;
        });
        return imageData;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result Page'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: Transform.rotate(
              angle: pi / 2,
              child: Center(
                child: Container(
                  child: Image.memory(widget.bytes),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              convertWidgetToImage(_repaintKey);
            },
            child: const Text('Convert to Image'),
          ),
          SizedBox(height: 10),
          _byteImage.isNotEmpty ? Container(color: Colors.grey, child: Image.memory(_byteImage)) : CircularProgressIndicator(),
        ],
      ),
    );
  }
}
