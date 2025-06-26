import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/screens/chat/bloc.dart';
import '../presentation/screens/chat/state.dart';

class SocketTestWidget extends StatefulWidget {
  const SocketTestWidget({Key? key}) : super(key: key);

  @override
  State<SocketTestWidget> createState() => _SocketTestWidgetState();
}

class _SocketTestWidgetState extends State<SocketTestWidget> {
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wifi,
                      color: _getSocketColor(state),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Socket Connection Test',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (_isTesting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Socket Status
                _buildStatusRow('Socket Connected', state is ChatLoaded),
                _buildStatusRow('Connection State', state.runtimeType.toString().contains('Loaded')),
                
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTesting ? null : _testSocketConnection,
                        icon: const Icon(Icons.wifi, size: 16),
                        label: const Text('Test Socket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _forceReconnect,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reconnect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (state is ChatError) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Error: ${state.message}',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String label, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.error,
            color: isConnected ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSocketColor(ChatState state) {
    if (state is ChatLoaded) {
      return Colors.green;
    } else if (state is ChatError) {
      return Colors.red;
    } else if (state is ChatLoading) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  Future<void> _testSocketConnection() async {
    setState(() {
      _isTesting = true;
    });

    try {
      final health = await context.read<ChatBloc>().checkConnectionHealth();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Socket Health: ${health['socket']['connected']}'),
          backgroundColor: health['socket']['connected'] ? Colors.green : Colors.red,
        ),
      );
      
      debugPrint('Socket health check: $health');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _forceReconnect() async {
    try {
      await context.read<ChatBloc>().forceReconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reconnection initiated'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reconnection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 