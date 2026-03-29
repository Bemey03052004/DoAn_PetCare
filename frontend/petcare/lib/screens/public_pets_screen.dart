import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/pet_provider.dart';
import '../providers/auth_provider.dart';
import '../services/sale_service.dart';
import '../services/boarding_service.dart';
import '../services/image_proxy_service.dart';
import '../services/auth_service.dart';
import '../models/sale_request.dart';
import '../models/boarding_request.dart';
import '../config/api_config.dart';

class PublicPetsScreen extends StatefulWidget {
  const PublicPetsScreen({super.key});

  @override
  State<PublicPetsScreen> createState() => _PublicPetsScreenState();
}

class _PublicPetsScreenState extends State<PublicPetsScreen> with TickerProviderStateMixin {
  final _speciesCtrl = TextEditingController();
  final _keywordCtrl = TextEditingController();
  final _minAgeCtrl = TextEditingController();
  final _maxAgeCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  
  // Filter states for each tab
  String _selectedFilter = 'Tất cả'; // Tất cả, Bán, Giữ hộ, Cho
  String _sortBy = 'Mới nhất'; // Mới nhất, Cũ nhất, Giá thấp, Giá cao
  late TabController _tabController;
  // Adoption tab filters
  String _adoptionFilter = 'Tất cả'; // Tất cả, Đã chấp nhận, Đang chờ, Bị từ chối
  String _adoptionSort = 'Mới nhất'; // Mới nhất, Cũ nhất
  String _activityType = 'Tất cả'; // Tất cả, Cho, Giữ dùm, Bán
  
  // Activity data
  List<SaleRequest> _mySaleRequests = [];
  List<BoardingRequest> _myBoardingRequests = [];
  bool _loadingActivities = false;

