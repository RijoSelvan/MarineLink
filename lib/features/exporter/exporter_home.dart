import 'package:flutter/material.dart';
import 'exporter_dashboard.dart';

class ExporterHome extends StatelessWidget {
  const ExporterHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ExporterHomeContent(),
    );
  }
}