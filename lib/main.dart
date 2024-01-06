import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'communicator/def.dart';
import 'communicator/sender.dart';
import 'utils/logger.dart';

void main() {
    runApp(const MaterialApp(
            title: '软定义手写板', 
            home: SafeArea(child: CanvasPage()),
            debugShowCheckedModeBanner: false,
        ),
    );
}

class CanvasPage extends StatefulWidget {
    const CanvasPage({Key? key}) : super(key: key);

    @override
    State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
    Path path = Path();
    String _address = '192.168.1.12'; 
    int _port = 8080; 
    PositionSender? sender;
    bool isIconConnected = false;
    bool mouseMode = false;

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
            appBar: AppBar(
                title: const Text('软定义手写板'),
                backgroundColor: const Color.fromARGB(255, 67, 232, 171),
                actions: [
                    IconButton(onPressed: () {
                        logger.i("click");
                        path.reset();
                        setState(() {
                            mouseMode = !mouseMode;
                        });
                    }, icon: mouseMode ? const Icon(Icons.mouse) : const Icon(Icons.brush)),
                    IconButton(onPressed: () {
                        logger.i("click");
                        path.reset();
                        setState(() {});
                    }, 
                    icon: const Icon(Icons.clear)),
                    IconButton(onPressed: () {
                        logger.i("click");
                        _showConfigurationDialog(context);
                    }, 
                    icon: const Icon(Icons.settings_sharp)),
                    IconButton(onPressed: () async {
                        logger.i("click");
                        if (sender != null) {
                            logger.i("already connected");
                            await sender!.disconnect();
                            sender = null;
                            setState(() {
                                // 切换图标的显示状态
                                isIconConnected = !isIconConnected;
                            });
                            return;
                        }
                        logger.i("try to connect");
                        sender = PositionSender(_address, _port);
                        setState(() {
                            // 切换图标的显示状态
                            isIconConnected = !isIconConnected;
                        });
                    }, icon: isIconConnected ? const Icon(Icons.pause) : const Icon(Icons.play_arrow)),
                ],
            ),
            body: Listener(
                // 落下
                onPointerDown: (e) {
                    if (!mouseMode) {
                        path.moveTo(e.localPosition.dx, e.localPosition.dy);
                    }
                    // logger.d('mvTo $e.localPosition.dx, $e.localPosition.dy');
                    // sendDraw(e.localPosition.dx, e.localPosition.dy, false);
                    if (sender != null) {
                        sender!.addToSender(Position(e.localPosition.dx.truncate(), e.localPosition.dy.truncate(), false));
                    }
                    setState(() {});
                },
                // 移动
                onPointerMove: (e) {
                    // logger.d('lineTo $e.localPosition.dx, $e.localPosition.dy');
                    if (!mouseMode) {
                        path.lineTo(e.localPosition.dx, e.localPosition.dy);
                    }
                    // sendDraw(e.localPosition.dx, e.localPosition.dy, true);
                    if (sender != null) {
                        sender!.addToSender(Position(e.localPosition.dx.truncate(), e.localPosition.dy.truncate(), !mouseMode));
                    }
                    setState(() {});
                },
                // 离开
                onPointerUp: (e) {
                    if (!mouseMode) {
                        path.moveTo(e.localPosition.dx, e.localPosition.dy);
                        path.close();
                    }
                    if (sender != null) {
                        sender!.addToSender(Position(e.localPosition.dx.truncate(), e.localPosition.dy.truncate(), false));
                    }
                    setState(() {});
                },
                child: CustomPaint(
                    foregroundPainter: CanvasPaint(path: path), 
                    child: Container(color: Colors.transparent)
                )
            ),
        );
    }

    Future<void> _showConfigurationDialog(BuildContext context) async {
        String tmpAddress = '';
        String tmpPort = '0';
        tmpAddress = _address;
        tmpPort = _port.toString();
        await showDialog(
            context: context,
            builder: (BuildContext context) {
            return AlertDialog(
                title: const Text('连接配置'),
                content: Column(
                    children: [
                        TextField(
                            onChanged: (value) {
                                tmpAddress = value;
                            },
                            decoration: InputDecoration(
                                labelText: "现配置:$tmpAddress",
                            ),
                        ),
                        TextField(
                            onChanged: (value) {
                                tmpPort = value;
                            },
                            decoration: InputDecoration(
                                labelText: "现配置:$tmpPort",
                            ),
                        ),
                        TextField(
                            onChanged: (value) {
                                // tmpPort = value;
                            },
                            decoration: const InputDecoration(
                                labelText: "放大倍数现配置: 1",
                            ),
                        ),
                    ]
                ),
                actions: [
                    TextButton(
                        onPressed: () {
                            Navigator.pop(context); // 关闭弹窗
                        },
                        child: const Text('取消'),
                    ),
                    TextButton(
                        onPressed: () {
                            // 在这里保存用户输入的配置，你可以将 _address 存储到适当的地方
                            logger.i('User entered: $tmpAddress');
                            _address = tmpAddress;
                            _port = int.tryParse(tmpPort)!;
                            Navigator.pop(context); // 关闭弹窗
                        },
                        child: const Text('保存'),
                    ),
                ],
            );
            },
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