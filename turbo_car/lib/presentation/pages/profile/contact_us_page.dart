/// Contact Us Page
/// Page displaying contact information
library;

import 'package:flutter/material.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/common/custom_app_bar.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: CustomAppBar(title: StringConstants.contactUsTitle),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Phone card
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: const Text(StringConstants.phoneNumber),
                subtitle: const Text(
                  '+1 234 567 8900',
                ), // TODO: Replace with actual number
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {
                    Helpers.launchPhone('+12345678900');
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Email card
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text(StringConstants.email),
                subtitle: const Text(
                  'support@turbocar.com',
                ), // TODO: Replace with actual email
                trailing: IconButton(
                  icon: const Icon(Icons.mail),
                  onPressed: () {
                    Helpers.launchEmail('support@turbocar.com');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
