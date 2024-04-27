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
  .equiv @listHeaderWords, 4
  .equiv @strHeaderWords, 4
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

.globl $a
$a:
  .word 0                                  # Initial value of global var: a

.globl $b
$b:
  .word 0                                  # Initial value of global var: b

.globl $i
$i:
  .word 0                                  # Initial value of global var: i

.globl $j
$j:
  .word 0                                  # Initial value of global var: j

.globl $k
$k:
  .word 0                                  # Initial value of global var: k

.globl $l
$l:
  .word 0                                  # Initial value of global var: l

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
  addi sp, sp, -@..main.size               # Reserve space for stack frame.
  sw ra, @..main.size-4(sp)                # return address
  sw fp, @..main.size-8(sp)                # control link
  addi fp, sp, @..main.size                # New fp is at old SP.
  jal initchars                            # Initialize one-character strings.
  li a0, 1                                 # Load integer literal 1
  sw a0, -12(fp)                           # Push argument 1 from last.
  li a0, 1                                 # Pass list length
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal conslist                             # Move values to new list object
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  sw a0, $a, t0                            # Assign global: a (using tmp register)
  li a0, 1                                 # Load integer literal 1
  sw a0, -12(fp)                           # Push argument 1 from last.
  li a0, 1                                 # Pass list length
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal conslist                             # Move values to new list object
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  sw a0, $b, t0                            # Assign global: b (using tmp register)
  la a0, const_2                           # Load string literal
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal $str_to_int                          # Invoke function: str_to_int
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  sw a0, $k, t0                            # Assign global: k (using tmp register)
  j label_2                                # Jump to loop test
label_1:                                   # Top of while loop
  la t0, noconv                            # Identity conversion
  sw t0, -20(fp)                           # Push argument 3 from last.
  la t0, noconv                            # Identity conversion
  sw t0, -24(fp)                           # Push argument 2 from last.
  lw a0, $a                                # Load global: a
  sw a0, -28(fp)                           # Push argument 1 from last.
  lw a0, $a                                # Load global: a
  sw a0, -32(fp)                           # Push argument 0 from last.
  addi sp, fp, -32                         # Set SP to last argument.
  jal concat                               # Call runtime concatenation routine.
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  sw a0, $a, t0                            # Assign global: a (using tmp register)
  la t0, noconv                            # Identity conversion
  sw t0, -20(fp)                           # Push argument 3 from last.
  la t0, noconv                            # Identity conversion
  sw t0, -24(fp)                           # Push argument 2 from last.
  lw a0, $b                                # Load global: b
  sw a0, -28(fp)                           # Push argument 1 from last.
  lw a0, $b                                # Load global: b
  sw a0, -32(fp)                           # Push argument 0 from last.
  addi sp, fp, -32                         # Set SP to last argument.
  jal concat                               # Call runtime concatenation routine.
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  sw a0, $b, t0                            # Assign global: b (using tmp register)
  lw a0, $i                                # Load global: i
  sw a0, -12(fp)                           # Push on stack slot 3
  li a0, 1                                 # Load integer literal 1
  lw t0, -12(fp)                           # Pop stack slot 3
  add a0, t0, a0                           # Operator +
  sw a0, $i, t0                            # Assign global: i (using tmp register)
label_2:                                   # Test loop condition
  lw a0, $i                                # Load global: i
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, $k                                # Load global: k
  lw t0, -12(fp)                           # Pop stack slot 3
  blt t0, a0, label_1                      # Branch on <
  li a0, 0                                 # Load integer literal 0
  sw a0, $i, t0                            # Assign global: i (using tmp register)
  li a0, 2                                 # Load integer literal 2
  sw a0, -12(fp)                           # Push argument 1 from last.
  lw a0, $k                                # Load global: k
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal $pow                                 # Invoke function: pow
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  sw a0, $l, t0                            # Assign global: l (using tmp register)
  j label_4                                # Jump to loop test
label_3:                                   # Top of while loop
  j label_6                                # Jump to loop test
