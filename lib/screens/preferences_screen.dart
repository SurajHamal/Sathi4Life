import 'package:flutter/material.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  // Example country list — you can expand or fetch dynamically later
  final List<String> _countries = ['All', 'Nepal', 'India', 'USA', 'Canada'];
  String _selectedCountry = 'All';

  @override
  void initState() {
    super.initState();
    // TODO: Load saved preferences here, if you want persistence
  }

  void _onCountryChanged(String? newCountry) {
    if (newCountry == null) return;
    setState(() {
      _selectedCountry = newCountry;
    });
    // TODO: Save preference persistently if desired
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Country Filter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedCountry,
              items: _countries
                  .map((country) => DropdownMenuItem(
                value: country,
                child: Text(country),
              ))
                  .toList(),
              onChanged: _onCountryChanged,
            ),
            // Add more filters here as you want
          ],
        ),
      ),
    );
  }
}
