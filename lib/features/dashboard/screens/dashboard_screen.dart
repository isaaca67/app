import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/features/dashboard/utils/dashboard_metrics.dart';
import 'package:stitch_cov_dark_mobile_login/models/product.dart';
import 'package:stitch_cov_dark_mobile_login/models/sale.dart';
import 'package:stitch_cov_dark_mobile_login/services/product_service.dart';
import 'package:stitch_cov_dark_mobile_login/services/sale_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.userId,
    required this.productService,
    required this.saleService,
  });

  final String userId;
  final ProductService productService;
  final SaleService saleService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  RevenuePeriod _selectedPeriod = RevenuePeriod.day;
  late final DateTime _monthStart;
  late final DateTime _nextMonthStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthStart = DateTime(now.year, now.month);
    _nextMonthStart = DateTime(now.year, now.month + 1);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: widget.productService.watchProducts(widget.userId),
      builder: (context, productsSnapshot) {
        return StreamBuilder<List<Sale>>(
          stream: widget.saleService.watchSalesForPeriod(
            widget.userId,
            start: _monthStart,
            end: _nextMonthStart,
          ),
          builder: (context, salesSnapshot) {
            if (productsSnapshot.hasError || salesSnapshot.hasError) {
              return const _DashboardError();
            }
            if (!productsSnapshot.hasData || !salesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final metrics = DashboardMetrics.from(
              products: productsSnapshot.data!,
              monthlySales: salesSnapshot.data!,
              now: DateTime.now(),
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1050;
                final padding = isDesktop ? 28.0 : 16.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(padding, 24, padding, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panel de estadísticas',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ingresos y movimiento del inventario durante ${_monthLabel(_monthStart)}.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          _FinancialSummary(
                            metrics: metrics,
                            selectedPeriod: _selectedPeriod,
                            isDesktop: isDesktop,
                            onPeriodSelected: (period) {
                              setState(() => _selectedPeriod = period);
                            },
                          ),
                          const SizedBox(height: 24),
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _RevenueChartCard(
                                    period: _selectedPeriod,
                                    metrics: metrics,
                                    onPeriodSelected: (period) {
                                      setState(() => _selectedPeriod = period);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      _ProductRankingCard(
                                        title: 'Top 5 más vendidos',
                                        subtitle: 'Unidades vendidas este mes',
                                        icon: Icons.trending_up,
                                        color: AppTheme.successColor,
                                        products: metrics.topProducts,
                                      ),
                                      const SizedBox(height: 20),
                                      _ProductRankingCard(
                                        title: 'Top 5 menos vendidos',
                                        subtitle:
                                            'Incluye productos sin ventas',
                                        icon: Icons.trending_down,
                                        color: AppTheme.warningColor,
                                        products: metrics.leastProducts,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _RevenueChartCard(
                              period: _selectedPeriod,
                              metrics: metrics,
                              onPeriodSelected: (period) {
                                setState(() => _selectedPeriod = period);
                              },
                            ),
                            const SizedBox(height: 20),
                            _ProductRankingCard(
                              title: 'Top 5 más vendidos',
                              subtitle: 'Unidades vendidas este mes',
                              icon: Icons.trending_up,
                              color: AppTheme.successColor,
                              products: metrics.topProducts,
                            ),
                            const SizedBox(height: 20),
                            _ProductRankingCard(
                              title: 'Top 5 menos vendidos',
                              subtitle: 'Incluye productos sin ventas',
                              icon: Icons.trending_down,
                              color: AppTheme.warningColor,
                              products: metrics.leastProducts,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({
    required this.metrics,
    required this.selectedPeriod,
    required this.isDesktop,
    required this.onPeriodSelected,
  });

  final DashboardMetrics metrics;
  final RevenuePeriod selectedPeriod;
  final bool isDesktop;
  final ValueChanged<RevenuePeriod> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        label: 'Ingresos de hoy',
        value: metrics.todayRevenue,
        icon: Icons.today_outlined,
        isSelected: selectedPeriod == RevenuePeriod.day,
        onTap: () => onPeriodSelected(RevenuePeriod.day),
      ),
      _MetricCard(
        label: 'Ingresos de la semana',
        value: metrics.weekRevenue,
        icon: Icons.date_range_outlined,
        isSelected: selectedPeriod == RevenuePeriod.week,
        onTap: () => onPeriodSelected(RevenuePeriod.week),
      ),
      _MetricCard(
        label: 'Ingresos del mes',
        value: metrics.monthRevenue,
        icon: Icons.calendar_month_outlined,
        isSelected: selectedPeriod == RevenuePeriod.month,
        onTap: () => onPeriodSelected(RevenuePeriod.month),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isDesktop
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatefulWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final double value;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = widget.isSelected || _hovered
        ? AppTheme.primaryColor
        : (isDark ? AppTheme.darkBorder : Colors.grey[300]!);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label),
                      const SizedBox(height: 4),
                      Text(
                        _money(widget.value),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  const _RevenueChartCard({
    required this.period,
    required this.metrics,
    required this.onPeriodSelected,
  });

  final RevenuePeriod period;
  final DashboardMetrics metrics;
  final ValueChanged<RevenuePeriod> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    final points = metrics.pointsFor(period);
    final total = metrics.totalFor(period);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey[300]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evolución de ingresos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('${_periodLabel(period)} · ${_money(total)}'),
                ],
              ),
              SegmentedButton<RevenuePeriod>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: RevenuePeriod.day, label: Text('Día')),
                  ButtonSegment(
                    value: RevenuePeriod.week,
                    label: Text('Semana'),
                  ),
                  ButtonSegment(value: RevenuePeriod.month, label: Text('Mes')),
                ],
                selected: {period},
                onSelectionChanged: (selection) {
                  onPeriodSelected(selection.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 300,
            child: total == 0
                ? const _EmptyChart()
                : _RevenueLineChart(points: points, period: period),
          ),
        ],
      ),
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  const _RevenueLineChart({required this.points, required this.period});

  final List<RevenuePoint> points;
  final RevenuePeriod period;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(0, (max, point) {
      return math.max(max, point.value);
    });
    final maxY = math.max(1.0, maxValue * 1.2);
    final textColor = Theme.of(context).textTheme.bodySmall?.color;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withValues(alpha: 0.18),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  _compactMoney(value),
                  style: TextStyle(fontSize: 11, color: textColor),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 10,
                  child: Text(
                    points[index].label,
                    style: TextStyle(fontSize: 11, color: textColor),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppTheme.darkSurface,
            getTooltipItems: (spots) => spots.map((spot) {
              final index = math.min(
                math.max(spot.x.round(), 0),
                points.length - 1,
              );
              final point = points[index];
              final label = point.label.isEmpty
                  ? _pointFallbackLabel(period, index)
                  : point.label;
              return LineTooltipItem(
                '$label\n${_money(point.value)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points
                .map((point) => FlSpot(point.index.toDouble(), point.value))
                .toList(),
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: period != RevenuePeriod.month),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withValues(alpha: 0.13),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.query_stats,
          size: 54,
          color: AppTheme.primaryColor.withValues(alpha: 0.65),
        ),
        const SizedBox(height: 12),
        Text(
          'Todavía no hay ventas en este período.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _ProductRankingCard extends StatelessWidget {
  const _ProductRankingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.products,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<ProductSalesMetric> products;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey[300]!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(child: Text('Aún no hay productos registrados.')),
            )
          else
            for (var index = 0; index < products.length; index++) ...[
              _ProductRankingRow(
                position: index + 1,
                product: products[index],
                color: color,
              ),
              if (index < products.length - 1) const Divider(height: 18),
            ],
        ],
      ),
    );
  }
}

class _ProductRankingRow extends StatelessWidget {
  const _ProductRankingRow({
    required this.position,
    required this.product,
    required this.color,
  });

  final int position;
  final ProductSalesMetric product;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.13),
        child: Text(
          '$position',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${product.unitsSold} unidades · ${_money(product.revenue)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ],
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 56),
          SizedBox(height: 16),
          Text(
            'No pudimos cargar las estadísticas. Revisa la conexión y vuelve a intentarlo.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _compactMoney(double value) {
  if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}k';
  return '\$${value.toStringAsFixed(0)}';
}

String _periodLabel(RevenuePeriod period) => switch (period) {
  RevenuePeriod.day => 'Hoy por hora',
  RevenuePeriod.week => 'Semana actual',
  RevenuePeriod.month => 'Mes actual',
};

String _pointFallbackLabel(RevenuePeriod period, int index) => switch (period) {
  RevenuePeriod.day => '${index.toString().padLeft(2, '0')}:00',
  RevenuePeriod.week => 'Día ${index + 1}',
  RevenuePeriod.month => 'Día ${index + 1}',
};

String _monthLabel(DateTime date) {
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${months[date.month - 1]} de ${date.year}';
}
