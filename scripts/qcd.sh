#! /bin/bash

# This script is meant to be sourced as a bash alias.

quick_cd() {
    declare args=($@);
    declare data_file=~/bin/qcd/data.dat;
    mkdir -p ~/bin/qcd/;

    # Loads cd_shortcuts
    declare -A cd_shortcuts;
    if [ -f $data_file ]; then
        source $data_file;
    else
        cd_shortcuts=();
    fi

    # No args
    if [ ${#args[@]} -eq 0 ]; then
        if [ ${#cd_shortcuts[@]} -eq 0 ]; then
            echo "No saved directories";
        else
            for i in "${!cd_shortcuts[@]}"
            do
                printf "${i}\t${cd_shortcuts[${i}]}\n";
            done
        fi
    # Switch syntax
    elif [ $(echo ${args[0]} | grep ^"-") ]; then
        # Show help if missing second argument
        if [ ${#args[@]} -eq 1 ]; then
            args[0]="-h";
        fi
        
        case ${args[0]} in
            "-h")
                printf "Usage: qcd [OPTION] SHORTCUT"`
                    `"\nqcd - quickly cd using shortcuts."`
                    `"\n\nOptions:"`
                    `"\n  -h\tprint this help and exit"`
                    `"\n  -a\tadd shortcut for current dir"`
                    `"\n  -d\tdelete shortcut"`
                    `"\n";
                ;;
            "-a")
                declare shortcut=${args[1]}

                # Don't overwrite existing shortcuts
                if [ "${cd_shortcuts["$shortcut"]}" == "" ]; then
                    cd_shortcuts["$shortcut"]=$PWD;
                    echo "# DO NOT EDIT! File generated by script" \
                        > $data_file;
                    echo "cd_shortcuts=(\\" >> $data_file;
                    for i in "${!cd_shortcuts[@]}";
                    do
                        printf "\t[\"${i}\"]=\"${cd_shortcuts[${i}]}\" \\" \
                            >> $data_file;
                        printf "\n" >> $data_file;
                    done
                    echo ")" >> $data_file;
                    echo "Added $shortcut";
                else
                    echo "Shortcut already exists";
                fi
                ;;
            "-d")
                declare shortcut=${args[1]}
                
                if [ "${cd_shortcuts["$shortcut"]}" != "" ]; then
                    unset cd_shortcuts["$shortcut"];
                    echo "# DO NOT EDIT! File generated by script" \
                        > $data_file;
                    echo "cd_shortcuts=(\\" >> $data_file;
                    for i in "${!cd_shortcuts[@]}";
                    do
                        printf "\t[\"${i}\"]=\"${cd_shortcuts[${i}]}\" \\" \
                            >> $data_file;
                        printf "\n" >> $data_file;
                    done
                    echo ")" >> $data_file;
                    echo "Deleted $shortcut";
                else
                    echo "No such shortcut";
                fi
                ;;
        esac
    # Valid shortcut and dir (default)
    elif [[ "${cd_shortcuts["${args[0]}"]}" != "" ]] && \
        [ -d "${cd_shortcuts["${args[0]}"]}" ]; then
        cd "${cd_shortcuts["${args[0]}"]}";
    # Invalid shortcut
    elif [[ "${cd_shortcuts["${args[0]}"]}" == "" ]]; then
        echo "No such shortcut";
    # Invalid dir
    elif ! [ -d "${cd_shortcuts["${args[0]}"]}" ]; then
        echo "No such directory";
    # If you got this far, then you are highly talented
    else
        echo "Invalid option";
    fi
}

