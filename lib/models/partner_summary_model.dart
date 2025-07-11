// lib/models/partner_summary_model.dart - Updated with new fields

class PartnerSummaryModel {
  final int ordersCount;
  final int productsCount;
  final int tagsCount;
  final double rating;
  final List<SalesDataPoint> salesData;
  final bool acceptingOrders;
  final String totalSales;
  final double orderAcceptanceRate;
  final double orderCancellationRate;
  final List<TopSellingItem> topSellingItems;

  const PartnerSummaryModel({
    required this.ordersCount,
    required this.productsCount,
    required this.tagsCount,
    required this.rating,
    required this.salesData,
    required this.acceptingOrders,
    required this.totalSales,
    required this.orderAcceptanceRate,
    required this.orderCancellationRate,
    required this.topSellingItems,
  });

  factory PartnerSummaryModel.fromJson(Map<String, dynamic> json) {
    final salesDataList = json['salesData'] as List<dynamic>? ?? [];
    final topSellingItemsList = json['topSellingItems'] as List<dynamic>? ?? [];
    
    return PartnerSummaryModel(
      ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
      productsCount: (json['productsCount'] as num?)?.toInt() ?? 0,
      tagsCount: (json['tagsCount'] as num?)?.toInt() ?? 0,
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      salesData: salesDataList
          .map((item) => SalesDataPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      acceptingOrders: json['acceptingOrders'] == true,
      totalSales: json['totalSales']?.toString() ?? '0.00',
      orderAcceptanceRate: double.tryParse(json['orderAcceptanceRate']?.toString() ?? '0.0') ?? 0.0,
      orderCancellationRate: double.tryParse(json['orderCancellationRate']?.toString() ?? '0.0') ?? 0.0,
      topSellingItems: topSellingItemsList
          .map((item) => TopSellingItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ordersCount': ordersCount,
      'productsCount': productsCount,
      'tagsCount': tagsCount,
      'rating': rating.toString(),
      'salesData': salesData.map((item) => item.toJson()).toList(),
      'acceptingOrders': acceptingOrders,
      'totalSales': totalSales,
      'orderAcceptanceRate': orderAcceptanceRate.toString(),
      'orderCancellationRate': orderCancellationRate.toString(),
      'topSellingItems': topSellingItems.map((item) => item.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'PartnerSummaryModel(ordersCount: $ordersCount, productsCount: $productsCount, '
           'tagsCount: $tagsCount, rating: $rating, salesDataPoints: ${salesData.length}, '
           'acceptingOrders: $acceptingOrders, totalSales: $totalSales, '
           'orderAcceptanceRate: $orderAcceptanceRate, orderCancellationRate: $orderCancellationRate, '
           'topSellingItems: ${topSellingItems.length})';
  }
}

class SalesDataPoint {
  final String date;
  final int sales;

  const SalesDataPoint({
    required this.date,
    required this.sales,
  });

  factory SalesDataPoint.fromJson(Map<String, dynamic> json) {
    return SalesDataPoint(
      date: json['date']?.toString() ?? '',
      sales: (json['sales'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'sales': sales,
    };
  }

  @override
  String toString() {
    return 'SalesDataPoint(date: $date, sales: $sales)';
  }
}

class TopSellingItem {
  final String menuId;
  final String name;
  final String totalSold;

  const TopSellingItem({
    required this.menuId,
    required this.name,
    required this.totalSold,
  });

  factory TopSellingItem.fromJson(Map<String, dynamic> json) {
    return TopSellingItem(
      menuId: json['menu_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      totalSold: json['total_sold']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_id': menuId,
      'name': name,
      'total_sold': totalSold,
    };
  }

  @override
  String toString() {
    return 'TopSellingItem(menuId: $menuId, name: $name, totalSold: $totalSold)';
  }
}

class PartnerSummaryResponse {
  final String status;
  final String message;
  final PartnerSummaryModel? data;

  const PartnerSummaryResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory PartnerSummaryResponse.fromJson(Map<String, dynamic> json) {
    return PartnerSummaryResponse(
      status: json['status'] as String? ?? 'ERROR',
      message: json['message'] as String? ?? '',
      data: json['data'] != null 
          ? PartnerSummaryModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get success => status == 'SUCCESS';

  @override
  String toString() {
    return 'PartnerSummaryResponse(status: $status, message: $message, data: $data)';
  }
}