label_5:                                   # Top of while loop
  lw a0, $a                                # Load global: a
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, $j                                # Load global: j
  lw a1, -12(fp)                           # Pop stack slot 3
  bnez a1, label_7                         # Ensure not None
  j error.None                             # Go to error handler
label_7:                                   # Not None
  lw t0, 12(a1)                            # Load attribute: __len__
  bltu a0, t0, label_8                     # Ensure 0 <= index < len
  j error.OOB                              # Go to error handler
label_8:                                   # Index within bounds
  addi a0, a0, 4                           # Compute list element offset in words
  li t0, 4                                 # Word size in bytes
  mul a0, a0, t0                           # Compute list element offset in bytes
  add a0, a1, a0                           # Pointer to list element
  lw a0, 0(a0)                             # Get list element
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, $b                                # Load global: b
  sw a0, -16(fp)                           # Push on stack slot 4
  lw a0, $j                                # Load global: j
  lw a1, -16(fp)                           # Pop stack slot 4
  bnez a1, label_9                         # Ensure not None
  j error.None                             # Go to error handler
label_9:                                   # Not None
  lw t0, 12(a1)                            # Load attribute: __len__
  bltu a0, t0, label_10                    # Ensure 0 <= index < len
  j error.OOB                              # Go to error handler
label_10:                                  # Index within bounds
  addi a0, a0, 4                           # Compute list element offset in words
  li t0, 4                                 # Word size in bytes
  mul a0, a0, t0                           # Compute list element offset in bytes
  add a0, a1, a0                           # Pointer to list element
  lw a0, 0(a0)                             # Get list element
  lw t0, -12(fp)                           # Pop stack slot 3
  add a0, t0, a0                           # Operator +
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, $j                                # Load global: j
  lw t0, -12(fp)                           # Pop stack slot 3
  add a0, t0, a0                           # Operator +
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, $a                                # Load global: a
  sw a0, -16(fp)                           # Push on stack slot 4
  lw a0, $j                                # Load global: j
  lw t0, -16(fp)                           # Pop stack slot 4
  lw t1, -12(fp)                           # Pop stack slot 3
  bnez t0, label_11                        # Ensure not None
  j error.None                             # Go to error handler
label_11:                                  # Not None
  lw t2, 12(t0)                            # Load attribute: __len__
  bltu a0, t2, label_12                    # Ensure 0 <= index < len
  j error.OOB                              # Go to error handler
label_12:                                  # Index within bounds
  addi a0, a0, 4                           # Compute list element offset in words
  li t2, 4                                 # Word size in bytes
  mul a0, a0, t2                           # Compute list element offset in bytes
  add a0, t0, a0                           # Pointer to list element
  sw t1, 0(a0)                             # Set list element
  lw a0, $j                                # Load global: j
  sw a0, -12(fp)                           # Push on stack slot 3
  li a0, 1                                 # Load integer literal 1
  lw t0, -12(fp)                           # Pop stack slot 3
  add a0, t0, a0                           # Operator +
  sw a0, $j, t0                            # Assign global: j (using tmp register)
label_6:                                   # Test loop condition
  lw a0, $j                                # Load global: j
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, $l                                # Load global: l
  lw t0, -12(fp)                           # Pop stack slot 3
  blt t0, a0, label_5                      # Branch on <
  lw a0, $i                                # Load global: i
  sw a0, -12(fp)                           # Push on stack slot 3
  li a0, 1                                 # Load integer literal 1
  lw t0, -12(fp)                           # Pop stack slot 3
  add a0, t0, a0                           # Operator +
  sw a0, $i, t0                            # Assign global: i (using tmp register)
label_4:                                   # Test loop condition
  lw a0, $i                                # Load global: i
  sw a0, -12(fp)                           # Push on stack slot 3
  li a0, 10                                # Load integer literal 10
  lw t0, -12(fp)                           # Pop stack slot 3
  blt t0, a0, label_3                      # Branch on <
  lw a0, $a                                # Load global: a
  sw a0, -20(fp)                           # Push on stack slot 5
  lw a0, $l                                # Load global: l
  sw a0, -24(fp)                           # Push on stack slot 6
  li a0, 1                                 # Load integer literal 1
  lw t0, -24(fp)                           # Pop stack slot 6
  sub a0, t0, a0                           # Operator -
  lw a1, -20(fp)                           # Pop stack slot 5
  bnez a1, label_13                        # Ensure not None
  j error.None                             # Go to error handler
