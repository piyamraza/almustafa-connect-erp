import 'package:flutter/material.dart';

const _borderColor = Color(0xFFE1E6ED);

class BirthdayLoadingCard extends StatelessWidget {
  const BirthdayLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _borderColor,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
