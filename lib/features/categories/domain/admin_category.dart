class AdminCategory {
  const AdminCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory AdminCategory.fromMap(Map<String, dynamic> map) {
    return AdminCategory(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
    );
  }
}
