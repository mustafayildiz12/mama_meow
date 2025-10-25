import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/models/podcast_model.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DisplayPodcastPage extends StatefulWidget {
  /// The podcast model containing all necessary information for playback and display
  final Podcast podcast;

  /// The complete list of podcasts for navigation
  final List<Podcast> podcastList;

  /// The current index in the podcast list
  final int currentIndex;

  const DisplayPodcastPage({
    super.key,
    required this.podcast,
    required this.podcastList,
    required this.currentIndex,
  });

  @override
  State<DisplayPodcastPage> createState() => _DisplayPodcastPageState();
}

/// Private state class for DisplayPodcastPage that manages audio playback and UI state.
///
/// This class handles:
/// - Audio player initialization and lifecycle management
/// - Playback state management (playing, paused, looping)
/// - Stream subscriptions for real-time UI updates
/// - User interaction handling (play/pause, seek, speed control)
class _DisplayPodcastPageState extends State<DisplayPodcastPage> {
  /// The main audio player instance for podcast playback
  late AudioPlayer _player;

  /// Current playback state - true if audio is playing, false if paused
  bool isPlaying = false;

  /// Loop mode state - true if audio should loop continuously
  bool isLooping = false;

  /// Current playback speed multiplier (1.0 = normal speed)
  double playbackSpeed = 1.0;

  /// Available playback speed options for user selection
  final List<double> speedOptions = [1.0, 1.25, 1.5, 2.0];

  /// Current podcast being played
  late Podcast currentPodcast;

  /// Current index in the podcast list
  late int currentIndex;

  bool isUserPremium = false;

