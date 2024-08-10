import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'utils.dart';

class Toolbar extends StatelessWidget {
  final Color selectedColor;
  final double strokeWidth;
  final bool eraseMode;
  final DrawingShape currentShape;
  final Function(Color) onColorChanged;
  final Function(double) onStrokeWidthChanged;
  final Function(bool) onEraseModeChanged;
  final Function(DrawingShape) onShapeChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  Toolbar({
    required this.selectedColor,
    required this.strokeWidth,
    required this.eraseMode,
    required this.currentShape,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onEraseModeChanged,
    required this.onShapeChanged,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: !eraseMode && currentShape == DrawingShape.none ? Colors.blue : Colors.black),
              onPressed: () {
                onEraseModeChanged(false);
                onShapeChanged(DrawingShape.none);
              },
            ),
            IconButton(
              icon: Icon(Icons.color_lens),
              onPressed: () => _showColorPicker(context),
            ),
            IconButton(
              icon: Icon(Icons.brush),
              onPressed: () => _showStrokeWidthPicker(context),
            ),
            IconButton(
              icon: Icon(Icons.rectangle_outlined),
              onPressed: () => onShapeChanged(DrawingShape.rectangle),
            ),
            IconButton(
              icon: Icon(Icons.circle_outlined),
              onPressed: () => onShapeChanged(DrawingShape.circle),
            ),
            IconButton(
              icon: Icon(Icons.change_history),
              onPressed: () => onShapeChanged(DrawingShape.triangle),
            ),
            IconButton(
              icon: Icon(Icons.square_outlined),
              onPressed: () => onShapeChanged(DrawingShape.square),
            ),
            IconButton(
              icon: Icon(Icons.undo),
              onPressed: onUndo,
            ),
            IconButton(
              icon: Icon(Icons.redo),
              onPressed: onRedo,
            ),
            IconButton(
              icon: Icon(Icons.auto_fix_high, color: eraseMode ? Colors.blue : Colors.black),
              onPressed: () {
                onEraseModeChanged(true);
                onShapeChanged(DrawingShape.none);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: onColorChanged,
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

  void _showStrokeWidthPicker(BuildContext context) {
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
          onChanged: onStrokeWidthChanged,
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
}