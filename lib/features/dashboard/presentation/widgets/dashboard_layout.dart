import 'package:flutter/material.dart';

import 'sidebar.dart';

class DashboardLayout extends StatelessWidget {
  const DashboardLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const SizedBox(
            width: 250,
            child: Sidebar(),
          ),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to Almustafa Connect ERP',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        int columns = 4;

                        if (constraints.maxWidth < 700) {
                          columns = 1;
                        } else if (constraints.maxWidth < 1100) {
                          columns = 2;
                        } else if (constraints.maxWidth < 1500) {
                          columns = 3;
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          crossAxisCount: columns,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 1.8,
                          children: const [
                            DashboardStatCard(
                              title: 'Total Students',
                              value: '1,280',
                              icon: Icons.school,
                              color: Colors.blue,
                            ),
                            DashboardStatCard(
                              title: 'Total Teachers',
                              value: '85',
                              icon: Icons.person,
                              color: Colors.green,
                            ),
                            DashboardStatCard(
                              title: 'Total Staff',
                              value: '42',
                              icon: Icons.groups,
                              color: Colors.orange,
                            ),
                            DashboardStatCard(
                              title: 'Total Classes',
                              value: '36',
                              icon: Icons.class_,
                              color: Colors.purple,
                            ),
                            DashboardStatCard(
                              title: "Today's Attendance",
                              value: '96%',
                              icon: Icons.fact_check,
                              color: Colors.teal,
                            ),
                            DashboardStatCard(
                              title: "Today's Fee Collection",
                              value: 'Rs. 245,000',
                              icon: Icons.payments,
                              color: Colors.indigo,
                            ),
                            DashboardStatCard(
                              title: 'Monthly Fee Collection',
                              value: 'Rs. 3.4M',
                              icon:
                                  Icons.account_balance_wallet,
                              color: Colors.deepPurple,
                            ),
                            DashboardStatCard(
                              title: 'Pending Fees',
                              value: 'Rs. 680,000',
                              icon: Icons.warning_amber,
                              color: Colors.red,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 1000) {
                          return const Column(
                            children: [
                              RecentAdmissionsCard(),
                              SizedBox(height: 20),
                              UpcomingBirthdaysCard(),
                              SizedBox(height: 20),
                              LatestNoticesCard(),
                              SizedBox(height: 20),
                              QuickActionsCard(),
                            ],
                          );
                        }

                        return const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: RecentAdmissionsCard(),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  UpcomingBirthdaysCard(),
                                  SizedBox(height: 20),
                                  LatestNoticesCard(),
                                  SizedBox(height: 20),
                                  QuickActionsCard(),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
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
class RecentAdmissionsCard extends StatelessWidget {
  const RecentAdmissionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Admissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Admission #')),
                  DataColumn(label: Text('Student')),
                  DataColumn(label: Text('Class')),
                ],
                rows: const [
                  DataRow(
                    cells: [
                      DataCell(Text('A1001')),
                      DataCell(Text('Ali Raza')),
                      DataCell(Text('Grade 5')),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('A1002')),
                      DataCell(Text('Ahmed Khan')),
                      DataCell(Text('Grade 8')),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('A1003')),
                      DataCell(Text('Fatima Noor')),
                      DataCell(Text('Grade 2')),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('A1004')),
                      DataCell(Text('Usman Ali')),
                      DataCell(Text('Grade 10')),
                    ],
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
class UpcomingBirthdaysCard extends StatelessWidget {
  const UpcomingBirthdaysCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Upcoming Birthdays',
      children: [
        ListTile(
          leading: CircleAvatar(child: Icon(Icons.cake)),
          title: Text('Ayesha'),
          subtitle: Text('Tomorrow'),
        ),
        ListTile(
          leading: CircleAvatar(child: Icon(Icons.cake)),
          title: Text('Hamza'),
          subtitle: Text('31 July'),
        ),
      ],
    );
  }
}
class LatestNoticesCard extends StatelessWidget {
  const LatestNoticesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Latest Notices',
      children: [
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text('PTM on Saturday'),
        ),
        Divider(height: 1),
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text('Fee submission deadline'),
        ),
        Divider(height: 1),
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text('Summer Camp Registration'),
        ),
      ],
    );
  }
}
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quick Actions',
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.class_),
              label: const Text('Classes'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.payments),
              label: const Text('Fee'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.campaign),
              label: const Text('Notice'),
            ),
          ],
        ),
      ],
    );
  }
}
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}