label_13:                                  # Not None
  lw t0, 12(a1)                            # Load attribute: __len__
  bltu a0, t0, label_14                    # Ensure 0 <= index < len
  j error.OOB                              # Go to error handler
label_14:                                  # Index within bounds
  addi a0, a0, 4                           # Compute list element offset in words
  li t0, 4                                 # Word size in bytes
  mul a0, a0, t0                           # Compute list element offset in bytes
  add a0, a1, a0                           # Pointer to list element
  lw a0, 0(a0)                             # Get list element
  jal makeint                              # Box integer
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal $print                               # Invoke function: print
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  .equiv @..main.size, 32
label_0:                                   # End of program
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
  la a1, const_3                           # Load error message as str
  addi a1, a1, @.__str__                   # Load address of attribute __str__
  j abort                                  # Abort

# Printing bools
print_9:                                   # Print bool object in A0
  lw a0, @.__bool__(a0)                    # Load attribute __bool__
  beq a0, zero, print_10                   # Go to: print(False)
  la a0, const_4                           # String representation: True
  j print_8                                # Go to: print(str)
print_10:                                  # Print False object in A0
  la a0, const_5                           # String representation: False
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
  la a1, const_3                           # Load error message as str
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

.globl $str_to_int
$str_to_int:
  addi sp, sp, -@str_to_int.size           # Reserve space for stack frame.
  sw ra, @str_to_int.size-4(sp)            # return address
  sw fp, @str_to_int.size-8(sp)            # control link
  addi fp, sp, @str_to_int.size            # New fp is at old SP.
  li a0, 0                                 # Load integer literal 0
  sw a0, -12(fp)                           # local variable result
  li a0, 0                                 # Load integer literal 0
  sw a0, -16(fp)                           # local variable digit
  la a0, const_6                           # Load string literal
  sw a0, -20(fp)                           # local variable char
  li a0, 1                                 # Load integer literal 1
  sw a0, -24(fp)                           # local variable sign
  li a0, 1                                 # Load boolean literal: true
  sw a0, -28(fp)                           # local variable first_char
  li a0, 0                                 # Load integer literal 0
  sw a0, -32(fp)                           # local variable i
  j label_18                               # Jump to loop test
label_17:                                  # Top of while loop
  lw a0, 0(fp)                             # Load var: str_to_int.string
  sw a0, -36(fp)                           # Push on stack slot 9
  lw a0, -32(fp)                           # Load var: str_to_int.i
  lw a1, -36(fp)                           # Peek stack slot 8
  lw t0, 12(a1)                            # Load attribute: __len__
  bltu a0, t0, label_19                    # Ensure 0 <= idx < len
  j error.OOB                              # Go to error handler
label_19:                                  # Index within bounds
  sw a0, -40(fp)                           # Push on stack slot 10
  lw t0, -40(fp)                           # Pop stack slot 10
  lw a1, -36(fp)                           # Peek stack slot 8
  addi t0, t0, 16                          # Convert index to offset to char in bytes
  add t0, a1, t0                           # Get pointer to char
  lbu t0, 0(t0)                            # Load character
  li t1, 20
  mul t0, t0, t1                           # Multiply by size of string object
  la a0, allChars                          # Index into single-char table
  add a0, a0, t0
  sw a0, -20(fp)                           # Assign var: str_to_int.char
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_7                           # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_21                        # Branch on false.
  lw a0, -28(fp)                           # Load var: str_to_int.first_char
  bnez a0, label_22                        # Branch on true.
  la a0, const_8                           # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal $print                               # Invoke function: print
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  li a0, 0                                 # Load integer literal 0
  j label_16                               # Go to return
