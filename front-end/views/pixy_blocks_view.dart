import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PixyBlocksView extends StatefulWidget {
  const PixyBlocksView({super.key});

  @override
  State<PixyBlocksView> createState() => _PixyBlocksViewState();
}

class _PixyBlocksViewState extends State<PixyBlocksView> {
  List<Block> blocks = [];
  String rawJson = 'Loading...';

  bool showBorders = false;
  bool toggleRoute0 = false;
  bool toggleRoute1 = false;

  Set<int> disabledSignatures = {};
  Set<String> disabledCameras = {};

  @override
  void initState() {
    super.initState();
    fetchData();

    // Refresh data every 100ms
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 100));
      await fetchData();
      return true;
    });
  }

  void toggleBorders() {
    setState(() {
      showBorders = !showBorders;
    });
  }

  void setToggleRoute0() {
    setState(() {
      toggleRoute0 = !toggleRoute0;
    });
  }

  void setToggleRoute1() {
    setState(() {
      toggleRoute1 = !toggleRoute1;
    });
  }

  void toggleSignature(int signatureId) {
    setState(() {
      if (disabledSignatures.contains(signatureId)) {
        disabledSignatures.remove(signatureId);
      } else {
        disabledSignatures.add(signatureId);
      }
    });
  }

  void toggleCamera(String cameraName) {
    setState(() {
      if (disabledCameras.contains(cameraName)) {
        disabledCameras.remove(cameraName);
      } else {
        disabledCameras.add(cameraName);
      }
    });
  }

  Future<void> fetchData() async {
    final Map<String, bool> useEmptyJsonForRoute = {
      'https://nahid-sekander.duckdns.org/pixy/get_json_0': toggleRoute0,
      'https://nahid-sekander.duckdns.org/pixy/get_json_1': toggleRoute1,
    };

    final urls =
        useEmptyJsonForRoute.entries.map((entry) {
          return entry.value ? 'data:application/json,[]' : entry.key;
        }).toList();

    List<Block> allBlocks = [];
    List<dynamic> allJsonData = [];

    for (final url in urls) {
      debugPrint("Current url : $url");
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          allJsonData.add(jsonData);
          for (var i = 0; i < jsonData.length; i++) {
            final cameraName = jsonData[i]['camera'] as String? ?? '';
            if (disabledCameras.contains(cameraName)) continue;

            if (jsonData[i] != null && jsonData[i]['blocks'] != null) {
              allBlocks.addAll(
                (jsonData[i]['blocks'] as List)
                    .map((b) => Block.fromJson(b))
                    .where(
                      (block) => !disabledSignatures.contains(block.signature),
                    )
                    .toList(),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching data from $url: $e');
      }
    }

    setState(() {
      blocks = allBlocks;
      rawJson = const JsonEncoder.withIndent('  ').convert(allJsonData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pixy Blocks Viewer')),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Pixy Viewer Controls",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              title: const Text("Close Drawer"),
              leading: const Icon(Icons.close),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              title: Text(
                showBorders ? "Hide Block Borders" : "Show Block Borders",
              ),
              onTap: toggleBorders,
            ),
            ListTile(
              title: Text(toggleRoute0 ? "Enable Route 0" : "Disable Route 0"),
              onTap: setToggleRoute0,
            ),
            ListTile(
              title: Text(toggleRoute1 ? "Enable Route 1" : "Disable Route 1"),
              onTap: setToggleRoute1,
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Toggle Signatures",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (int sig = 1; sig <= 4; sig++)
              ListTile(
                title: Text(
                  disabledSignatures.contains(sig)
                      ? "Enable Signature $sig"
                      : "Disable Signature $sig",
                ),
                onTap: () => toggleSignature(sig),
              ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Toggle Cameras",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: Text(
                disabledCameras.contains('PI-CAMERA 1: ')
                    ? "Enable Camera 1"
                    : "Disable Camera 1",
              ),
              onTap: () => toggleCamera('PI-CAMERA 1: '),
            ),
            ListTile(
              title: Text(
                disabledCameras.contains('PI-CAMERA 2: ')
                    ? "Enable Camera 2"
                    : "Disable Camera 2",
              ),
              onTap: () => toggleCamera('PI-CAMERA 2: '),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 480),
              painter: BlockPainter(blocks, showBorders),
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: SelectableText(rawJson),
            ),
          ),
        ],
      ),
    );
  }
}

class Block {
  final int x, y, width, height, signature;

  Block({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.signature,
  });

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      x: json['x'],
      y: json['y'],
      width: json['width'],
      height: json['height'],
      signature: json['signature'],
    );
  }
}

class BlockPainter extends CustomPainter {
  final List<Block> blocks;
  final bool showBorders;

  BlockPainter(this.blocks, this.showBorders);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final block in blocks) {
      switch (block.signature) {
        case 1:
          paint.color = Colors.red;
          break;
        case 2:
          paint.color = Colors.orange;
          break;
        case 3:
          paint.color = Colors.blue;
          break;
        case 4:
          paint.color = Colors.green;
          break;
        default:
          paint.color = Colors.grey;
      }

      final rect = Rect.fromLTWH(
        block.x.toDouble(),
        block.y.toDouble(),
        block.width.toDouble(),
        block.height.toDouble(),
      );

      // 👇 Debug print to show what is being rendered
      debugPrint(
        "Rendering Block → "
        "Signature: ${block.signature}, "
        "x: ${block.x}, y: ${block.y}, "
        "w: ${block.width}, h: ${block.height}, "
        "Color: ${paint.color}",
      );

      canvas.drawRect(rect, paint);

      if (showBorders) {
        final borderPaint =
            Paint()
              ..color = Colors.black
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1;
        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
