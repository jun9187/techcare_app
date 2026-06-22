import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../../services/auth_service.dart';
import 'add_user_sheet.dart';
import 'user_detail_screen.dart';
import 'user_tile.dart';

const Color utmMaroon = Color(0xFF800000);
const Color goldHighlight = Color(0xFFFFD700);
const Color backgroundDark = Color(0xFF0F0F0F);
const Color cardGrey = Color(0xFF1B1B1B);

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterUsers(
    List<Map<String, dynamic>> users,
    String? currentUid,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return users
        .where((user) {
          if (user['id'] == currentUid) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          final searchableValues = [
            user['name'],
            user['email'],
            user['matricNumber'],
            user['faculty'],
            user['role'],
          ];

          return searchableValues.any(
            (value) => value?.toString().toLowerCase().contains(query) ?? false,
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final authService = RepositoryProvider.of<AuthService>(context);
    final authState = context.watch<AuthBloc>().state;
    final currentUid = authState is Authenticated ? authState.uid : null;

    return Scaffold(
      backgroundColor: backgroundDark,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search name, email, matric number, or role',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white54,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                        ),
                      ),
                filled: true,
                fillColor: cardGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: utmMaroon, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: authService.streamAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading users: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final users = _filterUsers(snapshot.data ?? [], currentUid);

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      _searchController.text.trim().isEmpty
                          ? 'No other users found.'
                          : 'No users match your search.',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return UserTile(
                      user: user,
                      onTap: () => _openUserDetail(context, user, authService),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: utmMaroon,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User'),
        onPressed: () => _showAddUserSheet(context),
      ),
    );
  }

  Future<void> _openUserDetail(
    BuildContext context,
    Map<String, dynamic> user,
    AuthService authService,
  ) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailScreen(user: user, authService: authService),
      ),
    );
  }

  Future<void> _showAddUserSheet(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RepositoryProvider.value(
        value: RepositoryProvider.of<AuthService>(context),
        child: const AddUserSheet(),
      ),
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully.')),
      );
    }
  }
}
