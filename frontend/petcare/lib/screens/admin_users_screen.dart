import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/role_service.dart';
import '../services/auth_service.dart';
import '../models/admin_models.dart';
import '../models/role.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  List<UserDto> _users = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final users = await _adminService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserStatus(int userId, bool isActive) async {
    try {
      await _adminService.updateUserStatus(userId, isActive);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Kích hoạt người dùng thành công' : 'Vô hiệu hóa người dùng thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _assignRole(int userId, String roleName) async {
    try {
      await _adminService.assignRole(userId, roleName);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gán quyền $roleName thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _manageRoles(UserDto user) async {
    final roleService = RoleService(AuthService());
    try {
      final roles = await roleService.getAllRoles();
      // Lấy roles mới nhất của user từ server (tránh lệch dữ liệu)
      final latestUserRoles = await _adminService.getUserRolesAdmin(user.id);
      final selectedNames = latestUserRoles.toSet();

      // Show dialog with checkbox list
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogCtx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              return AlertDialog(
                title: Text('Quyền của ${user.fullName}'),
                content: SizedBox(
                  width: 380,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: roles.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final Role role = roles[index];
                      final bool checked = selectedNames.contains(role.name);
                      return CheckboxListTile(
                        value: checked,
                        title: Text(role.name),
                        subtitle: (role.description != null && role.description!.isNotEmpty)
                            ? Text(role.description!)
                            : null,
                        onChanged: (val) async {
                          // Optimistic update
                          setState(() {
                            if (val == true) {
                              selectedNames.add(role.name);
                            } else {
                              selectedNames.remove(role.name);
                            }
                          });
                          try {
                            // Gửi toàn bộ danh sách roles hiện tại sau khi thay đổi
                            final toUpdate = selectedNames.isEmpty
                                ? <String>['User']
                                : selectedNames.toList();
                            await _adminService.updateUserRoles(user.id, toUpdate);
                            await _loadUsers();
                          } catch (e) {
                            // Revert on error
                            setState(() {
                              if (val == true) {
                                selectedNames.remove(role.name);
                              } else {
                                selectedNames.add(role.name);
                              }
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi cập nhật quyền: $e')),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh sách quyền: $e')),
      );
    }
  }

  Future<void> _removeRole(int userId, int roleId) async {
    try {
      await _adminService.removeRole(userId, roleId);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa quyền thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi: $_error',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có người dùng nào',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user.isActive ? Colors.green : Colors.red,
                                child: Text(
                                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email: ${user.email}'),
                                  if (user.phoneNumber.isNotEmpty)
                                    Text('SĐT: ${user.phoneNumber}'),
                                  Text(
                                    'Trạng thái: ${user.isActive ? "Hoạt động" : "Bị khóa"}',
                                    style: TextStyle(
                                      color: user.isActive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (user.roles.isNotEmpty)
                                    Text('Quyền: ${user.roles.join(", ")}'),
                                  Text(
                                    'Tạo lúc: ${_formatDateTime(user.createdAt)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'toggle_status':
                                      await _updateUserStatus(user.id, !user.isActive);
                                      break;
                                    case 'manage_roles':
                                      await _manageRoles(user);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'toggle_status',
                                    child: Row(
                                      children: [
                                        Icon(
                                          user.isActive ? Icons.block : Icons.check_circle,
                                          color: user.isActive ? Colors.red : Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(user.isActive ? 'Khóa tài khoản' : 'Kích hoạt tài khoản'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'manage_roles',
                                    child: Row(
                                      children: [
                                        Icon(Icons.security, color: Colors.purple),
                                        SizedBox(width: 8),
                                        Text('Quản lý quyền (tích chọn)'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
