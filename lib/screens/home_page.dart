import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

// ---------------- FILTER ENUM ----------------
enum FilterType { week, month, year, all }

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  FilterType currentFilter = FilterType.all;
  bool showAllTransactions = false;
  int _currentIndex = 0;

  // ---------------- LOGOUT ----------------
  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/login');
  }

  void _showAccountMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Icons.person),
              title: Text("My Account"),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () async {
                Navigator.pop(context);
                await _logout(context);
              },
            ),
          ],
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    if (hour < 21) return "Good Evening";
    return "Good Night";
  }

  // ---------------- FILTER ----------------
  List<TransactionModel> _getFilteredTransactions(
      List<TransactionModel> transactions) {
    if (currentFilter == FilterType.all) return transactions;

    final now = DateTime.now();

    return transactions.where((t) {
      switch (currentFilter) {
        case FilterType.week:
          return now.difference(t.date).inDays <= 7;
        case FilterType.month:
          return t.date.month == now.month && t.date.year == now.year;
        case FilterType.year:
          return t.date.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final greeting = _getGreeting();

    final transactionState = ref.watch(transactionProvider);

    if (transactionState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredTransactions =
    _getFilteredTransactions(transactionState.transactions);

    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- FAB ----------------
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3E8E86),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.arrow_downward, color: Colors.red),
                  title: const Text("Add Expense"),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.push('/add-expense');
                    ref.read(transactionProvider.notifier).refresh();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_upward, color: Colors.green),
                  title: const Text("Add Income"),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.push('/add-income');
                    ref.read(transactionProvider.notifier).refresh();
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add, size: 30),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ---------------- BOTTOM BAR ----------------
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFF3E8E86)),
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart, color: Colors.grey),
                onPressed: () => context.push('/statistics'),
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: const Icon(Icons.credit_card, color: Colors.grey),
                onPressed: () => setState(() => _currentIndex = 2),
              ),
              GestureDetector(
                onTap: () => _showAccountMenu(context),
                child: const Icon(Icons.person, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),

      // ---------------- BODY ----------------
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              greeting: greeting,
              userName:
              (user?.userMetadata?['full_name'] ?? 'USER')
                  .toString()
                  .toUpperCase(),
              totalBalance: transactionState.totalBalance,
              income: transactionState.income,
              expenses: transactionState.expenses,
              onFilterChange: (f) {
                setState(() => currentFilter = f);
              },
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Income & Expense Listing",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => setState(
                            () => showAllTransactions = !showAllTransactions),
                    child: Text(
                      showAllTransactions ? "Show Less" : "See all",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: showAllTransactions
                    ? filteredTransactions.length
                    : (filteredTransactions.length > 4
                    ? 4
                    : filteredTransactions.length),
                itemBuilder: (_, index) {
                  final t = filteredTransactions[index];

                  return GestureDetector(
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete Transaction"),
                          content: const Text(
                              "Are you sure you want to delete this?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ref
                                    .read(transactionProvider.notifier)
                                    .deleteTransaction(t);
                              },
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: TransactionTile(
                      title: t.title,
                      subtitle:
                      t.date.toIso8601String().split('T')[0],
                      amount:
                      "${t.isIncome ? '+' : '-'} \$${t.amount.toStringAsFixed(2)}",
                      isIncome: t.isIncome,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- UI COMPONENTS ----------------

class _Header extends StatelessWidget {
  final String greeting;
  final String userName;
  final double totalBalance;
  final double income;
  final double expenses;
  final Function(FilterType) onFilterChange;

  const _Header({
    required this.greeting,
    required this.userName,
    required this.totalBalance,
    required this.income,
    required this.expenses,
    required this.onFilterChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF3E8E86),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$greeting,", style: const TextStyle(color: Colors.white70)),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
              const Icon(Icons.notifications_none, color: Colors.white),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2F7F78),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Balance",
                      style: TextStyle(color: Colors.white70)),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: FilterType.values
                              .map(
                                (f) => ListTile(
                              title: Text(f.name.toUpperCase()),
                              onTap: () {
                                onFilterChange(f);
                                Navigator.pop(context);
                              },
                            ),
                          )
                              .toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "\$ ${totalBalance.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BalanceItem(
                    icon: Icons.arrow_upward,
                    title: "Income",
                    amount: "\$ ${income.toStringAsFixed(2)}",
                  ),
                  BalanceItem(
                    icon: Icons.arrow_downward,
                    title: "Expenses",
                    amount: "\$ ${expenses.toStringAsFixed(2)}",
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class BalanceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;

  const BalanceItem({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white24,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ]),
    ]);
  }
}

class TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isIncome;

  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Text(
        amount,
        style: TextStyle(
          color: isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
