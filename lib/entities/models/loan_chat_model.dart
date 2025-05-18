class LoanChat {
  final int id;
  final int loanId;
  final int loanCompensationId;
  final String user_1;
  final String user_2;
  final bool archivedByOwner;
  final bool archivedByHolder;
  final String content;
  final bool deleteByOwner;
  final bool deleteByHolder;

  LoanChat({
    required this.id,
    required this.loanId,
    required this.loanCompensationId,
    required this.user_1,
    required this.user_2,
    required this.archivedByOwner,
    required this.archivedByHolder,
    required this.content,
    required this.deleteByOwner,
    required this.deleteByHolder
  });

  factory LoanChat.fromJson(Map<String, dynamic> json) {
    return LoanChat(
      id: json['id'],
      loanId: json['loanId'],
      loanCompensationId: json['loanCompensationId'],
      user_1: json['user_1'] ?? '',
      user_2: json['user_2'] ?? '',
      archivedByOwner: json['archivedByOwner'] ?? false,
      archivedByHolder: json['archivedByHolder'] ?? false,
      deleteByOwner: json['deleteByOwner'] ?? false,
      deleteByHolder: json['deleteByHolder'] ?? false,
      content: json['content'] ?? '',
    );
  }
}
