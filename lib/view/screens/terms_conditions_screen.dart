// terms_conditions_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:staysafe/view/widgets/app_bar.dart';
import '../../utils/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppMainBar(showBack: true),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColor.appSecondary.withValues(alpha: 0.1),
                        AppColor.appPrimary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColor.appSecondary.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.appSecondary.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.appSecondary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.appSecondary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.fileText,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'SafeMap Terms of Service',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Terms Content
                _buildSection(
                  context,
                  '1. Acceptance of Terms',
                  'By downloading, installing, or using SafeMap, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our application.',
                ),
                _buildSection(
                  context,
                  '2. Description of Service',
                  'SafeMap is a location-based safety application designed to enhance personal security through features like safe zone mapping, emergency alerts, and community safety reporting.',
                ),
                _buildSection(
                  context,
                  '3. User Responsibilities',
                  'Users are responsible for: Providing accurate information, maintaining account security, using the service lawfully, and respecting other users\' privacy and safety.',
                ),
                _buildSection(
                  context,
                  '4. Privacy and Data Protection',
                  'We are committed to protecting your privacy. Our collection, use, and storage of personal data comply with applicable privacy laws and our Privacy Policy.',
                ),
                _buildSection(
                  context,
                  '5. Emergency Services',
                  'SafeMap provides emergency assistance features, but users should not rely solely on this app for emergency situations. Always contact local emergency services when needed.',
                ),
                _buildSection(
                  context,
                  '6. Intellectual Property',
                  'All content, features, and functionality of SafeMap are owned by us and are protected by copyright, trademark, and other intellectual property laws.',
                ),
                _buildSection(
                  context,
                  '7. Limitation of Liability',
                  'SafeMap is provided "as is" without warranties. We are not liable for any damages arising from your use of the application, including but not limited to direct, indirect, or consequential damages.',
                ),
                _buildSection(
                  context,
                  '8. Service Modifications',
                  'We reserve the right to modify, suspend, or discontinue the service with or without notice. We will not be liable for any modifications, suspensions, or discontinuations.',
                ),
                _buildSection(
                  context,
                  '9. Termination',
                  'We may terminate or suspend your account and bar access to the service immediately, without prior notice or liability, if you breach the terms.',
                ),
                _buildSection(
                  context,
                  '10. Contact Information',
                  'For questions about these Terms and Conditions, please contact us at support@safemap.app',
                ),

                const SizedBox(height: 32),

                // Last Updated
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        color: AppColor.appSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Last Updated: January 15, 2025',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.getContainerBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColor.getContainerBorder(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColor.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColor.getTextSecondary(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
