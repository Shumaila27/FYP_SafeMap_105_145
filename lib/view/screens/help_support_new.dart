import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  BoxDecoration _sectionDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: AppColor.getContainerBackground(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColor.getContainerBorder(context), width: 1),
    );
  }

  TextStyle _sectionTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColor.getTextPrimary(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColor.getPrimaryGradient(context),
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: AppColor.appSecondary.withValues(alpha: 0.3),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Help Section
            _buildEmergencySection(),
            const SizedBox(height: 20),

            // Quick Help Categories
            _buildQuickHelpSection(),
            const SizedBox(height: 20),

            // FAQ Section
            _buildFAQSection(),
            const SizedBox(height: 20),

            // Contact Support Section
            _buildContactSection(),
            const SizedBox(height: 20),

            // Safety Tips Section
            _buildSafetyTipsSection(),
            const SizedBox(height: 20),

            // Report Issue Section
            _buildReportIssueSection(),
            const SizedBox(height: 20),

            // Community Guidelines
            _buildCommunitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _sectionDecoration(context),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: [
              const Icon(Icons.emergency, color: Colors.red),
              const SizedBox(width: 8),
              Text('Emergency Help', style: _sectionTitleStyle(context)),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          // Emergency content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'If you\'re in immediate danger, call emergency services first.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showEmergencyDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Emergency Services',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showSOSDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'SOS Features',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelpSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _sectionDecoration(context),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: [
              const Icon(Icons.help_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Quick Help', style: _sectionTitleStyle(context)),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          // Quick Help content
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildHelpCard(
                icon: Icons.map,
                title: 'Using Maps',
                onTap: () => _showTutorial('maps'),
              ),
              _buildHelpCard(
                icon: Icons.people,
                title: 'Emergency Contacts',
                onTap: () => _showTutorial('contacts'),
              ),
              _buildHelpCard(
                icon: Icons.security,
                title: 'Safe Walk',
                onTap: () => _showTutorial('safewalk'),
              ),
              _buildHelpCard(
                icon: Icons.warning,
                title: 'Report Incident',
                onTap: () => _showTutorial('report'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue.shade600, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _sectionDecoration(context),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: [
              const Icon(Icons.quiz, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                'Frequently Asked Questions',
                style: _sectionTitleStyle(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          // FAQ content
          _buildFAQItem(
            'How do I add emergency contacts?',
            'Go to Profile > Emergency Contacts > Edit > Add new contact with name and phone number.',
          ),
          _buildFAQItem(
            'What is Safe Walk feature?',
            'Safe Walk allows you to share your location with trusted contacts while walking alone.',
          ),
          _buildFAQItem(
            'How do I report an incident?',
            'Tap Report button on map, select incident type, add details and submit.',
          ),
          _buildFAQItem(
            'Is my location data secure?',
            'Yes, your location is encrypted and only shared with your trusted contacts.',
          ),
          _buildFAQItem(
            'How do I enable SOS?',
            'Go to Settings > SOS > Enable and add emergency contacts.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _sectionDecoration(context),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: [
              Icon(Icons.support_agent, color: AppColor.appSecondary),
              const SizedBox(width: 8),
              Text('Contact Support', style: _sectionTitleStyle(context)),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          // Contact content
          _buildContactInfo(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@safemap.com',
            color: Colors.blue,
            iconColor: Colors.white,
            onTap: _sendEmail,
          ),
          _buildContactInfo(
            icon: Icons.phone_in_talk,
            title: 'Phone Support',
            subtitle: '+92 312 4195181',
            color: Colors.purple,
            iconColor: Colors.white,
            onTap: _makePhoneCall,
          ),
          _buildContactInfo(
            icon: Icons.message,
            title: 'WhatsApp Support',
            subtitle: '+92 312 4195181',
            color: Colors.green.shade600,
            iconColor: Colors.white,
            onTap: _openWhatsApp,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openLiveChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("Open Live Chat Demo"),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = Colors.blue,
    Color iconColor = Colors.white,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.open_in_new, size: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTipsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _sectionDecoration(context),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: [
              const Icon(Icons.security, color: Colors.green),
              const SizedBox(width: 8),
              Text('Safety Tips', style: _sectionTitleStyle(context)),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          // Safety Tips content
          _buildSafetyTip(
            'Always share your location when walking alone',
            Icons.location_on,
          ),
          _buildSafetyTip(
            'Keep emergency contacts updated regularly',
            Icons.people,
          ),
          _buildSafetyTip(
            'Test SOS features before you need them',
            Icons.security,
          ),
          _buildSafetyTip(
            'Trust your instincts - report suspicious activity',
            Icons.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 13,
                height: 1.3,
              ).copyWith(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportIssueSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _sectionDecoration(context),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Report an Issue', style: _sectionTitleStyle(context)),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          // Report Issue content
          Text(
            'Found a bug or have a suggestion? Let us know!',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showReportDialog(),
            icon: const Icon(Icons.bug_report, size: 18),
            label: const Text('Report Issue', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade500,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _sectionDecoration(context),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: [
              const Icon(Icons.gavel, color: Colors.indigo),
              const SizedBox(width: 8),
              Text('Community Guidelines', style: _sectionTitleStyle(context)),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          // Community Guidelines content
          Text(
            'Help us keep SafeMap safe for everyone by following our community guidelines.',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showGuidelines(),
            icon: const Icon(Icons.book, size: 18),
            label: const Text(
              'View Guidelines',
              style: TextStyle(fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog Methods
  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Services'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Icons.phone, color: Colors.red),
              title: Text('Police: 15'),
              subtitle: Text('For police emergencies'),
            ),
            const ListTile(
              leading: Icon(Icons.local_hospital, color: Colors.red),
              title: Text('Ambulance: 15'),
              subtitle: Text('For medical emergencies'),
            ),
            const ListTile(
              leading: Icon(Icons.local_fire_department, color: Colors.red),
              title: Text('Fire Department: 16'),
              subtitle: Text('For fire emergencies'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSOSDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Features'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SOS allows you to quickly alert your emergency contacts.'),
            SizedBox(height: 16),
            Text('Features:'),
            SizedBox(height: 8),
            Text('1. Quick tap to send location to contacts'),
            Text('2. Automatic alert if no response'),
            Text('3. Emergency services integration'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTutorial(String topic) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Tutorial for $topic coming soon!')));
  }

  void _openLiveChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chat, color: Colors.green.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Live Chat Support'),
          ],
        ),
        content: SizedBox(
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support Agent: Hello! How can I help you today?',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Typing indicator...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Message sent! We\'ll respond shortly.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close Chat'),
          ),
        ],
      ),
    );
  }

  void _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@safemap.com',
      query:
          'subject=SafeMap Support Request&body=Hi SafeMap Team,\n\nI need help with:\n\nThank you!',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open email app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+923001234567');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open phone dialer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openWhatsApp() async {
    final String phoneNumber = '+923001234567';
    final String message = 'Hi SafeMap! I need help with your app.';

    final Uri whatsappUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: phoneNumber,
      query: 'text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Issue Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Issue reported successfully!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showGuidelines() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Community Guidelines'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Be respectful to all community members'),
              Text('2. Report only genuine safety concerns'),
              Text('3. Do not share false information'),
              Text('4. Respect others\' privacy'),
              Text('5. Help others when you can safely'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
