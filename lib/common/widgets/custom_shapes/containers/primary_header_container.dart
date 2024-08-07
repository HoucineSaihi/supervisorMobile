import 'package:flutter/material.dart';
import 'package:supervisormobile/common/widgets/custom_shapes/containers/circular_container.dart';
import 'package:supervisormobile/common/widgets/custom_shapes/curved_edges/curved_edges_widget.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

class TPrimaryHeaderContainer extends StatelessWidget {
  const TPrimaryHeaderContainer({
    super.key,
    required this.child,
    this.secondChild,
    this.height = 400, // Default height is 400, can be overridden
  });

  final Widget child;
  final Widget? secondChild;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TCurvedEdgeWidget(
          child: Container(
            color: TColors.primary,
            padding: const EdgeInsets.all(0),
            child: SizedBox(
              height: height, // Use dynamic height
              child: Stack(
                children: [
                  Positioned(
                    top: -150,
                    right: -250,
                    child: TCircularContainer(
                      backgroundColor: TColors.textWhite.withOpacity(0.1),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    right: -300,
                    child: TCircularContainer(
                      backgroundColor: TColors.textWhite.withOpacity(0.1),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
        if (secondChild != null)
          Container(
            child: secondChild,
          ),
      ],
    );
  }
}
