{ -- MF/TIN CORE (always include) functions
  -- Copyright (c) 2003 by Jeff Massung }

\ inlined peek and poke values into GBA memory
icode peek ( a -- h ) tos 0@ tos ldrh, end-code
icode poke ( a h -- ) w pop w 0@ tos strh, tos pop end-code

\ divide and modula
: / ( n1 n2 -- n3 ) swap a! 7 swi ;
: mod ( n1 n2 -- n3 ) / drop a ;

\ conditionals
: = ( n1 n2 -- flag ) - 0= ;
: <> ( n1 n2 -- flag ) - 0= com ;
: < ( n1 n2 -- flag ) - 0< ;
: > ( n1 n2 -- flag ) swap - 0< ;
: <= ( n1 n2 -- flag ) swap - 0< com ;
: >= ( n1 n2 -- flag ) - 0< com ;

\ fixed point math operations
: f* ( n1 n2 -- n3 ) * 8 # a/ ;
: f/ ( n1 n2 -- n3 ) a! 8 # n* 6 swi ;

\ send a string to the VBA console
: log ( a -- ) 1+ $ff swi drop ;

\ the restore data pointer
variable .idata

\ transfer from data pointer to local address register
: >a ( -- ) .idata @ a! ;
: a> ( -- ) a .idata ! ;

\ allocate bytes of data on the return stack
code r-alloc ( u -- a )
	rsp w mov,
	
	\ allocate space
	tos rsp rsp sub,
	rsp tos mov,
	w link \ save old rsp
	
	\ save new returning adress
	u link
	pc u mov,
	ret
	
	\ this is called on next return
	u unlink
	rsp 0@ rsp ldr,
	u bx,
end-code

\ copy bytes from one address to another
code copy ( to from u -- )
	sp ia! v0 v1 ldm,
	tos tos tst,
	
	\ loop
	l: __copy
	
	\ if <= 0 then return
	tos le? pop
	le? ret
	
	\ transfer
	v0 2 (# w ldrh,
	v1 2 (# w strh,
	
	\ decrement and loop
	2 ## tos tos s! sub,
	__copy b,
end-code

\ erase bytes at an address
code erase ( a u -- )
	v0 pop
	w w w eor,
	tos tos tst,
	
	\ loop
	l: __erase
	
	\ if <= 0 then return
	tos le? pop
	le? ret
	
	\ erase
	v0 2 (# w strh,
	
	\ decrement and loop
	2 ## tos tos s! sub,
	__erase b,
end-code

\ set the graphics mode
code graphics ( mode sprites -- )
	v1 pop
	
	\ ready r2
	0 ## v2 mov,
	0 ## tos cmp,
	
	\ set the sprite bit
	$1040 tos ne? literal
	
	\ bitmapped modes enable bg 2
	3 ## v1 cmp,
	$400 ## v2 ge? mov,
	
	\ write mode to REG_DISPCNT
	v2 v1 v2 orr,
	v2 tos v2 orr,
	$4000000 ## tos mov,
	tos 0@ v2 strh,

	\ store VRAM address
	VRAM ## tos mov,
	tos push
	
	\ erase VRAM
	$17fff tos literal
	erase b,
end-code

\ wait for the next vertical blank
code vblank ( -- )
	$4000000 ## v0 mov,
	
	\ wait for vertical blank
	l: __wait
	v0 6 #( v1 ldrh,
	160 ## v1 cmp,
	__wait ne? b,
	
	\ done
	ret
end-code

\ return the current scanline
code scanline ( -- n )
	tos push
	REGISTERS ## tos mov,
	tos 6 #( tos ldrh,
	ret
end-code