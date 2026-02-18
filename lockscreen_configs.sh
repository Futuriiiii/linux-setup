# - make the script run in bash/zsh while having its dotfile sourced
# - this is important when there are variables exported, which might
#   be used by this script

sudo apt install autoconf gcc make pkg-config libpam0g-dev libcairo2-dev libfontconfig1-dev libxcb-composite0-dev libev-dev libx11-xcb-dev libxcb-xkb-dev libxcb-xinerama0-dev libxcb-randr0-dev libxcb-image0-dev libxcb-util0-dev libxcb-xrm-dev libxkbcommon-dev libxkbcommon-x11-dev libjpeg-dev libgif-dev

cd submodules/i3lock-color
./install-i3lock-color.sh
cd ~/git 

wget https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh -O - -q | sudo bash -s system

betterlockscreen -u ~/git/linux-setup/miscellaneous/wallpapers/capybots.jpg
