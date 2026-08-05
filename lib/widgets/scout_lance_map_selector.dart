import 'dart:math' as math;

import 'package:flutter/material.dart';

class ScoutLanceMapSelector extends StatelessWidget {
  static const double _boardAspectRatio = 0.88;

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
  static const double bottomY = 0.69;

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

  static const Offset _sevenMeterAnchor = Offset(0.50, 0.61);

  static const List<List<int>> _goalRows = [
    [1, 4, 7],
    [2, 5, 8],
    [3, 6, 9],
  ];

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
    final top = height * 0.06;
    final goalWidth = width * 0.72;
    final goalHeight = height * 0.30;

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
                      Positioned.fill(
                        child: _ShotZoneLayer(
                          selectedZoneId: selectedZoneId,
                          enabled: enabled,
                          onZoneSelected: onZoneSelected,
                        ),
                      ),
                      _goalGrid(width, height),
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

class _ShotZoneLayer extends StatelessWidget {
  final int? selectedZoneId;
  final bool enabled;
  final ValueChanged<int> onZoneSelected;

  const _ShotZoneLayer({
    required this.selectedZoneId,
    required this.enabled,
    required this.onZoneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: enabled
              ? (details) {
                  final zoneId = _ShotZoneGeometry.hitTest(
                    details.localPosition,
                    size,
                  );
                  if (zoneId != null) {
                    onZoneSelected(zoneId);
                  }
                }
              : null,
          child: CustomPaint(
            painter: _ShotZoneHighlightPainter(selectedZoneId),
          ),
        );
      },
    );
  }
}

class _ShotZoneHighlightPainter extends CustomPainter {
  final int? selectedZoneId;

  const _ShotZoneHighlightPainter(this.selectedZoneId);

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedZoneId == null || selectedZoneId == 11) {
      return;
    }

    final path = _ShotZoneGeometry.pathFor(selectedZoneId!, size);
    if (path == null) {
      return;
    }

    final fillPaint = Paint()
      ..color = const Color(0xFFFFD33D).withValues(alpha: 0.46)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFFFFE76A)
      ..strokeWidth = size.width * 0.006
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ShotZoneHighlightPainter oldDelegate) {
    return oldDelegate.selectedZoneId != selectedZoneId;
  }
}

class _ShotZoneGeometry {
  static const List<int> _zoneOrder = [1, 5, 10, 6, 2, 3, 4, 9, 8, 7];

  static int? hitTest(Offset position, Size size) {
    for (final zoneId in _zoneOrder) {
      final path = pathFor(zoneId, size);
      if (path != null && path.contains(position)) {
        return zoneId;
      }
    }
    return null;
  }

  static Path? pathFor(int zoneId, Size size) {
    final width = size.width;
    final height = size.height;

    switch (zoneId) {
      case 1:
        return Path()
          ..moveTo(0, height * 0.36)
          ..lineTo(width * 0.14, height * 0.36)
          ..quadraticBezierTo(width * 0.145, height * 0.44, width * 0.18, height * 0.465)
          ..lineTo(width * 0.10, height * 0.53)
          ..lineTo(0, height * 0.45)
          ..close();
      case 5:
        return Path()
          ..moveTo(width, height * 0.36)
          ..lineTo(width * 0.86, height * 0.36)
          ..quadraticBezierTo(width * 0.855, height * 0.44, width * 0.82, height * 0.465)
          ..lineTo(width * 0.90, height * 0.53)
          ..lineTo(width, height * 0.45)
          ..close();
      case 10:
        return Path()
          ..moveTo(0, height * 0.45)
          ..lineTo(width * 0.10, height * 0.53)
          ..lineTo(width * 0.18, height * 0.58)
          ..lineTo(width * 0.03, height * 0.61)
          ..lineTo(0, height * 0.54)
          ..close();
      case 6:
        return Path()
          ..moveTo(width, height * 0.45)
          ..lineTo(width * 0.90, height * 0.53)
          ..lineTo(width * 0.82, height * 0.58)
          ..lineTo(width * 0.97, height * 0.61)
          ..lineTo(width, height * 0.54)
          ..close();
      case 2:
        return Path()
          ..moveTo(width * 0.18, height * 0.465)
          ..quadraticBezierTo(width * 0.27, height * 0.505, width * 0.39, height * 0.515)
          ..lineTo(width * 0.34, height * 0.62)
          ..lineTo(width * 0.18, height * 0.58)
          ..lineTo(width * 0.10, height * 0.53)
          ..close();
      case 3:
        return Path()
          ..moveTo(width * 0.39, height * 0.515)
          ..quadraticBezierTo(width * 0.50, height * 0.535, width * 0.61, height * 0.515)
          ..lineTo(width * 0.66, height * 0.62)
          ..quadraticBezierTo(width * 0.50, height * 0.65, width * 0.34, height * 0.62)
          ..close();
      case 4:
        return Path()
          ..moveTo(width * 0.61, height * 0.515)
          ..quadraticBezierTo(width * 0.73, height * 0.505, width * 0.82, height * 0.465)
          ..lineTo(width * 0.90, height * 0.53)
          ..lineTo(width * 0.82, height * 0.58)
          ..lineTo(width * 0.66, height * 0.62)
          ..close();
      case 9:
        return Path()
          ..moveTo(width * 0.03, height * 0.61)
          ..lineTo(width * 0.34, height * 0.62)
          ..lineTo(width * 0.28, height * ScoutLanceMapSelector.bottomY)
          ..lineTo(width * 0.01, height * ScoutLanceMapSelector.bottomY)
          ..close();
      case 8:
        return Path()
          ..moveTo(width * 0.34, height * 0.62)
          ..quadraticBezierTo(width * 0.50, height * 0.65, width * 0.66, height * 0.62)
          ..lineTo(width * 0.72, height * ScoutLanceMapSelector.bottomY)
          ..lineTo(width * 0.28, height * ScoutLanceMapSelector.bottomY)
          ..close();
      case 7:
        return Path()
          ..moveTo(width * 0.66, height * 0.62)
          ..lineTo(width * 0.97, height * 0.61)
          ..lineTo(width * 0.99, height * ScoutLanceMapSelector.bottomY)
          ..lineTo(width * 0.72, height * ScoutLanceMapSelector.bottomY)
          ..close();
      default:
        return null;
    }
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
