	xref	FileOpen
	xref	FileReset
	xref	FileClose
	xref	FileCharRead
	xref	KbdCharRead
	xref	ScrnCharWrite
	xref	Exit


LF	EQU	10
CR	EQU	13
NULL	EQU	0
SCREENW	EQU	80

start:	jsr	FileOpen	
	cmp.l	#0,d0
	bne	nofile

	cmp.l	#0,d1
	beq	nocontents

	move.l	d1,bytes	;store bytes
	move.l	#0,d3	;running # of letters	
	move.l	#0,d4	;longest word
	move.l	#0,d5	;number of words

getwords:	
	clr.l	d0					
	jsr	FileCharRead
	sub.l	#1,d1	;remove a letter
	cmp.l	#0,d1
	beq	addword
	
	cmp.l	#CR,d0
	beq	getwords	;add to word length	

	cmp.l	#LF,d0
	beq	addword
	
	add.l	#1,d3
	bra	getwords
	
addword:
	add.l	#1,d5	;add word
	cmp.l	d3,d4
	blt	update
	clr.l	d3
	tst		d1
	beq	eof
	bra	getwords
	
update:
	move.l	d3,d4
	clr.l	d3
	bra	getwords


eof:	jsr	FileReset
	move.l	d5,words	
	add.l	#1,d4	;get longest word + 1	
	move.l	d4,longest

	cmp.l	#SCREENW,d4	
	bge	col
	bra	dcol

col:
	move.l	#1,d2
	move.l	d2,column
	bra	typecolumn
dcol:
	move.l	#SCREENW,d2	
	divu.w	d4,d2
	move.w 	d2,column

typecolumn:
	divu.w	d2,d5		;d5 - longcolumn and regcolumn
	move.w	d5,regcol	;calculate columns by 1 or 80/ (longest+1)
	swap	d5			;regcolumnn=words/columns
	move.w	d5,loncol	;longcolumn=words%columns
	
rows:				;if longcolumns rows=regcol+1 else rows=regcol		
	cmp.w	#0,d5
	bne	erow

	swap	d5
	move.w	d5,d6	
	move.w	d6,row
	bra	print
erow:
	swap	d5
	move.w	d5,d6
	add.w	#1,d6
	move.w	d6,row
			


;new data register table
	clr.l	d7	;d7-offset	
	clr.l	d6	;d6- listpos
	clr.l	d5	;d5- current word length
	clr.l	d4	;d4- whitespace
	clr.l	d3	;d3- currWord
	clr.l	d2	;d2- currRow
	move.l	bytes,d1;d1- file size
	clr.l	d0	;d0- input/output
	
	
print:


outer:	move.l	row,d0
	swap	d0
	cmp.l	d0,d2
	bge	doneouter	
	move.l	d2,d6
	clr.l	d7		

inner:	
	clr.l	d5
	move.l	column,d0
	swap 	d0
	cmp.l	d0,d3
	bge	doneinner
	
	cmp.l	d6,d7
	beq	printword	
noword:	
	jsr	FileCharRead
	cmp.l	#LF,d0
	bne	noword
	add.l	#1,d7	
	bra	inner

printword:
	jsr	FileCharRead
	cmp.l	#CR,d0
	beq	doneword
	jsr	ScrnCharWrite
	add.l	#1,d5
	bra	printword

doneword:
	jsr	FileCharRead	;read lf
	move.l	longest,d4
	sub.l	d5,d4

printwhite:
	move.b	#' ',d0
	jsr	ScrnCharWrite
	sub.l	#1,d4
	cmp.l	#0,d4
	bne	printwhite
donewhite:
	move.l 	regcol,d5
	swap	d5
	add.l	d5,d6
	move.l	loncol,d5
	swap	d5
	cmp.l	d5,d3
	blt	regword
	sub.l	#1,d6
regword:
	add.l	#1,d3
	clr.l	d0
	add.l	d2,d0
	add.l	#1,d0
	move.l	row,d5
	swap	d5
	cmp.l	d5,d0
	beq	maybe
	bra 	inner

maybe:	move.l	loncol,d5
	swap 	d5
	cmp.l	d5,d3
	bne	inner
	add.l	#1,d3
	move.l	column,d0
	swap	d0
	add.l	d0,d3
 	bra 	inner

doneinner:
	clr.l	d3
	add.l	#1,d2
	move.l	#CR,d0
	jsr	ScrnCharWrite
	move.l	#LF,d0
	jsr	ScrnCharWrite
	jsr 	FileReset
	bra	outer
doneouter:
	move.l	#CR,d0
	jsr	ScrnCharWrite
	move.l	#LF,d0
	jsr	ScrnCharWrite
	jsr	FileClose		
	bra	exitmsg

nofile:	lea	FileDNE,a0
	bra	writemsg

nocontents:
	lea	FileNoContent,a0
	bra	writemsg

writemsg:
	move.b	(a0)+,d0
	cmp.b	#NULL,d0
	beq	exitmsg
	jsr	ScrnCharWrite
	bra	writemsg

exitmsg:
	lea	PressAnyKey,a1
writex:	
	move.b	(a1)+,d0
	cmp.b	#NULL,d0
	beq	exit
	jsr	ScrnCharWrite
	bra	writex

exit:	
	jsr	KbdCharRead
	jsr	Exit

PressAnyKey:	dc.b	"Press any key to exit",CR,LF,NULL
FileDNE		dc.b	"File does not exist.",CR,LF,NULL
FileNoContent:	dc.b	"File contains nothing.",CR,LF,NULL
	even
bytes	ds.l	1
words	ds.l	1
longest	ds.l	1
count	ds.l	1
column	ds.l	1
regcol	ds.l	1
loncol	ds.l	1
white	ds.l	1
row		ds.l	1
offset	ds.l	1
crow	ds.l	1
ccol	ds.l	1
list	ds.l	1