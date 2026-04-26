class Settlement {
  final String from;
  final String to;
  final double amount;
  const Settlement({required this.from, required this.to, required this.amount});
}

class SplitResult {
  final double total;
  final double perPerson;
  final Map<String, double> balanceByMember; // +ve means should receive, -ve means owes
  final List<Settlement> settlements;
  const SplitResult({
    required this.total,
    required this.perPerson,
    required this.balanceByMember,
    required this.settlements,
  });
}

SplitResult calculateEqualSplit({
  required List<String> members,
  required List<Map<String, dynamic>> expenses,
}) {
  final uniqMembers = {...members}.toList();
  final n = uniqMembers.length;
  final paid = {for (final m in uniqMembers) m: 0.0};

  double total = 0;
  for (final e in expenses) {
    final who = e['paidBy'] as String;
    final amount = (e['amount'] as num).toDouble();
    total += amount;
    paid[who] = (paid[who] ?? 0) + amount;
  }

  final perPerson = n == 0 ? 0.0 : total / n;
  final balance = <String, double>{
    for (final m in uniqMembers) m: (paid[m] ?? 0) - perPerson,
  };

  final creditors = balance.entries.where((e) => e.value > 1e-6).map((e) => MapEntry(e.key, e.value)).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final debtors = balance.entries.where((e) => e.value < -1e-6).map((e) => MapEntry(e.key, -e.value)).toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final settlements = <Settlement>[];
  var i = 0;
  var j = 0;
  while (i < debtors.length && j < creditors.length) {
    final d = debtors[i];
    final c = creditors[j];
    final pay = d.value < c.value ? d.value : c.value;
    settlements.add(Settlement(from: d.key, to: c.key, amount: pay));
    debtors[i] = MapEntry(d.key, d.value - pay);
    creditors[j] = MapEntry(c.key, c.value - pay);
    if (debtors[i].value <= 1e-6) i++;
    if (creditors[j].value <= 1e-6) j++;
  }

  return SplitResult(total: total, perPerson: perPerson, balanceByMember: balance, settlements: settlements);
}

