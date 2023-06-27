# Problem 3
#
# The prime factors of 13195 are 5, 7, 13 and 29. 
# What is the largest prime factor of the number 600851475143?

def breakdown(n):
    for i in range(1,n+1):
        print(i)
        if all([
            n % i == 0,     
            n != 1,
        ]):
            n = n/i
            return n
                
def main():
    old_num = 600851475143
    new_num = 0
    while new_num != old_num:
        new_num = breakdown(old_num)
    print(new_num)

main()
