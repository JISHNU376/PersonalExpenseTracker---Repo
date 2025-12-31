import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../providers/statistics_provider.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsNotifierProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final isExpense = ref.watch(isExpenseProvider);

    final notifier = ref.read(statisticsNotifierProvider.notifier);

    void onTabChange(int index) {
      ref.read(selectedTabProvider.notifier).state = index;
      notifier.fetchTransactions(isExpense: isExpense, selectedTab: index);
    }

    void onTypeChange(String value) {
      final expense = value == "Expense";
      ref.read(isExpenseProvider.notifier).state = expense;
      notifier.fetchTransactions(isExpense: expense, selectedTab: selectedTab);
    }

    Future<void> downloadStatistics() async {
      if (state.transactions.isEmpty) return;

      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Storage permission is required to save file')),
          );
          return;
        }
      }

      String csv = 'Date,Category,Amount\n';
      for (var tx in state.transactions) {
        csv +=
        '${DateFormat('yyyy-MM-dd').format(tx.date)},${tx.category},${tx.amount}\n';
      }

      Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final path =
          '${directory.path}/statistics_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File saved to ${file.path}')),
      );
    }

    final tabs = ["Day", "Week", "Month", "Year"];
    final zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      zoomMode: ZoomMode.x,
      enablePinching: false,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Statistics",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.black),
            onPressed: downloadStatistics,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Tabs ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(tabs.length, (index) {
                final isSelected = selectedTab == index;
                return GestureDetector(
                  onTap: () => onTabChange(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2E7D73)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // ---------------- Expense / Income Dropdown ----------------
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: isExpense ? "Expense" : "Income",
                    items: const [
                      DropdownMenuItem(
                        value: "Expense",
                        child: Text("Expense"),
                      ),
                      DropdownMenuItem(
                        value: "Income",
                        child: Text("Income"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onTypeChange(value);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---------------- Chart ----------------
            SizedBox(
              height: 240,
              child: state.chartData.isEmpty
                  ? const Center(child: Text("No data found"))
                  : SfCartesianChart(
                zoomPanBehavior: zoomPanBehavior,
                plotAreaBorderWidth: 0,
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  header: '',
                  format: '₹ point.y',
                ),
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  interval: 1,
                ),
                primaryYAxis: NumericAxis(isVisible: false),
                series: <CartesianSeries<ChartData, String>>[
                  SplineAreaSeries<ChartData, String>(
                    dataSource: state.chartData,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.amount,
                    splineType: SplineType.natural,
                    borderColor: const Color(0xFF2E7D73),
                    borderWidth: 3,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF2E7D73)
                            .withAlpha((0.35 * 255).round()),
                        const Color(0xFF2E7D73)
                            .withAlpha((0.05 * 255).round()),
                      ],
                    ),
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.circle,
                      width: 10,
                      height: 10,
                      borderWidth: 2,
                      borderColor: Color(0xFF2E7D73),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ---------------- Top Spending ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Top Spending",
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.tune),
              ],
            ),
            const SizedBox(height: 16),

            ...state.topSpendings.map((tx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _spendingTile(
                  icon: Icons.shopping_cart,
                  title: tx.category,
                  date: DateFormat('dd MMM yyyy').format(tx.date),
                  amount: "- ₹${tx.amount.toStringAsFixed(2)}",
                  amountColor: Colors.red,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _spendingTile({
    required IconData icon,
    required String title,
    required String date,
    required String amount,
    required Color amountColor,
    Color bgColor = Colors.white,
    Color textColor = Colors.black,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 4),
                Text(date,
                    style: TextStyle(
                        color: textColor.withAlpha((0.6 * 255).round()))),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          )
        ],
      ),
    );
  }
}

