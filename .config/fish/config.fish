# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # Run fastfetch only if not in VSCode, Nvim, or Antigravity
    function run_fastfetch
        # Kiểm tra nếu không phải vscode hay nvim
        if test "$TERM_PROGRAM" != vscode; and not set -q NVIM; and not set -q VSCODE_PID
            ~/.config/fastfetch/fastfetch-random-char.sh
        end
    end

    run_fastfetch

    # Colors - apply AFTER fastfetch to not clear the image
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != linux
        starship init fish | source
        enable_transience
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    function clear
        printf '\033[2J\033[3J\033[1;1H'
        run_fastfetch --force
    end
    function reset
        command reset
        printf '\033[2J\033[3J\033[1;1H'
        run_fastfetch --force
    end
    alias celar clear
    alias claer clear
    alias ckear clear
    alias cl clear
    alias cleả clear
    alias claẻ clear
    alias clẻa clear
    alias clảe clear
    alias a antigravity
    alias pamcan pacman
    alias q 'qs -c ii'
    alias ba 'env INIR_CMD=ba ~/.config/quickshell/ii/scripts/ba'
    alias stfu 'shutdown now'
    function n
        if test (count $argv) -eq 0
            nvim .
            return
        end

        set file $argv[1]

        if string match -qr '^(/etc|/usr|/bin|/sbin|/boot|/root)' -- $file
            sudoedit $argv
            return
        end

        nvim $argv
    end

    #    alias n 'sudo -E nvim'
    if test "$TERM" != linux
        alias ls 'eza --icons'
    end
    if test "$TERM" = xterm-kitty
        alias ssh 'kitten ssh'
    end
end

set -Ux SAL_USE_VCLPLUGIN gtk3
set -Ux SAL_USE_VCLPLUGIN qt6

set -Ux PYENV_ROOT $HOME/.pyenv
set -Ux PATH $PYENV_ROOT/bin $PATH
# status --is-interactive; and pyenv init - | source

set -x PATH /opt/cuda/bin $PATH
set -x LD_LIBRARY_PATH /opt/cuda/lib64 $LD_LIBRARY_PATH

if status is-login
    # set -Ux GTK_IM_MODULE fcitx
    set -Ux QT_IM_MODULE fcitx
    set -Ux XMODIFIERS @im=fcitx
    set -Ux SDL_IM_MODULE fcitx
    set -Ux GLFW_IM_MODULE ibus

    # NVIDIA Wayland & Aquamarine workarounds
    set -Ux AQ_MGPU_NO_EXPLICIT 1
    set -Ux AQ_NO_MODIFIERS 1
    set -Ux GBM_BACKEND nvidia-drm
    set -Ux __GLX_VENDOR_LIBRARY_NAME nvidia
    set -Ux LIBVA_DRIVER_NAME nvidia
    set -Ux WLR_NO_HARDWARE_CURSORS 1
end

# opencode
fish_add_path /home/rhythmgc/.opencode/bin

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# uv
fish_add_path "/home/rhythmgc/.local/bin"

# Pi
fish_add_path "/home/rhythmgc/.local/share/fnm/node-versions/v24.16.0/installation/bin"


# Added by Antigravity CLI installer
set -gx PATH "/home/rhythmgc/.local/bin" $PATH
if status is-login
    set -Ux GTK_IM_MODULE fcitx
    set -Ux QT_IM_MODULE fcitx
    set -Ux XMODIFIERS @im=fcitx
    set -Ux SDL_IM_MODULE fcitx
    set -Ux GLFW_IM_MODULE ibus
end
