import 'dart:async';

import 'package:flutter/material.dart';

import '../../../documents/presentation/pages/birthday_document_preview_page.dart';
import '../../domain/entities/engagement_person_entity.dart';

const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class BirthdayWorkspaceCard extends StatefulWidget {
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
  State<BirthdayWorkspaceCard> createState() => _BirthdayWorkspaceCardState();
}

class _BirthdayWorkspaceCardState extends State<BirthdayWorkspaceCard> {
  Timer? _searchDebounce;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void didUpdateWidget(covariant BirthdayWorkspaceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showSearch && widget.showSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.showSearch) _searchFocusNode.requestFocus();
      });
    } else if (oldWidget.showSearch && !widget.showSearch) {
      _searchFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    final query = value.trim();

    setState(() {});

    if (query.isEmpty) {
      _searchDebounce = Timer(const Duration(milliseconds: 100), () {
        if (mounted) {
          widget.onSearch();
        }
      });

      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        widget.onSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderColor),
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
                      style: TextStyle(color: _textSecondary, fontSize: 14),
                    ),
                  ],
                );

                final searchButton = FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _brandBlue),
                  onPressed: widget.onToggleSearch,
                  icon: Icon(widget.showSearch ? Icons.close : Icons.search),
                  label: Text(
                    widget.showSearch ? 'Close Search' : 'Search Birthday',
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
                    const Expanded(child: heading),
                    const SizedBox(width: 16),
                    searchButton,
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1),

          if (widget.showSearch) ...[
            Padding(
              padding: const EdgeInsets.all(22),
              child: TextField(
                controller: widget.searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,

                onChanged: _onSearchChanged,

                onSubmitted: (_) {
                  _searchDebounce?.cancel();

                  widget.onSearch();
                },

                decoration: InputDecoration(
                  labelText: 'Search student',

                  hintText: 'Start typing student name or admission number',

                  prefixIcon: const Icon(Icons.search),

                  suffixIcon: widget.searching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : widget.searchController.text.trim().isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchDebounce?.cancel();

                            widget.searchController.clear();

                            setState(() {});

                            widget.onSearch();
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,

                  border: const OutlineInputBorder(),
                ),
              ),
            ),

            if (widget.searchError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                child: Text(
                  widget.searchError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (!widget.searching &&
                widget.searchController.text.trim().isNotEmpty &&
                widget.searchResults.isEmpty &&
                widget.searchError == null)
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: Text(
                  'No matching active student found.',
                  style: TextStyle(color: _textSecondary),
                ),
              ),

            if (widget.searchResults.isNotEmpty)
              ...widget.searchResults.map(
                (person) => _BirthdayPersonRow(
                  person: person,
                  showBirthdayDate: true,
                  showStudentDetails: true,
                ),
              ),

            const Divider(height: 1),
          ],

          const Padding(
            padding: EdgeInsets.fromLTRB(22, 20, 22, 8),
            child: Text(
              "Today's Birthdays",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          if (widget.todayBirthdays.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cake_outlined, size: 52, color: _textSecondary),
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
                      style: TextStyle(color: _textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ...widget.todayBirthdays.map(
              (person) => _BirthdayPersonRow(
                person: person,
                showBirthdayDate: false,
                showStudentDetails: false,
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
    required this.showStudentDetails,
  });

  final EngagementPersonEntity person;
  final bool showBirthdayDate;
  final bool showStudentDetails;

  @override
  Widget build(BuildContext context) {
    final dob = person.dateOfBirth;

    final birthdayText = showBirthdayDate
        ? 'Birthday: ${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}'
        : 'Birthday today';

    final fatherName = person.fatherName.trim();

    final className = person.classSectionLabel.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: _brandBlue.withValues(alpha: 0.10),
            backgroundImage: person.profileImageUrl.trim().isNotEmpty
                ? NetworkImage(person.profileImageUrl)
                : null,
            child: person.profileImageUrl.trim().isEmpty
                ? const Icon(Icons.person_outline, color: _brandBlue)
                : null,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.displayName,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (showStudentDetails &&
                    (fatherName.isNotEmpty || className.isNotEmpty)) ...[
                  const SizedBox(height: 5),

                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      if (fatherName.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.family_restroom_outlined,
                              size: 16,
                              color: _textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Father: $fatherName',
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                      if (className.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 16,
                              color: _textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Class: $className',
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 4),

                Text(
                  birthdayText,
                  style: const TextStyle(color: _textSecondary, fontSize: 13),
                ),

                if (!showStudentDetails && className.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    className,
                    style: const TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 16),

          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BirthdayDocumentPreviewPage(person: person),
                ),
              );
            },
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Preview Card'),
          ),
        ],
      ),
    );
  }
}
