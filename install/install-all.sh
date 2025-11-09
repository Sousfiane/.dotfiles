cd "$(dirname "$0")/.."
export DOTFILES=$(pwd -P)

$DOTFILES/install/install-dotfiles.sh
$DOTFILES/install/install-yay.sh
$DOTFILES/install/install-packages.sh
$DOTFILES/install/install-theme.sh
