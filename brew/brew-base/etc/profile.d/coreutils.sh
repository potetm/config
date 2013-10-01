COREUTILS_LIBEXEC="`brew --prefix`/opt/coreutils/libexec"

PATH="$COREUTILS_LIBEXEC"/gnubin:"$PATH"
MANPATH="$COREUTILS_LIBEXEC"/gnuman:"$MANPATH"

export PATH
export MANPATH
