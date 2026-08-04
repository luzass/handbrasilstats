import 'dart:math' as math;

import 'package:flutter/material.dart';

class ScoutLanceMapSelector extends StatelessWidget {
  static const double _boardAspectRatio = 0.78;

  final int? selectedZoneId;
  final int? selectedGoalZoneId;
  final ValueChanged<int> onZoneSelected;
  final ValueChanged<int> onGoalZoneSelected;
  final bool goalZonesEnabled;
  final bool enabled;

  const ScoutLanceMapSelector({
    super.key,
    required this.selectedZoneId,
    required this.selectedGoalZoneId,
    required this.onZoneSelected,
    required this.onGoalZoneSelected,
    required this.goalZonesEnabled,
    this.enabled = true,
  });

  static const Map<int, Offset> _shotZoneAnchors = {
    1: Offset(0.13, 0.48),
    5: Offset(0.87, 0.48),
    10: Offset(0.17, 0.60),
    6: Offset(0.83, 0.60),
    2: Offset(0.33, 0.71),
    3: Offset(0.50, 0.74),
    4: Offset(0.67, 0.71),
    9: Offset(0.20, 0.90),
    8: Offset(0.50, 0.91),
    7: Offset(0.80, 0.90),
  };

  static const Offset _sevenMeterAnchor = Offset(0.50, 0.55);

  static const List<List<int>> _goalRows = [
    [1, 4, 7],
    [2, 5, 8],
    [3, 6, 9],
  ];

  Widget _shotMarker(
    int zoneId,
    Offset anchor,
    double width,
    double height,
  ) {
    final isSelected = selectedZoneId == zoneId;
    final markerWidth = (width * 0.19).clamp(54.0, 90.0).toDouble();
    final markerHeight = (height * 0.085).clamp(40.0, 64.0).toDouble();

    return Positioned(
      left: (width * anchor.dx) - (markerWidth / 2),
      top: (height * anchor.dy) - (markerHeight / 2),
      child: _HitRegion(
        width: markerWidth,
        height: markerHeight,
        isSelected: isSelected,
        onTap: enabled ? () => onZoneSelected(zoneId) : null,
      ),
    );
  }

  Widget _sevenMeterMarker(double width, double height) {
    final isSelected = selectedZoneId == 11;
    final markerWidth = (width * 0.12).clamp(40.0, 56.0).toDouble();
    final markerHeight = (height * 0.05).clamp(26.0, 34.0).toDouble();
    final fontSize = (markerHeight * 0.35).clamp(10.0, 12.0).toDouble();

    return Positioned(
      left: (width * _sevenMeterAnchor.dx) - (markerWidth / 2),
      top: (height * _sevenMeterAnchor.dy) - (markerHeight / 2),
      child: _SevenMeterButton(
        width: markerWidth,
        height: markerHeight,
        isSelected: isSelected,
        onTap: enabled ? () => onZoneSelected(11) : null,
        fontSize: fontSize,
      ),
    );
  }

