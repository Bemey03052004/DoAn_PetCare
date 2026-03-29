import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class AdminPetsScreen extends StatefulWidget {
  const AdminPetsScreen({super.key});

  @override
  State<AdminPetsScreen> createState() => _AdminPetsScreenState();
}

class _AdminPetsScreenState extends State<AdminPetsScreen> {
  late AdminService _adminService;
  List<PetDto> _pets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService(context.read<AuthProvider>().authService);
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final pets = await _adminService.getAllPets();
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePet(int id) async {
    try {
      await _adminService.deletePet(id);
      await _loadPets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting pet: $e')),
        );
      }
    }
  }

  Future<void> _showEditDialog(PetDto pet) async {
    final nameController = TextEditingController(text: pet.name);
    final speciesController = TextEditingController(text: pet.species);
    final breedController = TextEditingController(text: pet.breed);
    final ageController = TextEditingController(text: pet.age.toString());
    final genderController = TextEditingController(text: pet.gender);
    final descriptionController = TextEditingController(text: pet.description);
    final imageUrlController = TextEditingController(text: pet.imageUrl);
    final priceController = TextEditingController(text: pet.price.toString());
    
    bool isPublic = pet.isPublic;
    bool isAdopted = pet.isAdopted;
    bool isHidden = pet.isHidden;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Pet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: speciesController,
                  decoration: const InputDecoration(labelText: 'Species'),
                ),
                TextField(
                  controller: breedController,
                  decoration: const InputDecoration(labelText: 'Breed'),
                ),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: genderController,
                  decoration: const InputDecoration(labelText: 'Gender'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isPublic,
                      onChanged: (value) => setState(() => isPublic = value ?? false),
                    ),
                    const Text('Public'),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isAdopted,
                      onChanged: (value) => setState(() => isAdopted = value ?? false),
                    ),
                    const Text('Adopted'),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isHidden,
                      onChanged: (value) => setState(() => isHidden = value ?? false),
                    ),
                    const Text('Hidden'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final updateDto = UpdatePetDto(
          name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
          species: speciesController.text.trim().isEmpty ? null : speciesController.text.trim(),
          breed: breedController.text.trim().isEmpty ? null : breedController.text.trim(),
          ageMonths: int.tryParse(ageController.text.trim()),
          gender: genderController.text.trim().isEmpty ? null : genderController.text.trim(),
          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
          imageUrl: imageUrlController.text.trim().isEmpty ? null : imageUrlController.text.trim(),
          price: double.tryParse(priceController.text.trim()),
          isPublic: isPublic,
          isAdopted: isAdopted,
          isHidden: isHidden,
        );

        await _adminService.updatePet(pet.id, updateDto);
        await _loadPets();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pet updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating pet: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Pets')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPets,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Pets'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPets,
          ),
        ],
      ),
      body: _pets.isEmpty
          ? const Center(child: Text('No pets found'))
          : ListView.builder(
              itemCount: _pets.length,
              itemBuilder: (context, index) {
                final pet = _pets[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (pet.imageUrl?.isNotEmpty ?? false)
                          ? NetworkImage(pet.imageUrl!)
                          : null,
                      child: (pet.imageUrl?.isEmpty ?? true)
                          ? const Icon(Icons.pets)
                          : null,
                    ),
                    title: Text(pet.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${pet.species} - ${pet.breed}'),
                        Text('Owner: ${pet.ownerName}'),
                        Row(
                          children: [
                            if (pet.isPublic)
                              const Chip(
                                label: Text('Public'),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            if (pet.isAdopted)
                              const Chip(
                                label: Text('Adopted'),
                                backgroundColor: Colors.blue,
                                labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            if (pet.isHidden)
                              const Chip(
                                label: Text('Hidden'),
                                backgroundColor: Colors.red,
                                labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(pet),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteDialog(pet),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showDeleteDialog(PetDto pet) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Are you sure you want to delete ${pet.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deletePet(pet.id);
    }
  }
}
