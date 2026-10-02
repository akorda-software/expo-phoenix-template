import type { ExpoConfig } from "expo/config";

function readOptionalEnv(name: string): string | undefined {
  const value = process.env[name];

  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed === "" ? undefined : trimmed;
}

export default (): ExpoConfig => {
  const googleIosUrlScheme = readOptionalEnv("GOOGLE_IOS_URL_SCHEME");
  const plugins: NonNullable<ExpoConfig["plugins"]> = [
    "expo-router",
    "expo-apple-authentication",
    "expo-secure-store"
  ];
  if (googleIosUrlScheme) {
    plugins.push(["@react-native-google-signin/google-signin", { iosUrlScheme: googleIosUrlScheme }]);
  }

  return {
    name: readOptionalEnv("EXPO_APP_NAME") ?? "YourApp",
    slug: readOptionalEnv("EXPO_APP_SLUG") ?? "your_app",
    scheme: readOptionalEnv("EXPO_APP_SCHEME") ?? "your_app",
    version: "0.0.0",
    platforms: ["android", "ios", "web"],
    userInterfaceStyle: "automatic",
    web: {
      bundler: "metro"
    },
    android: {
      package: readOptionalEnv("EXPO_ANDROID_PACKAGE") ?? "app.yourapp.mobile"
    },
    ios: {
      usesAppleSignIn: true,
      bundleIdentifier: readOptionalEnv("EXPO_IOS_BUNDLE_IDENTIFIER") ?? "app.yourapp.mobile"
    },
    plugins,
    extra: {
      apiBaseUrlAndroid: readOptionalEnv("EXPO_PUBLIC_API_BASE_URL_ANDROID"),
      apiBaseUrlIos: readOptionalEnv("EXPO_PUBLIC_API_BASE_URL_IOS"),
      apiBaseUrlWeb: readOptionalEnv("EXPO_PUBLIC_API_BASE_URL_WEB"),
      googleWebClientId: readOptionalEnv("EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID"),
      googleIosClientId: readOptionalEnv("EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID")
    }
  };
};
