import 'package:commet/client/role.dart';
import 'package:flutter/material.dart';

class MatrixRole implements Role {
  int powerLevel;
  late int rank;

  MatrixRole(this.powerLevel, {String? nameOverride, IconData? iconOverride}) {
    if (powerLevel >= 100) {
      name = "Admin";
      rank = 100;
      icon = Icons.security;
    } else if (powerLevel >= 50) {
      name = "Moderator";
      rank = 50;
      icon = Icons.shield_rounded;
    } else {
      name = "Member";
      icon = Icons.groups;
      rank = 0;
    }

    if (nameOverride != null) {
      name = nameOverride;
    }

    if (iconOverride != null) {
      icon = iconOverride;
    }
  }

  @override
  late String name;

  @override
  bool operator ==(Object other) {
    if (other is! MatrixRole) return false;
    if (identical(this, other)) return true;
    return rank == other.rank;
  }

  @override
  int get hashCode => powerLevel.hashCode;

  @override
  late IconData icon;
}
