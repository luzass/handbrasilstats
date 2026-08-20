import 'dart:math' as math;

import 'package:flutter/material.dart';

class ScoutLanceMapSelector extends StatelessWidget {
  static const double _boardAspectRatio = 1.15;

  // ----- shared court geometry -----
  // Single source of truth for where the goal line, 6m area and 9m line
  // sit (as a fraction of the board height). Both the tap-zone anchors
  // below and the CustomPainter read these, so the clickable zones always
  // line up with what's actually drawn, even if these numbers change.
  static const double goalLineY = 0.36;
  static const double sixMeterDepth = 0.15; // 6m area bulge, below goalLineY
  static const double nineMeterExtra = 0.12; // extra depth of the 9m line, below the 6m apex
  static const double sixMeterApexY = goalLineY + sixMeterDepth; // ~0.48
  static const double nineMeterApexY = sixMeterApexY + nineMeterExtra; // ~0.61
  static const double bottomY = 0.77;

  final int? selectedZoneId;
  final int? selectedGoalZoneId;
  final ValueChanged<int> onZoneSelected;
  final ValueChanged<int> onGoalZoneSelected;
  final bool goalZonesEnabled;
  final bool outsideGoalZonesEnabled;
  final bool enabled;

  const ScoutLanceMapSelector({
    super.key,
    required this.selectedZoneId,
    required this.selectedGoalZoneId,
    required this.onZoneSelected,
    required this.onGoalZoneSelected,
    required this.goalZonesEnabled,
    this.outsideGoalZonesEnabled = false,
    this.enabled = true,
  });

  static const Offset _sevenMeterAnchor = Offset(0.50, 0.55);

  static const List<List<int>> _goalRows = [
    [1, 4, 7],
    [2, 5, 8],
    [3, 6, 9],
  ];

  static const Map<int, Offset> _shotZoneAnchors = {
    1: Offset(0.16, 0.48),
    5: Offset(0.84, 0.48),
    10: Offset(0.05, 0.58),
    6: Offset(0.95, 0.58),
    2: Offset(0.28, 0.58),
    3: Offset(0.50, 0.64),
    4: Offset(0.72, 0.58),
    9: Offset(0.22, 0.72),
    8: Offset(0.50, 0.72),
    7: Offset(0.78, 0.72),
  };

  Widget _shotMarker(
    int zoneId,
    Offset anchor,
    double width,
    double height,
  ) {
    final isSelected = selectedZoneId == zoneId;
    final markerWidth = (width * 0.115).clamp(42.0, 74.0).toDouble();
    final markerHeight = (height * 0.054).clamp(24.0, 40.0).toDouble();
    final fontSize = (markerHeight * 0.46).clamp(11.0, 17.0).toDouble();

    return Positioned(
      left: (width * anchor.dx) - (markerWidth / 2),
      top: (height * anchor.dy) - (markerHeight / 2),
      child: _ShotZoneButton(
        label: 'Z${zoneId.toString().padLeft(2, '0')}',
        width: markerWidth,
        height: markerHeight,
        isSelected: isSelected,
        onTap: enabled ? () => onZoneSelected(zoneId) : null,
        fontSize: fontSize,
      ),
    );
  }

