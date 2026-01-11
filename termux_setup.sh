# direct setup for termux
# run using:
# sh -c "$(curl -fsSL http://192.168.1.x:3000/termux_setup.sh)"

echo "Starting setup..."

pkg update -y

pkg install git wget curl python zsh neovim ripgrep clang make cmake -y

# ssh setup
echo "Setting up SSH..."
pkg install -y openssh
pkg install -y busybox termux-services
source $PREFIX/etc/profile.d/start-services.sh
sv-enable ftpd
sv up ftpd

echo "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing powerlevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "Installing auto-completion plugin..."
git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete

echo "Installing auto-suggestions plugin..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo "Open ~/.zshrc, find the line that sets ZSH_THEME, and change its value to 'powerlevel10k/powerlevel10k'"

source ~/.zshrc 
