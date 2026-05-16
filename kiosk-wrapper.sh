#!/bin/sh

#The purpose of this program is to create a wrapper for Google Chrome's kiosk mode that restarts it after a period of inactivity. This script requires dbus, Gnome 4X in standard Wayland or single application Wayland mode (some versions of Gnome 3 may work, but they are untested), sleep, awk, Google Chrome, and a POSIX-compliant shell. CMD, PowerShell, and Fish shells will not work, and Google Chrome must be named or aliased to "google-chrome"!

#Creates the documentation show when the -h (help) flag or an invalid option are used
displayHelp(){
    echo "Usage:"
    echo "    kiosk-wrapper [-v] [-V] [-t NUMBER] [-p NUMBER] [-w URL]"
    echo "Options:"
    echo "    -v, verbose                 shows outputs of what the program is doing"
    echo "    -V, version                 shows program version"
    echo "    -t [int], timeout           set custom timeout value in milliseconds (must be a counting number)"
    echo "    -p [int], polling rate      set custom polling rate in seconds (must be a positive number)"
    echo "    -w [str], website           set custom URL (must inclue protocol ex. https://)"
    exit 0
}

#Sets verbose mode to off by default, sets the default timeout to 300,000 milliseconds (5 minutes), sets the default polling rate to 5 seconds, and sets the default website to Blue CoLab's kiosk website
verbose=false
timeout=300000
pollingRate=5
website="https://bluecolab.github.io/react-kiosk"
refreshed=false
extension_path="/path/to/chrome-extension"

#Checks for flags. -v enables verbose mode, -V echos the version information -t allows for user set timeout in milliseconds, -p allows for user set polling rate,and -w allows for user set website
while getopts "h?vVt:p:w:" opt; do
  case "$opt" in
    h|\?)
      displayHelp
      ;;
    v)  verbose=true
      ;;
    V)
      echo "Kiosk Wrapper, Version 2.0.0"
      echo "Created by Sebastian Roman 2024-05-04"
      echo "Modified by Kenji Okura + Victor Lima 2025-05-12"
      exit 0  
      ;;
    t)  timeout=$OPTARG
      ;;
    p)  pollingRate=$OPTARG
      ;;
    w)  website="$OPTARG"
      ;;
  esac
done

#When verbose mode is enabled, tells the user what the variables are set to
if $verbose; then
  echo "verbose mode: $verbose"
  echo "polling rate: $pollingRate seconds"
  echo "timeout: $timeout milliseconds"
  echo "website: $website"
fi

#Creates the first instance of the kiosk
google-chrome --kiosk "$website" --load-extension="$extension_path" &
if $verbose; then
  echo "started initial kiosk and the script continues"
fi

python -m http.server 9999 -d /home/kiosk-user/Videos

#Creates forever loop
while true; do 
  #Pauses the loop for as long as the polling rate is set to
  sleep ${pollingRate}s
  #Checks the idle time in Wayland
  idleTime=$(dbus-send --print-reply --dest=org.gnome.Mutter.IdleMonitor /org/gnome/Mutter/IdleMonitor/Core org.gnome.Mutter.IdleMonitor.GetIdletime | awk -F 'uint64 ' '{print $2}')
  #When in verbose mode it prints the current idle time, the variable for idle time, and the refreshed status
  if $verbose; then
    echo "refreshed: ${refreshed}"
    echo $idleTime
    echo $(dbus-send --print-reply --dest=org.gnome.Mutter.IdleMonitor /org/gnome/Mutter/IdleMonitor/Core org.gnome.Mutter.IdleMonitor.GetIdletime | awk -F 'uint64 ' '{print $2}')
  fi
  #Runs the nested code if the idle time is above the threshold and it hasn't already refreshed since the last user input, to prevent continuous refreshing
  if [ "$idleTime" -gt "$timeout" ]; then
    if $verbose; then
      echo "idle > $timeout"
    fi
    if [ $refreshed = false ]; then
      #Restarts the browser. Closing the previous instance is unnecessary. This will also still work if the user closed out of the browser without stopping this script
      google-chrome --kiosk "$website" --load-extension="$extension_path" &
      #Sets refreshed to true to prevent continuous refreshing
      refreshed=true
    fi
  #If the idle time is below the threshold, it resets refreshed to false
  else
    refreshed=false
  fi
done
