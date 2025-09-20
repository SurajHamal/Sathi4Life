import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sathi4life/services/match_service.dart';  // Adjust the import path as needed

class MatchDetailScreen extends StatefulWidget {
  final String matchUserId;

  const MatchDetailScreen({Key? key, required this.matchUserId}) : super(key: key);

  @override
  _MatchDetailScreenState createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final MatchService _matchService = MatchService();
  DocumentSnapshot? _profileDoc;
  bool _isLoading = true;

  List<QueryDocumentSnapshot> _profiles = [];
  int _currentIndex = 0;

  // Keep history for undo swipe
  final List<int> _swipeHistory = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadProfilesForSwipe();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('profiles').doc(widget.matchUserId).get();
    setState(() {
      _profileDoc = doc;
      _isLoading = false;
    });
  }

  // Loads profiles excluding current user (and maybe excluding the matched user if needed)
  void _loadProfilesForSwipe() {
    FirebaseFirestore.instance.collection('profiles').snapshots().listen((snapshot) {
      setState(() {
        _profiles = snapshot.docs.where((doc) => doc.id != widget.matchUserId).toList();
        _currentIndex = 0;
        _swipeHistory.clear();
      });
    });
  }

  void _onSwipeLeft() {
    if (_currentIndex >= _profiles.length) return;
    print('Pass on ${_profiles[_currentIndex].id}');
    _recordSwipe();
    setState(() {
      _currentIndex++;
    });
    // TODO: record pass in Firestore for current user
  }

  void _onSwipeRight() {
    if (_currentIndex >= _profiles.length) return;
    print('Like ${_profiles[_currentIndex].id}');
    _recordSwipe();
    setState(() {
      _currentIndex++;
    });
    // TODO: record like in Firestore for current user
  }

  void _recordSwipe() {
    _swipeHistory.add(_currentIndex);
  }

  void _undoSwipe() {
    if (_swipeHistory.isEmpty) return;
    setState(() {
      _currentIndex = _swipeHistory.removeLast();
    });
    print('Undo swipe to index $_currentIndex');
    // TODO: remove last like/pass from Firestore if needed
  }

  Widget _buildCard(QueryDocumentSnapshot profileDoc, {double scale = 1.0, double opacity = 1.0}) {
    final data = profileDoc.data() as Map<String, dynamic>;
    final isOnline = data['isOnline'] == true;

    return Center(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            child: SizedBox(
              width: 320,
              height: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: data['imageUrl'] != null
                            ? Image.network(
                          data['imageUrl'],
                          width: 320,
                          height: 380,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          width: 320,
                          height: 380,
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 80, color: Colors.grey),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${data['name'] ?? 'User'}, ${data['age'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  if (data['location'] != null)
                    Text(
                      data['location'],
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileDoc == null || !_profileDoc!.exists) {
      return const Scaffold(
        body: Center(child: Text('Profile not found.')),
      );
    }

    final profileData = _profileDoc!.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(profileData['name'] ?? 'Match Details'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo last swipe',
            onPressed: _undoSwipe,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              children: [
                SizedBox(height: 20),
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profileData['imageUrl'] != null
                      ? NetworkImage(profileData['imageUrl'])
                      : null,
                  child: profileData['imageUrl'] == null ? const Icon(Icons.person, size: 60) : null,
                ),
                SizedBox(height: 12),
                Text(
                  '${profileData['name'] ?? 'User'}, ${profileData['age'] ?? ''}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                if (profileData['location'] != null)
                  Text(
                    profileData['location'],
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                SizedBox(height: 20),
                Expanded(
                  child: _profiles.isEmpty
                      ? const Center(child: Text('No profiles to swipe.'))
                      : Stack(
                    children: [
                      if (_currentIndex + 1 < _profiles.length)
                        _buildCard(_profiles[_currentIndex + 1], scale: 0.9, opacity: 0.7),
                      DraggableCard(
                        profileDoc: _profiles[_currentIndex],
                        onSwipeLeft: _onSwipeLeft,
                        onSwipeRight: _onSwipeRight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// DraggableCard widget for swipe gesture handling
class DraggableCard extends StatefulWidget {
  final QueryDocumentSnapshot profileDoc;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const DraggableCard({
    Key? key,
    required this.profileDoc,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  }) : super(key: key);

  @override
  _DraggableCardState createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard> {
  double dx = 0;
  double dy = 0;
  double rotation = 0;

  @override
  Widget build(BuildContext context) {
    final data = widget.profileDoc.data() as Map<String, dynamic>;

    return GestureDetector(
      onTap: () {
        // Optionally: Navigate to a detailed profile page for this user
      },
      onPanUpdate: (details) {
        setState(() {
          dx += details.delta.dx;
          dy += details.delta.dy;
          rotation = dx / 300;
        });
      },
      onPanEnd: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (dx > screenWidth * 0.25) {
          widget.onSwipeRight();
        } else if (dx < -screenWidth * 0.25) {
          widget.onSwipeLeft();
        }

        setState(() {
          dx = 0;
          dy = 0;
          rotation = 0;
        });
      },
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: rotation,
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              child: SizedBox(
                width: 320,
                height: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: data['imageUrl'] != null
                              ? Image.network(
                            data['imageUrl'],
                            width: 320,
                            height: 380,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: 320,
                            height: 380,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 80, color: Colors.grey),
                          ),
                        ),
                        if (data['isOnline'] == true)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${data['name'] ?? 'User'}, ${data['age'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    if (data['location'] != null)
                      Text(
                        data['location'],
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
