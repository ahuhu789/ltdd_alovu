@echo off
echo Dang dong cac tien trinh Java/Kotlin/Dart bi treo...
taskkill /F /IM java.exe /T >nul 2>&1
taskkill /F /IM dart.exe /T >nul 2>&1
taskkill /F /IM kotlin.exe /T >nul 2>&1

echo Xoa thu muc build cua Flutter SDK...
rmdir /s /q "C:\flutter_windows_3.38.6-stable\flutter\packages\flutter_tools\gradle\build" >nul 2>&1

echo Xoa thu muc cache va build cua project...
rmdir /s /q build >nul 2>&1
rmdir /s /q .dart_tool >nul 2>&1

echo Da mo khoa thu muc thanh cong! Ban co the build lai App.
pause
