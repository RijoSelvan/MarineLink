// import 'package:flutter/material.dart';
// import '../../widgets/dashboard_card.dart';

// class ExporterHome extends StatelessWidget {
//   const ExporterHome({super.key});

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(

//       appBar: AppBar(
//         title: const Text("Exporter Dashboard"),
//       ),

//       body: GridView.count(
//         crossAxisCount: 2,

//         children: const [

//           DashboardCard(
//             title: "Add Product",
//             icon: Icons.add_box,
//           ),

//           DashboardCard(
//             title: "Inventory",
//             icon: Icons.inventory,
//           ),

//           DashboardCard(
//             title: "Orders",
//             icon: Icons.shopping_cart,
//           ),

//           DashboardCard(
//             title: "Shipment",
//             icon: Icons.local_shipping,
//           ),

//           DashboardCard(
//             title: "Reports",
//             icon: Icons.bar_chart,
//           ),

//           DashboardCard(
//             title: "Profile",
//             icon: Icons.person,
//           ),
//         ],
//       ),
//     );
//   }
// }