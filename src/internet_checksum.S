/*
 * RFC 1071 Internet Checksum without the final one's complement.
 *
 * It supports Thumb-only and Thumb-2 targets thus all Cortex-M CPUs are supported.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 * Copyright (c) 2024 Chien Wong <m@xv97.com>
 */

.syntax unified
.text
.align 2
.global internet_checksum_fast
.thumb
.thumb_func
.type internet_checksum_fast, %function
internet_checksum_fast:
        @ r0: start of buffer address, it may be unaligned
        @ r1: length of buffer
        @ return r0: Checksum of buffer, without the one's complement(bitwise NOT)
#if defined(__thumb2__)

.macro BIG_BLOCK_STEP op1
        ldmia   r3!, {r5-r11, lr}
        \op1    r4, r5
.irp reg, r6, r7, r8, r9, r10, r11, lr
        adcs    r4, \reg
.endr
.endm

        mov     r12, #0
        cbz     r1, 1f
        ands    r2, r0, #1
        beq     1f
        mov     r3, r0
        ldrb    r2, [r3], #1
        subs    r1, #1
        lsl     r12, r2, #8
        b       2f
1:
        mov     r3, r0
2:
        push    {r4, lr}
        lsls    r2, r3, #30
        mov     r4, #0
        beq     .Lfour_bytes_aligned
        cmp     r1, #2
        itt     hs
        ldrhhs  r4, [r3], #2
        subhs   r1, #2
.Lfour_bytes_aligned:
        cmp     r1, #64
        blo     .Lsmall_block_check
        push    {r5-r11}
.Lbig_block_loop:
        subs    r1, #64
        BIG_BLOCK_STEP adds
        BIG_BLOCK_STEP adcs
        adc     r4, #0
        cmp     r1, #63
        bhi     .Lbig_block_loop
        pop     {r5-r11}
        b       .Lsmall_block_check

.Lsmall_block_loop:
        ldrd    r2, lr, [r3], #8
        subs    r1, #8
        adds    r4, r2
        adcs    r4, lr
        adc     r4, #0
.Lsmall_block_check:
        cmp     r1, #7
        bhi     .Lsmall_block_loop
        uxth    r2, r4
        cmp     r1, #2
        add     r2, r2, r4, lsr #16
        blo     .Lremaining_1
.Lhalf_words_loop:
        ldrh    r4, [r3], #2
        subs    r1, #2
        cmp     r1, #1
        add     r2, r4
        bhi     .Lhalf_words_loop
.Lremaining_1:
        cmp     r1, #0
        ite     ne
        ldrbne  r1, [r3]
        moveq   r1, #0
        orr     r1, r1, r12
        add     r1, r2
        uxth    r2, r1
        add     r1, r2, r1, lsr #16
        uxth    r2, r1
        add     r1, r2, r1, lsr #16
        lsls    r0, r0, #31
        rev     r2, r1
        it      ne
        lsrne   r1, r2, #16
        uxth    r0, r1
        pop     {r4, pc}

#elif defined(__thumb__)

        push    {r4, r5, r6, lr}
        movs    r2, #1
        ands    r2, r0
        movs    r4, #0
        cmp     r1, #0
        beq     1f
        cmp     r2, #0
        beq     1f
        adds    r3, r0, #1
        subs    r1, r1, #1
        ldrb    r0, [r0]
        lsls    r0, r0, #8
        b       2f
1:
        mov     r3, r0
        mov     r0, r4
2:
        lsls    r5, r3, #30
        beq     .Lfour_bytes_aligned
        cmp     r1, #2
        blo     .Lfour_bytes_aligned
        subs    r1, r1, #2
        ldrh    r4, [r3]
        adds    r3, r3, #2
.Lfour_bytes_aligned:
        movs    r6, #0
        cmp     r1, #64
        blo     .Lsmall_block_check
.Lbig_block_loop:
        ldr     r5, [r3]
        adds    r4, r5, r4

.set offset, 4
.rept 15
        ldr     r5, [r3, #offset]
        adcs    r4, r5
.set offset, offset + 4
.endr

        adcs    r4, r6
        adds    r3, #64
        subs    r1, #64
        cmp     r1, #63
        bhi     .Lbig_block_loop
        b       .Lsmall_block_check

.Lsmall_block_loop:
        ldr     r5, [r3]
        adds    r4, r5, r4
        ldr     r5, [r3, #4]
        adcs    r4, r5
        adcs    r4, r6
        adds    r3, #8
        subs    r1, #8
.Lsmall_block_check:
        cmp     r1, #7
        bhi     .Lsmall_block_loop

        uxth    r5, r4
        lsrs    r4, r4, #16
        adds    r4, r4, r5
        cmp     r1, #2
        blo     .Lremaining_1
.Lhalf_words_loop:
        ldrh    r5, [r3]
        adds    r4, r4, r5
        subs    r1, r1, #2
        adds    r3, r3, #2
        cmp     r1, #1
        bhi     .Lhalf_words_loop
.Lremaining_1:
        cmp     r1, #0
        beq     1f
        ldrb    r1, [r3]
        b       2f
1:
        movs    r1, #0
2:
        orrs    r1, r0
        adds    r0, r1, r4
        uxth    r1, r0
        lsrs    r0, r0, #16
        adds    r0, r0, r1
        uxth    r1, r0
        lsrs    r0, r0, #16
        adds    r0, r0, r1
        cmp     r2, #0
        beq     1f
        rev     r0, r0
        lsrs    r0, r0, #16
1:
        uxth    r0, r0
        pop     {r4, r5, r6, pc}

#else
#error "Unsupported target"
#endif

        .size   internet_checksum_fast, . - internet_checksum_fast
