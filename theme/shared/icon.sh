#!/bin/sh

function icon_map() {
  case $1 in
    "Arc"|"Firefox"|"Zen")
      ICON=
      ;;
    "Code"|"Cursor"|"VSCodium"|"Xcode"|"Xcode-beta")
      ICON=󰨞
      ;;
    "Claude")
      ICON=⚹
      ;;
    "Calendar")
      ICON=
      ;;
    "Docker Desktop")
      ICON=
      ;;
    "Discord"|"Voxa"|"Discord Canary")
      ICON=
      ;;
    "Postman")
      ICON=⛑
      ;;
    "FaceTime")
      ICON=
      ;;
    "Finder"|"ForkLift")
      ICON=󰀶
      ;;
    "Google Chrome")
      ICON=
      ;;
    "IINA"|"Crunchyroll")
      ICON=󰥠
      ;;
    "kitty")
      ICON=󰄛
      ;;
    "Ghostty")
      ICON=󰊠
      ;;
    "Messages")
      ICON=
      ;;
    "Notion"|"Obsidian"|"Notes")
      ICON=
      ;;
    "Goodnotes")
      ICON=
      ;;
    "Preview")
      ICON=
      ;;
    "PS Remote Play"|"Prism Launcher"|"CrossOver")
      ICON=
      ;;
    "Prism Launcher"|"Lunar Client")
      ICON=󰍳
      ;;
    "Spotify")
      ICON=
      ;;
    "TextEdit"|"Sublime Text")
      ICON=
      ;;
    "Transmission")
      ICON=󱎔
      ;;
    "LM Studio")
      ICON=󰶘
      ;;
    "Mail"|"Thunderbird")
      ICON=
      ;;
    "Passwords")
      ICON=
      ;;
    "Parallels Desktop")
      ICON=
      ;;
    "App Store")
      ICON=
      ;;
    "Setapp")
      ICON=
      ;;
    "System Settings")
      ICON=
      ;;
    "Reminders")
      ICON=
      ;;
    *)
      ICON=󰘔
      ;;
  esac
}

icon_map "$1"

echo "$ICON"
