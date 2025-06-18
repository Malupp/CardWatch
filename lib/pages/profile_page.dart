import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Profilo'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(),
                _buildStatsSection(),
                _buildProfileActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blue[50],
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nome Utente',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            'Membro dal 2023',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFollowButton(),
              const SizedBox(width: 10),
              _buildMessageButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.blue),
      ),
      child: const Text('SEGUITI'),
    );
  }

  Widget _buildMessageButton() {
    return ElevatedButton(
      onPressed: () {},
      child: const Text('MESSAGGIO'),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Carte', '1,234'),
          _buildStatItem('Scambi', '56'),
          _buildStatItem('Valutazione', '4.8'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProfileActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildActionTile(Icons.collections, 'Le Mie Collezioni'),
          _buildActionTile(Icons.favorite, 'Preferiti'),
          _buildActionTile(Icons.history, 'Cronologia Scambi'),
          _buildActionTile(Icons.star, 'Achievements'),
          _buildActionTile(Icons.exit_to_app, 'Logout'),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}