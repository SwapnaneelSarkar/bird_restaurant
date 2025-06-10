// lib/models/partner_summary_model.dart - New file to create

class PartnerSummaryModel {
  final int ordersCount;
  final int productsCount;
  final int tagsCount;
  final double rating;
  final List<SalesDataPoint> salesData;
  final bool acceptingOrders;

  const PartnerSummaryModel({
    required this.ordersCount,
    required this.productsCount,
    required this.tagsCount,
    required this.rating,
    required this.salesData,
    required this.acceptingOrders,
  });

  factory PartnerSummaryModel.fromJson(Map<String, dynamic> json) {
    final salesDataList = json['salesData'] as List<dynamic>? ?? [];
    
    return PartnerSummaryModel(
      ordersCount: json['ordersCount'] as int? ?? 0,
      productsCount: json['productsCount'] as int? ?? 0,
      tagsCount: json['tagsCount'] as int? ?? 0,
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      salesData: salesDataList
          .map((item) => SalesDataPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      acceptingOrders: json['acceptingOrders'] as bool? ?? false,
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
    };
  }

  @override
  String toString() {
    return 'PartnerSummaryModel(ordersCount: $ordersCount, productsCount: $productsCount, '
           'tagsCount: $tagsCount, rating: $rating, salesDataPoints: ${salesData.length}, '
           'acceptingOrders: $acceptingOrders)';
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
      date: json['date'] as String? ?? '',
      sales: json['sales'] as int? ?? 0,
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