label_22:                                  # End of if-else statement
  li a0, 1                                 # Load integer literal 1
  sub a0, zero, a0                         # Unary negation
  sw a0, -24(fp)                           # Assign var: str_to_int.sign
  j label_20                               # Then body complete; jump to end-if
label_21:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_9                           # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_24                        # Branch on false.
  li a0, 0                                 # Load integer literal 0
  sw a0, -16(fp)                           # Assign var: str_to_int.digit
  j label_23                               # Then body complete; jump to end-if
label_24:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_10                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_26                        # Branch on false.
  li a0, 1                                 # Load integer literal 1
  sw a0, -16(fp)                           # Assign var: str_to_int.digit
  j label_25                               # Then body complete; jump to end-if
label_26:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_11                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_28                        # Branch on false.
  li a0, 2                                 # Load integer literal 2
  sw a0, -16(fp)                           # Assign var: str_to_int.digit
  j label_27                               # Then body complete; jump to end-if
label_28:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_12                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_30                        # Branch on false.
  li a0, 3                                 # Load integer literal 3
  sw a0, -16(fp)                           # Assign var: str_to_int.digit
  j label_29                               # Then body complete; jump to end-if
label_30:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_12                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_32                        # Branch on false.
  li a0, 3                                 # Load integer literal 3
  sw a0, -16(fp)                           # Assign var: str_to_int.digit
  j label_31                               # Then body complete; jump to end-if
label_32:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_13                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_34                        # Branch on false.
  li a0, 4                                 # Load integer literal 4
  sw a0, -16(fp)                           # Assign var: str_to_int.digit
  j label_33                               # Then body complete; jump to end-if
label_34:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_14                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_36                        # Branch on false.
  li a0, 5                                 # Load integer literal 5
  sw a0, -16(fp)                           # Assign var: str_to_int.digit
  j label_35                               # Then body complete; jump to end-if
label_36:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_15                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_38                        # Branch on false.
  li a0, 6                                 # Load integer literal 6
  sw a0, -16(fp)                           # Assign var: str_to_int.digit
  j label_37                               # Then body complete; jump to end-if
label_38:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_16                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_40                        # Branch on false.
  li a0, 7                                 # Load integer literal 7
  sw a0, -16(fp)                           # Assign var: str_to_int.digit
  j label_39                               # Then body complete; jump to end-if
label_40:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_17                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_42                        # Branch on false.
  li a0, 8                                 # Load integer literal 8
  sw a0, -16(fp)                           # Assign var: str_to_int.digit
  j label_41                               # Then body complete; jump to end-if
label_42:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_18                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_44                        # Branch on false.
  li a0, 9                                 # Load integer literal 9
  sw a0, -16(fp)                           # Assign var: str_to_int.digit
  j label_43                               # Then body complete; jump to end-if
label_44:                                  # Else body
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_19                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  bnez a0, label_47                        # Branch on true.
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_20                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  bnez a0, label_47                        # Branch on true.
  lw a0, -20(fp)                           # Load var: str_to_int.char
  sw a0, -44(fp)                           # Push argument 1 from last.
  la a0, const_21                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal streql                               # Call string == function
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  beqz a0, label_46                        # Branch on false.
label_47::
  lw a0, -12(fp)                           # Load var: str_to_int.result
  sw a0, -36(fp)                           # Push on stack slot 9
  lw a0, -24(fp)                           # Load var: str_to_int.sign
  lw t0, -36(fp)                           # Pop stack slot 9
  mul a0, t0, a0                           # Operator *
  j label_16                               # Go to return
  j label_45                               # Then body complete; jump to end-if
label_46:                                  # Else body
  la a0, const_22                          # Load string literal
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal $print                               # Invoke function: print
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  li a0, 0                                 # Load integer literal 0
  j label_16                               # Go to return
