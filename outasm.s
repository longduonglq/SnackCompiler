  .equiv @sbrk, 9
  .equiv @print_string, 4
  .equiv @print_char, 11
  .equiv @print_int, 1
  .equiv @exit2, 17
  .equiv @read_string, 8
  .equiv @fill_line_buffer, 18
  .equiv @.__obj_size__, 4
  .equiv @.__len__, 12
  .equiv @.__int__, 12
  .equiv @.__bool__, 12
  .equiv @.__str__, 16
  .equiv @.__elts__, 16
  .equiv @error_div_zero, 2
  .equiv @error_arg, 1
  .equiv @error_oob, 3
  .equiv @error_none, 4
  .equiv @error_oom, 5
  .equiv @error_nyi, 6
  .equiv @bool.True, const_1
  .equiv @bool.False, const_0

.data

.globl $object$prototype
$object$prototype:
  .word 0                                  # Type tag for class: object
  .word 3                                  # Object size
  .word $object$dispatchTable              # Pointer to dispatch table
  .align 2

.globl $int$prototype
$int$prototype:
  .word 1                                  # Type tag for class: int
  .word 4                                  # Object size
  .word $int$dispatchTable                 # Pointer to dispatch table
  .word 0                                  # Initial value of attribute: __int__
  .align 2

.globl $bool$prototype
$bool$prototype:
  .word 2                                  # Type tag for class: bool
  .word 4                                  # Object size
  .word $bool$dispatchTable                # Pointer to dispatch table
  .word 0                                  # Initial value of attribute: __bool__
  .align 2

.globl $str$prototype
$str$prototype:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 0                                  # Initial value of attribute: __len__
  .word 0                                  # Initial value of attribute: __str__
  .align 2

.globl $.list$prototype
$.list$prototype:
  .word -1                                 # Type tag for class: .list
  .word 4                                  # Object size
  .word 0                                  # Pointer to dispatch table
  .word 0                                  # Initial value of attribute: __len__
  .align 2

.globl $object$dispatchTable
$object$dispatchTable:
  .word $object.__init__                   # Implementation for method: object.__init__

.globl $int$dispatchTable
$int$dispatchTable:
  .word $object.__init__                   # Implementation for method: int.__init__

.globl $bool$dispatchTable
$bool$dispatchTable:
  .word $object.__init__                   # Implementation for method: bool.__init__

.globl $str$dispatchTable
$str$dispatchTable:
  .word $object.__init__                   # Implementation for method: str.__init__

.globl $n
$n:
  .word 15                                 # Initial value of global var: n

.globl $i
$i:
  .word 1                                  # Initial value of global var: i

.text

.globl main
main:
  lui a0, 8192                             # Initialize heap size (in multiples of 4KB)
  add s11, s11, a0                         # Save heap size
  jal heap.init                            # Call heap.init routine
  mv gp, a0                                # Initialize heap pointer
  mv s10, gp                               # Set beginning of heap
  add s11, s10, s11                        # Set end of heap (= start of heap + heap size)
  mv ra, zero                              # No normal return from main program.
  mv fp, zero                              # No preceding frame.
  addi sp, sp, -8                          # Saved FP and saved RA (unused at top level).
  sw zero, 0(sp)                           # Top saved FP is 0.
  sw zero, 4(sp)                           # Top saved RA is 0.
  addi fp, sp, 8                           # Set FP to previous SP.
label_1:                                   # Top of while loop
  lw a0, $i                                # Load identifier label into A0
  addi sp, sp, -4                          # Store binop's left operand to stack
  sw a0, 0(sp)                             # push reg a0 to stack
label_4:                                   # Evaluate OR second expression
  lw a0, $n                                # Load identifier label into A0
  lw t1, 0(sp)                             # pop stack to reg t1
  addi sp, sp, 4                           # Binop's left operand from stack to `T1`.
  bge a0, t1, label_6                      # <=: Compare if T1 <= A0
  li a0, 0                                 # A0 is NOT greater than T1, Set A0 to False (0)
  j label_7                                # Jump to exit local label
label_6:                                   # Less than or equal to local label
  li a0, 1                                 # A0 is greater than T1, Set A0 to True (1)
label_7:                                   # Exit local label
label_5:                                   # Exit binary expression local label
  li t0, 1                                 # Store 1 into temp reg
  beq a0, t0, label_2                      # Check if condition is true
  j label_3                                # Jump to bottom of while loop to exit
