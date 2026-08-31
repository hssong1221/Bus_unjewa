import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/theme/app_background.dart';
import 'package:bus_51/theme/app_tokens.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// View
// --------------------------------------------------
class ExplainScreenView extends StatefulWidget {
  const ExplainScreenView({super.key});

  @override
  State<ExplainScreenView> createState() => _ExplainScreenViewState();
}

class _ExplainScreenViewState extends State<ExplainScreenView> {
  // 자체 서버 복구 시 initState 의 postFrameCallback 에서
  // BusApiService.testConnect 로 연결 확인을 되살린다

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: appBackgroundDecoration(colorScheme),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // App Title
                Text(
                  "버스언제와",
                  style: context.textStyle.appTitle.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                
                Expanded(child: _buildMainContent(colorScheme)),
                
                // Footer Info
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "GPS와 실시간 교통정보를 이용합니다",
                        style: context.textStyle.caption.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
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
    );
  }

  Widget _buildMainContent(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildWelcomeCard(colorScheme),
        const SizedBox(height: 48),
        _buildStartButton(colorScheme),
      ],
    );
  }

  // 웰컴 카드는 앱에서 유일하게 브랜드 컬러 배경을 쓰는 곳 (기존 결정) — 채도만 낮춘 플랫 카드
  Widget _buildWelcomeCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outline.withValues(alpha: kCardBorderAlpha)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.14),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            "매일 같은 버스로\n출퇴근하는 당신을 위한",
            style: context.textStyle.headlineMedium.copyWith(
              color: colorScheme.onSurface,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "실시간 버스 도착 정보를\n한눈에 확인하세요",
            style: context.textStyle.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: () => context.read<InitProvider>().nextAccountView(),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
        label: Text(
          "시작하기",
          style: context.textStyle.buttonText.copyWith(color: colorScheme.onPrimary),
        ),
      ),
    );
  }
}
