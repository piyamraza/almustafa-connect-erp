import 'package:flutter/material.dart';

import '../../domain/entities/engagement_person_entity.dart';
import '../pages/birthday_card_preview_page.dart';

const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class BirthdayWorkspaceCard extends StatelessWidget {
  const BirthdayWorkspaceCard({
    super.key,
    required this.todayBirthdays,
    required this.showSearch,
    required this.searchController,
    required this.searching,
    required this.searchResults,
    required this.searchError,
    required this.onToggleSearch,
    required this.onSearch,
  });

  final List<EngagementPersonEntity> todayBirthdays;
  final bool showSearch;
  final TextEditingController searchController;
  final bool searching;
  final List<EngagementPersonEntity> searchResults;
  final String? searchError;
  final VoidCallback onToggleSearch;
  final Future<void> Function() onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _borderColor,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Birthday Wishes',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'View today\'s birthdays or search any student.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );

                final searchButton = FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandBlue,
                  ),
                  onPressed: onToggleSearch,
                  icon: Icon(
                    showSearch ? Icons.close : Icons.search,
                  ),
                  label: Text(
                    showSearch
                        ? 'Close Search'
                        : 'Search Birthday',
                  ),
                );

                if (constraints.maxWidth < 650) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading,
                      const SizedBox(height: 16),
                      searchButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    const Expanded(
                      child: heading,
                    ),
                    const SizedBox(width: 16),
                    searchButton,
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),

          if (showSearch) ...[
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => onSearch(),
                      decoration: const InputDecoration(
                        labelText: 'Search student',
                        hintText: 'Enter student name or admission number',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: searching ? null : onSearch,
                    icon: searching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ],
              ),
            ),

            if (searchError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  0,
                  22,
                  18,
                ),
                child: Text(
                  searchError!,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),

            if (!searching &&
                searchController.text.trim().isNotEmpty &&
                searchResults.isEmpty &&
                searchError == null)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  0,
                  22,
                  22,
                ),
                child: Text(
                  'No matching active student found.',
                  style: TextStyle(
                    color: _textSecondary,
                  ),
                ),
              ),

            if (searchResults.isNotEmpty)
              ...searchResults.map(
                (person) => _BirthdayPersonRow(
                  person: person,
                  showBirthdayDate: true,
                ),
              ),

            const Divider(height: 1),
          ],

          const Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              20,
              22,
              8,
            ),
            child: Text(
              "Today's Birthdays",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          if (todayBirthdays.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 36,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.cake_outlined,
                      size: 52,
                      color: _textSecondary,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No birthdays today',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'There are no active students celebrating a birthday today.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...todayBirthdays.map(
              (person) => _BirthdayPersonRow(
                person: person,
                showBirthdayDate: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _BirthdayPersonRow extends StatelessWidget {
  const _BirthdayPersonRow({
    required this.person,
    required this.showBirthdayDate,
  });

  final EngagementPersonEntity person;
  final bool showBirthdayDate;

  @override
  Widget build(BuildContext context) {
    final dob = person.dateOfBirth;

    final birthdayText = showBirthdayDate
        ? 'Birthday: ${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}'
        : 'Birthday today';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: _brandBlue.withValues(
              alpha: 0.10,
            ),
            backgroundImage:
                person.profileImageUrl.trim().isNotEmpty
                    ? NetworkImage(
                        person.profileImageUrl,
                      )
                    : null,
            child:
                person.profileImageUrl.trim().isEmpty
                    ? const Icon(
                        Icons.person_outline,
                        color: _brandBlue,
                      )
                    : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  person.displayName,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  birthdayText,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (person
                    .classSectionLabel
                    .isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    person.classSectionLabel,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      BirthdayCardPreviewPage(
                    person: person,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.card_giftcard,
            ),
            label: const Text(
              'Create Card',
            ),
          ),
        ],
      ),
    );
  }
}
