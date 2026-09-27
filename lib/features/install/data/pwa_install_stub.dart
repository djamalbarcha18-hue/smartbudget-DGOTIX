enum InstallMode {
  /// Nothing to offer (unsupported browser, or not the web).
  none,

  /// The browser can install it: show an "Install" button.
  prompt,

  /// iPhone/iPad Safari: install through Share → Add to Home Screen.
  iosHint,

  /// Already running as an installed app.
  installed,
}

InstallMode installMode() => InstallMode.none;

Future<bool> promptInstall() async => false;

Stream<void> installChanges() => const Stream<void>.empty();
