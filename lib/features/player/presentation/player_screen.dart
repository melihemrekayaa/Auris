import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/word_timestamp.dart';

class SentenceTimestamp {
  final String text;
  final double startTime;
  final double endTime;
  SentenceTimestamp(this.text, this.startTime, this.endTime);
}

class PlayerScreen extends StatefulWidget {
  final String title;
  final String? audioFilePath;
  final List<WordTimestamp>? wordTimestamps;
  final String? script;
  final String? imageUrl;
  final String? category;
  
  const PlayerScreen({
    super.key,
    required this.title,
    this.audioFilePath,
    this.wordTimestamps,
    this.script,
    this.imageUrl,
    this.category,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isPlayerReady = false;
  bool _showLyrics = false;
  bool _showSubtitleTooltip = true;

  final ScrollController _lyricsScrollController = ScrollController();
  List<SentenceTimestamp> _sentences = [];
  int _currentSentenceIndex = -1;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _parseSentences();
  }

  void _parseSentences() {
    if (widget.wordTimestamps != null && widget.wordTimestamps!.isNotEmpty) {
      String currentSentence = '';
      double start = widget.wordTimestamps!.first.startTime;
      
      for (var wt in widget.wordTimestamps!) {
        currentSentence += wt.word;
        if (wt.word.trim().endsWith('.') || wt.word.trim().endsWith('!') || wt.word.trim().endsWith('?')) {
          _sentences.add(SentenceTimestamp(currentSentence.trim(), start, wt.endTime));
          currentSentence = '';
          start = wt.endTime; // approximate next start
        } else {
          currentSentence += ' '; // Kelimeler arasına boşluk ekle
        }
      }
      if (currentSentence.trim().isNotEmpty) {
        _sentences.add(SentenceTimestamp(currentSentence.trim(), start, widget.wordTimestamps!.last.endTime));
      }
    }
  }

  Future<void> _initAudioPlayer() async {
    // Listen to changes
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
          _updateLyricsScroll();
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });

    // Load file if available
    if (widget.audioFilePath != null && widget.audioFilePath!.isNotEmpty) {
      try {
        final path = widget.audioFilePath!;
        if (path.startsWith('http://') || path.startsWith('https://')) {
          // Cloud URL — play directly from URL (audioplayers handles caching)
          await _audioPlayer.setSourceUrl(path);
        } else {
          // Local file
          await _audioPlayer.setSourceDeviceFile(path);
        }
        _isPlayerReady = true;
        // Auto play
        await _audioPlayer.resume();
      } catch (e) {
        debugPrint('Error loading audio: $e');
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  void _updateLyricsScroll() {
    if (_sentences.isEmpty) return;

    final currentSec = _position.inMilliseconds / 1000.0;
    int newIndex = _sentences.indexWhere((s) => currentSec >= s.startTime && currentSec <= s.endTime);
    
    // Eğer konuşma aralarındaki bir saniyedeysek, son okunan cümleyi vurgulu tut
    if (newIndex == -1) {
      newIndex = _sentences.lastIndexWhere((s) => currentSec > s.endTime);
    }

    if (newIndex != -1 && newIndex != _currentSentenceIndex) {
      setState(() {
        _currentSentenceIndex = newIndex;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background matches the album art color vibe
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2E1065), // Deep Purple
                  AppColors.backgroundDark,
                  AppColors.backgroundDarker,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                      ),
                      Text(
                        'Now Playing',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: _sentences.isNotEmpty ? () {
                              setState(() {
                                _showLyrics = !_showLyrics;
                                _showSubtitleTooltip = false;
                              });
                            } : null,
                            icon: Icon(
                              _showLyrics ? Icons.subtitles_rounded : Icons.subtitles_off_rounded,
                              color: _sentences.isNotEmpty ? Colors.white : Colors.white24,
                            ),
                          ),
                          // Tooltip
                          if (_showSubtitleTooltip && _sentences.isNotEmpty)
                            Positioned(
                              top: 48,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _showSubtitleTooltip = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Tap to show lyrics ',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Got it',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Album Art — Makale fotoğrafı veya gradient placeholder
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                        )
                      : _buildCoverPlaceholder(),
                  ),
                ),

                const Spacer(flex: 1),

                // Title and Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: widget.title.length > 60 ? 18 : (widget.title.length > 40 ? 22 : 26),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Kategori etiketi + kaynak
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.category != null && widget.category!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.category!,
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            'AI Podcast',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: _position.inSeconds.toDouble(),
                          max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 100,
                          onChanged: (value) async {
                            final position = Duration(seconds: value.toInt());
                            await _audioPlayer.seek(position);
                          },
                        ),
                      ),
                      
                      // Timestamps
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_position), style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                            Text(_formatDuration(_duration), style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Player Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () async {
                              final newPos = _position - const Duration(seconds: 10);
                              await _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
                            },
                            icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 32),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (!_isPlayerReady) return;
                              if (_isPlaying) {
                                await _audioPlayer.pause();
                              } else {
                                await _audioPlayer.resume();
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryDark],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final newPos = _position + const Duration(seconds: 10);
                              await _audioPlayer.seek(newPos > _duration ? _duration : newPos);
                            },
                            icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 32),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _showLyrics && _sentences.isNotEmpty ? 120 : 48), // Bottom sheet için boşluk
              ],
            ),
          ),
          
          // Sürüklenebilir Lyrics Paneli (DraggableScrollableSheet)
          if (_sentences.isNotEmpty && _showLyrics)
            DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.15,
              maxChildSize: 0.75,
              snap: true,
              snapSizes: const [0.15, 0.35, 0.55, 0.75],
              builder: (context, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        border: Border(top: BorderSide(width: 1, color: Colors.white.withOpacity(0.15))),
                      ),
                      child: Column(
                        children: [
                          // Sürükleme çubuğu (handle)
                          GestureDetector(
                            onTap: () => setState(() => _showLyrics = false),
                            child: Container(
                              margin: const EdgeInsets.only(top: 12, bottom: 4),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Subtitles',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          // Lyrics listesi
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.only(top: 4, bottom: 80, left: 24, right: 24),
                              itemCount: _sentences.length,
                              itemBuilder: (context, index) {
                                final sentence = _sentences[index];
                                final isActive = index == _currentSentenceIndex;
                                final isPast = index < _currentSentenceIndex;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    sentence.text,
                                    style: GoogleFonts.inter(
                                      fontSize: isActive ? 22 : 18,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                      color: isActive 
                                          ? Colors.white 
                                          : (isPast ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.2)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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

  Widget _buildCoverPlaceholder() {
    return Container(
      width: 280,
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC026D3), Color(0xFF4F46E5)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.graphic_eq_rounded, size: 80, color: Colors.white54),
      ),
    );
  }
}
