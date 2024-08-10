import 'dart:math';

import 'package:flutter/material.dart';
import 'utils.dart';
import 'dart:ui' as ui;



class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final DrawingShape currentShape;
  final Offset? startPoint;
  final Offset? endPoint;
  final Color selectedColor;
  final double strokeWidth;
  final bool eraseMode;

  _DrawingPainter({
    required this.points,
    required this.currentShape,
    this.startPoint,
    this.endPoint,
    required this.selectedColor,
    required this.strokeWidth,
    required this.eraseMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
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