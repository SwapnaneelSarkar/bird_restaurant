import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import '../presentation/screens/resturant_details_2/state.dart';

class OperationalHourCard extends StatelessWidget {
  final int index;
  final OperationalDay day;
  final VoidCallback onToggleEnabled;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const OperationalHourCard({
    Key? key,
    required this.index,
    required this.day,
    required this.onToggleEnabled,
    required this.onPickStart,
    required this.onPickEnd,
  }) : super(key: key);

  String _format(BuildContext context, TimeOfDay tod) => tod.format(context);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final side = mq.size.width * 0.04;
    final vert  = mq.size.height * 0.015;
    final grey  = Colors.grey.shade500;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: vert),
      padding: EdgeInsets.symmetric(horizontal: side, vertical: vert),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: ColorManager.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // checkbox
          InkWell(
            onTap: onToggleEnabled,
            child: Icon(
              day.enabled
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: Colors.blue,
            ),
          ),
          SizedBox(width: side),

          // day label
          SizedBox(
            width: mq.size.width * 0.20,
            child: Text(
              day.label,
              style: TextStyle(
                fontFamily: FontConstants.fontFamily,
                fontSize: FontSize.s14,
                color: day.enabled ? ColorManager.black : grey,
              ),
            ),
          ),

          // start time
          _timeBox(
            context,
            _format(context, day.start),
            day.enabled ? onPickStart : null,
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: side * 0.3),
            child: Text('to'),
          ),

          // end time
          _timeBox(
            context,
            _format(context, day.end),
            day.enabled ? onPickEnd : null,
          ),
        ],
      ),
    );
  }

  Widget _timeBox(BuildContext ctx, String label, VoidCallback? onTap) {
    final mq = MediaQuery.of(ctx);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: mq.size.width * 0.20,
        height: mq.size.height * 0.05,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: ColorManager.grey,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: FontConstants.fontFamily,
            fontSize: FontSize.s12,
            color:
                onTap == null ? Colors.grey.shade500 : ColorManager.black,
          ),
        ),
      ),
    );
  }
}
