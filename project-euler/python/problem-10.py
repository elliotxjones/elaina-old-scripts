# PROBLEM 10
#
# The sum of the primes below 10 is 2 + 3 + 5 + 7 = 17.
#
# Find the sum of all the primes below two million.
#
# Duration: 22.68 minutes
# Duration on server: 13.21 minutes

from time import time, sleep

primes = [2]

def update_test_set(test_set):
    '''Sorts prime numbers from a given list.
    
    Finds the first prime number in a given list and returns a new  
    list without the prime or it's multiples. 

    args:
        (list) test_set: List of numbers to sort.
    return:
        (list) new_test_set: List of numbers without first prime  
            number or its multiples.
    '''
    for x in test_set:
        for y in range(primes[-1],x+1):
            if all([
                x % y == 0,
                x > y,
                y != 1,
            ]):
                # X is not prime, skip.
                #return 0,test_set[test_set.index(x)+1:]
                break
            elif x == y:
                # X must be prime.
                primes.append(x)
                
                new_list = []
                for i in test_set[test_set.index(x):]:
                    if i % x != 0:
                       new_list.append(i) 
                        
                print(f"{round((1/len(test_set))*100,6)}%")
                return new_list


def main():
    start = time() 
    test_set = []

    for x in range(2,2000001):
        test_set.append(x)

    while test_set:
        test_set = update_test_set(test_set)

    end = time()
    dur = round((end - start)/60,3)

    print(f"\nSum of primes:\t{sum(primes)-2}")
    print(f"Duration (min):\t{dur}") 
    

main()

