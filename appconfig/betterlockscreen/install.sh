#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

unattended=0
for param in "$@"
do
  if [ "$param" = "--unattended" ]; then
    echo "installing in unattended mode"
    unattended=1
  fi
done

########################################
# Install BetterLockScreen
########################################

default=y
while true; do
  if [[ "$unattended" == "1" ]]
  then
    resp=$default
  else
    [[ -t 0 ]] && {
      read -t 10 -n 2 -p $'\e[1;32mInstall BetterLockScreen? [y/n] (default: '"$default"$')\e[0m\n' resp || resp=$default ;
    }
  fi

  response=`echo $resp | sed -r 's/(.*)$/\1=/'`

  if [[ $response =~ ^(y|Y)=$ ]]
  then
    toilet Installing BetterLockScreen

    sudo apt update

    sudo apt install -y \
      autoconf gcc make pkg-config \
      libpam0g-dev libcairo2-dev libfontconfig1-dev \
      libxcb-composite0-dev libev-dev libx11-xcb-dev \
      libxcb-xkb-dev libxcb-xinerama0-dev libxcb-randr0-dev \
      libxcb-image0-dev libxcb-util0-dev libxcb-xrm-dev \
      libxkbcommon-dev libxkbcommon-x11-dev \
      libjpeg-dev libgif-dev

    # Install i3lock-color
    cd ~/git/linux-setup/submodules/i3lock-color
    ./install-i3lock-color.sh
    cd ~/git

    # Install betterlockscreen
    wget https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh -O - -q | sudo bash -s system

    # Set wallpaper
    betterlockscreen -u ~/git/linux-setup/miscellaneous/wallpapers/petr.jpg

    break

  elif [[ $response =~ ^(n|N)=$ ]]
  then
    break
  else
    echo "What? \"$resp\" is not a correct answer. Try y+Enter."
  fi
done
