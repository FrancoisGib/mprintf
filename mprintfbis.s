.text
.global put_arg_in_rax
put_arg_in_res:
    pushq %rbp
    movq %rsp, %rbp
    cmpb $'c', %r10b
    je char
    cmpb $'s', %r10b
    je string
    movq %rdi, %rax

    number:
        jmp put_arg_done

    string:
        popq %rsi /* str size */

    char:
        movb %r10b, (%rdi)
        dec %rdi
        dec %r12


    put_arg_done:
        movq %rbp, %rsp
        popq %rbp
        ret

.global get_arg_size
get_arg_size:
    pushq %rbp
    movq %rsp, %rbp
    /* get_arg_type */
    cmpb $'c', %r10b
    je char_type
    cmpb $'s', %r10b
    je string_type
    pushq %rax /* save the registers */
    pushq %rdx
    movq %rdi, %rax

    get_number_size:
        movq $0, %rdx
        cmpq $0, %rax
        je get_number_size_done
        idivq %r13
        inc %r12
        jmp get_number_size

        get_number_size_done:
            popq %rdx
            popq %rax
            jmp get_arg_size_done

    string_type:
        pushq %r8
        movq $0, %r8
        get_str_size:
            cmpb $0, (%rdi)
            je get_str_size_done
            inc %rdi
            inc %r8
            jmp get_str_size
        get_str_size_done:
            popq %rdi /* r8 */
            popq %rsi /* former rbp */
            popq %r11 /* function call pointer */
            pushq %r8
            addq %r8, %r12
            pushq %r11
            pushq %rsi
            movq %rdi, %r8 /* restore the registers */
            jmp get_arg_size_done

    char_type:
        inc %r12

    get_arg_size_done:
        movq %rbp, %rsp
        popq %rbp
        ret


.global mprintf
mprintf:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r13
    pushq %r12
    movq $0, %r12 /* string to print size */
    movq %rdi, %r11 /* pointer to the chain */
    movb $0, %ah /* argument index */

    get_args: /* %rsi, %rdx, %rcx, %r8, %r9, stack_args */
        movb (%r11), %r10b
        cmpb $0, %r10b
        je end_read_args
        inc %r11
        cmpb $'%', %r10b
        je get_arg_type
        inc %r12
        jmp get_args

        get_arg_type:
            movb (%r11), %r10b
            cmpb $'t', %r10b
            je type_array
            cmpb $'d', %r10b
            je type_decimal
            cmpb $'h', %r10b
            je type_hexadecimal
            cmpb $'b', %r10b
            je type_binary

        push_arg:
            cmpb $5, %ah
            jge push_stack_arg 
            cmpb $0, %ah
            je push_rsi
            cmpb $1, %ah
            je push_rdx
            cmpb $2, %ah
            je push_rcx
            cmpb $3, %ah
            je push_r8
            cmpb $4, %ah
            je push_r9

        push_rsi:
            pushq %rsi
            jmp inc_arg_counter

        push_rdx:
            pushq %rdx
            jmp inc_arg_counter

        push_rcx:
            pushq %rcx
            jmp inc_arg_counter

        push_r8:
            pushq %r8
            jmp inc_arg_counter

        push_r9:
            pushq %r9
            jmp inc_arg_counter
        
        push_stack_arg:
            addq $8, %rbp
            movq 8(%rbp), %rsi
            pushq %rsi

        inc_arg_counter:
            inc %ah
            inc %r11
            popq %rdi
            pushq %r11
            pushq %rdi
            call get_arg_size
            popq %rsi
            popq %r11
            pushq %rsi
            jmp get_args /* go to next arg */

        /* al
        0 -> normal argument
        1 -> array arg
        */
        type_array:
            inc %r11
            movb $1, %al
            jmp push_arg

        type_decimal:
            movq $10, %r13
            jmp push_arg
        
        type_hexadecimal:
            movq $16, %r13
            jmp push_arg

        type_binary:
            movq $2, %r13
            jmp push_arg

        end_read_args:
            dec %ah
            subq $8, %rbp
            cmpb $5, %ah
            jg end_read_args

        malloc_res_size:
            pushq %r9
            movq %r12, %rdi
            call malloc
            popq %r9
            addq %r12, %rax
            movq %r12, %rcx /* stock the size of the string */

        read_string_reverse:
            cmpq $0, %r12
            je print
            dec %rcx
            dec %rax
            movb (%r11), %r10b
            dec %r11
            dec %r12
            cmpb $'%', (%r11)
            je percent_copy
            movb %r10b, (%rax)
            jmp read_string_reverse

            percent_copy:

            put_args_in_res:
                movb (%r11), %r10b
                popq %rdi
                call put_arg_in_res


        print:

    done:
        call free
        popq %r13
        popq %r12
        movq %rbp, %rsp
        popq %rbp
        ret
