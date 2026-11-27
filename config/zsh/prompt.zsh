# The prompt: what Powerlevel10k's "pure" style showed (p10k has very limited support now), with no plugin.
#
#   ~/.dotfiles/config main* ⇡                                        12s venv user@host
#
#   left    the directory (blue), then Git: the branch, or @ and the commit when detached (grey), * for any
#           change, untracked files included, and ⇣⇡ when behind/ahead of the upstream (cyan). During a
#           merge, rebase... the action replaces * and the arrows, in red (as p10k showed it: "|rebase-i1/3")
#   right   the last command's duration when it took 5s or more (yellow), the Python virtualenv (grey), and
#           user@host when root or over SSH (grey; the user white when root)
#
# There's no prompt symbol, and once a command is entered its prompt shrinks to the command alone (p10k's
# transient prompt). Colours are the terminal's 16, which kitty sets from the theme, so a theme switch
# recolours it with nothing to reload here.
#
# Git status runs in the background (zle -F): the prompt shows at once, and the Git part arrives a moment
# later. Within the same repository the last status stays meanwhile, so it doesn't flicker.

zmodload zsh/datetime # EPOCHREALTIME
autoload -Uz add-zsh-hook add-zle-hook-widget
setopt prompt_subst

export VIRTUAL_ENV_DISABLE_PROMPT=1 # the virtualenv is on the right: activate mustn't add "(venv) " to PROMPT

typeset -g _prompt_git=""      # the Git part, ready to print
typeset -g _prompt_git_root="" # the work tree it's for
typeset -gi _prompt_git_fd=0   # the background status being waited for, if any
typeset -g _prompt_right=""
typeset -g _prompt_start=""    # when the running command started
typeset -gi _prompt_shrunk=0   # whether the prompt is the shrunk one (see _prompt_transient)

_prompt_left='%F{4}%~%f${_prompt_git:+ $_prompt_git} '

