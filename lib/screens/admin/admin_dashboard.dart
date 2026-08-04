import 'package:flutter/material.dart';
import '../../widgets/dashboard_card.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),

      body: Padding(

        padding: const EdgeInsets.all(15),

        child: GridView.count(

          crossAxisCount: 2,

          crossAxisSpacing: 15,

          mainAxisSpacing: 15,

          children: [

            DashboardCard(
              title: "Manage Users",
              icon: Icons.people,
              onTap: () {},
            ),

            DashboardCard(
              title: "Approve Exporters",
              icon: Icons.verified,
              onTap: () {},
            ),

            DashboardCard(
              title: "Manage Products",
              icon: Icons.set_meal,
              onTap: () {},
            ),

            DashboardCard(
              title: "Orders",
              icon: Icons.shopping_cart,
              onTap: () {},
            ),

            DashboardCard(
              title: "Payments",
              icon: Icons.payments,
              onTap: () {},
            ),

            DashboardCard(
              title: "Reports",
              icon: Icons.bar_chart,
              onTap: () {},
            ),

          ],
        ),
      ),
    );
  }
}