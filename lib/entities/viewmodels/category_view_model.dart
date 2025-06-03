// Modelo de vista del formulario de creación
class CreateCategoryViewModel{
  final String name;
  final String image;
  final String description;

  CreateCategoryViewModel({
    required this.name,
    required this.image,
    required this.description,
  });
}

// Modelo de vista del formulario de edición
class EditCategoryViewModel{
  final int id;
  final String name;
  final String image;
  final String description;

  EditCategoryViewModel({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
  });
}