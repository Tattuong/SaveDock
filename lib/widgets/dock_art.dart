import 'package:flutter/material.dart';

class ChairArt extends StatelessWidget {
  const ChairArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFF2F6BFF)),
      child: CustomPaint(painter: _ChairPainter(), child: SizedBox.expand()),
    );
  }
}

class _ChairPainter extends CustomPainter {
  const _ChairPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1D4ED8);
    final seat = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.34, size.width * 0.64, size.height * 0.42),
      const Radius.circular(28),
    );
    canvas.drawRRect(seat, paint);
    final back = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, size.height * 0.16, size.width * 0.28, size.height * 0.46),
      const Radius.circular(22),
    );
    canvas.drawRRect(back, Paint()..color = const Color(0xFF3B82F6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FieldArt extends StatelessWidget {
  const FieldArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE24B2A),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FIELD\nNOTES',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w900,
                fontSize: 22,
                height: 0.9,
              ),
            ),
            Expanded(child: _RidgeSlot()),
          ],
        ),
      ),
    );
  }
}

class _RidgeSlot extends StatelessWidget {
  const _RidgeSlot();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight.clamp(0.0, 36.0);
          return CustomPaint(
            painter: const _RidgePainter(),
            child: SizedBox(height: height, width: double.infinity),
          );
        },
      ),
    );
  }
}

class _RidgePainter extends CustomPainter {
  const _RidgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.35, size.height * 0.25)
      ..lineTo(size.width * 0.55, size.height * 0.7)
      ..lineTo(size.width * 0.78, size.height * 0.15)
      ..lineTo(size.width, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShoeMark extends StatelessWidget {
  const ShoeMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5A36),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const SizedBox(width: 36, height: 18, child: CustomPaint(painter: _ShoePainter())),
    );
  }
}

class _ShoePainter extends CustomPainter {
  const _ShoePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFE8C2);
    final path = Path()
      ..moveTo(2, 12)
      ..quadraticBezierTo(8, 2, 18, 4)
      ..quadraticBezierTo(30, 6, 34, 12)
      ..lineTo(2, 12);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
