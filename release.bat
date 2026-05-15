@echo off
setlocal enabledelayedexpansion

:: 1. Create dist folder if it doesn't exist
if not exist "dist" mkdir "dist"

:: 2. Extract Version from .toc file
set "VERSION=unknown"
if exist TotemStomper.toc (
    for /f "tokens=2 delims=:" %%a in ('findstr /B /C:"## Version:" TotemStomper.toc') do (
        set "VERSION=%%a"
    )
)

:: 3. Create new fresh folder inside dist
mkdir "dist\TotemStomper"

:: 4. Copy ONLY files with prefix (ignoring other folders)
echo Copying TotemStomper files to dist\TotemStomper...
xcopy "TotemStomper*" "dist\TotemStomper\" /Y

:: 5. Zip the folder inside dist
echo Zipping TotemStomper_v%VERSION%.zip...
powershell -command "Compress-Archive -Path 'dist\TotemStomper' -DestinationPath 'dist\TotemStomper_v%VERSION%.zip' -Force"

:: 6. Cleanup temporary folder
echo Cleaning up temporary files...
rd /S /Q "dist\TotemStomper"

echo.
echo Packaging complete! All build artifacts are in the \dist folder.
pause