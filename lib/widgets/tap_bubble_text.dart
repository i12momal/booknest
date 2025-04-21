import 'package:flutter/material.dart';

class TapBubbleText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const TapBubbleText({super.key, required this.text, this.style});

  @override
  State<TapBubbleText> createState() => _TapBubbleTextState();
}

class _TapBubbleTextState extends State<TapBubbleText> {
  final GlobalKey _textKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _showBubble() {
    final RenderBox renderBox = _textKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final leftPosition = offset.dx + size.width / 2 - 135;
    final topPosition = offset.dy;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        const bubbleWidth = 270.0;

        return Positioned(
          left: leftPosition,
          top: topPosition,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: CustomPaint(
                    size: const Size(20, 10),
                    painter: _TrianglePainter(),
                  ),
                ),
                Container(
                  width: bubbleWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.text,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 2), () => _removeBubble());
  }

  void _removeBubble() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showBubble,
      child: Text(
        widget.text,
        key: _textKey,
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black87;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
