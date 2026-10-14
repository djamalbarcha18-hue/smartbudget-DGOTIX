import 'package:flutter/widgets.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';

export 'package:smartbudget/core/l10n/app_lang.dart';

/// The display language of the nearest [Localizations].
AppLang appLangOf(BuildContext context) =>
    AppLang.fromCode(Localizations.localeOf(context).languageCode);
