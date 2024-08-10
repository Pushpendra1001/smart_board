import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:io';

enum DrawingShape { none, rectangle, circle, triangle, square }

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

Future<void> saveDrawing(BuildContext context, List<DrawingPoint> points) async {
  try {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = MediaQuery.of(context).size;
    
    // Create a white background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    
    // Draw all points and shapes
    for (int i = 0; i < points.length; i++) {
      if (points[i].endOffset == null) {
        if (i > 0) {
          canvas.drawLine(points[i - 1].offset, points[i].offset, points[i].paint);
        } else {
          canvas.drawPoints(ui.PointMode.points, [points[i].offset], points[i].paint);
        }
      } else {
        _drawShape(canvas, points[i]);
      }
    }
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes!.buffer.asUint8List());
    await GallerySaver.saveImage(file.path);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Drawing saved to gallery')));
  } catch (e) {
    print('Error saving drawing: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save drawing')));
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