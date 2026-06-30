import 'package:flutter/material.dart';
import 'package:staysafe/view/screens/ai_screens/chatboot_screen.dart';
import '../../../utils/app_colors.dart';
import '../../widgets/app_bar.dart';

class AIRecommendationScreen extends StatelessWidget {
  const AIRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppMainBar(),
      backgroundColor: colorScheme.surface,
      body: const SafeArea(
        child: Column(
          children: [
            AiAppBar(),
            Expanded(child: ChatBotScreen()),
          ],
        ),
      ),
    );
  }
}

//App bar to be added below the main app bar

class AiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AiAppBar({super.key});

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
              Icons.auto_awesome,
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
                "AI Assistant",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Your intelligent safety companion",
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
