import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/models.dart';
import '../models/explore_filter_options.dart';
import 'widgets/explore_filter_bar.dart';
import 'widgets/explore_option_sheets.dart';
import 'widgets/explore_search_app_bar.dart';
import 'widgets/explore_states.dart';
import 'widgets/explore_story_card.dart';

final _genresProvider = FutureProvider<List<Genre>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<List<dynamic>>(ApiEndpoints.genres);
  return data.map((g) => Genre.fromJson(g as Map<String, dynamic>)).toList();
});

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Story> _stories = [];

  Timer? _debounce;
  String _draftQuery = '';
  String _query = '';
  String? _selectedGenreId;
  String? _selectedType;
  String? _selectedStatus;
  ExploreSortOption _selectedSort = exploreSortOptions.first;
  int _nextPage = 1;
  int _requestId = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  bool get _hasActiveFilters {
    return _query.isNotEmpty ||
        _selectedGenreId != null ||
        _selectedType != null ||
        _selectedStatus != null ||
        _selectedSort != exploreSortOptions.first;
  }

  @override
  void initState() {
    super.initState();
    _fetchStories(page: 1, requestId: _requestId);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _draftQuery = value);
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () {
      final nextQuery = value.trim();
      if (nextQuery == _query) return;
      _reloadStories(() => _query = nextQuery);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    if (_draftQuery.isEmpty && _query.isEmpty) return;

    _reloadStories(() {
      _draftQuery = '';
      _query = '';
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || !_hasMore) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _fetchStories(page: _nextPage, requestId: _requestId);
    }
  }

  Future<void> _refreshStories() {
    return _reloadStories(() {});
  }

  Future<void> _reloadStories(VoidCallback updateFilters) {
    final nextRequestId = _requestId + 1;
    setState(() {
      updateFilters();
      _requestId = nextRequestId;
      _nextPage = 1;
      _hasMore = true;
      _errorMessage = null;
      _stories.clear();
    });

    return _fetchStories(page: 1, requestId: nextRequestId);
  }

  Future<void> _fetchStories({
    required int page,
    required int requestId,
  }) async {
    if (_isLoading && page != 1) return;
    if (!_hasMore && page != 1) return;

    setState(() {
      _isLoading = true;
      if (page == 1) _errorMessage = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final params = <String, dynamic>{
        'page': page,
        'limit': AppConstants.defaultPageSize,
        'sortBy': _selectedSort.sortBy,
        'sortOrder': _selectedSort.sortOrder,
      };

      if (_query.isNotEmpty) params['search'] = _query;
      if (_selectedGenreId != null) params['genreId'] = _selectedGenreId;
      if (_selectedType != null) params['type'] = _selectedType;
      if (_selectedStatus != null) params['status'] = _selectedStatus;

      final result = await api.get<Map<String, dynamic>>(
        ApiEndpoints.stories,
        queryParameters: params,
      );

      final items = (result['data'] as List? ?? [])
          .map((e) => Story.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = result['pagination'];
      final totalPages = pagination is Map
          ? pagination['totalPages'] as int?
          : null;

      if (!mounted || requestId != _requestId) return;
      setState(() {
        if (page == 1) _stories.clear();
        _stories.addAll(items);
        _nextPage = page + 1;
        _hasMore = totalPages != null
            ? page < totalPages
            : items.length >= AppConstants.defaultPageSize;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _errorMessage = error is ApiException
            ? error.message
            : AppStrings.exploreLoadStoriesFailed;
        _isLoading = false;
        if (page == 1) _hasMore = false;
      });
    }
  }

  void _selectGenre(String? genreId) {
    _reloadStories(() => _selectedGenreId = genreId);
  }

  void _selectType(String? type) {
    _reloadStories(() => _selectedType = type);
  }

  void _selectStatus(String? status) {
    _reloadStories(() => _selectedStatus = status);
  }

  void _selectSort(ExploreSortOption sort) {
    _reloadStories(() => _selectedSort = sort);
  }

  void _clearAllFilters() {
    _debounce?.cancel();
    _searchController.clear();
    _reloadStories(() {
      _draftQuery = '';
      _query = '';
      _selectedGenreId = null;
      _selectedType = null;
      _selectedStatus = null;
      _selectedSort = exploreSortOptions.first;
    });
  }

  String? _selectedGenreName(AsyncValue<List<Genre>> genres) {
    final genreId = _selectedGenreId;
    if (genreId == null) return null;

    final list = genres.maybeWhen(data: (items) => items, orElse: () => null);
    if (list == null) return AppStrings.exploreGenreSelected;

    for (final genre in list) {
      if (genre.id == genreId) return genre.name;
    }
    return AppStrings.exploreGenreSelected;
  }

  @override
  Widget build(BuildContext context) {
    final genres = ref.watch(_genresProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.emerald500,
        onRefresh: _refreshStories,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            ExploreSearchAppBar(
              controller: _searchController,
              query: _draftQuery,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
            SliverToBoxAdapter(
              child: ExploreFilterBar(
                genreLabel: _selectedGenreName(genres) ?? AppStrings.exploreGenreFilterLabel,
                typeLabel: exploreOptionLabel(
                  exploreTypeOptions,
                  _selectedType,
                  AppStrings.exploreTypeFilterLabel,
                ),
                statusLabel: exploreOptionLabel(
                  exploreStatusOptions,
                  _selectedStatus,
                  AppStrings.exploreStatusFilterLabel,
                ),
                sortLabel: _selectedSort.label,
                hasGenre: _selectedGenreId != null,
                hasType: _selectedType != null,
                hasStatus: _selectedStatus != null,
                hasCustomSort: _selectedSort != exploreSortOptions.first,
                hasActiveFilters: _hasActiveFilters,
                onGenreTap: () => _showGenreSheet(context, genres),
                onTypeTap: () => _showOptionSheet(
                  context: context,
                  title: AppStrings.exploreChooseTypeTitle,
                  options: exploreTypeOptions,
                  selectedValue: _selectedType,
                  onSelected: _selectType,
                ),
                onStatusTap: () => _showOptionSheet(
                  context: context,
                  title: AppStrings.exploreChooseStatusTitle,
                  options: exploreStatusOptions,
                  selectedValue: _selectedStatus,
                  onSelected: _selectStatus,
                ),
                onSortTap: () => _showSortSheet(context),
                onClearTap: _clearAllFilters,
              ),
            ),
            _buildStorySliver(),
            if (_isLoading && _stories.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            if (_errorMessage != null && _stories.isNotEmpty)
              SliverToBoxAdapter(
                child: ExploreInlineLoadError(
                  message: _errorMessage!,
                  onRetry: () =>
                      _fetchStories(page: _nextPage, requestId: _requestId),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorySliver() {
    if (_stories.isEmpty && _isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_stories.isEmpty && _errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ExploreEmptyState(
          icon: Icons.wifi_off_rounded,
          title: _errorMessage!,
          actionLabel: AppStrings.retry,
          onAction: _refreshStories,
        ),
      );
    }

    if (_stories.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ExploreEmptyState(
          icon: Icons.search_off_rounded,
          title: AppStrings.exploreNoStoriesFound,
          subtitle: _hasActiveFilters
              ? AppStrings.exploreTryDifferentFilter
              : AppStrings.exploreNoStoriesAvailable,
          actionLabel: _hasActiveFilters ? AppStrings.exploreClearFilter : null,
          onAction: _hasActiveFilters ? _clearAllFilters : null,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, index) => ExploreStoryCard(story: _stories[index]),
          childCount: _stories.length,
        ),
      ),
    );
  }

  void _showOptionSheet({
    required BuildContext context,
    required String title,
    required List<ExploreSelectionOption> options,
    required String? selectedValue,
    required ValueChanged<String?> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return ExploreOptionSheet(
          title: title,
          options: options,
          selectedValue: selectedValue,
          onSelected: (value) {
            Navigator.pop(sheetContext);
            onSelected(value);
          },
        );
      },
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return ExploreSortSheet(
          selectedSort: _selectedSort,
          onSelected: (sort) {
            Navigator.pop(sheetContext);
            _selectSort(sort);
          },
        );
      },
    );
  }

  void _showGenreSheet(BuildContext context, AsyncValue<List<Genre>> genres) {
    String genreQuery = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(context).padding.bottom + 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ExploreSheetHandle(),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.exploreChooseGenreTitle,
                        style: AppTypography.heading3(
                          Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) {
                          setSheetState(() => genreQuery = value.trim());
                        },
                        decoration: const InputDecoration(
                          hintText: AppStrings.exploreGenreSearchHint,
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: genres.when(
                          data: (list) {
                            final normalizedQuery = removeAccents(
                              genreQuery.toLowerCase(),
                            );
                            final filteredGenres = normalizedQuery.isEmpty
                                ? list
                                : list.where((genre) {
                                    final name = removeAccents(
                                      genre.name.toLowerCase(),
                                    );
                                    return name.contains(normalizedQuery);
                                  }).toList();

                            return ListView(
                              controller: scrollController,
                              children: [
                                ExploreGenreTile(
                                  label: AppStrings.exploreAllGenres,
                                  selected: _selectedGenreId == null,
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    _selectGenre(null);
                                  },
                                ),
                                const Divider(height: 1),
                                if (filteredGenres.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 32,
                                    ),
                                    child: Center(
                                      child: Text(
                                        AppStrings.exploreGenreNotFound,
                                        style: AppTypography.bodyMedium(
                                          context.appTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...filteredGenres.map(
                                    (genre) => ExploreGenreTile(
                                      label: genre.name,
                                      selected: _selectedGenreId == genre.id,
                                      onTap: () {
                                        Navigator.pop(sheetContext);
                                        _selectGenre(genre.id);
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => Center(
                            child: Text(
                              AppStrings.exploreGenreLoadFailed,
                              style: AppTypography.bodyMedium(
                                context.appTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
