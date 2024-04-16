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

.globl $Vector$prototype
$Vector$prototype:
  .word 4                                  # Type tag for class: Vector
  .word 5                                  # Object size
  .word $Vector$dispatchTable              # Pointer to dispatch table
  .word 0                                  # Initial value of attribute: items
  .word 0                                  # Initial value of attribute: size
  .align 2

.globl $DoublingVector$prototype
$DoublingVector$prototype:
  .word 5                                  # Type tag for class: DoublingVector
  .word 6                                  # Object size
  .word $DoublingVector$dispatchTable      # Pointer to dispatch table
  .word 0                                  # Initial value of attribute: items
  .word 0                                  # Initial value of attribute: size
  .word 1000                               # Initial value of attribute: doubling_limit
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

.globl $Vector$dispatchTable
$Vector$dispatchTable:
  .word $Vector.__init__                   # Implementation for method: Vector.__init__
  .word $Vector.capacity                   # Implementation for method: Vector.capacity
  .word $Vector.increase_capacity          # Implementation for method: Vector.increase_capacity
  .word $Vector.append                     # Implementation for method: Vector.append
  .word $Vector.append_all                 # Implementation for method: Vector.append_all
  .word $Vector.remove_at                  # Implementation for method: Vector.remove_at
  .word $Vector.get                        # Implementation for method: Vector.get
  .word $Vector.length                     # Implementation for method: Vector.length

.globl $DoublingVector$dispatchTable
$DoublingVector$dispatchTable:
  .word $Vector.__init__                   # Implementation for method: DoublingVector.__init__
  .word $Vector.capacity                   # Implementation for method: DoublingVector.capacity
  .word $DoublingVector.increase_capacity  # Implementation for method: DoublingVector.increase_capacity
  .word $Vector.append                     # Implementation for method: DoublingVector.append
  .word $Vector.append_all                 # Implementation for method: DoublingVector.append_all
  .word $Vector.remove_at                  # Implementation for method: DoublingVector.remove_at
  .word $Vector.get                        # Implementation for method: DoublingVector.get
  .word $Vector.length                     # Implementation for method: DoublingVector.length

.globl $n
$n:
  .word 50                                 # Initial value of global var: n

.globl $v
$v:
  .word 0                                  # Initial value of global var: v

.globl $i
$i:
  .word 0                                  # Initial value of global var: i

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
  li a0, 2                                 # Load integer literal 2
  sw a0, -12(fp)                           # Push argument 1 from last.
  lw a0, $n                                # Load global: n
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal $vrange                              # Invoke function: vrange
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  sw a0, $v, t0                            # Assign global: v (using tmp register)
  lw a0, $v                                # Load global: v
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal $sieve                               # Invoke function: sieve
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  j label_2                                # Jump to loop test
label_1:                                   # Top of while loop
  lw a0, $v                                # Load global: v
  bnez a0, label_3                         # Ensure not None
  j error.None                             # Go to error handler
label_3:                                   # Not None
  sw a0, -28(fp)                           # Push argument 1 from last.
  lw a0, $i                                # Load global: i
  sw a0, -32(fp)                           # Push argument 0 from last.
  lw a0, -28(fp)                           # Peek stack slot 6
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 24(a1)                            # Load address of method: Vector.get
  addi sp, fp, -32                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.get
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  jal makeint                              # Box integer
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal $print                               # Invoke function: print
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  lw a0, $i                                # Load global: i
  sw a0, -12(fp)                           # Push on stack slot 3
  li a0, 1                                 # Load integer literal 1
  lw t0, -12(fp)                           # Pop stack slot 3
  add a0, t0, a0                           # Operator +
  sw a0, $i, t0                            # Assign global: i (using tmp register)
label_2:                                   # Test loop condition
  lw a0, $i                                # Load global: i
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, $v                                # Load global: v
  bnez a0, label_4                         # Ensure not None
  j error.None                             # Go to error handler
label_4:                                   # Not None
  sw a0, -16(fp)                           # Push argument 0 from last.
  lw a0, -16(fp)                           # Peek stack slot 3
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 28(a1)                            # Load address of method: Vector.length
  addi sp, fp, -16                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.length
  addi sp, fp, -@..main.size               # Set SP to stack frame top.
  lw t0, -12(fp)                           # Pop stack slot 3
  blt t0, a0, label_1                      # Branch on <
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

.globl $Vector.__init__
$Vector.__init__:
  addi sp, sp, -@Vector.__init__.size      # Reserve space for stack frame.
  sw ra, @Vector.__init__.size-4(sp)       # return address
  sw fp, @Vector.__init__.size-8(sp)       # control link
  addi fp, sp, @Vector.__init__.size       # New fp is at old SP.
  li a0, 0                                 # Load integer literal 0
  sw a0, -12(fp)                           # Push argument 1 from last.
  li a0, 1                                 # Pass list length
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal conslist                             # Move values to new list object
  addi sp, fp, -@Vector.__init__.size      # Set SP to stack frame top.
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 0(fp)                             # Load var: Vector.__init__.self
  mv a1, a0                                # Move object
  lw a0, -12(fp)                           # Pop stack slot 3
  bnez a1, label_7                         # Ensure not None
  j error.None                             # Go to error handler
