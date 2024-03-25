.text
.global mprintf
mprintf:
    enter $0, $0
    movq %rdi, %r15 /* pointer to the pattern */
    xorq %r10, %r10 /* string to print size */
    xorq %r11, %r11 /* number of args */
    pushq %r12 /* The char value register */
    pushq %r15
    pushq %r13

    read_pattern:
        movb (%r15), %r12b
        cmpb $0, %r12b
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
            cmpb $'t', %r12b
            je array_arg

            push_arg:
                inc %r11
                cmpq $1, %r11 /* no case for the first, first arg already in rsi */
                je push_arg_done
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
                    jmp push_arg_done

                third_arg:
                    movq %rcx, %rsi
                    jmp push_arg_done

                fourth_arg:
                    movq %r8, %rsi
                    jmp push_arg_done

                fifth_arg:
                    movq %r9, %rsi
                    jmp push_arg_done

                stack_arg:
                    movq 16(%rbp), %rsi
                    addq $8, %rbp

                push_arg_done:
                    cmpb $1, %r12b
                    je get_array_pointer_done
                    cmpb $2, %r12b
                    je get_array_size_done
                    jmp inc_buffer_size_with_arg_size

                inc_buffer_size_with_arg_size:
                    cmpq $0, %rsi
                    je number_zero
                    pushq %rsi
                    pushq %r12
                    inc_buffer_end:
                        call get_arg_size
                        addq %rax, %r10
                        popq %r12
                        cmpq $1, %rsi
                        je number_not_zero
                        cmpb $'s', %r12b
                        jne read_pattern
                    
                    push_arg_size:
                        pushq %rax /* push the size of the arg to avoid recalculating later */
                        jmp read_pattern

                    number_zero:
                        inc %r10
                        pushq $2
                        jmp read_pattern

                    number_not_zero:
                        pushq $1
                        jmp read_pattern

                    array_arg:
                        movb $2, %r12b
                        jmp push_arg
                        get_array_size_done:
                            dec %r12b
                            pushq %rsi /* push the array size */
                            movq %rsi, %r14
                            jmp push_arg
                        get_array_pointer_done:
                            movq %r14, %rdx /* the second argument has been read so we can use rdx */
                            addq %rdx, %r10 /* add the array header ([n,n]) */
                            inc %r10 /* we had one comma too many so we don't have to add the ']', just the '[' */
                            movb (%r15), %r12b /* get the type of the elements */
                            inc %r15 /* pass the arg type */
                            movq %rsi, %r14
                        get_array_print_size_loop:
                            movl (%r14), %esi
                            call get_arg_size
                            addq %rax, %r10
                            dec %rdx
                            cmpq $0, %rdx
                            je get_array_print_size_done
                            addq $4, %r14 /* the size of an int */
                            jmp get_array_print_size_loop
                        get_array_print_size_done:
                            pushq %r14
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
            cmpb $'t', %r11b
            je call_put_array
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
                cmpb $'b', %r12b
                je put_binary_number
                cmpb $'h', %r12b
                je put_hexadecimal_number
                movq $10, %r13 /* case decimal number */
                call put_number_in_res
                jmp reverse_read
                
                put_binary_number:
                    movq $2, %r13
                    call put_number_in_res
                    movb $'b', (%rax)
                    dec %rax
                    movb $'0', (%rax)
                    dec %rax
                    subq $2, %r10
                    jmp reverse_read

                put_hexadecimal_number:
                    movq $16, %r13
                    call put_number_in_res
                    movb $'x', (%rax)
                    dec %rax
                    movb $'0', (%rax)
                    dec %rax
                    subq $2, %r10
                    jmp reverse_read

                case_zero:
                    movb $48, (%rax)
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

            call_put_array:
                dec %r15 /* pass the 't' */
                dec %r15 /* pass the '%' */
                popq %rsi /* pointer to the last element in array */
                popq %r11 /* the number of elements in the array */
                movb $']', (%rax)
                dec %rax /* dec the buffer pointer and the remaining bytes to copy */
                dec %r10
                movb (%r15), %r12b
                cmpb $'b', %r12b
                je array_put_binary
                cmpb $'h', %r12b
                je array_put_hexadecimal
                movq $10, %r13
                put_array_loop:
                    movl (%rsi), %r8d
                    pushq %r8
                    pushq $1
                    call put_number_in_res
                    subq $4, %rsi
                    dec %r11
                    cmpq $0, %r11
                    je put_array_done
                    movb $',', (%rax)
                    dec %rax
                    dec %r10
                    jmp put_array_loop

                put_array_done:
                    movb $'[', (%rax)
                    dec %rax
                    dec %r13
                    jmp reverse_read
                
                array_put_binary:
                    movq $2, %r13
                    jmp put_array_loop

                array_put_hexadecimal:
                    movq $16, %r13
                    jmp put_array_loop
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
        pushq %rdx
        pushq %r11
        movq $1, %r11 /* initial size of the number */
        movq %rsi, %rax /* put in rax for the division */
        movq $1, %rsi
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
            jmp get_arg_size_done

        string:
            movb (%rsi), %r13b
            cmpb $0, %r13b
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
        cmpq $9, %rdx
        jg hexa
        addq $48, %rdx

        put_decimal:
            movb %dl, (%r14)
            dec %r14
            dec %r10
            jmp division_put

        hexa:
            addq $55, %rdx
            jmp put_decimal

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