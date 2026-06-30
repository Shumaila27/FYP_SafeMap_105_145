// lib/view/screens/community_vote_screen.dart
//
// ──────────────────────────────────────────────────────────────────
//  CommunityVoteScreen
//
//  Shown when a user taps a community-vote FCM notification.
//  Lets nearby users confirm or deny a freshly submitted report.
//
//  Route arguments (Map<String, dynamic>):
//    'report_id'    : String  — UUID of the report to vote on
//    'category_name': String  — Incident category (e.g. "Theft")
//    'description'  : String  — Short description from the report
// ──────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../services/community_vote_service.dart';
import '../../utils/app_colors.dart';


class CommunityVoteScreen extends StatefulWidget {
  final String reportId;
  final String categoryName;
  final String description;

  const CommunityVoteScreen({
    super.key,
    required this.reportId,
    required this.categoryName,
    required this.description,
  });

  @override
  State<CommunityVoteScreen> createState() => _CommunityVoteScreenState();
}

class _CommunityVoteScreenState extends State<CommunityVoteScreen>
    with TickerProviderStateMixin {

  // ── State ─────────────────────────────────────────────────────
  _VoteScreenState _state = _VoteScreenState.loading;
  bool? _userVote;        // true = yes, false = no
  String _errorMessage = '';

  // ── Animation Controllers ─────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _successController;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkIfAlreadyVoted();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _successAnim = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  // ── Logic ─────────────────────────────────────────────────────

  Future<void> _checkIfAlreadyVoted() async {
    try {
      final hasVoted = await CommunityVoteService.instance
          .hasUserVoted(widget.reportId);

      if (!mounted) return;
      setState(() {
        _state = hasVoted
            ? _VoteScreenState.alreadyVoted
            : _VoteScreenState.idle;
      });
    } catch (_) {
      if (mounted) setState(() => _state = _VoteScreenState.idle);
    }
  }

  Future<void> _castVote(bool witnessed) async {
    setState(() {
      _state    = _VoteScreenState.casting;
      _userVote = witnessed;
    });

    try {
      await CommunityVoteService.instance.castVote(
        reportId:  widget.reportId,
        witnessed: witnessed,
      );

      if (!mounted) return;
      setState(() => _state = _VoteScreenState.success);
      _successController.forward();

      // Auto-dismiss after 2.5 seconds
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) Navigator.of(context).pop();

    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _state        = _VoteScreenState.error;
        _errorMessage = msg;
      });
    }
  }

  void _skip() => Navigator.of(context).pop();

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF080F1A)
          : const Color(0xFFF0FDFA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: _buildBody(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D4F4A), const Color(0xFF0A3530)]
              : [AppColor.teal500, AppColor.teal700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.teal700.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: back button + label
          Row(
            children: [
              GestureDetector(
                onTap: _skip,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Community Verification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Icon + title
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, _) => Transform.scale(
                  scale: 1.0 + (_pulseAnim.value * 0.08),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Incident Near You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Did you witness this?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body dispatcher ───────────────────────────────────────────

  Widget _buildBody(bool isDark) {
    switch (_state) {
      case _VoteScreenState.loading:
        return _buildLoading();
      case _VoteScreenState.alreadyVoted:
        return _buildAlreadyVoted(isDark);
      case _VoteScreenState.idle:
      case _VoteScreenState.casting:
        return _buildVoteCard(isDark);
      case _VoteScreenState.success:
        return _buildSuccess(isDark);
      case _VoteScreenState.error:
        return _buildError(isDark);
    }
  }

  // ── Loading ───────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColor.teal500,
        strokeWidth: 3,
      ),
    );
  }

  // ── Vote Card ─────────────────────────────────────────────────

  Widget _buildVoteCard(bool isDark) {
    final isLoading = _state == _VoteScreenState.casting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // ── Report Info Card ─────────────────────────────
            _InfoCard(isDark: isDark, categoryName: widget.categoryName, description: widget.description),

            const SizedBox(height: 28),

            // ── Question label ───────────────────────────────
            Text(
              'Did you see this incident in your area?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColor.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your anonymous vote helps verify or dismiss this report.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColor.getTextSecondary(context),
              ),
            ),

            const SizedBox(height: 32),

            // ── YES Button ────────────────────────────────────
            _VoteButton(
              label: 'Yes, I Witnessed This',
              icon: Icons.check_circle_rounded,
              gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
              shadowColor: const Color(0xFF10B981),
              isLoading: isLoading && _userVote == true,
              isDisabled: isLoading,
              onTap: () => _castVote(true),
            ),

            const SizedBox(height: 16),

            // ── NO Button ────────────────────────────────────
            _VoteButton(
              label: 'No, I Did Not See This',
              icon: Icons.cancel_rounded,
              gradient: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
              shadowColor: const Color(0xFFEF4444),
              isLoading: isLoading && _userVote == false,
              isDisabled: isLoading,
              onTap: () => _castVote(false),
            ),

            const SizedBox(height: 24),

            // ── Skip ─────────────────────────────────────────
            if (!isLoading)
              TextButton(
                onPressed: _skip,
                child: Text(
                  'Skip — I\'m not sure',
                  style: TextStyle(
                    color: AppColor.getTextTertiary(context),
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ── Info note ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColor.teal500.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColor.teal500.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColor.teal500, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your vote is anonymous. This helps the community '
                      'validate real incidents and filter fake reports.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.getTextSecondary(context),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Already Voted ─────────────────────────────────────────────

  Widget _buildAlreadyVoted(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColor.teal400, AppColor.teal600],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.teal500.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.how_to_vote_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              'Already Voted',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColor.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You\'ve already submitted your vote for this incident report.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColor.getTextSecondary(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _InfoCard(
              isDark: isDark,
              categoryName: widget.categoryName,
              description: widget.description,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _skip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.teal500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Close',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Success ───────────────────────────────────────────────────

  Widget _buildSuccess(bool isDark) {
    final isYes = _userVote == true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ScaleTransition(
          scale: _successAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated circle
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, value, _) => Transform.scale(
                  scale: value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isYes
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isYes
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                              .withValues(alpha: 0.45),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      isYes
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                isYes ? 'Vote Recorded — Yes!' : 'Vote Recorded — No!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColor.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isYes
                    ? 'You confirmed witnessing this incident.\n'
                      'Your vote helps the community trust this report.'
                    : 'You did not witness this incident.\n'
                      'Your vote helps filter potential fake reports.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.getTextSecondary(context),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Animated progress indicator (auto-dismiss)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 0.0),
                duration: const Duration(milliseconds: 2500),
                builder: (_, value, _) => Column(
                  children: [
                    LinearProgressIndicator(
                      value: value,
                      backgroundColor:
                          AppColor.teal500.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(AppColor.teal500),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 4,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Closing automatically…',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.getTextTertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColor.dangerRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColor.dangerRed, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              'Vote Failed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColor.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColor.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skip,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _state = _VoteScreenState.idle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.teal500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  State Enum
// ══════════════════════════════════════════════════════════════════

enum _VoteScreenState { loading, idle, casting, success, alreadyVoted, error }

// ══════════════════════════════════════════════════════════════════
//  Sub-widgets
// ══════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final bool   isDark;
  final String categoryName;
  final String description;

  const _InfoCard({
    required this.isDark,
    required this.categoryName,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111827)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColor.teal800.withValues(alpha: 0.5)
              : AppColor.teal200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColor.teal500, AppColor.teal700],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      categoryName,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.location_on_rounded,
                color: AppColor.teal500.withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Nearby',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColor.getTextTertiary(context),
                ),
              ),
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: AppColor.getTextPrimary(context),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final List<Color>  gradient;
  final Color        shadowColor;
  final bool         isLoading;
  final bool         isDisabled;
  final VoidCallback onTap;

  const _VoteButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: isDisabled && !isLoading ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
