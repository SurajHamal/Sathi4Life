import 'package:flutter/material.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:sathi4life/services/match_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final MatchService _matchService = MatchService();

  late List<SwipeItem> _swipeItems;
  late MatchEngine _matchEngine;

  List<Map<String, dynamic>> _users = [];
  int _currentIndex = 0;

  SwipeItem? _lastSwipedItem;
  String? _lastSwipedAction; // 'like' or 'pass'

  double _selectedDistance = 50; // default distance in km

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _matchService.getSuggestedUsers();

    setState(() {
      _users = users;
      _swipeItems = users.map((user) {
        return SwipeItem(
          content: user,
          likeAction: () => _onSwipeRight(user),
          nopeAction: () => _onSwipeLeft(user),
          superlikeAction: () async {},
          onSlideUpdate: (_) async {},
        );
      }).toList();

      _matchEngine = MatchEngine(swipeItems: _swipeItems);
      _currentIndex = 0;
    });
  }

  void _onSwipeRight(Map<String, dynamic> user) async {
    if (!await _matchService.canSwipeToday()) {
      _showSwipeLimitDialog();
      return;
    }

    final targetUid = user['uid'];
    if (targetUid == null) return;

    await _matchService.likeUser(targetUid);
    await _matchService.incrementSwipeCount();

    setState(() {
      _lastSwipedItem = _swipeItems[_currentIndex];
      _lastSwipedAction = 'like';
      _currentIndex++;
    });
  }

  void _onSwipeLeft(Map<String, dynamic> user) async {
    if (!await _matchService.canSwipeToday()) {
      _showSwipeLimitDialog();
      return;
    }

    final targetUid = user['uid'];
    if (targetUid == null) return;

    await _matchService.passUser(targetUid);
    await _matchService.incrementSwipeCount();

    setState(() {
      _lastSwipedItem = _swipeItems[_currentIndex];
      _lastSwipedAction = 'pass';
      _currentIndex++;
    });
  }

  Future<void> _undoLastSwipe() async {
    if (_lastSwipedItem == null || _lastSwipedAction == null) return;

    final user = _lastSwipedItem!.content as Map<String, dynamic>;
    final targetUid = user['uid'];
    if (targetUid == null) return;

    if (_lastSwipedAction == 'like') {
      await _matchService.undoLike(targetUid);
    } else if (_lastSwipedAction == 'pass') {
      await _matchService.undoPass(targetUid);
    }

    setState(() {
      _currentIndex = (_currentIndex - 1).clamp(0, _swipeItems.length - 1);
      _swipeItems.insert(_currentIndex, _lastSwipedItem!);
      _matchEngine = MatchEngine(swipeItems: _swipeItems);
      _lastSwipedItem = null;
      _lastSwipedAction = null;
    });
  }

  void _showSwipeLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Daily Limit Reached"),
        content: Text("You've reached the maximum of 20 swipes for today. Come back tomorrow!"),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Max Distance (km): ${_selectedDistance >= 9999 ? "Global" : _selectedDistance.toInt()}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            min: 1,
            max: 9999,
            divisions: 100,
            value: _selectedDistance,
            label: _selectedDistance >= 9999 ? "Global" : '${_selectedDistance.toInt()} km',
            onChanged: (val) {
              setState(() {
                _selectedDistance = val;
              });
            },
            onChangeEnd: (_) {
              _loadUsers();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_users.isEmpty) {
      return Center(
        child: Text('No users found matching your filters.'),
      );
    }

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SwipeCards(
              matchEngine: _matchEngine,
              itemBuilder: (BuildContext context, int index) {
                final user = _users[index];
                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        user['imageUrl'] != null
                            ? Image.network(user['imageUrl'], fit: BoxFit.cover)
                            : Container(color: Colors.grey[300]),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black54, Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                            child: Text(
                              '${user['name'] ?? 'No Name'}, ${user['age'] ?? ''}',
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              onStackFinished: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No more users')),
                );
              },
              upSwipeAllowed: false,
              fillSpace: true,
            ),
          ),
        ),
      ],
    );
  }
}
