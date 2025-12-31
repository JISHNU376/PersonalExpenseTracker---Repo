import '../models/transaction_model.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final double income;
  final double expenses;
  final double totalBalance;
  final bool isLoading;

  TransactionState({
    required this.transactions,
    required this.income,
    required this.expenses,
    required this.totalBalance,
    required this.isLoading,
  });

  factory TransactionState.initial() {
    return TransactionState(
      transactions: [],
      income: 0,
      expenses: 0,
      totalBalance: 0,
      isLoading: true,
    );
  }

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    double? income,
    double? expenses,
    double? totalBalance,
    bool? isLoading,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      income: income ?? this.income,
      expenses: expenses ?? this.expenses,
      totalBalance: totalBalance ?? this.totalBalance,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
