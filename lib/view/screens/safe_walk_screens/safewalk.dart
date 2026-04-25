import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../Models/guardian_model.dart';
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

  //***************Functions*********************//
  void startSafeWalk() {
    if (destination.isNotEmpty && selectedGuardians.isNotEmpty) {
      setState(() {
        isWalking = true;
      });
    }
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

  void showAddGuardianDialog() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameController = TextEditingController();
        TextEditingController phoneController = TextEditingController();
        TextEditingController relationController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Guardian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(labelText: 'Relation'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // You can add logic to save new guardian here
                Navigator.pop(context);
              },
              child: const Text('Add Guardian'),
            ),
          ],
        );
      },
    );
  }

  //***************Main Screen widgets ********************//
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppMainBar(showBack: true),

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Guardians',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: showAddGuardianDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add New'),
              ),
            ],
          ),

          Column(
            children: mockGuardians
                .map(
                  (g) => Card(
                    color: selectedGuardians.contains(g.id)
                        ? AppColor.appPrimary
                        : Colors.purple[50],
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: selectedGuardians.contains(g.id)
                            ? AppColor.appSecondary
                            : AppColor.appPrimary,
                        child: Text(
                          g.name.split(' ').map((n) => n[0]).join(),
                          style: TextStyle(
                            color: selectedGuardians.contains(g.id)
                                ? Colors.white
                                : Colors.black,
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
              color: const Color(0xFFF3EDFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD9CFFF), width: 2),
            ),
            child: Center(
              child: Text(
                "Select at least one guardian to start Safe Walk",
                style: TextStyle(
                  color: Colors.deepPurple.shade700,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "What happens during Safe Walk?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
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
                  children: mockGuardians
                      .where((g) => selectedGuardians.contains(g.id))
                      .map(
                        (g) => Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.green[50],
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColor.appSecondary,
                              child: Text(
                                g.name.split(' ').map((n) => n[0]).join(),
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
          color: Colors.amber[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '💡 Stay alert and keep your phone accessible. Your guardians will be notified if you stop moving for more than 5 minutes.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
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
            backgroundColor: Colors.white,
            foregroundColor: Colors.green,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 5),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {},
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
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  //journey info row
  Widget buildJourneyInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
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
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
    return AppBar(
      backgroundColor: Colors.white,
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Safe Walk",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Share location with trusted contacts",
                style: TextStyle(color: Colors.black, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
