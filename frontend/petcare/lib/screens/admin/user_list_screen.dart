import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../models/role.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/role_service.dart';
import '../../services/auth_service.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    // Load users when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadAllUsers();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = Provider.of<AuthProvider>(context).user;
    
    if (currentUser == null || !currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unauthorized')),
        body: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: userProvider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : userProvider.errorMessage != null
              ? Center(child: Text('Error: ${userProvider.errorMessage}'))
              : ListView.builder(
                  itemCount: userProvider.users.length,
                  itemBuilder: (context, index) {
                    final user = userProvider.users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(user.fullName.substring(0, 1)),
                        ),
                        title: Text(user.fullName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Text(
                              'Roles: ${user.roles.join(", ")}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _showUserActions(context, user);
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserDetailScreen(userId: user.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Reload users
          userProvider.loadAllUsers();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  void _showUserActions(BuildContext context, User user) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    
    // Don't allow the current user to delete themselves
    final isSelf = currentUser?.id == user.id;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserDetailScreen(userId: user.id),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Manage Roles'),
                onTap: () {
                  Navigator.pop(context);
                  _showManageRolesDialog(context, user);
                },
              ),
              if (!isSelf) // Don't allow deleting self
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete User', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await _confirmDeletion(context, user);
                    if (confirmed) {
                      await userProvider.deleteUser(user.id);
                      userProvider.loadAllUsers(); // Reload the list
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  Future<bool> _confirmDeletion(BuildContext context, User user) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text('Are you sure you want to delete ${user.fullName}? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
  
  void _showManageRolesDialog(BuildContext context, User user) {
    final adminService = AdminService();
    final roleService = RoleService(AuthService());
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Gán quyền cho ${user.fullName}')
          ,
          content: FutureBuilder<List<Role>>(
            future: roleService.getAllRoles(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Text('Không tải được danh sách quyền');
              }

              final roles = snapshot.data!;
              final selected = Set<String>.from(user.roles);

              return StatefulBuilder(
                builder: (context, setState) {
                  return SizedBox(
                    width: 360,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: roles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final role = roles[index];
                        final checked = selected.contains(role.name);
                        return CheckboxListTile(
                          value: checked,
                          title: Text(role.name),
                          subtitle: role.description != null && role.description!.isNotEmpty
                              ? Text(role.description!)
                              : null,
                          onChanged: (val) async {
                            // Optimistic UI
                            setState(() {
                              if (val == true) {
                                selected.add(role.name);
                              } else {
                                selected.remove(role.name);
                              }
                            });
                            try {
                              if (val == true) {
                                await adminService.assignRole(user.id, role.name);
                              } else {
                                await adminService.removeRole(user.id, role.id);
                              }
                              await userProvider.loadAllUsers();
                            } catch (_) {
                              // Revert UI on error
                              setState(() {
                                if (val == true) {
                                  selected.remove(role.name);
                                } else {
                                  selected.add(role.name);
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cập nhật quyền thất bại')),
                              );
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
  
  Future<List<String>?> _getAllAvailableRoles(BuildContext context) async {
    try {
      // In a real app, you would fetch this from the role service
      // For this example, we'll hardcode a few roles
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      return ['User', 'Admin', 'Moderator', 'PetOwner', 'Veterinarian'];
    } catch (e) {
      return null;
    }
  }
}

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Future<User?> _userFuture;
  
  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }
  
  Future<User?> _loadUser() async {
    return await Provider.of<UserProvider>(context, listen: false)
        .getUserById(widget.userId);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (snapshot.data == null) {
            return const Center(child: Text('User not found'));
          }
          
          final user = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User profile header
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // User details
                const Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailItem('Phone', user.phone ?? 'Not provided'),
                _buildDetailItem('Address', user.address ?? 'Not provided'),
                _buildDetailItem(
                  'Member Since',
                  '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                ),
                
                const SizedBox(height: 24),
                
                // Roles section
                const Text(
                  'Roles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: user.roles.map((role) {
                    return Chip(label: Text(role));
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
