import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:narrate/utils/index.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../apis/index.dart';
import '../../enums/index.dart';
import '../../models/index.dart';
import '../../routes/index.dart';
import '../../services/index.dart';
import '../../store/index.dart';
import '../../theme.dart';
import '../../widgets/index.dart';
import '../main/index.dart';

part 'controller.dart';
part 'dialog/delete_confirm_dialog.dart';
part 'dialog/entitlement_dialog.dart';
part 'dialog/more_settings_sheet.dart';
part 'dialog/points_confirm_dialog.dart';
part 'dialog/style_sheet.dart';
part 'dialog/upload_progress_dialog.dart';
part 'dialog/video_preview_dialog.dart';
part 'dialog/voice_sheet.dart';
part 'view.dart';
part 'widgets/creation_sheet_widgets.dart';
