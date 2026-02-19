#!/bin/bash
set -e

echo "=== Installing latest Vim for YouCompleteMe (Ubuntu 22.04) ==="

sudo apt update

# Remove old vim
sudo apt remove -y vim vim-tiny vim-common vim-runtime || true

# Install dependencies
sudo apt install -y \
  build-essential \
  cmake \
  git \
  curl \
  libncurses-dev \
  libgtk-3-dev \
  libatk1.0-dev \
  libcairo2-dev \
  libx11-dev \
  libxpm-dev \
  libxt-dev \
  python3-dev \
  python3-pip \
  clang \
  clangd \
  libclang-dev \
  libboost-all-dev

# Get python config dir automatically
PYTHON_CONFIG_DIR=$(python3 - <<EOF
import sysconfig
print(sysconfig.get_config_var("LIBPL"))
EOF
)

echo "Python config dir: $PYTHON_CONFIG_DIR"

# Clone latest Vim
cd /tmp
rm -rf vim
git clone https://github.com/vim/vim.git
cd vim

# Compile Vim
./configure \
  --with-features=huge \
  --enable-multibyte \
  --enable-python3interp=yes \
  --with-python3-config-dir=$PYTHON_CONFIG_DIR \
  --enable-cscope \
  --enable-terminal \
  --enable-gui=no \
  --prefix=/usr/local

make -j$(nproc)
sudo make install

echo "Vim installed:"
vim --version | grep python

# Install plugins
echo "Installing plugins..."
vim +PlugInstall +qall || true

# Compile YouCompleteMe
if [ -d "$HOME/.vim/plugged/YouCompleteMe" ]; then
  cd ~/.vim/plugged/YouCompleteMe
  git submodule update --init --recursive
  python3 install.py --clangd-completer
else
  echo "YouCompleteMe not found in ~/.vim/plugged"
fi

echo "=== DONE ==="
