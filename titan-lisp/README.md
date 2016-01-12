# Titan LISP Compiler #

## Description ##

A compiler for a small dialect of LISP for Titan written in scheme.

## Useage ##

    (compile program-name)

    ./compile input-file

### Example ###

Write a valid titan lisp program to a file

    (define (addone num)
      (+ num 1))

Then using CHICKEN, compile the compiler and compiler the file to assembly

    $ csc compiler.scm -o compile
    $ ./compile
    Useage: compiler input-file output-file
    $ ./compile testlisp.lsp testlisp.asm
      ...

Then again using CHICKEN, compile the assembler and assemble the output of the compiler

    $ csc assembler.scm -o assembler
    $ ./assemble
    Useage: assemble input-file address-offset
    $ ./assembler testlisp.asm 0 4
      ....

## Conventions ##

All conventions are in the specification which can be found [here](https://github.com/bootnecklad/Titan-Specifications/blob/master/Specifications.md)