  Widget _goalGrid(double width, double height) {
    final left = width * 0.14;
    final top = height * 0.05;
    final goalWidth = width * 0.72;
    final goalHeight = height * 0.27;

    return Positioned(
      left: left,
      top: top,
      width: goalWidth,
      height: goalHeight,
      child: Opacity(
        opacity: goalZonesEnabled ? 1 : 0.40,
        child: Column(
          children: _goalRows
              .map(
                (row) => Expanded(
                  child: Row(
                    children: row
                        .map(
                          (goalZoneId) => Expanded(
                            child: _GoalCell(
                              goalZoneId: goalZoneId,
                              isSelected: selectedGoalZoneId == goalZoneId,
                              enabled: enabled && goalZonesEnabled,
                              onTap: () => onGoalZoneSelected(goalZoneId),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: _boardAspectRatio,
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
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF07152D).withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScoutLanceMapPainter(),
                    ),
                  ),
                  _goalGrid(width, height),
                  for (final entry in _shotZoneAnchors.entries)
                    _shotMarker(entry.key, entry.value, width, height),
                  _sevenMeterMarker(width, height),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HitRegion extends StatelessWidget {
  final double width;
  final double height;
  final bool isSelected;
  final VoidCallback? onTap;

  const _HitRegion({
    required this.width,
    required this.height,
    required this.isSelected,
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
            color: isSelected
                ? const Color(0xFFFFD33D).withValues(alpha: 0.26)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: isSelected
                ? Border.all(
                    color: const Color(0xFFFFE76A),
                    width: 2.2,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD33D).withValues(alpha: 0.38),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _SevenMeterButton extends StatelessWidget {
  final double width;
  final double height;
  final bool isSelected;
  final VoidCallback? onTap;
  final double fontSize;

  const _SevenMeterButton({
    required this.width,
    required this.height,
    required this.isSelected,
    required this.onTap,
    required this.fontSize,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFE76A) : Colors.white,
              width: isSelected ? 2.2 : 1.1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFFFFD33D).withValues(alpha: 0.42),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Text(
            '7m',
            style: TextStyle(
              color: const Color(0xFF1956B6),
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalCell extends StatelessWidget {
  final int goalZoneId;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _GoalCell({
    required this.goalZoneId,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD33D).withValues(alpha: 0.30)
              : Colors.transparent,
          border: Border.all(color: Colors.white.withValues(alpha: 0.72), width: 0.8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD33D).withValues(alpha: 0.34),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// Draws the handball half-court: goal net, 6m goal area (solid half-ellipse),
/// 9m free-throw line (dashed, concentric half-ellipse) and the sidelines /
/// zone dividers, all connected to one another with no floating segments.
class _ScoutLanceMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeWidth = width * 0.006
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dashedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = width * 0.005
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = width * 0.003
      ..style = PaintingStyle.stroke;

    final goalWhitePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = width * 0.024
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final goalRedPaint = Paint()
      ..color = const Color(0xFFFF584D)
      ..strokeWidth = width * 0.024
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final areaFillPaint = Paint()
      ..color = const Color(0xFF1956B6).withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    // ----- key coordinates -----
    final centerX = width / 2;
    final goalLeft = width * 0.14;
    final goalRight = width * 0.86;
    final goalTop = height * 0.05;
    final goalBottom = height * 0.32; // goal line: where the 6m area starts
    final goalLineY = goalBottom;

    // ----- goal net grid -----
    for (var i = 1; i < 11; i++) {
      final x = goalLeft + ((goalRight - goalLeft) * i / 11);
      canvas.drawLine(Offset(x, goalTop), Offset(x, goalBottom), netPaint);
    }
    for (var i = 1; i < 5; i++) {
      final y = goalTop + ((goalBottom - goalTop) * i / 5);
      canvas.drawLine(Offset(goalLeft, y), Offset(goalRight, y), netPaint);
    }

    void drawStripedLine({
      required Offset start,
      required Offset end,
      required int segments,
    }) {
      canvas.drawLine(start, end, goalWhitePaint);
      for (var i = 0; i < segments; i += 2) {
        final t1 = i / segments;
        final t2 = (i + 1) / segments;
        final sx = start.dx + ((end.dx - start.dx) * t1);
        final sy = start.dy + ((end.dy - start.dy) * t1);
        final ex = start.dx + ((end.dx - start.dx) * t2);
        final ey = start.dy + ((end.dy - start.dy) * t2);
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), goalRedPaint);
      }
    }

    drawStripedLine(
      start: Offset(goalLeft, goalTop),
      end: Offset(goalRight, goalTop),
      segments: 14,
    );
    drawStripedLine(
      start: Offset(goalLeft, goalTop),
      end: Offset(goalLeft, goalBottom),
      segments: 8,
    );
    drawStripedLine(
      start: Offset(goalRight, goalTop),
      end: Offset(goalRight, goalBottom),
      segments: 8,
    );

    // ----- 6m goal area: a real half-ellipse ("D" shape) -----
    // Flat edge = the goal line itself (goalLeft -> goalRight), curved edge
    // bulges toward the court. Using an actual elliptical arc (not a Bezier
    // approximation) keeps it perfectly smooth and symmetric.
    final areaRx = (goalRight - goalLeft) / 2;
    final areaRy = height * 0.30;
    final areaRect = Rect.fromCenter(
      center: Offset(centerX, goalLineY),
      width: areaRx * 2,
      height: areaRy * 2,
    );

    // angle 0 = east, increases clockwise (y grows downward).
    // pi = west (goalLeft) -> sweep -pi clockwise through south (bottom) -> 0 = east (goalRight)
    final areaPath = Path()
      ..moveTo(goalLeft, goalLineY)
      ..arcTo(areaRect, math.pi, -math.pi, false)
      ..close();

    canvas.drawPath(areaPath, areaFillPaint);
    canvas.drawPath(areaPath, linePaint);

    // ----- 9m free-throw line: concentric dashed half-ellipse -----
    final nineRx = areaRx + width * 0.14;
    final nineRy = areaRy + height * 0.14;
    final nineRect = Rect.fromCenter(
      center: Offset(centerX, goalLineY),
      width: nineRx * 2,
      height: nineRy * 2,
    );

    _drawDashedArc(
      canvas: canvas,
      rect: nineRect,
      startAngle: math.pi,
      totalSweep: -math.pi,
      dashAngle: 0.13,
      gapAngle: 0.09,
      paint: dashedPaint,
    );

    // ----- sidelines: continue straight from the 6m area's flat-top corners -----
    final bottomY = height * 0.99;
    canvas.drawLine(Offset(goalLeft, goalLineY), Offset(width * 0.015, bottomY), linePaint);
    canvas.drawLine(Offset(goalRight, goalLineY), Offset(width * 0.985, bottomY), linePaint);

    // ----- inner dividers: split the middle zones (2/9 | 3/8 | 4/7) -----
    final dividerTopY = goalLineY + (areaRy * 1.35);
    canvas.drawLine(
      Offset(centerX - width * 0.09, dividerTopY),
      Offset(width * 0.34, bottomY),
      linePaint,
    );
    canvas.drawLine(
      Offset(centerX + width * 0.09, dividerTopY),
      Offset(width * 0.66, bottomY),
      linePaint,
    );

    // small centre tick on the 6m line, just above its apex
    final apexY = goalLineY + areaRy;
    canvas.drawLine(
      Offset(centerX - width * 0.035, apexY - height * 0.02),
      Offset(centerX + width * 0.035, apexY - height * 0.02),
      linePaint,
    );
  }

  void _drawDashedArc({
    required Canvas canvas,
    required Rect rect,
    required double startAngle,
    required double totalSweep,
    required double dashAngle,
    required double gapAngle,
    required Paint paint,
  }) {
    final direction = totalSweep.isNegative ? -1.0 : 1.0;
    final totalAbs = totalSweep.abs();
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
