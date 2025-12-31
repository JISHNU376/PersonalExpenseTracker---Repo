import 'package:json_annotation/json_annotation.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;

  @JsonKey(name: 'user_id')
  final String userId;

  /// UI / logic purpose only
  /// fromJson-la varathu → so DEFAULT value kudu
  @JsonKey(ignore: true)
  final bool isIncome;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.userId,

    /// 👇 IMPORTANT FIX
    this.isIncome = false,
  });

  /// Statistics page
  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  /// Home page / list page
  factory TransactionModel.fromMap(
      Map<String, dynamic> map, {
        required bool isIncome,
      }) {
    return TransactionModel(
      id: map['id'],
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      category: map['category'] ?? '',
      userId: map['user_id'],
      isIncome: isIncome,
    );
  }
}
