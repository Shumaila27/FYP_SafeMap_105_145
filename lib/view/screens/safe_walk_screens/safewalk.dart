import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/guardian_service.dart';
import '../../../utils/app_colors.dart';
import '../../widgets/app_bar.dart';

class SafeWalkScreen extends StatefulWidget {
  const SafeWalkScreen({super.key});

  @override
  State<SafeWalkScreen> createState() => _SafeWalkScreenState();
}

class _SafeWalkScreenState extends State<SafeWalkScreen> {
  bool isWalking = false;
  bool showAddGuardian = false;
  String destination = '';
  List<String> selectedGuardians = [];
  final GuardianService _guardianService = GuardianService();

  @override
  void initState() {
    super.initState();
    // Initialize with shared service
    _guardianService.initializeGuardians();
  }

  //***************Functions*********************//
  void startSafeWalk() {
    // Check if destination is entered
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your destination first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if guardians are selected
    if (selectedGuardians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one guardian'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    _showSafeWalkStartConfirmation();
  }

  void _showSafeWalkStartConfirmation() {
    final selectedGuardianNames = _guardianService.guardians
        .where((g) => selectedGuardians.contains(g.id))
        .map((g) => g.name)
        .join(', ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shield, color: AppColor.getInteractivePrimary(context)),
            const SizedBox(width: 8),
            const Text('Start Safe Walk'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'re about to start a Safe Walk to:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColor.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.getContainerBackground(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColor.getContainerBorder(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColor.getInteractivePrimary(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      destination,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColor.getTextPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your selected guardians:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColor.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.getContainerBackground(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColor.getContainerBorder(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.group,
                    color: AppColor.getInteractivePrimary(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedGuardianNames,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColor.getTextPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your guardians will receive live location updates',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.green[300]
                            : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColor.getTextSecondary(context)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isWalking = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Safe Walk started successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.shield, color: Colors.white),
            label: const Text('Start Safe Walk'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.getInteractivePrimary(context),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void endSafeWalk() {
    setState(() {
      isWalking = false;
      destination = '';
      selectedGuardians.clear();
    });
  }

  void toggleGuardian(String id) {
    setState(() {
      if (selectedGuardians.contains(id)) {
        selectedGuardians.remove(id);
      } else {
        selectedGuardians.add(id);
      }
    });
  }

  void triggerEmergencyAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Send Emergency Alert?"),
        content: const Text(
          "This will alert all selected guardians with your latest known location.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Emergency alert sent to selected guardians."),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Send Alert"),
          ),
        ],
      ),
    );
  }

  //***************Main Screen widgets ********************//
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppMainBar(showBack: true),
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const SafeWalkAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: isWalking ? buildWalkingView() : buildSetupView(),
            ),
          ),
        ],
      ),
    );
  }

  //**********************COMPONENTS****************************//

  //Component 1: Setup means main view View
  Widget buildSetupView() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ⭐ DESTINATION INPUT
          TextField(
            decoration: const InputDecoration(
              labelText: 'Where are you going?',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                destination = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // ⭐ GUARDIAN SELECTION
          const Row(
            children: [
              Text(
                'Select Guardians',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          Column(
            children: _guardianService.guardians
                .map(
                  (g) => Card(
                    color: selectedGuardians.contains(g.id)
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: selectedGuardians.contains(g.id)
                            ? AppColor.appSecondary
                            : AppColor.appPrimary,
                        child: Text(
                          g.name
                              .trim()
                              .split(' ')
                              .where((n) => n.isNotEmpty)
                              .map((n) => n[0])
                              .join()
                              .toUpperCase(),
                          style: TextStyle(
                            color: selectedGuardians.contains(g.id)
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      title: Text(
                        g.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${g.relation} | ${g.phone}'),
                      trailing: Icon(
                        Icons.check_circle,
                        color: selectedGuardians.contains(g.id)
                            ? AppColor.appSecondary
                            : AppColor.appPrimary,
                      ),
                      onTap: () => toggleGuardian(g.id),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 10),

          // ⭐ TOP PURPLE INFO BOX
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B3A) : const Color(0xFFF3EDFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF4C3D8F)
                    : const Color(0xFFD9CFFF),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                "Select at least one guardian to start Safe Walk",
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFC4B5FD)
                      : Colors.deepPurple.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // ⭐ WHAT HAPPENS DURING SAFE WALK → WHITE CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What happens during Safe Walk?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                buildBullet(
                  "Your selected guardians receive live location updates",
                ),
                buildBullet("Automatic alerts if you stop moving unexpectedly"),
                buildBullet("One-tap emergency alert to all guardians"),
                buildBullet("Journey history for your records"),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ⭐ START SAFE WALK BUTTON
          ElevatedButton.icon(
            onPressed: startSafeWalk,
            icon: const Icon(Icons.shield, color: Colors.white),
            label: const Text(
              "Start Safe Walk",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColor.appSecondary,
            ),
          ),
        ],
      ),
    );
  }

  //Component 2: Walking View
  Widget buildWalkingView() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Journey Info Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                buildJourneyInfoRow(
                  Icons.location_on,
                  'Destination',
                  destination,
                ),
                buildJourneyInfoRow(
                  Icons.access_time,
                  'Journey Duration',
                  '5 minutes',
                ),
                buildJourneyInfoRow(
                  Icons.navigation,
                  'Current Location',
                  'Main Boulevard, Gulberg',
                ),
              ],
            ),
          ),
        ),
        // Active Guardians
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.group, color: AppColor.appSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Active Guardians (${selectedGuardians.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: _guardianService.guardians
                      .where((g) => selectedGuardians.contains(g.id))
                      .map(
                        (g) => Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: isDark
                              ? const Color(0xFF14322C)
                              : Colors.green[50],
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColor.appSecondary,
                              child: Text(
                                g.name
                                    .trim()
                                    .split(' ')
                                    .where((n) => n.isNotEmpty)
                                    .map((n) => n[0])
                                    .join()
                                    .toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              g.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(g.relation),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Watching',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        // Safety Tips
        Card(
          color: isDark ? const Color(0xFF3A2B12) : Colors.amber[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '💡 Stay alert and keep your phone accessible. Your guardians will be notified if you stop moving for more than 5 minutes.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFFBBF24) : Colors.amber,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Bottom Buttons
        ElevatedButton.icon(
          onPressed: endSafeWalk,
          icon: const Icon(Icons.check_circle),
          label: const Text("I've Arrived Safely"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerLowest,
            foregroundColor: Colors.green.shade600,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 5),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: selectedGuardians.isEmpty ? null : triggerEmergencyAlert,
          icon: const Icon(Icons.phone),
          label: const Text("Emergency Alert"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 5),
          ),
        ),
      ],
    );
  }

  // ✔ Reusable bullet text row
  Widget buildBullet(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check,
            color: Color(0xFF009A5A), // green check color
            size: 20,
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  //journey info row
  Widget buildJourneyInfoRow(IconData icon, String title, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColor.appSecondary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Below app bar after main app bar

class SafeWalkAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SafeWalkAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80); // AppBar height

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: colorScheme.surfaceContainerLowest,
      elevation: 1,
      automaticallyImplyLeading: false, // remove default back icon
      // 🔥 Title Section → Icon + Title + Subtitle
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🟣 Rounded Gradient Icon
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColor.appPrimary, AppColor.appSecondary],
              ),
            ),
            child: const Icon(
              LucideIcons.shield,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 10),

          // 🧠 Title + Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Safe Walk",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Share location with trusted contacts",
                style: TextStyle(
                  color: isDark ? colorScheme.onSurfaceVariant : Colors.black,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
