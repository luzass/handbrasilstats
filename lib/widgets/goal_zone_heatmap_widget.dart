import 'package:flutter/material.dart';

import '../models/match_goal_zone_breakdown_model.dart';

class GoalZoneHeatmapWidget extends StatelessWidget {
  final List<MatchGoalZoneBreakdownModel> breakdown;
  final bool isGoalkeeper;

  const GoalZoneHeatmapWidget({
    super.key,
    required this.breakdown,
    required this.isGoalkeeper,
  });

  static const List<List<int>> _rows = [
    [1, 4, 7],
    [2, 5, 8],
    [3, 6, 9],
  ];

  MatchGoalZoneBreakdownModel? _findZone(int goalZoneId) {
    try {
      return breakdown.firstWhere((e) => e.goalZoneId == goalZoneId);
    } catch (_) {
      return null;
    }
  }

  Color _zoneColor(MatchGoalZoneBreakdownModel? zone) {
    if (zone == null || zone.totalShots == 0) {
      return Colors.white;
    }

    final percentage = zone.percentage;

    if (percentage >= 80) return Colors.green.shade300;
    if (percentage >= 60) return Colors.green.shade200;
    if (percentage >= 40) return Colors.yellow.shade200;
    if (percentage >= 20) return Colors.orange.shade200;
    return Colors.red.shade200;
  }

  Widget _buildCell(int goalZoneId) {
    final zone = _findZone(goalZoneId);
    final percentage = zone?.percentage ?? 0;
    final totalShots = zone?.totalShots ?? 0;
    final primaryValue =
        isGoalkeeper ? (zone?.totalSaves ?? 0) : (zone?.totalGoals ?? 0);
    final hasData = totalShots > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelSize = constraints.maxHeight * 0.22;
        final statSize = constraints.maxHeight * 0.18;
        final subSize = constraints.maxHeight * 0.12;

        return Container(
          decoration: BoxDecoration(
            color: _zoneColor(zone),
            border: Border.all(color: Colors.black.withValues(alpha: 0.2), width: 0.8),
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
                    fontWeight: FontWeight.w900,
                    fontSize: labelSize,
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.02),
                Text(
                  hasData ? '${percentage.toStringAsFixed(1)}%' : '-',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: statSize,
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.01),
                Text(
                  isGoalkeeper ? 'Def: $primaryValue' : 'Gol: $primaryValue',
                  style: TextStyle(
                    fontSize: subSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Ch: $totalShots',
                  style: TextStyle(
                    fontSize: subSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 1.55,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GoalHeatmapFramePainter(),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        constraints.maxWidth * 0.07,
                        constraints.maxHeight * 0.07,
                        constraints.maxWidth * 0.07,
                        constraints.maxHeight * 0.08,
                      ),
                      child: Column(
                        children: _rows
                            .map(
                              (row) => Expanded(
                                child: Row(
                                  children: row
                                      .map(
                                        (goalZoneId) => Expanded(
                                          child: _buildCell(goalZoneId),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GoalHeatmapFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sideInset = size.width * 0.06;
    final topInset = size.height * 0.07;
    final bottomInset = size.height * 0.08;
    final left = sideInset;
    final right = size.width - sideInset;
    final top = topInset;
    final bottom = size.height - bottomInset;

    final whitePaint = Paint()
      ..color = const Color(0xFFD6D9DE)
      ..strokeWidth = size.width * 0.024
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final redPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = size.width * 0.024
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    void drawStripedLine({
      required Offset start,
      required Offset end,
      required int segments,
    }) {
      canvas.drawLine(start, end, whitePaint);
      for (var i = 0; i < segments; i += 2) {
        final t1 = i / segments;
        final t2 = (i + 1) / segments;
        final sx = start.dx + ((end.dx - start.dx) * t1);
        final sy = start.dy + ((end.dy - start.dy) * t1);
        final ex = start.dx + ((end.dx - start.dx) * t2);
        final ey = start.dy + ((end.dy - start.dy) * t2);
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), redPaint);
      }
    }

    drawStripedLine(
      start: Offset(left, top),
      end: Offset(right, top),
      segments: 12,
    );
    drawStripedLine(
      start: Offset(left, top),
      end: Offset(left, bottom),
      segments: 8,
    );
    drawStripedLine(
      start: Offset(right, top),
      end: Offset(right, bottom),
      segments: 8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
