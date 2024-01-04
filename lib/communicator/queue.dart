import 'dart:async';
import 'dart:collection';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class Position {
    final double x;
    final double y;
    final bool isDrag;
    Position(this.x, this.y, this.isDrag);
}

class SimpleLock {
  bool _isLocked = false;

  Future<void> lock() async {
    while (_isLocked) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    _isLocked = true;
  }

  void unlock() {
    _isLocked = false;
  }
}



class TcpClient {
    final String host;
    final int port;
    late Socket _socket;
    final int maxRetries;
    int _retries = 0;

    TcpClient(this.host, this.port, {this.maxRetries = 5});

    Future<void> connect() async {
        try {
            _socket = await Socket.connect(host, port);
            print('Connected to: ${_socket.remoteAddress.address}:${_socket.remotePort}');
            _socket.listen(
                (data) {
                    // 处理接收到的数据
                },
                onError: (error) {
                    print('Socket error: $error');
                    _socket.destroy();
                    _reconnect();
                },
                onDone: () {
                    print('Disconnected from server');
                    _socket.destroy();
                    _reconnect();
                },
            );
        } on SocketException catch (e) {
            print('SocketException: $e');
            _reconnect();
        }
    }

    void _reconnect() {
        if (_retries < maxRetries) {
            _retries++;
            print('Attempt to reconnect (${_retries}/$maxRetries)');
            Future.delayed(Duration(seconds: 2), () {
                connect();
            });
        } else {
            print('Max retries reached. Stop reconnecting.');
        }
    }

    Future<void> sendPos(int x, int y, int isDrag) async {
        // 将整数值转换为字节
        // 这里我们使用字节序为大端（network byte order）的方式
        var data = ByteData(4)..setInt32(0, x, Endian.big);
        List<int> bytes = data.buffer.asUint8List();
        _socket.add(bytes);

        data = ByteData(4)..setInt32(0, y, Endian.big);
        bytes = data.buffer.asUint8List();
        _socket.add(bytes);

        data = ByteData(4)..setInt32(0, isDrag, Endian.big);
        bytes = data.buffer.asUint8List();
        _socket.add(bytes);
        // 等待所有数据被发送
        await _socket.flush();

        // // 关闭连接
        // await _socket.close();
        // print('Disconnected');
    }

    // 发送数据的方法
    // 其他方法
}


class PositionQueue {
    final Queue<Position> _queue = Queue<Position>();
    late Timer _timer;
    late TcpClient _client;
    final lock = SimpleLock();

    PositionQueue() {
        _timer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) => _checkQueue());
        _client = TcpClient('192.168.1.16', 8080);
        _client.connect();
    }

    void addToQueue(Position item) {
        // _queue.add(item);
        _client.sendPos(item.x.truncate(), item.y.truncate(), item.isDrag ? 1: 0);
    }

    void _checkQueue() {
        int count = 0;
        var jsonArray = [];
        while (_queue.isNotEmpty) {
            count++;

            var element = _queue.removeFirst(); // 移除并获取队列的第一个元素
            // print("send element");
            jsonArray.add({
                'x': element.x,
                'y': element.y,
                'is_drag': element.isDrag,
            });

            if (count > 40) {
                sendDraw(jsonArray);
                jsonArray = [];
                count = 0;
            }
        }

        if (jsonArray.isNotEmpty) {
            sendDraw(jsonArray);
            // jsonArray = [];
        }
    }

    void stop() {
        _timer.cancel();
    }

    void sendDraw(List<dynamic> data) async  {
      await lock.lock();
      try {
            Dio dio = Dio();
            String jsonData = jsonEncode(data);
            Response resp = await dio.post("http://30.75.128.204:8000/moveMouse", data: jsonData);
      } finally {
        lock.unlock();
      }


    }
}