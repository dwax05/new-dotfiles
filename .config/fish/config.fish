
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /Users/dylanwax/miniconda3/bin/conda
    eval /Users/dylanwax/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/Users/dylanwax/miniconda3/etc/fish/conf.d/conda.fish"
        . "/Users/dylanwax/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/Users/dylanwax/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<


# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/dylanwax/.lmstudio/bin
# End of LM Studio CLI section

