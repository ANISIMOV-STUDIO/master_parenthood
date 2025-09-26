// lib/widgets/lazy_loading_list.dart
// 🚀 Lazy Loading List - Flutter 2025 Performance Best Practices
import 'package:flutter/material.dart';

/// Optimized lazy loading list widget with proper memory management
class LazyLoadingList<T> extends StatefulWidget {
  const LazyLoadingList({
    super.key,
    required this.itemBuilder,
    required this.loadMoreItems,
    this.initialItems = const [],
    this.hasMore = true,
    this.isLoading = false,
    this.itemsPerPage = 20,
    this.loadingThreshold = 3,
    this.errorWidget,
    this.emptyWidget,
    this.loadingWidget,
    this.separatorBuilder,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  });

  /// Builder function for individual items
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Function to load more items
  final Future<List<T>> Function(int page, int limit) loadMoreItems;

  /// Initial items to display
  final List<T> initialItems;

  /// Whether there are more items to load
  final bool hasMore;

  /// Whether currently loading
  final bool isLoading;

  /// Number of items to load per page
  final int itemsPerPage;

  /// How many items from the end to trigger loading
  final int loadingThreshold;

  /// Widget to show on error
  final Widget? errorWidget;

  /// Widget to show when list is empty
  final Widget? emptyWidget;

  /// Widget to show while loading
  final Widget? loadingWidget;

  /// Separator builder between items
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Whether to shrink wrap the list
  final bool shrinkWrap;

  /// Padding around the list
  final EdgeInsetsGeometry? padding;

  @override
  State<LazyLoadingList<T>> createState() => _LazyLoadingListState<T>();
}

class _LazyLoadingListState<T> extends State<LazyLoadingList<T>> {
  late ScrollController _scrollController;
  List<T> _items = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _items = List.from(widget.initialItems);
    _hasMore = widget.hasMore;

    // Load initial data if no initial items provided
    if (_items.isEmpty && _hasMore) {
      _loadMoreItems();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            (widget.loadingThreshold * 100)) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final newItems = await widget.loadMoreItems(_currentPage, widget.itemsPerPage);

      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _currentPage++;
          _hasMore = newItems.length == widget.itemsPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
      _hasError = false;
      _errorMessage = null;
    });

    await _loadMoreItems();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty && _hasError) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    if (_items.isEmpty && !_hasMore) {
      return widget.emptyWidget ?? const Center(child: Text('No items found'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        padding: widget.padding,
        itemCount: _items.length + (_hasMore || _isLoading ? 1 : 0),
        separatorBuilder: widget.separatorBuilder ?? (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index < _items.length) {
            return widget.itemBuilder(context, _items[index], index);
          } else {
            // Loading or error indicator
            if (_hasError) {
              return _buildErrorWidget();
            } else if (_isLoading) {
              return widget.loadingWidget ?? _buildLoadingWidget();
            } else {
              return const SizedBox.shrink();
            }
          }
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading items',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMoreItems,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Optimized grid view with lazy loading
class LazyLoadingGridView<T> extends StatefulWidget {
  const LazyLoadingGridView({
    super.key,
    required this.itemBuilder,
    required this.loadMoreItems,
    required this.crossAxisCount,
    this.initialItems = const [],
    this.hasMore = true,
    this.isLoading = false,
    this.itemsPerPage = 20,
    this.loadingThreshold = 3,
    this.errorWidget,
    this.emptyWidget,
    this.loadingWidget,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
  });

  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<List<T>> Function(int page, int limit) loadMoreItems;
  final int crossAxisCount;
  final List<T> initialItems;
  final bool hasMore;
  final bool isLoading;
  final int itemsPerPage;
  final int loadingThreshold;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  @override
  State<LazyLoadingGridView<T>> createState() => _LazyLoadingGridViewState<T>();
}

class _LazyLoadingGridViewState<T> extends State<LazyLoadingGridView<T>> {
  late ScrollController _scrollController;
  List<T> _items = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _items = List.from(widget.initialItems);
    _hasMore = widget.hasMore;

    if (_items.isEmpty && _hasMore) {
      _loadMoreItems();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            (widget.loadingThreshold * 100)) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final newItems = await widget.loadMoreItems(_currentPage, widget.itemsPerPage);

      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _currentPage++;
          _hasMore = newItems.length == widget.itemsPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
      _hasError = false;
      _errorMessage = null;
    });

    await _loadMoreItems();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty && _hasError) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    if (_items.isEmpty && !_hasMore) {
      return widget.emptyWidget ?? const Center(child: Text('No items found'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: GridView.builder(
        controller: _scrollController,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
          childAspectRatio: widget.childAspectRatio,
        ),
        itemCount: _items.length + (_hasMore || _isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _items.length) {
            return widget.itemBuilder(context, _items[index], index);
          } else {
            if (_hasError) {
              return _buildErrorWidget();
            } else if (_isLoading) {
              return widget.loadingWidget ?? _buildLoadingWidget();
            } else {
              return const SizedBox.shrink();
            }
          }
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 32,
            color: Colors.red,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadMoreItems,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}