/// Language Selector Modal
/// Modal for selecting app language
library;

import 'package:flutter/material.dart';

class LanguageSelectorModal extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageSelected;

  const LanguageSelectorModal({
    super.key,
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Get languages from constants
    final languages = ['English', 'Spanish', 'French', 'German'];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Language',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          for (final language in languages)
            RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  onLanguageSelected(value);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
    );
  }
}