label_2:                                   # While loop body
  lw a0, $i                                # Load identifier label into A0
  addi sp, sp, -4                          # push arg 0-th `n` of "get_prime" to stack
  sw a0, 0(sp)                             # push reg a0 to stack
  jal $get_prime                           # Call function: get_prime
  addi sp, fp, -16                         # Set SP to top of stack
  jal wrapInteger
  addi sp, sp, -4                          # push arg 0-th `arg` of "print" to stack
  sw a0, 0(sp)                             # push reg a0 to stack
  jal $print                               # Call function: print
  addi sp, fp, -8                          # Set SP to top of stack
  lw a0, $i                                # Load identifier label into A0
  addi sp, sp, -4                          # Store binop's left operand to stack
  sw a0, 0(sp)                             # push reg a0 to stack
label_8:                                   # Evaluate OR second expression
  li a0, 1                                 # Load integer literal: 1
  lw t1, 0(sp)                             # pop stack to reg t1
  addi sp, sp, 4                           # Binop's left operand from stack to `T1`.
  add a0, t1, a0                           # + two operands
label_9:                                   # Exit binary expression local label
  sw a0, $i, t1                            # Store A0 into global var i
  j label_1                                # Go back to top of while loop
label_3:                                   # Bottom of while loop
  li a0, 10                                # Code for ecall: exit
  ecall

.globl $object.__init__
$object.__init__:
# Init method for type object.	
  mv a0, zero                              # `None` constant
  jr ra                                    # Return

.globl $print
$print:
# Function print
  lw a0, 0(sp)                             # Load arg
  beq a0, zero, print_6                    # None is an illegal argument
  lw t0, 0(a0)                             # Get type tag of arg
  li t1, 1                                 # Load type tag of `int`
  beq t0, t1, print_7                      # Go to print(int)
  li t1, 3                                 # Load type tag of `str`
  beq t0, t1, print_8                      # Go to print(str)
  li t1, 2                                 # Load type tag of `bool`
  beq t0, t1, print_9                      # Go to print(bool)
print_6:                                   # Invalid argument
  li a0, 1                                 # Exit code for: Invalid argument
  la a1, const_2                           # Load error message as str
  addi a1, a1, @.__str__                   # Load address of attribute __str__
  j abort                                  # Abort

# Printing bools
print_9:                                   # Print bool object in A0
  lw a0, @.__bool__(a0)                    # Load attribute __bool__
  beq a0, zero, print_10                   # Go to: print(False)
  la a0, const_3                           # String representation: True
  j print_8                                # Go to: print(str)
print_10:                                  # Print False object in A0
  la a0, const_4                           # String representation: False
  j print_8                                # Go to: print(str)

# Printing strs.
print_8:                                   # Print str object in A0
  addi a1, a0, @.__str__                   # Load address of attribute __str__
  j print_11                               # Print the null-terminated string is now in A1
  mv a0, zero                              # Load None
  j print_5                                # Go to return
print_11:                                  # Print null-terminated string in A1
  li a0, @print_string                     # Code for ecall: print_string
  ecall                                    # Print string
  li a1, 10                                # Load newline character
  li a0, @print_char                       # Code for ecall: print_char
  ecall                                    # Print character
  j print_5                                # Go to return

# Printing ints.
print_7:                                   # Print int object in A0
  lw a1, @.__int__(a0)                     # Load attribute __int__
  li a0, @print_int                        # Code for ecall: print_int
  ecall                                    # Print integer
  li a1, 10                                # Load newline character
  li a0, 11                                # Code for ecall: print_char
  ecall                                    # Print character

print_5:                                   # End of function
  mv a0, zero                              # Load None
  jr ra                                    # Return to caller

.globl $len
$len:
# Function len
      # We do not save/restore fp/ra for this function
      # because we know that it does not use the stack or does not
      # call other functions.

  lw a0, 0(sp)                             # Load arg
  beq a0, zero, len_12                     # None is an illegal argument
  lw t0, 0(a0)                             # Get type tag of arg
  li t1, 3                                 # Load type tag of `str`
  beq t0, t1, len_13                       # Go to len(str)
  li t1, -1                                # Load type tag for list objects
  beq t0, t1, len_13                       # Go to len(list)
