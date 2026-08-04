import 'dart:math' as math;

import 'package:flutter/material.dart';

class ShotZoneSelector extends StatelessWidget {
  static const double _boardAspectRatio = 1.32;

  final int? selectedZoneId;
  final ValueChanged<int> onSelected;
  final bool enabled;

  const ShotZoneSelector({
    super.key,
    required this.selectedZoneId,
    required this.onSelected,
    this.enabled = true,
  });

  static const Map<int, Offset> _zoneAnchors = {
    1: Offset(0.10, 0.23),
    5: Offset(0.90, 0.23),
    10: Offset(0.10, 0.40),
    6: Offset(0.90, 0.40),
    2: Offset(0.28, 0.54),
    3: Offset(0.50, 0.54),
    4: Offset(0.72, 0.54),
    9: Offset(0.12, 0.80),
    8: Offset(0.50, 0.80),
    7: Offset(0.88, 0.80),
  };

  static const Offset _sevenMeterAnchor = Offset(0.50, 0.23);

  Widget _buildZoneMarker(
    int zoneId,
    Offset anchor,
    double width,
    double height,
  ) {
    final isSelected = selectedZoneId == zoneId;
    final markerWidth = (width * 0.15).clamp(42.0, 68.0).toDouble();
    final markerHeight = (height * 0.14).clamp(28.0, 40.0).toDouble();
    final fontSize = (markerHeight * 0.34).clamp(10.0, 13.0).toDouble();

    return Positioned(
      left: (width * anchor.dx) - (markerWidth / 2),
      top: (height * anchor.dy) - (markerHeight / 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? () => onSelected(zoneId) : null,
          child: Container(
            width: markerWidth,
            height: markerHeight,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFD33D) : const Color(0xF20B1933),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFFFFE76A) : Colors.white.withValues(alpha: 0.7),
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
            alignment: Alignment.center,
            child: Text(
              'Z${zoneId.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isSelected ? const Color(0xFF07152D) : Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSevenMeterMarker(double width, double height) {
    final isSelected = selectedZoneId == 11;
    final markerWidth = (width * 0.12).clamp(38.0, 56.0).toDouble();
    final markerHeight = (height * 0.13).clamp(26.0, 36.0).toDouble();
    final fontSize = (markerHeight * 0.34).clamp(10.0, 12.0).toDouble();

    return Positioned(
      left: (width * _sevenMeterAnchor.dx) - (markerWidth / 2),
      top: (height * _sevenMeterAnchor.dy) - (markerHeight / 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: enabled ? () => onSelected(11) : null,
          child: Container(
            width: markerWidth,
            height: markerHeight,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFD33D) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? const Color(0xFFFFE76A) : Colors.white,
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
            alignment: Alignment.center,
            child: Text(
              '7M',
              style: TextStyle(
                color: const Color(0xFF07152D),
                fontWeight: FontWeight.w900,
                fontSize: fontSize,
              ),
            ),
          ),
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
                    Color(0xFF0A1B38),
                    Color(0xFF071124),
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
                      painter: _ShotCourtPainter(),
                    ),
                  ),
                  for (final entry in _zoneAnchors.entries)
                    _buildZoneMarker(entry.key, entry.value, width, height),
                  _buildSevenMeterMarker(width, height),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShotCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = size.width * 0.007
      ..style = PaintingStyle.stroke;

    final dashedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = size.width * 0.005
      ..style = PaintingStyle.stroke;

    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..strokeWidth = size.width * 0.003
      ..style = PaintingStyle.stroke;

    final goalWhitePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.018
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final goalRedPaint = Paint()
      ..color = const Color(0xFFFF584D)
      ..strokeWidth = size.width * 0.018
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final areaFillPaint = Paint()
      ..color = const Color(0xFF1956B6).withValues(alpha: 0.86)
      ..style = PaintingStyle.fill;

    final top = size.height * 0.04;
    final centerX = size.width / 2;

    final goalLeft = size.width * 0.20;
    final goalRight = size.width * 0.80;
    final goalTop = size.height * 0.07;
    final goalBottom = size.height * 0.28;

    for (var i = 1; i < 9; i++) {
      final x = goalLeft + ((goalRight - goalLeft) * i / 9);
      canvas.drawLine(Offset(x, goalTop), Offset(x, goalBottom), netPaint);
    }
    for (var i = 1; i < 4; i++) {
      final y = goalTop + ((goalBottom - goalTop) * i / 4);
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
      Offset(size.width * 0.04, goalBottom),
      Offset(size.width * 0.96, goalBottom),
      linePaint,
    );

    final goalAreaRadius = size.width * 0.34;
    final freeThrowRadius = size.width * 0.49;
    final arcCenter = Offset(centerX, top);

    final areaPath = Path()
      ..moveTo(size.width * 0.06, goalBottom)
      ..lineTo(size.width * 0.20, goalBottom)
      ..arcTo(
        Rect.fromCircle(center: arcCenter, radius: goalAreaRadius),
        math.pi * 0.20,
        math.pi * 0.60,
        false,
      )
      ..lineTo(size.width * 0.94, goalBottom)
      ..lineTo(size.width * 0.06, goalBottom)
      ..close();
    canvas.drawPath(areaPath, areaFillPaint);

    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: goalAreaRadius),
      0,
      math.pi,
      false,
      linePaint,
    );

    const dashAngle = 0.16;
    const gapAngle = 0.09;
    var angle = math.pi;
    while (angle < math.pi * 2) {
      canvas.drawArc(
        Rect.fromCircle(center: arcCenter, radius: freeThrowRadius),
        angle - math.pi,
        dashAngle,
        false,
        dashedPaint,
      );
      angle += dashAngle + gapAngle;
    }

    canvas.drawLine(
      Offset(centerX - size.width * 0.028, size.height * 0.32),
      Offset(centerX + size.width * 0.028, size.height * 0.32),
      linePaint,
    );
    canvas.drawLine(
      Offset(centerX - size.width * 0.022, size.height * 0.50),
      Offset(centerX + size.width * 0.022, size.height * 0.50),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
