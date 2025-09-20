import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'swipe_screen.dart';        // Your Tinder-like swipe screen
import 'package:sathi4life/screens/chat/chat_list_screen.dart';  // Chat screen with matches on top
import 'discover_screen.dart';
import 'profile_screen.dart';
import 'preferences_screen.dart'; // Import the Preferences page
import 'package:google_fonts/google_fonts.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Default tab index: Swipe screen (0)
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    SwipeScreen(),       // 0 - Tinder-like swipe screen (main/default)
    ChatListScreen(),    // 1 - Chats with horizontal matches on top
    DiscoverScreen(),    // 2 - Discover / Search users
    ProfileScreen(),     // 3 - User Profile
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.swipe),
      label: 'Swipe',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_bubble_outline),
      label: 'Chats',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.explore),
      label: 'Discover',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('Sathi4Life',
          style: GoogleFonts.cinzelDecorative(
            fontSize: MediaQuery.sizeOf(context).width > 600 ? 32 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
            shadows: const [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black26,
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.deepPurple),
            onSelected: (value) async {
              if (value == 'preferences') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PreferencesScreen()),
                );
              } else if (value == 'signout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Sign Out'),
                    content: Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Sign Out', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Signed out successfully')),
                    );
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'preferences',
                child: Row(
                  children: [
                    Icon(Icons.tune, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Preferences'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],

      ),
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex, // This tracks current page properly
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 10,
          items: _navItems,
        ),
      ),
    );
  }
}
