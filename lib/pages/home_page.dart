import 'package:card_watch/services/notification_services.dart';
import '../widgets/random_cards.dart';
import 'package:flutter/material.dart';
import '../widgets/search_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CardWatch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SearchBarWidget(),
          SizedBox(height: 16),
          RandomCardsWidget(),
        ],
      ),
      floatingActionButton: Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      FloatingActionButton(
        onPressed: () => NotificationService.showNow(),
        tooltip: 'Open Notifications',
        child: const Icon(Icons.notifications_active),
      ),
      const SizedBox(height: 16),
      FloatingActionButton(
        onPressed: () => NotificationService.showDelayed(),
        tooltip: 'Notifica dopo 30s',
        child: const Icon(Icons.timer),
      ),
    ],
  ),
    );
  }
}
