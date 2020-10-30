# backup sp is
# addi $sp, $sp, -4
# sw $ra, 0($sp)
.data
msg_welcome: .asciiz "Hello\n"
youtyped:    .asciiz "You typed A\n"
youfailed:   .asciiz "You didn't type A\n"
.text
    # print message (syscall 4)
    addi $v0, $zero, 4
    la $a0, msg_welcome
    syscall

    # get response (go into input mode)
    addi $v0, $v0, 4
    addi $a0, $a0, 52
    addi $a1, $zero, 2
    # save response location
    move $t0, $a0
    syscall

    # go back to print mode
    addi $v0, $v0, -4

    # do some testing
    addi $t1, $zero, 0x41
    lbu $t2, 0($t0)
    beq $t1, $t2, 4

    # print the message if they didnt type A
    la $a0, youfailed
    beq $zero, $zero, 3

    # print the message if they typed A
    la $a0, youtyped
    syscall

    # exit
    jr $ra