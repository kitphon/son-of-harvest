@echo off
rem Double-click to skip the title and start on the field (--demo: 10:00, planted plots).
cd /d "%~dp0"
call "%~dp0play.bat" %* -- --demo
