# CS 164: Programming Assignment 3

[PA3 Specification]: https://drive.google.com/open?id=1TrMUZK9A83W_WgOLzOCviZSd7HdvuU4W
[ChocoPy Specification]: https://drive.google.com/file/d/1mrgrUFHMdcqhBYzXHG24VcIiSrymR6wt
[ChocoPy Implementation Guide]: https://drive.google.com/open?id=177fFobSh6yYTV6pD-n9jcPgcJtqaoeAC

Note: Users running Windows should replace the colon (`:`) with a semicolon (`;`) in the classpath argument for all command listed below.

## Getting started

Run the following command to build your compiler, and then run all the provided tests:

```
mvn clean package

java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=..s --run --dir src/test/data/pa3/sample/ --test
```

In the starter code, only one test should pass. Your objective is to implement a code generator that passes all the provided tests and meets the assignment specifications.

### Generating assembly files

You can also run the code generator on one input file at at time. In general, running the code generator on a ChocoPy program is a three-step process. 

1. First, run the reference parser to get an AST JSON:
```
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=r <chocopy_input_file> --out <ast_json_file>
```
2. Second, run the reference analysis on the AST JSON to get a typed AST JSON:
```
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=.r <ast_json_file> --out <typed_ast_json_file>
```

3. Third, run your code generator on the typed AST JSON to get a RISC-V assembly file:
```
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=..s <typed_ast_json_file> --out <assembly_file>
```

The `src/tests/data/pa3/sample` directory already contains the typed AST JSONs for the test programs (with extension `.out.typed`); therefore, you can skip the first two steps for the sample test programs.

### Executing an assembly program using the Venus simulator

To run a generated RISC-V program in the Venus-164 execution environment, run:

```
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --run <assembly_file>
```

### Chained commands

For quick development, you can chain all the stages
to directly execute a ChocoPy program:

```
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrs --run <chocopy_input_file>
```

You can omit the `--run` in the above chain to print the generated assembly program instead of executing it.

### Running the reference implementation

To observe the output of the reference implementation of the code generator, replace  `--pass=rrs` with `--pass=rrr` in any command where applicable.

## Assignment specifications

See the [PA3 specification][] on the course
website for a detailed specification of the assignment.

Refer to the [ChocoPy Specification][] on the CS164 web site
for the specification of the ChocoPy language. 

Refer to the [ChocoPy Implementation Guide][] on the CS164 web site
for the conventions used by the reference compiler and the
starter code.

## Receiving updates to this repository

Add the `upstream` repository remotes (you only need to do this once in your local clone):

```
git remote add upstream https://github.com/cs164berkeley/pa3-chocopy-code-generation.git
```

To sync with updates upstream:
```
git pull upstream master
```

## Submission writeup

Team member 1: Justin Wong 

Team member 2: Lucas Duong 

No outside help or collaboration received. 

No slip hours used.

**1. Which optimizations did you implement? Cite line numbers in your implementation.**
We implemented optimizations for unboxing/boxing, printing integers & strings, and the str_to_int method. On lines 1260-1272, we only box for 
integers and booleans when the variable that we are assigning to is of type `object`. For other cases, we use the unboxed version which helped with 
reducing unnecessary overhead.

We realized that many of the tests utilized print statements for integers and strings (mainly integers). Currently, when we 
want to print an int/str, we are required to box them since `print` needs the input to be in `object` form in order to get 
the appropriate type tag. This creates additional overhead that cummulatively can be a performance hinderance. Thus, within 
`CallExpr`, if we are printing an integer or a string, we directly call the associated print subroutine for the respective type, 
skipping the boxing procedure. We noticed that this optimization gave us a speedup of approximately +0.6. The print optimizations can be 
seen from lines 1136-1154 & 2278-2300. 

Finally, we replaced the `str_to_int` method with our own optimized implementation that converts the string digits to integers via 
ASCII manipulation on lines 1157-1217. Each numerical digit can be represented as ASCII and refered by an integer. We can subtract the numerical 
ASCII value for zero from the current digit to the appropriate value in ASCII. 

**2. Which optimization had the most significant impact, why do you think this is the case?**
The `str_to_int` optimization had the most significant impact since it greatly helped condense all of the if-elif statements and their 
respective branches into just several lines of mathematical operations when we worked in the ASCII world. The implementation for `str_to_int` varied greatly, so creating 
an optimized version of it allowed us to fix the function for all tests. 