label_7:                                   # Not None
  sw a0, 12(a1)                            # Set attribute: Vector.items
  mv a0, zero                              # Load None
  j label_6                                # Jump to function epilogue
label_6:                                   # Epilogue
  .equiv @Vector.__init__.size, 16
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @Vector.__init__.size       # Restore stack pointer
  jr ra                                    # Return to caller

.globl $Vector.capacity
$Vector.capacity:
  addi sp, sp, -@Vector.capacity.size      # Reserve space for stack frame.
  sw ra, @Vector.capacity.size-4(sp)       # return address
  sw fp, @Vector.capacity.size-8(sp)       # control link
  addi fp, sp, @Vector.capacity.size       # New fp is at old SP.
  lw a0, 0(fp)                             # Load var: Vector.capacity.self
  bnez a0, label_10                        # Ensure not None
  j error.None                             # Go to error handler
label_10:                                  # Not None
  lw a0, 12(a0)                            # Get attribute: Vector.items
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal $len                                 # Invoke function: len
  addi sp, fp, -@Vector.capacity.size      # Set SP to stack frame top.
  j label_9                                # Go to return
  mv a0, zero                              # Load None
  j label_9                                # Jump to function epilogue
label_9:                                   # Epilogue
  .equiv @Vector.capacity.size, 16
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @Vector.capacity.size       # Restore stack pointer
  jr ra                                    # Return to caller

.globl $Vector.increase_capacity
$Vector.increase_capacity:
  addi sp, sp, -@Vector.increase_capacity.size # Reserve space for stack frame.
  sw ra, @Vector.increase_capacity.size-4(sp) # return address
  sw fp, @Vector.increase_capacity.size-8(sp) # control link
  addi fp, sp, @Vector.increase_capacity.size # New fp is at old SP.
  la t0, noconv                            # Identity conversion
  sw t0, -20(fp)                           # Push argument 3 from last.
  la t0, noconv                            # Identity conversion
  sw t0, -24(fp)                           # Push argument 2 from last.
  lw a0, 0(fp)                             # Load var: Vector.increase_capacity.self
  bnez a0, label_13                        # Ensure not None
  j error.None                             # Go to error handler
label_13:                                  # Not None
  lw a0, 12(a0)                            # Get attribute: Vector.items
  sw a0, -28(fp)                           # Push argument 1 from last.
  li a0, 0                                 # Load integer literal 0
  sw a0, -44(fp)                           # Push argument 1 from last.
  li a0, 1                                 # Pass list length
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal conslist                             # Move values to new list object
  addi sp, fp, -@Vector.increase_capacity.size # Set SP to stack frame top.
  sw a0, -32(fp)                           # Push argument 0 from last.
  addi sp, fp, -32                         # Set SP to last argument.
  jal concat                               # Call runtime concatenation routine.
  addi sp, fp, -@Vector.increase_capacity.size # Set SP to stack frame top.
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 0(fp)                             # Load var: Vector.increase_capacity.self
  mv a1, a0                                # Move object
  lw a0, -12(fp)                           # Pop stack slot 3
  bnez a1, label_14                        # Ensure not None
  j error.None                             # Go to error handler
label_14:                                  # Not None
  sw a0, 12(a1)                            # Set attribute: Vector.items
  lw a0, 0(fp)                             # Load var: Vector.increase_capacity.self
  bnez a0, label_15                        # Ensure not None
  j error.None                             # Go to error handler
label_15:                                  # Not None
  sw a0, -16(fp)                           # Push argument 0 from last.
  lw a0, -16(fp)                           # Peek stack slot 3
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 4(a1)                             # Load address of method: Vector.capacity
  addi sp, fp, -16                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.capacity
  addi sp, fp, -@Vector.increase_capacity.size # Set SP to stack frame top.
  j label_12                               # Go to return
  mv a0, zero                              # Load None
  j label_12                               # Jump to function epilogue
label_12:                                  # Epilogue
  .equiv @Vector.increase_capacity.size, 48
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @Vector.increase_capacity.size # Restore stack pointer
  jr ra                                    # Return to caller

.globl $Vector.append
$Vector.append:
  addi sp, sp, -@Vector.append.size        # Reserve space for stack frame.
  sw ra, @Vector.append.size-4(sp)         # return address
  sw fp, @Vector.append.size-8(sp)         # control link
  addi fp, sp, @Vector.append.size         # New fp is at old SP.
  lw a0, 4(fp)                             # Load var: Vector.append.self
  bnez a0, label_19                        # Ensure not None
  j error.None                             # Go to error handler
label_19:                                  # Not None
  lw a0, 16(a0)                            # Get attribute: Vector.size
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 4(fp)                             # Load var: Vector.append.self
  bnez a0, label_20                        # Ensure not None
  j error.None                             # Go to error handler
label_20:                                  # Not None
  sw a0, -16(fp)                           # Push argument 0 from last.
  lw a0, -16(fp)                           # Peek stack slot 3
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 4(a1)                             # Load address of method: Vector.capacity
  addi sp, fp, -16                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.capacity
  addi sp, fp, -@Vector.append.size        # Set SP to stack frame top.
  lw t0, -12(fp)                           # Pop stack slot 3
  bne t0, a0, label_18                     # Branch on not ==
  lw a0, 4(fp)                             # Load var: Vector.append.self
  bnez a0, label_21                        # Ensure not None
  j error.None                             # Go to error handler
