import 'package:flutter/material.dart';

class GoalZoneSelector extends StatelessWidget {
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

  Widget _cell(int goalZoneId) {
    final isSelected = selectedGoalZoneId == goalZoneId;

    return GestureDetector(
      onTap: enabled ? () => onSelected(goalZoneId) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE53935).withValues(alpha: 0.18) : Colors.transparent,
          border: Border.all(color: Colors.black.withValues(alpha: 0.22), width: 0.8),
        ),
        alignment: Alignment.center,
        child: Text(
          'G${goalZoneId.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
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
                                      child: _cell(goalZoneId),
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