len_12:                                    # Invalid argument
  li a0, @error_arg                        # Exit code for: Invalid argument
  la a1, const_2                           # Load error message as str
  addi a1, a1, @.__str__                   # Load address of attribute __str__
  j abort                                  # Abort
len_13:                                    # Get length of string
  lw a0, @.__len__(a0)                     # Load attribute: __len__
  jr ra                                    # Return to caller

.globl $input
$input:
# Function input
  addi sp, sp, -16                         # Reserve stack	
  sw ra, 12(sp)                            # Save registers
  sw fp, 8(sp)	
  sw s1, 4(sp)
  addi fp, sp, 16                          # Set fp

  li a0, @fill_line_buffer                 # Fill the internal line buffer.
  ecall
  bgez a0, input_nonempty                  # More input found
  la a0, $str$prototype                    # EOF: Return empty string.
  j input_done

input_nonempty:
  mv s1, a0
  addi t0, s1, 5                           # Compute bytes for string (+NL+NUL),
  addi t0, t0, @.__str__                   # Including header.
  srli a1, t0, 2                           # Convert to words.
  la a0, $str$prototype                    # Load address of string prototype.
  jal ra, alloc2                           # Allocate string.
  sw s1, @.__len__(a0)                     # Store string length.
  mv a2, s1                                # Pass length.
  mv s1, a0                                # Save string object address.
  addi a1, a0, @.__str__                   # Pass address of string data.
  li a0, @read_string                      # ecall to read from internal buffer.
  ecall
  addi a0, a0, 1                           # Actual length (including NL).
  sw a0, @.__len__(s1)                     # Store actual length.
  add t0, a0, s1
  li t1, 10                                # Store newline and null byte
  sb t1, @.__str__-1(t0)
  sb zero, @.__str__(t0)                   # Store null byte at end.
  mv a0, s1                                # Return string object.

input_done:
  lw s1, -12(fp)
  lw ra, -4(fp)
  lw fp, -8(fp)
  addi sp, sp, 16
  jr ra
  #--------------------------------------------------( get_prime )-------------------------------------------------- # 

.globl $get_prime
$get_prime:
  addi sp, sp, -16                         # [fn=get_prime] Reserve space for stack frame
  sw ra, 12(sp)                            # [fn=get_prime] Save return address.
  sw fp, 8(sp)                             # [fn=get_prime] Save control link.
  addi fp, sp, 16                          # [fn=get_prime] `fp` is at old `sp`.
  li a0, 2                                 # Load integer literal: 2
  sw a0, -12(fp)                           # [fn=get_prime] store local VAR `candidate: int` FROM reg `a0`
  li a0, 0                                 # Load integer literal: 0
  sw a0, -16(fp)                           # [fn=get_prime] store local VAR `found: int` FROM reg `a0`
label_11:                                  # Top of while loop
  li a0, 1                                 # Load boolean immediate "true" into A0
  li t0, 1                                 # Store 1 into temp reg
  beq a0, t0, label_12                     # Check if condition is true
  j label_13                               # Jump to bottom of while loop to exit
label_12:                                  # While loop body
  lw a0, -12(fp)                           # [fn=get_prime] load local VAR `candidate: int` TO reg `a0`
  addi sp, sp, -4                          # push arg 0-th `x` of "is_prime" to stack
  sw a0, 0(sp)                             # push reg a0 to stack
  jal $is_prime                            # Call function: is_prime
  addi sp, fp, -12                         # Set SP to top of stack
  beqz a0, label_14                        # If A0 == 0, jump to falseElseBranch
  lw a0, -16(fp)                           # [fn=get_prime] load local VAR `found: int` TO reg `a0`
  addi sp, sp, -4                          # Store binop's left operand to stack
  sw a0, 0(sp)                             # push reg a0 to stack
label_16:                                  # Evaluate OR second expression
  li a0, 1                                 # Load integer literal: 1
  lw t1, 0(sp)                             # pop stack to reg t1
  addi sp, sp, 4                           # Binop's left operand from stack to `T1`.
  add a0, t1, a0                           # + two operands
