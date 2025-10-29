# ~/.bashrc: executed by bash(1) for non-login shells.
export SHELL=/bin/bash
# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
#PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
#umask 022

# You may uncomment the following lines if you want `ls' to be colorized:
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'

# git
alias gpull='git pull origin $(git symbolic-ref --short HEAD)'
alias gpush='git push origin $(git symbolic-ref --short HEAD)'
alias gst='git status'

# Some more alias to avoid making mistakes:
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'



# --- colors (wrap with \[ \] to keep readline sane)
C_RESET='\[\e[0m\]'
C_DIM='\[\e[2m\]'
C_PATH='\[\e[1;34m\]'
C_GIT='\[\e[38;5;39m\]'
C_AHEAD='\[\e[38;5;70m\]'
C_BEHIND='\[\e[38;5;178m\]'
C_STAGED='\[\e[38;5;40m\]'
C_UNSTAGED='\[\e[38;5;208m\]'
C_UNTRACKED='\[\e[38;5;244m\]'
C_CONFLICT='\[\e[38;5;196m\]'
C_OP='\[\e[38;5;141m\]'
C_ERR='\[\e[38;5;160m\]'
C_PROMPT='\[\e[1;36m\]'

git_info() {
  # porcelain v2 for reliable parsing
  local out branch="" ahead=0 behind=0 staged=0 unstaged=0 untracked=0 conflicts=0 op=""
  out=$(git -c color.status=false status --porcelain=v2 -b -uno 2>/dev/null) || return 0

  while IFS= read -r line; do
    case "$line" in
      "# branch.head "*)
        branch=${line#"# branch.head "}
        ;;
      "# branch.ab "*)
        # format: "# branch.ab +A -B"
        local rest=${line#"# branch.ab "}
        local a=${rest%% *}; a=${a#+}
        local b=${rest#* }; b=${b#-}
        ahead=${a:-0}; behind=${b:-0}
        ;;
      "1 "*|"2 "*)
        # XY status at positions 3-4
        local xy=${line:2:2}
        [[ ${xy:0:1} != '.' ]] && ((staged++))
        [[ ${xy:1:1} != '.' ]] && ((unstaged++))
        ;;
      "? "*)
        ((untracked++))
        ;;
      "u "*)
        ((conflicts++))
        ;;
    esac
  done <<<"$out"

  # detached or unknown branch name fallback
  if [[ -z $branch || $branch == "(detached)" ]]; then
    branch=$(git describe --tags --always 2>/dev/null)
  fi

  # ongoing operations
  local gd
  gd=$(git rev-parse --git-dir 2>/dev/null) || return 0
  if   [[ -f "$gd/MERGE_HEAD" ]]; then op="MERGE"
  elif [[ -d "$gd/rebase-merge" || -d "$gd/rebase-apply" ]]; then op="REBASE"
  elif [[ -f "$gd/CHERRY_PICK_HEAD" ]]; then op="CHERRY-PICK"
  elif [[ -f "$gd/REVERT_HEAD" ]]; then op="REVERT"
  elif [[ -f "$gd/BISECT_LOG" ]]; then op="BISECT"
  fi

  local seg="${C_GIT}⎇ ${branch}${C_RESET}"
  ((ahead>0))     && seg+=" ${C_AHEAD}⇡${ahead}${C_RESET}"
  ((behind>0))    && seg+=" ${C_BEHIND}⇣${behind}${C_RESET}"
  ((staged>0))    && seg+=" ${C_STAGED}✚${staged}${C_RESET}"
  ((unstaged>0))  && seg+=" ${C_UNSTAGED}•${unstaged}${C_RESET}"
  ((untracked>0)) && seg+=" ${C_UNTRACKED}?${untracked}${C_RESET}"
  ((conflicts>0)) && seg+=" ${C_CONFLICT}✖${conflicts}${C_RESET}"
  [[ -n $op ]]    && seg+=" ${C_OP}| ${op}${C_RESET}"
  printf "%s" "$seg"
}

prompt_update() {
  local st=$?
  local exitseg=""
  ((st!=0)) && exitseg=" ${C_ERR}↩ ${st}${C_RESET}"
  PS1="\ndev-env ${C_RESET}${C_PATH}\w${C_RESET} $(git_info)${exitseg}\n${C_PROMPT}➜ ${C_RESET}"
}

# Écrire l'historique à chaque commande et recharger les nouvelles lignes,
# puis mettre à jour le prompt Git.
PROMPT_COMMAND=prompt_update

# History
export HISTFILE=/root/bash_history/.bash_history
export HISTSIZE=50000
export HISTFILESIZE=100000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
set -o history
