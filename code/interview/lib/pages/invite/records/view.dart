part of 'index.dart';

class InviteRecordsPage extends StatefulWidget {
  const InviteRecordsPage({super.key});

  @override
  State<InviteRecordsPage> createState() => _InviteRecordsPageState();
}

class _InviteRecordsPageState extends State<InviteRecordsPage> {
  late final InviteRecordsController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(InviteRecordsController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InviteScaffold(
      title: '邀请列表',
      child: Obx(
        () => AppStateBuilder(
          state: controller.pageState,
          loadingMessage: '加载邀请记录...',
          errorMessage: controller.errorMessage.value ?? '邀请记录加载失败',
          onRetry: controller.loadRecords,
          loading: const InviteDarkLoading(),
          error: InviteDarkError(onRetry: controller.loadRecords),
          builder: (_) => Obx(
            () => RefreshIndicator(
              color: invitePrimary,
              backgroundColor: const Color(0xFF101C10),
              onRefresh: controller.loadRecords,
              child: _InviteRecordsContent(
                overview: controller.overview.value,
                records: controller.filteredRecords,
                selectedFilter: controller.recordFilter.value,
                searchController: controller.recordSearchController,
                onFilterChanged: controller.selectRecordFilter,
                onKeywordChanged: controller.updateRecordKeyword,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteRecordsContent extends StatelessWidget {
  const _InviteRecordsContent({
    required this.overview,
    required this.records,
    required this.selectedFilter,
    required this.searchController,
    required this.onFilterChanged,
    required this.onKeywordChanged,
  });

  final InviteOverview? overview;
  final List<InviteRecord> records;
  final String selectedFilter;
  final TextEditingController searchController;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onKeywordChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('invite-records'),
      padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 36.h),
      children: [
        _TeamStatsCard(overview: overview),
        SizedBox(height: 20.h),
        InvitePanelCard(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的团队',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 18.h),
              _RecordTabs(
                selectedFilter: selectedFilter,
                onChanged: onFilterChanged,
              ),
              SizedBox(height: 16.h),
              _SearchInput(
                controller: searchController,
                onChanged: onKeywordChanged,
              ),
              SizedBox(height: 16.h),
              if (records.isEmpty)
                const InviteEmptyPanel(message: '暂无邀请记录')
              else
                Column(
                  children: records
                      .map(
                        (record) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _InviteRecordCard(record: record),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamStatsCard extends StatelessWidget {
  const _TeamStatsCard({required this.overview});

  final InviteOverview? overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 109.h,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF233209), Color(0xFF071006)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: CustomTheme.primary.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '团队数据',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _TeamStat(label: '团队总数', value: '${overview?.invitedCount ?? 0}'),
              _TeamStat(
                label: '今日新增',
                value: '${overview?.todayNewInvitedCount ?? 0}',
              ),
              _TeamStat(label: '会员人数', value: '${overview?.memberCount ?? 0}'),
              _TeamStat(
                label: '今日新增',
                value: '${overview?.todayNewMemberCount ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamStat extends StatelessWidget {
  const _TeamStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: inviteTextMuted, fontSize: 14.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTabs extends StatelessWidget {
  const _RecordTabs({required this.selectedFilter, required this.onChanged});

  final String selectedFilter;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RecordTab(
          label: '全部',
          selected: selectedFilter == 'ALL',
          onTap: () => onChanged('ALL'),
        ),
        _RecordTab(
          label: '仅注册',
          selected: selectedFilter == 'REGISTERED',
          onTap: () => onChanged('REGISTERED'),
        ),
        _RecordTab(
          label: '会员',
          selected: selectedFilter == 'MEMBER',
          onTap: () => onChanged('MEMBER'),
        ),
      ],
    );
  }
}

class _RecordTab extends StatelessWidget {
  const _RecordTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 26.w),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : inviteTextMuted,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              width: selected ? 28.w : 0,
              height: 2.h,
              color: invitePrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39.h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: Colors.white, fontSize: 13.sp),
        cursorColor: invitePrimary,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white,
            size: 18.r,
          ),
          hintText: '搜索手机号',
          hintStyle: TextStyle(color: inviteTextMuted, fontSize: 13.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        ),
      ),
    );
  }
}

class _InviteRecordCard extends StatelessWidget {
  const _InviteRecordCard({required this.record});

  final InviteRecord record;

  @override
  Widget build(BuildContext context) {
    final member = record.memberCommissionStatus == 'SETTLED';
    return Container(
      constraints: BoxConstraints(minHeight: 107.h),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      decoration: inviteCardDecoration(radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                record.nicknameMasked,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (member) ...[SizedBox(width: 8.w), const InviteMemberTag()],
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            member ? '开通会员名称' : '未开通会员',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            record.createdAtText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: inviteTextMuted, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