label_21:                                  # Not None
  sw a0, -16(fp)                           # Push argument 0 from last.
  lw a0, -16(fp)                           # Peek stack slot 3
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 8(a1)                             # Load address of method: Vector.increase_capacity
  addi sp, fp, -16                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.increase_capacity
  addi sp, fp, -@Vector.append.size        # Set SP to stack frame top.
label_18:                                  # End of if-else statement
  lw a0, 0(fp)                             # Load var: Vector.append.item
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 4(fp)                             # Load var: Vector.append.self
  bnez a0, label_22                        # Ensure not None
  j error.None                             # Go to error handler
label_22:                                  # Not None
  lw a0, 12(a0)                            # Get attribute: Vector.items
  sw a0, -16(fp)                           # Push on stack slot 4
  lw a0, 4(fp)                             # Load var: Vector.append.self
  bnez a0, label_23                        # Ensure not None
  j error.None                             # Go to error handler
label_23:                                  # Not None
  lw a0, 16(a0)                            # Get attribute: Vector.size
  lw t0, -16(fp)                           # Pop stack slot 4
  lw t1, -12(fp)                           # Pop stack slot 3
  bnez t0, label_24                        # Ensure not None
  j error.None                             # Go to error handler
label_24:                                  # Not None
  lw t2, 12(t0)                            # Load attribute: __len__
  bltu a0, t2, label_25                    # Ensure 0 <= index < len
  j error.OOB                              # Go to error handler
label_25:                                  # Index within bounds
  addi a0, a0, 4                           # Compute list element offset in words
  li t2, 4                                 # Word size in bytes
  mul a0, a0, t2                           # Compute list element offset in bytes
  add a0, t0, a0                           # Pointer to list element
  sw t1, 0(a0)                             # Set list element
  lw a0, 4(fp)                             # Load var: Vector.append.self
  bnez a0, label_26                        # Ensure not None
  j error.None                             # Go to error handler
label_26:                                  # Not None
  lw a0, 16(a0)                            # Get attribute: Vector.size
  sw a0, -12(fp)                           # Push on stack slot 3
  li a0, 1                                 # Load integer literal 1
  lw t0, -12(fp)                           # Pop stack slot 3
  add a0, t0, a0                           # Operator +
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 4(fp)                             # Load var: Vector.append.self
  mv a1, a0                                # Move object
  lw a0, -12(fp)                           # Pop stack slot 3
  bnez a1, label_27                        # Ensure not None
  j error.None                             # Go to error handler
label_27:                                  # Not None
  sw a0, 16(a1)                            # Set attribute: Vector.size
  mv a0, zero                              # Load None
  j label_17                               # Jump to function epilogue
label_17:                                  # Epilogue
  .equiv @Vector.append.size, 16
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @Vector.append.size         # Restore stack pointer
  jr ra                                    # Return to caller

.globl $Vector.append_all
$Vector.append_all:
  addi sp, sp, -@Vector.append_all.size    # Reserve space for stack frame.
  sw ra, @Vector.append_all.size-4(sp)     # return address
  sw fp, @Vector.append_all.size-8(sp)     # control link
  addi fp, sp, @Vector.append_all.size     # New fp is at old SP.
  li a0, 0                                 # Load integer literal 0
  sw a0, -12(fp)                           # local variable item
  lw a0, 0(fp)                             # Load var: Vector.append_all.new_items
  bnez a0, label_30                        # Ensure not None
  j error.None                             # Go to error handler
label_30:                                  # Not None
  sw a0, -16(fp)                           # Push on stack slot 4
  mv t1, zero                              # Initialize for-loop index
  sw t1, -20(fp)                           # Push on stack slot 5
label_31:                                  # for-loop header
  lw t1, -20(fp)                           # Pop stack slot 5
  lw t0, -16(fp)                           # Peek stack slot 3
  lw t2, 12(t0)                            # Get attribute __len__
  bgeu t1, t2, label_32                    # Exit loop if idx >= len(iter)
  addi t1, t1, 1                           # Increment idx
  sw t1, -20(fp)                           # Push on stack slot 5
  addi t1, t1, 3                           # Compute list element offset in words
  li t2, 4                                 # Word size in bytes
  mul t1, t1, t2                           # Compute list element offset in bytes
  add t1, t0, t1                           # Pointer to list element
  lw t0, 0(t1)                             # Get list element
  sw t0, -12(fp)                           # Assign var: Vector.append_all.item
  lw a0, 4(fp)                             # Load var: Vector.append_all.self
  bnez a0, label_33                        # Ensure not None
  j error.None                             # Go to error handler
label_33:                                  # Not None
  sw a0, -28(fp)                           # Push argument 1 from last.
  lw a0, -12(fp)                           # Load var: Vector.append_all.item
  sw a0, -32(fp)                           # Push argument 0 from last.
  lw a0, -28(fp)                           # Peek stack slot 6
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 12(a1)                            # Load address of method: Vector.append
  addi sp, fp, -32                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.append
  addi sp, fp, -@Vector.append_all.size    # Set SP to stack frame top.
  j label_31                               # Loop back to header
label_32:                                  # for-loop footer
  mv a0, zero                              # Load None
  j label_29                               # Jump to function epilogue
