import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/client/profile.dart';
import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class MiniProfileView extends StatefulWidget {
  const MiniProfileView(
      {required this.client,
      required this.userId,
      this.initialProfile,
      this.onTap,
      super.key});
  final Client client;
  final String userId;
  final Profile? initialProfile;
  final void Function()? onTap;

  @override
  State<MiniProfileView> createState() => _MiniProfileViewState();
}

class _MiniProfileViewState extends State<MiniProfileView> {
  Profile? profile;
  late double random;

  @override
  void initState() {
    super.initState();
    random = Random().nextDouble();

    if (widget.initialProfile == null) {
      widget.client.getProfile(widget.userId).then((value) => setState(() {
            profile = value;
          }));
    } else {
      profile = widget.initialProfile;
    }
  }

  @override
  Widget build(BuildContext context) {
    var shimmerColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Shimmer(
            linearGradient: Shimmer.harshGradient,
            child: ShimmerLoading(
              isLoading: profile == null,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: tiamat.Avatar(
                      placeholderText: profile?.displayName ?? " ",
                      placeholderColor: profile?.defaultColor ?? shimmerColor,
                      image: profile?.avatar,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profile != null
                            ? tiamat.Text.name(
                                profile!.displayName,
                                color: profile!.defaultColor,
                              )
                            : Container(
                                height: 12,
                                width: (random * 50) + 50,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: shimmerColor),
                              ),
                        profile != null
                            ? tiamat.Text.labelLow(profile!.identifier)
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                                child: Container(
                                  height: 8,
                                  width: (random * 10) + 100,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: shimmerColor),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
