import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';
import 'transaction_state.dart';

final transactionProvider =
NotifierProvider<TransactionNotifier, TransactionState>(
  TransactionNotifier.new,
);

class TransactionNotifier extends Notifier<TransactionState> {
  final supabase = Supabase.instance.client;

  @override
  TransactionState build() {
    _fetchTransactions();
    return TransactionState.initial();
  }

  Future<void> _fetchTransactions() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final expenseResponse = await supabase
          .from('expenses')
          .select()
          .eq('user_id', user.id);

      final incomeResponse = await supabase
          .from('income')
          .select()
          .eq('user_id', user.id);

      List<TransactionModel> tempList = [];

      tempList.addAll(
        (expenseResponse as List)
            .map((e) => TransactionModel.fromMap(e, isIncome: false)),
      );

      tempList.addAll(
        (incomeResponse as List)
            .map((e) => TransactionModel.fromMap(e, isIncome: true)),
      );

      tempList.sort((a, b) => b.date.compareTo(a.date));

      double inc = 0;
      double exp = 0;

      for (var t in tempList) {
        if (t.isIncome) {
          inc += t.amount;
        } else {
          exp += t.amount;
        }
      }

      state = state.copyWith(
        transactions: tempList,
        income: inc,
        expenses: exp,
        totalBalance: inc - exp,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteTransaction(TransactionModel t) async {
    await supabase
        .from(t.isIncome ? 'income' : 'expenses')
        .delete()
        .eq('id', t.id);

    final updatedList =
    state.transactions.where((e) => e.id != t.id).toList();

    final inc = t.isIncome ? state.income - t.amount : state.income;
    final exp = !t.isIncome ? state.expenses - t.amount : state.expenses;

    state = state.copyWith(
      transactions: updatedList,
      income: inc,
      expenses: exp,
      totalBalance: inc - exp,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _fetchTransactions();
  }
}
