import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

class WhiteboardPage extends StatefulWidget {
  @override
  _WhiteboardPageState createState() => _WhiteboardPageState();
}

class _WhiteboardPageState extends State<WhiteboardPage> {
  Color selectedColor = Colors.black;
  double strokeWidth = 3.0;
  List<DrawingPoint> points = [];
  bool eraseMode = false;
  DrawingShape currentShape = DrawingShape.none;
  Offset? startPoint;
  Offset? endPoint;
  List<List<DrawingPoint>> undoHistory = [];
  List<List<DrawingPoint>> redoHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Whiteboard'),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: _saveDrawing),
          IconButton(icon: Icon(Icons.delete), onPressed: _clearDrawing),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanStart: (details) {
              setState(() {
                startPoint = details.localPosition;
                if (currentShape == DrawingShape.none) {
                  points.add(DrawingPoint(
                    offset: details.localPosition,
                    paint: Paint()
                      ..strokeCap = StrokeCap.round
                      ..isAntiAlias = true
                      ..color = eraseMode ? Colors.white : selectedColor
                      ..strokeWidth = strokeWidth
                      ..blendMode = eraseMode ? BlendMode.clear : BlendMode.srcOver,
                  ));
                }
              });
            },
            onPanUpdate: (details) {
              setState(() {
                endPoint = details.localPosition;
                if (currentShape == DrawingShape.none) {
                  points.add(DrawingPoint(
                    offset: details.localPosition,
                    paint: Paint()
                      ..strokeCap = StrokeCap.round
                      ..isAntiAlias = true
                      ..color = eraseMode ? Colors.white : selectedColor
                      ..strokeWidth = strokeWidth
                      ..blendMode = eraseMode ? BlendMode.clear : BlendMode.srcOver,
                  ));
                }
              });
            },
            onPanEnd: (details) {
              setState(() {
                if (currentShape != DrawingShape.none) {
                  points.add(DrawingPoint(
                    offset: startPoint!,
                    paint: Paint()
                      ..strokeCap = StrokeCap.round
                      ..isAntiAlias = true
                      ..color = selectedColor
                      ..strokeWidth = strokeWidth
                      ..style = PaintingStyle.stroke,
                    endOffset: endPoint,
                    shape: currentShape,
                  ));
                }
                startPoint = null;
                endPoint = null;
                undoHistory.add(List.from(points));
                redoHistory.clear();
              });
            },
            child: CustomPaint(
              painter: _DrawingPainter(
                points: points,
                currentShape: currentShape,
                startPoint: startPoint,
                endPoint: endPoint,
                selectedColor: selectedColor,
                strokeWidth: strokeWidth,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildToolbar(),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: !eraseMode && currentShape == DrawingShape.none ? Colors.blue : Colors.black),
              onPressed: () => setState(() {
                eraseMode = false;
                currentShape = DrawingShape.none;
              }),
            ),
            IconButton(
              icon: Icon(Icons.color_lens),
              onPressed: _showColorPicker,
            ),
            IconButton(
              icon: Icon(Icons.brush),
              onPressed: _showStrokeWidthPicker,
            ),
            IconButton(
              icon: Icon(Icons.rectangle_outlined),
              onPressed: () => setState(() {
                eraseMode = false;
                currentShape = DrawingShape.rectangle;
              }),
            ),
            IconButton(
              icon: Icon(Icons.circle_outlined),
              onPressed: () => setState(() {
                eraseMode = false;
                currentShape = DrawingShape.circle;
              }),
            ),
            IconButton(
              icon: Icon(Icons.change_history),
              onPressed: () => setState(() {
                eraseMode = false;
                currentShape = DrawingShape.triangle;
              }),
            ),
            IconButton(
              icon: Icon(Icons.square_outlined),
              onPressed: () => setState(() {
                eraseMode = false;
                currentShape = DrawingShape.square;
              }),
            ),
            IconButton(
              icon: Icon(Icons.undo),
              onPressed: _undo,
            ),
            IconButton(
              icon: Icon(Icons.redo),
              onPressed: _redo,
            ),
            IconButton(
              icon: Icon(Icons.auto_fix_high, color: eraseMode ? Colors.blue : Colors.black),
              onPressed: () => setState(() {
                eraseMode = true;
                currentShape = DrawingShape.none;
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) => setState(() => selectedColor = color),
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            child: Text('Done'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showStrokeWidthPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select stroke width'),
        content: Slider(
          value: strokeWidth,
          min: 1,
          max: 20,
          divisions: 19,
          label: strokeWidth.round().toString(),
          onChanged: (value) => setState(() => strokeWidth = value),
        ),
        actions: [
          TextButton(
            child: Text('Done'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _clearDrawing() {
    setState(() {
      points.clear();
      undoHistory.clear();
      redoHistory.clear();
    });
  }

  void _undo() {
    if (undoHistory.isNotEmpty) {
      setState(() {
        redoHistory.add(List.from(points));
        points = List.from(undoHistory.last);
        undoHistory.removeLast();
      });
    }
  }

  void _redo() {
    if (redoHistory.isNotEmpty) {
      setState(() {
        undoHistory.add(List.from(points));
        points = List.from(redoHistory.last);
        redoHistory.removeLast();
      });
    }
  }

  Future<void> _saveDrawing() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = MediaQuery.of(context).size;
      _DrawingPainter(
        points: points,
        currentShape: DrawingShape.none,
        selectedColor: selectedColor,
        strokeWidth: strokeWidth,
      ).paint(canvas, size);
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes!.buffer.asUint8List());
      await GallerySaver.saveImage(file.path);
        
    // Save to app's documents directory instead of temporary directory
    final directory1 = await getApplicationDocumentsDirectory();
    final file1 = File('${directory1.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
    await file1.writeAsBytes(pngBytes!.buffer.asUint8List());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Drawing saved to gallery')));
    } catch (e) {
      print('Error saving drawing: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save drawing')));
    }
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final DrawingShape currentShape;
  final Offset? startPoint;
  final Offset? endPoint;
  final Color selectedColor;
  final double strokeWidth;

  _DrawingPainter({
    required this.points,
    required this.currentShape,
    this.startPoint,
    this.endPoint,
    required this.selectedColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length; i++) {
      if (points[i].endOffset == null) {
        canvas.drawPoints(ui.PointMode.points, [points[i].offset], points[i].paint);
      } else {
        _drawShape(canvas, points[i]);
      }
    }

    if (currentShape != DrawingShape.none && startPoint != null && endPoint != null) {
      final paint = Paint()
        ..color = selectedColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      _drawCurrentShape(canvas, paint);
    }
  }

  void _drawShape(Canvas canvas, DrawingPoint point) {
    switch (point.shape) {
      case DrawingShape.rectangle:
        canvas.drawRect(Rect.fromPoints(point.offset, point.endOffset!), point.paint);
        break;
      case DrawingShape.circle:
        canvas.drawOval(Rect.fromPoints(point.offset, point.endOffset!), point.paint);
        break;
      case DrawingShape.triangle:
        final path = Path()
          ..moveTo(point.offset.dx, point.endOffset!.dy)
          ..lineTo(point.endOffset!.dx, point.endOffset!.dy)
          ..lineTo((point.offset.dx + point.endOffset!.dx) / 2, point.offset.dy)
          ..close();
        canvas.drawPath(path, point.paint);
        break;
      case DrawingShape.square:
        final side = min((point.endOffset!.dx - point.offset.dx).abs(), (point.endOffset!.dy - point.offset.dy).abs());
        canvas.drawRect(Rect.fromCenter(center: point.offset, width: side, height: side), point.paint);
        break;
      default:
        break;
    }
  }

  void _drawCurrentShape(Canvas canvas, Paint paint) {
    switch (currentShape) {
      case DrawingShape.rectangle:
        canvas.drawRect(Rect.fromPoints(startPoint!, endPoint!), paint);
        break;
      case DrawingShape.circle:
        canvas.drawOval(Rect.fromPoints(startPoint!, endPoint!), paint);
        break;
      case DrawingShape.triangle:
        final path = Path()
          ..moveTo(startPoint!.dx, endPoint!.dy)
          ..lineTo(endPoint!.dx, endPoint!.dy)
          ..lineTo((startPoint!.dx + endPoint!.dx) / 2, startPoint!.dy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case DrawingShape.square:
        final side = min((endPoint!.dx - startPoint!.dx).abs(), (endPoint!.dy - startPoint!.dy).abs());
        canvas.drawRect(Rect.fromCenter(center: startPoint!, width: side, height: side), paint);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  final Offset? endOffset;
  final DrawingShape shape;

  DrawingPoint({
    required this.offset,
    required this.paint,
    this.endOffset,
    this.shape = DrawingShape.none,
  });
}

enum DrawingShape { none, rectangle, circle, triangle, square }