#!/bin/bash

set -x

if [ -z $1 -o -z $2 ]; then
  echo "need iso file and preseedfile"
  exit
fi

preseed=$(readlink -e $2)
target=$(readlink -e $1)

mkdir isomnt
sudo mount -o loop $target isomnt
sudo rm -rf extract-cd
mkdir extract-cd
sudo rsync -a isomnt/ extract-cd
sudo umount isomnt

# boot language
sudo chmod +w extract-cd/isolinux/isolinux.cfg
sudo sed -i -e 's/timeout 0/timeout 1/' extract-cd/isolinux/isolinux.cfg

# preseed file
cp -v extract-cd/install/initrd.gz ./
cp -v $preseed ./preseed.cfg
gunzip initrd.gz
chmod +w initrd
echo "preseed.cfg" | cpio -o -H newc -A -F initrd
gzip initrd
sudo cp -vf initrd.gz extract-cd/install/

# make auto-iso image (in same folder of original iso)
cd extract-cd
target_fullname="$(basename "$target")"
target_path="$(dirname "$target")"
target_name="${target_fullname%.*}"
rm -f "$target_path/$target_name-auto.iso"
sudo mkisofs -D -r -V "ubuntu_auto" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o "$target_path/$target_name-auto.iso" .
