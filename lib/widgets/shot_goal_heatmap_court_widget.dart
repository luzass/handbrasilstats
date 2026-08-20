import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/match_goal_zone_breakdown_model.dart';

class ShotGoalHeatmapCourtWidget extends StatelessWidget {
  final List<MatchGoalZoneBreakdownModel> breakdown;
  final bool isGoalkeeper;
  final int? selectedShotZoneId;
  final ValueChanged<int?> onShotZoneSelected;

  const ShotGoalHeatmapCourtWidget({
    super.key,
    required this.breakdown,
    required this.isGoalkeeper,
    required this.selectedShotZoneId,
    required this.onShotZoneSelected,
  });

  static const double _aspectRatio = 1.15;
  static const List<List<int>> _goalRows = [
    [1, 4, 7],
    [2, 5, 8],
    [3, 6, 9],
  ];
  static const Map<int, Offset> _shotZoneAnchors = {
    1: Offset(0.11, 0.40),
    5: Offset(0.89, 0.40),
    10: Offset(0.05, 0.58),
    6: Offset(0.95, 0.58),
    2: Offset(0.31, 0.49),
    3: Offset(0.50, 0.54),
    4: Offset(0.69, 0.49),
    9: Offset(0.18, 0.67),
    8: Offset(0.50, 0.72),
    7: Offset(0.82, 0.67),
    11: Offset(0.50, 0.46),
  };

  MatchGoalZoneBreakdownModel? _findGoalZone(int goalZoneId) {
    try {
      return breakdown.firstWhere((zone) => zone.goalZoneId == goalZoneId);
    } catch (_) {
      return null;
    }
  }

  Color _goalZoneColor(MatchGoalZoneBreakdownModel? zone) {
    if (zone == null || zone.totalShots == 0) {
      return Colors.white.withValues(alpha: 0.90);
    }

    final percentage = zone.percentage;
    if (percentage >= 80) return Colors.green.shade300;
    if (percentage >= 60) return Colors.green.shade200;
    if (percentage >= 40) return Colors.yellow.shade200;
    if (percentage >= 20) return Colors.orange.shade200;
    return Colors.red.shade200;
  }

  String _shotZoneLabel(int zoneId) {
    if (zoneId == 11) {
      return '7M';
    }
    return 'Z${zoneId.toString().padLeft(2, '0')}';
  }

  Widget _shotZoneButton({
    required int zoneId,
    required Offset anchor,
    required double width,
    required double height,
  }) {
    final selected = selectedShotZoneId == zoneId;
    final buttonWidth = (width * 0.115).clamp(42.0, 74.0).toDouble();
    final buttonHeight = (height * 0.054).clamp(24.0, 40.0).toDouble();
    final fontSize = (buttonHeight * 0.46).clamp(11.0, 17.0).toDouble();

    return Positioned(
      left: (width * anchor.dx) - (buttonWidth / 2),
      top: (height * anchor.dy) - (buttonHeight / 2),
      child: _PillButton(
        label: _shotZoneLabel(zoneId),
        width: buttonWidth,
        height: buttonHeight,
        fontSize: fontSize,
        selected: selected,
        onTap: () => onShotZoneSelected(zoneId),
      ),
    );
  }

