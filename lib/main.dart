import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'communicator/def.dart';
import 'communicator/sender.dart';
import 'utils/logger.dart';

void main() {
    runApp(const MaterialApp(title: '软定义手写板', home: SafeArea(child: CanvasPage())));
}

class CanvasPage extends StatefulWidget {
    const CanvasPage({Key? key}) : super(key: key);

    @override
    State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
    Path path = Path();
    PositionSender sender = PositionSender();

    // void sendDraw(double x, y, bool is_drag) async {
    //     Dio dio = new Dio();
    //     Response resp = await dio.post("http://192.168.1.12:8000/moveMouse", data: {
    //       'x': x,
    //       'y': y,
    //       'is_drag': is_drag,
    //     });
    // }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('软定义手写板')),
            body: Listener(
                // 落下
                onPointerDown: (e) {
                    path.moveTo(e.localPosition.dx, e.localPosition.dy);
                    // logger.d('mvTo $e.localPosition.dx, $e.localPosition.dy');
                    // sendDraw(e.localPosition.dx, e.localPosition.dy, false);
                    sender.addToSender(Position(e.localPosition.dx.truncate(), e.localPosition.dy.truncate(), false));
                    setState(() {});
                },
                // 移动
                onPointerMove: (e) {
                    // logger.d('lineTo $e.localPosition.dx, $e.localPosition.dy');
                    path.lineTo(e.localPosition.dx, e.localPosition.dy);
                    // sendDraw(e.localPosition.dx, e.localPosition.dy, true);
                    sender.addToSender(Position(e.localPosition.dx.truncate(), e.localPosition.dy.truncate(), true));
                    setState(() {});
                },
                // 离开
                onPointerUp: (e) {
                    path.moveTo(e.localPosition.dx, e.localPosition.dy);
                    path.close();
                    sender.addToSender(Position(e.localPosition.dx.truncate(), e.localPosition.dy.truncate(), false));
                    setState(() {});
                },
                child: CustomPaint(
                    foregroundPainter: CanvasPaint(path: path), 
                    child: Container(color: Colors.transparent)
                )
            ),
        );
    }
}

class CanvasPaint extends CustomPainter {
    Path? path;
    Color? color; // 画笔颜色
    double? width;

    CanvasPaint({required this.path, this.color = Colors.black, this.width = 3});

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