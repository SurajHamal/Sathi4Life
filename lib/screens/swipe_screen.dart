import 'package:flutter/material.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:sathi4life/services/match_service.dart';
import 'package:sathi4life/widgets/user_card.dart';
import 'package:sathi4life/models/user_card_profile.dart';

class SwipeScreen extends StatefulWidget {
  final String? initialCountryFilter;

  const SwipeScreen({Key? key, this.initialCountryFilter}) : super(key: key);

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final MatchService _matchService = MatchService();
  late List<SwipeItem> _swipeItems;
  late MatchEngine _matchEngine;

  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountryFilter;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final countryFilter = (_selectedCountry == null || _selectedCountry == 'All')
        ? null
        : _selectedCountry;

    final userMaps = await _matchService.getSuggestedUsers(countryFilter: countryFilter);

    final profiles = userMaps.map((map) => UserCardProfile.fromMap(map)).toList();

    setState(() {
      _swipeItems = profiles.map((profile) {
        return SwipeItem(
          content: profile,
          likeAction: () => _onSwipeRight(profile),
          nopeAction: () => _onSwipeLeft(profile),
        );
      }).toList();

      _matchEngine = MatchEngine(swipeItems: _swipeItems);
    });
  }

  void updateCountryFilter(String? country) {
    if (country == null) return;
    if (country == _selectedCountry) return;

    setState(() {
      _selectedCountry = country;
    });
    _loadUsers();
  }

  void _onSwipeRight(UserCardProfile user) async {
    if (!await _matchService.canSwipeToday()) {
      _showSwipeLimitDialog();
      return;
    }
    await _matchService.likeUser(user.uid);
    await _matchService.incrementSwipeCount();
  }

  void _onSwipeLeft(UserCardProfile user) async {
    if (!await _matchService.canSwipeToday()) {
      _showSwipeLimitDialog();
      return;
    }
    await _matchService.passUser(user.uid);
    await _matchService.incrementSwipeCount();
  }

  void _showSwipeLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Daily Limit Reached"),
        content: const Text("You've reached your daily swipe limit. Try again tomorrow!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _swipeItems.isEmpty
          ? const Center(child: Text("No users to swipe."))
          : SwipeCards(
        matchEngine: _matchEngine,
        itemBuilder: (context, index) {
          final user = _swipeItems[index].content as UserCardProfile;
          return UserCard(
            user: user,
            onLike: () => _onSwipeRight(user),
            onPass: () => _onSwipeLeft(user),
          );
        },
        onStackFinished: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You've seen all suggestions."),
            ),
          );
        },
        upSwipeAllowed: false,
        fillSpace: true,
      ),
    );
  }
}
