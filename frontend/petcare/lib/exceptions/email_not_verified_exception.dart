class EmailNotVerifiedException implements Exception {
  final String message;
  
  EmailNotVerifiedException(this.message);
  
  @override
  String toString() => message;
}
