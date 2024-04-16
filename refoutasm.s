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
  .equiv @boolTRUE, const_1
  .equiv @boolFALSE, const_0

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

.globl $x
$x:
  .word 42                                 # Initial value of global var: x

.globl $y
$y:
  .word 7                                  # Initial value of global var: y

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
  addi sp, sp, -224                        # Saved FP and saved RA (unused at top level).
  sw ra, 52(sp)                            # [fn=main] Save return address.
  sw fp, 48(sp)                            # [fn=main] Save control link.
  sw zero, 0(sp)                           # Top saved FP is 0.
  sw zero, 4(sp)                           # Top saved RA is 0.
  addi fp, sp, 224                         # Set FP to previous SP.
  jal createSmallCharTable                 # create one-character string table
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_1:                                   # Evaluate OR second expression
  lw a0, $y                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  beq a0, t1, label_3                      # ==: Compare if A0 & T1 are equal
  li a0, 0                                 # Set A0 to be False (0)
  j label_4                                # Jump to exit local label
label_3:                                   # Equal Local Label
  li a0, 1                                 # Set A0 to be True (1)
label_4:                                   # Exit Local Label
label_2:                                   # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_5:                                   # Evaluate OR second expression
  lw a0, $y                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  beq a0, t1, label_7                      # !=: Compare if A0 & T1 are equal
  li a0, 1                                 # Set A0 to be True (1)
  j label_8                                # Jump to exit local label
label_7:                                   # Equal local label
  li a0, 0                                 # Set A0 to be False (0)
label_8:                                   # Exit local label
label_6:                                   # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_9:                                   # Evaluate OR second expression
  lw a0, $y                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  sub a0, t1, a0                           # <: Subtract A0 (Right) from T1 (Left)
  li t2, 0                                 # Load 0 into temp reg
  slt a0, a0, t2                           # Check if A0 < 0, if so set A0 to 0 else 1
label_10:                                  # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_11:                                  # Evaluate OR second expression
  lw a0, $y                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  bge a0, t1, label_13                     # <=: Compare if T1 <= A0
  li a0, 0                                 # A0 is NOT greater than T1, Set A0 to False (0)
  j label_14                               # Jump to exit local label
label_13:                                  # Less than or equal to local label
  li a0, 1                                 # A0 is greater than T1, Set A0 to True (1)
label_14:                                  # Exit local label
label_12:                                  # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_15:                                  # Evaluate OR second expression
  lw a0, $y                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  sub a0, a0, t1                           # >: Subtract T1 (Left) from A0 (Right)
  li t2, 0                                 # Load 0 into temp reg
  slt a0, a0, t2                           # Check if A0 < 0, if so set A0 to 0 else 1
label_16:                                  # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_17:                                  # Evaluate OR second expression
  lw a0, $y                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  bge t1, a0, label_19                     # >=: Compare if T1 >= A0
  li a0, 0                                 # T1 is NOT greater than A0, Set A0 to False (0)
  j label_20                               # Jump to exit local label
label_19::
  li a0, 1                                 # T1 is greater than A0, Set A0 to True (1)
label_20:                                  # Exit local label
label_18:                                  # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_21:                                  # Evaluate OR second expression
  lw a0, $x                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  beq a0, t1, label_23                     # ==: Compare if A0 & T1 are equal
  li a0, 0                                 # Set A0 to be False (0)
  j label_24                               # Jump to exit local label
label_23:                                  # Equal Local Label
  li a0, 1                                 # Set A0 to be True (1)
label_24:                                  # Exit Local Label
label_22:                                  # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_25:                                  # Evaluate OR second expression
  lw a0, $x                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  beq a0, t1, label_27                     # !=: Compare if A0 & T1 are equal
  li a0, 1                                 # Set A0 to be True (1)
  j label_28                               # Jump to exit local label
label_27:                                  # Equal local label
  li a0, 0                                 # Set A0 to be False (0)
