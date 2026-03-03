// TODO Implement this library.
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: AchievementsScreen()));

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
  });
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data
    final List<Achievement> achievements = [
      Achievement(
        title: 'First Win',
        description: 'Complete your first match',
        icon: Icons.emoji_events,
        isUnlocked: true,
      ),
      Achievement(
        title: 'Collector',
        description: 'Collect 10 items',
        icon: Icons.cases,
        isUnlocked: true,
      ),
      Achievement(
        title: 'Pro Player',
        description: 'Reach level 50',
        icon: Icons.workspace_premium,
        isUnlocked: false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final item = achievements[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: item.isUnlocked ? Colors.amber : Colors.grey,
                child: Icon(item.icon, color: Colors.white),
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  fontWeight: item.isUnlocked
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: Text(item.description),
              trailing: item.isUnlocked
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.lock, color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}
