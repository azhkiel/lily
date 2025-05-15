import 'package:flutter/material.dart';
import 'package:mentaly/theme/app_theme.dart';

class Mood {
  final String emoji;
  final String label;

  Mood({required this.emoji, required this.label});
}

class MoodSelector extends StatelessWidget {
  final Function(Mood)? onSelect;

  const MoodSelector({super.key, this.onSelect});

  static final List<Mood> moods = [
    Mood(emoji: "😊", label: "Happy"),
    Mood(emoji: "😐", label: "Neutral"),
    Mood(emoji: "😔", label: "Sad"),
    Mood(emoji: "😡", label: "Angry"),
    Mood(emoji: "😰", label: "Anxious"),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          moods.map((mood) {
            return GestureDetector(
              onTap: () {
                if (onSelect != null) {
                  onSelect!(mood);
                }
              },
              child: Column(
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    mood.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
