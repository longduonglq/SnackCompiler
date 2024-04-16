class A(object):
    def __init__(self: "A"):
        print("A has entered the chat!")

    def rhinestonePolishing(self: "A", stones: [int], bonus: int) -> int:
        totalInitValue:int = 0
        numOfRhinestones:int = 0
        stone:int = 0
        numOfRhinestones = len(stones)

        for stone in stones:
            totalInitValue = totalInitValue + stone

        while numOfRhinestones > 0:
            totalInitValue = totalInitValue * 4
            numOfRhinestones = numOfRhinestones - 1

        return totalInitValue

class B(A):
    def __init__(self: "B"):
        print("B has entered the chat!")
        print(self.aCordialGreeting("B"))

    def calculating(self: "B", numOne:int, numTwo:int, numThree:int, numFour: int) -> int:
        return numTwo * numThree + numOne * numFour

    def aCordialGreeting(self: "B", name: str) -> str:
        return "Hello! I'm " + name + "! How are you?"

    def polishRhinestones(self: "B", stones: [int], secretWord: str) -> int:
        return self.rhinestonePolishing(stones, self.calculating(10, 100, 8, 39)) + len(secretWord)

    def getDecision(self: "B", yesOrNo:bool) -> str:
        if yesOrNo:
            return "apple"
        else:
            return "apple cider"

    def decidingOnHardThings(self: "B", x:str, y:int) -> str:
        if len(x) < y:
            return self.getDecision(True)
        elif len(x) > y:
            return self.getDecision(False)
        else:
            if y > 0:
                return self.getDecision(True)
            else:
                return self.getDecision(False)

a:A = None
b:B = None
a = A()
b = B()

print(b.polishRhinestones([3, 4, 5, 6], "sesame"))
print(b.decidingOnHardThings("apples", 10))
