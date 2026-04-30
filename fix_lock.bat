@echo off
echo Dang don dep cac tien trinh Flutter bi treo...
taskkill /F /IM dart.exe /T >nul 2>&1
taskkill /F /IM flutter.bat /T >nul 2>&1

echo Xoa thu muc cache va build...
rmdir /s /q build 
rmdir /s /q .dart_tool 
rmdir /s /q windows\flutter\ephemeral 
rmdir /s /q macos\Flutter\ephemeral 
rmdir /s /q ios\Flutter\ephemeral 

echo Da mo khoa thu muc thanh cong! Ban co the build lai App.
pause
