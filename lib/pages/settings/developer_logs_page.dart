// lib/pages/settings/developer_logs_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ⭐ 用于复制到剪贴板
import '../../services/storage_service.dart';

class DeveloperLogsPage extends StatefulWidget {
  const DeveloperLogsPage({super.key});

  @override
  State<DeveloperLogsPage> createState() => _DeveloperLogsPageState();
}

class _DeveloperLogsPageState extends State<DeveloperLogsPage> {
  final StorageService _storage = StorageService();
  List<String> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    final logs = await _storage.getDebugLogs();

    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('格式诊断'),
        backgroundColor: Colors.white,
        actions: [
          // ⭐ 复制按钮
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制全部日志',
            onPressed: () async {
              if (_logs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('日志为空')),
                );
                return;
              }
              
              final allLogs = _logs.join('\n');
              await Clipboard.setData(ClipboardData(text: allLogs));
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ 已复制到剪贴板'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          // 清空按钮
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空日志',
            onPressed: () async {
              await _storage.clearDebugLogs();
              await _loadLogs();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('日志已清空')),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Text(
                    '暂无日志记录\n\n开启开发者模式后进行对话即可记录',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  reverse: true, // 最新的在上面
                  itemBuilder: (context, index) {
                    final log = _logs[_logs.length - 1 - index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        log,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}