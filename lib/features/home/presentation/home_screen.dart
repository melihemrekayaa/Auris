import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/trial_provider.dart';
import '../../../core/providers/podcast_provider.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../player/presentation/player_screen.dart';
import 'podcast_loading_overlay.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends ConsumerStatefulWidget {
  const _HomeScreenContent({super.key});

  @override
  ConsumerState<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends ConsumerState<_HomeScreenContent> {
  final GlobalKey _trialBadgeKey = GlobalKey();
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowCoachmark();
    });
  }

  Future<void> _checkAndShowCoachmark() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenCoachmark = prefs.getBool('has_seen_home_coachmark') ?? false;
    
    if (!hasSeenCoachmark) {
      if (!mounted) return;
      ShowCaseWidget.of(context).startShowCase([_trialBadgeKey]);
      await prefs.setBool('has_seen_home_coachmark', true);
    }
  }

  Future<void> _handleGeneratePodcast() async {
    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    // [TESTING MODE] Free Trial kullanma mantığını geçici olarak devre dışı bıraktık
    // try {
    //   final trialNotifier = ref.read(trialProvider.notifier);
    //   await trialNotifier.useTrial();
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Failed to process trial. Please try again.')),
    //   );
    //   return;
    // }

    // 2. Yapay Zeka Podcast üretimini başlat
    final success = await ref.read(podcastProvider.notifier).generatePodcast(_urlController.text.trim());

    if (success && mounted) {
      final podcastState = ref.read(podcastProvider);
      final filePath = podcastState.audioFilePath;
      if (filePath != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              title: podcastState.title ?? 'Generated Podcast',
              audioFilePath: filePath,
              wordTimestamps: podcastState.wordTimestamps,
              script: podcastState.script,
              imageUrl: podcastState.imageUrl,
              category: podcastState.category,
            ),
          ),
        );
      }
    } else if (mounted) {
      final error = ref.read(podcastProvider).error;
      debugPrint('PODCAST GENERATION ERROR: $error'); // Konsola yazdır
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trialState = ref.watch(trialProvider);
    final podcastState = ref.watch(podcastProvider);
    // [TESTING MODE] Her zaman false yaparak sınırsız deneme hakkı tanımlıyoruz
    final hasUsedTrial = false; 

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Consumer(
                        builder: (context, ref, child) {
                          final user = ref.watch(authStateProvider).value;
                          final displayName = user?.displayName ?? 'Ready to listen?';
                          return Text(
                            displayName,
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 28,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  // Profile / Logout
                  Consumer(
                    builder: (context, ref, child) {
                      final user = ref.watch(authStateProvider).value;
                      return GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: AppColors.glassBackground,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(height: 24),
                                  ListTile(
                                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                                    title: Text('Sign Out', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await ref.read(authServiceProvider).signOut();
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.glassBackground,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: user?.photoURL != null
                              ? ClipOval(child: Image.network(user!.photoURL!, fit: BoxFit.cover))
                              : const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                        ),
                      );
                    },
                  ),

                ],
              ),
            ),

            // Input Area (Glassmorphism)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tooltip (Coachmark) Target
                        Showcase(
                          key: _trialBadgeKey,
                          description: "Paste an article link here to generate your first free podcast!",
                          tooltipBackgroundColor: AppColors.primary,
                          textColor: Colors.white,
                          descTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                          child: hasUsedTrial
                            ? Text(
                                'Trial Finished (Premium Required)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.tertiary,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '1',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Free Trial Available',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.glassBorder, width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.link, color: AppColors.textSecondary, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _urlController,
                                        enabled: !hasUsedTrial && !podcastState.isLoading,
                                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                                        decoration: InputDecoration(
                                          hintText: 'https://...',
                                          hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.only(bottom: 12), // Align visually
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: (hasUsedTrial || podcastState.isLoading) ? null : _handleGeneratePodcast,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: (hasUsedTrial || podcastState.isLoading)
                                        ? [Colors.grey.shade800, Colors.grey.shade900]
                                        : [AppColors.primary, AppColors.primaryDark],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: podcastState.isLoading 
                                    ? const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        if (podcastState.isLoading) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              podcastState.statusMessage,
                              style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Recent Podcasts List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Your Library',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final historyAsync = ref.watch(historyProvider);
                  
                  return historyAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (error, stack) => Center(
                      child: Text('Error loading library: $error', style: GoogleFonts.inter(color: Colors.redAccent)),
                    ),
                    data: (history) {
                      if (history.isEmpty) {
                        return Center(
                          child: Text(
                            'No podcasts generated yet.\nPaste a link above to get started!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final podcast = history[index];

                      return Dismissible(
                        key: Key(podcast.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (BuildContext ctx) {
                              return AlertDialog(
                                backgroundColor: AppColors.backgroundDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text('Delete Podcast?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                                content: Text(
                                  'This will permanently delete the podcast and free up space on your device.',
                                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: Text('Delete', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              );
                            },
                          ) ?? false;
                        },
                        onDismissed: (direction) {
                          ref.read(historyProvider.notifier).deletePodcast(podcast.id);
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PlayerScreen(
                                  title: podcast.title,
                                  audioFilePath: podcast.audioFilePath,
                                  wordTimestamps: podcast.wordTimestamps,
                                  script: podcast.script,
                                  imageUrl: podcast.imageUrl,
                                  category: podcast.category,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.glassBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Row(
                              children: [
                                // Makale Fotoğrafı veya Gradient Placeholder
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: podcast.imageUrl != null && podcast.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        podcast.imageUrl!,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildPlaceholderThumb(),
                                      )
                                    : _buildPlaceholderThumb(),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        podcast.title,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (podcast.category != null && podcast.category!.isNotEmpty) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                podcast.category!,
                                                style: GoogleFonts.inter(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Text(
                                            '${podcast.createdAt.day}/${podcast.createdAt.month}/${podcast.createdAt.year}',
                                            style: GoogleFonts.inter(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 36),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                    }, // end of data callback
                  ); // end of historyAsync.when
                },
              ),
            ),
          ],
        ),
      ),
      
          // Tam ekran Loading Overlay
          if (podcastState.isLoading)
            PodcastLoadingOverlay(statusMessage: podcastState.statusMessage),
        ],
      ),
    );
  }

  Widget _buildPlaceholderThumb() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.5),
            AppColors.primaryDark.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
    );
  }
}
