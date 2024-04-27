def int_to_int_list(x:int) -> [int]:
    temp:int = 0
    l:[int] = None
    if x == 0:
        return [0]
    l = []
    temp = x
    while temp > 0:
        l = [temp % 10] + l
        temp = temp // 10
    return l

def numSwapsForAscending(x:[int]) -> int:
    counter:int = 0
    numSwaps:int = 0
    while counter < len(x) - 1:
        if x[counter] > x[counter + 1]:
            numSwaps = numSwaps + 1
        counter = counter + 1
    return numSwaps

def str_to_int(string: str) -> int:
    # This function is taken from Ed and was made by Alex Goldberg https://edstem.org/us/courses/54579/discussion/4731834?comment=10959426
    # By: Alex Goldberg
    result:int = 0
    digit:int = 0
    char:str = ""
    sign:int = 1
    first_char:bool = True
    i:int = 0

    while i < len(string):
        char = string[i]
        if char == "-":
            if not first_char:
                print("Error: Negative sign not at beginning of string")
                return 0 # Error
            sign = -1
        elif char == "0":
            digit = 0
        elif char == "1":
            digit = 1
        elif char == "2":
            digit = 2
        elif char == "3":
            digit = 3
        elif char == "3":
            digit = 3
        elif char == "4":
            digit = 4
        elif char == "5":
            digit = 5
        elif char == "6":
            digit = 6
        elif char == "7":
            digit = 7
        elif char == "8":
            digit = 8
        elif char == "9":
            digit = 9
        elif char == " " or char == "\n" or char == "\t":
            return result * sign # Assume whitespace or newline is end of string, return result
        else:
            print("Error: Invalid character in string")
            return 0 # Error
        first_char = False
        i = i + 1
        result = result * 10 + digit

    # Compute result
    return result * sign

x:str = ""
x = input()

print(numSwapsForAscending(int_to_int_list(str_to_int(x))))