label_17:                                  # Exit binary expression local label
  mv t0, fp                                # Get static link of get_prime
  sw a0, -16(t0)                           # [fn=get_prime] load NON-LOCAL param `found: int` to reg A0
  lw a0, -16(fp)                           # [fn=get_prime] load local VAR `found: int` TO reg `a0`
  addi sp, sp, -4                          # Store binop's left operand to stack
  sw a0, 0(sp)                             # push reg a0 to stack
label_20:                                  # Evaluate OR second expression
  lw a0, 0(fp)                             # [fn=get_prime] load local PARAM `n: int` to reg `a0`
  lw t1, 0(sp)                             # pop stack to reg t1
  addi sp, sp, 4                           # Binop's left operand from stack to `T1`.
  beq a0, t1, label_22                     # ==: Compare if A0 & T1 are equal
  li a0, 0                                 # Set A0 to be False (0)
  j label_23                               # Jump to exit local label
label_22:                                  # Equal Local Label
  li a0, 1                                 # Set A0 to be True (1)
label_23:                                  # Exit Local Label
label_21:                                  # Exit binary expression local label
  beqz a0, label_18                        # If A0 == 0, jump to falseElseBranch
  lw a0, -12(fp)                           # [fn=get_prime] load local VAR `candidate: int` TO reg `a0`
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, 16                          # Restore stack pointer
  jr ra                                    # Return to caller
  jal label_19
label_18::
label_19::
  jal label_15
label_14::
label_15::
  lw a0, -12(fp)                           # [fn=get_prime] load local VAR `candidate: int` TO reg `a0`
  addi sp, sp, -4                          # Store binop's left operand to stack
  sw a0, 0(sp)                             # push reg a0 to stack
label_24:                                  # Evaluate OR second expression
  li a0, 1                                 # Load integer literal: 1
  lw t1, 0(sp)                             # pop stack to reg t1
  addi sp, sp, 4                           # Binop's left operand from stack to `T1`.
  add a0, t1, a0                           # + two operands
label_25:                                  # Exit binary expression local label
  mv t0, fp                                # Get static link of get_prime
  sw a0, -12(t0)                           # [fn=get_prime] load NON-LOCAL param `candidate: int` to reg A0
  j label_11                               # Go back to top of while loop
label_13:                                  # Bottom of while loop
  li a0, 0                                 # Load integer literal: 0
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, 16                          # Restore stack pointer
  jr ra                                    # Return to caller
  li a0, 0                                 # Load integer literal: 0
  j label_10                               # [fn=get_prime] jump to epilogue
label_10:                                  # Epilogue
  lw ra, -4(fp)                            # get return addr
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, 16                          # restore stack ptr
  jr ra                                    # return to caller
  #--------------------------------------------------( is_prime )-------------------------------------------------- # 

.globl $is_prime
$is_prime:
  addi sp, sp, -12                         # [fn=is_prime] Reserve space for stack frame
  sw ra, 8(sp)                             # [fn=is_prime] Save return address.
  sw fp, 4(sp)                             # [fn=is_prime] Save control link.
  addi fp, sp, 12                          # [fn=is_prime] `fp` is at old `sp`.
  li a0, 2                                 # Load integer literal: 2
  sw a0, -12(fp)                           # [fn=is_prime] store local VAR `div: int` FROM reg `a0`
label_27:                                  # Top of while loop
  lw a0, -12(fp)                           # [fn=is_prime] load local VAR `div: int` TO reg `a0`
  addi sp, sp, -4                          # Store binop's left operand to stack
  sw a0, 0(sp)                             # push reg a0 to stack
label_30:                                  # Evaluate OR second expression
  lw a0, 0(fp)                             # [fn=is_prime] load local PARAM `x: int` to reg `a0`
  lw t1, 0(sp)                             # pop stack to reg t1
  addi sp, sp, 4                           # Binop's left operand from stack to `T1`.
  sub a0, t1, a0                           # <: Subtract A0 (Right) from T1 (Left)
  li t2, 0                                 # Load 0 into temp reg
  slt a0, a0, t2                           # Check if A0 < 0, if so set A0 to 0 else 1
label_31:                                  # Exit binary expression local label
  li t0, 1                                 # Store 1 into temp reg
  beq a0, t0, label_28                     # Check if condition is true
  j label_29                               # Jump to bottom of while loop to exit
label_28:                                  # While loop body
  lw a0, 0(fp)                             # [fn=is_prime] load local PARAM `x: int` to reg `a0`
  addi sp, sp, -4                          # Store binop's left operand to stack
  sw a0, 0(sp)                             # push reg a0 to stack
