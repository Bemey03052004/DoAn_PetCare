import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';
import 'chat_screen.dart';

class PetAdoptionRequestsScreen extends StatefulWidget {
  final int petId;
  const PetAdoptionRequestsScreen({super.key, required this.petId});

  @override
  State<PetAdoptionRequestsScreen> createState() => _PetAdoptionRequestsScreenState();
}

class _PetAdoptionRequestsScreenState extends State<PetAdoptionRequestsScreen> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final list = await context.read<PetProvider>().loadAdoptionRequests(widget.petId);
    if (list != null && mounted) {
      setState(() => _items = list);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PetProvider>().isLoading;
    final error = context.watch<PetProvider>().errorMessage;
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu nhận nuôi')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final requesterId = item['userId'];
                      final msg = item['message'] ?? '';
                      final status = (item['status'] ?? 'Pending').toString();
                      return ListTile(
                        title: Text('Người yêu cầu: #$requesterId'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.toString().isNotEmpty) Text(msg),
                            Text('Trạng thái: $status'),
                          ],
                        ),
                        trailing: Builder(builder: (context) {
                          if (status == 'Pending') {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () async {
                                    final ok = await context.read<PetProvider>().declineAdoption(item['id']);
                                    if (ok) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối')));
                                      _load();
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () async {
                                    final ok = await context.read<PetProvider>().acceptAdoption(item['id']);
                                    if (ok) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chấp nhận')));
                                      _load();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: requesterId)),
                                      );
                                    }
                                  },
                                ),
                              ],
                            );
                          }
                          if (status == 'Accepted') {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final ok = await context.read<PetProvider>().reopenAdoption(item['id']);
                                    if (ok) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đưa về chờ duyệt')));
                                      _load();
                                    }
                                  },
                                  icon: const Icon(Icons.history),
                                  label: const Text('Đưa về Pending'),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.chat),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: requesterId)),
                                    );
                                  },
                                ),
                              ],
                            );
                          }
                          // Declined
                          return const SizedBox.shrink();
                        }),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: requesterId)),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}


