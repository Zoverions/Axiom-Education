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

  @override
  void initState() {
    super.initState();
    _initModels();
  }

  Future<void> _initModels() async {
    await _scorer.initModel();
    await _watcher.initModel();
  }

  void _evaluateDrawing() async {
    // Scaffolded implementation converting strokes to mock format for the Scorer
    List<Map<String, dynamic>> mockStrokeData = _strokes.map((s) => {
      'points': s.length,
      // More advanced logic would capture stylus pressure events
    }).toList();

    final (pressure, consistency) = await _scorer.scoreHandwriting(mockStrokeData);

    // Convert canvas to image for the Watcher (pseudo-logic for architecture representation)
    // final imageBytes = await _captureCanvasAsImage();
    // final parsedContent = await _watcher.parseCanvas(imageBytes);

    if (widget.onScore != null) {
      widget.onScore!(pressure, consistency);
    }
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.white,
          ),
          child: GestureDetector(
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
              _evaluateDrawing();
            },
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              painter: _HandwritingPainter(_strokes),
              child: Container(), // Transparent container to receive gestures
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _clearCanvas,
              icon: const Icon(Icons.clear),
              label: const Text('Clear')
            ),
          ],
        )
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
