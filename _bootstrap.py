g: int = 1
def foo(x: int) -> int:
    y: int = 2
    def bar() -> int:
        z: int = 3
        def baz(m: int) -> int:
            return qux(y)
        return baz(5)
    def qux(p: int) -> int:
        return p

    return bar()

print(foo(g))
