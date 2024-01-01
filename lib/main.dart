import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(title: '画板', home: SafeArea(child: CanvasPage())));
}

class CanvasPage extends StatefulWidget {
  const CanvasPage({Key? key}) : super(key: key);

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  Path path = Path();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('画板')),
      body: Listener(
          // 落下
          onPointerDown: (e) {
            path.moveTo(e.localPosition.dx, e.localPosition.dy);
            print('mvTo $e.localPosition.dx, $e.localPosition.dy');
            setState(() {});
          },
          // 移动
          onPointerMove: (e) {
            print('lineTo $e.localPosition.dx, $e.localPosition.dy');
            path.lineTo(e.localPosition.dx, e.localPosition.dy);
            setState(() {});
          },
          // 离开
          onPointerUp: (e) {
            path.moveTo(e.localPosition.dx, e.localPosition.dy);
            path.close();
            setState(() {});
          },
          child: CustomPaint(foregroundPainter: CanvasPaint(path: path), child: Container(color: Colors.transparent))),
    );
  }
}

class CanvasPaint extends CustomPainter {
  Path? path;
  Color? color; // 画笔颜色
  double? width;

  CanvasPaint({required this.path, this.color = Colors.black, this.width = 5});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color!
      ..strokeWidth = width!
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path!, paint);
  }

  // 是否需要重新绘制
  @override
  bool shouldRepaint(covariant CanvasPaint oldDelegate) {
    // return oldDelegate.path != path;
    return true;
  }
}