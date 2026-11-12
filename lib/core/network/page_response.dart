/// Página de resultados (`PageResponse` del backend).
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.page,
    required this.totalElements,
    required this.last,
  });

  final List<T> content;
  final int page;
  final int totalElements;
  final bool last;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) => PageResponse(
    content: (json['content'] as List)
        .map((e) => fromItem(e as Map<String, dynamic>))
        .toList(),
    page: (json['page'] as num).toInt(),
    totalElements: (json['totalElements'] as num).toInt(),
    last: json['last'] as bool,
  );
}
