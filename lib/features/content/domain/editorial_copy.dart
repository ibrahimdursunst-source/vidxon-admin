class EditorialCopy {
  const EditorialCopy({this.title = '', this.description = ''});

  final String title;
  final String description;

  bool get hasContent =>
      title.trim().isNotEmpty || description.trim().isNotEmpty;
}
