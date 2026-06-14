part of 'index.dart';

final class WorkDetailController extends GetxController {
  WorkDetailController({required this.workId});

  final String workId;

  final RxBool loading = false.obs;
  final RxBool downloading = false.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<WorkDetail> detail = Rxn<WorkDetail>();

  bool get _useMock => Get.find<ConfigStore>().mockEnabled.value;
  MockService get _mock => Get.find<MockService>();

  ViewState get pageState {
    if (loading.value) {
      return ViewState.loading;
    }
    if (errorMessage.value != null) {
      return ViewState.error;
    }
    if (detail.value == null) {
      return ViewState.notFound;
    }
    return ViewState.success;
  }

  @override
  void onInit() {
    super.onInit();
    loadDetail();
  }

  Future<void> loadDetail() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      detail.value = await _detail(workId);
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
    } finally {
      loading.value = false;
    }
  }

  /// 下载生成完成的作品视频，并保存到系统相册。
  Future<void> download(BuildContext context, {int variantIndex = 0}) async {
    final item = detail.value;
    if (item == null) {
      return;
    }
    if (item.status == WorkStatus.expired) {
      CustomToast.text('作品已过期，无法下载');
      return;
    }
    if (item.status != WorkStatus.succeeded) {
      CustomToast.text('作品生成完成后才可下载');
      return;
    }

    if (downloading.value) {
      return;
    }
    downloading.value = true;
    try {
      CustomToast.showProgress(0.05, '正在获取下载地址...');
      final variant = item.videoVariantAt(variantIndex);
      if (_useMock) {
        await _mock.resolve<String>(
          'mock://download/${item.id}_${variantIndex + 1}.mp4',
          mockKey: 'works.download',
        );
        CustomToast.showProgress(1, '视频已保存到相册');
        CustomToast.dismiss();
        CustomToast.success('视频已保存到相册');
      } else {
        final downloadUrl = variant?.downloadUrl?.trim().isNotEmpty == true
            ? variant!.downloadUrl!.trim()
            : await WorksAPI.downloadUrl(item.id, variantId: variant?.id);
        if (!context.mounted) {
          CustomToast.dismiss();
          return;
        }
        await WorkDownloadService.saveVideoToGallery(
          context: context,
          url: downloadUrl,
          workId: item.id,
          onProgress: CustomToast.showProgress,
        );
        CustomToast.dismiss();
        CustomToast.success('视频已保存到相册');
      }
    } on ApiException catch (error) {
      CustomToast.dismiss();
      CustomToast.text(error.userMessage);
    } on WorkDownloadException catch (error) {
      CustomToast.dismiss();
      CustomToast.fail(error.message);
    } catch (_) {
      CustomToast.dismiss();
      CustomToast.fail('视频下载失败，请重试');
    } finally {
      downloading.value = false;
    }
  }

  Future<WorkDetail> _detail(String id) {
    if (!_useMock) {
      return WorksAPI.detail(id);
    }
    final detail = _mockDetail(id);
    if (detail == null) {
      throw const ApiException(type: ApiErrorType.notFound);
    }
    return _mock.resolve<WorkDetail>(detail, mockKey: 'works.detail');
  }

  WorkDetail? _mockDetail(String id) {
    Work? work;
    for (final item in _mockWorks) {
      if (item.id == id) {
        work = item;
        break;
      }
    }
    if (work == null) {
      return null;
    }
    return WorkDetail(
      id: work.id,
      title: work.title,
      coverUrl: work.coverUrl,
      videoUrl: 'mock://video/${work.id}.mp4',
      durationText: work.durationText,
      status: work.status,
      workType: work.workType,
      createdAtText: work.createdAtText,
      params: const <String, String>{'风格': '快剪快讲', '配音': '解说小帅', '语速': '1.0x'},
      expireAtText: '7 天后过期',
    );
  }

  static const List<Work> _mockWorks = <Work>[
    Work(
      id: 'work_001',
      title: '夜晚的城市街道',
      coverUrl: '',
      durationText: '01:26',
      status: WorkStatus.succeeded,
      workType: WorkType.shortSeries,
      createdAtText: '今天 12:20',
    ),
    Work(
      id: 'work_002',
      title: '电影剧情顺剪',
      coverUrl: '',
      durationText: '00:58',
      status: WorkStatus.generating,
      workType: WorkType.movie,
      createdAtText: '今天 10:18',
    ),
    Work(
      id: 'work_003',
      title: '切片快剪-小说转漫画-悬疑惊悚19701',
      coverUrl: '',
      durationText: '03:20',
      status: WorkStatus.draft,
      workType: WorkType.movie,
      createdAtText: '2026-01-26',
    ),
    Work(
      id: 'work_004',
      title: '电视剧高能片段解说',
      coverUrl: '',
      durationText: '02:12',
      status: WorkStatus.failed,
      workType: WorkType.tvSeries,
      createdAtText: '2026-01-25',
    ),
  ];
}
