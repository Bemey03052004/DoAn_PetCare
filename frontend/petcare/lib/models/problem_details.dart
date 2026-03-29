class ProblemDetails {
  final String? type;
  final String? title;
  final int? status;
  final String? detail;
  final String? instance;
  final String? traceId;
  final Map<String, List<String>> errors;

  ProblemDetails({
    this.type,
    this.title,
    this.status,
    this.detail,
    this.instance,
    this.traceId,
    Map<String, List<String>>? errors,
  }) : errors = errors ?? const {};

  factory ProblemDetails.fromJson(Map<String, dynamic> json) {
    final rawErrors = <String, List<String>>{};
    final e = json['errors'];
    if (e is Map) {
      e.forEach((k, v) {
        if (v is List) {
          rawErrors[k.toString()] = v.map((x) => x.toString()).toList();
        } else if (v is String) {
          rawErrors[k.toString()] = [v];
        }
      });
    }
    return ProblemDetails(
      type: json['type']?.toString(),
      title: json['title']?.toString(),
      status: json['status'] is int ? json['status'] : int.tryParse('${json['status']}'),
      detail: json['detail']?.toString(),
      instance: json['instance']?.toString(),
      traceId: json['traceId']?.toString(),
      errors: rawErrors,
    );
  }

  /// Trích các message lỗi phẳng (dễ show Snackbar/List)
  List<String> allMessages() {
    final msgs = <String>[];
    if (title != null && title!.isNotEmpty) msgs.add(title!);
    if (detail != null && detail!.isNotEmpty) msgs.add(detail!);
    errors.forEach((_, list) => msgs.addAll(list));
    return msgs;
  }
}