label_28:                                  # Exit local label
label_26:                                  # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_29:                                  # Evaluate OR second expression
  lw a0, $x                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  sub a0, t1, a0                           # <: Subtract A0 (Right) from T1 (Left)
  li t2, 0                                 # Load 0 into temp reg
  slt a0, a0, t2                           # Check if A0 < 0, if so set A0 to 0 else 1
label_30:                                  # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_31:                                  # Evaluate OR second expression
  lw a0, $x                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  bge a0, t1, label_33                     # <=: Compare if T1 <= A0
  li a0, 0                                 # A0 is NOT greater than T1, Set A0 to False (0)
  j label_34                               # Jump to exit local label
label_33:                                  # Less than or equal to local label
  li a0, 1                                 # A0 is greater than T1, Set A0 to True (1)
label_34:                                  # Exit local label
label_32:                                  # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_35:                                  # Evaluate OR second expression
  lw a0, $x                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  sub a0, a0, t1                           # >: Subtract T1 (Left) from A0 (Right)
  li t2, 0                                 # Load 0 into temp reg
  slt a0, a0, t2                           # Check if A0 < 0, if so set A0 to 0 else 1
label_36:                                  # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
  lw a0, $x                                # Load identifier label into A0
  sw a0, 44(sp)                            # [push-temp `left-operand`] Store binop's left operand to stack
label_37:                                  # Evaluate OR second expression
  lw a0, $x                                # Load identifier label into A0
  lw t1, 44(sp)                            # [peek-temp `left-operand`] load binop's left operand from stack to `T1`
  bge t1, a0, label_39                     # >=: Compare if T1 >= A0
  li a0, 0                                 # T1 is NOT greater than A0, Set A0 to False (0)
  j label_40                               # Jump to exit local label
label_39::
  li a0, 1                                 # T1 is greater than A0, Set A0 to True (1)
label_40:                                  # Exit local label
label_38:                                  # Exit binary expression local label
  jal wrapBoolean
  sw a0, 44(sp)                            # [push-temp `arg 0-th`] push arg 0-th `arg` of "print" to stack
  addi sp, sp, 44                          # [deflate-stack] shrink stack
  jal $print                               # Call function: print
  addi sp, sp, -44                         # [inflate-stack] inflate stack
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
  li a0, 2                                 # Exit code for: Division by zero
  la a1, const_7                           # Load error message as str
  addi a1, a1, 16                          # Load address of attribute __str__
  j abort                                  # Abort

.globl error.OOB
error.OOB:
  li a0, 3                                 # Exit code for: Index out of bounds
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
  beq a0, t0, label_41                     # Check which boolean branch to go to
  la a0, const_0                           # Load False constant's address into A0
  jr ra                                    # Go back
label_41:                                  # Label for true branch
  la a0, const_1                           # Load True constant's address into A0
  jr ra                                    # Go back

.globl concatenateList
concatenateList:
  addi sp, sp, -72                         # Reserve space for stack frame
  sw ra, 68(sp)                            # Save return address.
  sw fp, 64(sp)                            # Save control link.
  addi fp, sp, 72                          # `fp` is at old `sp`.
  sw s1, 60(sp)                            # backup registers s1->s5
  sw s2, 56(sp)                            # backup registers s1->s5
  sw s3, 52(sp)                            # backup registers s1->s5
  sw s4, 48(sp)                            # backup registers s1->s5
  sw s5, 44(sp)                            # backup registers s1->s5
  #..................................................( Compute sum of list lengths and then allocate ).................................................. # 
  lw t0, 4(fp)                             # t0 = arg1
  lw t1, 0(fp)                             # t1 = arg2
  beqz t0, label_42                        # asserts t0 not None
  beqz t1, label_42                        # asserts t1 not None
  lw t0, 12(t0)                            # t0 = t0.__len__
  lw t1, 12(t1)                            # t1 = t1.__len__
  add s5, t0, t1                           # s5 = arg1.len + arg2.len
  addi a1, s5, 4                           # reserve space for header and load sum into A1 to prep for alloc2
  la a0, $.list$prototype                  # A0 = list-prototype (for alloc2)
  jal alloc2                               # allocate new list
  #__________________________________________________( initialize newly created array )__________________________________________________ # 
  sw s5, 12(a0)                            # initialize new list's size
  mv s5, a0                                # s5 = heap-ptr
  addi s3, s5, 16                          # s3 = heap-ptr + offset-to-first-element
  lw s1, 4(fp)                             # s1 = arg1
  lw s2, 12(s1)                            # s2 = arg1.len
  #..................................................( Copy arg1 into allocated list ).................................................. # 
  addi s1, s1, 16                          # s1 = &arg1[0]
