class GoogleAuthConfig {
  const GoogleAuthConfig._();

  static const String androidPackageName = 'com.example.frontend';

  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '668109690310-q3cmtd9olaptsnp7q8snphdqemcrncis.apps.googleusercontent.com',
  );

  static String? get clientId {
    final value = webClientId.trim();
    return value.isEmpty ? null : value;
  }

  static String? get serverClientId => clientId;
}
