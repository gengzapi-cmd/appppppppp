import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppStage { splash, mainApp }

class SnapCatAppScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const SnapCatAppScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<SnapCatAppScreen> createState() => _SnapCatAppScreenState();
}

class _SnapCatAppScreenState extends State<SnapCatAppScreen>
    with TickerProviderStateMixin {
  AppStage _stage = AppStage.splash;
  int _splashStep = 0;
  int _activeTab = 0; // 0: Home, 1: Downloads, 2: Settings

  // Controllers for Splash & Onboarding
  late AnimationController _wheelRotationController;
  late AnimationController _circleZoomController;
  late Animation<double> _circleScaleAnimation;

  // Search Input Controller
  final TextEditingController _linkInputController = TextEditingController();
  bool _hasSearched = false;
  String _searchedUrl = "";

  // Modals state
  bool _showHistoryModal = false;
  bool _showAddonModal = false;

  // Toast Notification state
  String? _toastMessage;
  bool _toastIsError = false;

  // EXACT 1:1 Splash Slides Data dari index.html
  final List<Map<String, String>> _splashSlidesData = [
    {
      "tag": "TUTORIAL",
      "title": "Salin Tautan",
      "subtitle":
          "Temukan video di platform favorit anda, klik bagikan lalu klik salin tautan",
    },
    {
      "tag": "TUTORIAL",
      "title": "Tempel Tautan",
      "subtitle": "Tempel tautan yang anda salin ke input tautan SnapCat",
    },
    {
      "tag": "TUTORIAL",
      "title": "Cari & Unduh",
      "subtitle": "Klik tombol cari, lihat pratinjau, pilih resolusi dan unduh",
    },
    {
      "tag": "SNAPCAT",
      "title": "Unduh apa saja",
      "subtitle":
          "Salin, tempel, cari, pilih resolusi dan simpan, that simple bro",
    },
  ];

  @override
  void initState() {
    super.initState();

    _wheelRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _circleZoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _circleScaleAnimation = Tween<double>(begin: 1.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _circleZoomController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _wheelRotationController.dispose();
    _circleZoomController.dispose();
    _linkInputController.dispose();
    super.dispose();
  }

  void _nextSplashStep() {
    if (_splashStep < _splashSlidesData.length - 1) {
      setState(() {
        _splashStep++;
      });
      _wheelRotationController.forward(from: 0.0);
    } else {
      _finishSplash();
    }
  }

  void _goToSplashStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < _splashSlidesData.length) {
      setState(() {
        _splashStep = stepIndex;
      });
      _wheelRotationController.forward(from: 0.0);
    }
  }

  void _finishSplash() {
    _circleZoomController.forward().then((_) {
      setState(() {
        _stage = AppStage.mainApp;
      });
    });
  }

  void _showToast(String message, {bool isError = false}) {
    setState(() {
      _toastMessage = message;
      _toastIsError = isError;
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  void _triggerDownload() {
    String text = _linkInputController.text.trim();
    if (text.isEmpty) {
      _showToast("Tautan kosong", isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _searchedUrl = text;
      _hasSearched = true;
    });
    _showToast("Tautan ditemukan");
  }

  void _pasteFromClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      _linkInputController.text = data.text!;
      _showToast("Tautan disalin ke papan klip");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          if (_stage == AppStage.splash) _buildSplashScreen(),
          if (_stage == AppStage.mainApp) _buildMainAppScreen(),
          if (_toastMessage != null) _buildToastNotification(),
        ],
      ),
    );
  }

  // ========================================================
  // 1. SPLASH SCREEN (EXACT 4 CARDINAL SVG LOGO WHEEL)
  // ========================================================
  Widget _buildSplashScreen() {
    final step = _splashSlidesData[_splashStep];
    final bool isLastStep = _splashStep == _splashSlidesData.length - 1;
    final double targetTurns = -0.25 * _splashStep;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mesh Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: CustomPaint(painter: GridMeshPainter()),
            ),
          ),

          // White Circle Bottom Wheel
          AnimatedBuilder(
            animation: _circleScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _circleScaleAnimation.value,
                child: Positioned(
                  bottom: -340,
                  child: RotationTransition(
                    turns: Tween<double>(
                      begin: targetTurns,
                      end: targetTurns,
                    ).animate(_wheelRotationController),
                    child: Container(
                      width: 680,
                      height: 680,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 40,
                            offset: const Offset(0, -12),
                          )
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Top Point: Share SVG Icon
                          _buildCircleLogoPoint(
                            Alignment.topCenter,
                            targetTurns,
                            CustomPaint(
                              size: const Size(40, 40),
                              painter: ShareCardinalSvgPainter(),
                            ),
                          ),
                          // Right Point: Clipboard SVG Icon
                          _buildCircleLogoPoint(
                            Alignment.centerRight,
                            targetTurns,
                            CustomPaint(
                              size: const Size(40, 40),
                              painter: ClipboardCardinalSvgPainter(),
                            ),
                          ),
                          // Bottom Point: Search SVG Icon
                          _buildCircleLogoPoint(
                            Alignment.bottomCenter,
                            targetTurns,
                            CustomPaint(
                              size: const Size(40, 40),
                              painter: SearchCardinalSvgPainter(),
                            ),
                          ),
                          // Left Point: Fast Forward Play SVG Icon
                          _buildCircleLogoPoint(
                            Alignment.centerLeft,
                            targetTurns,
                            CustomPaint(
                              size: const Size(42, 42),
                              painter: FastForwardCardinalSvgPainter(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Splash Text Wrapper
          Positioned(
            bottom: 122,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    step["tag"]!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  step["title"]!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  step["subtitle"]!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Splash Dots Container
          Positioned(
            bottom: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_splashSlidesData.length, (index) {
                bool active = index == _splashStep;
                return GestureDetector(
                  onTap: () => _goToSplashStep(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Action Button
          Positioned(
            bottom: 55,
            child: GestureDetector(
              onTap: _nextSplashStep,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                width: isLastStep ? 220 : 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(isLastStep ? 20 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Center(
                  child: isLastStep
                      ? const Text(
                          "Mulai Sekarang",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleLogoPoint(
    Alignment alignment,
    double wheelTurns,
    Widget iconWidget,
  ) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          border: Border.all(color: Colors.white, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.45),
              blurRadius: 28,
              offset: const Offset(0, 10),
            )
          ],
        ),
        // Counter-rotate inner icon so it stays upright facing user
        child: RotationTransition(
          turns: AlwaysStoppedAnimation(-wheelTurns),
          child: Center(child: iconWidget),
        ),
      ),
    );
  }

  // ========================================================
  // 2. MAIN APP SCREEN (3 NAV TABS WITH EXACT SVG ICONS)
  // ========================================================
  Widget _buildMainAppScreen() {
    return Container(
      color: widget.isDarkMode
          ? const Color(0xFF090D16)
          : const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          Column(
            children: [
              _buildTopRedHeaderBanner(),

              Expanded(
                child: IndexedStack(
                  index: _activeTab,
                  children: [
                    _buildHomeTabPage(),
                    _buildDownloadTabPage(),
                    _buildSettingsTabPage(),
                  ],
                ),
              ),
            ],
          ),

          // Floating Navigation Dock (3 TABS WITH SVG ICONS)
          Positioned(
            bottom: 20,
            left: 24,
            right: 24,
            child: _buildFloatingNavDock(),
          ),

          if (_showHistoryModal) _buildHistoryModal(),
          if (_showAddonModal) _buildAddonModal(),
        ],
      ),
    );
  }

  Widget _buildTopRedHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "SnapCat",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      widget.isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: Colors.white,
                    ),
                    onPressed: widget.onToggleTheme,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showHistoryModal = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Color(0xFF111827),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _linkInputController,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _triggerDownload(),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.content_paste_rounded,
                    color: Color(0xFF6B7280),
                    size: 18,
                  ),
                  onPressed: _pasteFromClipboard,
                ),
                GestureDetector(
                  onTap: _triggerDownload,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 0: HOME TAB ====================
  Widget _buildHomeTabPage() {
    final bool isDark = widget.isDarkMode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Row(
          children: [
            _buildSocialItem("TikTok", Icons.music_note_rounded, Colors.black),
            const SizedBox(width: 12),
            _buildSocialItem("YouTube", Icons.play_arrow_rounded, const Color(0xFFFF0000)),
          ],
        ),
        const SizedBox(height: 28),

        if (_hasSearched && _searchedUrl.isNotEmpty)
          _buildPreviewCard(isDark),
      ],
    );
  }

  Widget _buildSocialItem(String name, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isDarkMode
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              SizedBox(width: 8),
              Text(
                "Tautan Ditemukan",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _searchedUrl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 1: DOWNLOADS TAB ====================
  Widget _buildDownloadTabPage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        children: [
          Row(
            children: [
              _buildFilterPill("Semua", "0", true),
              const SizedBox(width: 8),
              _buildFilterPill("Selesai", "0", false),
              const SizedBox(width: 8),
              _buildFilterPill("Gagal", "0", false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, String count, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFEF4444)
            : (widget.isDarkMode
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : (widget.isDarkMode
                      ? Colors.white70
                      : const Color(0xFF4B5563)),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active
                    ? Colors.white
                    : (widget.isDarkMode
                        ? Colors.white70
                        : const Color(0xFF4B5563)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: SETTINGS TAB ====================
  Widget _buildSettingsTabPage() {
    final bool isDark = widget.isDarkMode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        _buildSettingsRowItem(
          iconWidget: CustomPaint(
            size: const Size(20, 20),
            painter: SettingsSvgPainter(color: const Color(0xFFEF4444)),
          ),
          title: "Mode Gelap",
          trailing: Switch(
            value: isDark,
            onChanged: (_) => widget.onToggleTheme(),
            activeColor: const Color(0xFFEF4444),
          ),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildSettingsRowItem(
          iconWidget: const Icon(Icons.extension_rounded, color: Color(0xFFEF4444), size: 20),
          title: "Toko Add-on",
          onTap: () {
            setState(() {
              _showAddonModal = true;
            });
          },
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSettingsRowItem({
    required Widget iconWidget,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // ==================== FLOATING NAVIGATION DOCK (3 TABS WITH SVG ICONS) ====================
  Widget _buildFloatingNavDock() {
    final bool isDark = widget.isDarkMode;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavDockItem(
            0,
            (color) => CustomPaint(
              size: const Size(22, 22),
              painter: HomeSvgPainter(color: color),
            ),
            "Home",
          ),
          _buildNavDockItem(
            1,
            (color) => CustomPaint(
              size: const Size(20, 20),
              painter: DownloadSvgPainter(color: color),
            ),
            "Unduhan",
          ),
          _buildNavDockItem(
            2,
            (color) => CustomPaint(
              size: const Size(22, 22),
              painter: SettingsSvgPainter(color: color),
            ),
            "Pengaturan",
          ),
        ],
      ),
    );
  }

  Widget _buildNavDockItem(
    int index,
    Widget Function(Color color) iconBuilder,
    String label,
  ) {
    bool active = _activeTab == index;
    Color iconColor = active ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF);

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFEF4444).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            iconBuilder(iconColor),
            if (active) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // ==================== HISTORY MODAL ====================
  Widget _buildHistoryModal() {
    final bool isDark = widget.isDarkMode;

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showHistoryModal = false;
            });
          },
          child: Container(
            color: Colors.black54,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      setState(() {
                        _showHistoryModal = false;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== ADD-ON STORE MODAL ====================
  Widget _buildAddonModal() {
    final bool isDark = widget.isDarkMode;

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showAddonModal = false;
            });
          },
          child: Container(
            color: Colors.black54,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      setState(() {
                        _showAddonModal = false;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== TOAST NOTIFICATION ====================
  Widget _buildToastNotification() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _toastIsError
                ? const Color(0xFFEF4444)
                : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(
                _toastIsError
                    ? Icons.error_outline_rounded
                    : Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _toastMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================================
// 4 CARDINAL POINT SVG PAINTERS FOR ONBOARDING WHEEL
// ========================================================

// 1. Share Cardinal SVG (Top Point in index.html)
class ShareCardinalSvgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.scale(size.width / 24.0, size.height / 24.0);

    canvas.drawCircle(const Offset(18, 5), 3, strokePaint);
    canvas.drawCircle(const Offset(6, 12), 3, strokePaint);
    canvas.drawCircle(const Offset(18, 19), 3, strokePaint);

    canvas.drawLine(const Offset(8.59, 13.51), const Offset(15.42, 17.49), strokePaint);
    canvas.drawLine(const Offset(15.41, 6.51), const Offset(8.59, 10.49), strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Clipboard Cardinal SVG (Right Point in index.html)
class ClipboardCardinalSvgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.scale(size.width / 24.0, size.height / 24.0);

    final path = Path()
      ..moveTo(16, 4)
      ..lineTo(18, 4)
      ..relativeArcToPoint(const Offset(2, 2), radius: const Radius.circular(2))
      ..lineTo(20, 20)
      ..relativeArcToPoint(const Offset(-2, 2), radius: const Radius.circular(2))
      ..lineTo(6, 22)
      ..relativeArcToPoint(const Offset(-2, -2), radius: const Radius.circular(2))
      ..lineTo(4, 6)
      ..relativeArcToPoint(const Offset(2, -2), radius: const Radius.circular(2))
      ..lineTo(8, 4);
    canvas.drawPath(path, strokePaint);

    final rectPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 2, 8, 4),
        const Radius.circular(1),
      ));
    canvas.drawPath(rectPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Search Cardinal SVG (Bottom Point in index.html)
class SearchCardinalSvgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.scale(size.width / 24.0, size.height / 24.0);

    canvas.drawCircle(const Offset(11, 11), 8, strokePaint);
    canvas.drawLine(const Offset(21, 21), const Offset(16.65, 16.65), strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. Fast Forward Play Cardinal SVG (Left Point in index.html)
class FastForwardCardinalSvgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.scale(size.width / 24.0, size.height / 24.0);

    final path1 = Path()
      ..moveTo(4, 6)
      ..lineTo(12, 12)
      ..lineTo(4, 18)
      ..close();
    canvas.drawPath(path1, fillPaint);

    final path2 = Path()
      ..moveTo(20, 6)
      ..lineTo(12, 12)
      ..lineTo(20, 18)
      ..close();
    canvas.drawPath(path2, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================================
// EXACT 1:1 SVG ICON PAINTERS (home.svg & seting.svg)
// ========================================================

// 1. Home SVG Painter (1:1 from home.svg)
class HomeSvgPainter extends CustomPainter {
  final Color color;
  HomeSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.scale(size.width / 48.0, size.height / 48.0);

    final path = Path()
      ..moveTo(23.951172, 4)
      ..relativeArcToPoint(const Offset(-0.878906, 0.3222656), radius: const Radius.circular(1.50015))
      ..lineTo(8.859375, 15.519531)
      ..cubicTo(7.0554772, 16.941163, 6, 19.113506, 6, 21.410156)
      ..lineTo(6, 40.5)
      ..cubicTo(6, 41.863594, 7.1364058, 43, 8.5, 43)
      ..lineTo(18.5, 43)
      ..cubicTo(19.863594, 43, 21, 41.863594, 21, 40.5)
      ..lineTo(21, 30.5)
      ..cubicTo(21, 30.204955, 21.204955, 30, 21.5, 30)
      ..lineTo(26.5, 30)
      ..cubicTo(26.795045, 30, 27, 30.204955, 27, 30.5)
      ..lineTo(27, 40.5)
      ..cubicTo(27, 41.863594, 28.136406, 43, 29.5, 43)
      ..lineTo(39.5, 43)
      ..cubicTo(40.863594, 43, 42, 41.863594, 42, 40.5)
      ..lineTo(42, 21.410156)
      ..cubicTo(42, 19.113506, 40.944523, 16.941163, 39.140625, 15.519531)
      ..lineTo(24.927734, 4.3222656)
      ..relativeArcToPoint(const Offset(-0.976562, -0.3222656), radius: const Radius.circular(1.50015))
      ..close()
      ..moveTo(24, 7.4101562)
      ..lineTo(37.285156, 17.876953)
      ..cubicTo(38.369258, 18.731322, 39, 20.030807, 39, 21.410156)
      ..lineTo(39, 40)
      ..lineTo(30, 40)
      ..lineTo(30, 30.5)
      ..cubicTo(30, 28.585045, 28.414955, 27, 26.5, 27)
      ..lineTo(21.5, 27)
      ..cubicTo(19.585045, 27, 18, 28.585045, 18, 30.5)
      ..lineTo(18, 40)
      ..lineTo(9, 40)
      ..lineTo(9, 21.410156)
      ..cubicTo(9, 20.030807, 9.6307412, 18.731322, 10.714844, 17.876953)
      ..lineTo(24, 7.4101562)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 2. Download SVG Painter (1:1 from index.html download icon)
class DownloadSvgPainter extends CustomPainter {
  final Color color;
  DownloadSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.scale(size.width / 24.0, size.height / 24.0);

    final boxPath = Path()
      ..moveTo(21, 15)
      ..lineTo(21, 19)
      ..relativeArcToPoint(const Offset(-2, 2), radius: const Radius.circular(2))
      ..lineTo(5, 21)
      ..relativeArcToPoint(const Offset(-2, -2), radius: const Radius.circular(2))
      ..lineTo(3, 15);
    canvas.drawPath(boxPath, strokePaint);

    final arrowHeadPath = Path()
      ..moveTo(7, 10)
      ..lineTo(12, 15)
      ..lineTo(17, 10);
    canvas.drawPath(arrowHeadPath, strokePaint);

    final arrowLinePath = Path()
      ..moveTo(12, 15)
      ..lineTo(12, 3);
    canvas.drawPath(arrowLinePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 3. Settings SVG Painter (1:1 from seting.svg)
class SettingsSvgPainter extends CustomPainter {
  final Color color;
  SettingsSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.scale(size.width / 48.0, size.height / 48.0);

    final path = Path()
      ..moveTo(24, 4)
      ..cubicTo(22.423103, 4, 20.902664, 4.1994284, 19.451172, 4.5371094)
      ..relativeArcToPoint(const Offset(-1.150391, 1.2988281), radius: const Radius.circular(1.50015))
      ..lineTo(17.982422, 8.7382812)
      ..cubicTo(17.878304, 9.6893592, 17.328913, 10.530853, 16.5, 11.009766)
      ..cubicTo(15.672739, 11.487724, 14.66862, 11.540667, 13.792969, 11.15625)
      ..lineTo(11.125, 9.9824219)
      ..relativeArcToPoint(const Offset(-1.6992188, 0.3476561), radius: const Radius.circular(1.50015))
      ..cubicTo(7.3532865, 12.539588, 5.7626807, 15.215064, 4.859375, 18.201172)
      ..relativeArcToPoint(const Offset(0.5488281, 1.644531), radius: const Radius.circular(1.50015))
      ..lineTo(7.7734375, 21.580078)
      ..cubicTo(8.5457929, 22.147918, 9, 23.042801, 9, 24)
      ..cubicTo(9, 24.95771, 8.5458041, 25.853342, 7.7734375, 26.419922)
      ..lineTo(5.4082031, 28.152344)
      ..relativeArcToPoint(const Offset(-0.5488281, 1.644531), radius: const Radius.circular(1.50015))
      ..cubicTo(5.7625845, 32.782665, 7.3519262, 35.460112, 9.4257812, 37.669922)
      ..relativeArcToPoint(const Offset(1.6992188, 0.345703), radius: const Radius.circular(1.50015))
      ..lineTo(13.791016, 36.841797)
      ..cubicTo(14.667094, 36.456509, 15.672169, 36.511947, 16.5, 36.990234)
      ..cubicTo(17.328913, 37.469147, 17.878304, 38.310641, 17.982422, 39.261719)
      ..lineTo(18.300781, 42.164062)
      ..relativeArcToPoint(const Offset(1.148438, 1.296876), radius: const Radius.circular(1.50015))
      ..cubicTo(20.901371, 43.799844, 22.423103, 44, 24, 44)
      ..cubicTo(25.576897, 44, 27.097336, 43.800572, 28.548828, 43.462891)
      ..relativeArcToPoint(const Offset(1.150391, -1.298829), radius: const Radius.circular(1.50015))
      ..lineTo(30.017578, 39.261719)
      ..cubicTo(30.121696, 38.310641, 30.671087, 37.469147, 31.5, 36.990234)
      ..cubicTo(32.327261, 36.512276, 33.33138, 36.45738, 34.207031, 36.841797)
      ..lineTo(36.875, 38.015625)
      ..relativeArcToPoint(const Offset(1.699219, -0.345703), radius: const Radius.circular(1.50015))
      ..cubicTo(40.646713, 35.460412, 42.237319, 32.782983, 43.140625, 29.796875)
      ..relativeArcToPoint(const Offset(-0.548828, -1.644531), radius: const Radius.circular(1.50015))
      ..lineTo(40.226562, 26.419922)
      ..cubicTo(39.454197, 25.853342, 39, 24.95771, 39, 24)
      ..cubicTo(39, 23.04229, 39.454197, 22.146658, 40.226562, 21.580078)
      ..lineTo(42.591797, 19.847656)
      ..relativeArcToPoint(const Offset(0.548828, -1.644531), radius: const Radius.circular(1.50015))
      ..cubicTo(42.237319, 15.217017, 40.646713, 12.539588, 38.574219, 10.330078)
      ..relativeArcToPoint(const Offset(-1.699219, -0.345703), radius: const Radius.circular(1.50015))
      ..lineTo(34.207031, 11.158203)
      ..cubicTo(33.33138, 11.54262, 32.327261, 11.487724, 31.5, 11.009766)
      ..cubicTo(30.671087, 10.530853, 30.121696, 9.6893592, 30.017578, 8.7382812)
      ..lineTo(29.699219, 5.8359375)
      ..relativeArcToPoint(const Offset(-1.148438, -1.296875), radius: const Radius.circular(1.50015))
      ..cubicTo(27.098629, 4.2001555, 25.576897, 4, 24, 4)
      ..close()
      ..moveTo(24, 16)
      ..cubicTo(19.599487, 16, 16, 19.59949, 16, 24)
      ..cubicTo(16, 28.40051, 19.599487, 32, 24, 32)
      ..cubicTo(28.400513, 32, 32, 28.40051, 32, 24)
      ..cubicTo(32, 19.59949, 28.400513, 16, 24, 16)
      ..close()
      ..moveTo(24, 19)
      ..cubicTo(26.779194, 19, 29, 21.220808, 29, 24)
      ..cubicTo(29, 26.779192, 26.779194, 29, 24, 29)
      ..cubicTo(21.220806, 29, 19, 26.779192, 19, 24)
      ..cubicTo(19, 21.220808, 21.220806, 19, 24, 19)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter untuk Ambient Mesh Grid
class GridMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
