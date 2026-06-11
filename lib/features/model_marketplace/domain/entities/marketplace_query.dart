enum ModelSort {
  popularity, // Downloads
  rating,
  size,
}

enum RamFilter {
  all,
  low,  // < 4GB
  mid,  // 4GB - 8GB
  high, // > 8GB
}

class MarketplaceFilters {
  final String category;
  final String searchQuery;
  final ModelSort sortBy;
  final RamFilter ramFilter;

  const MarketplaceFilters({
    this.category = 'Chat',
    this.searchQuery = '',
    this.sortBy = ModelSort.popularity,
    this.ramFilter = RamFilter.all,
  });

  MarketplaceFilters copyWith({
    String? category,
    String? searchQuery,
    ModelSort? sortBy,
    RamFilter? ramFilter,
  }) {
    return MarketplaceFilters(
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      ramFilter: ramFilter ?? this.ramFilter,
    );
  }
}
