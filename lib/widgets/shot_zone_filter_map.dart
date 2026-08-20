import 'dart:math' as math;

import 'package:flutter/material.dart';

class ShotZoneFilterMap extends StatelessWidget {
  final int? selectedZoneId;
  final ValueChanged<int?> onSelected;

  const ShotZoneFilterMap({
    super.key,
    required this.selectedZoneId,
    required this.onSelected,
  });

  static const double _aspectRatio = 1.85;

  static const Map<int, Offset> _zoneAnchors = {
    1: Offset(0.15, 0.35),
    5: Offset(0.85, 0.35),
    10: Offset(0.07, 0.50),
    6: Offset(0.93, 0.50),
    2: Offset(0.31, 0.52),
    3: Offset(0.50, 0.63),
    4: Offset(0.69, 0.52),
    9: Offset(0.22, 0.78),
    8: Offset(0.50, 0.78),
    7: Offset(0.78, 0.78),
    11: Offset(0.50, 0.43),
  };

  String _labelFor(int zoneId) {
    if (zoneId == 11) {
      return '7M';
    }
    return 'Z${zoneId.toString().padLeft(2, '0')}';
  }

  Widget _zoneButton({
    required int zoneId,
    required Offset anchor,
    required double width,
    required double height,
  }) {
    final isSelected = selectedZoneId == zoneId;
    final buttonWidth = (width * 0.12).clamp(42.0, 62.0).toDouble();
    final buttonHeight = (height * 0.15).clamp(26.0, 36.0).toDouble();
    final fontSize = (buttonHeight * 0.44).clamp(11.0, 15.0).toDouble();

    return Positioned(
      left: (width * anchor.dx) - (buttonWidth / 2),
      top: (height * anchor.dy) - (buttonHeight / 2),
      child: _ZonePill(
        label: _labelFor(zoneId),
        width: buttonWidth,
        height: buttonHeight,
        fontSize: fontSize,
        selected: isSelected,
        onTap: () => onSelected(zoneId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _GeneralFilterPill(
            selected: selectedZoneId == null,
            onTap: () => onSelected(null),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AspectRatio(
              aspectRatio: _aspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF07152D),
                          Color(0xFF0A1C3C),
                          Color(0xFF061024),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF173A66)),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ShotZoneFilterPainter(),
                          ),
                        ),
                        for (final entry in _zoneAnchors.entries)
                          _zoneButton(
                            zoneId: entry.key,
                            anchor: entry.value,
                            width: width,
                            height: height,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GeneralFilterPill extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _GeneralFilterPill({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ZonePill(
      label: 'Geral',
      width: 92,
      height: 34,
      fontSize: 13,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _ZonePill extends StatelessWidget {
  final String label;
  final double width;
  final double height;
  final double fontSize;
  final bool selected;
  final VoidCallback onTap;

  const _ZonePill({
    required this.label,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFD33D).withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? const Color(0xFFFFE76A) : Colors.white,
              width: selected ? 2.0 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD33D).withValues(alpha: 0.34),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF0B1016),
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShotZoneFilterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final goalLineY = height * 0.20;
    final areaLeft = width * 0.16;
    final areaRight = width * 0.84;
    final areaRx = (areaRight - areaLeft) / 2;
    final areaRy = height * 0.28;

    final areaFillPaint = Paint()
      ..color = const Color(0xFF1956B6).withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeWidth = width * 0.008
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dashedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = width * 0.007
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final areaRect = Rect.fromCenter(
      center: Offset(centerX, goalLineY),
      width: areaRx * 2,
      height: areaRy * 2,
    );
    final areaPath = Path()
      ..moveTo(areaLeft, goalLineY)
      ..arcTo(areaRect, math.pi, -math.pi, false)
      ..close();

    canvas.drawPath(areaPath, areaFillPaint);
    canvas.drawPath(areaPath, linePaint);
    canvas.drawLine(
      Offset(width * 0.01, goalLineY),
      Offset(width * 0.99, goalLineY),
      linePaint,
    );

    final nineRect = Rect.fromCenter(
      center: Offset(centerX, goalLineY),
      width: width * 0.96,
      height: height * 0.78,
    );
    _drawDashedArc(
      canvas: canvas,
      rect: nineRect,
      paint: dashedPaint,
    );

    canvas.drawLine(
      Offset(width * 0.17, goalLineY + (areaRy * 0.72)),
      Offset(width * 0.02, height * 0.98),
      linePaint,
    );
    canvas.drawLine(
      Offset(width * 0.83, goalLineY + (areaRy * 0.72)),
      Offset(width * 0.98, height * 0.98),
      linePaint,
    );
    canvas.drawLine(
      Offset(width * 0.39, goalLineY + (areaRy * 1.02)),
      Offset(width * 0.28, height * 0.98),
      linePaint,
    );
    canvas.drawLine(
      Offset(width * 0.61, goalLineY + (areaRy * 1.02)),
      Offset(width * 0.72, height * 0.98),
      linePaint,
    );
  }

  void _drawDashedArc({
    required Canvas canvas,
    required Rect rect,
    required Paint paint,
  }) {
    const startAngle = math.pi;
    const totalSweep = -math.pi;
    const dashAngle = 0.13;
    const gapAngle = 0.09;
    const direction = -1.0;
    const totalAbs = math.pi;
    var covered = 0.0;

    while (covered < totalAbs) {
      final remaining = totalAbs - covered;
      final sweep = (dashAngle < remaining ? dashAngle : remaining) * direction;
      canvas.drawArc(rect, startAngle + (covered * direction), sweep, false, paint);
      covered += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
