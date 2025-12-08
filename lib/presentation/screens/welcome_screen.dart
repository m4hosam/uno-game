import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import 'home_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C1B1B), // Slightly lighter at top
              AppTheme.backgroundColor, // Dark at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Logo
                ZoomIn(
                  child: Image.asset(
                    'docs/cards-assets/uno_logo.png',
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: Colors.white,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 48),

                // Welcome Text
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    l10n.welcomeTitle,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    l10n.chooseLanguage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // English Button
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('en'));
                        ref.read(hasSeenWelcomeProvider.notifier).setSeen();
                        _navigateToHome(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.unoRed,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.english),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Arabic Button
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('ar'));
                        ref.read(hasSeenWelcomeProvider.notifier).setSeen();
                        _navigateToHome(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                            0xFF374151), // Dark Grey for secondary option
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.arabic),
                    ),
                  ),
                ),

                const Spacer(),

                // Footer
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Text(
                    l10n.languageSaved,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
