import 'package:flutter/material.dart';
import '../models/cuisine_model.dart';
import '../utils/cuisine_mapper.dart';
import '../constants/enums.dart';
import 'cuisine_card.dart';

typedef CuisineTap = void Function(CuisineType type);

class CuisineGrid extends StatelessWidget {
  final double width;
  final double height;
  final List<Cuisine> cuisines;
  final Set<CuisineType> selected;
  final CuisineTap onTap;

  const CuisineGrid({
    Key? key,
    required this.width,
    required this.height,
    required this.cuisines,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = (width > 600) ? 4 : 3;
    final items = cuisines
        .map((c) => CuisineMapper.toCuisineType(c.name))
        .whereType<CuisineType>()
        .toList();

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: height * 0.015,
      crossAxisSpacing: width * 0.03,
      childAspectRatio: 1,
      children: [
        for (final ct in items)
          CuisineCard(
            cuisine: ct,
            selected: selected.contains(ct),
            onTap: () => onTap(ct),
          ),
      ],
    );
  }
}

