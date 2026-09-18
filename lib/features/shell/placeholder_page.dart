import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/components/ds_states.dart';

/// Generic "not built yet" page used for routes whose feature lands in a later
/// phase. Keeps navigation fully functional in P1 without fabricating content.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return DsEmpty(
      title: title,
      message: message,
      icon: Icons.construction_outlined,
    );
  }
}
