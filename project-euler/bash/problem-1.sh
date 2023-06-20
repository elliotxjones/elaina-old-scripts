#! /bin/bash

# Problem 1
#
# If we list all the natural numbers below 10 that are multiples of 3  
# or 5, we get 3, 5, 6 and 9. The sum of these multiples is 23.
#
# Find the sum of all the multiples of 3 or 5 below 1000.


declare -i m_sum=0

# The maximum theoretical multiplier is 1000.
# In reality, this should be 1000 divided by the smaller of 3 or 
# 5 but we won't need to be precise, only accurate since we are 
# breaking out sooner anyway.
for i in {1..1000};
do
    # If no more multiples under 1000 for either 3 or 5, break
    # out of the loop.
    if [ $(($i*3)) -gt 1000 ] && \
        [ $(($i*5)) -gt 1000 ]; then
        break
    fi
    # If multiple of 3 is less than 1000, add to sum.
    if [ $(($i*3)) -lt 1000 ]; then
        m_sum+=$(($i*3))
    fi
    # If multiple of 5 is less than 1000, and is not a multiple of 3,
    # add to sum. Checking that it's not a multiple of 3 avoids adding 
    # duplicate multiples.
    if [ $(($i*5)) -lt 1000 ] && \
        ! [ $(($i*5%3)) -eq 0 ]; then
        m_sum+=$(($i*5))
    fi
done

echo $m_sum
