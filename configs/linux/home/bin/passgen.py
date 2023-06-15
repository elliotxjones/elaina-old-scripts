import sys
from secrets import choice


def passgen(pass_length=12):
    """Foobar"""
    pass_chars = []
    
    chars_num = []
    chars_upper = []
    chars_lower = []
    chars_special = []
    
    # invalid
    chars_invalid = [".", ",", "\\"]

    # Initialize valid numbers.
    for x in range(0,10):
        chars_num.append(str(x))
    # Initialize valid lower and uppercase chars.
    for x in range(97,123):
        chars_lower.append(str(chr(x)))
        chars_upper.append(str(chr(x).upper()))
    # Initialize valid special characters.
    for x in range(33,127):
        y = str(chr(x))
        if all([
            y not in chars_num,
            y not in chars_upper,
            y not in chars_lower,
            y not in chars_invalid,
        ]):
            chars_special.append(y)

    # Seed password with minimum required chars.
    pass_chars.append(choice(chars_num))
    pass_chars.append(choice(chars_upper))
    pass_chars.append(choice(chars_lower))
    pass_chars.append(choice(chars_special))

    chars_all = \
        chars_num + \
        chars_upper + \
        chars_lower + \
        chars_special
    
    # Append random chars to meet password length.
    while len(pass_chars) < pass_length:
        pass_chars.append(choice(chars_all))
    
    pass_seed = []

    # Randomize password so password does not start with seed.
    while pass_chars:
        x = choice(pass_chars)

        pass_seed.append(x)
        pass_chars.remove(x)
    
    # Save password list as string.
    password = "".join(pass_seed)

    print(password)

    #return password
    return None
        
def bash_main():
    print(sys.argv)
    try:
        if sys.argv[1]:
            try:
                x = int(sys.argv[1])
            except:
                print("Invalid: Arguement must be an integer!")
                print(f"Type {type(sys.argv)} provided.")
                
                return None
    except:
        x = 12
    passgen(x)

if __name__ == '__main__':
    if len(sys.argv) > 1:
        try:
            x = int(sys.argv[1])
            passgen(x)
        except:
            print("Arguement must be an integer!")
    else:
        passgen()

