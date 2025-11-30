// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'UNO متعدد اللاعبين';

  @override
  String get createRoom => 'إنشاء غرفة';

  @override
  String get joinRoom => 'انضمام لغرفة';

  @override
  String get enterName => 'أدخل اسمك';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get roomName => 'اسم الغرفة';

  @override
  String get password => 'كلمة المرور (اختياري)';

  @override
  String get create => 'إنشاء';

  @override
  String get join => 'انضمام';

  @override
  String get players => 'اللاعبين';

  @override
  String get waitingForHost => 'بانتظار المضيف لبدء اللعبة...';

  @override
  String get startGame => 'بدء اللعبة';

  @override
  String get leaveRoom => 'مغادرة الغرفة';

  @override
  String get uno => 'أونو!';

  @override
  String get drawCard => 'سحب ورقة';

  @override
  String get yourTurn => 'دورك';

  @override
  String get winner => 'فائز!';

  @override
  String get playAgain => 'العب مرة أخرى';
}
