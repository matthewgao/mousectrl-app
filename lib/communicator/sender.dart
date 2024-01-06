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

    PositionSender(String addr, int port) {
        // _timer = Timer.periodic(const Duration(milliseconds: 10), (Timer t) => _checkQueue());
        // _client = TcpClient('30.75.128.137', 8080);
        _client = TcpClient(addr, port, maxRetries: 5);
        _client.connect();
    }

    void addToSender(Position item) {
        
        int xTmp = item.x;
        int yTmp = item.y;
        if(xTmp == _x && yTmp == _y) {
            return;
        }

        // _queue.add(item);
        _client.sendPosAndFlush(item.x, item.y, item.isDrag ? 1: 0);

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

            _client.sendPos(element.x, element.y, element.isDrag ? 1: 0);
            if (count > 40) {
                // sendDraw(jsonArray);
                _client.flush();
                jsonArray = [];
                count = 0;
            }
        }

        if (jsonArray.isNotEmpty) {
            _client.flush();
            // sendDraw(jsonArray);
            // jsonArray = [];
        }
    }

    Future<void> disconnect() async {
        try {
            await _client.closeConnection();
        } on Exception catch (e) {
            logger.e('disconnect Exception: $e');
        }
    }

    void stop() {
        _timer.cancel();
    }
}