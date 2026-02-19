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

sudo apt update

########################################
# Install Flameshot
########################################

default=y
while true; do
  if [[ "$unattended" == "1" ]]
  then
    resp=$default
  else
    [[ -t 0 ]] && {
      read -t 10 -n 2 -p $'\e[1;32mInstall Flameshot? [y/n] (default: '"$default"$')\e[0m\n' resp || resp=$default ;
    }
  fi

  response=`echo $resp | sed -r 's/(.*)$/\1=/'`

  if [[ $response =~ ^(y|Y)=$ ]]
  then
    echo "Installing Flameshot..."
    sudo apt install -y flameshot
    break
  elif [[ $response =~ ^(n|N)=$ ]]
  then
    break
  else
    echo "What? \"$resp\" is not a correct answer. Try y+Enter."
  fi
done


########################################
# Install OBS Studio
########################################

default=y
while true; do
  if [[ "$unattended" == "1" ]]
  then
    resp=$default
  else
    [[ -t 0 ]] && {
      read -t 10 -n 2 -p $'\e[1;32mInstall OBS Studio? [y/n] (default: '"$default"$')\e[0m\n' resp || resp=$default ;
    }
  fi

  response=`echo $resp | sed -r 's/(.*)$/\1=/'`

  if [[ $response =~ ^(y|Y)=$ ]]
  then
    echo "Installing OBS Studio..."
    sudo add-apt-repository -y ppa:obsproject/obs-studio
    sudo apt update
    sudo apt install -y obs-studio
    break
  elif [[ $response =~ ^(n|N)=$ ]]
  then
    break
  else
    echo "What? \"$resp\" is not a correct answer. Try y+Enter."
  fi
done
