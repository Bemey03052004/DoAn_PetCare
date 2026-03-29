import 'package:flutter/material.dart';
import 'package:petcare/services/image_proxy_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/pet_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load pets when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<PetProvider>().loadMyPets(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final petProvider = context.watch<PetProvider>();

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with User Info
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade400,
                      Colors.purple.shade400,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xin chào,',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (user.isAdmin)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'ADMIN',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _buildNotificationButton(),
                            const SizedBox(width: 8),
                            _buildProfileButton(),
                            const SizedBox(width: 8),
                            _buildLogoutButton(auth),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: user.isAdmin ? [_buildAdminMenu()] : [],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  _buildQuickStats(petProvider),
                  const SizedBox(height: 24),

                  // Main Actions
                  _buildMainActions(),
                  const SizedBox(height: 24),

                  // Recent Pets
                  _buildRecentPets(petProvider),
                  const SizedBox(height: 24),

                  // Admin Stats (if admin)
                  if (user.isAdmin) ...[
                    _buildAdminStats(),
                    const SizedBox(height: 24),
                  ],

                  // Personal Stats
                  _buildPersonalStats(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Builder(
      builder: (context) {
        final notif = context.watch<NotificationProvider>();
        final unread = notif.items.where((e) => !e.isRead).length;
        return Stack(
          alignment: Alignment.center,
          children: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () async {
                await context.read<NotificationProvider>().load();
                if (context.mounted) {
                  Navigator.of(context).pushNamed('/notifications');
                }
              },
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : unread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProfileButton() {
    return IconButton(
      icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
    );
  }

  Widget _buildLogoutButton(AuthProvider auth) {
    return IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
    );
  }

  Widget _buildAdminMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
      onSelected: (value) {
        switch (value) {
          case 'dashboard':
            Navigator.of(context).pushNamed('/admin/dashboard');
            break;
          case 'pets':
            Navigator.of(context).pushNamed('/admin/pets');
            break;
          case 'transactions':
            Navigator.of(context).pushNamed('/admin/transactions');
            break;
          case 'users':
            Navigator.of(context).pushNamed('/admin/users');
            break;
          case 'boarding':
            Navigator.of(context).pushNamed('/admin/boarding');
            break;
          case 'adoption':
            Navigator.of(context).pushNamed('/admin/adoption');
            break;
          case 'species':
            Navigator.of(context).pushNamed('/admin/species');
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'dashboard',
          child: Row(
            children: [
              Icon(Icons.dashboard),
              SizedBox(width: 8),
              Text('Dashboard'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'pets',
          child: Row(
            children: [
              Icon(Icons.pets),
              SizedBox(width: 8),
              Text('Manage Pets'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'transactions',
          child: Row(
            children: [
              Icon(Icons.payment),
              SizedBox(width: 8),
              Text('Transactions'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'users',
          child: Row(
            children: [
              Icon(Icons.people),
              SizedBox(width: 8),
              Text('Manage Users'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'boarding',
          child: Row(
            children: [
              Icon(Icons.hotel),
              SizedBox(width: 8),
              Text('Boarding Requests'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'adoption',
          child: Row(
            children: [
              Icon(Icons.favorite),
              SizedBox(width: 8),
              Text('Adoption Requests'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'species',
          child: Row(
            children: [
              Icon(Icons.category),
              SizedBox(width: 8),
              Text('Manage Species'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(PetProvider petProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Thú cưng của tôi',
              petProvider.myPets.length.toString(),
              Icons.pets,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Thú cưng công khai',
              petProvider.myPets.where((p) => p.isPublic).length.toString(),
              Icons.public,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Đang bán',
              petProvider.myPets.where((p) => p.isForSale).length.toString(),
              Icons.sell,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
                  children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hành động chính',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Khám phá thú cưng',
                'Tìm kiếm và khám phá thú cưng',
                Icons.explore,
                Colors.blue,
                () => Navigator.pushNamed(context, '/pets/public'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Tạo thú cưng',
                'Thêm thú cưng mới',
                Icons.add_circle,
                Colors.green,
                () => Navigator.pushNamed(context, '/pets/create'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPets(PetProvider petProvider) {
    final recentPets = petProvider.myPets.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Thú cưng gần đây',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/pets/public'),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentPets.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.pets, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Chưa có thú cưng nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy tạo thú cưng đầu tiên của bạn!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentPets.length,
              itemBuilder: (context, index) {
                final pet = recentPets[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildPetCard(pet),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPetCard(pet) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/pets/detail',
          arguments: pet.id,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: pet.imageUrl != null
                    ? Image.network(
                        ImageProxyService.getProxyImageUrl(pet.imageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.pets, size: 40, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.pets, size: 40, color: Colors.grey),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pet.species,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (pet.isForSale && pet.price != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${pet.price!.toStringAsFixed(0)}₫',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildAdminStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê Admin',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          'Dashboard Admin',
          'Xem tổng quan hệ thống',
          Icons.dashboard,
          Colors.purple,
          () => Navigator.pushNamed(context, '/stats/admin'),
        ),
      ],
    );
  }

  Widget _buildPersonalStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê cá nhân',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          'Thống kê của tôi',
          'Xem thống kê cá nhân',
          Icons.bar_chart,
          Colors.orange,
          () => Navigator.pushNamed(context, '/stats/me'),
        ),
      ],
    );
  }
}
