import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/activity_catalog.dart';
import '../config/constants.dart';
import '../config/forest_theme.dart';
import '../widgets/activity_card.dart';
import '../widgets/decorated_card.dart';
import '../widgets/page_background.dart';
import '../widgets/section_title.dart';
import '../widgets/soft_status_badge.dart';

class HomeScreen extends StatelessWidget {
  final String childId;

  const HomeScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        topDecorativeAssetPath: 'assets/images/ui/top_decor.png',
        bottomDecorativeAssetPath: 'assets/images/ui/bottom_decor.png',
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedCard(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stackVertically = constraints.maxWidth < 780;
                      final intro = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SoftStatusBadge(
                            label: '欢迎回到森林练习角',
                            icon: Icons.waving_hand_rounded,
                            backgroundColor: ForestPalette.sage,
                          ),
                          const SizedBox(height: 16),
                          const SectionTitle(
                            title: '今天想先玩什么？',
                            subtitle: '选一个熟悉的小活动，让伙伴陪孩子慢慢开始今天的练习。',
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '每个小卡片都是一段轻松的互动故事，按孩子的节奏慢慢进入就好。',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: ForestPalette.bark
                                          .withValues(alpha: 0.78),
                                    ),
                          ),
                        ],
                      );

                      final therapistEntry = Align(
                        alignment: stackVertically
                            ? Alignment.centerLeft
                            : Alignment.topRight,
                        child: _TherapistEntryCard(
                          onActivated: () => _showTherapistEntry(context),
                        ),
                      );

                      if (stackVertically) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            intro,
                            const SizedBox(height: 16),
                            therapistEntry,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: intro),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: therapistEntry),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: DecoratedCard(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SoftStatusBadge(
                              label: '共 ${ActivityCatalog.all.length} 个森林活动',
                              icon: Icons.grid_view_rounded,
                              backgroundColor:
                                  ForestPalette.sunrise.withValues(alpha: 0.28),
                            ),
                            const SoftStatusBadge(
                              label: '轻点卡片即可开始',
                              icon: Icons.touch_app_outlined,
                              backgroundColor: ForestPalette.sage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final crossAxisCount = width >= 1200
                                  ? 3
                                  : width >= 700
                                      ? 2
                                      : 1;
                              return GridView.builder(
                                padding: const EdgeInsets.only(bottom: 8),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: width >= 700 ? 1.02 : 1.28,
                                ),
                                itemCount: ActivityCatalog.all.length,
                                itemBuilder: (_, index) {
                                  final activity = ActivityCatalog.all[index];
                                  return ActivityCard(
                                    activityKey: activity.key,
                                    onTap: () => context.go(
                                      '/train?child_id=$childId&activity=${activity.key}',
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTherapistEntry(BuildContext context) async {
    final ctrl = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('治疗师入口'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密码',
                  errorText: errorText,
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text == kTherapistPassword) {
                  Navigator.pop(ctx);
                  context.go('/dashboard?child_id=$childId');
                } else {
                  setDialogState(() => errorText = '密码错误');
                }
              },
              child: const Text('进入'),
            ),
          ],
        ),
      ),
    );

    ctrl.dispose();
  }
}

class _TherapistEntryCard extends StatelessWidget {
  final VoidCallback onActivated;

  const _TherapistEntryCard({required this.onActivated});

  @override
  Widget build(BuildContext context) {
    return DecoratedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SoftStatusBadge(
            label: '治疗师入口',
            icon: Icons.lock_outline,
            backgroundColor: ForestPalette.mist,
          ),
          const SizedBox(height: 10),
          Text(
            '长按小齿轮 3 秒进入设置与数据视图。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ForestPalette.bark.withValues(alpha: 0.72),
                ),
          ),
          const SizedBox(height: 12),
          _TherapistLongPressButton(onActivated: onActivated),
        ],
      ),
    );
  }
}

class _TherapistLongPressButton extends StatefulWidget {
  final VoidCallback onActivated;

  const _TherapistLongPressButton({required this.onActivated});

  @override
  State<_TherapistLongPressButton> createState() =>
      _TherapistLongPressButtonState();
}

class _TherapistLongPressButtonState extends State<_TherapistLongPressButton> {
  Timer? _timer;
  bool _holding = false;

  void _onLongPressStart(LongPressStartDetails _) {
    setState(() => _holding = true);
    _timer = Timer(const Duration(seconds: 3), () {
      if (_holding) widget.onActivated();
    });
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    _timer?.cancel();
    setState(() => _holding = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _holding
              ? ForestPalette.sunrise.withValues(alpha: 0.34)
              : ForestPalette.sage.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _holding ? ForestPalette.sunrise : ForestPalette.sage,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_outlined,
              color: _holding ? ForestPalette.bark : ForestPalette.moss,
            ),
            const SizedBox(width: 8),
            Text(
              _holding ? '继续按住…' : '长按小齿轮',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: ForestPalette.bark,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
