# Google Authentication Setup Guide (Takwa App)

This guide provides step-by-step instructions for configuring Google Authentication in the Takwa app using **Supabase** and **Google Cloud Console**.

---

## 1. Create a Release Keystore

The release keystore is used to sign your app for production. You need the SHA-1 and SHA-256 fingerprints from this file to register your app with Google.

### Generate the Keystore

If running `keytool` directly fails with "command not found", it is likely because your Java `bin` folder is not in your system PATH.

Since you are a Flutter developer, you can use the `keytool` bundled with Android Studio:

```bash
# Run this exact command (Windows path for Android Studio JBR)
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore takwa-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias takwa
```

> [!NOTE]
> When prompted for the keystore password, typing will be invisible. Press Enter when done.

> [!IMPORTANT]
>
> - **Destination**: This will create a file named `takwa-release-key.jks` in your current directory. Save this file securely.

### Extract SHA Fingerprints

To see your SHA-1 and SHA-256 fingerprints, run:

```bash
keytool -list -v -keystore takwa-release-key.jks -alias takwa
```

Copy the **SHA-1** and **SHA-256** values. You will need them in the next steps.

---

## 2. Google Cloud Console Configuration

### Create/Select a Project

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project or select your existing one.

### Configure OAuth Consent Screen

1. Go to **APIs & Services > OAuth consent screen**.
2. Select **External** and click **Create**.
3. Fill in the required app information (App name: `Takwa`, User support email, Developer contact info).
4. Add the `.../auth/userinfo.email`, `.../auth/userinfo.profile`, and `openid` scopes.

### Create OAuth 2.0 Client IDs

You need **two** Client IDs: one for Android and one for the Web (which Supabase uses).

#### A. Android Client ID

1. Go to **APIs & Services > Credentials**.
2. Click **Create Credentials > OAuth client ID**.
3. Select **Android** as the application type.
4. **Name**: `Takwa Android Release`.
5. **Package Name**: `com.takwa`
6. **SHA-1 certificate fingerprint**: Paste the SHA-1 you extracted from your keystore.
7. Click **Create**.

#### B. Web Client ID (Required for Supabase)

1. Click **Create Credentials > OAuth client ID**.
2. Select **Web application** as the application type.
3. **Name**: `Takwa Supabase Auth`.
4. **Authorized redirect URIs**:
   - You need to get this from Supabase: `https://[YOUR_PROJECT_REF].supabase.co/auth/v1/callback`
5. Click **Create**.
6. **Save the Client ID and Client Secret**.

---

## 3. Supabase Console Configuration

1. Go to your [Supabase Dashboard](https://app.supabase.com/).
2. Select your project and go to **Authentication > Providers**.
3. Find **Google** and enable it.
4. **Client ID (for Google)**: Paste the **Web Client ID** (from Step 2B).
5. **Client Secret (for Google)**: Paste the **Web Client Secret** (from Step 2B).
6. Click **Save**.

---

## 4. Flutter App Configuration

### Android Signing Config

Update `android/app/build.gradle.kts` to use your release key:

```kotlin
android {
    // ...
    signingConfigs {
        create("release") {
            keyAlias = "takwa"
            keyPassword = "YOUR_KEY_PASSWORD"
            storeFile = file("PATH_TO_YOUR_KEYSTORE") // e.g., file("../../takwa-release-key.jks")
            storePassword = "YOUR_STORE_PASSWORD"
        }
    }
    buildTypes {
        release {
           signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### Google Sign-In Setup

In your Flutter code (e.g., `lib/core/providers/auth_providers.dart`), make sure you use the **Web Client ID** for the `google_sign_in` configuration on Android:

```dart
final GoogleSignIn googleSignIn = GoogleSignIn(
  clientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com', // DO NOT use the Android client ID here
);
```

---

## 5. Summary Checklist

- [ ] Keystore generated and fingerprints saved.
- [ ] Android Client ID created in Google Cloud with production SHA-1.
- [ ] Web Client ID created in Google Cloud.
- [ ] Google Provider enabled in Supabase with Web Client ID/Secret.
- [ ] Supabase Redirect URL added to Google Cloud.
- [ ] `build.gradle.kts` updated with release signing config.
