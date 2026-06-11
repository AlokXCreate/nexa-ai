/// Environment Configuration
/// Determines which API endpoints, feature flags, and keys to use.
enum Environment {
  development,
  staging,
  production,
}

class EnvConfig {
  static late final Environment currentEnvironment;
  static late final String apiBaseUrl;

  static void initialize(Environment env) {
    currentEnvironment = env;
    switch (env) {
      case Environment.development:
        apiBaseUrl = 'https://dev-api.localmind.ai';
        break;
      case Environment.staging:
        apiBaseUrl = 'https://staging-api.localmind.ai';
        break;
      case Environment.production:
        apiBaseUrl = 'https://api.localmind.ai';
        break;
    }
  }
}
