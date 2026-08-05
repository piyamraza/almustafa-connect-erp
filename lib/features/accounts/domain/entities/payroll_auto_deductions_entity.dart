import 'package:equatable/equatable.dart';

class PayrollAutoDeductionsEntity extends Equatable {
  const PayrollAutoDeductionsEntity({
    required this.advanceDeduction,
    required this.loanDeduction,
    required this.otherDeductions,
  });

  const PayrollAutoDeductionsEntity.zero()
    : advanceDeduction = 0,
      loanDeduction = 0,
      otherDeductions = 0;

  final int advanceDeduction;
  final int loanDeduction;
  final int otherDeductions;

  int get totalDeduction => advanceDeduction + loanDeduction + otherDeductions;

  PayrollAutoDeductionsEntity copyWith({
    int? advanceDeduction,
    int? loanDeduction,
    int? otherDeductions,
  }) {
    return PayrollAutoDeductionsEntity(
      advanceDeduction: advanceDeduction ?? this.advanceDeduction,
      loanDeduction: loanDeduction ?? this.loanDeduction,
      otherDeductions: otherDeductions ?? this.otherDeductions,
    );
  }

  @override
  List<Object> get props => [advanceDeduction, loanDeduction, otherDeductions];
}
