class SelectableStudentRow {
  const SelectableStudentRow({
    required this.id,
    required this.name,
    this.imageUrl,
    this.subtitle,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final String? subtitle;
}
