part of '../index.dart';

/// 展示配音角色弹层，并在用户确认后返回角色和情绪选择。
Future<({String voiceId, String emotion})?> showCreationVoiceSheet(
  BuildContext context, {
  required List<VoiceRole> voices,
  required List<String> emotions,
  required String initialVoiceId,
  required String initialEmotion,
}) {
  return showModalBottomSheet<({String voiceId, String emotion})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _CreationVoiceSheet(
        voices: voices,
        initialVoiceId: initialVoiceId,
        initialEmotion: initialEmotion,
      );
    },
  );
}

/// 试听播放器抽象，方便 widget 测试替换真实原生播放器。
abstract interface class CreationVoiceAuditionPlayer {
  /// 播放完成事件。
  Stream<void> get onComplete;

  /// 播放远程试听音频。
  Future<void> play(String url);

  /// 停止当前试听音频。
  Future<void> stop();

  /// 释放播放器资源。
  Future<void> dispose();
}

/// 配音弹层试听播放器工厂，测试可替换为内存 fake。
CreationVoiceAuditionPlayer Function() creationVoiceAuditionPlayerFactory =
    _AudioPlayersVoiceAuditionPlayer.new;

/// 基于 audioplayers 的真实试听播放器。
final class _AudioPlayersVoiceAuditionPlayer
    implements CreationVoiceAuditionPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  @override
  Future<void> play(String url) => _player.play(UrlSource(url));

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

/// 配音角色弹层，负责角色选择、情绪选择和试听播放器生命周期。
class _CreationVoiceSheet extends StatefulWidget {
  const _CreationVoiceSheet({
    required this.voices,
    required this.initialVoiceId,
    required this.initialEmotion,
  });

  /// 后端返回的音色列表。
  final List<VoiceRole> voices;

  /// 打开弹层时已选中的音色 id。
  final String initialVoiceId;

  /// 打开弹层时已选中的情绪标签。
  final String initialEmotion;

  @override
  State<_CreationVoiceSheet> createState() => _CreationVoiceSheetState();
}

class _CreationVoiceSheetState extends State<_CreationVoiceSheet> {
  /// 当前弹层内选中的音色。
  VoiceRole? _selectedVoice;

  /// 当前弹层内选中的音色 id。
  late String _selectedVoiceId;

  /// 当前弹层内选中的情绪标签；无标签音色保持空字符串。
  late String _selectedEmotion;

  /// 当前正在试听的音色 id。
  String? _auditioningVoiceId;

  /// 当前试听按钮是否正在等待播放器响应。
  bool _auditionBusy = false;

  /// 弹层内持有的试听播放器。
  late final CreationVoiceAuditionPlayer _auditionPlayer;

  /// 播放完成监听，用于自动恢复试听按钮状态。
  StreamSubscription<void>? _auditionCompleteSubscription;

  @override
  void initState() {
    super.initState();
    _selectedVoice =
        _voiceById(widget.voices, widget.initialVoiceId) ??
        _firstVoice(widget.voices);
    _selectedVoiceId = _selectedVoice?.id ?? widget.initialVoiceId;
    _selectedEmotion = _normalizedEmotion(
      _selectedVoice,
      widget.initialEmotion,
    );
    _auditionPlayer = creationVoiceAuditionPlayerFactory();
    _auditionCompleteSubscription = _auditionPlayer.onComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _auditioningVoiceId = null;
        _auditionBusy = false;
      });
    });
  }

  @override
  void dispose() {
    _auditionCompleteSubscription?.cancel();
    unawaited(_auditionPlayer.stop());
    unawaited(_auditionPlayer.dispose());
    super.dispose();
  }

  /// 选择音色并按当前音色真实标签修正情绪值。
  void _selectVoice(VoiceRole voice) {
    setState(() {
      _selectedVoice = voice;
      _selectedVoiceId = voice.id;
      _selectedEmotion = _normalizedEmotion(voice, _selectedEmotion);
    });
  }

  /// 切换当前音色的情绪标签。
  void _selectEmotion(String emotion) {
    setState(() {
      _selectedEmotion = emotion;
    });
  }

  /// 播放或停止当前音色试听。
  Future<void> _toggleAudition(VoiceRole voice) async {
    final auditionUrl = voice.auditionUrl?.trim() ?? '';
    if (auditionUrl.isEmpty) {
      CustomToast.text('试听音频不可用');
      return;
    }
    if (_auditionBusy) {
      return;
    }
    setState(() {
      _auditionBusy = true;
    });
    try {
      if (_auditioningVoiceId == voice.id) {
        await _auditionPlayer.stop();
        if (!mounted) {
          return;
        }
        setState(() {
          _auditioningVoiceId = null;
          _auditionBusy = false;
        });
        return;
      }
      await _auditionPlayer.stop();
      await _auditionPlayer.play(auditionUrl);
      if (!mounted) {
        return;
      }
      setState(() {
        _auditioningVoiceId = voice.id;
        _auditionBusy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _auditioningVoiceId = null;
          _auditionBusy = false;
        });
      }
      CustomToast.text('试听播放失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CreationSheetScaffold(
      height: 544.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          SizedBox(height: 20.h),
          Expanded(
            child: widget.voices.isEmpty
                ? const Center(
                    child: Text(
                      '暂无可用配音角色',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(17.w, 0, 17.w, 8.h),
                    itemCount: widget.voices.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final voice = widget.voices[index];
                      final selected = voice.id == _selectedVoiceId;
                      return _VoiceRoleCard(
                        voice: voice,
                        selected: selected,
                        selectedEmotion: _selectedEmotion,
                        emotions: _voiceEmotions(voice),
                        auditioning: _auditioningVoiceId == voice.id,
                        onSelect: () => _selectVoice(voice),
                        onEmotionChanged: _selectEmotion,
                        onAudition: () => _toggleAudition(voice),
                      );
                    },
                  ),
          ),
          _SheetActionBar(
            onCancel: () => Navigator.pop(context),
            onConfirm: () {
              Navigator.pop(context, (
                voiceId: _selectedVoiceId,
                emotion: _selectedEmotion,
              ));
            },
          ),
        ],
      ),
    );
  }
}

