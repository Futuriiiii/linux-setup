#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# get the path to this script
APP_PATH=`dirname "$0"`
APP_PATH=`( cd "$APP_PATH" && pwd )`

unattended=0
subinstall_params=""
for param in "$@"
do
  echo $param
  if [ "$param" = "--unattended" ]; then
    echo "installing in unattended mode"
    unattended=1
    subinstall_params="--unattended"
  fi
done

var=`lsb_release -r | awk '{ print $2 }'`
[ "$var" = "18.04" ] && export BEAVER=1
[ "$var" = "22.04" ] && export JAMMY=1

default=y
while true; do
  if [[ "$unattended" == "1" ]]
  then
    resp=$default
  else
    [[ -t 0 ]] && { read -t 10 -n 2 -p $'\e[1;32mInstall vim? [y/n] (default: '"$default"$')\e[0m\n' resp || resp=$default ; }
  fi
  response=`echo $resp | sed -r 's/(.*)$/\1=/'`

  if [[ $response =~ ^(y|Y)=$ ]]
  then

    toilet Setting up vim

    sudo apt-get -y remove vim-* || echo ""

    if [ -n "$BEAVER" ]; then
      sudo apt-get -y install libgnome2-dev libgnomeui-dev libbonoboui2-dev
    fi

    # Dependências base
    sudo apt-get -y install libncurses5-dev libncursesw5-dev libgtk2.0-dev libatk1.0-dev libcairo2-dev libx11-dev libxpm-dev libxt-dev clang-format build-essential cmake

    # Instala o Python 3.12 no Jammy (22.04) para suportar o YCM novo
    if [ -n "$JAMMY" ]; then
      sudo add-apt-repository -y ppa:deadsnakes/ppa
      sudo apt-get update
      sudo apt-get -y install python3.12 python3.12-dev python3.12-venv python3-dev
      PYTHON_CMD="python3.12"
    else
      sudo apt-get -y install python3-dev
      PYTHON_CMD="python3"
    fi

    sudo -H pip3 install rospkg

    # compile vim from sources
    cd $APP_PATH/../../submodules/vim
    
    # Atualiza o repositório para garantir Vim 9.1+
    git checkout master || git checkout main
    git pull

    make clean || true
    ./configure --with-features=huge \
      --enable-multibyte \
      --enable-python3interp=yes \
      --with-python3-command=$PYTHON_CMD \
      --enable-perlinterp=yes \
      --enable-luainterp=yes \
      --enable-gui=no \
      --enable-cscope --prefix=/usr

      cd src
      make -j$(nproc)
      cd ../
      sudo make install

    # set vim as a default git mergetool
    git config --global merge.tool vimdiff

    # symlink vim settings
    rm -rf ~/.vim
    ln -fs $APP_PATH/dotvim ~/.vim

    # updated new plugins and clean old plugins
    if [ -n "$JAMMY" ]; then
      # Garante que o arquivo da 22.04 seja o principal
      ln -fs $APP_PATH/dotvim22rc ~/.vimrc
      /usr/bin/vim -E -c "let g:user_mode=1" -c "PlugInstall" -c "wqa" || echo "It normally returns >0"
    else
      ln -fs $APP_PATH/dotvimrc ~/.vimrc
      /usr/bin/vim -E -c "let g:user_mode=1" -c "PlugInstall" -c "wqa" || echo "It normally returns >0"
    fi

    if [ -n "$JAMMY" ]; then
      default=n
    else
      default=y
    fi

    while true; do
      if [[ "$unattended" == "1" ]]
      then
        resp=$default
      else
        [[ -t 0 ]] && { read -t 10 -n 2 -p $'\e[1;32mCompile YouCompleteMe? [y/n] (default: '"$default"$')\e[0m\n' resp || resp=$default ; }
      fi
      response=`echo $resp | sed -r 's/(.*)$/\1=/'`

      if [[ $response =~ ^(y|Y)=$ ]]
      then

        # set youcompleteme
        toilet Setting up youcompleteme

        # if not on 20.04, g++-8 has to be installed manually
        if [ -n "$BEAVER" ]; then
          sudo apt-get -y install g++-8
          sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 700 --slave /usr/bin/g++ g++ /usr/bin/g++-7
          sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 --slave /usr/bin/g++ g++ /usr/bin/g++-8
          # add llvm repo for clangd and python3-clang
          wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
          sudo apt-add-repository "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-11 main"
          sudo apt-get -y install clang-11 libclang-11-dev
          sudo pip3 install clang
        else
          # if 20.04/22.04, just install python3-clang from apt
          sudo apt-get -y install python3-clang 
        fi
        
        # install prequisites for YCM
        sudo apt-get -y install clangd-11
        # set clangd to version 11 by default
        sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-11 999 || true
        sudo apt-get -y install libboost-all-dev

        # Proteção: Se o PlugInstall não baixou o YCM, clona agora
        if [ ! -d "$HOME/.vim/plugged/YouCompleteMe" ]; then
          echo "Clonando YouCompleteMe manualmente..."
          mkdir -p ~/.vim/plugged
          git clone https://github.com/ycm-core/YouCompleteMe.git ~/.vim/plugged/YouCompleteMe
        fi

        cd ~/.vim/plugged/YouCompleteMe/
        git submodule update --init --recursive
        
        # Usa a variável dinâmica para compilar com o Python correto
        $PYTHON_CMD ./install.py --clangd-completer

        # link .ycm_extra_conf.py
        ln -fs $APP_PATH/dotycm_extra_conf.py ~/.ycm_extra_conf.py

        break
      elif [[ $response =~ ^(n|N)=$ ]]
      then
        break
      else
        echo " What? \"$resp\" is not a correct answer. Try y+Enter."
      fi
    done

    break
  elif [[ $response =~ ^(n|N)=$ ]]
  then
    break
  else
    echo " What? \"$resp\" is not a correct answer. Try y+Enter."
  fi
  vim +PlugInstall +qall
done
