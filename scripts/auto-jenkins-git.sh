#! /bin/bash
#
# Automated Jenkinsfile git workflow script created to simplify the 
# chore of changing node labels and namespace everytime a new Jenkins  
# pipeline is to be run.

# This line needs to be first to get the correct execution path of 
# this script. This is needed for dynamically setting the
# config and data file directories when run as an alias.
declare -g script_path=$_;

# TIP: {{{ and }}} are vim folds. If you aren't using vim, you're 
# missing out ;)
# file_defines {{{
declare -gA file_defines;
file_defines=(\
    ["system-workload"]="jenkinsfile" \
);
# }}}
# system_list {{{
declare -g system_list=(\
    "system" \
);
# }}}
# workload_list {{{
declare -g workload_list=(\
        "workload" \
);
# }}}

# Basic checks to verify config file integrity before load.
# Also an excuse for abusing bash one-liners :D
test_config_file() {
    [ -f $config_file ] || return 1
    ! [[ $(grep ^"repo_root" $config_file) == "" ]] || return 1
    ! [[ $(grep ^"jenkins_file_dir" $config_file) == "" ]] || return 1
    ! [[ $(grep ^"git_branch" $config_file) == "" ]] || return 1
    return 0
}

# Creates template config.conf with default values.
make_config_file() {
    printf \
        "# Path to repository root (edit if different)"`
        `"\nrepo_root="`
        `"\n# Path from repository root to Jenkinsfiles (this should be the same)"`
        `"\njenkins_file_dir="`
        `"\n# Name of git branch to update"`
        `"\n# 1. ASSUMES YOUR FORK IS NAMED 'origin'"`
        `"\n# 2. ASSUMES BRANCH EXISTS"`
        `"\ngit_branch=your-branch-name" \
        > $config_file;
}

# Loads config.conf. Creates template if none exists.
load_config_file() {
    test_config_file;
    if [[ $? == 0 ]]; then
        source $config_file;
    else
        printf "Config file missing or invalid!\n";
        make_config_file;
        printf "\nCreated template $config_file\n"`
            `"Edit before re-running script!\n"`
            `"Run script with '-s' option for setup help\n";
        exit 1
    fi
    # Dumb fix if missing trailing "/" in config file which could 
    # break concatenated path strings. 
    if [[ $(echo $repo_root | grep -o "/"$) == "" ]]; then
        declare -g repo_root+="/";
    fi
    if [[ $(echo $jenkins_file_dir | grep -o "/"$) == "" ]]; then
        declare -g jenkins_file_dir+="/";
    fi
}

# Loads custom system-workload and jenkinsfile definitions from data 
# file. We do this to allow for flexible way of adding system 
# variatiants (i.e. type foo or type bar) per user for distinction in 
# Jenkins to avoid pipeline collisions if attempting multiple tests 
# with the same generic jenkinsfile.
load_data_file() {
    declare -g custom_system_list=();
    declare -gA custom_defines=();
    touch $data_file;
    ! [ -f $data_file ] || source $data_file;
    system_list+=(${custom_system_list[*]});
    for i in "${!custom_defines[@]}";
    do
        file_defines[${i}]=${custom_defines[${i}]};
    done
}

