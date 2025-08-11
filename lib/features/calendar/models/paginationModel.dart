class PaginationModel {
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isFirstPage;
  final bool isLastPage;
  final int currentPageSize;
  final int remainingItems;
  final int? nextPageNumber;
  final int? previousPageNumber;

  PaginationModel({
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.isFirstPage,
    required this.isLastPage,
    required this.currentPageSize,
    required this.remainingItems,
    this.nextPageNumber,
    this.previousPageNumber,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 PaginationModel.fromJson: Parsing pagination data');
      
      // Log null values for debugging
      final nullFields = <String>[];
      if (json['pageNumber'] == null) nullFields.add('pageNumber');
      if (json['pageSize'] == null) nullFields.add('pageSize');
      if (json['totalCount'] == null) nullFields.add('totalCount');
      if (json['totalPages'] == null) nullFields.add('totalPages');
      if (json['hasNextPage'] == null) nullFields.add('hasNextPage');
      if (json['hasPreviousPage'] == null) nullFields.add('hasPreviousPage');
      if (json['isFirstPage'] == null) nullFields.add('isFirstPage');
      if (json['isLastPage'] == null) nullFields.add('isLastPage');
      if (json['currentPageSize'] == null) nullFields.add('currentPageSize');
      if (json['remainingItems'] == null) nullFields.add('remainingItems');
      if (json['nextPageNumber'] == null) nullFields.add('nextPageNumber');
      if (json['previousPageNumber'] == null) nullFields.add('previousPageNumber');
      
      if (nullFields.isNotEmpty) {
        print('⚠️ PaginationModel.fromJson: Null fields detected: ${nullFields.join(', ')}');
      }
      
      // Handle null values for nextPageNumber and previousPageNumber
      final nextPageNumber = json['nextPageNumber'] as int?;
      final previousPageNumber = json['previousPageNumber'] as int?;
      
      print('✅ PaginationModel.fromJson: nextPageNumber = $nextPageNumber');
      print('✅ PaginationModel.fromJson: previousPageNumber = $previousPageNumber');
      
      return PaginationModel(
        pageNumber: json['pageNumber'] as int,
        pageSize: json['pageSize'] as int,
        totalCount: json['totalCount'] as int,
        totalPages: json['totalPages'] as int,
        hasNextPage: json['hasNextPage'] as bool,
        hasPreviousPage: json['hasPreviousPage'] as bool,
        isFirstPage: json['isFirstPage'] as bool,
        isLastPage: json['isLastPage'] as bool,
        currentPageSize: json['currentPageSize'] as int,
        remainingItems: json['remainingItems'] as int,
        nextPageNumber: nextPageNumber,
        previousPageNumber: previousPageNumber,
      );
    } catch (e) {
      print('❌ PaginationModel.fromJson: Error parsing pagination: $e');
      print('📄 PaginationModel.fromJson: JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      'totalCount': totalCount,
      'totalPages': totalPages,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
      'isFirstPage': isFirstPage,
      'isLastPage': isLastPage,
      'currentPageSize': currentPageSize,
      'remainingItems': remainingItems,
      'nextPageNumber': nextPageNumber,
      'previousPageNumber': previousPageNumber,
    };
  }
}
