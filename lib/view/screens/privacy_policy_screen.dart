// privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:staysafe/view/widgets/app_bar.dart';
import '../../utils/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                          LucideIcons.lock,
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
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'How SafeMap Protects Your Data',
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

                // Privacy Content
                _buildSection(
                  context,
                  '1. Information We Collect',
                  'We collect the following types of information:\n\n'
                      '• Location Data: GPS coordinates for real-time safety tracking\n'
                      '• Device Information: Device type, operating system, unique device identifiers\n'
                      '• Usage Data: How you interact with our app and features\n'
                      '• Contact Information: Name, email, phone number when provided\n'
                      '• Emergency Contacts: Contact details you add for emergency situations',
                ),
                _buildSection(
                  context,
                  '2. How We Use Your Information',
                  'Your information is used to provide and improve our services, ensure safety features work properly, communicate with you, and comply with legal obligations.',
                ),
                _buildSection(
                  context,
                  '3. Data Security',
                  'We implement industry-standard security measures:\n\n'
                      '• Encryption: All data is encrypted in transit and at rest\n'
                      '• Access Controls: Strict authentication and authorization systems\n',
                ),
                _buildSection(
                  context,
                  '4. Data Sharing and Disclosure',
                  'We may share your information in the following circumstances:\n\n'
                      '• Emergency Services: With your consent during emergency situations\n'
                      '• Law Enforcement: When required by law or to protect user safety\n'
                      '• Service Providers: With trusted third-party providers for app functionality\n'
                      '• Aggregated Data: Anonymized data for research and improvement\n\n'
                      'We never sell your personal information to third parties.',
                ),
                _buildSection(
                  context,
                  '5. Data Sharing',
                  'We do not sell your personal information. We only share data when required by law, with emergency services during active emergencies, or with service providers who assist in our operations.',
                ),
                _buildSection(
                  context,
                  '6. Your Rights',
                  'You have the right to access, update, or delete your personal information. You can also control data sharing preferences and request data export.',
                ),
                _buildSection(
                  context,
                  '7. Cookies and Tracking',
                  'We use minimal cookies and tracking technologies essential for app functionality and security. Third-party analytics are used with anonymized data.',
                ),
                _buildSection(
                  context,
                  '8. Children\'s Privacy',
                  'SafeMap is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
                ),
                _buildSection(
                  context,
                  '9. International Data Transfers',
                  'Your data may be transferred to and processed in countries other than your own, where we have service providers and infrastructure.',
                ),
                _buildSection(
                  context,
                  '10. Changes to This Policy',
                  'We may update this privacy policy occasionally. We will notify you of significant changes by email or through the app.',
                ),
                _buildSection(
                  context,
                  '11. Contact Us',
                  'For privacy-related questions or concerns, please contact our privacy officer at privacy@safemap.app',
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
