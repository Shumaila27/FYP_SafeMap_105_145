import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../utils/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  @override
  Widget build(BuildContext context) {
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
              colors: [AppColor.appSecondary, AppColor.appPrimary],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: AppColor.appSecondary.withValues(alpha: 0.3),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),
      backgroundColor: Colors.grey.shade50,
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 1.4),
      ),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: const [
              Icon(Icons.emergency, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Emergency Help',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: Colors.grey.shade300),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 1.4),
      ),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: const [
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Quick Help',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: Colors.grey.shade300),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 1.4),
      ),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: const [
              Icon(Icons.quiz, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: Colors.grey.shade300),
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
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 1.4),
      ),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: [
              Icon(Icons.support_agent, color: AppColor.appSecondary),
              const SizedBox(width: 8),
              const Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          // Contact content
          _buildContactInfo(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@safemap.com',
            color: Colors.blue,
            iconColor: Colors.white,
          ),
          _buildContactInfo(
            icon: Icons.phone_in_talk,
            title: 'Phone Support',
            subtitle: '+92 312 4195181',
            color: Colors.purple,
            iconColor: Colors.white,
          ),
          _buildContactInfo(
            icon: Icons.message,
            title: 'WhatsApp Support',
            subtitle: '+92 312 4195181',
            color: Colors.green.shade600,
            iconColor: Colors.white,
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
                  color: color.withOpacity(0.3),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.info_outline, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTipsSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 1.4),
      ),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: const [
              Icon(Icons.security, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Safety Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: Colors.grey.shade300),
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
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportIssueSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 1.4),
      ),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: const [
              Icon(Icons.bug_report, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Report an Issue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          // Report Issue content
          const Text(
            'Found a bug or have a suggestion? Let us know!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 1.4),
      ),
      child: Column(
        children: [
          // Main heading with icon
          Row(
            children: const [
              Icon(Icons.gavel, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'Community Guidelines',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Minimal line divider
          Container(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          // Community Guidelines content
          const Text(
            'Help us keep SafeMap safe for everyone by following our community guidelines.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
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
