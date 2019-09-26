# Path to your oh-my-zsh installation.
export ZSH=/home/jredding/.oh-my-zsh
export ZSH_CUSTOM=/home/jredding/.oh-my-zsh/custom

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_COLOR_SCHEME='dark'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(root_indicator virtualenv context dir)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs vcs)
ZSH_THEME="powerlevel9k/powerlevel9k"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  colored-man
  colorize
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh
source /opt/ros/kinetic/setup.zsh
source /home/jredding/kitty_ws/devel/setup.zsh

# User configuration
export CC="/usr/bin/gcc"
export CXX="/usr/bin/g++"
export PATH="$PATH:$HOME/bin"
# source /home/jredding/.bazel/bin/bazel-complete.bash

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
alias kws="cd ~/kitty_ws/"
alias ks="kws; cd src/kitty_stack/"
alias ll="ls -alt"
alias gs="git status"
alias gb="git branch"
alias clean="kws; rm -rf ./build ./devel ./install ./third_party"
alias nuke="clean; ccache -C"
alias setup="kws; cd src/kitty_stack; ./setup.sh"
alias cm="kws; catkin_make -j7"
alias cmi="cm; catkin_make -j7 install"
alias cmt="kws; catkin_make tests"
alias cmr="kws; catkin_make run_tests"
alias cmd="kws; catkin_make -DCMAKE_BUILD_TYPE=Debug -j7"
alias sim1="kws; source devel/setup.sh; rosrun kittymaster launch.py veh:=F261s multi_kp:=false"
alias sim="kws; source devel/setup.sh; rosrun kittymaster launch.py veh:=F261s multi_kp:=true"
alias gcs="kws; source devel/setup.sh; ks; ./gcs/kitty_station/scripts/start_kitty_station.sh localhost --namespace=F261s --kill_switch_active=false --auto_launch_plots=false --plot1=false --plot2=false --plot3=false"
alias ssharm="ssh ubuntu@147.75.108.106"

unsetopt share_history

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/jredding/google-cloud-sdk/path.zsh.inc' ]; then . '/home/jredding/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/jredding/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/jredding/google-cloud-sdk/completion.zsh.inc'; fi