# the Git part for the work tree in $1, as one line (run in the background)
_prompt_git_status() {
    emulate -L zsh
    cd -q -- "$1" 2>/dev/null || return

    local out
    out=$(GIT_OPTIONAL_LOCKS=0 command git status --porcelain=v2 --branch 2>/dev/null) || return

    local line head oid dirty=""
    local -i ahead=0 behind=0
    for line in "${(@f)out}"; do
        case $line in
            ('# branch.oid '*)  oid=${line#\# branch.oid } ;;
            ('# branch.head '*) head=${line#\# branch.head } ;;
            ('# branch.ab '*)   line=${line#\# branch.ab }; ahead=${${line%% *}#+}; behind=${${line##* }#-} ;;
            ('#'*) ;;
            (?*) dirty='*' ;;
        esac
    done
    [[ $head == '(detached)' ]] && head="@${oid[1,8]}"

    # what Git is in the middle of, named and ordered as p10k's gitstatus (libgit2) does
    local g=.git action="" next="" last=""
    [[ -f $g ]] && { g=$(<$g); g=${g#gitdir: } }
    if [[ -d $g/rebase-merge ]]; then
        [[ -e $g/rebase-merge/interactive ]] && action=rebase-i || action=rebase-m
        next=$(<$g/rebase-merge/msgnum) last=$(<$g/rebase-merge/end)
    elif [[ -d $g/rebase-apply ]]; then
        if [[ -e $g/rebase-apply/rebasing ]]; then action=rebase
        elif [[ -e $g/rebase-apply/applying ]]; then action=am
        else action=am/rebase
        fi
        next=$(<$g/rebase-apply/next) last=$(<$g/rebase-apply/last)
    elif [[ -e $g/MERGE_HEAD ]]; then action=merge
    elif [[ -e $g/REVERT_HEAD ]]; then [[ -e $g/sequencer/todo ]] && action=revert-seq || action=revert
    elif [[ -e $g/CHERRY_PICK_HEAD ]]; then [[ -e $g/sequencer/todo ]] && action=cherry-seq || action=cherry
    elif [[ -e $g/BISECT_LOG ]]; then action=bisect
    fi 2>/dev/null

    local s="%F{8}${head//\%/%%}"
    if [[ -n $action ]]; then
        s+="%F{1}|$action"
        [[ -n $next && -n $last ]] && s+="$next/$last"
    else
        s+=$dirty
        local arrows=""
        (( behind )) && arrows+='⇣'
        (( ahead )) && arrows+='⇡'
        [[ -n $arrows ]] && s+="%F{6} $arrows"
    fi
    print -r -- "$s%f"
}

# the background status arrived (a zle -F handler, run as a widget so it can redraw)
_prompt_git_done() {
    local fd=$1 line=""
    IFS= read -r -u $fd line
    zle -F $fd
    exec {fd}<&-
    (( fd == _prompt_git_fd )) || return # an older one, overtaken
    _prompt_git_fd=0
    [[ $line == "$_prompt_git" ]] && return
    _prompt_git=$line
    zle reset-prompt
}
zle -N _prompt_git_done

_prompt_git_refresh() {
    # the work tree we're in: the nearest folder up with a .git (a folder, or a file for worktrees)
    local root=$PWD
    until [[ -e $root/.git || $root == / ]]; do root=${root:h}; done
    [[ -e $root/.git ]] || root=""

    if (( _prompt_git_fd )); then
        zle -F $_prompt_git_fd
        exec {_prompt_git_fd}<&-
        _prompt_git_fd=0
    fi
    [[ $root == "$_prompt_git_root" ]] || _prompt_git="" # another repository: don't show the last one's
    _prompt_git_root=$root
    [[ -n $root ]] || return

    exec {_prompt_git_fd}< <(_prompt_git_status "$root")
    zle -F -w $_prompt_git_fd _prompt_git_done
}

_prompt_preexec() {
    _prompt_start=$EPOCHREALTIME
}

_prompt_precmd() {
    local -a right

    # the last command's duration, as p10k showed it: 7s, 1m 5s, 2h 0m 3s, 1d 2h 0m 3s
    if [[ -n $_prompt_start ]]; then
        local -F took=$(( EPOCHREALTIME - _prompt_start ))
        _prompt_start=""
        if (( took >= 5 )); then
            local -i t=$(( took + 0.5 ))
            local text="$(( t % 60 ))s"
            (( t >= 60 )) && text="$(( t / 60 % 60 ))m $text"
            (( t >= 3600 )) && text="$(( t / 3600 % 24 ))h $text"
            (( t >= 86400 )) && text="$(( t / 86400 ))d $text"
            right+="%F{3}$text%f"
        fi
    fi

    # the virtualenv's name: its pyvenv.cfg prompt, or activate's, or its folder (the parent folder's for
    # a generic name like .venv)
    if [[ -n $VIRTUAL_ENV ]]; then
        local name=${VIRTUAL_ENV:t} cfg=""
        [[ -r $VIRTUAL_ENV/pyvenv.cfg ]] && cfg=$(<$VIRTUAL_ENV/pyvenv.cfg)
        local -a match mbegin mend
        if [[ $'\n'$cfg$'\n' == (#b)*$'\n'prompt[$' \t']#=([^$'\n']#)$'\n'* ]]; then
            name=${${match[1]##[$' \t']#}%%[$' \t']#}
            [[ $name == (\"*\"|\'*\') ]] && name=${name[2,-2]}
        elif [[ $VIRTUAL_ENV_PROMPT == '('?*') ' && $VIRTUAL_ENV_PROMPT != "($name) " ]]; then
            name=${VIRTUAL_ENV_PROMPT[2,-3]}
        elif [[ $name == (virtualenv|venv|.venv|env) ]]; then
            name=${VIRTUAL_ENV:h:t}
        fi
        right+="%F{8}${(V)name//\%/%%}%f"
    fi

    # user@host, only when root or over SSH
    if (( EUID == 0 )); then
        right+="%F{7}%n%f%F{8}@%m%f"
    elif [[ -n $SSH_CLIENT || -n $SSH_TTY || -n $SSH_CONNECTION ]]; then
        right+="%F{8}%n@%m%f"
    fi

    _prompt_right=${(j: :)right}
    _prompt_shrunk=0
    PROMPT=$_prompt_left
    RPROMPT='$_prompt_right'
    _prompt_git_refresh
}

# once a command is entered, its prompt shrinks to the command alone. What another hook put in front of it
# stays: kitty's precmd adds its prompt mark there, and runs after a ctrl+c when ours doesn't, so the
# state is a flag rather than PROMPT being exactly ' '
_prompt_transient() {
    (( _prompt_shrunk )) && return
    _prompt_shrunk=1
    PROMPT="${PROMPT%"$_prompt_left"} "
    RPROMPT=''
    zle reset-prompt
}

# ctrl+c at the prompt shrinks it too: no command runs, so precmd doesn't put the full prompt back for the
# next line, and _prompt_restore does
TRAPINT() {
    zle && _prompt_transient
    return $(( 128 + $1 ))
}
_prompt_restore() {
    (( _prompt_shrunk )) || return
    _prompt_shrunk=0
    PROMPT="${PROMPT% }$_prompt_left"
    RPROMPT='$_prompt_right'
    zle reset-prompt
}

add-zsh-hook preexec _prompt_preexec
add-zsh-hook precmd _prompt_precmd
add-zle-hook-widget line-finish _prompt_transient
add-zle-hook-widget line-init _prompt_restore
