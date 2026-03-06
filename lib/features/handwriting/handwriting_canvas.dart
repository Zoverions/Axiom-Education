import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/services/model_bindings.dart';

class HandwritingCanvas extends StatefulWidget {
  final Function(double, double)? onScore;

  const HandwritingCanvas({super.key, this.onScore});

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  final HandwritingScorer _scorer = HandwritingScorer();
  final WatcherModel _watcher = WatcherModel();

  String _parsedContent = "";
  double _pressureScore = 0.0;
  double _consistencyScore = 0.0;
  bool _isEvaluating = false;

  @override
  void initState() {
    super.initState();
    _initModels();
  }

  Future<void> _initModels() async {
    await _scorer.initModel();
    await _watcher.initModel();
  }

  Future<void> _evaluateDrawing() async {
    if (_strokes.isEmpty) return;

    setState(() {
      _isEvaluating = true;
    });

    try {
      // 1. Convert strokes to data structure for the Scorer
      List<Map<String, dynamic>> mockStrokeData = [];
      for (var stroke in _strokes) {
        for (var point in stroke) {
          mockStrokeData.add({
            'x': point.dx,
            'y': point.dy,
            'pressure': 0.5, // Replace with actual pressure if Stylus API allows
          });
        }
      }

      final (pressure, consistency) = await _scorer.scoreHandwriting(mockStrokeData);

      // 2. Render canvas to image for the Watcher
      final imageBytes = await _captureCanvasAsImage();
      String parsedContent = "No drawing detected.";
      if (imageBytes != null) {
          parsedContent = await _watcher.parseCanvas(imageBytes);
      }

      if (mounted) {
        setState(() {
          _pressureScore = pressure;
          _consistencyScore = consistency;
          _parsedContent = parsedContent;
          _isEvaluating = false;
        });

        if (widget.onScore != null) {
          widget.onScore!(pressure, consistency);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
           _parsedContent = "Evaluation failed: $e";
           _isEvaluating = false;
        });
      }
    }
  }

  Future<ui.Image?> _captureImage() async {
    if (_strokes.isEmpty) return null;

    // Set a fixed dimension or use context size
    const double width = 800;
    const double height = 400;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(Offset.zero, Offset(width, height)));

    // Draw white background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var stroke in _strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }

    final picture = recorder.endRecording();
    return await picture.toImage(width.toInt(), height.toInt());
  }

  Future<Uint8List?> _captureCanvasAsImage() async {
    final image = await _captureImage();
    if (image == null) return null;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _parsedContent = "";
      _pressureScore = 0.0;
      _consistencyScore = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.white,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              setState(() {
                _currentStroke = [details.localPosition];
                _strokes.add(_currentStroke);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentStroke.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
              // Optionally trigger evaluation on every stroke end,
              // or rely on a manual submit button.
              // _evaluateDrawing();
            },
            child: CustomPaint(
              painter: _HandwritingPainter(_strokes),
              child: Container(), // Transparent container to receive gestures
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _isEvaluating ? null : _evaluateDrawing,
              icon: _isEvaluating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.analytics),
              label: Text(_isEvaluating ? 'Evaluating...' : 'Evaluate Drawing')
            ),
            TextButton.icon(
              onPressed: _clearCanvas,
              icon: const Icon(Icons.clear),
              label: const Text('Clear')
            ),
          ],
        ),
        if (_parsedContent.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Watcher Output: $_parsedContent', style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Pressure Score: ${(_pressureScore * 100).toStringAsFixed(1)}%'),
                Text('Consistency Score: ${(_consistencyScore * 100).toStringAsFixed(1)}%'),
              ],
            ),
          )
        ]
      ],
    );
  }

  @override
  void dispose() {
    _scorer.dispose();
    _watcher.dispose();
    super.dispose();
  }
}

class _HandwritingPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _HandwritingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
         canvas.drawPoints(ui.PointMode.points, [stroke.first], paint);
         continue;
      }
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) {
    return true; // Simple repaint optimization
  }
}