# Checks user set configs to catch dumb mistakes we can't fix with code.
test_setup() {
    if ! [ -d $repo_root ]; then
        printf "[test]\t$config_file: no such directory for 'repo_root'\n";
        declare is_valid_setup=false;
    elif ! [ -d ${repo_root}${jenkins_file_dir} ]; then
        printf "[test]\t$config_file: no such directory for "`
            `"'jenkins_file_dir'\n";
        declare is_valid_setup=false;
    fi
    if [ -d ${repo_root} ]; then
        [[ $PWD == $repo_root ]] || cd $repo_root;
        if ! [ -d .git/ ]; then
            printf "[test]\t$config_file: 'repo_root' not a git repository\n";
            declare is_valid_setup=false;
        elif [[ $(git branch | grep -w $git_branch) == "" ]]; then
            printf "[test]\t$config_file: no such git branch $git_branch\n";
            declare is_valid_setup=false;
        elif ! [[ $(git remote -v | grep -w origin | \
            grep -w git@github.com:intel-innersource) == "" ]]; then
            printf "[test]\tgit remote: 'origin' set to track "`
                `"redacted\n"`
                `"      \t'origin' needs to track your fork\n"`
                `"      \tuse 'git clone' with your fork url\n";
            declare is_valid_setup=false;
        elif [ -d ${repo_root}${jenkins_file_dir} ]; then
            git stash &> /dev/null;
            git checkout $git_branch &> /dev/null;
            for i in ${!file_defines[@]};
            do
                declare jenkins_file="${repo_root}${jenkins_file_dir}"`
                    `"${file_defines[${i}]}";
                if ! [ -f $jenkins_file ]; then
                    printf "[test]\t${file_defines[${i}]}: no such file\n"`
                        `"      \tmake sure branch '$git_branch' "`
                        `"is up-to-date with 'upstream/main'\n";
                    declare is_valid_setup=false;
                fi
            done     
        fi
        cd $working_dir;
    fi
    if [[ $(grep -w email ~/.gitconfig) == "" ]] || \
        [[ $(grep -w name ~/.gitconfig) == "" ]]; then
        printf "[test]\t~/.gitconfig: missing user info for git\n"`
            `"      \trefer to the following commands for setting user info\n"`
            `"      \t\tgit config --global user.name \"Your Name\"\n"`
            `"      \t\tgit config --global user.email "`
            `"\"youremail@yourdomain.com\"\n";
        declare is_valid_setup=false;
    fi

    $is_valid_setup || return 1
    return 0
}

# Configures gitconfig proxies.
config_gitconfig() {
    declare f=~/.gitconfig;
    [ -f $f ] || touch $f;
    if [[ $(grep github.com $f) == "" ]]; then
        printf "[http \"https://github.com\"]"`
            `"\n    proxy = proxy:port\n" >> $f;
    fi
}

# Add KUBECONFIG file to ~/.bashrc if this is the cluster system.
config_bashrc() {
    declare f=~/.bashrc;
    declare kube_config_file=~/kube/config;
    [ -f $f ] || touch $f;
    
    export KUBECONFIG;
    # Overwrite default if already set.
    # Existing value takes priority.
    if ! [[ $(echo $KUBECONFIG) == "" ]]; then
        declare kube_config_file=$KUBECONFIG;
    fi

    if [[ $(grep KUBECONFIG $f) == "" ]] \
        && [ -f $kube_config_file ]; then
        printf "\nexport KUBECONFIG=${kube_config_file}" >> $f
    else
        unset KUBECONFIG;
    fi
}

