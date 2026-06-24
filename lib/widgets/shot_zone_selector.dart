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

    return Positioned(
      left: (width * anchor.dx) - 34,
      top: (height * anchor.dy) - 20,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? () => onSelected(zoneId) : null,
          child: Container(
            width: 68,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEEF4FF) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF1565C0) : const Color(0xFF2A2A2A),
                width: isSelected ? 2 : 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Z${zoneId.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isSelected ? const Color(0xFF1565C0) : const Color(0xFF1A1A1A),
                fontSize: 13,
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

    return Positioned(
      left: (width * _sevenMeterAnchor.dx) - 28,
      top: (height * _sevenMeterAnchor.dy) - 18,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: enabled ? () => onSelected(11) : null,
          child: Container(
            width: 56,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF1E6) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? const Color(0xFFF57C00) : const Color(0xFF2A2A2A),
                width: isSelected ? 2 : 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '7M',
              style: TextStyle(
                color: isSelected ? const Color(0xFFF57C00) : const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w900,
                fontSize: 12,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
      ..color = Colors.black
      ..strokeWidth = size.width * 0.007
      ..style = PaintingStyle.stroke;

    final dashedPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = size.width * 0.005
      ..style = PaintingStyle.stroke;

    final top = size.height * 0.02;
    final centerX = size.width / 2;

    final goalAreaRadius = size.width * 0.37;
    final freeThrowRadius = size.width * 0.49;
    final arcCenter = Offset(centerX, top);

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
      Offset(centerX - size.width * 0.028, size.height * 0.31),
      Offset(centerX + size.width * 0.028, size.height * 0.31),
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
