part of 'index.dart';

typedef EventHandler<T> = void Function(T event);

/// 请求刷新“我的作品”列表的业务事件。
///
/// 视频解说节目提交生成任务并成功创建作品后发出；接收方只需要重新拉取列表，
/// 事件本身不携带作品详情，避免前端列表状态和后端分页数据产生分叉。
final class WorksListRefreshRequested {
  const WorksListRefreshRequested();
}

/// “我的作品”Tab 可见性变化事件。
///
/// [WorksController] 是 permanent controller，不能只依赖 onInit/onClose 判断页面是否可见。
/// 主页面切换底部 Tab 时发出该事件，用于控制作品列表轮询启动和停止。
final class WorksPageVisibilityChanged {
  const WorksPageVisibilityChanged({required this.active});

  /// `true` 表示当前切到作品页，`false` 表示离开作品页。
  final bool active;
}

final class EventService {
  final StreamController<Object> _controller =
      StreamController<Object>.broadcast();

  Stream<T> on<T>() =>
      _controller.stream.where((event) => event is T).cast<T>();

  void emit(Object event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
