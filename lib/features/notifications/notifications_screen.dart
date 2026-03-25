import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.items.isEmpty) {
            return const Center(child: Text('Aucune notification'));
          }
          return ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              return ListTile(
                leading: Icon(
                  item.isRead ? Icons.notifications_none : Icons.notifications_active,
                ),
                title: Text(item.title),
                subtitle: Text(
                  '${item.message}\n${DateFormat('dd/MM HH:mm').format(item.createdAt)}',
                ),
                isThreeLine: true,
                trailing: item.isRead
                    ? null
                    : TextButton(
                        onPressed: () => provider.markAsRead(item.id),
                        child: const Text('Marquer lu'),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
