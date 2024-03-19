.text
.global mprintf
mprintf:
    enter $0, $0
    movq %rdi, %r15 /* pointer to the pattern */
    movq $0, %r10 /* string to print size */
    movq $0, %r11 /* number of args */
    pushq %r12 /* The char value register */
    pushq %r15
    pushq %r13

    read_pattern:
        movb (%r15), %r12b
        cmpb  $0, %r12b
        je read_pattern_done
        cmpb $'%', %r12b
        je get_arg_type
        inc %r15
        inc %r10
        jmp read_pattern

        get_arg_type:
            inc %r15 /* pass the percent */
            movb (%r15), %r12b
            inc %r15 /* pass the arg type */

            push_arg:
                inc %r11
                cmpq $1, %r11 /* no case for the first, first arg already in rsi */
                je inc_buffer_size_with_arg_size
                cmpq $2, %r11
                je second_arg
                cmpq $3, %r11
                je third_arg
                cmpq $4, %r11
                je fourth_arg
                cmpq $5, %r11
                je fifth_arg
                jmp stack_arg

                second_arg:
                    movq %rdx, %rsi
                    jmp inc_buffer_size_with_arg_size

                third_arg:
                    movq %rcx, %rsi
                    jmp inc_buffer_size_with_arg_size

                fourth_arg:
                    movq %r8, %rsi
                    jmp inc_buffer_size_with_arg_size

                fifth_arg:
                    movq %r9, %rsi
                    jmp inc_buffer_size_with_arg_size

                stack_arg:
                    movq 16(%rbp), %rsi
                    addq $8, %rbp

                inc_buffer_size_with_arg_size:
                    cmpq $0, %rsi
                    je zero_number
                    pushq %rsi
                    pushq %r12
                    call get_arg_size
                    addq %rax, %r10
                    popq %r12
                    cmpb $'s', %r12b
                    jne read_pattern
                    
                    push_arg_size:
                        pushq %rax /* push the size of the arg to avoid recalculating later */
                        jmp read_pattern

                    zero_number:
                        inc %r10
                        pushq $2
                        jmp read_pattern
                    

        read_pattern_done:  /* reset the stack */
            cmpq $5, %r11
            jng malloc_res_size
            dec %r11
            subq $8, %rbp
            jmp read_pattern_done
                
        malloc_res_size:
            pushq %r10
            movq %r10, %rdi
            call malloc
            dec %r10
            addq %r10, %rax
            popq %r10
            movq %r10, %rdx
            dec %r15 /* point before the \0 */  
        
        reverse_read:
            cmpq $0, %r10 /* end before the first char */
            je print
            movb (%r15), %r12b
            dec %r15
            movb (%r15), %r11b
            cmpb $'%', %r11b
            je call_put_arg_in_string
            movb %r12b, (%rax)
            dec %r10
            dec %rax
            jmp reverse_read

            call_put_arg_in_string:
                dec %r15
                cmpb $'c', %r12b
                je call_put_char
                cmpb $'s', %r12b
                je call_put_string
                
            call_put_number:
                popq %r13
                cmpq $2, %r13
                je case_zero
                popq %r8
                movq $10, %r13
                call put_number_in_res
                jmp reverse_read
                case_zero:
                    movq $48, (%rax)
                    dec %rax
                    dec %r10
                    jmp reverse_read


            call_put_string:
                popq %r8
                subq %r8, %r10
                popq %r11
                pushq %r10
                call put_string_in_res
                popq %r10
                jmp reverse_read

            call_put_char:
                popq %r8
                dec %r10
                movb %r8b, (%rax)
                dec %rax
                jmp reverse_read
                
                

    print:
        movq %r9, %rsi
        movq $1, %rax
        movq $0, %rdi
        syscall
        movq %r9, %rsi
        call free

    done:
        popq %r13
        popq %r15
        popq %r12
        leave
        ret


.global get_arg_size
get_arg_size:
    enter $0, $0
    movq $0, %rax
    cmpb $'s', %r12b
    je string
    cmpb $'c', %r12b
    je char
    
    /* number: */
        cmpq $0, %rsi
        je zero
        pushq %r13 /* save registers used */
        pushq %rdx
        pushq %r11
        movq $1, %r11 /* initial size of the number */
        movq %rsi, %rax /* put in rax for the division */
        cmpb $'h', %r12b
        je hexadecimal_number
        cmpb $'b', %r12b
        je binary_number

        decimal_number:
            movq $10, %r13
            jmp get_number_size

        hexadecimal_number:
            movq $16, %r13
            jmp add_header_size

        binary_number:
            movq $2, %r13

        add_header_size:
            addq $2, %r11 /* 0x or 0b */

        get_number_size:
            movq $0, %rdx
            cmpq %r13, %rax
            jl get_number_size_done
            idivq %r13
            inc %r11
            jmp get_number_size

        get_number_size_done:
            movq %r11, %rax
            popq %r11
            popq %rdx
            popq %r13
            jmp get_arg_size_done

        zero:
            movq $-1, %rax
            jmp get_arg_size_done

    string:
        movb (%rsi), %r8b
        cmpb $0, %r8b
        je get_arg_size_done
        inc %rsi
        inc %rax
        jmp string

    char:
        inc %rax

    get_arg_size_done:
        leave
        ret


.global put_number_in_res
put_number_in_res:
    enter $0, $0
    pushq %r14
    movq %rax, %r14
    movq %r8, %rax

    division_put:
        movq $0, %rdx
        cmpq $0, %rax
        je put_number_done
        idivq %r13
        addq $48, %rdx
        movb %dl, (%r14)
        dec %r14
        dec %r10
        jmp division_put
    put_number_done:
        movq %r14, %rax
        popq %rdx
        popq %r14
        leave
        ret

.global put_string_in_res
put_string_in_res:
    enter $0, $0
    dec %r8
    addq %r8, %r11 /* go to the end of the string */
    loop:
        movb (%r11), %r12b
        movb %r12b, (%rax)
        dec %rax
        dec %r11
        dec %r8
        cmpq $-1, %r8
        jne loop
    leave
    ret