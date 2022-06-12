#!/bin/sh                                                                                                                                                                                    

zenity --info --text="downloading update, this while take some time"

curl -o updated-sukeban.tar.gz -LJ https://github.com/cosmo-ray/Sukeban/releases/download/latest/sukeban_I_use_Arch_BTW.tar.gz
if [ $? -ne 0 ]; then
    zenity --info --text="curl fail, so did the update"
    exit 1
fi

zenity --question --text="updated-sukeban.tar.gz have been download.\nDo you want to have automatic update ?"
if [ $? -eq 0 ]; then
    tar -xvf updated-sukeban.tar.gz
    zenity --question --text="do you want to bakup old files ?"
    if [ $? -eq 0 ]; then
        mkdir bakup-$(date +%d%m%y-%H%M%S)/
        rsync -r --exclude bakup* *  bakup-$(date +%d%m%y-%H%M%S)/
        zenity --info --text="baakkup done in ${PWD}/bakup-$(date +%d%m%y-%H%M%S)/"
    fi
    tar -xvf updated-sukeban.tar.gz
    cp -rf sukeban_I_use_Arch_BTW/* .
    rm -rf sukeban_I_use_Arch_BTW
    rm -v updated-sukeban.tar.gz
fi