label_45:                                  # End of if-else statement
label_43:                                  # End of if-else statement
label_41:                                  # End of if-else statement
label_39:                                  # End of if-else statement
label_37:                                  # End of if-else statement
label_35:                                  # End of if-else statement
label_33:                                  # End of if-else statement
label_31:                                  # End of if-else statement
label_29:                                  # End of if-else statement
label_27:                                  # End of if-else statement
label_25:                                  # End of if-else statement
label_23:                                  # End of if-else statement
label_20:                                  # End of if-else statement
  li a0, 0                                 # Load boolean literal: false
  sw a0, -28(fp)                           # Assign var: str_to_int.first_char
  lw a0, -32(fp)                           # Load var: str_to_int.i
  sw a0, -36(fp)                           # Push on stack slot 9
  li a0, 1                                 # Load integer literal 1
  lw t0, -36(fp)                           # Pop stack slot 9
  add a0, t0, a0                           # Operator +
  sw a0, -32(fp)                           # Assign var: str_to_int.i
  lw a0, -12(fp)                           # Load var: str_to_int.result
  sw a0, -36(fp)                           # Push on stack slot 9
  li a0, 10                                # Load integer literal 10
  lw t0, -36(fp)                           # Pop stack slot 9
  mul a0, t0, a0                           # Operator *
  sw a0, -36(fp)                           # Push on stack slot 9
  lw a0, -16(fp)                           # Load var: str_to_int.digit
  lw t0, -36(fp)                           # Pop stack slot 9
  add a0, t0, a0                           # Operator +
  sw a0, -12(fp)                           # Assign var: str_to_int.result
label_18:                                  # Test loop condition
  lw a0, -32(fp)                           # Load var: str_to_int.i
  sw a0, -36(fp)                           # Push on stack slot 9
  lw a0, 0(fp)                             # Load var: str_to_int.string
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal $len                                 # Invoke function: len
  addi sp, fp, -@str_to_int.size           # Set SP to stack frame top.
  lw t0, -36(fp)                           # Pop stack slot 9
  blt t0, a0, label_17                     # Branch on <
  lw a0, -12(fp)                           # Load var: str_to_int.result
  sw a0, -36(fp)                           # Push on stack slot 9
  lw a0, -24(fp)                           # Load var: str_to_int.sign
  lw t0, -36(fp)                           # Pop stack slot 9
  mul a0, t0, a0                           # Operator *
  j label_16                               # Go to return
  mv a0, zero                              # Load None
  j label_16                               # Jump to function epilogue
label_16:                                  # Epilogue
  .equiv @str_to_int.size, 48
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @str_to_int.size            # Restore stack pointer
  jr ra                                    # Return to caller

.globl $pow
$pow:
  addi sp, sp, -@pow.size                  # Reserve space for stack frame.
  sw ra, @pow.size-4(sp)                   # return address
  sw fp, @pow.size-8(sp)                   # control link
  addi fp, sp, @pow.size                   # New fp is at old SP.
  li a0, 1                                 # Load integer literal 1
  sw a0, -12(fp)                           # local variable result
  li a0, 0                                 # Load integer literal 0
  sw a0, -16(fp)                           # local variable i
  j label_51                               # Jump to loop test
label_50:                                  # Top of while loop
  lw a0, -12(fp)                           # Load var: pow.result
  sw a0, -20(fp)                           # Push on stack slot 5
  lw a0, 4(fp)                             # Load var: pow.base
  lw t0, -20(fp)                           # Pop stack slot 5
  mul a0, t0, a0                           # Operator *
  sw a0, -12(fp)                           # Assign var: pow.result
  lw a0, -16(fp)                           # Load var: pow.i
  sw a0, -20(fp)                           # Push on stack slot 5
  li a0, 1                                 # Load integer literal 1
  lw t0, -20(fp)                           # Pop stack slot 5
  add a0, t0, a0                           # Operator +
  sw a0, -16(fp)                           # Assign var: pow.i
