import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(15),

      child: Card(

        elevation: 5,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),

        child: Padding(
          padding: const EdgeInsets.all(15),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Icon(
                icon,
                size: 45,
                color: Colors.blue,
              ),

              const SizedBox(height: 15),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}