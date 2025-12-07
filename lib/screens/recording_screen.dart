import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:the_cases/screens/report_view_screen.dart';
import 'package:the_cases/services/api_service.dart';

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});
  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen>
    with SingleTickerProviderStateMixin {
  // We use late initialization but create it in initState to be safe
  late final AudioRecorder _recorder;

  // States
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isLoading = false;
  bool _hasRecordedData = false;

  String? _path;
  int _seconds = 0;
  Timer? _timer;

  late AnimationController _animCtrl;
  double _amplitude = 0.0;
  Timer? _ampTimer;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder(); // Initialize here
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _init();
  }

  Future<void> _init() async {
    await Permission.microphone.request();
  }

  // --- CONTROLLER LOGIC ---

  Future<void> _start() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path =
            '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Start recording
        await _recorder.start(const RecordConfig(), path: path);

        if (!mounted) return;

        setState(() {
          _isRecording = true;
          _isPaused = false;
          _hasRecordedData = true;
        });

        _animCtrl.repeat();
        _startTimers();
      }
    } catch (e) {
      debugPrint("Start Error: $e");
    }
  }

  Future<void> _pause() async {
    try {
      await _recorder.pause();
      _timer?.cancel();
      _animCtrl.stop();
      if (mounted) setState(() => _isPaused = true);
    } catch (e) {
      debugPrint("Pause Error: $e");
    }
  }

  Future<void> _resume() async {
    try {
      await _recorder.resume();
      _animCtrl.repeat();
      _startTimers();
      if (mounted) setState(() => _isPaused = false);
    } catch (e) {
      debugPrint("Resume Error: $e");
    }
  }

  Future<void> _stopAndProcess() async {
    _stopTimers(); // Stop UI updates immediately
    _animCtrl.stop();

    try {
      if (_isRecording) {
        _path = await _recorder.stop();
      }
    } catch (e) {
      debugPrint("Stop Error: $e");
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _amplitude = 0;
      });
    }

    if (_path != null) {
      _process();
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _recorder.stop();
    } catch (e) {
      // Ignore error if already stopped
    }

    // Clean up file
    if (_path != null) {
      final file = File(_path!);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    _stopTimers();
    _animCtrl.stop();
    _animCtrl.reset();

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _hasRecordedData = false;
        _seconds = 0;
        _path = null;
        _amplitude = 0;
      });
    }
  }

  void _startTimers() {
    _timer?.cancel();
    _ampTimer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });

    _ampTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
      if (!mounted || _isPaused || !_isRecording) return;
      try {
        final amp = await _recorder.getAmplitude();
        double norm = (amp.current + 60) / 60;
        if (norm < 0.1) norm = 0;
        if (mounted) setState(() => _amplitude = norm.clamp(0, 1));
      } catch (e) {
        // Silent catch: recorder might be disposing
      }
    });
  }

  void _stopTimers() {
    _timer?.cancel();
    _ampTimer?.cancel();
  }

  void _process() async {
    if (_path == null) return;
    setState(() => _isLoading = true);
    try {
      final medicalCase = await AiService.generateCaseReport(_path!);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CaseViewerScreen(medicalCase: medicalCase),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // 1. STOP TIMERS FIRST to prevent async callbacks
    _timer?.cancel();
    _ampTimer?.cancel();

    // 2. DISPOSE ANIMATION
    _animCtrl.dispose();

    // 3. DISPOSE RECORDER LAST
    _recorder.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    Color stateColor = primaryColor;
    String statusText = "READY";
    IconData statusIcon = LucideIcons.mic;

    if (_isRecording) {
      if (_isPaused) {
        stateColor = Colors.amber;
        statusText = "PAUSED ||";
        statusIcon = LucideIcons.pause;
      } else {
        stateColor = Colors.red;
        statusText = "REC ●";
        statusIcon = LucideIcons.circleDot;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(color: theme.dividerColor.withOpacity(0.05)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: () {
                          if (_isRecording) _cancelRecording();
                          Navigator.pop(context);
                        },
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: stateColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: stateColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: stateColor),
                            const SizedBox(width: 8),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: stateColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(),

                Text(
                  _formatTime(_seconds),
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w200,
                    color: _isRecording
                        ? stateColor
                        : theme.colorScheme.onSurface,
                    letterSpacing: -2,
                    fontFamily: 'monospace',
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.05),
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: stateColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: EcgPainter(
                        progress: _animCtrl.value,
                        amplitude: _amplitude,
                        isActive: _isRecording && !_isPaused,
                        color: stateColor,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                if (_isLoading)
                  _buildLoadingView(theme)
                else
                  _buildControlBar(theme, stateColor),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Column(
      children: [
        CircularProgressIndicator(color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text("Processing Consultation...", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          "Translating & Summarizing...",
          style: TextStyle(color: theme.colorScheme.secondary),
        ),
      ],
    );
  }

  Widget _buildControlBar(ThemeData theme, Color stateColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_hasRecordedData)
            IconButton.filledTonal(
              onPressed: _cancelRecording,
              icon: const Icon(LucideIcons.trash2),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                foregroundColor: theme.colorScheme.error,
                padding: const EdgeInsets.all(16),
              ),
            )
          else
            const SizedBox(width: 56),

          GestureDetector(
            onTap: () {
              if (!_isRecording) {
                _start();
              } else if (_isPaused) {
                _resume();
              } else {
                _pause();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                color: stateColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: stateColor.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                !_isRecording
                    ? LucideIcons.mic
                    : (_isPaused ? LucideIcons.play : LucideIcons.pause),
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          if (_hasRecordedData)
            IconButton.filled(
              onPressed: _stopAndProcess,
              icon: const Icon(LucideIcons.check, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            )
          else
            const SizedBox(width: 56),
        ],
      ),
    );
  }

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class EcgPainter extends CustomPainter {
  final double progress, amplitude;
  final bool isActive;
  final Color color;
  EcgPainter({
    required this.progress,
    required this.amplitude,
    required this.isActive,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mid = size.height / 2;

    if (!isActive) {
      canvas.drawLine(
        Offset(0, mid),
        Offset(size.width, mid),
        paint..color = color.withOpacity(0.5),
      );
      return;
    }

    double h = amplitude * 80;
    final pts = [
      0.0,
      0.0,
      -10.0,
      50.0,
      -20.0,
      10.0,
      0.0,
      0.0,
    ].map((e) => e * (h / 50)).toList();

    double x = -progress * 200;
    final path = Path();
    path.moveTo(x, mid);
    while (x < size.width) {
      path.lineTo(x + 20, mid);
      path.lineTo(x + 30, mid + pts[2]);
      path.lineTo(x + 40, mid - pts[3]);
      path.lineTo(x + 50, mid + pts[4]);
      path.lineTo(x + 70, mid);
      path.lineTo(x + 200, mid);
      x += 200;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant EcgPainter old) =>
      old.progress != progress ||
      old.amplitude != amplitude ||
      old.isActive != isActive;
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 40)
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += 40)
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