label_44:                                  # copy arg1 to destination
  beqz s2, label_46                        # loop when s2 > 0; else start initialize the copying of arg2
  lw a0, 0(s1)                             # a0 = arg1[0]
  sw a0, 0(s3)                             # *ptr-to-first-elem = a0
  addi s2, s2, -1                          # decrement index s2 = (arg1.len ... 1)
  addi s1, s1, 4                           # advance to next element of arg1
  addi s3, s3, 4                           # ptr-to-first-elem += 4
  j label_44                               # continue loop
label_46:                                  # preparing to copy arg2
  lw s1, 0(fp)                             # s1 = arg2
  lw s2, 12(s1)                            # s2 = arg2.len
  addi s1, s1, 16                          # s1 = &arg2[0]
  #..................................................( Copy arg2 into allocated list ).................................................. # 
label_45:                                  # copy arg2
  beqz s2, label_43                        # when done copying, go to epilogue
  lw a0, 0(s1)                             # a0 = arg2[0]
  sw a0, 0(s3)                             # *ptr-to-first-element = arg2[0]
  addi s2, s2, -1                          # remaining elements -= 1
  addi s1, s1, 4                           # advance to next element of arg2
  addi s3, s3, 4                           # ptr-to-first-element += 4
  j label_45                               # loop
label_43:                                  # cleanup
  mv a0, s5                                # ret = heap-ptr
  lw s5, 44(sp)                            # restore registers s1 -> s5
  lw s4, 48(sp)                            # restore registers s1 -> s5
  lw s3, 52(sp)                            # restore registers s1 -> s5
  lw s2, 56(sp)                            # restore registers s1 -> s5
  lw s1, 60(sp)                            # restore registers s1 -> s5
  lw ra, -4(fp)                            # get return addr
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, 72                          # restore stack ptr
  jr ra                                    # return to caller
label_42:                                  # concat_none:
  j error.None                             # 

.globl constructList
constructList:
  addi sp, sp, -8
  sw ra, 4(sp)
  sw fp, 0(sp)
  addi fp, sp, 8                           # fp is old sp
  lw a1, 0(fp)                             # Get list size
  la a0, $.list$prototype                  # Get list prototype for alloc2
  beqz a1, conslist_done                   # If list empty, then we done.
  addi a1, a1, 4                           # Allocate sz + 4 to store elements and headers
  jal alloc2                               # Allocate space for list on heap
  lw t0, 0(fp)                             # t0 = len
  sw t0, 12(a0)                            # store length attr to list on heap
  slli t1, t0, 2                           # t1 = size (in bytes) of list in memory
  add t1, t1, fp                           # t1 now points to start of stack-list
  addi t2, a0, 16                          # t2 points to first array element
conslist_1:                                # copying contents from stack-list to heap-list
  lw t3, 0(t1)                             # t3 = stack-arr[0]
  sw t3, 0(t2)                             # heap-arr[0] = t3
  addi t1, t1, -4                          # stack-arr -= 4
  addi t2, t2, 4                           # heap-arr += 4
  addi t0, t0, -1                          # size -= 1
  bnez t0, conslist_1                      # if there are still element to be copy, keep copying.
conslist_done:                             # just finishing up
  lw ra, -4(fp)
  lw fp, -8(fp)
  addi sp, sp, 8
  jr ra

.globl createSmallCharTable
createSmallCharTable:
  la a0, $str$prototype                    # get string prototype
  lw t0, 0(a0)                             # get str tag
  lw t1, 4(a0)                             # get object size
  lw t2, 8(a0)                             # Get ptr-to-dispatch-table
  li t3, 1                                 # size of string
  la a0, smallCharsTable                   # get ptr to charTable
  li t4, 256
  mv t5, zero                              # set up idx = 0
