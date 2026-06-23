// lib/screens/safe_walk/safe_walk_screen.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../Controller/safe_walk_controller.dart';
import '../../../Models/guardian_model.dart';
import '../../../utils/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../../main.dart'; // ✅ NEW — gives access to routeObserver

class SafeWalkScreen extends StatefulWidget {
  const SafeWalkScreen({super.key});

  @override
  State<SafeWalkScreen> createState() => _SafeWalkScreenState();
}

// ✅ CHANGED: added RouteAware mixin
class _SafeWalkScreenState extends State<SafeWalkScreen> with RouteAware {

  late final SafeWalkController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SafeWalkController();
    _ctrl.init();
    _ctrl.addListener(_onControllerUpdate);
  }

  // ✅ NEW: subscribe to route observer so didPopNext() fires
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  // ✅ NEW: fires when user comes BACK to this screen (e.g. from ProfileScreen)
  // Safety fallback — forces a fresh fetch in case ChangeNotifier missed anything
  @override
  void didPopNext() {
    _ctrl.reloadGuardians();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this); // ✅ NEW — prevent memory leak
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (_ctrl.error != null) {
      _snack(_ctrl.error!, Colors.red);
    }
    if (mounted) setState(() {});
  }

  // ── Snackbar ──────────────────────────────────────────────

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
  }

  // ── Confirmation dialogs ──────────────────────────────────

  Future<void> _showStartConfirmation() async {
    final names = _ctrl.guardians
        .where((g) => _ctrl.isSelected(g.id))
        .map((g) => g.name)
        .join(', ');

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.shield, color: AppColor.getInteractivePrimary(context)),
          const SizedBox(width: 8),
          const Text('Start Safe Walk'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Destination:'),
            const SizedBox(height: 6),
            _infoBox(Icons.location_on, _ctrl.destination),
            const SizedBox(height: 12),
            _label('Guardians:'),
            const SizedBox(height: 6),
            _infoBox(Icons.group, names.isEmpty ? 'None selected' : names),
            if (_ctrl.hasNoSafeMapGuardians) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: const Row(children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'None of your guardians have SafeMap. '
                          'Live tracking will not be active.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ]),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Guardians on SafeMap will receive live location updates',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
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

    if (confirmed == true) {
      final error = await _ctrl.startWalk();
      if (error == null && mounted) {
        _snack('Safe Walk started! Guardians are being notified.', Colors.green);
      }
    }
  }

  Future<void> _showEmergencyDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 8),
          Text('Send Emergency Alert?',
              style: TextStyle(color: Colors.red)),
        ]),
        content: const Text(
          'This will immediately alert all your guardians '
              'with your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Alert',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error = await _ctrl.sendEmergencyAlert();
      if (error == null && mounted) {
        _snack('🚨 Emergency alert sent to all guardians!', Colors.red);
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppMainBar(showBack: true),
      backgroundColor: cs.surface,
      body: Column(children: [
        const SafeWalkAppBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: switch (_ctrl.state) {
              WalkState.idle      => _buildSetupView(),
              WalkState.starting  => _buildSetupView(),
              WalkState.active    => _buildWalkingView(),
              WalkState.emergency => _buildWalkingView(),
              WalkState.ending    => _buildWalkingView(),
            },
          ),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SETUP VIEW
  // ════════════════════════════════════════════════════════════

  Widget _buildSetupView() {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        TextField(
          decoration: const InputDecoration(
            labelText: 'Where are you going?',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          onChanged: _ctrl.setDestination,
        ),

        const SizedBox(height: 16),

        Row(children: [
          const Text('Select Guardians',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          if (_ctrl.guardians.isEmpty)
            Text('Add contacts in Profile first',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ]),
        const SizedBox(height: 8),

        _ctrl.guardians.isEmpty
            ? _emptyGuardiansCard()
            : Column(
          children: _ctrl.guardians
              .map((g) => _guardianCard(g))
              .toList(),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1B3A)
                : const Color(0xFFF3EDFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF4C3D8F)
                  : const Color(0xFFD9CFFF),
              width: 2,
            ),
          ),
          child: Text(
            'Select at least one guardian to start Safe Walk',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? const Color(0xFFC4B5FD)
                  : Colors.deepPurple.shade700,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What happens during Safe Walk?',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              const SizedBox(height: 10),
              _bullet('Guardians on SafeMap receive live location updates'),
              _bullet('Automatic alerts if you stop moving unexpectedly'),
              _bullet('One-tap emergency alert to all guardians'),
              _bullet('Journey history saved for your records'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: _ctrl.isStarting
              ? null
              : () {
            final v = _ctrl.validate();
            if (!v.isValid) {
              _snack(v.error!, Colors.orange);
            } else {
              _showStartConfirmation();
            }
          },
          icon: _ctrl.isStarting
              ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.shield, color: Colors.white),
          label: Text(
            _ctrl.isStarting ? 'Starting...' : 'Start Safe Walk',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColor.appSecondary,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  //  WALKING VIEW
  // ════════════════════════════════════════════════════════════

  Widget _buildWalkingView() {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walk   = _ctrl.currentWalk;

    final activeGuardians = _ctrl.guardians
        .where((g) => _ctrl.isSelected(g.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _journeyRow(Icons.location_on, 'Destination',
                  _ctrl.destination),
              _journeyRow(Icons.access_time, 'Journey Duration',
                  _ctrl.elapsedString),
              _journeyRow(
                Icons.navigation,
                'Current Location',
                walk?.currentLat != null && walk?.currentLng != null
                    ? '${walk!.currentLat!.toStringAsFixed(4)}, '
                    '${walk.currentLng!.toStringAsFixed(4)}'
                    : 'Acquiring location...',
              ),
              if (_ctrl.isEmergency)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.warning, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('🚨 Emergency alert sent to all guardians',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
            ]),
          ),
        ),

        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.group, color: AppColor.appSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Active Guardians (${activeGuardians.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ]),
                const SizedBox(height: 12),
                ...activeGuardians.map((g) => Card(
                  color: isDark
                      ? const Color(0xFF14322C)
                      : Colors.green[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColor.appSecondary,
                      child: Text(g.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(g.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(g.relation),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: g.isOnSafeMap
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        g.isOnSafeMap ? 'Watching' : 'No app',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),

        Card(
          color: isDark ? const Color(0xFF3A2B12) : Colors.amber[50],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '💡 Stay alert and keep your phone accessible. '
                  'Your guardians will be notified if you stop moving.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFFBBF24)
                    : Colors.amber[800],
              ),
            ),
          ),
        ),

        ElevatedButton.icon(
          onPressed: _ctrl.isEnding ? null : () async {
            final error = await _ctrl.endWalk();
            if (error == null && mounted) {
              _snack('You arrived safely! Walk ended.', Colors.green);
            }
          },
          icon: _ctrl.isEnding
              ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check_circle),
          label: Text(_ctrl.isEnding ? 'Ending walk...' : "I've Arrived Safely"),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.surfaceContainerLowest,
            foregroundColor: Colors.green.shade600,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),

        const SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: (_ctrl.isEmergency || _ctrl.isEnding)
              ? null
              : _showEmergencyDialog,
          icon: const Icon(Icons.phone),
          label: const Text('Emergency Alert'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  //  REUSABLE WIDGETS — all unchanged
  // ════════════════════════════════════════════════════════════

  Widget _guardianCard(Guardian g) {
    final cs       = Theme.of(context).colorScheme;
    final selected = _ctrl.isSelected(g.id);

    return Card(
      color: selected
          ? cs.primaryContainer
          : cs.surfaceContainerHighest.withValues(alpha: 0.4),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          selected ? AppColor.appSecondary : AppColor.appPrimary,
          child: Text(g.initials,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(g.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${g.relation} | ${g.phone}'),
            const SizedBox(height: 4),
            g.isOnSafeMap
                ? _statusBadge('✅ On SafeMap — Live tracking', Colors.green)
                : _statusBadge('⚠️ Not on SafeMap', Colors.orange),
          ],
        ),
        trailing: Icon(
          selected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: selected ? AppColor.appSecondary : cs.onSurfaceVariant,
        ),
        onTap: () => _ctrl.toggleGuardian(g.id),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(text,
        style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600)),
  );

  Widget _emptyGuardiansCard() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        'No emergency contacts found.\n'
            'Go to Profile → Emergency Contacts to add them.',
        textAlign: TextAlign.center,
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColor.getTextPrimary(context)));

  Widget _infoBox(IconData icon, String text) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColor.getContainerBackground(context),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColor.getContainerBorder(context)),
    ),
    child: Row(children: [
      Icon(icon,
          color: AppColor.getInteractivePrimary(context), size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColor.getTextPrimary(context))),
      ),
    ]),
  );

  Widget _bullet(String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Color(0xFF009A5A), size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 14, color: cs.onSurface))),
        ],
      ),
    );
  }

  Widget _journeyRow(IconData icon, String title, String value) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColor.appSecondary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: cs.onSurface)),
        ]),
      ]),
    );
  }
}

// ── SafeWalk AppBar — unchanged ──────────────────────────────

class SafeWalkAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SafeWalkAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: cs.surfaceContainerLowest,
      elevation: 1,
      automaticallyImplyLeading: false,
      title: Row(children: [
        Container(
          width: 45, height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: [AppColor.appPrimary, AppColor.appSecondary]),
          ),
          child: const Icon(LucideIcons.shield,
              color: Colors.white, size: 25),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Safe Walk',
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Share location with trusted contacts',
                style: TextStyle(
                    color: isDark ? cs.onSurfaceVariant : Colors.black,
                    fontSize: 13)),
          ],
        ),
      ]),
    );
  }
}