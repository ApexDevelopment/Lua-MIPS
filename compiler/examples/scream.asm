.data
    .asciiz "Hello!"
.text
    # Set v0 to 4 (print syscall)
    ADDI $v0, $zero, 4
    # Put the address of our string in a0 for the syscall
    ADD $a0, $zero, $gp
    # Execute syscall
    SYSCALL
    # Exit
    JR $ra