label_29:                                  # Epilogue
  .equiv @Vector.append_all.size, 32
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @Vector.append_all.size     # Restore stack pointer
  jr ra                                    # Return to caller

.globl $Vector.remove_at
$Vector.remove_at:
  addi sp, sp, -@Vector.remove_at.size     # Reserve space for stack frame.
  sw ra, @Vector.remove_at.size-4(sp)      # return address
  sw fp, @Vector.remove_at.size-8(sp)      # control link
  addi fp, sp, @Vector.remove_at.size      # New fp is at old SP.
  lw a0, 0(fp)                             # Load var: Vector.remove_at.idx
  sw a0, -12(fp)                           # Push on stack slot 3
  li a0, 0                                 # Load integer literal 0
  lw t0, -12(fp)                           # Pop stack slot 3
  bge t0, a0, label_36                     # Branch on not <
  mv a0, zero                              # Returning None implicitly
  j label_35                               # Go to return
label_36:                                  # End of if-else statement
  j label_38                               # Jump to loop test
label_37:                                  # Top of while loop
  lw a0, 4(fp)                             # Load var: Vector.remove_at.self
  bnez a0, label_39                        # Ensure not None
  j error.None                             # Go to error handler
label_39:                                  # Not None
  lw a0, 12(a0)                            # Get attribute: Vector.items
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 0(fp)                             # Load var: Vector.remove_at.idx
  sw a0, -16(fp)                           # Push on stack slot 4
  li a0, 1                                 # Load integer literal 1
  lw t0, -16(fp)                           # Pop stack slot 4
  add a0, t0, a0                           # Operator +
  lw a1, -12(fp)                           # Pop stack slot 3
  bnez a1, label_40                        # Ensure not None
  j error.None                             # Go to error handler
label_40:                                  # Not None
  lw t0, 12(a1)                            # Load attribute: __len__
  bltu a0, t0, label_41                    # Ensure 0 <= index < len
  j error.OOB                              # Go to error handler
label_41:                                  # Index within bounds
  addi a0, a0, 4                           # Compute list element offset in words
  li t0, 4                                 # Word size in bytes
  mul a0, a0, t0                           # Compute list element offset in bytes
  add a0, a1, a0                           # Pointer to list element
  lw a0, 0(a0)                             # Get list element
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 4(fp)                             # Load var: Vector.remove_at.self
  bnez a0, label_42                        # Ensure not None
  j error.None                             # Go to error handler
label_42:                                  # Not None
  lw a0, 12(a0)                            # Get attribute: Vector.items
  sw a0, -16(fp)                           # Push on stack slot 4
  lw a0, 0(fp)                             # Load var: Vector.remove_at.idx
  lw t0, -16(fp)                           # Pop stack slot 4
  lw t1, -12(fp)                           # Pop stack slot 3
  bnez t0, label_43                        # Ensure not None
  j error.None                             # Go to error handler
label_43:                                  # Not None
  lw t2, 12(t0)                            # Load attribute: __len__
  bltu a0, t2, label_44                    # Ensure 0 <= index < len
  j error.OOB                              # Go to error handler
label_44:                                  # Index within bounds
  addi a0, a0, 4                           # Compute list element offset in words
  li t2, 4                                 # Word size in bytes
  mul a0, a0, t2                           # Compute list element offset in bytes
  add a0, t0, a0                           # Pointer to list element
  sw t1, 0(a0)                             # Set list element
  lw a0, 0(fp)                             # Load var: Vector.remove_at.idx
  sw a0, -12(fp)                           # Push on stack slot 3
  li a0, 1                                 # Load integer literal 1
  lw t0, -12(fp)                           # Pop stack slot 3
  add a0, t0, a0                           # Operator +
  sw a0, 0(fp)                             # Assign var: Vector.remove_at.idx
label_38:                                  # Test loop condition
  lw a0, 0(fp)                             # Load var: Vector.remove_at.idx
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 4(fp)                             # Load var: Vector.remove_at.self
  bnez a0, label_45                        # Ensure not None
  j error.None                             # Go to error handler
label_45:                                  # Not None
  lw a0, 16(a0)                            # Get attribute: Vector.size
  sw a0, -16(fp)                           # Push on stack slot 4
  li a0, 1                                 # Load integer literal 1
  lw t0, -16(fp)                           # Pop stack slot 4
  sub a0, t0, a0                           # Operator -
  lw t0, -12(fp)                           # Pop stack slot 3
  blt t0, a0, label_37                     # Branch on <
  lw a0, 4(fp)                             # Load var: Vector.remove_at.self
  bnez a0, label_46                        # Ensure not None
  j error.None                             # Go to error handler
label_46:                                  # Not None
  lw a0, 16(a0)                            # Get attribute: Vector.size
  sw a0, -12(fp)                           # Push on stack slot 3
  li a0, 1                                 # Load integer literal 1
  lw t0, -12(fp)                           # Pop stack slot 3
  sub a0, t0, a0                           # Operator -
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 4(fp)                             # Load var: Vector.remove_at.self
  mv a1, a0                                # Move object
  lw a0, -12(fp)                           # Pop stack slot 3
  bnez a1, label_47                        # Ensure not None
  j error.None                             # Go to error handler
label_47:                                  # Not None
  sw a0, 16(a1)                            # Set attribute: Vector.size
  mv a0, zero                              # Load None
  j label_35                               # Jump to function epilogue
