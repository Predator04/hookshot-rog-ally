@echo off
rem One-step install of Longshot for the ROG Ally: see Install-LongshotAlly.ps1 next to this file.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-LongshotAlly.ps1" %*
