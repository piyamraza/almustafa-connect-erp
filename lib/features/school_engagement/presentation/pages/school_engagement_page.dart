import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/engagement_person_entity.dart';
import '../../domain/services/birthday_resolver_service.dart';
import '../../domain/usecases/get_today_birthdays.dart';
import '../../domain/usecases/get_upcoming_birthdays.dart';
import '../../domain/usecases/search_birthday_people.dart';
import '../widgets/birthday_error_card.dart';
import '../widgets/birthday_loading_card.dart';
import '../widgets/birthday_summary_cards.dart';
import '../widgets/birthday_workspace_card.dart';
import '../widgets/school_engagement_header.dart';

const _pageBackground = Color(0xFFF5F7FA);

class SchoolEngagementPage extends StatefulWidget {
  const SchoolEngagementPage({super.key});

  @override
  State<SchoolEngagementPage> createState() =>
      _SchoolEngagementPageState();
}

class _SchoolEngagementPageState extends State<SchoolEngagementPage> {
  late Future<_BirthdaySummaryData> _summaryFuture;

  final TextEditingController _searchController =
      TextEditingController();

  bool _showSearch = false;
  bool _searching = false;

  List<EngagementPersonEntity> _searchResults =
      const <EngagementPersonEntity>[];

  String? _searchError;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_BirthdaySummaryData> _loadSummary() async {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final tomorrow = today.add(
      const Duration(days: 1),
    );

    final endOfWeek = today.add(
      Duration(
        days: DateTime.daysPerWeek - today.weekday,
      ),
    );

    final endOfMonth = DateTime(
      today.year,
      today.month + 1,
      0,
    );

    final todayBirthdays = await sl<GetTodayBirthdays>()(
      now: today,
    );

    final upcoming = await sl<GetUpcomingBirthdays>()(
      startDate: tomorrow,
      endDate: endOfMonth,
    );

    final resolver = sl<BirthdayResolverService>();

    final tomorrowCount = upcoming.where((person) {
      return resolver.isBirthdayOn(
        person,
        tomorrow,
      );
    }).length;

    final weekCount = upcoming.where((person) {
      final birthday = resolver.nextBirthdayDate(
        person,
        fromDate: today,
      );

      return !birthday.isBefore(today) &&
          !birthday.isAfter(endOfWeek);
    }).length;

    return _BirthdaySummaryData(
      todayBirthdays: todayBirthdays,
      tomorrowCount: tomorrowCount,
      weekCount: weekCount,
      monthCount: upcoming.length,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _summaryFuture = _loadSummary();
    });

    await _summaryFuture;
  }

  void _openHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Birthday history will be connected next.',
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;

      if (!_showSearch) {
        _searchController.clear();
        _searchResults =
            const <EngagementPersonEntity>[];
        _searchError = null;
        _searching = false;
      }
    });
  }

  Future<void> _searchBirthdayPeople() async {
    final keyword = _searchController.text.trim();

    if (keyword.isEmpty) {
      setState(() {
        _searchResults =
            const <EngagementPersonEntity>[];
        _searchError = null;
      });

      return;
    }

    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final results =
          await sl<SearchBirthdayPeople>()(
        keyword,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults =
            const <EngagementPersonEntity>[];
        _searching = false;
        _searchError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: FutureBuilder<_BirthdaySummaryData>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;

                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    SchoolEngagementHeader(
                      onRefresh: _refresh,
                      onHistory: _openHistory,
                    ),
                    const SizedBox(height: 24),

                    if (snapshot.connectionState ==
                        ConnectionState.waiting)
                      const BirthdayLoadingCard()
                    else if (snapshot.hasError)
                      BirthdayErrorCard(
                        message:
                            snapshot.error.toString(),
                        onRetry: _refresh,
                      )
                    else
                      BirthdaySummaryCards(
                        todayCount:
                            data?.todayBirthdays.length ??
                            0,
                        tomorrowCount:
                            data?.tomorrowCount ?? 0,
                        weekCount:
                            data?.weekCount ?? 0,
                        monthCount:
                            data?.monthCount ?? 0,
                      ),

                    const SizedBox(height: 24),

                    BirthdayWorkspaceCard(
                      todayBirthdays:
                          data?.todayBirthdays ??
                          const <EngagementPersonEntity>[],
                      showSearch: _showSearch,
                      searchController:
                          _searchController,
                      searching: _searching,
                      searchResults:
                          _searchResults,
                      searchError: _searchError,
                      onToggleSearch: _toggleSearch,
                      onSearch:
                          _searchBirthdayPeople,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BirthdaySummaryData {
  const _BirthdaySummaryData({
    required this.todayBirthdays,
    required this.tomorrowCount,
    required this.weekCount,
    required this.monthCount,
  });

  final List<EngagementPersonEntity>
      todayBirthdays;

  final int tomorrowCount;
  final int weekCount;
  final int monthCount;
}