# Setup steps to walk user through adding an ssh key to their github 
# account.
ssh_setup_helper() {
    declare ssh_key=$1;
    clear
    printf "\nVisit https://github.com/settings/keys to add your ssh key to "`
        `"Github\nThis step MUST be completed to authenticate over ssh"`
        `"\n[Enter] to continue\n";
    read cont;
    clear
    printf "Click the green \"New SSH key\" button"`
        `"\nTitle can be anything."`
        `"\nKey type should be \"Authentication Key\""`
        `"\nThe Key field will be your ssh public key"`
        `"\n[Enter] to continue\n";
    read cont;
    clear
    printf "You can copy the contents your key using the cat command"`
        `"\nExample: cat $(\
            if [ -f /home/$(whoami)/.ssh/${ssh_key}.pub ] && \
                ! [[ $(echo $ssh_key) == "" ]]; then
                printf "/home/$(whoami)/.ssh/${ssh_key}.pub"`
                    `"\nIf this is the key you intend to use you can copy it "`
                    `"below\n\n$(cat /home/$(whoami)/.ssh/${ssh_key}.pub)";
            else
                printf "/home/$(whoami)/.ssh/YourSSHKey.pub";
            fi
        )\n"`
        `"\n[Enter] to continue\n";
    read cont;
    clear
    printf "After you've added your ssh key you will need to configure it "`
        `"for SSO\nClick the \"Configure SSO\" button next to your key"`
        `"\nYou will see a dropdown menu of single sign-on organizations"`
        `"\nClick the \"Authorize\" button next to each organization"`
        `"\nSSH should now be configured!\n"
}

# Configures ~/.ssh/config for github.
config_ssh() {
    declare f=~/.ssh/config;
    [ -d ~/.ssh ] || mkdir ~/.ssh;
    [ -f $f ] || touch $f;
    cd ~/.ssh/;
    chmod 600 $f;
    if [[ $(grep "Host github.com" $f) == "" ]]; then
        printf "Missing ssh key for github\n"`
            `"For ease of use leave passphrase empty at the prompts\n\n";
        ssh-keygen -t rsa -V -1m:forever;
        declare new_list=($(ls -c));
        declare ssh_key=${new_list[0]};
        printf "Host github.com"`
            `"\n    HostName ssh.github.com"`
            `"\n    ProxyCommand nc -X connect -x proxy-dmz.intel.com:912 "`
            `"%%h %%p\n    IdentityFile ~/.ssh/${ssh_key}" >> $f;
        printf "Read ssh key setup instructions?\n";
        declare -l opt;
        read -p "(Y/n)? " opt;
        if ! [[ $opt == "n" ]]; then
            ssh_setup_helper $ssh_key;
        fi
        printf "\nTesting your ssh connection"`
            `"\n[Enter] to continue\n";
        read cont;
        ssh -T git@github.com;
    fi
}

# Configures environment as much as we can, otherwise runs tests 
# against user setup to catch dumb mistakes and provide pointers for 
# improper setup we can't fix with code.
try_initial_setup() {
    config_gitconfig;
    config_bashrc;
    config_ssh;
    test_setup;
    if [[ $? == 1 ]]; then
        exit 1
    fi
}

# Updates local git branch to avoid conflicts.
update_git_worktree() {
    if ! [[ $PWD == "${repo_root}${jenkins_file_dir}" ]]; then
        cd ${repo_root}${jenkins_file_dir};
    fi
        
    # Stash any changed (uncommon) so we can safely change branches.
    git stash &> /dev/null;
    git checkout $git_branch &> /dev/null;
    git fetch origin $git_branch &> /dev/null;
    git merge --ff-only origin/$git_branch &> /dev/null;
    cd $working_dir;
}

# Writes custom system-workload and jenkinsfile definitions to data 
# file. We do this to allow for flexible way of adding system 
# variatiants (i.e. icx acc vs icx gp) per user for distinction in 
# Jenkins to avoid pipeline colisions if attempting multiple tests 
# with the same generic jenkinsfile.
write_data_file() {
    echo "# DO NOT EDIT! File automatically generated by script" \
        > $data_file;
    echo "custom_system_list=(\\" >> $data_file;
    for i in ${custom_system_list[*]};
    do
        printf "\t\"$i\" \\" >> $data_file;
        printf "\n" >> $data_file;
    done
    echo ")" >> $data_file;

    echo "custom_defines=(\\" >> $data_file;
    for i in "${!custom_defines[@]}";
    do
        printf "\t[${i}]=${custom_defines[${i}]} \\" >> $data_file;
        printf "\n" >> $data_file;
    done
    echo ")" >> $data_file;
}

# Copies jenkinsfiles for each workload for a user selected 
# system type. Adds custom system-workload and jenkinsfile 
# definitions to data file to dynamically populate selection menus.
# Commits and pushes new files to git.
clone_jenkins_file() {
    select_system_string;
    # Load data file after string selection so selection menu is not 
    # populated with custom options. That way we are only using the 
    # origin (stable) jenkinsfiles as templates.
    load_data_file;
    declare new_file_list=();
    declare -A cp_defines;

    # Allow up to 3 retries since this is far enough along in the 
    # process that exiting would be annoying for users to do over.
    declare -i rename_retries=0;
    while true;
    do
        printf "\nEnter system name to CLONE as\n";
        printf "Selected: $system_string\n";
        read -p "CLONE: " opt;
        if [ $rename_retries -gt 1 ]; then
            echo "Max retries reached";
            echo "exiting...";
            exit 1
        elif ! [ $opt ]; then
            echo "System name cannot be blank - try again";
            rename_retries+=1;
        elif ! [ $(echo ${system_list[*]} | grep -oP $opt) ]; then
            break
        elif [ $(echo ${system_list[*]} | grep -oP $opt) ]; then
            echo "System name already exists - try again";
            rename_retries+=1;
        else
            # Stupid catch-all
            echo "Invalid system name - try again";
            rename_retries+=1;
        fi
    done


    declare custom_system=$opt;
    custom_system_list+=(${custom_system});
    for i in ${workload_list[*]};
    do
        declare system_workload_key="${system_string}-${i}";
        declare define_value=${file_defines[$system_workload_key]};
        declare jenkins_file=${repo_root}${jenkins_file_dir}${define_value};
        declare new_file=Jenkinsfile.cluster-${i}-${custom_system}-CUSTOM;
        new_file_list+=($new_file);
        cp_defines[${jenkins_file}]=${repo_root}${jenkins_file_dir}${new_file};
        custom_defines[${custom_system}-$i]=$new_file;
    done

    for i in ${!cp_defines[@]};
    do
        cp $i ${cp_defines[${i}]};
        # Overwrite global jenkins_file "selection" so the new files 
        # are within the scope of the update functions.
        declare overwrite_global="jenkins_file=${cp_defines[${i}]}";
        eval $overwrite_global;
        update_name_space "CUSTOMIZE THIS";
        update_node_label "CUSTOMIZE THIS";
    done

    write_data_file;
    update_git_worktree;
    if ! [[ $PWD == "${repo_root}${jenkins_file_dir}" ]]; then
        cd ${repo_root}${jenkins_file_dir};
    fi
    git add --all;
    git commit -F <(printf \
        "feat: Automated add of custom Jenkinsfiles\n"`
        `"\nAdds copied jenkinsfiles using existing file as a template.\n"`
        `"\n$(\
            for i in ${new_file_list[*]};
            do
                printf "new file:   $i\n";
            done
        )") &> /dev/null;
    git push origin $git_branch &> /dev/null;
    printf "\nNew files pushed to remote 'origin/$git_branch':"`
        `"\n$(\
            for i in ${new_file_list[*]};
            do
                printf "   $i\n";
            done
        )\n"

    cd $working_dir;
}

# Removes jenkinsfiles for each workload for a user selected 
# system type. Removes custom system-workload and jenkinsfile 
# definitions from data file.
# Commits and pushes new files to git.
remove_jenkins_file() {
    load_data_file;
    # Overwrite global with custom system list since we 
    # only want custom systems as options to remove.
    declare overwrite_global="system_list=(\
        $(echo ${custom_system_list[*]}))";
    eval $overwrite_global;
    
    if [[ ${system_list[*]} == "" ]]; then
        printf "No custom files saved\n";
        exit 0
    fi

    select_system_string;
    declare rm_file_list=();
    declare -A rm_defines=();
    
    for i in ${workload_list[*]};
    do
        declare system_workload_key="${system_string}-${i}";
        declare define_value=${custom_defines[$system_workload_key]};
        declare jenkins_file=${repo_root}${jenkins_file_dir}${define_value};
        rm_file_list+=($define_value);
        rm_defines[${system_workload_key}]=$jenkins_file;
    done
    
    printf "\nThe following files will be removed:"`
        `"\n$(\
            for i in ${rm_file_list[*]};
            do
                printf "   $i\n";
            done
        )\n";

    read -p "Type '$system_string' to confirm: " confirm_string;

    if ! [[ $confirm_string == $system_string ]]; then
        printf "exiting...\n";
        exit 0
    fi
    
    update_git_worktree;
    for i in ${!custom_system_list[*]};
    do
        if [[ ${custom_system_list[${i}]} == $system_string ]]; then
            unset custom_system_list[${i}];
            break
        fi
    done

    # This probably could be done better for removing an array item.
    for i in ${!rm_defines[@]};
    do
        unset custom_defines[${i}];
        ! [ -f ${rm_defines[${i}]} ] || rm ${rm_defines[${i}]};
    done

    write_data_file;
    if ! [[ $PWD == "${repo_root}${jenkins_file_dir}" ]]; then
        cd ${repo_root}${jenkins_file_dir};
    fi
    
    git add --all;
    git commit -F <(printf \
        "refactor: Automated removal of custom Jenkinsfiles\n"`
        `"\nRemoves custom jenkinsfiles previously copied from existing files.\n"`
        `"\n$(\
            for i in ${rm_file_list[*]};
            do
                printf "deleted:   $i\n";
            done
        )") &> /dev/null;
    git push origin $git_branch &> /dev/null;
    printf "\nFiles deleted from remote 'origin/$git_branch'\n"

    cd $working_dir;
}

# Prompts user with advanced menu options.
advanced_menu() {
    declare modify_options=(\
        "copy from existing" \
        "remove" \
    );

    printf "Select an operation from the list\n";
    for i in ${!modify_options[@]};
    do
        printf "[$i]\t${modify_options[${i}]}\n";
    done;
    read -p "(Enter a number 0-$((${#modify_options[@]}-1))): " opt;
    
    if [[ ${modify_options[${opt}]} == "" ]]; then
        echo "Invalid selection!";
        echo "exiting...";
        exit 1
    fi
    
    case ${modify_options[${opt}]} in
        "copy from existing")
            clone_jenkins_file;
            exit 0
            ;;
        "remove")
            remove_jenkins_file;
            exit 0
            ;;
    esac
}

# Parse args for advanced functionality.
parse_args() {
    case $1 in
        "-h")
            printf "Usage:"`
                `"\n-h\tprint this help and exit"`
                `"\n-t\ttest setup"`
                `"\n-m\tmodify custom jenkinsfiles"`
                `"\n";
            exit 0
            ;;
        "-t")
            load_config_file;
            try_initial_setup;
            # Initial setup will exit on setup fail so this only 
            # runs if it works.
            echo "setup ok :)"
            exit 0
            ;;
        "-m")
            load_config_file;
            try_initial_setup;
            advanced_menu;
            exit 0
            ;;
    esac
}

# Gets user selected system string from system list.
select_system_string() {
    printf "Select a system from the list\n";
    for i in ${!system_list[@]};
    do
        printf "[$i]\t${system_list[${i}]}\n";
    done;
    read -p "(Enter a number 0-$((${#system_list[@]}-1))): " opt;
    
    if [[ ${system_list[${opt}]} == "" ]] || ! [ $opt ]; then
        echo "Invalid selection!";
        echo "exiting...";
        exit 1
    fi

    declare -g system_string=${system_list[${opt}]};
}

# Gets user selected workload string from workload list.
select_workload_string() {
    printf "Select a workload from the list\n";
    for i in ${!workload_list[@]};
    do
        printf "[$i]\t${workload_list[${i}]}\n";
    done
    read -p "(Enter a number 0-$((${#workload_list[@]}-1))): " opt;
    
    if [[ ${workload_list[${opt}]} == "" ]] || ! [ $opt ]; then
        echo "Invalid selection!";
        echo "exiting...";
        exit 1
    fi
    
    declare -g workload_string=${workload_list[${opt}]};
}

# Defines corresponding Jenkinsfiles for each system-workload string.
define_jenkins_file() {
    select_system_string;
    select_workload_string;
    declare system_workload_key="${system_string}-${workload_string}";
    declare define_value=${file_defines[$system_workload_key]};
    declare -g jenkins_file=${repo_root}${jenkins_file_dir}${define_value};
}

# Updates NS variable in Jenkinsfile with user provided value.
update_name_space() {
    cp $jenkins_file $jenkins_file.tmp;
    cat $jenkins_file.tmp | sed -e "s/NS=.*$/NS=\"${1}\"/g" \
        > $jenkins_file;
    rm -f $jenkins_file.tmp;
}

# Updates JENKINS_NODE_LABEL variable in Jenkinsfile with user provided  
# value.
update_node_label() {
    cp $jenkins_file $jenkins_file.tmp;
    cat $jenkins_file.tmp | sed \
        -e "s/JENKINS_NODE_LABEL=.*$/JENKINS_NODE_LABEL=\"${1}\"/g" \
        > $jenkins_file;
    rm -f $jenkins_file.tmp;
}

# Updates Jenkinsfile node label and namespace for corresponding  
# system-workload string.
update_jenkins_file() {
    define_jenkins_file;

    #TODO: Deprecate/refactor. Will only catch custom files so this 
    #   needs to reflect that.
    if ! [ -f $jenkins_file ]; then
        declare modified_file=$(echo $jenkins_file | grep -o '[^/]\+$')
        printf "No such file: ${modified_file}"`
            `"\nMake sure branch '${git_branch}' is "`
            `"up-to-date with upstream/main "`
            `"and any custom files exist.\n"`
            `"\nYou can re-copy or remove custom files by running "`
            `"\nthe script with the '-m' option.\n";
        exit 1
    fi

    # Name space input
    printf "\nEnter NEW namespace\n";
    printf "Old: $(cat $jenkins_file | \
        grep NS= | \
        grep -oP '"\K[^"\047]+(?=["\047])')\n";
    read -p "NEW (include full name using \"cdc\"): " name_space;
    if ! [ $name_space ]; then
        echo "namespace value cannot be blank";
        echo "exiting...";
        exit 1
    fi

    # Node label input.
    printf "\nEnter NEW node label\n";
    printf "Old: $(cat $jenkins_file | \
        grep JENKINS_NODE_LABEL= | \
        grep -oP '"\K[^"\047]+(?=["\047])')\n";
    read -p "NEW: " node_label;
    if ! [ $node_label ]; then
        echo "node label value cannot be blank";
        echo "exiting...";
        exit 1
    fi

    update_name_space $name_space;
    update_node_label $node_label;

    printf "\n";
}

# Commits changes to local branch.
git_commit() {
    if ! [[ $PWD == "${repo_root}${jenkins_file_dir}" ]]; then
        cd ${repo_root}${jenkins_file_dir};
    fi
    git add $jenkins_file;
    declare modified_file=$(echo $jenkins_file | grep -o '[^/]\+$')
    git commit -F <(printf \
        "chore: Automated update of Jenkinsfile namespace and node label\n"`
        `"\nSets namespace to $(cat $jenkins_file | \
            grep NS= | grep -oP '"\K[^"\047]+(?=["\047])')"`
        `"\nSets node label to $(cat $jenkins_file | \
            grep JENKINS_NODE_LABEL= | grep -oP '"\K[^"\047]+(?=["\047])')\n"`
        `"\nmodified:   ${modified_file}") &> /dev/null;
    git push origin $git_branch &> /dev/null;
    
    printf "Modified file pushed to remote 'origin/$git_branch':"`
        `"\n   $modified_file\n";
    cd $working_dir;
}

# Creates alias to run script from anywhere.
# Installing to ~/bin to run with alias is a hack to work around limited  
# permissions on execution server.
add_alias() {
    declare alias_name=auto-jenkins;
    declare alias_dir=~/bin/${alias_name};
    declare alias_path=${alias_dir}/${alias_name}.sh;
    declare -l opt="n";

    touch ~/.bash_aliases;
    if [[ $(grep ^"alias auto-jenkins" ~/.bash_aliases) == "" ]]; then
        printf "Save script as alias?\nOnce aliased, "`
            `"you can call this script from anywhere\n";
        read -p "(y/N): " opt;
    fi
    
    if [[ $opt == "y" ]]; then
        [ -d $alias_dir ] || mkdir -p $alias_dir;
        
        cp $script_path $alias_path;
        cp $config_file $alias_dir;
        cp $data_file $alias_dir;
        chmod +x "$alias_path";

        echo "alias $alias_name=\"${alias_path}\"" \
            >> ~/.bash_aliases;
        printf "\nAlias added!\nEnter '$alias_name' from anywhere to use\n";
        source ~/.bash_aliases; exec bash;
    fi
}

main() {
    declare -g config_file=$(echo $script_path | grep -oP "/*.+/")config.conf;
    declare -g data_file=$(echo $script_path | grep -oP "/*.+/")data.dat;
    declare -g working_dir=$PWD;

    parse_args $1;
    load_config_file;
    try_initial_setup;
    load_data_file;
    update_git_worktree;
    update_jenkins_file;
    git_commit;
    add_alias;
}

main $1

