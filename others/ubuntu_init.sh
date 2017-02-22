#!/bin/bash

# sudoers
sudo update-alternatives --set editor /usr/bin/vim.basic
sudo sed -i 's/\(%sudo.\+\)ALL/\1NOPASSWD:ALL/' /etc/sudoers

# configs
sudo systemctl disable apt-daily.timer  # disable apt background update

# install tools
#sudo apt install -y tree tmux cifs-utils

# [reboot]
# disable console screensaver
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 consoleblank=0"/' /etc/default/grub
sudo update-grub
sudo reboot
