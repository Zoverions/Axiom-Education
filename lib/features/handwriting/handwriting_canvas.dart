import 'package:flutter/material.dart';

class HandwritingCanvas extends StatefulWidget {
  final Function(double, double)? onScore;

  const HandwritingCanvas({super.key, this.onScore});

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
      ),
      child: Center(
        child: Text('Handwriting Canvas Placeholder\n(Stylus input goes here)'),
      ),
    );
  }
}
