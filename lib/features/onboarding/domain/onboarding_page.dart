import 'package:flutter/material.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.image,
    required this.badge,
    required this.badgeIcon,
    required this.title,
    required this.body,
    required this.topChip,
    required this.bottomChip,
  });
  final String image;
  final String badge;
  final IconData badgeIcon;
  final String title;
  final String body;
  final String topChip;
  final String bottomChip;
}

const onboardingPages = [
  OnboardingPageData(
    image: 'assets/images/onboarding_1.png',
    badge: 'MEET NEW PEOPLE',
    badgeIcon: Icons.groups,
    title: 'Discover Meaningful\nConnections',
    body: 'Meet interesting people for dating, friendship, networking, or marriage.',
    topChip: 'Social & Dating',
    bottomChip: 'Curated Circles',
  ),
  OnboardingPageData(
    image: 'assets/images/onboarding_2.png',
    badge: 'LIVE SPEED DATING',
    badgeIcon: Icons.bolt,
    title: 'Real People. Live\nConnections.',
    body: 'Join live events, meet compatible people, and start meaningful conversations in quick video dates.',
    topChip: 'Live Speed Dates',
    bottomChip: '100% Authentic',
  ),
];
