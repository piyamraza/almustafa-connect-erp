import 'package:flutter/material.dart';

import '../../domain/entities/engagement_person_entity.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _brandBlue = Color(0xFF0B63CE);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class BirthdayCardPreviewPage extends StatelessWidget {
  const BirthdayCardPreviewPage({
    super.key,
    required this.person,
  });

  final EngagementPersonEntity person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        title: const Text('Birthday Card Preview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: Column(
              children: [
                _BirthdayCard(person: person),
                const SizedBox(height: 24),
                _ActionBar(person: person),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({
    required this.person,
  });

  final EngagementPersonEntity person;

  @override
  Widget build(BuildContext context) {
    final isFemale = person.isFemale;

    final primary = isFemale
        ? const Color(0xFFE54868)
        : const Color(0xFF246BFD);

    final secondary = isFemale
        ? const Color(0xFFFFE9EF)
        : const Color(0xFFEAF2FF);

    return AspectRatio(
      aspectRatio: 1.45,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: _DecorativeCircle(
                size: 180,
                color: primary.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -40,
              child: _DecorativeCircle(
                size: 220,
                color: primary.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(42),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _BirthdayMessage(
                      person: person,
                      primary: primary,
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    flex: 4,
                    child: _StudentPortrait(
                      person: person,
                      primary: primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthdayMessage extends StatelessWidget {
  const _BirthdayMessage({
    required this.person,
    required this.primary,
  });

  final EngagementPersonEntity person;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.celebration,
          color: primary,
          size: 42,
        ),
        const SizedBox(height: 18),
        Text(
          'HAPPY BIRTHDAY',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          person.displayName,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 36,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Wishing you a wonderful birthday filled with happiness, success and beautiful memories.',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'ALMUSTAFA CONNECT',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentPortrait extends StatelessWidget {
  const _StudentPortrait({
    required this.person,
    required this.primary,
  });

  final EngagementPersonEntity person;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        person.profileImageUrl.trim().isNotEmpty;

    return Center(
      child: Container(
        width: 260,
        height: 320,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: primary.withValues(alpha: 0.25),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: hasPhoto
              ? Image.network(
                  person.profileImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return _PhotoPlaceholder(
                      primary: primary,
                    );
                  },
                )
              : _PhotoPlaceholder(
                  primary: primary,
                ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({
    required this.primary,
  });

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.person,
          size: 110,
          color: primary.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.person,
  });

  final EngagementPersonEntity person;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: () => _comingSoon(
            context,
            'Image generation',
          ),
          icon: const Icon(Icons.image_outlined),
          label: const Text('Generate Image'),
        ),
        OutlinedButton.icon(
          onPressed: () => _comingSoon(
            context,
            'PDF generation',
          ),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('PDF'),
        ),
        OutlinedButton.icon(
          onPressed: () => _comingSoon(
            context,
            'Printing',
          ),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Print'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _brandBlue,
          ),
          onPressed: () => _comingSoon(
            context,
            'WhatsApp sharing',
          ),
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share'),
        ),
      ],
    );
  }

  void _comingSoon(
    BuildContext context,
    String feature,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature for ${person.displayName} will be connected next.',
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
