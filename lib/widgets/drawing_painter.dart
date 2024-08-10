
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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