label_51:                                  # Test loop condition
  lw a0, -16(fp)                           # Load var: pow.i
  sw a0, -20(fp)                           # Push on stack slot 5
  lw a0, 0(fp)                             # Load var: pow.exp
  lw t0, -20(fp)                           # Pop stack slot 5
  blt t0, a0, label_50                     # Branch on <
  lw a0, -12(fp)                           # Load var: pow.result
  j label_49                               # Go to return
  mv a0, zero                              # Load None
  j label_49                               # Jump to function epilogue
label_49:                                  # Epilogue
  .equiv @pow.size, 32
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @pow.size                   # Restore stack pointer
  jr ra                                    # Return to caller

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
  la a1, const_23                          # Load error message as str
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

.globl concat
concat:

        addi sp, sp, -32
        sw ra, 28(sp)
        sw fp, 24(sp)
        addi fp, sp, 32
	sw s1, -12(fp)
        sw s2, -16(fp)
        sw s3, -20(fp)
	sw s4, -24(fp)
        sw s5, -28(fp)
        lw t0, 4(fp)
        lw t1, 0(fp)
        beqz t0, concat_none
        beqz t1, concat_none
        lw t0, @.__len__(t0)
        lw t1, @.__len__(t1)
        add s5, t0, t1
        addi a1, s5, @listHeaderWords
        la a0, $.list$prototype
        jal alloc2
        sw s5, @.__len__(a0)
	mv s5, a0
        addi s3, s5, @.__elts__
        lw s1, 4(fp)
	lw s2, @.__len__(s1)
        addi s1, s1, @.__elts__
	lw s4, 12(fp)
concat_1:
        beqz s2, concat_2
        lw a0, 0(s1)
	jalr ra, s4, 0
        sw a0, 0(s3)
        addi s2, s2, -1
        addi s1, s1, 4
        addi s3, s3, 4
        j concat_1
concat_2:
        lw s1, 0(fp)
        lw s2, @.__len__(s1)
        addi s1, s1, @.__elts__
	lw s4, 8(fp)
concat_3:
        beqz s2, concat_4
        lw a0, 0(s1)
	jalr ra, s4, 0
        sw a0, 0(s3)
        addi s2, s2, -1
        addi s1, s1, 4
        addi s3, s3, 4
        j concat_3
concat_4:
	mv a0, s5
        lw s1, -12(fp)
        lw s2, -16(fp)
        lw s3, -20(fp)
	lw s4, -24(fp)
        lw s5, -28(fp)
        lw ra, -4(fp)
        lw fp, -8(fp)
        addi sp, sp, 32
        jr ra
concat_none:
        j error.None


.globl conslist
conslist:

        addi sp, sp, -8
        sw ra, 4(sp)
        sw fp, 0(sp)
        addi fp, sp, 8
        lw a1, 0(fp)
        la a0, $.list$prototype
        beqz a1, conslist_done
        addi a1, a1, @listHeaderWords
        jal alloc2
        lw t0, 0(fp)
        sw t0, @.__len__(a0)
        slli t1, t0, 2
        add t1, t1, fp
        addi t2, a0, @.__elts__
conslist_1:
        lw t3, 0(t1)
        sw t3, 0(t2)
        addi t1, t1, -4
        addi t2, t2, 4
        addi t0, t0, -1
        bnez t0, conslist_1
conslist_done:
        lw ra, -4(fp)
        lw fp, -8(fp)
        addi sp, sp, 8
        jr ra


.globl strcat
strcat:

        addi sp, sp, -12
        sw ra, 8(sp)
        sw fp, 4(sp)
        addi fp, sp, 12
        lw t0, 4(fp)
        lw t1, 0(fp)
        lw t0, @.__len__(t0)
        beqz t0, strcat_4
        lw t1, @.__len__(t1)
        beqz t1, strcat_5
        add t1, t0, t1
        sw t1, -12(fp)
        addi t1, t1, 4
        srli t1, t1, 2
        addi a1, t1, @listHeaderWords
        la a0, $str$prototype
        jal alloc2
        lw t0, -12(fp)
        sw t0, @.__len__(a0)
        addi t2, a0, 16
        lw t0, 4(fp)
        lw t1, @.__len__(t0)
        addi t0, t0, @.__str__