label_36:                                  # Evaluate OR second expression
  lw a0, -12(fp)                           # [fn=is_prime] load local VAR `div: int` TO reg `a0`
  lw t1, 0(sp)                             # pop stack to reg t1
  addi sp, sp, 4                           # Binop's left operand from stack to `T1`.
  rem a0, t1, a0                           # % two operands
label_37:                                  # Exit binary expression local label
  addi sp, sp, -4                          # Store binop's left operand to stack
  sw a0, 0(sp)                             # push reg a0 to stack
label_34:                                  # Evaluate OR second expression
  li a0, 0                                 # Load integer literal: 0
  lw t1, 0(sp)                             # pop stack to reg t1
  addi sp, sp, 4                           # Binop's left operand from stack to `T1`.
  beq a0, t1, label_38                     # ==: Compare if A0 & T1 are equal
  li a0, 0                                 # Set A0 to be False (0)
  j label_39                               # Jump to exit local label
label_38:                                  # Equal Local Label
  li a0, 1                                 # Set A0 to be True (1)
label_39:                                  # Exit Local Label
label_35:                                  # Exit binary expression local label
  beqz a0, label_32                        # If A0 == 0, jump to falseElseBranch
  li a0, 0                                 # Load boolean immediate "false" into A0
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, 12                          # Restore stack pointer
  jr ra                                    # Return to caller
  jal label_33
label_32::
label_33::
  lw a0, -12(fp)                           # [fn=is_prime] load local VAR `div: int` TO reg `a0`
  addi sp, sp, -4                          # Store binop's left operand to stack
  sw a0, 0(sp)                             # push reg a0 to stack
label_40:                                  # Evaluate OR second expression
  li a0, 1                                 # Load integer literal: 1
  lw t1, 0(sp)                             # pop stack to reg t1
  addi sp, sp, 4                           # Binop's left operand from stack to `T1`.
  add a0, t1, a0                           # + two operands
label_41:                                  # Exit binary expression local label
  mv t0, fp                                # Get static link of is_prime
  sw a0, -12(t0)                           # [fn=is_prime] load NON-LOCAL param `div: int` to reg A0
  j label_27                               # Go back to top of while loop
label_29:                                  # Bottom of while loop
  li a0, 1                                 # Load boolean immediate "true" into A0
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, 12                          # Restore stack pointer
  jr ra                                    # Return to caller
  li a0, 1                                 # Load boolean immediate "true" into A0
  j label_26                               # [fn=is_prime] jump to epilogue
label_26:                                  # Epilogue
  lw ra, -4(fp)                            # get return addr
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, 12                          # restore stack ptr
  jr ra                                    # return to caller

.globl alloc
alloc:
# Runtime support function alloc.
        # Prototype address is in a0.
  lw a1, 4(a0)                             # Get size of object in words
  j alloc2                                 # Allocate object with exact size

.globl alloc2
alloc2:
# Runtime support function alloc2 (realloc).
        # Prototype address is in a0.
        # Number of words to allocate is in a1.
  li a2, 4                                 # Word size in bytes
  mul a2, a1, a2                           # Calculate number of bytes to allocate
  add a2, gp, a2                           # Estimate where GP will move
  bgeu a2, s11, alloc2_15                  # Go to OOM handler if too large
  lw t0, @.__obj_size__(a0)                # Get size of object in words
  mv t2, a0                                # Initialize src ptr
  mv t3, gp                                # Initialize dest ptr
alloc2_16:                                 # Copy-loop header
  lw t1, 0(t2)                             # Load next word from src
  sw t1, 0(t3)                             # Store next word to dest
  addi t2, t2, 4                           # Increment src
  addi t3, t3, 4                           # Increment dest
  addi t0, t0, -1                          # Decrement counter
  bne t0, zero, alloc2_16                  # Loop if more words left to copy
  mv a0, gp                                # Save new object's address to return
  sw a1, @.__obj_size__(a0)                # Set size of new object in words
                                           # (same as requested size)
  mv gp, a2                                # Set next free slot in the heap
  jr ra                                    # Return to caller
alloc2_15:                                 # OOM handler
  li a0, @error_oom                        # Exit code for: Out of memory
  la a1, const_5                           # Load error message as str
  addi a1, a1, @.__str__                   # Load address of attribute __str__
  j abort                                  # Abort

