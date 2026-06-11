import 'dart:math';
import 'package:flutter/material.dart';

class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final String label;
  final Color lineColor;

  LineChartPainter({
    required this.dataPoints,
    required this.label,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paintLine = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw Grid Lines (horizontal)
    final gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final y = size.height * i / gridCount;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Min and Max calculation
    final minVal = dataPoints.reduce(min);
    final maxVal = dataPoints.reduce(max);
    final valRange = maxVal - minVal > 0 ? maxVal - minVal : 1.0;

    final double stepX = size.width / (dataPoints.length > 1 ? dataPoints.length - 1 : 1);

    final List<Offset> points = [];
    final path = Path();

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      // Normalizing between 0 and size.height (reversing y index since y=0 is top)
      final normalizedY = (dataPoints[i] - minVal) / valRange;
      final y = size.height - (normalizedY * (size.height - 20)) - 10;
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw filled gradient area below the line
    if (points.isNotEmpty) {
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();

      final paintFill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withOpacity(0.25),
            lineColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, paintFill);
    }

    // Draw main line
    canvas.drawPath(path, paintLine);

    // Draw glowing dots
    for (final point in points) {
      canvas.drawCircle(point, 5.0, paintDot);
      canvas.drawCircle(
        point,
        10.0,
        Paint()
          ..color = lineColor.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints || oldDelegate.lineColor != lineColor;
  }
}

class BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color barColor;

  BarChartPainter({
    required this.values,
    required this.labels,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paintBar = Paint()
      ..style = PaintingStyle.fill;

    final maxVal = values.reduce(max);
    final valRange = maxVal > 0 ? maxVal : 1.0;

    final double barGap = 20.0;
    final double totalGapsWidth = barGap * (values.length + 1);
    final double barWidth = (size.width - totalGapsWidth) / values.length;

    for (int i = 0; i < values.length; i++) {
      final double left = barGap + i * (barWidth + barGap);
      final double normalizedY = values[i] / valRange;
      final double top = size.height - (normalizedY * (size.height - 30)) - 15;
      final double right = left + barWidth;
      final double bottom = size.height;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        const Radius.circular(8),
      );

      paintBar.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          barColor,
          barColor.withOpacity(0.3),
        ],
      ).createShader(Rect.fromLTRB(left, top, right, bottom));

      canvas.drawRRect(rect, paintBar);

      // Simple text drawing fallback since standard Paragraph can be verbose
      final textPainterVal = TextPainter(
        text: TextSpan(
          text: values[i].toStringAsFixed(1),
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainterVal.paint(
        canvas,
        Offset(left + (barWidth - textPainterVal.width) / 2, top - 15),
      );

      final textPainterLabel = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.white60, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainterLabel.paint(
        canvas,
        Offset(left + (barWidth - textPainterLabel.width) / 2, bottom + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}

class AreaChartPainter extends CustomPainter {
  final List<Offset> points; // X = normalized key (e.g. prompt length), Y = latency (ms)
  final Color areaColor;

  AreaChartPainter({
    required this.points,
    required this.areaColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintLine = Paint()
      ..color = areaColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke;

    // Draw Grid background
    final grids = 5;
    for (int i = 0; i <= grids; i++) {
      final double x = size.width * i / grids;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
      final double y = size.height * i / grids;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final double maxX = points.map((p) => p.dx).reduce(max);
    final double minX = points.map((p) => p.dx).reduce(min);
    final double rangeX = maxX - minX > 0 ? maxX - minX : 1.0;

    final double maxY = points.map((p) => p.dy).reduce(max);
    final double minY = points.map((p) => p.dy).reduce(min);
    final double rangeY = maxY - minY > 0 ? maxY - minY : 1.0;

    // Sort by X value so we don't have overlapping drawing lines loops
    final sortedPoints = List<Offset>.from(points)
      ..sort((a, b) => a.dx.compareTo(b.dx));

    final path = Path();
    final List<Offset> screenPoints = [];

    for (int i = 0; i < sortedPoints.length; i++) {
      final p = sortedPoints[i];
      final double x = size.width * (p.dx - minX) / rangeX;
      final double normalizedY = (p.dy - minY) / rangeY;
      final double y = size.height - (normalizedY * (size.height - 20)) - 10;
      
      final screenOffset = Offset(x, y);
      screenPoints.add(screenOffset);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (screenPoints.isNotEmpty) {
      final fillPath = Path.from(path)
        ..lineTo(screenPoints.last.dx, size.height)
        ..lineTo(screenPoints.first.dx, size.height)
        ..close();

      final paintFill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            areaColor.withOpacity(0.3),
            areaColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, paintFill);
    }

    canvas.drawPath(path, paintLine);

    for (final sp in screenPoints) {
      canvas.drawCircle(sp, 3.5, Paint()..color = areaColor);
    }
  }

  @override
  bool shouldRepaint(covariant AreaChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.areaColor != areaColor;
  }
}

class DonutChartPainter extends CustomPainter {
  final double percentage; // 0.0 to 1.0
  final String centerLabel;
  final Color ringColor;

  DonutChartPainter({
    required this.percentage,
    required this.centerLabel,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = min(size.width, size.height) / 2.0;
    final center = Offset(size.width / 2, size.height / 2);

    final paintBackground = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0;

    final paintValue = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    paintValue.shader = SweepGradient(
      colors: [
        ringColor.withOpacity(0.5),
        ringColor,
        ringColor.withOpacity(0.5),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-pi / 2),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius - 7, paintBackground);

    // Draw Arc representing percentage
    final double sweepAngle = 2 * pi * percentage.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 7),
      -pi / 2, // starts at top
      sweepAngle,
      false,
      paintValue,
    );

    // Draw Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: centerLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.ringColor != ringColor;
  }
}
