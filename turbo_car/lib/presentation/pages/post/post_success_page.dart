/// Post Success Page
/// Shows success message after posting a car
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/custom_button.dart';
import '../../../core/router/route_names.dart';

class PostSuccessPage extends StatelessWidget {
  const PostSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, size: 80, color: Colors.green),
              ),
              const SizedBox(height: 32),

              // Success message
              Text(
                'Car Posted Successfully!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Your car listing has been successfully posted. It will be visible to potential buyings soon.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Go to Home button
              CustomButton(
                text: 'Go to Home',
                onPressed: () => context.go(RouteNames.home),
              ),
              const SizedBox(height: 16),

              // View My Cars button
              CustomButton.outline(
                text: 'View My Cars',
                onPressed: () => context.go(RouteNames.myCars),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
