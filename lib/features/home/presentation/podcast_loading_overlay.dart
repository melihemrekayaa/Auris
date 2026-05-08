import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class PodcastLoadingOverlay extends StatefulWidget {
  final String statusMessage;

  const PodcastLoadingOverlay({
    super.key,
    required this.statusMessage,
  });

  @override
  State<PodcastLoadingOverlay> createState() => _PodcastLoadingOverlayState();
}

class _PodcastLoadingOverlayState extends State<PodcastLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _factFadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _factFadeAnimation;

  int _currentFactIndex = 0;
  Timer? _factTimer;

  static const List<String> _funFacts = [
    "🎧 The word 'podcast' is a combination of 'iPod' and 'broadcast', coined in 2004.",
    "🌍 There are over 4 million podcasts worldwide, but only 20% are actively producing new episodes.",
    "⏱️ The average podcast listener subscribes to 7 shows and listens to about 8 episodes per week.",
    "🧠 Studies show that podcast listeners retain 40% more information than readers of the same content.",
    "🚗 44% of podcast listening happens while driving or commuting.",
    "📈 Podcast advertising revenue surpassed \$2 billion in 2023 for the first time.",
    "🎙️ The longest podcast episode ever recorded lasted over 36 hours straight.",
    "🇹🇷 Turkey ranks among the top 15 countries in podcast listenership growth.",
    "💡 AI-generated podcasts are a rising trend — you're part of the revolution!",
    "🎵 Music and podcasts activate different brain regions. Podcasts stimulate areas linked to empathy.",
    "📱 70% of podcast listeners use mobile devices, making apps like Auris essential.",
    "🌙 Many people use podcasts as a sleep aid — 30% listen right before bed.",
    "🔥 Joe Rogan's deal with Spotify was worth \$200 million, making it the largest podcast deal ever.",
    "🤖 AI text-to-speech technology has improved 300% in quality over the last 3 years.",
    "📚 Listening to podcasts can improve vocabulary and language skills by up to 25%.",
    "🎯 Podcast listeners are 45% more likely to have a college degree compared to the general population.",
    "⚡ The first podcast was recorded in 2003 by Dave Winer and Christopher Lydon.",
    "🌐 English dominates podcast content (75%), but multilingual podcasts are growing fast.",
    "🎤 Serial (2014) was the first podcast to reach 5 million downloads and started the true-crime podcast wave.",
    "💬 Auris uses advanced AI to transform any article into an engaging podcast in seconds.",
  ];



  String _getStatusEmoji(String status) {
    final Map<String, String> emojiMap = {
      'Reading': '📖',
      'Writing': '✍️',
      'Recording': '🎙️',
      'Saving': '☁️',
      'Done': '🎉',
    };
    for (final entry in emojiMap.entries) {
      if (status.contains(entry.key)) return entry.value;
    }
    return '⚡';
  }

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _factFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _factFadeAnimation = CurvedAnimation(
      parent: _factFadeController,
      curve: Curves.easeInOut,
    );

    _currentFactIndex = Random().nextInt(_funFacts.length);

    _factTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _cycleFact();
    });
  }

  void _cycleFact() async {
    await _factFadeController.reverse();
    if (!mounted) return;
    setState(() {
      _currentFactIndex = (_currentFactIndex + 1) % _funFacts.length;
    });
    _factFadeController.forward();
  }

  @override
  void dispose() {
    _factTimer?.cancel();
    _pulseController.dispose();
    _rotateController.dispose();
    _factFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _getStatusEmoji(widget.statusMessage);

    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundDark.withOpacity(0.95),
                const Color(0xFF1A0533).withOpacity(0.95),
                AppColors.backgroundDarker.withOpacity(0.95),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Animated Orb
                _buildAnimatedOrb(),

                const SizedBox(height: 40),

                // Samimi Başlık
                Text(
                  'Creating Your Podcast',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Hang tight — we're making something special for you ✨",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Status Badge
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    key: ValueKey(widget.statusMessage),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          widget.statusMessage,
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Did You Know? Section
                _buildFunFactCard(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedOrb() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating ring
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateController.value * 2 * pi,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.transparent,
                      width: 2,
                    ),
                    gradient: SweepGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.0),
                        AppColors.primary.withOpacity(0.7),
                        AppColors.secondary.withOpacity(0.7),
                        AppColors.primary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Inner pulsing orb
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        AppColors.primary,
                        Color(0xFF7C3AED),
                        Color(0xFF4F46E5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFunFactCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: FadeTransition(
        opacity: _factFadeAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Did You Know?',
                    style: GoogleFonts.inter(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _funFacts[_currentFactIndex],
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
