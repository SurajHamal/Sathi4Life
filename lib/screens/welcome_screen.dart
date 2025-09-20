import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'home_screen.dart';
import 'dart:ui'; // for ImageFilter

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _nameController;
  late AnimationController _taglineController;
  late Animation<double> _logoFade;
  late Animation<double> _logoRotation;
  late Animation<double> _nameFade;
  late Animation<double> _nameScale;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  bool _imageLoadFailed = false;
  bool _showButtons = false;
  bool _isLoading = false; // new flag for logged-in user loading
  String currentLang = 'np';

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));
    _logoRotation = Tween<double>(begin: 0.5, end: 0.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    // Rotation starts upside down (0.5 turns) and rotates to normal (0.0)

    _nameController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _nameController, curve: Curves.easeIn));
    _nameScale = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _nameController, curve: Curves.easeOutBack));

    _taglineController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _taglineController, curve: Curves.easeIn));
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _taglineController, curve: Curves.easeOut));

    _playIntroAnimation();

    // Immediately decide what to show depending on login state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Already logged in - show loading spinner and navigate
        setState(() {
          _isLoading = true;
          _showButtons = false;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          }
        });
      } else {
        // Not logged in - show buttons immediately
        setState(() {
          _showButtons = true;
          _isLoading = false;
        });
      }
    });
  }

  void _playIntroAnimation() {
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _nameController.forward());
    Future.delayed(const Duration(milliseconds: 600), () => _taglineController.forward());
  }

  void _toggleLanguage() {
    setState(() {
      currentLang = currentLang == 'np' ? 'en' : 'np';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/welcome_page.png'),
      context,
      onError: (e, stackTrace) {
        setState(() {
          _imageLoadFailed = true;
        });
        print('Error loading image: $e');
      },
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _nameController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: _imageLoadFailed ? const Color(0xFFD2042D) : null,
          image: _imageLoadFailed
              ? null
              : const DecorationImage(
            image: AssetImage('assets/welcome_page.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: RotationTransition(
                    turns: _logoRotation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Image.asset(
                              'assets/logo_heart.png',
                              color: Colors.redAccent.withOpacity(0.6),
                              colorBlendMode: BlendMode.srcATop,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Image.asset(
                            'assets/logo_heart.png',
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FadeTransition(
                  opacity: _nameFade,
                  child: ScaleTransition(
                    scale: _nameScale,
                    child: Text(
                      'Sathi4Life',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: MediaQuery.sizeOf(context).width > 600 ? 80 : 54,
                        fontWeight: FontWeight.w700,
                        color: Colors.amberAccent,
                        shadows: const [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black45,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _taglineFade,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => currentLang = 'en'),
                      onExit: (_) => setState(() => currentLang = 'np'),
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _toggleLanguage,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                          child: Shimmer.fromColors(
                            key: ValueKey<String>(currentLang),
                            baseColor: Colors.white70,
                            highlightColor: Colors.white,
                            child: Text(
                              currentLang == 'np'
                                  ? 'माया को बन्धन, सधैंका लागि'
                                  : 'Bound by love, for life',
                              style: GoogleFonts.notoSansDevanagari(
                                fontSize: MediaQuery.sizeOf(context).width > 600 ? 24 : 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Show buttons if _showButtons is true
                if (_showButtons) ...[
                  // Log In Button with glowing shadow and animation
                  AnimatedOpacity(
                    opacity: _showButtons ? 1 : 0,
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(color: Colors.orangeAccent, width: 2),
                          ),
                          elevation: 10,
                          textStyle: GoogleFonts.alegreya(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        child: const Text('Log In'),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sign Up Button with glowing shadow and animation
                  AnimatedOpacity(
                    opacity: _showButtons ? 1 : 0,
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(30),
                      ),
                    child:SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F), // Reddish orange
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(color: Colors.orangeAccent, width: 2),
                          ),
                          elevation: 10,
                          textStyle: GoogleFonts.alegreya(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        child: const Text(
                          'Sign Up'),
                        ),
                    ),
                      ),
                    ),
                ] else if (_isLoading) ...[
                  const SizedBox(height: 32),
                  // Stylish colorful loading spinner
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                      backgroundColor: Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