label_35:                                  # Epilogue
  .equiv @Vector.remove_at.size, 16
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @Vector.remove_at.size      # Restore stack pointer
  jr ra                                    # Return to caller

.globl $Vector.get
$Vector.get:
  addi sp, sp, -@Vector.get.size           # Reserve space for stack frame.
  sw ra, @Vector.get.size-4(sp)            # return address
  sw fp, @Vector.get.size-8(sp)            # control link
  addi fp, sp, @Vector.get.size            # New fp is at old SP.
  lw a0, 4(fp)                             # Load var: Vector.get.self
  bnez a0, label_50                        # Ensure not None
  j error.None                             # Go to error handler
label_50:                                  # Not None
  lw a0, 12(a0)                            # Get attribute: Vector.items
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 0(fp)                             # Load var: Vector.get.idx
  lw a1, -12(fp)                           # Pop stack slot 3
  bnez a1, label_51                        # Ensure not None
  j error.None                             # Go to error handler
label_51:                                  # Not None
  lw t0, 12(a1)                            # Load attribute: __len__
  bltu a0, t0, label_52                    # Ensure 0 <= index < len
  j error.OOB                              # Go to error handler
label_52:                                  # Index within bounds
  addi a0, a0, 4                           # Compute list element offset in words
  li t0, 4                                 # Word size in bytes
  mul a0, a0, t0                           # Compute list element offset in bytes
  add a0, a1, a0                           # Pointer to list element
  lw a0, 0(a0)                             # Get list element
  j label_49                               # Go to return
  mv a0, zero                              # Load None
  j label_49                               # Jump to function epilogue
label_49:                                  # Epilogue
  .equiv @Vector.get.size, 16
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @Vector.get.size            # Restore stack pointer
  jr ra                                    # Return to caller

.globl $Vector.length
$Vector.length:
  addi sp, sp, -@Vector.length.size        # Reserve space for stack frame.
  sw ra, @Vector.length.size-4(sp)         # return address
  sw fp, @Vector.length.size-8(sp)         # control link
  addi fp, sp, @Vector.length.size         # New fp is at old SP.
  lw a0, 0(fp)                             # Load var: Vector.length.self
  bnez a0, label_55                        # Ensure not None
  j error.None                             # Go to error handler
label_55:                                  # Not None
  lw a0, 16(a0)                            # Get attribute: Vector.size
  j label_54                               # Go to return
  mv a0, zero                              # Load None
  j label_54                               # Jump to function epilogue
label_54:                                  # Epilogue
  .equiv @Vector.length.size, 16
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @Vector.length.size         # Restore stack pointer
  jr ra                                    # Return to caller

.globl $DoublingVector.increase_capacity
$DoublingVector.increase_capacity:
  addi sp, sp, -@DoublingVector.increase_capacity.size # Reserve space for stack frame.
  sw ra, @DoublingVector.increase_capacity.size-4(sp) # return address
  sw fp, @DoublingVector.increase_capacity.size-8(sp) # control link
  addi fp, sp, @DoublingVector.increase_capacity.size # New fp is at old SP.
  lw a0, 0(fp)                             # Load var: DoublingVector.increase_capacity.self
  bnez a0, label_60                        # Ensure not None
  j error.None                             # Go to error handler
label_60:                                  # Not None
  sw a0, -16(fp)                           # Push argument 0 from last.
  lw a0, -16(fp)                           # Peek stack slot 3
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 4(a1)                             # Load address of method: DoublingVector.capacity
  addi sp, fp, -16                         # Set SP to last argument.
  jalr a1                                  # Invoke method: DoublingVector.capacity
  addi sp, fp, -@DoublingVector.increase_capacity.size # Set SP to stack frame top.
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 0(fp)                             # Load var: DoublingVector.increase_capacity.self
  bnez a0, label_61                        # Ensure not None
  j error.None                             # Go to error handler
label_61:                                  # Not None
  lw a0, 20(a0)                            # Get attribute: DoublingVector.doubling_limit
  sw a0, -16(fp)                           # Push on stack slot 4
  li a0, 2                                 # Load integer literal 2
  lw t0, -16(fp)                           # Pop stack slot 4
  bnez a0, label_62                        # Ensure non-zero divisor
  j error.Div                              # Go to error handler
label_62:                                  # Divisor is non-zero
  xor t2, t0, a0                           # Check for same sign
  bltz t2, label_64                        # If !=, need to adjust left operand
  div a0, t0, a0                           # Operator //
  j label_63
label_64:                                  # Operands have differing signs
  slt t2, zero, a0                         # tmp = 1 if right > 0 else 0
  add t2, t2, t2                           # tmp *= 2
  addi t2, t2, -1                          # tmp = 1 if right>=0 else -1
  add t2, t0, t2                           # Adjust left operand
  div t2, t2, a0                           # Adjusted division, toward 0
  addi a0, t2, -1                          # Complete division when signs !=
label_63:                                  # End of //
  lw t0, -12(fp)                           # Pop stack slot 3
  blt a0, t0, label_59                     # Branch on not <=
  la t0, noconv                            # Identity conversion
  sw t0, -20(fp)                           # Push argument 3 from last.
  la t0, noconv                            # Identity conversion
  sw t0, -24(fp)                           # Push argument 2 from last.
  lw a0, 0(fp)                             # Load var: DoublingVector.increase_capacity.self
  bnez a0, label_65                        # Ensure not None
  j error.None                             # Go to error handler
