# google-services.json needed here

Once a Firebase project exists for this app (Android package name
`com.example.supervisormobile` — the current placeholder applicationId in
`android/app/build.gradle`), download its Android config file from the Firebase
console and place it at:

    android/app/google-services.json

The Gradle plugin (`com.google.gms.google-services`, already applied in
`android/build.gradle` / `android/app/build.gradle`) picks it up automatically
on the next build — no other code changes needed.

If the applicationId is changed before shipping, the `google-services.json`
must be regenerated for the new package name (Firebase keys the config to the
exact package name).
