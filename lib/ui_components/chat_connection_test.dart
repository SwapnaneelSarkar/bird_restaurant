import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/screens/chat/bloc.dart';
import '../presentation/screens/chat/state.dart';

class ChatConnectionTest extends StatefulWidget {
  const ChatConnectionTest({Key? key}) : super(key: key);

  @override
  State<ChatConnectionTest> createState() => _ChatConnectionTestState();
}

class _ChatConnectionTestState extends State<ChatConnectionTest> {
  Map<String, dynamic>? _connectionHealth;
  bool _isChecking = false;

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
                      color: _getConnectionColor(state),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chat Connection Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (_isChecking)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Connection Status
                _buildStatusRow('Socket Connected', state is ChatLoaded),
                _buildStatusRow('API Reachable', _connectionHealth?['api']?['reachable'] ?? false),
                _buildStatusRow('Token Available', _connectionHealth?['api']?['tokenAvailable'] ?? false),
                _buildStatusRow('User ID Available', _connectionHealth?['api']?['userIdAvailable'] ?? false),
                
                if (_connectionHealth != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Details:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _connectionHealth.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isChecking ? null : _checkConnection,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Check Connection'),
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
                        icon: const Icon(Icons.replay, size: 16),
                        label: const Text('Reconnect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
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

  Color _getConnectionColor(ChatState state) {
    if (state is ChatLoaded) {
      return Colors.green;
    } else if (state is ChatError) {
      return Colors.red;
    } else if (state is ChatLoading) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final health = await context.read<ChatBloc>().checkConnectionHealth();
      setState(() {
        _connectionHealth = health;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking connection: $e')),
      );
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _forceReconnect() async {
    try {
      await context.read<ChatBloc>().forceReconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconnection initiated')),
      );
      // Check connection after reconnect
      await _checkConnection();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reconnection failed: $e')),
      );
    }
  }
} 