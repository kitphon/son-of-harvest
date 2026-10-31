@echo off
rem Double-click to play Harvest Son (title screen).
rem Uses the Godot 4.7.2 binary kept next to the project (not in git).
cd /d "%~dp0"
if not exist "%~dp0Godot_v4.7.2-stable_win64.exe" (
    echo Godot_v4.7.2-stable_win64.exe was not found in %~dp0
    echo Put the Godot 4.7.2 editor binary next to project.godot and try again.
    pause
    exit /b 1
)
start "" "%~dp0Godot_v4.7.2-stable_win64.exe" --path . %*
