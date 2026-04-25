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
                            const SizedBox(height: 4),
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
                  '1. Information We Collect',
                  'We collect the following types of information:\n\n'
                      '• Location Data: GPS coordinates for real-time safety tracking\n'
                      '• Device Information: Device type, operating system, unique device identifiers\n'
                      '• Usage Data: How you interact with our app and features\n'
                      '• Contact Information: Name, email, phone number when provided\n'
                      '• Emergency Contacts: Contact details you add for emergency situations',
                ),

                _buildSection(
                  '2. How We Use Your Information',
                  'We use your information to:\n\n'
                      '• Provide Safety Services: Real-time location tracking and safety scoring\n'
                      '• Emergency Response: Contact emergency services and your designated contacts\n'
                      '• Improve Services: Analyze usage patterns to enhance app functionality\n'
                      '• Communicate: Send safety alerts and important notifications\n'
                      '• Support: Respond to your inquiries and provide technical support',
                ),

                _buildSection(
                  '3. Data Sharing and Disclosure',
                  'We may share your information in the following circumstances:\n\n'
                      '• Emergency Services: With your consent during emergency situations\n'
                      '• Law Enforcement: When required by law or to protect user safety\n'
                      '• Service Providers: With trusted third-party providers for app functionality\n'
                      '• Aggregated Data: Anonymized data for research and improvement\n\n'
                      'We never sell your personal information to third parties.',
                ),

                _buildSection(
                  '4. Data Security',
                  'We implement industry-standard security measures:\n\n'
                      '• Encryption: All data is encrypted in transit and at rest\n'
                      '• Access Controls: Strict authentication and authorization systems\n'
                      '• Regular Audits: Periodic security assessments and updates\n'
                      '• Data Minimization: We collect only necessary information\n'
                      '• Secure Storage: Your data is stored in secure, redundant facilities',
                ),

                _buildSection(
                  '5. Your Privacy Rights',
                  'You have the following rights regarding your data:\n\n'
                      '• Access: Request a copy of your personal information\n'
                      '• Correction: Update or correct inaccurate information\n'
                      '• Deletion: Request removal of your personal data\n'
                      '• Portability: Transfer your data to other services\n'
                      '• Opt-out: Disable certain data collection features',
                ),

                _buildSection(
                  '6. Location Data and Privacy',
                  'SafeMap uses location data for safety purposes:\n\n'
                      '• Precise Location: Required for accurate safety scoring and emergency response\n'
                      '• Background Location: Only when safety features are active\n'
                      '• Location History: Stored for safety analysis and route optimization\n'
                      '• Anonymous Mode: Option to use app without precise location tracking\n\n'
                      'You can control location settings in your device preferences.',
                ),

                _buildSection(
                  '7. Cookies and Tracking',
                  'We use minimal tracking technologies:\n\n'
                      '• Essential Cookies: Required for app functionality\n'
                      '• Analytics: Anonymous usage statistics to improve services\n'
                      '• No Third-Party Advertising: We do not use tracking for advertising\n'
                      '• Local Storage: Most data is stored locally on your device',
                ),

                _buildSection(
                  '8. Children\'s Privacy',
                  'SafeMap is not intended for children under 13:\n\n'
                      '• We do not knowingly collect information from children\n'
                      '• Parents can request removal of their child\'s data\n'
                      '• Additional verification may be required for minor accounts\n'
                      '• Educational content about online safety is available',
                ),

                _buildSection(
                  '9. International Data Transfers',
                  'Your data may be transferred internationally:\n\n'
                      '• Global Infrastructure: Servers located in multiple countries\n'
                      '• Adequate Protection: All transfers maintain privacy standards\n'
                      '• Legal Compliance: Follow applicable data protection laws\n'
                      '• Your Consent: Continued use constitutes agreement to transfers',
                ),

                _buildSection(
                  '10. Policy Updates',
                  'We may update this privacy policy:\n\n'
                      '• Notification: Users will be informed of significant changes\n'
                      '• Effective Date: Changes take effect upon posting\n'
                      '• Continued Use: Ongoing use indicates acceptance\n'
                      '• Review Period: 30 days to review major changes',
                ),

                _buildSection(
                  '11. Contact Us',
                  'For privacy-related questions or concerns:\n\n'
                      '• Email: privacy@safemap.com\n'
                      '• Phone: +92-300-1234567\n'
                      '• Address: SafeMap Inc., Privacy Department, Karachi, Pakistan\n'
                      '• Response Time: We respond within 48 hours',
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

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
