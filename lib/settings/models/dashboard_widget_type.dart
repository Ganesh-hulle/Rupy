enum DashboardWidgetType {
  metrics('Quick metrics'),
  breakdown('Spending breakdown'),
  cardSpend('Card spending'),
  usableBudget('Usable budget'),
  forecast('Forecast'),
  recurring('Recurring & Subscriptions'),
  burnChart('Burn chart'),
  anomalies('Spotlights'),
  categoryChart('Category chart'),
  budgetCard('Budget details'),
  recentExpenses('Recent expenses');

  const DashboardWidgetType(this.label);
  final String label;

  static const List<DashboardWidgetType> defaultOrder = [
    metrics,
    breakdown,
    cardSpend,
    usableBudget,
    forecast,
    recurring,
    burnChart,
    anomalies,
    categoryChart,
    budgetCard,
    recentExpenses,
  ];
}