.globl abort
abort:
# Runtime support function abort (does not return).
  mv t0, a0                                # Save exit code in temp
  li a0, @print_string                     # Code for print_string ecall
  ecall                                    # Print error message in a1
  li a1, 10                                # Load newline character
  li a0, @print_char                       # Code for print_char ecall
  ecall                                    # Print newline
  mv a1, t0                                # Move exit code to a1
  li a0, @exit2                            # Code for exit2 ecall
  ecall                                    # Exit with code
abort_17:                                  # Infinite loop
  j abort_17                               # Prevent fallthrough

.globl heap.init
heap.init:
# Runtime support function heap.init.
  mv a1, a0                                # Move requested size to A1
  li a0, @sbrk                             # Code for ecall: sbrk
  ecall                                    # Request A1 bytes
  jr ra                                    # Return to caller

.globl error.None
error.None:
  li a0, 4                                 # Exit code for: Operation on None
  la a1, const_6                           # Load error message as str
  addi a1, a1, 16                          # Load address of attribute __str__
  j abort                                  # Abort

.globl error.Div
error.Div:
  li a0, 4                                 # Exit code for: Division by zero
  la a1, const_7                           # Load error message as str
  addi a1, a1, 16                          # Load address of attribute __str__
  j abort                                  # Abort

.globl error.OOB
error.OOB:
  li a0, 4                                 # Exit code for: Index out of bounds
  la a1, const_8                           # Load error message as str
  addi a1, a1, 16                          # Load address of attribute __str__
  j abort                                  # Abort

.globl wrapInteger
wrapInteger:
  addi sp, sp, -8
  sw ra, 0(sp)
  sw a0, 4(sp)
  la a0, $int$prototype
  jal alloc
  lw t0, 4(sp)
  sw t0, 12(a0)
  lw ra, 0(sp)
  addi sp, sp, 8
  jr ra

.globl wrapBoolean
wrapBoolean:
  li t0, 1                                 # Load True into temp reg for comparison
  beq a0, t0, label_42                     # Check which boolean branch to go to
  la a0, const_0                           # Load False constant's address into A0
  jr ra                                    # Go back
label_42:                                  # Label for true branch
  la a0, const_1                           # Load True constant's address into A0
  jr ra                                    # Go back

.data

.globl const_0
const_0:
  .word 2                                  # Type tag for class: bool
  .word 4                                  # Object size
  .word $bool$dispatchTable                # Pointer to dispatch table
  .word 0                                  # Constant value of attribute: __bool__
  .align 2

.globl const_1
const_1:
  .word 2                                  # Type tag for class: bool
  .word 4                                  # Object size
  .word $bool$dispatchTable                # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __bool__
  .align 2

.globl const_7
const_7:
  .word 3                                  # Type tag for class: str
  .word 9                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 16                                 # Constant value of attribute: __len__
  .string "Division by zero"               # Constant value of attribute: __str__
  .align 2

.globl const_5
const_5:
  .word 3                                  # Type tag for class: str
  .word 8                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 13                                 # Constant value of attribute: __len__
  .string "Out of memory"                  # Constant value of attribute: __str__
  .align 2

.globl const_8
const_8:
  .word 3                                  # Type tag for class: str
  .word 9                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 19                                 # Constant value of attribute: __len__
  .string "Index out of bounds"            # Constant value of attribute: __str__
  .align 2

.globl const_3
const_3:
  .word 3                                  # Type tag for class: str
  .word 6                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 4                                  # Constant value of attribute: __len__
  .string "True"                           # Constant value of attribute: __str__
  .align 2

.globl const_6
const_6:
  .word 3                                  # Type tag for class: str
  .word 9                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 17                                 # Constant value of attribute: __len__
  .string "Operation on None"              # Constant value of attribute: __str__
  .align 2

.globl const_2
const_2:
  .word 3                                  # Type tag for class: str
  .word 9                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 16                                 # Constant value of attribute: __len__
  .string "Invalid argument"               # Constant value of attribute: __str__
  .align 2

.globl const_4
const_4:
  .word 3                                  # Type tag for class: str
  .word 6                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 5                                  # Constant value of attribute: __len__
  .string "False"                          # Constant value of attribute: __str__
  .align 2