label_65:                                  # Not None
  lw a0, 12(a0)                            # Get attribute: DoublingVector.items
  sw a0, -28(fp)                           # Push argument 1 from last.
  lw a0, 0(fp)                             # Load var: DoublingVector.increase_capacity.self
  bnez a0, label_66                        # Ensure not None
  j error.None                             # Go to error handler
label_66:                                  # Not None
  lw a0, 12(a0)                            # Get attribute: DoublingVector.items
  sw a0, -32(fp)                           # Push argument 0 from last.
  addi sp, fp, -32                         # Set SP to last argument.
  jal concat                               # Call runtime concatenation routine.
  addi sp, fp, -@DoublingVector.increase_capacity.size # Set SP to stack frame top.
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 0(fp)                             # Load var: DoublingVector.increase_capacity.self
  mv a1, a0                                # Move object
  lw a0, -12(fp)                           # Pop stack slot 3
  bnez a1, label_67                        # Ensure not None
  j error.None                             # Go to error handler
label_67:                                  # Not None
  sw a0, 12(a1)                            # Set attribute: DoublingVector.items
  j label_58                               # Then body complete; jump to end-if
label_59:                                  # Else body
  la t0, noconv                            # Identity conversion
  sw t0, -20(fp)                           # Push argument 3 from last.
  la t0, noconv                            # Identity conversion
  sw t0, -24(fp)                           # Push argument 2 from last.
  lw a0, 0(fp)                             # Load var: DoublingVector.increase_capacity.self
  bnez a0, label_68                        # Ensure not None
  j error.None                             # Go to error handler
label_68:                                  # Not None
  lw a0, 12(a0)                            # Get attribute: DoublingVector.items
  sw a0, -28(fp)                           # Push argument 1 from last.
  li a0, 0                                 # Load integer literal 0
  sw a0, -44(fp)                           # Push argument 1 from last.
  li a0, 1                                 # Pass list length
  sw a0, -48(fp)                           # Push argument 0 from last.
  addi sp, fp, -48                         # Set SP to last argument.
  jal conslist                             # Move values to new list object
  addi sp, fp, -@DoublingVector.increase_capacity.size # Set SP to stack frame top.
  sw a0, -32(fp)                           # Push argument 0 from last.
  addi sp, fp, -32                         # Set SP to last argument.
  jal concat                               # Call runtime concatenation routine.
  addi sp, fp, -@DoublingVector.increase_capacity.size # Set SP to stack frame top.
  sw a0, -12(fp)                           # Push on stack slot 3
  lw a0, 0(fp)                             # Load var: DoublingVector.increase_capacity.self
  mv a1, a0                                # Move object
  lw a0, -12(fp)                           # Pop stack slot 3
  bnez a1, label_69                        # Ensure not None
  j error.None                             # Go to error handler
label_69:                                  # Not None
  sw a0, 12(a1)                            # Set attribute: DoublingVector.items
label_58:                                  # End of if-else statement
  lw a0, 0(fp)                             # Load var: DoublingVector.increase_capacity.self
  bnez a0, label_70                        # Ensure not None
  j error.None                             # Go to error handler
label_70:                                  # Not None
  sw a0, -16(fp)                           # Push argument 0 from last.
  lw a0, -16(fp)                           # Peek stack slot 3
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 4(a1)                             # Load address of method: DoublingVector.capacity
  addi sp, fp, -16                         # Set SP to last argument.
  jalr a1                                  # Invoke method: DoublingVector.capacity
  addi sp, fp, -@DoublingVector.increase_capacity.size # Set SP to stack frame top.
  j label_57                               # Go to return
  mv a0, zero                              # Load None
  j label_57                               # Jump to function epilogue
label_57:                                  # Epilogue
  .equiv @DoublingVector.increase_capacity.size, 48
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @DoublingVector.increase_capacity.size # Restore stack pointer
  jr ra                                    # Return to caller

.globl $vrange
$vrange:
  addi sp, sp, -@vrange.size               # Reserve space for stack frame.
  sw ra, @vrange.size-4(sp)                # return address
  sw fp, @vrange.size-8(sp)                # control link
  addi fp, sp, @vrange.size                # New fp is at old SP.
  mv a0, zero                              # Load None
  sw a0, -12(fp)                           # local variable v
  la a0, const_5                           # Load string literal
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal $print                               # Invoke function: print
  addi sp, fp, -@vrange.size               # Set SP to stack frame top.
  la a0, $DoublingVector$prototype         # Load pointer to prototype of: DoublingVector
  jal alloc                                # Allocate new object in A0
  sw a0, -16(fp)                           # Push on stack slot 4
  sw a0, -32(fp)                           # Push argument 0 from last.
  addi sp, fp, -32                         # Set SP to last argument.
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 0(a1)                             # Load address of method: DoublingVector.__init__
  jalr a1                                  # Invoke method: DoublingVector.__init__
  addi sp, fp, -@vrange.size               # Set SP to stack frame top.
  lw a0, -16(fp)                           # Pop stack slot 4
  sw a0, -12(fp)                           # Assign var: vrange.v
  j label_74                               # Jump to loop test
