// import 'package:flutter/material.dart';
// import '../../widgets/dashboard_card.dart';

// class BuyerHome extends StatelessWidget {
//   const BuyerHome({super.key});

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(

//       appBar: AppBar(
//         title: const Text("Buyer Dashboard"),
//       ),

//       body: GridView.count(
//         crossAxisCount: 2,

//         children: const [

//           DashboardCard(
//             title: "Products",
//             icon: Icons.set_meal,
//           ),

//           DashboardCard(
//             title: "Categories",
//             icon: Icons.category,
//           ),

//           DashboardCard(
//             title: "Cart",
//             icon: Icons.shopping_cart,
//           ),

//           DashboardCard(
//             title: "Orders",
//             icon: Icons.receipt,
//           ),

//           DashboardCard(
//             title: "Track Shipment",
//             icon: Icons.local_shipping,
//           ),

//           DashboardCard(
//             title: "Wishlist",
//             icon: Icons.favorite,
//           ),
//         ],
//       ),
//     );
//   }
// }