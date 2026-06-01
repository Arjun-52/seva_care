import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';

class FamilyVitals extends StatelessWidget {
  const FamilyVitals({super.key});

  @override
  Widget build(BuildContext context) {
    final senior = MockData.seniors[0];
    final history = MockData.vitalsHistory;

    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(title: Text(t('vitals_monitor'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${senior.name}', style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
          const SizedBox(height: 16),

          // Current Vitals
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
            children: [
              _vitalTile(t('blood_pressure'), senior.vitals['bp'], t('normal'), Icons.monitor_heart, SevaColors.primary, SevaColors.primaryLight),
              _vitalTile(t('oxygen_level'), '${senior.vitals['spo2']}%', t('normal'), Icons.favorite, SevaColors.green, SevaColors.greenLight),
              _vitalTile(t('heart_rate'), '${senior.vitals['heartRate']} bpm', t('normal'), Icons.trending_up, SevaColors.purple, SevaColors.purpleLight),
              _vitalTile(t('temperature'), '${senior.vitals['temp']}°F', t('normal'), Icons.thermostat, SevaColors.orange, SevaColors.orangeLight),
            ],
          ),
          const SizedBox(height: 24),

          // BP Chart
          SectionTitle(title: '${t('blood_pressure')} Trend', icon: Icons.show_chart),
          const SizedBox(height: 12),
          SevaCard(child: SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(color: SevaColors.divider, strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: SevaColors.textTertiary)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                  getTitlesWidget: (v, _) {
                    if (v.toInt() < history.length) {
                      return Text(history[v.toInt()]['time'] as String, style: const TextStyle(fontSize: 9, color: SevaColors.textTertiary));
                    }
                    return const SizedBox.shrink();
                  })),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 60, maxY: 160,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(history.length, (i) => FlSpot(i.toDouble(), history[i]['bp_sys'] as double)),
                  isCurved: true, color: SevaColors.primary, barWidth: 2.5,
                  belowBarData: BarAreaData(show: true, color: SevaColors.primary.withAlpha(20)),
                  dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(radius: 3, color: SevaColors.primary, strokeWidth: 0)),
                ),
                LineChartBarData(
                  spots: List.generate(history.length, (i) => FlSpot(i.toDouble(), history[i]['bp_dia'] as double)),
                  isCurved: true, color: SevaColors.primary.withAlpha(102), barWidth: 2,
                  dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(radius: 2.5, color: SevaColors.primary.withAlpha(127), strokeWidth: 0)),
                ),
              ],
            )),
          )),
          const SizedBox(height: 24),

          // SpO2 & HR Chart
          SectionTitle(title: '${t('oxygen_level')} & ${t('heart_rate')}', icon: Icons.favorite_border),
          const SizedBox(height: 12),
          SevaCard(child: SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(color: SevaColors.divider, strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: SevaColors.textTertiary)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                  getTitlesWidget: (v, _) {
                    if (v.toInt() < history.length) {
                      return Text(history[v.toInt()]['time'] as String, style: const TextStyle(fontSize: 9, color: SevaColors.textTertiary));
                    }
                    return const SizedBox.shrink();
                  })),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 60, maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(history.length, (i) => FlSpot(i.toDouble(), history[i]['spo2'] as double)),
                  isCurved: true, color: SevaColors.green, barWidth: 2.5,
                  belowBarData: BarAreaData(show: true, color: SevaColors.green.withAlpha(20)),
                  dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(radius: 3, color: SevaColors.green, strokeWidth: 0)),
                ),
                LineChartBarData(
                  spots: List.generate(history.length, (i) => FlSpot(i.toDouble(), history[i]['hr'] as double)),
                  isCurved: true, color: SevaColors.purple, barWidth: 2,
                  dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(radius: 2.5, color: SevaColors.purple, strokeWidth: 0)),
                ),
              ],
            )),
          )),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _vitalTile(String label, String value, String sub, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SevaColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textSecondary)),
            Text(sub, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: SevaColors.green)),
          ]),
        ]),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: SevaColors.textPrimary)),
      ]),
    );
  }
}
