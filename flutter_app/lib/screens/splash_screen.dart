import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/forest_theme.dart';
import '../models/child.dart';
import '../providers/backend_provider.dart';
import '../widgets/decorated_card.dart';
import '../widgets/page_background.dart';
import '../widgets/section_title.dart';
import '../widgets/soft_status_badge.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  List<Child> _children = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final api = ref.read(apiServiceProvider);
      final children = await api.listChildren();
      if (!mounted) return;
      setState(() {
        _children = children;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createChild(String robot) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建儿童档案'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: '孩子的名字'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    try {
      final api = ref.read(apiServiceProvider);
      await api.createChild(name: name, robotPreference: robot);
      await _loadChildren();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        topDecorativeAssetPath: 'assets/images/ui/top_decor.png',
        bottomDecorativeAssetPath: 'assets/images/ui/bottom_decor.png',
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 940;
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DecoratedCard(
                        child: isWide
                            ? Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: _buildWelcomeCopy(context),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 5,
                                    child: _buildHeroArt(height: 300),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildWelcomeCopy(context),
                                  const SizedBox(height: 20),
                                  _buildHeroArt(height: 220),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),
                      _buildRobotChoiceSection(isWide),
                      const SizedBox(height: 20),
                      _buildChildProfilesSection(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCopy(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SoftStatusBadge(
          label: '从伙伴开始今天的森林旅程',
          icon: Icons.auto_stories_outlined,
          backgroundColor: ForestPalette.sage,
        ),
        const SizedBox(height: 18),
        const SectionTitle(
          title: '星语灵境',
          subtitle: '先选一位温柔陪伴的小伙伴，再继续今天的情绪练习。',
        ),
        const SizedBox(height: 14),
        Text(
          'Tino 和 Tina 会一起陪孩子进入故事森林，用更轻松的方式开始今天的互动。',
          style: textTheme.bodyLarge?.copyWith(
            color: ForestPalette.bark.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroArt({required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: height,
        color: ForestPalette.sage.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          'assets/images/ui/splash_forest_hero.png',
          key: const Key('splash_hero_image'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildRobotChoiceSection(bool isWide) {
    final tinoCard = _RobotStoryCard(
      label: 'Tino（男）',
      robot: 'tino',
      accentColor: const Color(0xFF7AA7D9),
      description: '像故事里的小向导一样，陪孩子轻轻进入练习。',
      onTap: () => _createChild('tino'),
    );
    final tinaCard = _RobotStoryCard(
      label: 'Tina（女）',
      robot: 'tina',
      accentColor: const Color(0xFFD99DBD),
      description: '像森林里的小伙伴一样，用温柔回应鼓励每一步。',
      onTap: () => _createChild('tina'),
    );

    return DecoratedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '选择你的伙伴',
            subtitle: '点击喜欢的伙伴，为孩子创建新的练习档案。',
          ),
          const SizedBox(height: 18),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tinoCard),
                const SizedBox(width: 16),
                Expanded(child: tinaCard),
              ],
            )
          else
            Column(
              children: [
                tinoCard,
                const SizedBox(height: 16),
                tinaCard,
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChildProfilesSection() {
    return DecoratedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '已有档案',
            subtitle: '也可以从熟悉的小朋友故事继续往下走。',
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            SoftStatusBadge(
              label: _error!,
              icon: Icons.error_outline,
              backgroundColor: ForestPalette.berry.withValues(alpha: 0.16),
              foregroundColor: ForestPalette.berry,
            )
          else if (_children.isEmpty)
            Text(
              '还没有档案，先从上面的伙伴故事卡创建一个吧。',
              style: TextStyle(
                color: ForestPalette.bark.withValues(alpha: 0.7),
              ),
            )
          else
            Column(
              children: _children
                  .map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ChildStoryRow(
                        childProfile: child,
                        onTap: () => context.go('/home?child_id=${child.id}'),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _RobotStoryCard extends StatelessWidget {
  final String label;
  final String robot;
  final Color accentColor;
  final String description;
  final VoidCallback onTap;

  const _RobotStoryCard({
    required this.label,
    required this.robot,
    required this.accentColor,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon =
        robot == 'tina' ? Icons.favorite_outline : Icons.explore_outlined;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.smart_toy_outlined,
                    color: accentColor, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: ForestPalette.bark,
                                ),
                          ),
                        ),
                        Icon(icon, color: accentColor, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ForestPalette.bark.withValues(alpha: 0.74),
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '点我创建',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildStoryRow extends StatelessWidget {
  final Child childProfile;
  final VoidCallback onTap;

  const _ChildStoryRow({
    required this.childProfile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = childProfile.robotPreference == 'tina'
        ? const Color(0xFFD99DBD)
        : const Color(0xFF7AA7D9);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: ForestPalette.sunrise.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ForestPalette.sunrise.withValues(alpha: 0.34),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.menu_book_outlined, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childProfile.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lv.${childProfile.currentDifficultyLevel} · ${childProfile.robotPreference.toUpperCase()} 的陪伴故事',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ForestPalette.bark.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: ForestPalette.bark),
            ],
          ),
        ),
      ),
    );
  }
}