/// 单个配音角色卡片，选中后展开展示情绪标签。
class _VoiceRoleCard extends StatelessWidget {
  const _VoiceRoleCard({
    required this.voice,
    required this.selected,
    required this.selectedEmotion,
    required this.emotions,
    required this.auditioning,
    required this.onSelect,
    required this.onEmotionChanged,
    required this.onAudition,
  });

  /// 当前卡片对应的配音角色。
  final VoiceRole voice;

  /// 当前角色是否已被选中。
  final bool selected;

  /// 当前选中的情绪标签。
  final String selectedEmotion;

  /// 当前角色可选的情绪标签。
  final List<String> emotions;

  /// 当前角色是否正在试听。
  final bool auditioning;

  /// 选择当前角色。
  final VoidCallback onSelect;

  /// 修改当前角色情绪。
  final ValueChanged<String> onEmotionChanged;

  /// 试听当前角色。
  final VoidCallback onAudition;

  @override
  Widget build(BuildContext context) {
    final showEmotions = selected && emotions.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: showEmotions ? 198.h : 112.h,
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF999999).withValues(alpha: 0.05)
            : const Color(0xFF999999).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
            child: showEmotions
                ? _buildExpanded(context)
                : _buildCompact(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Row(
      children: [
        _VoiceAvatar(coverUrl: voice.coverUrl),
        SizedBox(width: 15.w),
        Expanded(child: _VoiceIdentity(voice: voice)),
        _AuditionPill(playing: auditioning, onTap: onAudition),
        SizedBox(width: 10.w),
        _SelectVoicePill(selected: selected, onTap: onSelect),
      ],
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _VoiceAvatar(coverUrl: voice.coverUrl),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VoiceIdentity(voice: voice),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        '情绪：$selectedEmotion',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Image.asset(
                        AppAssets.iconPackup,
                        width: 14.r,
                        height: 14.r,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _AuditionPill(playing: auditioning, onTap: onAudition),
            SizedBox(width: 10.w),
            _SelectVoicePill(selected: true, onTap: onSelect),
          ],
        ),
        SizedBox(height: 20.h),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 11.w,
            runSpacing: 12.h,
            children: emotions.map((emotion) {
              return _EmotionPill(
                label: emotion,
                selected: emotion == selectedEmotion,
                onTap: () => onEmotionChanged(emotion),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// 配音角色身份信息，负责展示名称、描述和后端真实标签。
class _VoiceIdentity extends StatelessWidget {
  const _VoiceIdentity({required this.voice});

  /// 当前卡片对应的音色。
  final VoiceRole voice;

  @override
  Widget build(BuildContext context) {
    final description = voice.description.trim();
    final badges = _voiceBadges(voice);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          voice.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (description.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        if (badges.isNotEmpty) ...[
          SizedBox(height: 4.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: List<Widget>.generate(badges.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 5.w),
                  child: _VoiceBadge(label: badges[index]),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

/// 音色标签，例如推荐、新、男声/女声。
class _VoiceBadge extends StatelessWidget {
  const _VoiceBadge({required this.label});

  /// 标签文案。
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18.h,
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFCBFF31).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(
          color: const Color(0xFFCBFF31).withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(0xFFCBFF31),
          fontSize: 9.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 配音角色头像，优先展示后端 coverUrl，失败时回退为深色占位。
class _VoiceAvatar extends StatelessWidget {
  const _VoiceAvatar({required this.coverUrl});

  /// 后端返回的音色头像地址。
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    final url = coverUrl.trim();
    final fallback = _VoiceAvatarFallback(size: 48.r);
    return ClipOval(
      child: Container(
        width: 48.r,
        height: 48.r,
        color: Colors.white.withValues(alpha: 0.05),
        child: url.isEmpty
            ? fallback
            : Image.network(
                url,
                width: 48.r,
                height: 48.r,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

/// 头像加载失败时的兜底图形。
class _VoiceAvatarFallback extends StatelessWidget {
  const _VoiceAvatarFallback({required this.size});

  /// 头像尺寸。
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Icon(
        Icons.person_rounded,
        size: 24.r,
        color: Colors.white.withValues(alpha: 0.22),
      ),
    );
  }
}

/// 角色试听入口。
class _AuditionPill extends StatelessWidget {
  const _AuditionPill({required this.playing, required this.onTap});

  /// 当前音色是否正在试听。
  final bool playing;

  /// 点击试听。
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 56.w,
        height: 28.h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.iconListening,
              width: 13.r,
              height: 13.r,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            SizedBox(width: 4.w),
            Text(
              playing ? '停止' : '试听',
              style: TextStyle(
                color: playing ? const Color(0xFFCBFF31) : Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 角色选择状态按钮。
class _SelectVoicePill extends StatelessWidget {
  const _SelectVoicePill({required this.selected, required this.onTap});

  /// 当前角色是否已选中。
  final bool selected;

  /// 点击选择角色。
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 56.w,
        height: 28.h,
        padding: EdgeInsets.all(1.r),
        decoration: BoxDecoration(
          gradient: _voiceGreenGradient,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? _voiceGreenGradient : null,
            color: selected ? null : const Color(0xFF111811),
            borderRadius: BorderRadius.circular(13.r),
          ),
          child: selected
              ? Text(
                  '已选择',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF111811),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : _GradientText(
                  '选择',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
        ),
      ),
    );
  }
}

/// 情绪标签按钮。
class _EmotionPill extends StatelessWidget {
  const _EmotionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// 情绪标签名称。
  final String label;

  /// 当前标签是否选中。
  final bool selected;

  /// 点击选择情绪。
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelText = selected
        ? _GradientText(label, fontSize: 12.sp, fontWeight: FontWeight.w500)
        : Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          );

    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 52.w, minHeight: 26.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            alignment: Alignment.center,
            child: labelText,
          ),
        ),
      ),
    );

    final pill = selected
        ? Container(
            padding: EdgeInsets.all(1.r),
            decoration: BoxDecoration(
              gradient: _voiceGreenGradient,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: child,
          )
        : child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: pill,
    );
  }
}

/// 绿色渐变文字。
class _GradientText extends StatelessWidget {
  const _GradientText(
    this.text, {
    required this.fontSize,
    required this.fontWeight,
  });

  /// 展示文案。
  final String text;

  /// 字号。
  final double fontSize;

  /// 字重。
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => _voiceGreenGradient.createShader(bounds),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

/// 角色弹层统一使用的绿色渐变。
const LinearGradient _voiceGreenGradient = LinearGradient(
  colors: [Color(0xFFF2F865), Color(0xFF6BF775)],
);

VoiceRole? _firstVoice(List<VoiceRole> voices) {
  return voices.isEmpty ? null : voices.first;
}

VoiceRole? _voiceById(List<VoiceRole> voices, String id) {
  for (final voice in voices) {
    if (voice.id == id) {
      return voice;
    }
  }
  return null;
}

List<String> _voiceEmotions(VoiceRole voice) {
  return voice.emotionTags
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<String> _voiceBadges(VoiceRole voice) {
  final labels = <String>[];
  if (voice.recommend) {
    labels.add('推荐');
  }
  if (voice.newVoice) {
    labels.add('新');
  }
  final genderLabel = _voiceGenderLabel(voice.gender);
  if (genderLabel.isNotEmpty) {
    labels.add(genderLabel);
  }
  return labels;
}

String _voiceGenderLabel(String gender) {
  switch (gender.trim().toLowerCase()) {
    case 'man':
    case 'male':
      return '男声';
    case 'woman':
    case 'female':
      return '女声';
    default:
      return '';
  }
}

String _normalizedEmotion(VoiceRole? voice, String emotion) {
  if (voice == null) {
    return emotion.trim();
  }
  final values = _voiceEmotions(voice);
  if (values.isEmpty) {
    return '';
  }
  return values.contains(emotion) ? emotion : values.first;
}