  /// Initializes the audio player and sets up stream listeners for real-time UI updates.
  ///
  /// This method:
  /// 1. Creates a new AudioPlayer instance
  /// 2. Initializes audio with the podcast URL
  /// 3. Sets up stream listeners for:
  ///    - Playback state changes (playing/paused)
  ///    - Player state changes (completed, buffering, etc.)
  ///    - Loop mode changes
  ///
  /// **Stream Listeners:**
  /// - `playingStream`: Updates UI when playback starts/stops
  /// - `playerStateStream`: Handles completion events and auto-replay
  /// - `loopModeStream`: Syncs loop toggle state with player
  ///
  ///
  @override
  void initState() {
    super.initState();
    currentPodcast = widget.podcast;
    currentIndex = widget.currentIndex;
    checkUserPremium();
    _player = AudioPlayer();
    _initAudio();

    // Listen to playback state changes
    _player.playingStream.listen((playing) {
      if (mounted) setState(() => isPlaying = playing);
    });

    // Handle completion behavior: auto-replay if loop is disabled
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        if (!isLooping) {
          // If loop is off, restart from beginning
          _player.seek(Duration.zero);
          _player.play();
        }
        // If loop is on, LoopMode.one handles this automatically
      }
    });

    // Listen to loop mode changes
    _player.loopModeStream.listen((mode) {
      if (!mounted) return;
      setState(() => isLooping = (mode == LoopMode.one));
    });
  }

  /// Cleans up resources when the widget is disposed.
  ///
  /// This method properly disposes of the AudioPlayer instance to prevent memory leaks
  /// and releases any system resources associated with audio playback.
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> checkUserPremium() async {
    InAppPurchaseService iap = InAppPurchaseService();
    bool isP = await iap.isPremium();
    setState(() {
      isUserPremium = isP;
    });
  }

  /// Navigates to the previous podcast in the playlist.
  ///
  /// This method:
  /// 1. Checks if there's a previous podcast available
  /// 2. Updates the current podcast and index
  /// 3. Stops current playback and loads the new podcast
  /// 4. Updates the UI to reflect the new podcast
  ///
  /// **Behavior:**
  /// - If at the first podcast (index 0), wraps around to the last podcast
  /// - Automatically starts playing the new podcast
  /// - Updates all UI elements with new podcast information
  void _playPrevious() async {
    if (widget.podcastList.isEmpty) return;

    final newIndex = currentIndex > 0
        ? currentIndex - 1
        : widget.podcastList.length - 1;

    await _switchToPodcast(newIndex);
  }

  /// Navigates to the next podcast in the playlist.
  ///
  /// This method:
  /// 1. Checks if there's a next podcast available
  /// 2. Updates the current podcast and index
  /// 3. Stops current playback and loads the new podcast
  /// 4. Updates the UI to reflect the new podcast
  ///
  /// **Behavior:**
  /// - If at the last podcast, wraps around to the first podcast
  /// - Automatically starts playing the new podcast
  /// - Updates all UI elements with new podcast information
  void _playNext() async {
    if (widget.podcastList.isEmpty) return;

    final newIndex = currentIndex < widget.podcastList.length - 1
        ? currentIndex + 1
        : 0;

    await _switchToPodcast(newIndex);
  }

  /// Switches to a specific podcast in the playlist.
  ///
  /// **Parameters:**
  /// - [newIndex]: The index of the podcast to switch to
  ///
  /// **Process:**
  /// 1. Stops current playback
  /// 2. Updates current podcast and index
  /// 3. Loads new audio URL
  /// 4. Starts playback of new podcast
  /// 5. Updates UI state
  ///
  /// **Error Handling:**
  /// - Displays error message if podcast loading fails
  /// - Safely handles widget disposal during async operations
  Future<void> _switchToPodcast(int newIndex) async {
    try {
      // Stop current playback
      await _player.stop();

      // Update current podcast and index
      setState(() {
        currentIndex = newIndex;
        currentPodcast = widget.podcastList[newIndex];
      });

      // Load new podcast
      await _player.setUrl(currentPodcast.audioUrl);

      // Start playing
      if (isUserPremium) {
        await _player.play();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load podcast: $e')));
    }
  }

  /// Checks if there's a previous podcast available in the playlist.
  ///
  /// **Returns:**
  /// - bool: true if previous podcast exists or playlist loops, false otherwise
  bool get _hasPrevious => widget.podcastList.isNotEmpty;

  /// Checks if there's a next podcast available in the playlist.
  ///
  /// **Returns:**
  /// - bool: true if next podcast exists or playlist loops, false otherwise
  bool get _hasNext => widget.podcastList.isNotEmpty;

  /// Builds the podcast player UI with all interactive controls and display elements.
  ///
  /// **UI Components:**
  /// - AppBar with podcast title and back navigation
  /// - Large podcast cover image (cached network image)
  /// - Podcast description text
  /// - Audio progress slider with real-time position updates
  /// - Time display (current position / total duration)
  /// - Play/pause button with dynamic icon
  /// - Playback speed control options
  /// - Loop toggle functionality
  ///
  /// **Real-time Updates:**
  /// - Uses StreamBuilder widgets to listen to audio player streams
  /// - Updates UI automatically when playback state changes
  /// - Handles duration and position changes smoothly
  ///
  /// **Parameters:**
  /// - [context]: The build context for this widget
  ///
  /// **Returns:**
  /// - Widget: A Scaffold containing the complete podcast player interface
  @override
  Widget build(BuildContext context) {
    final p = currentPodcast;
    double height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          p.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.pink500,
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous podcast button
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    size: 36,
                    color: _hasPrevious
                        ? Colors.pink.shade500
                        : Colors.grey.shade400,
                  ),
                  onPressed: _hasPrevious ? _playPrevious : null,
                ),

                // 10 seconds backward
                IconButton(
                  icon: Icon(
                    Icons.replay_10,
                    size: 32,
                    color: Colors.pink.shade500,
                  ),
                  onPressed: _skipBackward,
                ),

                // Play/Pause button
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 64,
                    color: Colors.pink.shade500,
                  ),
                  onPressed: togglePlay,
                ),

                // 10 seconds forward
                IconButton(
                  icon: Icon(
                    Icons.forward_10,
                    size: 32,
                    color: Colors.pink.shade500,
                  ),
                  onPressed: _skipForward,
                ),

                // Next podcast button
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    size: 36,
                    color: _hasNext
                        ? Colors.pink.shade500
                        : Colors.grey.shade400,
                  ),
                  onPressed: _hasNext ? _playNext : null,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "These podcasts are for informational purposes only. For comprehensive information, please consult the original sources. Our summaries don't replace professional medical advice. We credit all original authors and encourage supporting their work.",
                style: TextStyle(fontSize: 9, height: 1),
              ),
            ),
            SizedBox(height: 4),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: p.icon,
                height: height * 0.3, // Reduced from 2/5 (0.4) to 0.25

                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              p.description,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // --- Slider ve süreler StreamBuilder ile ---
            StreamBuilder<Duration?>(
              stream: _player.durationStream,
              builder: (context, durationSnap) {
                final total = durationSnap.data ?? Duration.zero;
                final max = total.inMilliseconds > 0
                    ? total.inMilliseconds.toDouble()
                    : 0.0;

                return StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  initialData: Duration.zero,
                  builder: (context, positionSnap) {
                    final pos = positionSnap.data ?? Duration.zero;
                    double value = pos.inMilliseconds.toDouble();

                    // Guard: NaN/∞/max aşımı vb.
                    if (value.isNaN || value.isInfinite) value = 0.0;
                    if (max > 0.0 && value > max) value = max;
                    if (max == 0.0) value = 0.0;

                    return Column(
                      children: [
                        Slider(
                          min: 0.0,
                          max: max,
                          value: value,
                          onChanged: (v) {
                            // Drag esnasında anında seek
                            _player.seek(Duration(milliseconds: v.toInt()));
                          },
                          activeColor: Colors.pink.shade500,
                        ),
                        Text(
                          "${_fmt(pos)} / ${_fmt(total)}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 8),

            // Playback speed control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.speed, color: Colors.grey),
                const SizedBox(width: 8),
                DropdownButton<double>(
                  value: playbackSpeed,
                  items: speedOptions.map((speed) {
                    return DropdownMenuItem<double>(
                      value: speed,
                      child: Text(
                        "${speed}x",
                        style: TextStyle(
                          color: Colors.pink.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newSpeed) {
                    if (newSpeed != null) {
                      _changePlaybackSpeed(newSpeed);
                    }
                  },
                  underline: Container(),
                  dropdownColor: Colors.white,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.pink.shade500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "Creator: ",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Expanded(child: Text(p.creator)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text("Source: ", style: TextStyle(fontWeight: FontWeight.w600)),

                if (p.source.contains("http")) ...[
                  TextButton(
                    onPressed: () {
                      if (_player.playing) {
                        _player.pause();
                      }
                      launchUrl(Uri.parse(p.source));
                    },
                    child: Text(
                      p.source,
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ] else ...[
                  Expanded(child: Text(p.source, maxLines: 1)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a Duration object into a human-readable time string.
  ///
  /// **Parameters:**
  /// - [d]: The Duration to format
  ///
  /// **Returns:**
  /// - String in format "mm:ss" for durations under 1 hour
  /// - String in format "h:mm:ss" for durations 1 hour or longer
  ///
  /// **Examples:**
  /// ```dart
  /// _fmt(Duration(minutes: 5, seconds: 30))  // Returns "05:30"
  /// _fmt(Duration(hours: 1, minutes: 23, seconds: 45))  // Returns "1:23:45"
  /// ```
  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    // Return hh:mm:ss if hours exist, otherwise mm:ss
    return h > 0 ? "$h:$m:$s" : "$m:$s";
  }

  /// Initializes the audio player with the podcast's audio URL.
  ///
  /// This method attempts to load the audio file from the provided URL and handles
  /// any errors that may occur during the loading process.
  ///
  /// **Error Handling:**
  /// - Displays a SnackBar with error message if audio loading fails
  /// - Safely handles widget disposal during async operation
  ///
  /// **Returns:**
  /// - Future<void> that completes when audio initialization is finished
  ///
  /// **Throws:**
  /// - Catches and handles all exceptions internally, displaying user-friendly error messages
  Future<void> _initAudio() async {
    try {
      await _player.setUrl(currentPodcast.audioUrl);
      // İstersen burada duration’a erişebilirsin:
      // final dur = _player.duration; // null olabilir
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ses yüklenemedi: $e')));
    }
  }

  /// Toggles the audio playback state between playing and paused.
  ///
  /// This method checks the current playing state and switches to the opposite:
  /// - If currently playing, pauses the audio
  /// - If currently paused, starts/resumes playback
  ///
  /// **State Management:**
  /// - The `isPlaying` state is automatically updated via the `playingStream` listener
  /// - No manual state updates are needed in this method
  ///
  /// **Usage:**
  /// Called when the user taps the play/pause button in the UI
  Future<void> togglePlay() async {
    if (isUserPremium) {
      if (_player.playing) {
        _player.pause();
      } else {
        _player.play();
      }
    } else {
      await Navigator.pushNamed(context, AppRoutes.premiumPaywall).then((
        v,
      ) async {
        if (v != null && v == true) {
          await checkUserPremium();
        }
      });
    }
  }

  /// Changes the playback speed of the audio player.
  ///
  /// **Parameters:**
  /// - [speed]: The new playback speed multiplier (e.g., 1.0 = normal, 1.5 = 1.5x speed, 2.0 = double speed)
  ///
  /// **Behavior:**
  /// - Updates the audio player's playback speed
  /// - Updates the local `playbackSpeed` state for UI consistency
  /// - Handles errors gracefully with user feedback
  ///
  /// **Error Handling:**
  /// - Displays a SnackBar if speed change fails
  /// - Safely handles widget disposal during async operation
  ///
  /// **Example:**
  /// ```dart
  /// _changePlaybackSpeed(1.5); // Set to 1.5x speed
  /// ```
  void _changePlaybackSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
      setState(() {
        playbackSpeed = speed;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Speed could not be changed: $e')));
    }
  }

  /// Skips backward by 10 seconds in the audio playback.
  ///
  /// This method gets the current position and seeks to 10 seconds earlier.
  /// If the current position is less than 10 seconds, it seeks to the beginning (0:00).
  ///
  /// **Behavior:**
  /// - Current position >= 10s: Seeks to (current - 10s)
  /// - Current position < 10s: Seeks to 0:00
  void _skipBackward() async {
    final currentPosition = _player.position;
    final newPosition = currentPosition - const Duration(seconds: 10);

    // Don't go below 0
    final seekPosition = newPosition.isNegative ? Duration.zero : newPosition;

    try {
      await _player.seek(seekPosition);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Geri sarma başarısız: $e')));
    }
  }

  /// Skips forward by 10 seconds in the audio playback.
  ///
  /// This method gets the current position and seeks to 10 seconds later.
  /// If the new position would exceed the total duration, it seeks to the end.
  ///
  /// **Behavior:**
  /// - New position <= total duration: Seeks to (current + 10s)
  /// - New position > total duration: Seeks to end of audio
  void _skipForward() async {
    final currentPosition = _player.position;
    final duration = _player.duration;

    if (duration == null) return; // Can't skip if duration is unknown

    final newPosition = currentPosition + const Duration(seconds: 10);

    // Don't go beyond the total duration
    final seekPosition = newPosition > duration ? duration : newPosition;

    try {
      await _player.seek(seekPosition);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('İleri sarma başarısız: $e')));
    }
  }
}