strcat_1:
        beqz t1, strcat_2
        lbu t3, 0(t0)
        sb t3, 0(t2)
        addi t1, t1, -1
        addi t0, t0, 1
        addi t2, t2, 1
        j strcat_1
strcat_2:
        lw t0, 0(fp)
        lw t1, 12(t0)
        addi t0, t0, 16
strcat_3:
        beqz t1, strcat_6
        lbu t3, 0(t0)
        sb t3, 0(t2)
        addi t1, t1, -1
        addi t0, t0, 1
        addi t2, t2, 1
        j strcat_3
strcat_4:
        lw a0, 0(fp)
        j strcat_7
strcat_5:
        lw a0, 4(fp)
        j strcat_7
strcat_6:
        sb zero, 0(t2)
strcat_7:
        lw ra, -4(fp)
        lw fp, -8(fp)
        addi sp, sp, 12
        jr ra


.globl streql
streql:

        addi sp, sp, -8
        sw ra, 4(sp)
        sw fp, 0(sp)
        addi fp, sp, 8
        lw a1, 4(fp)
        lw a2, 0(fp)
        lw t0, @.__len__(a1)
        lw t1, @.__len__(a2)
        bne t0, t1, streql_no
streql_1:
        lbu t2, @.__str__(a1)
        lbu t3, @.__str__(a2)
        bne t2, t3, streql_no
        addi a1, a1, 1
        addi a2, a2, 1
        addi t0, t0, -1
        bgtz t0, streql_1
        li a0, 1
        j streql_end
streql_no:
        xor a0, a0, a0
streql_end:
        lw ra, -4(fp)
        lw fp, -8(fp)
        addi sp, sp, 8
        jr ra


.globl strneql
strneql:

        addi sp, sp, -8
        sw ra, 4(sp)
        sw fp, 0(sp)
        addi fp, sp, 8
        lw a1, 4(fp)
        lw a2, 0(fp)
        lw t0, @.__len__(a1)
        lw t1, @.__len__(a2)
        bne t0, t1, strneql_yes
strneql_1:
        lbu t2, @.__str__(a1)
        lbu t3, @.__str__(a2)
        bne t2, t3, strneql_yes
        addi a1, a1, 1
        addi a2, a2, 1
        addi t0, t0, -1
        bgtz t0, strneql_1
        xor a0, a0, a0
        j strneql_end
strneql_yes:
        li a0, 1
strneql_end:
        lw ra, -4(fp)
        lw fp, -8(fp)
        addi sp, sp, 8
        jr ra


.globl makeint
makeint:

        addi sp, sp, -8
        sw ra, 4(sp)
        sw a0, 0(sp)
        la a0, $int$prototype
        jal ra, alloc
        lw t0, 0(sp)
        sw t0, @.__int__(a0)
        lw ra, 4(sp)
        addi sp, sp, 8
        jr ra


.globl makebool
makebool:

	slli a0, a0, 4
        la t0, @bool.False
        add a0, a0, t0
	jr ra


.globl noconv
noconv:

        jr ra


.globl initchars
initchars:

        la a0, $str$prototype
        lw t0, 0(a0)
        lw t1, 4(a0)
        lw t2, 8(a0)
        li t3, 1
        la a0, allChars
        li t4, 256
        mv t5, zero
initchars_1:
        sw t0, 0(a0)
        sw t1, 4(a0)
        sw t2, 8(a0)
        sw t3, 12(a0)
        sw t5, 16(a0)
        addi a0, a0, 20
        addi t5, t5, 1
        bne t4, t5, initchars_1
        jr  ra
        .data
        .align 2
        .globl allChars
allChars:
        .space 5120
        .text


.globl error.None
error.None:
  li a0, 4                                 # Exit code for: Operation on None
  la a1, const_24                          # Load error message as str
  addi a1, a1, 16                          # Load address of attribute __str__
  j abort                                  # Abort

.globl error.Div
error.Div:
  li a0, 2                                 # Exit code for: Division by zero
  la a1, const_25                          # Load error message as str
  addi a1, a1, 16                          # Load address of attribute __str__
  j abort                                  # Abort

