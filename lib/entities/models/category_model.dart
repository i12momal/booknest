// Define la entidad Categoría en el modelo de datos.
class Category{
  final int id;
  final String name;
  final String image;
  final String description;

  Category({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
  });
}