label_73:                                  # Top of while loop
  lw a0, 4(fp)                             # Load var: vrange.i
  jal makeint                              # Box integer
  sw a0, -16(fp)                           # Push argument 0 from last.
  addi sp, fp, -16                         # Set SP to last argument.
  jal $print                               # Invoke function: print
  addi sp, fp, -@vrange.size               # Set SP to stack frame top.
  lw a0, -12(fp)                           # Load var: vrange.v
  bnez a0, label_75                        # Ensure not None
  j error.None                             # Go to error handler
label_75:                                  # Not None
  sw a0, -28(fp)                           # Push argument 1 from last.
  lw a0, 4(fp)                             # Load var: vrange.i
  sw a0, -32(fp)                           # Push argument 0 from last.
  lw a0, -28(fp)                           # Peek stack slot 6
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 12(a1)                            # Load address of method: Vector.append
  addi sp, fp, -32                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.append
  addi sp, fp, -@vrange.size               # Set SP to stack frame top.
  lw a0, 4(fp)                             # Load var: vrange.i
  sw a0, -16(fp)                           # Push on stack slot 4
  li a0, 1                                 # Load integer literal 1
  lw t0, -16(fp)                           # Pop stack slot 4
  add a0, t0, a0                           # Operator +
  sw a0, 4(fp)                             # Assign var: vrange.i
label_74:                                  # Test loop condition
  lw a0, 4(fp)                             # Load var: vrange.i
  sw a0, -16(fp)                           # Push on stack slot 4
  lw a0, 0(fp)                             # Load var: vrange.j
  lw t0, -16(fp)                           # Pop stack slot 4
  blt t0, a0, label_73                     # Branch on <
  lw a0, -12(fp)                           # Load var: vrange.v
  j label_72                               # Go to return
  mv a0, zero                              # Load None
  j label_72                               # Jump to function epilogue
label_72:                                  # Epilogue
  .equiv @vrange.size, 32
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @vrange.size                # Restore stack pointer
  jr ra                                    # Return to caller

.globl $sieve
$sieve:
  addi sp, sp, -@sieve.size                # Reserve space for stack frame.
  sw ra, @sieve.size-4(sp)                 # return address
  sw fp, @sieve.size-8(sp)                 # control link
  addi fp, sp, @sieve.size                 # New fp is at old SP.
  li a0, 0                                 # Load integer literal 0
  sw a0, -12(fp)                           # local variable i
  li a0, 0                                 # Load integer literal 0
  sw a0, -16(fp)                           # local variable j
  li a0, 0                                 # Load integer literal 0
  sw a0, -20(fp)                           # local variable k
  j label_79                               # Jump to loop test
label_78:                                  # Top of while loop
  lw a0, -12(fp)                           # Load var: sieve.i
  jal makeint                              # Box integer
  sw a0, -32(fp)                           # Push argument 0 from last.
  addi sp, fp, -32                         # Set SP to last argument.
  jal $print                               # Invoke function: print
  addi sp, fp, -@sieve.size                # Set SP to stack frame top.
  lw a0, 0(fp)                             # Load var: sieve.v
  bnez a0, label_80                        # Ensure not None
  j error.None                             # Go to error handler
label_80:                                  # Not None
  sw a0, -28(fp)                           # Push argument 1 from last.
  lw a0, -12(fp)                           # Load var: sieve.i
  sw a0, -32(fp)                           # Push argument 0 from last.
  lw a0, -28(fp)                           # Peek stack slot 6
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 24(a1)                            # Load address of method: Vector.get
  addi sp, fp, -32                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.get
  addi sp, fp, -@sieve.size                # Set SP to stack frame top.
  sw a0, -20(fp)                           # Assign var: sieve.k
  lw a0, -12(fp)                           # Load var: sieve.i
  sw a0, -24(fp)                           # Push on stack slot 6
  li a0, 1                                 # Load integer literal 1
  lw t0, -24(fp)                           # Pop stack slot 6
  add a0, t0, a0                           # Operator +
  sw a0, -16(fp)                           # Assign var: sieve.j
  j label_82                               # Jump to loop test
label_81:                                  # Top of while loop
  lw a0, 0(fp)                             # Load var: sieve.v
  bnez a0, label_85                        # Ensure not None
  j error.None                             # Go to error handler
label_85:                                  # Not None
  sw a0, -28(fp)                           # Push argument 1 from last.
  lw a0, -16(fp)                           # Load var: sieve.j
  sw a0, -32(fp)                           # Push argument 0 from last.
  lw a0, -28(fp)                           # Peek stack slot 6
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 24(a1)                            # Load address of method: Vector.get
  addi sp, fp, -32                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.get
  addi sp, fp, -@sieve.size                # Set SP to stack frame top.
  sw a0, -24(fp)                           # Push on stack slot 6
  lw a0, -20(fp)                           # Load var: sieve.k
  lw t0, -24(fp)                           # Pop stack slot 6
  bnez a0, label_86                        # Ensure non-zero divisor
  j error.Div                              # Go to error handler
label_86:                                  # Divisor is non-zero
  rem t2, t0, a0                           # Operator rem
  beqz t2, label_87                        # If no remainder, no adjustment
  xor t3, t2, a0                           # Check for differing signs.
  bgez t3, label_87                        # Don't adjust if signs equal.
  add a0, t2, a0                           # Adjust
  j label_88
