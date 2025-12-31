import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'transaction_provider.dart';
/// ---------------- CHART DATA MODEL ----------------
class ChartData {
  final String label;
  final double amount;
  ChartData(this.label, this.amount);
}

/// ---------------- STATE ----------------
class StatisticsState {
  final List<TransactionModel> transactions;
  final List<ChartData> chartData;
  final List<TransactionModel> topSpendings;
  final bool isLoading; // ✅ must have

  StatisticsState({
    this.transactions = const [],
    this.chartData = const [],
    this.topSpendings = const [],
    this.isLoading = true,
  });

  StatisticsState copyWith({
    List<TransactionModel>? transactions,
    List<ChartData>? chartData,
    List<TransactionModel>? topSpendings,
    bool? isLoading,
  }) {
    return StatisticsState(
      transactions: transactions ?? this.transactions,
      chartData: chartData ?? this.chartData,
      topSpendings: topSpendings ?? this.topSpendings,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  factory StatisticsState.initial() => StatisticsState();
}

/// ---------------- NOTIFIER ----------------
class StatisticsNotifier extends Notifier<StatisticsState> {
  final supabase = Supabase.instance.client;

  @override
  StatisticsState build() {
    fetchTransactions(isExpense: true, selectedTab: 0);
    return StatisticsState.initial();
  }

  /// Fetch transactions from Supabase
  Future<void> fetchTransactions({
    required bool isExpense,
    required int selectedTab,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from(isExpense ? 'expenses' : 'income')
          .select()
          .eq('user_id', user.id);

      final transactions = (response as List)
          .map((e) => TransactionModel.fromMap(
        Map<String, dynamic>.from(e),
        isIncome: !isExpense,
      ))
          .toList();

      final chartData = _prepareChartData(transactions, selectedTab);
      final topSpendings = _prepareTopSpendings(transactions, isExpense);

      state = state.copyWith(
        transactions: transactions,
        chartData: chartData,
        topSpendings: topSpendings,
      );
    } catch (e) {
      state = state.copyWith(
        transactions: [],
        chartData: [],
        topSpendings: [],
      );
    }
  }

  /// Prepare chart data based on selected tab
  List<ChartData> _prepareChartData(List<TransactionModel> transactions, int selectedTab) {
    final now = DateTime.now();
    Map<String, double> grouped = {};

    for (final tx in transactions) {
      final date = tx.date;
      bool include = false;
      String label = "";

      switch (selectedTab) {
        case 0: // Day
          include = date.day == now.day && date.month == now.month && date.year == now.year;
          label = "Today";
          break;
        case 1: // Week
          include = now.difference(date).inDays <= 7;
          label = DateFormat('dd/MM').format(date);
          break;
        case 2: // Month
          include = date.month == now.month && date.year == now.year;
          label = date.day.toString();
          break;
        case 3: // Year
          include = date.year == now.year;
          const monthNames = [
            '',
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ];
          label = monthNames[date.month];
          break;
      }

      if (!include) continue;
      grouped[label] = (grouped[label] ?? 0) + tx.amount;
    }

    List<ChartData> chartData =
    grouped.entries.map((e) => ChartData(e.key, e.value)).toList();

    if (selectedTab == 3) {
      final monthOrder = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      };
      chartData.sort((a, b) => monthOrder[a.label]!.compareTo(monthOrder[b.label]!));
    }

    return chartData;
  }

  /// Get top 3 spendings
  List<TransactionModel> _prepareTopSpendings(List<TransactionModel> transactions, bool isExpense) {
    if (!isExpense) return [];
    final top = List<TransactionModel>.from(transactions);
    top.sort((a, b) => b.amount.compareTo(a.amount));
    return top.length > 3 ? top.sublist(0, 3) : top;
  }
}

/// ---------------- PROVIDERS ----------------
final statisticsNotifierProvider =
NotifierProvider<StatisticsNotifier, StatisticsState>(StatisticsNotifier.new);

final selectedTabProvider = StateProvider<int>((ref) => 0);
final isExpenseProvider = StateProvider<bool>((ref) => true);
