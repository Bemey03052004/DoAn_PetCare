import 'package:flutter/material.dart';
import '../services/stats_service.dart';
import '../services/auth_service.dart';

class UserStatsScreen extends StatefulWidget {
  const UserStatsScreen({super.key});

  @override
  State<UserStatsScreen> createState() => _UserStatsScreenState();
}

class _UserStatsScreenState extends State<UserStatsScreen> {
  final _service = StatsService(AuthService());
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getUserStats();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Thống kê cá nhân',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Theo dõi hoạt động của bạn',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _error != null
                    ? _buildErrorWidget()
                    : _buildStatsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    return RefreshIndicator(
      onRefresh: _load,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            _buildOverviewSection(),
            const SizedBox(height: 24),
            
            // Pet Management Stats
            _buildSectionCard(
              title: 'Quản lý thú cưng',
              icon: Icons.pets,
              color: Colors.blue,
              children: [
                _buildStatCard(
                  'Thú cưng đã đăng',
                  _data!['givenCount'].toString(),
                  Icons.add_circle_outline,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Đã được nhận nuôi',
                  _data!['givenAdopted'].toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                _buildStatCard(
                  'Đang chờ nhận nuôi',
                  (_data!['givenCount'] - _data!['givenAdopted']).toString(),
                  Icons.schedule,
                  Colors.orange,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Adoption Requests Stats
            _buildSectionCard(
              title: 'Yêu cầu nhận nuôi',
              icon: Icons.favorite,
              color: Colors.pink,
              children: [
                _buildStatCard(
                  'Yêu cầu đã gửi',
                  _data!['requestedCount'].toString(),
                  Icons.send,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Được chấp nhận',
                  _data!['acceptedCount'].toString(),
                  Icons.thumb_up,
                  Colors.green,
                ),
                _buildStatCard(
                  'Đang chờ duyệt',
                  _data!['pendingCount'].toString(),
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Bị từ chối',
                  (_data!['requestedCount'] - _data!['acceptedCount'] - _data!['pendingCount']).toString(),
                  Icons.thumb_down,
                  Colors.red,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Received Requests Stats
            _buildSectionCard(
              title: 'Yêu cầu nhận được',
              icon: Icons.inbox,
              color: Colors.indigo,
              children: [
                _buildStatCard(
                  'Yêu cầu đang chờ',
                  _data!['receivedPending'].toString(),
                  Icons.notifications_active,
                  Colors.amber,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Success Rate
            _buildSuccessRateCard(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final totalPets = _data!['givenCount'] as int;
    final adoptedPets = _data!['givenAdopted'] as int;
    final totalRequests = _data!['requestedCount'] as int;
    final acceptedRequests = _data!['acceptedCount'] as int;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan hoạt động',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  'Thú cưng',
                  totalPets.toString(),
                  Icons.pets,
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Đã nhận nuôi',
                  adoptedPets.toString(),
                  Icons.home,
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Yêu cầu',
                  totalRequests.toString(),
                  Icons.favorite,
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Thành công',
                  acceptedRequests.toString(),
                  Icons.check,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRateCard() {
    final totalPets = _data!['givenCount'] as int;
    final adoptedPets = _data!['givenAdopted'] as int;
    final totalRequests = _data!['requestedCount'] as int;
    final acceptedRequests = _data!['acceptedCount'] as int;
    
    final adoptionRate = totalPets > 0 ? (adoptedPets / totalPets * 100) : 0.0;
    final requestSuccessRate = totalRequests > 0 ? (acceptedRequests / totalRequests * 100) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Tỷ lệ thành công',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tỷ lệ nhận nuôi',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${adoptionRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tỷ lệ yêu cầu thành công',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${requestSuccessRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