  Widget _goalHeatmap({
    required double width,
    required double height,
  }) {
    final goalLeft = width * 0.14;
    final goalTop = height * 0.06;
    final goalWidth = width * 0.72;
    final goalHeight = height * 0.30;

    return Positioned(
      left: goalLeft,
      top: goalTop,
      width: goalWidth,
      height: goalHeight,
      child: Column(
        children: [
          for (final row in _goalRows)
            Expanded(
              child: Row(
                children: [
                  for (final goalZoneId in row)
                    Expanded(
                      child: _GoalHeatmapCell(
                        goalZoneId: goalZoneId,
                        zone: _findGoalZone(goalZoneId),
                        color: _goalZoneColor(_findGoalZone(goalZoneId)),
                        isGoalkeeper: isGoalkeeper,
                      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _PillButton(
            label: 'Geral',
            width: 92,
            height: 34,
            fontSize: 13,
            selected: selectedShotZoneId == null,
            onTap: () => onShotZoneSelected(null),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 0.77,
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
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _CourtGoalFramePainter(),
                              ),
                            ),
                            _goalHeatmap(width: width, height: height),
                            for (final entry in _shotZoneAnchors.entries)
                              _shotZoneButton(
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
          ),
        ),
      ],
    );
  }
}

class _GoalHeatmapCell extends StatelessWidget {
  final int goalZoneId;
  final MatchGoalZoneBreakdownModel? zone;
  final Color color;
  final bool isGoalkeeper;

  const _GoalHeatmapCell({
    required this.goalZoneId,
    required this.zone,
    required this.color,
    required this.isGoalkeeper,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = zone?.percentage ?? 0;
    final totalShots = zone?.totalShots ?? 0;
    final primaryValue =
        isGoalkeeper ? (zone?.totalSaves ?? 0) : (zone?.totalGoals ?? 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelSize = constraints.maxHeight * 0.22;
        final statSize = constraints.maxHeight * 0.17;
        final subSize = constraints.maxHeight * 0.11;

        return Container(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.74),
              width: 0.9,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'G${goalZoneId.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: const Color(0xFF51617A),
                    fontWeight: FontWeight.w900,
                    fontSize: labelSize,
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.02),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: const Color(0xFF51617A),
                    fontWeight: FontWeight.w800,
                    fontSize: statSize,
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.01),
                Text(
                  isGoalkeeper ? 'Def: $primaryValue' : 'Gol: $primaryValue',
                  style: TextStyle(
                    color: const Color(0xFF51617A),
                    fontSize: subSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Ch: $totalShots',
                  style: TextStyle(
                    color: const Color(0xFF51617A),
                    fontSize: subSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final double width;
  final double height;
  final double fontSize;
  final bool selected;
  final VoidCallback onTap;

  const _PillButton({
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

class _CourtGoalFramePainter extends CustomPainter {
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

    final centerX = width / 2;
    final goalLeft = width * 0.14;
    final goalRight = width * 0.86;
    final goalTop = height * 0.06;
    final goalLineY = height * 0.36;

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

    final areaRx = (goalRight - goalLeft) / 2;
    final areaRy = height * 0.15;
    final areaRect = Rect.fromCenter(
      center: Offset(centerX, goalLineY),
      width: areaRx * 2,
      height: areaRy * 2,
    );
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

    final nineRect = Rect.fromCenter(
      center: Offset(centerX, goalLineY),
      width: (areaRx + (width * 0.14)) * 2,
      height: (areaRy + (height * 0.12)) * 2,
    );
    _drawDashedArc(canvas: canvas, rect: nineRect, paint: dashedPaint);

    final bottomY = height * 0.77;
    canvas.drawLine(
      Offset(width * 0.18, goalLineY + (areaRy * 0.70)),
      Offset(width * 0.01, bottomY),
      linePaint,
    );
    canvas.drawLine(
      Offset(width * 0.82, goalLineY + (areaRy * 0.70)),
      Offset(width * 0.99, bottomY),
      linePaint,
    );
    canvas.drawLine(
      Offset(width * 0.39, goalLineY + (areaRy * 1.02)),
      Offset(width * 0.28, bottomY),
      linePaint,
    );
    canvas.drawLine(
      Offset(width * 0.61, goalLineY + (areaRy * 1.02)),
      Offset(width * 0.72, bottomY),
      linePaint,
    );
  }

  void _drawDashedArc({
    required Canvas canvas,
    required Rect rect,
    required Paint paint,
  }) {
    const startAngle = math.pi;
    const direction = -1.0;
    const totalAbs = math.pi;
    const dashAngle = 0.13;
    const gapAngle = 0.09;
    var covered = 0.0;

    while (covered < totalAbs) {
      final remaining = totalAbs - covered;
      final sweep = (dashAngle < remaining ? dashAngle : remaining) * direction;
      canvas.drawArc(
        rect,
        startAngle + (covered * direction),
        sweep,
        false,
        paint,
      );
      covered += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
