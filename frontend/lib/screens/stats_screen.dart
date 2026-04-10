import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FoodLog>>(
      future: context.read<FirebaseService>().fetchLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No meal logs yet."));

        final logs = snapshot.data!;
        
        // Group by day for simple stats
        Map<String, int> dailyCals = {};
        for(var log in logs) {
          String dateString = DateFormat('MM/dd').format(log.date);
          dailyCals[dateString] = (dailyCals[dateString] ?? 0) + log.calories;
        }

        List<BarChartGroupData> barGroups = [];
        int index = 0;
        dailyCals.forEach((date, cals) {
          barGroups.add(
            BarChartGroupData(
              x: index,
              barRods: [BarChartRodData(toY: cals.toDouble(), color: Theme.of(context).primaryColor, width: 16)],
            )
          );
          index++;
        });

        return Scaffold(
          appBar: AppBar(title: const Text('Last 7 Days', style: TextStyle(fontWeight: FontWeight.bold))),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Calorie History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text('Recent Meals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, i) {
                      final item = logs[i];
                      return ListTile(
                        leading: const Icon(Icons.fastfood, color: Colors.greenAccent),
                        title: Text(item.name),
                        subtitle: Text(DateFormat('MMM dd, hh:mm a').format(item.date)),
                        trailing: Text('${item.calories} Cal', style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }
}
