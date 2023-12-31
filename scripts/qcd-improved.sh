#! /bin/bash

# This line needs to be first for it to get the correct execution  
# path of this script. This is used to dynamically set the data file 
# path for improved portability by avoiding hardcoded paths. This 
# allows the script to be stored anywhere. Users are advised to use 
# a sepatare directory to avoid file collisions with any other 
# existing data.dat files.
declare -g script_path=$_;

# Sources cd_shortcuts
load_data_file() {
    declare -gA cd_shortcuts;

    if [ -f $data_file ]; then
        source $data_file;
    else
        cd_shortcuts=();
    fi
}

# Writes cd_shortcuts to data file
write_data_file() {
    echo "# DO NOT EDIT! File generated by script" > $data_file;
    echo "cd_shortcuts=(\\" >> $data_file;
    for i in "${!cd_shortcuts[@]}";
    do
        printf "\t[\"${i}\"]=\"${cd_shortcuts[${i}]}\" \\" >> $data_file;
        printf "\n" >> $data_file;
    done
    echo ")" >> $data_file;
}

# Adds shortcut for current directory to cd_shortcuts
add_shortcut() {
    declare shortcut=$1

    # Don't overwrite existing shortcuts
    if [ "${cd_shortcuts["$shortcut"]}" == "" ]; then
        cd_shortcuts["$shortcut"]=$PWD;
        write_data_file;
    else
        echo "Shortcut already exists";
    fi
}

# Deletes shortcut in cd_shortcuts
delete_shortcut() {
    declare shortcut=$1
    
    if [ "${cd_shortcuts["$shortcut"]}" != "" ]; then
        unset cd_shortcuts["$shortcut"];
        write_data_file;
    else
        echo "No such shortcut";
    fi
}

# Parse switch args
parse_args() {
    declare args=($@);
    
    # Show help if missing second argument
    if [ ${#args[@]} -eq 1 ]; then
        args[0]="-h";
    fi
    
    case ${args[0]} in
        "-h")
            print_help;
            ;;
        "-a")
            add_shortcut ${args[1]};
            ;;
        "-d")
            delete_shortcut ${args[1]};
            ;;
    esac
}

# Print saved shortcuts
print_shortcuts() {
    if [ ${#cd_shortcuts[@]} -eq 0 ]; then
        echo "No saved directories";
    else
        for i in "${!cd_shortcuts[@]}"
        do
            printf "${i}\t${cd_shortcuts[${i}]}\n";
        done
    fi
}

# Print help
print_help() {
    printf "Usage: qcd [OPTION] SHORTCUT"`
        `"\nqcd - quickly cd using shortcuts."`
        `"\n\nOptions:"`
        `"\n  -h\tprint this help and exit"`
        `"\n  -a\tadd shortcut with current dir"`
        `"\n  -d\tdelete shortcut"`
        `"\n";
}


main() {
    declare args=($@);
    declare -g data_file=$(echo $script_path | grep -oP "/*.+/")data.dat; 

    # Loads cd_shortcuts
    load_data_file

    # No args
    if [ ${#args[@]} -eq 0 ]; then
        print_shortcuts;
    # Switch syntax
    elif [ $(echo ${args[0]} | grep ^"-") ]; then
        parse_args ${args[*]};
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

main $@
