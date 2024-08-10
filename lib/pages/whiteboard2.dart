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
  Color backgroundColor = Colors.white;
  double strokeWidth = 3.0;
  List<DrawingPoint> points = [];
  bool eraseMode = false;
  DrawingShape currentShape = DrawingShape.none;
  Offset? startPoint;
  Offset? endPoint;
  List<List<DrawingPoint>> undoHistory = [];
  List<List<DrawingPoint>> redoHistory = [];
  DrawingTool currentTool = DrawingTool.pencil;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Whiteboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveDrawing,
            tooltip: 'Save Drawing',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _clearDrawing,
            tooltip: 'Clear Drawing',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                  child: CustomPaint(
                    painter: _DrawingPainter(
                      points: points,
                      currentShape: currentShape,
                      startPoint: startPoint,
                      endPoint: endPoint,
                      selectedColor: selectedColor,
                      strokeWidth: strokeWidth,
                      backgroundColor: backgroundColor,
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                );
              },
            ),
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(top: BorderSide(color: Colors.grey[400]!, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildToolbarItem(Icons.edit, 'Pencil', DrawingTool.pencil),
            _buildToolbarItem(Icons.brush, 'Brush', DrawingTool.brush),
            _buildToolbarItem(Icons.color_lens, 'Color', DrawingTool.colorPicker),
            _buildToolbarItem(Icons.format_paint, 'Fill', DrawingTool.fill),
            _buildToolbarItem(Icons.rectangle_outlined, 'Rectangle', DrawingTool.rectangle),
            _buildToolbarItem(Icons.circle_outlined, 'Circle', DrawingTool.circle),
            _buildToolbarItem(Icons.change_history, 'Triangle', DrawingTool.triangle),
            _buildToolbarItem(Icons.square_outlined, 'Square', DrawingTool.square),
            _buildToolbarItem(Icons.text_fields, 'Text', DrawingTool.text),
            _buildToolbarItem(Icons.undo, 'Undo', DrawingTool.undo),
            _buildToolbarItem(Icons.redo, 'Redo', DrawingTool.redo),
            _buildToolbarItem(Icons.auto_fix_high, 'Eraser', DrawingTool.eraser),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarItem(IconData icon, String tooltip, DrawingTool tool) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        child: IconButton(
          icon: Icon(icon, color: currentTool == tool ? Colors.blue : Colors.black),
          onPressed: () => _handleToolChange(tool),
        ),
      ),
    );
  }

  void _handleToolChange(DrawingTool tool) {
    setState(() {
      currentTool = tool;
      eraseMode = tool == DrawingTool.eraser;
      currentShape = DrawingShape.none;

      switch (tool) {
        case DrawingTool.rectangle:
          currentShape = DrawingShape.rectangle;
          break;
        case DrawingTool.circle:
          currentShape = DrawingShape.circle;
          break;
        case DrawingTool.triangle:
          currentShape = DrawingShape.triangle;
          break;
        case DrawingTool.square:
          currentShape = DrawingShape.square;
          break;
        case DrawingTool.colorPicker:
          _showColorPicker();
          break;
        case DrawingTool.fill:
          _fillBackground();
          break;
        case DrawingTool.text:
          _addText();
          break;
        case DrawingTool.undo:
          _undo();
          break;
        case DrawingTool.redo:
          _redo();
          break;
        default:
          break;
      }
    });
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      startPoint = details.localPosition;
      if (currentShape == DrawingShape.none) {
        points.add(DrawingPoint(
          offset: details.localPosition,
          paint: Paint()
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true
            ..color = eraseMode ? backgroundColor : selectedColor
            ..strokeWidth = strokeWidth
            ..blendMode = eraseMode ? BlendMode.src : BlendMode.srcOver,
        ));
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      endPoint = details.localPosition;
      if (currentShape == DrawingShape.none) {
        points.add(DrawingPoint(
          offset: details.localPosition,
          paint: Paint()
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true
            ..color = eraseMode ? backgroundColor : selectedColor
            ..strokeWidth = strokeWidth
            ..blendMode = eraseMode ? BlendMode.src : BlendMode.srcOver,
        ));
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
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

  void _fillBackground() {
    setState(() {
      backgroundColor = selectedColor;
    });
  }

  void _addText() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Text'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(hintText: 'Enter text'),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              setState(() {
                points.add(DrawingPoint(
                  offset: Offset(100, 100), // Default position, you may want to make this adjustable
                  paint: Paint()
                    ..color = selectedColor
                    ..strokeWidth = strokeWidth,
                  text: textController.text,
                ));
                undoHistory.add(List.from(points));
                redoHistory.clear();
              });
              Navigator.of(context).pop();
            },
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
      backgroundColor = Colors.white;
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
        backgroundColor: backgroundColor,
      ).paint(canvas, size);
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes!.buffer.asUint8List());
      await GallerySaver.saveImage(file.path);
      
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
  final Color backgroundColor;

  _DrawingPainter({
    required this.points,
    required this.currentShape,
    this.startPoint,
    this.endPoint,
    required this.selectedColor,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = backgroundColor);

    for (int i = 0; i < points.length; i++) {
      if (points[i].endOffset == null) {
        if (points[i].text != null) {
          _drawText(canvas, points[i]);
        } else {
          canvas.drawPoints(ui.PointMode.points, [points[i].offset], points[i].paint);
        }
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
void _drawText(Canvas canvas, DrawingPoint point) {
    final textSpan = TextSpan(
      text: point.text,
      style: TextStyle(color: point.paint.color, fontSize: point.paint.strokeWidth * 5),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, point.offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  final Offset? endOffset;
  final DrawingShape shape;
  final String? text;

  DrawingPoint({
    required this.offset,
    required this.paint,
    this.endOffset,
    this.shape = DrawingShape.none,
    this.text,
  });
}

enum DrawingShape { none, rectangle, circle, triangle, square }

enum DrawingTool {
  pencil,
  brush,
  eraser,
  colorPicker,
  fill,
  rectangle,
  circle,
  triangle,
  square,
  text,
  undo,
  redo,
}