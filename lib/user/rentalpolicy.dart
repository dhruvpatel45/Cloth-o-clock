import 'package:flutter/material.dart';

class RentalPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rental Return Policy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '1. Return Deadline:\n'
                    '   - Rented products must be returned immediately after your 7-day rental period ends.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '2. Return Button:\n'
                    '   - A return button will become visible and clickable as soon as the last day of your rental period ends and the date changes.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '3. Return Within 24 Hours:\n'
                    '   - You must click the return button within the next 24 hours.\n'
                    '   - If you fail to click within this period, additional charges will be added to your next order.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '4. Damage Responsibility:\n'
                    '   - If the product is returned in damaged condition, charges will be applied accordingly.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '5. Pickup Readiness:\n'
                    '   - Once the return button is clicked, you must remain present at the same delivery location for the next 6 hours with the product ready for pickup.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '6. Non-Compliance:\n'
                    '   - Failure to comply with the 6-hour presence or product readiness will result in extra charges.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
