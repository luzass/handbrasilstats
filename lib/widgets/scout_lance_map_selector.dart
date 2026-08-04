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
    1: Offset(0.14, 0.49),
    5: Offset(0.86, 0.49),
    10: Offset(0.16, 0.60),
    6: Offset(0.84, 0.60),
    2: Offset(0.31, 0.70),
    3: Offset(0.50, 0.72),
    4: Offset(0.69, 0.70),
    9: Offset(0.17, 0.90),
    8: Offset(0.50, 0.90),
    7: Offset(0.83, 0.90),
  };

  static const Offset _sevenMeterAnchor = Offset(0.50, 0.58);

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
    final markerWidth = (width * 0.16).clamp(44.0, 68.0).toDouble();
    final markerHeight = (height * 0.055).clamp(28.0, 38.0).toDouble();
    final fontSize = (markerHeight * 0.34).clamp(10.0, 13.0).toDouble();

    return Positioned(
      left: (width * anchor.dx) - (markerWidth / 2),
      top: (height * anchor.dy) - (markerHeight / 2),
      child: _MapButton(
        width: markerWidth,
        height: markerHeight,
        isSelected: isSelected,
        onTap: enabled ? () => onZoneSelected(zoneId) : null,
        label: 'Z${zoneId.toString().padLeft(2, '0')}',
        fontSize: fontSize,
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
      child: _MapButton(
        width: markerWidth,
        height: markerHeight,
        isSelected: isSelected,
        onTap: enabled ? () => onZoneSelected(11) : null,
        label: '7M',
        fontSize: fontSize,
        pill: true,
      ),
    );
  }

  Widget _goalGrid(double width, double height) {
    final left = width * 0.18;
    final top = height * 0.08;
    final goalWidth = width * 0.64;
    final goalHeight = height * 0.24;
    final fontSize = (width * 0.032).clamp(10.0, 14.0).toDouble();

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
                              fontSize: fontSize,
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

class _MapButton extends StatelessWidget {
  final double width;
  final double height;
  final bool isSelected;
  final VoidCallback? onTap;
  final String label;
  final double fontSize;
  final bool pill;

  const _MapButton({
    required this.width,
    required this.height,
    required this.isSelected,
    required this.onTap,
    required this.label,
    required this.fontSize,
    this.pill = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(pill ? 999 : 14),
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFD33D) : const Color(0xF20B1933),
            borderRadius: BorderRadius.circular(pill ? 999 : 14),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFE76A) : Colors.white.withValues(alpha: 0.72),
              width: isSelected ? 2.2 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF07152D) : Colors.white,
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
  final double fontSize;

  const _GoalCell({
    required this.goalZoneId,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD33D).withValues(alpha: 0.86)
              : Colors.white.withValues(alpha: 0.02),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72), width: 0.8),
        ),
        alignment: Alignment.center,
        child: Text(
          'G${goalZoneId.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: isSelected ? const Color(0xFF07152D) : Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ScoutLanceMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = size.width * 0.006
      ..style = PaintingStyle.stroke;

    final dashedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.76)
      ..strokeWidth = size.width * 0.005
      ..style = PaintingStyle.stroke;

    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = size.width * 0.003
      ..style = PaintingStyle.stroke;

    final goalWhitePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.020
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final goalRedPaint = Paint()
      ..color = const Color(0xFFFF584D)
      ..strokeWidth = size.width * 0.020
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final areaFillPaint = Paint()
      ..color = const Color(0xFF1956B6).withValues(alpha: 0.86)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final goalLeft = size.width * 0.18;
    final goalRight = size.width * 0.82;
    final goalTop = size.height * 0.08;
    final goalBottom = size.height * 0.32;
    final courtLineY = size.height * 0.36;
    final arcCenter = Offset(centerX, goalTop);
    final areaRadius = size.width * 0.36;
    final freeThrowRadius = size.width * 0.51;

    for (var i = 1; i < 10; i++) {
      final x = goalLeft + ((goalRight - goalLeft) * i / 10);
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
      segments: 12,
    );
    drawStripedLine(
      start: Offset(goalLeft, goalTop),
      end: Offset(goalLeft, goalBottom),
      segments: 6,
    );
    drawStripedLine(
      start: Offset(goalRight, goalTop),
      end: Offset(goalRight, goalBottom),
      segments: 6,
    );

    canvas.drawLine(
      Offset(size.width * 0.04, courtLineY),
      Offset(size.width * 0.96, courtLineY),
      linePaint,
    );

    final areaPath = Path()
      ..moveTo(size.width * 0.08, courtLineY)
      ..lineTo(size.width * 0.26, courtLineY)
      ..arcTo(
        Rect.fromCircle(center: arcCenter, radius: areaRadius),
        math.pi * 0.24,
        math.pi * 0.52,
        false,
      )
      ..lineTo(size.width * 0.92, courtLineY)
      ..lineTo(size.width * 0.08, courtLineY)
      ..close();
    canvas.drawPath(areaPath, areaFillPaint);
    canvas.drawPath(areaPath, linePaint);

    canvas.drawLine(
      Offset(size.width * 0.08, courtLineY),
      Offset(size.width * 0.25, size.height * 0.50),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.92, courtLineY),
      Offset(size.width * 0.75, size.height * 0.50),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.70),
      Offset(size.width * 0.42, size.height * 0.48),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, size.height * 0.70),
      Offset(size.width * 0.58, size.height * 0.48),
      linePaint,
    );

    const dashAngle = 0.15;
    const gapAngle = 0.10;
    var angle = math.pi * 0.22;
    while (angle < math.pi * 0.78) {
      canvas.drawArc(
        Rect.fromCircle(center: arcCenter, radius: freeThrowRadius),
        angle,
        dashAngle,
        false,
        dashedPaint,
      );
      angle += dashAngle + gapAngle;
    }

    canvas.drawLine(
      Offset(centerX - size.width * 0.035, size.height * 0.53),
      Offset(centerX + size.width * 0.035, size.height * 0.53),
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.98),
        width: size.width * 1.05,
        height: size.height * 0.24,
      ),
      math.pi,
      math.pi,
      false,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
