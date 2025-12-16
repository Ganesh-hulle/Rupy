import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class PlannedExpense extends Equatable {
  PlannedExpense({
    String? id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.category,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String? category;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'dueDate': dueDate.millisecondsSinceEpoch,
    'category': category,
  };

  factory PlannedExpense.fromMap(Map<String, dynamic> map) {
    return PlannedExpense(
      id: (map['id'] ?? '').toString(),
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      category: map['category'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, amount, dueDate, category];
}
