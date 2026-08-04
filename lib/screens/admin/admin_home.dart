// import 'package:flutter/material.dart';

// import '../../widgets/dashboard_card.dart';

// class AdminHome extends StatelessWidget {
//   const AdminHome({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(

//       appBar: AppBar(
//         title: const Text("Admin Dashboard"),
//       ),

//       body: GridView.count(
//         crossAxisCount: 2,
//         children: const [

//           DashboardCard(
//             title: "Manage Exporters",
//             icon: Icons.people,
//           ),

//           DashboardCard(
//             title: "Manage Buyers",
//             icon: Icons.person,
//           ),

//           DashboardCard(
//             title: "Reports",
//             icon: Icons.bar_chart,
//           ),

//           DashboardCard(
//             title: "Payments",
//             icon: Icons.payments,
//           ),

//           DashboardCard(
//             title: "Notifications",
//             icon: Icons.notifications,
//           ),

//           DashboardCard(
//             title: "Analytics",
//             icon: Icons.analytics,
//           ),
//         ],
//       ),
//     );
//   }
// }