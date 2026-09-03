import 'package:stitch_cov_dark_mobile_login/models/product.dart';
import 'package:stitch_cov_dark_mobile_login/models/sale.dart';

enum RevenuePeriod { day, week, month }

class RevenuePoint {
  const RevenuePoint({
    required this.index,
    required this.label,
    required this.value,
  });

  final int index;
  final String label;
  final double value;
}

class ProductSalesMetric {
  const ProductSalesMetric({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.revenue,
  });

  final String productId;
  final String productName;
  final int unitsSold;
  final double revenue;
}

/// Métricas calculadas a partir de un único snapshot mensual de ventas.
class DashboardMetrics {
  DashboardMetrics._({
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.dayPoints,
    required this.weekPoints,
    required this.monthPoints,
    required this.topProducts,
    required this.leastProducts,
  });

  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final List<RevenuePoint> dayPoints;
  final List<RevenuePoint> weekPoints;
  final List<RevenuePoint> monthPoints;
  final List<ProductSalesMetric> topProducts;
  final List<ProductSalesMetric> leastProducts;

  factory DashboardMetrics.from({
    required List<Product> products,
    required List<Sale> monthlySales,
    required DateTime now,
  }) {
    final localNow = now.toLocal();
    final dayStart = DateTime(localNow.year, localNow.month, localNow.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final weekStart = dayStart.subtract(Duration(days: dayStart.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final monthStart = DateTime(localNow.year, localNow.month);
    final monthEnd = DateTime(localNow.year, localNow.month + 1);

    final validSales = monthlySales
        .where((sale) => sale.createdAt != null)
        .toList(growable: false);

    double totalBetween(DateTime start, DateTime end) => validSales
        .where((sale) {
          final date = sale.createdAt!.toLocal();
          return !date.isBefore(start) && date.isBefore(end);
        })
        .fold(0, (sum, sale) => sum + sale.total);

    final hourlyRevenue = List<double>.filled(24, 0);
    final weeklyRevenue = List<double>.filled(7, 0);
    final daysInMonth = monthEnd.subtract(const Duration(days: 1)).day;
    final monthlyRevenue = List<double>.filled(daysInMonth, 0);

    final productMetrics = <String, _MutableProductMetric>{
      for (final product in products)
        product.id: _MutableProductMetric(
          productId: product.id,
          productName: product.name,
        ),
    };

    for (final sale in validSales) {
      final date = sale.createdAt!.toLocal();
      if (!date.isBefore(dayStart) && date.isBefore(dayEnd)) {
        hourlyRevenue[date.hour] += sale.total;
      }
      if (!date.isBefore(weekStart) && date.isBefore(weekEnd)) {
        weeklyRevenue[date.weekday - 1] += sale.total;
      }
      if (!date.isBefore(monthStart) && date.isBefore(monthEnd)) {
        monthlyRevenue[date.day - 1] += sale.total;
      }

      final metric = productMetrics.putIfAbsent(
        sale.productId,
        () => _MutableProductMetric(
          productId: sale.productId,
          productName: sale.productName,
        ),
      );
      metric.unitsSold += sale.quantity;
      metric.revenue += sale.total;
    }

    final rankedProducts = productMetrics.values
        .map((metric) => metric.freeze())
        .toList(growable: false);
    final topProducts = [...rankedProducts]
      ..sort((a, b) {
        final units = b.unitsSold.compareTo(a.unitsSold);
        return units != 0 ? units : b.revenue.compareTo(a.revenue);
      });
    final leastProducts = [...rankedProducts]
      ..sort((a, b) {
        final units = a.unitsSold.compareTo(b.unitsSold);
        return units != 0
            ? units
            : a.productName.toLowerCase().compareTo(
                b.productName.toLowerCase(),
              );
      });

    const weekLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return DashboardMetrics._(
      todayRevenue: totalBetween(dayStart, dayEnd),
      weekRevenue: totalBetween(weekStart, weekEnd),
      monthRevenue: totalBetween(monthStart, monthEnd),
      dayPoints: List.generate(
        24,
        (hour) => RevenuePoint(
          index: hour,
          label: hour % 4 == 0 ? '${hour.toString().padLeft(2, '0')}:00' : '',
          value: hourlyRevenue[hour],
        ),
      ),
      weekPoints: List.generate(
        7,
        (day) => RevenuePoint(
          index: day,
          label: weekLabels[day],
          value: weeklyRevenue[day],
        ),
      ),
      monthPoints: List.generate(
        daysInMonth,
        (day) => RevenuePoint(
          index: day,
          label: day == 0 || (day + 1) % 5 == 0 ? '${day + 1}' : '',
          value: monthlyRevenue[day],
        ),
      ),
      topProducts: topProducts.take(5).toList(growable: false),
      leastProducts: leastProducts.take(5).toList(growable: false),
    );
  }

  double totalFor(RevenuePeriod period) => switch (period) {
    RevenuePeriod.day => todayRevenue,
    RevenuePeriod.week => weekRevenue,
    RevenuePeriod.month => monthRevenue,
  };

  List<RevenuePoint> pointsFor(RevenuePeriod period) => switch (period) {
    RevenuePeriod.day => dayPoints,
    RevenuePeriod.week => weekPoints,
    RevenuePeriod.month => monthPoints,
  };
}

class _MutableProductMetric {
  _MutableProductMetric({required this.productId, required this.productName});

  final String productId;
  final String productName;
  int unitsSold = 0;
  double revenue = 0;

  ProductSalesMetric freeze() => ProductSalesMetric(
    productId: productId,
    productName: productName,
    unitsSold: unitsSold,
    revenue: revenue,
  );
}