label_47:                                  # loop to create char table
  sw t0, 0(a0)                             # store type tag
  sw t1, 4(a0)                             # store object size
  sw t2, 8(a0)                             # store ptr-to-dispatch-table
  sw t3, 12(a0)                            # store size of string
  sw t5, 16(a0)                            # store the character
  addi a0, a0, 20                          # jumps to the next location to store character
  addi t5, t5, 1                           # char = char + 1
  bne t4, t5, label_47                     # goto-loop
  jr ra                                    # return
  .data
  .align 2                                 # to ensure alignment

.globl smallCharsTable
smallCharsTable:
  .space 5120
  .text

.globl strCat
strCat:
  addi sp, sp, -12
  sw ra, 8(sp)
  sw fp, 4(sp)
  addi fp, sp, 12
  lw t0, 4(fp)                             # Load first string to T0
  lw t1, 0(fp)                             # Load second string to T1
  lw t0, 12(t0)                            # Get T0's length
  lw t1, 12(t1)                            # Get T1's length
  beqz t0, label_48                        # TO is empty so just return T1
  beqz t1, label_49                        # T1 is empty so just return T0
  add t0, t0, t1                           # k
  sw t0, -12(fp)                           # Store k to stack
  addi t0, t0, 4
  srli t0, t0, 2
  la a0, $str$prototype                    # Get string prototype for alloc2
  addi a1, t0, 4
  jal alloc2                               # jal alloc
  lw t0, -12(fp)                           # Load k from stack
  sw t0, 12(a0)                            # Store k to __len__ attr
  addi t1, a0, 16                          # T1 = address of new __str__ store
  lw t0, 4(fp)                             # Load first string to T0
  lw t2, 12(t0)                            # T2 = T0's length
  addi t0, t0, 16                          # T0 = content of 1st string
label_51:                                  # [ENTER BRANCH]: Loop and store for first string
  beqz t2, label_50                        # Finished storing T0, now do the same for T1
  lbu t3, 0(t0)                            # Load byte for first str
  sb t3, 0(t1)                             # Store byte into T1
  addi t2, t2, -1                          # Decrement T0's length by 1
  addi t1, t1, 1                           # Increment store __str__ address by 1
  addi t0, t0, 1                           # Increment str address by 1
  j label_51                               # [JUMP]: Loop and store for T0
label_50:                                  # [ENTER BRANCH]: Reset config for second string looping
  lw t0, 0(fp)                             # Load second string to T0
  lw t2, 12(t0)                            # T2 = T0's length
  addi t0, t0, 16                          # T0 = content of 2nd string
label_52:                                  # [ENTER BRANCH]: Loop and store for second string
  beqz t2, label_53                        # Finish processing T1, jump to add null char to str
  lbu t3, 0(t0)                            # Load byte for second str
  sb t3, 0(t1)                             # Store byte into T1
  addi t2, t2, -1                          # Decrement T1's length by 1
  addi t1, t1, 1                           # Increment store __str__ address by 1
  addi t0, t0, 1                           # Increment str address by 1
  j label_52                               # [JUMP]: Loop and store for T1
label_48:                                  # [ENTER BRANCH]: T0 Empty Return T1
  lw a0, 0(fp)                             # Return T1
  j label_54                               # [JUMP]; Calling Convention Cleanup
label_49:                                  # [ENTER BRANCH]: T1 Empty Return T0
  lw a0, 4(fp)                             # Return T0
  j label_54                               # [JUMP]: Calling Convention Cleanup
label_53:                                  # [ENTER BRANCH]: Append Null Char to str
  sb zero, 0(t1)                           # Append null char to str
label_54:                                  # [ENTER BRANCH]: Calling Convention Cleanup
  lw ra, -4(fp)
  lw fp, -8(fp)
  addi sp, sp, 12
  jr ra                                    # [JUMP]: Exit StrCat

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
