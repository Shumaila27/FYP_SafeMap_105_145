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
                    border: Border.all(color: AppColor.appSecondary.withValues(alpha: 0.2)),
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
                              color: AppColor.appSecondary.withValues(alpha: 0.3),
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
                            const SizedBox(height: 4),
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
                  '1. Acceptance of Terms',
                  'By downloading, installing, or using SafeMap, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our application.',
                ),
                
                _buildSection(
                  '2. Description of Service',
                  'SafeMap is a mobile safety application designed to help users navigate safely, report incidents, and access emergency services. The service includes real-time location tracking, safety scoring, and community reporting features.',
                ),
                
                _buildSection(
                  '3. User Responsibilities',
                  'Users are responsible for:\n• Providing accurate information\n• Using the service for lawful purposes only\n• Respecting other users\' privacy\n• Not sharing false or misleading information\n• Maintaining the security of their account',
                ),
                
                _buildSection(
                  '4. Privacy and Data Protection',
                  'We are committed to protecting your privacy. Our collection, use, and sharing of data are governed by our Privacy Policy. By using SafeMap, you consent to the collection and use of information in accordance with our policy.',
                ),
                
                _buildSection(
                  '5. Prohibited Activities',
                  'Users may not:\n• Use the service for illegal activities\n• Harass, abuse, or harm other users\n• Attempt to gain unauthorized access\n• Interfere with or disrupt the service\n• Share inappropriate or offensive content',
                ),
                
                _buildSection(
                  '6. Intellectual Property',
                  'SafeMap and its original content, features, and functionality are owned by SafeMap Inc. and are protected by international copyright, trademark, and other intellectual property laws.',
                ),
                
                _buildSection(
                  '7. Limitation of Liability',
                  'SafeMap is provided "as is" without warranties of any kind. We are not liable for any damages arising from your use of the service, including but not limited to direct, indirect, incidental, or consequential damages.',
                ),
                
                _buildSection(
                  '8. Termination',
                  'We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including if you breach the Terms.',
                ),
                
                _buildSection(
                  '9. Changes to Terms',
                  'We reserve the right to modify these terms at any time. Changes will be effective immediately upon posting. Your continued use of the service constitutes acceptance of any changes.',
                ),
                
                _buildSection(
                  '10. Contact Information',
                  'If you have any questions about these Terms and Conditions, please contact us at:\nEmail: legal@safemap.com\nPhone: +92-300-1234567',
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
