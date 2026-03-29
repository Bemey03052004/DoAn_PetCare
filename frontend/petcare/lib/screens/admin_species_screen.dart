import 'package:flutter/material.dart';
import '../services/species_service.dart';
import '../models/species.dart';

class AdminSpeciesScreen extends StatefulWidget {
  const AdminSpeciesScreen({super.key});

  @override
  State<AdminSpeciesScreen> createState() => _AdminSpeciesScreenState();
}

class _AdminSpeciesScreenState extends State<AdminSpeciesScreen> {
  final _service = SpeciesService();
  List<Species> _items = [];
  bool _loading = true;
  String? _error;
  final Set<int> _updatingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _service.getAll();
      setState(() { _items = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _showUpsert({Species? sp}) async {
    final nameCtrl = TextEditingController(text: sp?.name ?? '');
    final descCtrl = TextEditingController(text: sp?.description ?? '');
    bool isActive = sp?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(sp == null ? 'Thêm loài' : 'Sửa loài'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Tên loài *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                      title: const Text('Kích hoạt'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  String? error;
                  try {
                    if (sp == null) {
                      await _service.create(name: nameCtrl.text.trim(), description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), isActive: isActive);
                    } else {
                      await _service.update(id: sp.id, name: nameCtrl.text.trim(), description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), isActive: isActive);
                    }
                    navigator.pop();
                    await _load();
                  } catch (e) {
                    error = 'Lỗi: $e';
                  }
                  if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
                },
                child: const Text('Lưu'),
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(Species sp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa loài'),
        content: Text('Bạn chắc chắn muốn xóa "${sp.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    ) ?? false;
    if (!confirm) return;
    try {
      await _service.delete(sp.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý loài'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _showUpsert(), icon: const Icon(Icons.add)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUpsert(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : (_items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category_outlined, size: 56, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('Chưa có loài nào', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showUpsert(),
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm loài'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final sp = _items[i];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                child: const Icon(Icons.category, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            sp.name,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: sp.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            sp.isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(color: sp.isActive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (sp.description != null && sp.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        sp.description!,
                                        style: const TextStyle(color: Colors.black54),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Spacer(),
                                        IconButton(onPressed: () => _showUpsert(sp: sp), icon: const Icon(Icons.edit_outlined)),
                                        IconButton(onPressed: () => _delete(sp), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              StatefulBuilder(
                                builder: (context, setInner) {
                                  final isUpdating = _updatingIds.contains(sp.id);
                                  return Switch(
                                    value: sp.isActive,
                                    onChanged: isUpdating
                                        ? null
                                        : (v) async {
                                            setState(() { _updatingIds.add(sp.id); });
                                            String? errorMsg;
                                            final messenger = ScaffoldMessenger.of(context);
                                            try {
                                              await _service.update(
                                                id: sp.id,
                                                name: sp.name,
                                                description: sp.description,
                                                isActive: v,
                                              );
                                              await _load();
                                            } catch (e) {
                                              errorMsg = 'Cập nhật thất bại: $e';
                                            } finally {
                                              if (mounted) setState(() { _updatingIds.remove(sp.id); });
                                            }
                                            if (errorMsg != null) {
                                              messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
                                            }
                                          },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )),
    );
  }
}


