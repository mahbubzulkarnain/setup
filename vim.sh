#!/usr/bin/env bash
set -euo pipefail

echo "Install vim..."

mkdir -p ~/.vim/autoload ~/.vim/plugged ~/.vim/colors ~/.vim/doc

curl -fsSL "https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim" -o ~/.vim/autoload/pathogen.vim

curl -fsSL "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" -o ~/.vim/autoload/plug.vim

curl -fsSL "https://raw.githubusercontent.com/rakr/vim-one/master/colors/one.vim" -o ~/.vim/colors/one.vim

curl -fsSL "https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/vim/.vimrc" -o ~/.vimrc