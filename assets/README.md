# Assets Folder

## Alarm Sound

### alarm.mp3
This is a placeholder audio file required by the alarm package.

**On Android**: The app uses the native system alarm sound (same as the Clock app) through a custom notification channel configured in MainActivity.kt. The placeholder file is not actually played.

**On iOS**: The placeholder file would be used, but you can replace it with any alarm sound you prefer.

The Android implementation in `MainActivity.kt` configures the notification channel to use:
```kotlin
RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
```

This ensures your reminders sound exactly like Android's built-in alarms! 🔔
