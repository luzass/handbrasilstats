import 'package:flutter/material.dart';

class GoalZoneSelector extends StatelessWidget {
  static const double _boardAspectRatio = 1.32;

  final int? selectedGoalZoneId;
  final ValueChanged<int> onSelected;
  final bool enabled;

  const GoalZoneSelector({
    super.key,
    required this.selectedGoalZoneId,
    required this.onSelected,
    this.enabled = true,
  });

  static const List<List<int>> _rows = [
    [1, 4, 7],
    [2, 5, 8],
    [3, 6, 9],
  ];

  Widget _cell(int goalZoneId, double fontSize) {
    final isSelected = selectedGoalZoneId == goalZoneId;

    return GestureDetector(
      onTap: enabled ? () => onSelected(goalZoneId) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD33D).withValues(alpha: 0.82)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72), width: 0.8),
        ),
        alignment: Alignment.center,
        child: Text(
          'G${goalZoneId.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: isSelected ? const Color(0xFF07152D) : Colors.white,
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _boardAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fontSize = (constraints.maxWidth * 0.035).clamp(10.0, 14.0).toDouble();
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
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GoalFramePainter(),
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
                                        child: _cell(goalZoneId, fontSize),
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
            ),
          );
        },
      ),
    );
  }
}

class _GoalFramePainter extends CustomPainter {
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
      ..color = Colors.white
      ..strokeWidth = size.width * 0.024
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final redPaint = Paint()
      ..color = const Color(0xFFFF584D)
      ..strokeWidth = size.width * 0.024
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..strokeWidth = size.width * 0.003
      ..style = PaintingStyle.stroke;

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

    for (var i = 1; i < 10; i++) {
      final x = left + ((right - left) * i / 10);
      canvas.drawLine(Offset(x, top), Offset(x, bottom), netPaint);
    }
    for (var i = 1; i < 5; i++) {
      final y = top + ((bottom - top) * i / 5);
      canvas.drawLine(Offset(left, y), Offset(right, y), netPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
