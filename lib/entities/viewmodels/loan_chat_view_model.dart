// Modelo de vista del formulario de creación.
class CreateLoanChatViewModel {
  final int id;
  final String loanId;
  final String user_1;
  final String user_2;
  final bool archivedByOwner;
  final bool archivedByHolder;
  final String content;

  CreateLoanChatViewModel({
    required this.id,
    required this.loanId,
    required this.user_1,
    required this.user_2,
    required this.archivedByOwner,
    required this.archivedByHolder,
    required this.content
  });
}