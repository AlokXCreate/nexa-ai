class SearchFilters {
  final String query;
  final String category; // 'All', 'Chat', 'Coding', 'Reasoning', 'Writing', 'Translation', 'Vision'
  final String paramSize; // 'All', 'small' (<= 3B), 'medium' (3B - 7B), 'large' (> 7B)
  final String ramFilter; // 'All', 'low' (<= 4GB), 'mid' (4GB - 8GB), 'high' (> 8GB)
  final String language; // 'All', 'English', 'French', 'German', 'Chinese', 'Spanish', 'Multilingual'
  final String sortBy; // 'popularity', 'rating', 'size'

  const SearchFilters({
    this.query = '',
    this.category = 'All',
    this.paramSize = 'All',
    this.ramFilter = 'All',
    this.language = 'All',
    this.sortBy = 'popularity',
  });

  SearchFilters copyWith({
    String? query,
    String? category,
    String? paramSize,
    String? ramFilter,
    String? language,
    String? sortBy,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      category: category ?? this.category,
      paramSize: paramSize ?? this.paramSize,
      ramFilter: ramFilter ?? this.ramFilter,
      language: language ?? this.language,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
