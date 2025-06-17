import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/planner_service.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rencana Belanja'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: PlannerService().getPlanners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final planners = snapshot.data?.docs ?? [];

          if (planners.isEmpty) {
            return const Center(child: Text('Belum ada rencana belanja'));
          }

          // Kelompokkan berdasarkan kategori
          final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
          grouped = {};
          for (var doc in planners) {
            final cat = doc['category'] ?? 'Lainnya';
            grouped.putIfAbsent(cat, () => []).add(doc);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children:
                grouped.entries.map((entry) {
                  final category = entry.key;
                  final items = entry.value;
                  final total = items.fold(
                    0.0,
                    (sum, doc) => sum + (doc['amount'] ?? 0),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Total: Rp ${total.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      ...items.map((doc) {
                        final data = doc.data();
                        final title = data['title'] ?? '';
                        final amount = data['amount'] ?? 0;
                        final targetDate =
                            (data['targetDate'] as Timestamp).toDate();
                        final isDone = data['isDone'] ?? false;

                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: isDone,
                              onChanged:
                                  (val) => PlannerService().togglePlannerStatus(
                                    doc.id,
                                    val ?? false,
                                  ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                decoration:
                                    isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text(
                              'Target: ${DateFormat('dd MMM yyyy').format(targetDate)}',
                            ),
                            trailing: Text(
                              'Rp ${amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-planner'),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
