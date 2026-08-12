import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
          const Color(0xffF4F9FF),
      appBar: AppBar(
        title: const Text(
          'My Profile',
        ),
        backgroundColor:
            const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),

            // Profile picture
            const CircleAvatar(
              radius: 55,
              backgroundColor:
                  Color(0xff0A4D68),
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'Fish Exporter',
              style: TextStyle(
                fontSize: 25,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xff0A4D68),
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            const Text(
              'Exporter',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // Email
            _buildProfileItem(
              icon: Icons.email_outlined,
              title: 'Email',
              value:
                  user?.email ??
                      'Not available',
            ),

            const SizedBox(
              height: 15,
            ),

            // UID
            _buildProfileItem(
              icon: Icons.badge_outlined,
              title: 'User ID',
              value:
                  user?.uid ??
                      'Not available',
            ),

            const SizedBox(
              height: 30,
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                          0xff0A4D68),
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Edit profile will be added next.',
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit,
                ),
                label: const Text(
                  'Edit Profile',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              const Color(0xff0A4D68)
                  .withAlpha(25),
          child: Icon(
            icon,
            color:
                const Color(0xff0A4D68),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 5,
          ),
          child: Text(
            value,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}