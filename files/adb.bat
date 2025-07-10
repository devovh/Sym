bash
diff <(./adb shell pm list packages) <(./adb shell pm list packages -u)
pause