import 'package:flutter/material.dart';
import 'package:frontend/screens/chat_list_screen.dart';
import 'package:frontend/screens/my_profile_screen.dart';
import 'package:frontend/screens/artisan_portfolio_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/settings_screen.dart';
import 'package:frontend/widgets/navigation/bottom_navigation_widget.dart';

class TabNavigationService extends StatelessWidget {
  final String userRole;

  const TabNavigationService({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return const BottomNavigationWidget(userRole: 'client');
  }
}