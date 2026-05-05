import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:staysafe/view/screens/ai_screens/chatboot_screen.dart';
import 'package:staysafe/view/screens/ai_screens/routes_screen.dart';
import '../../../utils/app_colors.dart';
import '../../widgets/app_bar.dart';

class AIRecommendationScreen extends StatefulWidget {
  const AIRecommendationScreen({super.key});

  @override
  State<AIRecommendationScreen> createState() => _AIRecommendationScreenState();
}

class _AIRecommendationScreenState extends State<AIRecommendationScreen> {
  int selectedIndex = 0; // 0 = Guardian, 1 = Routes

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppMainBar(showBack: true),
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const AiAppBar(),

            // Toggle buttons (Guardian & Routes)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Guardian Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: selectedIndex == 0
                              ? null
                              : colorScheme.surfaceContainerHighest,
                          gradient: selectedIndex == 0
                              ? LinearGradient(
                                  colors: [
                                    AppColor.appPrimary,
                                    AppColor.appSecondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(2, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.botMessageSquare,
                              color: selectedIndex == 0
                                  ? Colors.white
                                  : colorScheme.onSurface,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Chat Boot',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selectedIndex == 0
                                    ? Colors.white
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Routes Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        margin: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          color: selectedIndex == 1
                              ? null
                              : colorScheme.surfaceContainerHighest,
                          gradient: selectedIndex == 1
                              ? LinearGradient(
                                  colors: [
                                    AppColor.appPrimary,
                                    AppColor.appSecondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(2, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.route_outlined,
                              color: selectedIndex == 1
                                  ? Colors.white
                                  : colorScheme.onSurface,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Routes',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selectedIndex == 1
                                    ? Colors.white
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Screen content area
            Expanded(
              child: selectedIndex == 0
                  ? const ChatBotScreen()
                  : const RoutesScreen(),
            ),
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
