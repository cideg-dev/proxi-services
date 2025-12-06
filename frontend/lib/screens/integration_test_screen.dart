import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/identity_verification_service.dart';
import 'package:frontend/services/analytics_service.dart';
import 'package:frontend/services/badge_service.dart';
import 'package:frontend/services/loyalty_service.dart';
import 'package:frontend/services/referral_service.dart';
import 'package:frontend/services/ai_service.dart';
import 'package:frontend/services/recommendation_service.dart';
import 'package:frontend/services/predictive_analysis_service.dart';
import 'package:frontend/services/moderation_service.dart';
import 'package:frontend/services/social_sharing_service.dart';
import 'package:frontend/services/content_service.dart';
import 'package:frontend/services/localization_service.dart';
import 'package:frontend/services/offline_mode_service.dart';
import 'package:frontend/services/performance_service.dart';
import 'package:frontend/services/security_service.dart';

class IntegrationTestScreen extends StatefulWidget {
  const IntegrationTestScreen({super.key});

  @override
  State<IntegrationTestScreen> createState() => _IntegrationTestScreenState();
}

class _IntegrationTestScreenState extends State<IntegrationTestScreen> {
  final List<String> _testResults = [];
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests d\'intégration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isTesting ? null : _runAllTests,
              child: _isTesting
                  ? const CircularProgressIndicator()
                  : const Text('Exécuter tous les tests'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                final isPass = result.contains('PASS');
                final isFail = result.contains('FAIL');
                
                Color textColor = Colors.grey;
                if (isPass) textColor = Colors.green;
                if (isFail) textColor = Colors.red;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    result,
                    style: TextStyle(color: textColor),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isTesting = true;
      _testResults.clear();
    });

    try {
      await _testProfileService();
      await _testIdentityVerificationService();
      await _testAnalyticsService();
      await _testBadgeService();
      await _testLoyaltyService();
      await _testReferralService();
      await _testAIService();
      await _testRecommendationService();
      await _testPredictiveAnalysisService();
      await _testModerationService();
      await _testSocialSharingService();
      await _testContentService();
      await _testLocalizationService();
      await _testOfflineModeService();
      await _testPerformanceService();
      await _testSecurityService();

      _testResults.add('\n=== Tous les tests terminés ===');
    } catch (e) {
      _testResults.add('ERREUR GLOBALE: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testProfileService() async {
    try {
      // ProfileService has been refactored into AuthService and ArtisanService
      // Testing AuthService instead
      final service = AuthService();
      _testResults.add('PASS: AuthService (ex-ProfileService) initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: AuthService - $e');
    }
  }

  Future<void> _testIdentityVerificationService() async {
    try {
      final service = IdentityVerificationService();
      _testResults.add('PASS: IdentityVerificationService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: IdentityVerificationService - $e');
    }
  }

  Future<void> _testAnalyticsService() async {
    try {
      final service = AnalyticsService();
      _testResults.add('PASS: AnalyticsService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: AnalyticsService - $e');
    }
  }

  Future<void> _testBadgeService() async {
    try {
      final service = BadgeService();
      _testResults.add('PASS: BadgeService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: BadgeService - $e');
    }
  }

  Future<void> _testLoyaltyService() async {
    try {
      final service = LoyaltyService();
      _testResults.add('PASS: LoyaltyService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: LoyaltyService - $e');
    }
  }

  Future<void> _testReferralService() async {
    try {
      final service = ReferralService();
      _testResults.add('PASS: ReferralService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: ReferralService - $e');
    }
  }

  Future<void> _testAIService() async {
    try {
      final service = AIService();
      _testResults.add('PASS: AIService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: AIService - $e');
    }
  }

  Future<void> _testRecommendationService() async {
    try {
      final service = RecommendationService();
      _testResults.add('PASS: RecommendationService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: RecommendationService - $e');
    }
  }

  Future<void> _testPredictiveAnalysisService() async {
    try {
      final service = PredictiveAnalysisService();
      _testResults.add('PASS: PredictiveAnalysisService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: PredictiveAnalysisService - $e');
    }
  }

  Future<void> _testModerationService() async {
    try {
      final service = ModerationService();
      _testResults.add('PASS: ModerationService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: ModerationService - $e');
    }
  }

  Future<void> _testSocialSharingService() async {
    try {
      final service = SocialSharingService();
      _testResults.add('PASS: SocialSharingService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: SocialSharingService - $e');
    }
  }

  Future<void> _testContentService() async {
    try {
      final service = ContentService();
      _testResults.add('PASS: ContentService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: ContentService - $e');
    }
  }

  Future<void> _testLocalizationService() async {
    try {
      final service = LocalizationService();
      await service.loadLocale('fr');
      _testResults.add('PASS: LocalizationService initialisé et chargé correctement');
    } catch (e) {
      _testResults.add('FAIL: LocalizationService - $e');
    }
  }

  Future<void> _testOfflineModeService() async {
    try {
      final service = OfflineModeService();
      await service.init();
      _testResults.add('PASS: OfflineModeService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: OfflineModeService - $e');
    }
  }

  Future<void> _testPerformanceService() async {
    try {
      final service = PerformanceService();
      _testResults.add('PASS: PerformanceService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: PerformanceService - $e');
    }
  }

  Future<void> _testSecurityService() async {
    try {
      final service = SecurityService();
      _testResults.add('PASS: SecurityService initialisé correctement');
    } catch (e) {
      _testResults.add('FAIL: SecurityService - $e');
    }
  }
}