import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../utils/logger.dart';

class TcpClient {
    final String host;
    final int port;
    Socket? _socket;
    final int maxRetries;
    int _retries = 0;

    TcpClient(this.host, this.port, {this.maxRetries = 5});

    Future<void> connect() async {
        try {
            logger.i("start to connect to ${host}:${port}");
            _socket = await Socket.connect(host, port);
            logger.i('Connected to: ${_socket!.remoteAddress.address}:${_socket!.remotePort}');
            _socket!.listen(
                (data) {
                    // 处理接收到的数据
                },
                onError: (error) {
                    logger.e('Socket error: $error');
                    _socket!.destroy();
                    _reconnect();
                },
                onDone: () {
                    logger.i('Disconnected from server');
                    _socket!.destroy();
                    _reconnect();
                },
            );
        } on SocketException catch (e) {
            logger.e('SocketException: $e');
            _reconnect();
        }
    }

    void _reconnect() {
        if (_retries < maxRetries) {
            _retries++;
            logger.i('Attempt to reconnect ($_retries/$maxRetries)');
            Future.delayed(const Duration(seconds: 2), () {
                connect();
            });
        } else {
            logger.w('Max retries reached. Stop reconnecting.');
        }
    }

    Future<void> sendPosAndFlush(int x, int y, int isDrag) async {
        if (_socket == null) {
            logger.w('Socket is not connected');
            return;
        }
        // 将整数值转换为字节
        // 这里我们使用字节序为大端（network byte order）的方式
        var data = ByteData(4)..setInt32(0, x, Endian.big);
        List<int> bytes = data.buffer.asUint8List();
        _socket!.add(bytes);

        data = ByteData(4)..setInt32(0, y, Endian.big);
        bytes = data.buffer.asUint8List();
        _socket!.add(bytes);

        data = ByteData(4)..setInt32(0, isDrag, Endian.big);
        bytes = data.buffer.asUint8List();
        _socket!.add(bytes);
        // 等待所有数据被发送
        await _socket!.flush();

        // // 关闭连接
        // await _socket.close();
        // print('Disconnected');
    }

    void sendPos(int x, int y, int isDrag) async {
        if (_socket == null) {
            logger.w('Socket is not connected');
            return;
        }
        // 将整数值转换为字节
        // 这里我们使用字节序为大端（network byte order）的方式
        var data = ByteData(4)..setInt32(0, x, Endian.big);
        List<int> bytes = data.buffer.asUint8List();
        _socket!.add(bytes);

        data = ByteData(4)..setInt32(0, y, Endian.big);
        bytes = data.buffer.asUint8List();
        _socket!.add(bytes);

        data = ByteData(4)..setInt32(0, isDrag, Endian.big);
        bytes = data.buffer.asUint8List();
        _socket!.add(bytes);
    }

    Future<void> flush() async {
        await _socket!.flush();
    }

    Future<void> closeConnection() async {
        if (_socket == null) {
            return;
        }
        try {
            await _socket!.close();
            _socket = null;
        } on Exception catch (e) {
            logger.e('closeConnection SocketException: $e');
        }
    }
    // 发送数据的方法
    // 其他方法
}