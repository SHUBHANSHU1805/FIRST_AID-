import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class PanicScreen extends StatefulWidget {
  const PanicScreen({super.key});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────
  bool _isActivated = false;
  bool _isFetchingLocation = false;
  bool _isCancelled = false;
  int _countdown = 5;
  String _statusMessage = "Press & hold to activate";
  String? _locationUrl;

  // ── Animation Controllers ──────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnim;
  late Animation<double> _rippleAnim;

  // ── Emergency Contacts (edit these) ───────────────────────
  final List<String> _emergencyContacts = [
    "+917541806959", // replace with real numbers
    "+918299557357",
  ];
  final String _ambulanceNumber = "108"; // India ambulance

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleAnim = Tween<double>(begin: 0.8, end: 1.6).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Start Panic Sequence ───────────────────────────────────
  void _startPanicSequence() {
    if (_isActivated) return;

    setState(() {
      _isActivated = true;
      _isCancelled = false;
      _countdown = 5;
      _statusMessage = "Sending alert in $_countdown seconds...";
    });

    _rippleController.repeat();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCancelled) {
        timer.cancel();
        _rippleController.stop();
        setState(() {
          _isActivated = false;
          _statusMessage = "Press & hold to activate";
          _countdown = 5;
        });
        return;
      }

      setState(() => _countdown--);

      if (_countdown <= 0) {
        timer.cancel();
        _triggerAlert();
      } else {
        setState(() {
          _statusMessage = "Sending alert in $_countdown seconds...";
        });
      }
    });
  }

  // ── Cancel Panic ──────────────────────────────────────────
  void _cancelPanic() {
    setState(() => _isCancelled = true);
    _showSnack("✅ Alert cancelled");
  }

  // ── Trigger Alert ─────────────────────────────────────────
  Future<void> _triggerAlert() async {
    setState(() {
      _isFetchingLocation = true;
      _statusMessage = "Fetching your location...";
    });

    final position = await _getLocation();

    if (position != null) {
      _locationUrl =
          "https://maps.google.com/?q=${position.latitude},${position.longitude}";
    }

    setState(() {
      _isFetchingLocation = false;
      _statusMessage = "🚨 ALERT SENT — Help is on the way!";
    });

    // Send WhatsApp alerts to all contacts
    for (final contact in _emergencyContacts) {
      await _sendWhatsApp(contact);
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  // ── Get GPS Location ──────────────────────────────────────
  Future<Position?> _getLocation() async {
    try {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        _showSnack("Location permission denied");
        return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack("Please enable location services");
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      _showSnack("Could not fetch location");
      return null;
    }
  }

  // ── Send WhatsApp Alert ───────────────────────────────────
  Future<void> _sendWhatsApp(String phone) async {
    final message = _locationUrl != null
        ? "🚨 EMERGENCY ALERT!\n\nI need immediate help!\n\n📍 My Location:\n$_locationUrl\n\nPlease call me or send help immediately!\n\n— Sent via FirstAid+"
        : "🚨 EMERGENCY ALERT!\n\nI need immediate help! Please call me immediately!\n\n— Sent via FirstAid+";

    final cleanPhone = phone.replaceAll("+", "").replaceAll(" ", "");
    final encodedMessage = Uri.encodeComponent(message);
    final url = "https://wa.me/$cleanPhone?text=$encodedMessage";

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnack("Could not open WhatsApp for $phone");
    }
  }

  // ── Call Ambulance ────────────────────────────────────────
 Future<void> _callAmbulance() async {
  final status = await Permission.phone.request();
  if (status.isGranted) {
    final url = "tel:$_ambulanceNumber";
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      _showSnack("Could not place call");
    }
  } else {
    _showSnack("Call permission denied");
  }
}

  // ── Share Location Manually ───────────────────────────────
  Future<void> _shareLocation() async {
    setState(() => _statusMessage = "Fetching location...");
    final position = await _getLocation();

    if (position != null) {
      final url =
          "https://maps.google.com/?q=${position.latitude},${position.longitude}";
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {
        _showSnack("Could not open maps");
      }
    }

    setState(() => _statusMessage =
        _isActivated ? "🚨 ALERT SENT — Help is on the way!" : "Press & hold to activate");
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -60,
            left: -60,
            child: _buildGlow(const Color(0xFFEF4444), 260),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: _buildGlow(const Color(0xFF6366F1), 200),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Top Bar ──────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E1628),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white12, width: 0.8),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white70, size: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Panic Alert",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // ── Status Message ────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _statusMessage,
                      key: ValueKey(_statusMessage),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isActivated
                            ? const Color(0xFFEF4444)
                            : Colors.white54,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Panic Button ──────────────────────────
                  AnimatedBuilder(
                    animation:
                        Listenable.merge([_pulseAnim, _rippleAnim]),
                    builder: (_, __) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple rings (only when activated)
                          if (_isActivated) ...[
                            _buildRipple(
                                _rippleAnim.value * 130, 0.08),
                            _buildRipple(
                                _rippleAnim.value * 110, 0.12),
                          ],

                          // Main button
                          Transform.scale(
                            scale: _isActivated
                                ? 1.0
                                : _pulseAnim.value,
                            child: GestureDetector(
                              onLongPress: _startPanicSequence,
                              onTap: _isActivated
                                  ? null
                                  : () => _showSnack(
                                      "Hold the button to activate"),
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: _isActivated
                                        ? [
                                            const Color(0xFFFF1A1A),
                                            const Color(0xFFDC2626),
                                          ]
                                        : [
                                            const Color(0xFFEF4444),
                                            const Color(0xFFB91C1C),
                                          ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: _isActivated ? 0.7 : 0.4),
                                      blurRadius:
                                          _isActivated ? 60 : 30,
                                      spreadRadius:
                                          _isActivated ? 10 : 4,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isActivated
                                          ? Icons.warning_rounded
                                          : Icons.warning_amber_rounded,
                                      color: Colors.white,
                                      size: 52,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isActivated
                                          ? (_isFetchingLocation
                                              ? "LOCATING..."
                                              : _countdown > 0
                                                  ? "$_countdown"
                                                  : "ACTIVE")
                                          : "HOLD",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      _isActivated ? "" : "TO ACTIVATE",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 40),
// ── Cancel Button (only when counting down) ──
                  // ── Cancel Button (only when counting down) ──
                  if (_isActivated && _countdown > 0)
                    GestureDetector(
                      onTap: _cancelPanic,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white24, width: 1),
                          color: const Color(0xFF0E1628),
                        ),
                        child: const Text(
                          "CANCEL",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                  // ── Deactivate Button (only after alert sent) ──
                  if (_isActivated && _countdown <= 0)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isActivated = false;
                          _statusMessage = "Press & hold to activate";
                          _countdown = 5;
                        });
                        _rippleController.stop();
                        _rippleController.reset();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 1),
                          color: const Color(0xFF0E1628),
                        ),
                        child: const Text(
                          "DEACTIVATE",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 50),

                  // ── Quick Action Cards ────────────────────
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Quick Actions",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.phone_rounded,
                          label: "Call\nAmbulance",
                          accent: const Color(0xFF22C55E),
                          onTap: _callAmbulance,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.location_on_rounded,
                          label: "Share\nLocation",
                          accent: const Color(0xFF3B82F6),
                          onTap: _shareLocation,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.message_rounded,
                          label: "WhatsApp\nAlert",
                          accent: const Color(0xFF25D366),
                          onTap: () async {
                            if (_emergencyContacts.isNotEmpty) {
                              await _sendWhatsApp(
                                  _emergencyContacts.first);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Info Box ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: const Color(0xFF0E1628),
                      border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Hold the panic button for 1 second to start a 5-second countdown. You can cancel anytime before it sends.",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRipple(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: size * 0.9,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Card Widget ───────────────────────────────────
class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF0E1628),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(widget.icon, color: widget.accent, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}