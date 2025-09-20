import 'package:flutter/material.dart';

class GenderPreferenceScreen extends StatefulWidget {
  const GenderPreferenceScreen({Key? key}) : super(key: key);

  @override
  State<GenderPreferenceScreen> createState() => _GenderPreferenceScreenState();
}

class _GenderPreferenceScreenState extends State<GenderPreferenceScreen> {
  String? selectedGender;
  String? interestedIn;
  bool showInterestStep = false;
  bool _visible = true;

  void _selectGender(String gender) async {
    setState(() {
      _visible = false; // fade out
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      selectedGender = gender;
      showInterestStep = true;
      _visible = true; // fade in next step
    });
  }

  void _selectInterest(String interest) async {
    setState(() {
      _visible = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      interestedIn = interest;
    });

    // TODO: Save to Firestore here if needed

    Navigator.pushNamed(context, '/profileSetup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: AnimatedOpacity(
            key: ValueKey(showInterestStep),
            duration: const Duration(milliseconds: 400),
            opacity: _visible ? 1.0 : 0.0,
            child: showInterestStep ? _buildInterestStep() : _buildGenderStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderStep() {
    return Column(
      key: const ValueKey('genderStep'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "What is your gender?",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: () => _selectGender('Male'), child: const Text('Male')),
        ElevatedButton(
            onPressed: () => _selectGender('Female'),
            child: const Text('Female')),
        ElevatedButton(
            onPressed: () => _selectGender('Other'), child: const Text('Other')),
      ],
    );
  }

  Widget _buildInterestStep() {
    return Column(
      key: const ValueKey('interestStep'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "What are you interested in?",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: () => _selectInterest('Men'), child: const Text('Men')),
        ElevatedButton(
            onPressed: () => _selectInterest('Women'),
            child: const Text('Women')),
        ElevatedButton(
            onPressed: () => _selectInterest('Everyone'),
            child: const Text('Everyone')),
      ],
    );
  }
}