  Widget _sevenMeterMarker(double width, double height) {
    final isSelected = selectedZoneId == 11;
    final markerWidth = (width * 0.115).clamp(42.0, 74.0).toDouble();
    final markerHeight = (height * 0.054).clamp(24.0, 40.0).toDouble();
    final fontSize = (markerHeight * 0.46).clamp(11.0, 17.0).toDouble();

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
    final top = height * 0.06;
    final goalWidth = width * 0.72;
    final goalHeight = height * 0.30;
    final outsideWidth = width * 0.11;
    final outsideTopHeight = height * 0.045;
    final innerCellWidth = goalWidth / 3;
    final innerCellHeight = goalHeight / 3;

    Widget cell({
      required int goalZoneId,
      required double cellLeft,
      required double cellTop,
      required double cellWidth,
      required double cellHeight,
      required bool enabledCell,
    }) {
      return Positioned(
        left: cellLeft,
        top: cellTop,
        width: cellWidth,
        height: cellHeight,
        child: _GoalCell(
          goalZoneId: goalZoneId,
          isSelected: selectedGoalZoneId == goalZoneId,
          enabled: enabled && enabledCell,
          onTap: () => onGoalZoneSelected(goalZoneId),
        ),
      );
    }

    return Positioned(
      left: left - outsideWidth,
      top: top - outsideTopHeight,
      width: goalWidth + (outsideWidth * 2),
      height: goalHeight + outsideTopHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (outsideGoalZonesEnabled) ...[
            for (var column = 1; column < 4; column++)
              cell(
                goalZoneId: 10 + column,
                cellLeft: outsideWidth + ((column - 1) * innerCellWidth),
                cellTop: 0,
                cellWidth: innerCellWidth,
                cellHeight: outsideTopHeight,
                enabledCell: true,
              ),
            for (var row = 0; row < 3; row++)
              cell(
                goalZoneId: 15 + row,
                cellLeft: 0,
                cellTop: outsideTopHeight + (row * innerCellHeight),
                cellWidth: outsideWidth,
                cellHeight: innerCellHeight,
                enabledCell: true,
              ),
            for (var row = 0; row < 3; row++)
              cell(
                goalZoneId: 18 + row,
                cellLeft: outsideWidth + goalWidth,
                cellTop: outsideTopHeight + (row * innerCellHeight),
                cellWidth: outsideWidth,
                cellHeight: innerCellHeight,
                enabledCell: true,
              ),
          ],
          Opacity(
            opacity: goalZonesEnabled ? 1 : 0.40,
            child: Stack(
              children: [
                for (var row = 0; row < _goalRows.length; row++)
                  for (var column = 0; column < _goalRows[row].length; column++)
                    cell(
                      goalZoneId: _goalRows[row][column],
                      cellLeft: outsideWidth + (column * innerCellWidth),
                      cellTop: outsideTopHeight + (row * innerCellHeight),
                      cellWidth: innerCellWidth,
                      cellHeight: innerCellHeight,
                      enabledCell: goalZonesEnabled,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: bottomY,
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
        ),
      ),
    );
  }
}

class _ShotZoneButton extends StatelessWidget {
  final String label;
  final double width;
  final double height;
  final bool isSelected;
  final VoidCallback? onTap;
  final double fontSize;

  const _ShotZoneButton({
    required this.label,
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
            color: isSelected
                ? const Color(0xFFFFD33D).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFE76A) : Colors.white,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFFFFD33D).withValues(alpha: 0.42),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
            ],
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

    // ----- key coordinates (shared with ScoutLanceMapSelector's tap zones) -----
    final centerX = width / 2;
    final goalLeft = width * 0.14;
    final goalRight = width * 0.86;
    final goalTop = height * 0.06;
    final goalLineY = height * ScoutLanceMapSelector.goalLineY; // where the 6m area starts

    // ----- goal net grid -----
    for (var i = 1; i < 11; i++) {
      final x = goalLeft + ((goalRight - goalLeft) * i / 11);
      canvas.drawLine(Offset(x, goalTop), Offset(x, goalLineY), netPaint);
    }
    for (var i = 1; i < 5; i++) {
      final y = goalTop + ((goalLineY - goalTop) * i / 5);
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
      end: Offset(goalLeft, goalLineY),
      segments: 8,
    );
    drawStripedLine(
      start: Offset(goalRight, goalTop),
      end: Offset(goalRight, goalLineY),
      segments: 8,
    );

    // ----- 6m goal area: a real half-ellipse ("D" shape) -----
    // Flat edge = the goal line itself (goalLeft -> goalRight), curved edge
    // bulges toward the court. Using an actual elliptical arc (not a Bezier
    // approximation) keeps it perfectly smooth and symmetric.
    final areaRx = (goalRight - goalLeft) / 2;
    final areaRy = height * ScoutLanceMapSelector.sixMeterDepth;
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
    canvas.drawLine(
      Offset(width * 0.01, goalLineY),
      Offset(width * 0.99, goalLineY),
      linePaint,
    );

    // ----- 9m free-throw line: concentric dashed half-ellipse -----
    final nineRx = areaRx + width * 0.14;
    final nineRy = areaRy + height * ScoutLanceMapSelector.nineMeterExtra;
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

    // ----- visible court cuts: keep only the compact section above bottomY -----
    // The long continuation of these guide lines is intentionally clipped out,
    // matching the compact attack-map reference instead of showing a full court.
    final bottomY = height * ScoutLanceMapSelector.bottomY;
    final leftSideStart = Offset(width * 0.18, goalLineY + areaRy * 0.70);
    final rightSideStart = Offset(width * 0.82, goalLineY + areaRy * 0.70);
    final leftSideEnd = Offset(width * 0.01, bottomY);
    final rightSideEnd = Offset(width * 0.99, bottomY);
    final leftInnerStart = Offset(width * 0.39, goalLineY + areaRy * 1.02);
    final rightInnerStart = Offset(width * 0.61, goalLineY + areaRy * 1.02);

    canvas.drawLine(
      leftSideStart,
      leftSideEnd,
      linePaint,
    );
    canvas.drawLine(
      rightSideStart,
      rightSideEnd,
      linePaint,
    );
    canvas.drawLine(
      leftInnerStart,
      Offset(width * 0.28, bottomY),
      linePaint,
    );
    canvas.drawLine(
      rightInnerStart,
      Offset(width * 0.72, bottomY),
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
