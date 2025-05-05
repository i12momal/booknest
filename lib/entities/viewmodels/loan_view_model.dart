// Modelo de vista del Index
class IndexLoanViewModel{
  final String ownerId;
  final String currentHolderId;
  final int bookId;
  final String startDate;
  final String endDate;
  final String format;
  final String state;

  IndexLoanViewModel({
    required this.ownerId,
    required this.currentHolderId,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.state
  });
}

// Modelo de vista del formulario de creación
class CreateLoanViewModel{
  final String ownerId;
  final String currentHolderId;
  final int bookId;
  final String startDate;
  final String endDate;
  final String format;
  final String state;
  final int currentPage;

  CreateLoanViewModel({
    required this.ownerId,
    required this.currentHolderId,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.state,
    required this.currentPage,
  });
}

// Modelo de vista del formulario de edición
class EditLoanViewModel{
  final int id;
  final String ownerId;
  final String currentHolderId;
  final int bookId;
  final String startDate;
  final String endDate;
  final String format;
  final String state;
  final int currentPage;

  EditLoanViewModel({
    required this.id,
    required this.ownerId,
    required this.currentHolderId,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.state,
    required this.currentPage,
  });
}