.globl error.OOB
error.OOB:
  li a0, 3                                 # Exit code for: Index out of bounds
  la a1, const_26                          # Load error message as str
  addi a1, a1, 16                          # Load address of attribute __str__
  j abort                                  # Abort

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

.globl const_6
const_6:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 0                                  # Constant value of attribute: __len__
  .string ""                               # Constant value of attribute: __str__
  .align 2

.globl const_8
const_8:
  .word 3                                  # Type tag for class: str
  .word 16                                 # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 47                                 # Constant value of attribute: __len__
  .string "Error: Negative sign not at beginning of string" # Constant value of attribute: __str__
  .align 2

.globl const_4
const_4:
  .word 3                                  # Type tag for class: str
  .word 6                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 4                                  # Constant value of attribute: __len__
  .string "True"                           # Constant value of attribute: __str__
  .align 2

.globl const_21
const_21:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "\t"                             # Constant value of attribute: __str__
  .align 2

.globl const_20
const_20:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "\n"                             # Constant value of attribute: __str__
  .align 2

.globl const_5
const_5:
  .word 3                                  # Type tag for class: str
  .word 6                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 5                                  # Constant value of attribute: __len__
  .string "False"                          # Constant value of attribute: __str__
  .align 2

.globl const_22
const_22:
  .word 3                                  # Type tag for class: str
  .word 13                                 # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 34                                 # Constant value of attribute: __len__
  .string "Error: Invalid character in string" # Constant value of attribute: __str__
  .align 2

.globl const_26
const_26:
  .word 3                                  # Type tag for class: str
  .word 9                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 19                                 # Constant value of attribute: __len__
  .string "Index out of bounds"            # Constant value of attribute: __str__
  .align 2

.globl const_3
const_3:
  .word 3                                  # Type tag for class: str
  .word 9                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 16                                 # Constant value of attribute: __len__
  .string "Invalid argument"               # Constant value of attribute: __str__
  .align 2

.globl const_19
const_19:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string " "                              # Constant value of attribute: __str__
  .align 2

.globl const_23
const_23:
  .word 3                                  # Type tag for class: str
  .word 8                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 13                                 # Constant value of attribute: __len__
  .string "Out of memory"                  # Constant value of attribute: __str__
  .align 2

.globl const_2
const_2:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 3                                  # Constant value of attribute: __len__
  .string "33\n"                           # Constant value of attribute: __str__
  .align 2

.globl const_7
const_7:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "-"                              # Constant value of attribute: __str__
  .align 2

.globl const_9
const_9:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "0"                              # Constant value of attribute: __str__
  .align 2

.globl const_10
const_10:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "1"                              # Constant value of attribute: __str__
  .align 2

.globl const_25
const_25:
  .word 3                                  # Type tag for class: str
  .word 9                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 16                                 # Constant value of attribute: __len__
  .string "Division by zero"               # Constant value of attribute: __str__
  .align 2

.globl const_11
const_11:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "2"                              # Constant value of attribute: __str__
  .align 2

.globl const_12
const_12:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "3"                              # Constant value of attribute: __str__
  .align 2

.globl const_13
const_13:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "4"                              # Constant value of attribute: __str__
  .align 2

.globl const_14
const_14:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "5"                              # Constant value of attribute: __str__
  .align 2

.globl const_15
const_15:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "6"                              # Constant value of attribute: __str__
  .align 2

.globl const_16
const_16:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "7"                              # Constant value of attribute: __str__
  .align 2

.globl const_17
const_17:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "8"                              # Constant value of attribute: __str__
  .align 2

.globl const_18
const_18:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 1                                  # Constant value of attribute: __len__
  .string "9"                              # Constant value of attribute: __str__
  .align 2

.globl const_24
const_24:
  .word 3                                  # Type tag for class: str
  .word 9                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 17                                 # Constant value of attribute: __len__
  .string "Operation on None"              # Constant value of attribute: __str__
  .align 2
