class SimpleLock {
    bool _isLocked = false;

    Future<void> lock() async {
        while (_isLocked) {
            await Future.delayed(const Duration(milliseconds: 10));
        }
        _isLocked = true;
    }

    void unlock() {
        _isLocked = false;
    }
}