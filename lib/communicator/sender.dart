import 'dart:async';
import 'dart:collection';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../utils/logger.dart';
import 'def.dart';
import 'tcp.dart';

class PositionSender {
    final Queue<Position> _queue = Queue<Position>();
    late Timer _timer;
    late TcpClient _client;
    int _x = 0;
    int _y = 0;

    PositionSender() {
        _timer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) => _checkQueue());
        // _client = TcpClient('30.75.128.137', 8080);
        _client = TcpClient('192.168.1.16', 8080, maxRetries: 10);
        _client.connect();
    }

    void addToSender(Position item) {
        // _queue.add(item);
        int xTmp = item.x.truncate();
        int yTmp = item.y.truncate();
        if(xTmp == _x && yTmp == _y) {
            return;
        }
        _client.sendPos(xTmp, yTmp, item.isDrag ? 1: 0);
        _x = xTmp;
        _y = yTmp;
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
                // sendDraw(jsonArray);
                jsonArray = [];
                count = 0;
            }
        }

        if (jsonArray.isNotEmpty) {
            // sendDraw(jsonArray);
            // jsonArray = [];
        }
    }

    void stop() {
        _timer.cancel();
    }
}