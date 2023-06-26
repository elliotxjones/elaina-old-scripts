#! /bin/bash

# Problem 3
#
# The prime factors of 13195 are 5, 7, 13, and 29.
# What is the largest prime factor of the number 
# 600851475143.

factor_down() {
    declare -i n=$1
    for i in $(seq 1 $n);
    do
        echo $i
        if [ $(($n%$i)) -eq 0 ] && \
            ! [ $n -eq 1 ]; then
            n=$(($n/$i))
            echo $n
            return 0
        fi
    done
}

main() {
    declare -i n=600851475143
    declare -i next_num=0
    while ! [ $n -eq $next_num ]; 
    do
        next_num=$(factor_down $n)
        echo $next_num
    done
    echo $new_num
}

main
