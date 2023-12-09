# To install zsh, with powerline add-ons:
# Ref: https://linuxhint.com/install_zsh_shell_ubuntu_1804/
# Ref: https://dev.to/nicoh/installing-oh-my-zsh-on-ubuntu-362f

sudo apt install git zsh

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sudo chsh -s $(which zsh) $(whoami)

sudo apt-get install powerline fonts-powerline

sudo apt-get install zsh-theme-powerlevel9k

sudo apt install zsh-syntax-highlighting

cd ~/.oh-my-zsh/themes && ln -s /usr/share/powerlevel9k powerlevel9k

sudo reboot
