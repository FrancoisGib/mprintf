.data
res:
   .space 64
number_buffer32:
   .space 10
.text

.global int_to_string
int_to_string: /* number in %r11, conversion made in %rax */
   pushq %rbp
   movq %rsp, %rbp /* save %rsp before pushing %rax because i need %rax in the middle of the function */
   pushq %r13 /* %r13 is used for the number_buffer32 pointer because %rax will be used by the division */
   pushq %r14 /* used for the size of the number so need to save it before */
   pushq %rbx
   pushq %rdx
   pushq %rax
   movq $number_buffer32, %r13
   movq $0, %r14
   movq %r11, %rax

   division:
      movq $0, %rdx
      movq %r15, %rbx
      cmpl $0, %eax
      je reverse_str
      idiv %ebx
      cmpq $9, %rdx
      jg hexadecimal_char
      addq $48, %rdx

   put_in_rax:
      movq %rdx, (%r13)
      inc %r13
      inc %r14
      jmp division

   hexadecimal_char:
      addq $55, %rdx
      jmp put_in_rax

   reverse_str:
      popq %rax
      dec %r13
      cmpq $10, %r15 /* add a header if the denominator is different than 10 */
      jne add_header

      place_char_in_rax:
         cmpq $0, %r14
         je int_to_string_done
         movb (%r13), %r11b
         movb %r11b, (%rax)
         inc %r12
         inc %rax
         dec %r14
         dec %r13
         jmp place_char_in_rax

      add_header:
         movb $'0', (%rax)
         inc %rax
         inc %r12
         cmpq $16, %r15
         je add_hexadecimal_header
         jmp add_binary_header

         add_hexadecimal_header:
            movb $'x', (%rax)
            jmp end_header

         add_binary_header:
            movb $'b', (%rax)

         end_header:
            inc %rax
            inc %r12
            jmp place_char_in_rax


   int_to_string_done:
      popq %rdx
      popq %rbx
      popq %r14
      popq %r13
      movq %rbp, %rsp
      popq %rbp
      ret

.global read_arg
read_arg:
   cmpq $5, %r13
   je stack_arg
   pushq %rbp
   movq %rsp, %rbp
   cmpq $0, %r13
   je first_arg
   cmpq $1, %r13
   je second_arg
   cmpq $2, %r13
   je third_arg
   cmpq $3, %r13
   je fourth_arg
   cmpq $4, %r13
   je fifth_arg
   
   get_arg_type:
      cmpq $0, %r14
      je read_decimal_number
      cmpq $2, %r14
      je read_string
      cmpq $1, %r14
      je read_char
      cmpq $3, %r14
      je read_hexadecimal_number
      cmpq $4, %r14
      je read_binary_number
      jmp read_arg_done

   stack_arg:
      popq %r11
      popq %rcx
      pushq %r11
      pushq %rbp
      movq %rsp, %rbp
      movq (%rcx), %r11
      jmp get_arg_type

   /* Arguments register placed to %r11 */
   first_arg:
      movq %rsi, %r11
      jmp get_arg_type

   second_arg:
      movq %rdx, %r11
      jmp get_arg_type

   third_arg:
      movq %rcx, %r11
      jmp get_arg_type

   fourth_arg:
      movq %r8, %r11
      jmp get_arg_type

   fifth_arg:
      movq %r9, %r11
      jmp get_arg_type

   /* Args read methods */
   read_string:
      movb (%r11), %r10b
      cmpb $0, %r10b /* if the second arg doesn't exist */
      jle read_arg_done
      cmpb $30, %r10b /* if the third arg doesn't exist */
      je read_arg_done
      cmpb $208, %r10b /* if the fourth arg doesn't exist */
      je read_arg_done
      cmpb $4, %r10b /* if the fifth arg doesn't exist */
      je read_arg_done
      /* no need for the sixth args to check if it doesn't exist */
      movb %r10b, (%rax)
      inc %r12
      inc %r11
      inc %rax
      jmp read_string

   read_decimal_number:
      movq $10, %r15 /* the base to convert the number to string */
      call int_to_string
      inc %r12
      inc %rax
      jmp read_arg_done

   read_hexadecimal_number:
      movq $16, %r15 /* the base to convert the number to string */
      call int_to_string
      inc %r12
      inc %rax
      jmp read_arg_done

   read_binary_number:
      movq $2, %r15 /* the base to convert the number to string */
      call int_to_string
      inc %r12
      inc %rax
      jmp read_arg_done

   read_char:
      movb %r11b, (%rax)
      inc %r12
      inc %rax

   read_arg_done:
      movq %rbp, %rsp
      popq %rbp
      ret

.global mprintf
mprintf:
   pushq %rbp
   movq %rsp, %rbp /* save the stack pointer */
   pushq %r12 /* saving the registers used in the program */
   pushq %r13
   pushq %r14 /* used for the status of the % (%s -> 0, %d -> 1, %c -> 2) */
   pushq %r15
   movq $res, %rax
   movq $0, %r12 /* res string size */
   movq $0, %r13 /* count of args */

   read_pattern:
      movb (%rdi), %r10b
      cmpb $0, %r10b
      je print
      cmpb $'%', %r10b
      je percent
      movb %r10b, (%rax)
      inc %rax
      inc %r12
      inc %rdi
      jmp read_pattern

   percent:
      cmpq $5, %r13
      je read_stack

      arg_type:
         inc %rdi /* pass the percent */
         movb (%rdi), %r10b
         inc %rdi /* pass the pattern (s, d...) */
         cmpb $'s', %r10b
         je string
         cmpb $'d', %r10b
         je decimal_number
         cmpb $'c', %r10b
         je char
         cmpb $'h', %r10b
         je hexadecimal_number
         cmpb $'b', %r10b
         je binary_number
         cmpq $5, %r13
         je get_args_count
         jmp read_pattern
      
   string:
      movq $2, %r14
      jmp start_arg_read

   decimal_number:
      movq $0, %r14
      jmp start_arg_read

   hexadecimal_number:
      movq $3, %r14
      jmp start_arg_read

   binary_number:
      movq $4, %r14
      jmp start_arg_read

   char:
      movq $1, %r14

   start_arg_read:
      call read_arg
      cmpq $1, %r9
      je get_args_count
      inc %r13 /* next arg */
      jmp read_pattern

   read_stack:
      movq $0, %r8
      addq $8, %rbp

      get_args_count:
         movb (%rdi), %r10b
         cmpb $0, %r10b
         je end_stack_reading
         cmpb $'%', %r10b
         je percent_stack
         movb %r10b, (%rax)
         inc %rax
         inc %r12
         inc %rdi
         jmp get_args_count

      percent_stack:
         addq $8, %rbp
         inc %r8
         pushq %rbp
         movq $1, %r9 /* status for the arg reading, to jump here */
         jmp arg_type

            
      end_stack_reading:
         dec %r8
         cmpq $0, %r8
         je print
         subq $8, %rbp
         jmp end_stack_reading

   print:
      movq $1, %rax
      movq $0, %rdi
      movq $res, %rsi
      movq %r12, %rdx
      syscall

   done:
      popq %r15
      popq %r14 /* restore the registers used in the program */
      popq %r13
      popq %r12
      popq %rbp
      ret