label_87:                                  # Store result
  mv a0, t2
label_88:                                  # End of %
  sw a0, -24(fp)                           # Push on stack slot 6
  li a0, 0                                 # Load integer literal 0
  lw t0, -24(fp)                           # Pop stack slot 6
  bne t0, a0, label_84                     # Branch on not ==
  lw a0, 0(fp)                             # Load var: sieve.v
  bnez a0, label_89                        # Ensure not None
  j error.None                             # Go to error handler
label_89:                                  # Not None
  sw a0, -28(fp)                           # Push argument 1 from last.
  lw a0, -16(fp)                           # Load var: sieve.j
  sw a0, -32(fp)                           # Push argument 0 from last.
  lw a0, -28(fp)                           # Peek stack slot 6
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 20(a1)                            # Load address of method: Vector.remove_at
  addi sp, fp, -32                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.remove_at
  addi sp, fp, -@sieve.size                # Set SP to stack frame top.
  j label_83                               # Then body complete; jump to end-if
label_84:                                  # Else body
  lw a0, -16(fp)                           # Load var: sieve.j
  sw a0, -24(fp)                           # Push on stack slot 6
  li a0, 1                                 # Load integer literal 1
  lw t0, -24(fp)                           # Pop stack slot 6
  add a0, t0, a0                           # Operator +
  sw a0, -16(fp)                           # Assign var: sieve.j
label_83:                                  # End of if-else statement
label_82:                                  # Test loop condition
  lw a0, -16(fp)                           # Load var: sieve.j
  sw a0, -24(fp)                           # Push on stack slot 6
  lw a0, 0(fp)                             # Load var: sieve.v
  bnez a0, label_90                        # Ensure not None
  j error.None                             # Go to error handler
label_90:                                  # Not None
  sw a0, -32(fp)                           # Push argument 0 from last.
  lw a0, -32(fp)                           # Peek stack slot 7
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 28(a1)                            # Load address of method: Vector.length
  addi sp, fp, -32                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.length
  addi sp, fp, -@sieve.size                # Set SP to stack frame top.
  lw t0, -24(fp)                           # Pop stack slot 6
  blt t0, a0, label_81                     # Branch on <
  lw a0, -12(fp)                           # Load var: sieve.i
  sw a0, -24(fp)                           # Push on stack slot 6
  li a0, 1                                 # Load integer literal 1
  lw t0, -24(fp)                           # Pop stack slot 6
  add a0, t0, a0                           # Operator +
  sw a0, -12(fp)                           # Assign var: sieve.i
label_79:                                  # Test loop condition
  lw a0, -12(fp)                           # Load var: sieve.i
  sw a0, -24(fp)                           # Push on stack slot 6
  lw a0, 0(fp)                             # Load var: sieve.v
  bnez a0, label_91                        # Ensure not None
  j error.None                             # Go to error handler
label_91:                                  # Not None
  sw a0, -32(fp)                           # Push argument 0 from last.
  lw a0, -32(fp)                           # Peek stack slot 7
  lw a1, 8(a0)                             # Load address of object's dispatch table
  lw a1, 28(a1)                            # Load address of method: Vector.length
  addi sp, fp, -32                         # Set SP to last argument.
  jalr a1                                  # Invoke method: Vector.length
  addi sp, fp, -@sieve.size                # Set SP to stack frame top.
  lw t0, -24(fp)                           # Pop stack slot 6
  blt t0, a0, label_78                     # Branch on <
  mv a0, zero                              # Load None
  j label_77                               # Jump to function epilogue
label_77:                                  # Epilogue
  .equiv @sieve.size, 32
  lw ra, -4(fp)                            # Get return address
  lw fp, -8(fp)                            # Use control link to restore caller's fp
  addi sp, sp, @sieve.size                 # Restore stack pointer
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
  la a1, const_6                           # Load error message as str
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

        jr ra


.globl error.None
error.None:
  li a0, 4                                 # Exit code for: Operation on None
  la a1, const_7                           # Load error message as str
  addi a1, a1, 16                          # Load address of attribute __str__
  j abort                                  # Abort

.globl error.Div
error.Div:
  li a0, 2                                 # Exit code for: Division by zero
  la a1, const_8                           # Load error message as str
  addi a1, a1, 16                          # Load address of attribute __str__
  j abort                                  # Abort

.globl error.OOB
error.OOB:
  li a0, 3                                 # Exit code for: Index out of bounds
  la a1, const_9                           # Load error message as str
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

.globl const_8
const_8:
  .word 3                                  # Type tag for class: str
  .word 9                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 16                                 # Constant value of attribute: __len__
  .string "Division by zero"               # Constant value of attribute: __str__
  .align 2

.globl const_6
const_6:
  .word 3                                  # Type tag for class: str
  .word 8                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 13                                 # Constant value of attribute: __len__
  .string "Out of memory"                  # Constant value of attribute: __str__
  .align 2

.globl const_9
const_9:
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

.globl const_7
const_7:
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

.globl const_5
const_5:
  .word 3                                  # Type tag for class: str
  .word 5                                  # Object size
  .word $str$dispatchTable                 # Pointer to dispatch table
  .word 3                                  # Constant value of attribute: __len__
  .string "1fr"                            # Constant value of attribute: __str__
  .align 2
