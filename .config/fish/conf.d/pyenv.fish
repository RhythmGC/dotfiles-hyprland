status --is-interactive; or exit

set -gx PYENV_ROOT $HOME/.pyenv

if not contains $PYENV_ROOT/bin $PATH
    set -gx PATH $PYENV_ROOT/bin $PATH
end

if not contains $PYENV_ROOT/shims $PATH
    set -gx PATH $PYENV_ROOT/shims $PATH
end

function pyenv
    functions -e pyenv
    command pyenv init - fish --no-rehash | source
    pyenv $argv
end