  // Selection mode for batch operations
  bool _isSelectionMode = false;
  Set<int> _selectedPetIds = <int>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
        _loadPetsWithFilter();
      }
    });
    Future.microtask(() => _loadPetsWithFilter());
  }

  Widget _buildTabContent(PetProvider provider, String tabName) {
    return Column(
      children: [
        // Filter và Sort bar
        Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (tabName == 'Khám phá' || tabName == 'Của tôi') ...[
                // Filter chips cho pets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Bán'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Giữ hộ'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cho'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Sort dropdown cho pets
                Row(
                  children: [
                    const Text('Sắp xếp: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sortBy,
                      items: const [
                        DropdownMenuItem(value: 'Mới nhất', child: Text('Mới nhất')),
                        DropdownMenuItem(value: 'Cũ nhất', child: Text('Cũ nhất')),
                        DropdownMenuItem(value: 'Giá thấp', child: Text('Giá thấp')),
                        DropdownMenuItem(value: 'Giá cao', child: Text('Giá cao')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                        _loadPetsWithFilter();
                      },
                    ),
                    const Spacer(),
                    if (tabName == 'Khám phá')
                      IconButton(
                        onPressed: () => _showAdvancedSearch(context),
                        icon: const Icon(Icons.tune),
                        tooltip: 'Tìm kiếm nâng cao',
                      ),
                  ],
                ),
              ]
              else if (tabName == 'Lịch sử hoạt động') ...[
                // Activity type filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActivityTypeChip('Tất cả'),
                      const SizedBox(width: 8),
                      _buildActivityTypeChip('Cho'),
                      const SizedBox(width: 8),
                      _buildActivityTypeChip('Giữ dùm'),
                      const SizedBox(width: 8),
                      _buildActivityTypeChip('Bán'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Status filter chips cho adoption requests
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAdoptionFilterChip('Tất cả'),
                      const SizedBox(width: 8),
                      _buildAdoptionFilterChip('Đã chấp nhận'),
                      const SizedBox(width: 8),
                      _buildAdoptionFilterChip('Đang chờ'),
                      const SizedBox(width: 8),
                      _buildAdoptionFilterChip('Bị từ chối'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Sort dropdown cho adoption requests
                Row(
                  children: [
                    const Text('Sắp xếp: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _adoptionSort,
                      items: const [
                        DropdownMenuItem(value: 'Mới nhất', child: Text('Mới nhất')),
                        DropdownMenuItem(value: 'Cũ nhất', child: Text('Cũ nhất')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _adoptionSort = value!;
                        });
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.read<PetProvider>().loadMyAdoptionRequests(),
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Làm mới',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Content based on tab
        if (provider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (provider.errorMessage != null)
          Expanded(child: Center(child: Text(provider.errorMessage!)))
        else
          Expanded(
            child: _buildTabContentBody(provider, tabName),
          ),
      ],
    );
  }

  Widget _buildTabContentBody(PetProvider provider, String tabName) {
    switch (tabName) {
      case 'Khám phá':
        return _buildFilteredPetList(provider);
      case 'Của tôi':
        return _buildMyPetsList(provider);
      case 'Lịch sử hoạt động':
        return _buildMyAdoptionsList(provider);
      default:
        return const Center(child: Text('Tab không xác định'));
    }
  }

  void _loadPetsWithFilter() {
    final provider = context.read<PetProvider>();
    final authUser = context.read<AuthProvider>().user;
    
    // Convert filter to backend format
    String? backendFilter;
    switch (_selectedFilter) {
      case 'Bán':
        backendFilter = 'sale';
        break;
      case 'Giữ hộ':
        backendFilter = 'boarding';
        break;
      case 'Cho':
        backendFilter = 'free';
        break;
      default: // 'Tất cả'
        backendFilter = 'all';
    }
    
    // Convert sort to backend format
    String? backendSort;
    switch (_sortBy) {
      case 'Cũ nhất':
        backendSort = 'oldest';
        break;
      case 'Giá thấp':
        backendSort = 'price_low';
        break;
      case 'Giá cao':
        backendSort = 'price_high';
        break;
      default: // 'Mới nhất'
        backendSort = 'newest';
    }
    
    final lat = authUser?.latitude;
    final lng = authUser?.longitude;
    final dist = double.tryParse(_distanceCtrl.text.trim());
    
    // Load data based on current tab
    switch (_tabController.index) {
      case 0: // Khám phá
        provider.loadPublicPets(
          species: _speciesCtrl.text.trim().isEmpty ? null : _speciesCtrl.text.trim(),
          minAgeMonths: int.tryParse(_minAgeCtrl.text.trim()),
          maxAgeMonths: int.tryParse(_maxAgeCtrl.text.trim()),
          keyword: _keywordCtrl.text.trim().isEmpty ? null : _keywordCtrl.text.trim(),
          lat: lat,
          lng: lng,
          maxDistanceKm: dist,
          filter: backendFilter,
          sortBy: backendSort,
        );
        break;
      case 1: // Của tôi
        if (authUser != null) {
          provider.loadMyPets(authUser.id);
        }
        break;
      case 2: // Lịch sử hoạt động
        _loadActivities();
        break;
    }
  }

  @override
  void dispose() {
    _speciesCtrl.dispose();
    _keywordCtrl.dispose();
    _minAgeCtrl.dispose();
    _maxAgeCtrl.dispose();
    _distanceCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetProvider>();
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('Đã chọn ${_selectedPetIds.length} thú cưng')
            : const Text('Quản lý thú cưng'),
        actions: _isSelectionMode ? [
          if (_selectedPetIds.isNotEmpty) ...[
            IconButton(
              onPressed: _showDeleteSelectedDialog,
              icon: const Icon(Icons.delete),
              tooltip: 'Xóa đã chọn',
            ),
          ],
          IconButton(
            onPressed: _exitSelectionMode,
            icon: const Icon(Icons.close),
            tooltip: 'Thoát chế độ chọn',
          ),
        ] : [
          if (_tabController.index == 1) // Chỉ hiện trong tab "Của tôi"
            IconButton(
              onPressed: _enterSelectionMode,
              icon: const Icon(Icons.checklist),
              tooltip: 'Chọn nhiều',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Khám phá'),
            Tab(text: 'Của tôi'),
            Tab(text: 'Lịch sử hoạt động'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Khám phá
          _buildTabContent(provider, 'Khám phá'),
          // Tab 2: Của tôi
          _buildTabContent(provider, 'Của tôi'),
          // Tab 3: Lịch sử hoạt động
          _buildTabContent(provider, 'Lịch sử hoạt động'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/pets/create'),
        label: const Text('Tạo thú cưng'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
        _loadPetsWithFilter();
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildFilteredPetList(PetProvider provider) {
    final authUser = context.read<AuthProvider>().user;
    
    // Filter out my own pets from discovery
    var filteredPets = provider.publicPets.where((pet) {
      if (authUser != null && pet.ownerId == authUser.id) {
        return false;
      }
      return true;
    }).toList();

    if (filteredPets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Không tìm thấy thú cưng nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredPets.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final pet = filteredPets[index];
        return _buildPetCard(pet);
      },
    );
  }

  Widget _buildMyPetsList(PetProvider provider) {
    var myPets = provider.myPets.toList();
    
    // Apply client-side filter and sort for my pets
    myPets = myPets.where((pet) {
      switch (_selectedFilter) {
        case 'Bán':
          return pet.isForSale == true;
        case 'Giữ hộ':
          return pet.isForBoarding == true;
        case 'Cho':
          return pet.isForSale != true && pet.isForBoarding != true;
        default: // 'Tất cả'
          return true;
      }
    }).toList();

    // Apply client-side sorting
    myPets.sort((a, b) {
      switch (_sortBy) {
        case 'Cũ nhất':
          return (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
        case 'Giá thấp':
          final priceA = a.price ?? 0;
          final priceB = b.price ?? 0;
          return priceA.compareTo(priceB);
        case 'Giá cao':
          final priceA = a.price ?? 0;
          final priceB = b.price ?? 0;
          return priceB.compareTo(priceA);
        default: // 'Mới nhất'
          return (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());
      }
    });

    if (myPets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Bạn chưa có thú cưng nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: myPets.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final pet = myPets[index];
        return _buildMyPetCard(pet);
      },
    );
  }

  Widget _buildMyAdoptionsList(PetProvider provider) {
    if (_loadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Combine all activities
    List<Map<String, dynamic>> allActivities = [];
    
    // Add adoption requests
    for (var item in provider.myAdoptionRequests) {
      allActivities.add({
        'id': item.id,
        'petId': item.petId,
        'petName': item.petName,
        'status': item.status,
        'createdAt': item.createdAt.toIso8601String(),
        'type': 'adoption',
        'typeName': item.petTag, // Use the tag from API
        'message': item.message,
        'isForSale': item.isForSale,
        'isForBoarding': item.isForBoarding,
        'salePrice': item.salePrice,
        'boardingPricePerDay': item.boardingPricePerDay,
      });
    }
    
    // Add sale requests
    for (var item in _mySaleRequests) {
      allActivities.add({
        'id': item.id,
        'petId': item.petId,
        'petName': item.petName,
        'status': item.status,
        'createdAt': item.createdAt?.toIso8601String(),
        'type': 'sale',
        'typeName': 'Bán',
        'amount': item.amount,
        'message': item.message,
      });
    }
    
    // Add boarding requests
    for (var item in _myBoardingRequests) {
      allActivities.add({
        'id': item.id,
        'petId': item.petId,
        'petName': item.petName,
        'status': item.status,
        'createdAt': item.createdAt?.toIso8601String(),
        'type': 'boarding',
        'typeName': 'Giữ dùm',
        'totalAmount': item.totalAmount,
        'message': item.specialInstructions,
      });
    }
    
    // Apply activity type filter
    if (_activityType != 'Tất cả') {
      allActivities = allActivities.where((e) {
        final typeName = e['typeName']?.toString() ?? '';
        return typeName == _activityType;
      }).toList();
    }
    
    // Apply status filter
    allActivities = allActivities.where((e) {
      final status = (e['status'] ?? '').toString();
      switch (_adoptionFilter) {
        case 'Đã chấp nhận':
          return status == 'Accepted' || status == 'Confirmed' || status == 'InProgress';
        case 'Đang chờ':
          return status == 'Pending';
        case 'Bị từ chối':
          return status == 'Declined' || status == 'Cancelled';
        default:
          return true;
      }
    }).toList();
    
    // Apply sorting
    allActivities.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
      return _adoptionSort == 'Cũ nhất' 
        ? dateA.compareTo(dateB)
        : dateB.compareTo(dateA);
    });
    
    if (allActivities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Chưa có hoạt động nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.separated(
      itemCount: allActivities.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = allActivities[index];
        final petId = item['petId'];
        final petName = item['petName']?.toString() ?? 'Thú cưng';
        final status = (item['status'] ?? 'Pending').toString();
        final msg = (item['message'] ?? '').toString();
        final typeName = item['typeName']?.toString() ?? '';
        final type = item['type']?.toString() ?? '';
        final createdAt = item['createdAt'] != null 
            ? DateTime.parse(item['createdAt']) 
            : DateTime.now();
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getActivityTypeColor(type).withOpacity(0.1),
              child: Icon(
                _getActivityTypeIcon(type),
                color: _getActivityTypeColor(type),
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(petName, style: const TextStyle(fontWeight: FontWeight.bold))),
                _buildActivityTypeTag(typeName),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.isNotEmpty) Text(msg),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Trạng thái: $status', 
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimeAgo(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (item['amount'] != null)
                  Text('Số tiền: ${item['amount'].toStringAsFixed(0)} VNĐ'),
                if (item['totalAmount'] != null)
                  Text('Tổng tiền: ${item['totalAmount'].toStringAsFixed(0)} VNĐ'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == 'Pending')
                  IconButton(
                    onPressed: () {
                      // TODO: Implement cancel request
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng hủy yêu cầu sẽ được thêm sau')),
                      );
                    },
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Hủy yêu cầu',
                  ),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/pets/detail', arguments: petId);
                  },
                  icon: const Icon(Icons.visibility),
                  tooltip: 'Xem thú cưng',
                ),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(context, '/pets/detail', arguments: petId);
            },
          ),
        );
      },
    );
  }

  Widget _buildAdoptionFilterChip(String label) {
    final isSelected = _adoptionFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _adoptionFilter = label;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildActivityTypeChip(String label) {
    final isSelected = _activityType == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _activityType = label;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildActivityTypeTag(String type) {
    Color color;
    switch (type) {
      case 'Bán':
        color = Colors.green;
        break;
      case 'Giữ dùm':
        color = Colors.blue;
        break;
      case 'Cho':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getActivityTypeColor(String type) {
    switch (type) {
      case 'adoption':
        return Colors.purple;
      case 'sale':
        return Colors.green;
      case 'boarding':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityTypeIcon(String type) {
    switch (type) {
      case 'adoption':
        return Icons.favorite;
      case 'sale':
        return Icons.shopping_cart;
      case 'boarding':
        return Icons.pets;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Accepted':
        return Icons.check_circle;
      case 'Declined':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  Widget _buildPetCard(pet) {
    final now = DateTime.now();
    final createdAt = pet.createdAt ?? now;
    final isNew = now.difference(createdAt).inDays < 7; // Mới trong 7 ngày
    final isSelected = _isSelectionMode && _selectedPetIds.contains(pet.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: _isSelectionMode 
            ? Checkbox(
                value: isSelected,
                onChanged: (value) => _togglePetSelection(pet.id),
              )
            : Stack(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: pet.imageUrl != null 
                        ? NetworkImage(ImageProxyService.getProxyImageUrl(pet.imageUrl!)) 
                        : null,
                    child: pet.imageUrl == null ? const Icon(Icons.pets) : null,
                  ),
                  if (isNew)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            _buildTypeTag(pet),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${pet.species} • ${pet.ageMonths} tháng'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _formatTimeAgo(createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (pet.price != null && pet.price! > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.attach_money, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      '${pet.price!.toStringAsFixed(0)}₫',
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, '/pets/detail', arguments: pet.id),
      ),
    );
  }

  Widget _buildMyPetCard(pet) {
    final now = DateTime.now();
    final createdAt = pet.createdAt ?? now;
    final isNew = now.difference(createdAt).inDays < 7; // Mới trong 7 ngày
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: pet.imageUrl != null 
                  ? NetworkImage(ImageProxyService.getProxyImageUrl(pet.imageUrl!)) 
                  : null,
              child: pet.imageUrl == null ? const Icon(Icons.pets) : null,
            ),
            if (isNew)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            _buildTypeTag(pet),
            const SizedBox(width: 8),
            _buildPublishStatusChip(pet),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${pet.species} • ${pet.ageMonths} tháng'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _formatTimeAgo(createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (pet.price != null && pet.price! > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.attach_money, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      '${pet.price!.toStringAsFixed(0)}₫',
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/pets/adoptions', arguments: pet.id),
              icon: const Icon(Icons.people),
              tooltip: 'Xem yêu cầu nhận nuôi',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/pets/detail', arguments: pet.id),
              icon: const Icon(Icons.edit),
              tooltip: 'Chỉnh sửa',
            ),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, '/pets/detail', arguments: pet.id),
      ),
    );
  }

  Widget _buildPublishStatusChip(pet) {
    Color color;
    String text;
    
    if (pet.isAdopted) {
      color = Colors.grey;
      text = 'ĐÃ NHẬN NUÔI';
    } else if (pet.isPublic) {
      color = Colors.green;
      text = 'CÔNG KHAI';
    } else {
      color = Colors.orange;
      text = 'RIÊNG TƯ';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeTag(pet) {
    String tag = '';
    Color color = Colors.grey;
    
    if (pet.isForSale == true) {
      tag = 'BÁN';
      color = Colors.orange;
    } else if (pet.isForBoarding == true) {
      tag = 'GIỮ HỘ';
      color = Colors.blue;
    } else {
      tag = 'CHO';
      color = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _showAdvancedSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với nút đóng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tìm kiếm nâng cao',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Form tìm kiếm
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Loài
                    TextField(
                      controller: _speciesCtrl,
                      decoration: InputDecoration(
                        labelText: 'Loài (Dog/Cat/...)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.pets),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tuổi
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAgeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tuổi tối thiểu',
                              hintText: 'Tháng',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.cake),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxAgeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tuổi tối đa',
                              hintText: 'Tháng',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.cake),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Từ khóa
                    TextField(
                      controller: _keywordCtrl,
                      decoration: InputDecoration(
                        labelText: 'Từ khóa',
                        hintText: 'Tên, mô tả...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Bán kính
                    TextField(
                      controller: _distanceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Bán kính tìm kiếm',
                        hintText: 'Km',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _speciesCtrl.clear();
                      _minAgeCtrl.clear();
                      _maxAgeCtrl.clear();
                      _keywordCtrl.clear();
                      _distanceCtrl.clear();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Xóa tất cả'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _loadPetsWithFilter();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Tìm kiếm'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadActivities() async {
    if (_loadingActivities) return;
    
    setState(() {
      _loadingActivities = true;
    });
    
    try {
      final authService = context.read<AuthProvider>().authService;
      final saleService = SaleService(authService);
      final boardingService = BoardingService(authService);
      
      // Load all activities in parallel
      final results = await Future.wait([
        saleService.getMySaleRequests(),
        boardingService.getMyBoardingRequests(),
        context.read<PetProvider>().loadMyAdoptionRequests(),
      ]);
      
      setState(() {
        _mySaleRequests = results[0] as List<SaleRequest>;
        _myBoardingRequests = results[1] as List<BoardingRequest>;
        _loadingActivities = false;
      });
    } catch (e) {
      setState(() {
        _loadingActivities = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải hoạt động: $e')),
        );
      }
    }
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedPetIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPetIds.clear();
    });
  }

  void _togglePetSelection(int petId) {
    setState(() {
      if (_selectedPetIds.contains(petId)) {
        _selectedPetIds.remove(petId);
      } else {
        _selectedPetIds.add(petId);
      }
    });
  }

  void _showDeleteSelectedDialog() {
    if (_selectedPetIds.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thú cưng đã chọn'),
        content: Text('Bạn có chắc chắn muốn xóa ${_selectedPetIds.length} thú cưng đã chọn? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSelectedPets();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedPets() async {
    if (_selectedPetIds.isEmpty) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/pets/batch'),
        headers: await _authHeaders,
        body: json.encode(_selectedPetIds.toList()),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa ${_selectedPetIds.length} thú cưng thành công'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the list
        _loadPetsWithFilter();
        
        // Exit selection mode
        _exitSelectionMode();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${errorData['message'] ?? 'Không thể xóa thú cưng'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, String>> get _authHeaders async {
    final authService = AuthService();
    final token = await authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}



