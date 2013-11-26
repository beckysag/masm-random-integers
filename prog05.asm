TITLE Prime Numbers       (Prog05.asm)

; Author: Rebecca Sagalyn
; Course / Project ID: CS271 #05		Date: 2/28/13
; Description:
; 1. Introduce the program.
; 2. Get a user request in the range [min=10 .. max=200].
; 3. Generate request random integers in the range [lo=100 .. hi=999], storing them in consecutive elements of an array.
; 4. Display the list of integers before sorting, 10 numbers per line.
; 5. Sort the list in descending order (i.e., largest first).
; 6. Calculate and display the median value, rounded to the nearest integer.
; 7. Display the sorted list, 10 numbers per line.

; Extra Credit (Be sure to describe your extras in the program header block): 
;   2. Use a recursive sorting algorithm (e.g., Merge Sort, Quick Sort, Heap Sort, etc.). 
;   4. Generate the numbers into a file; then read the file into the array. 




INCLUDE Irvine32.inc

;********************************************************************************** 
;*								 SHARED DATA			                          * 
;********************************************************************************** 

local_1	EQU DWORD PTR [ebp-4]
local_2	EQU DWORD PTR [ebp-8]
local_3	EQU DWORD PTR [ebp-12]
MIN = 10
MAX = 200
LO = 100
HI = 999
.data
	intro1		BYTE	"Sorting Random Integers		Programmed by Rebecca Sagalyn",02h,0Dh,0Ah,0Ah
				BYTE	"This program generates random numbers in the range [100 .. 999], ",0Dh, 0Ah
				BYTE	"displays the original list, sorts the list, and calculates the median value.",0Dh, 0Ah
				BYTE	"Finally, it displays the list sorted in desc order.",0Dh,0Ah,0Dh,0Ah,0
	prompt		BYTE	0Dh, 0Ah,"How many numbers should be generated?  [10 .. 200]:  ",0
	err_str		BYTE	"Invalid input",0
	strUn		BYTE	"The unsorted random numbers:",0
	SIZE_UN	= ($ - strUn)
	prompt2		BYTE	"The median is:  ",0
	strSort		BYTE	"The sorted list:",0
	SIZE_SORT = ($ - strSort)
	request		DWORD	?
	arr			DWORD	MAX	DUP(?)
	lf			DWORD ?
	rt			DWORD ?
	outHandle	DWORD ?												; handle to standard console output device
	fHandle		DWORD ?												; handle to output file
	fname		BYTE "C:\Users\Rebecca\Desktop\test.txt",0			; file name	
	buff		BYTE 5 DUP(0)										; buffer pointer

;********************************************************************************** 
;*								 PROCEDURES				                          * 
;********************************************************************************** 

.code

;----------------------------------------------------------------------------------
main PROC
	INVOKE	GetStdHandle, STD_OUTPUT_HANDLE					; init handle
	mov		[outHandle], eax								; store handle in outHandle
; Intro
	push	OFFSET intro1									; @intro1
	call	intro											; Introduce program
; Get number from user, store in request					
	push	OFFSET err_str									; @err_str
	push	OFFSET prompt									; @prompt
	push	OFFSET request									; @request
	call	getData											; Get user data
	exit
; Generate random numbers into file, one per line
	call	Randomize
	push	OFFSET buff										; @buff
	push	OFFSET fhandle									; @fhandle
	push	OFFSET fname									; @fname (file to write to)
	push	request											; request
	call	writeNums
; Read numbers from file into array
	push	OFFSET buff										; @buff
	push	OFFSET arr										; @arr
	push	OFFSET fname									; @fname (file to write to)
	push	request											; request
	call	readNums
; Display unsorted list
	push	OFFSET strUn
	push	OFFSET arr
	push	request
	call	displayList
; Sort List
	push	OFFSET arr										; @arr
	push	request											; request
	call	sortList
; Display sorted list
	push	OFFSET strSort
	push	OFFSET arr
	push	request
	call	displayList

; Display median
; Calculate and display the median value, rounded to the nearest integer.
	exit

main ENDP


;----------------------------------------------------------------------------------
intro PROC
; Introduces program and programmer, and describes program.
; Receives: [ebp+8] = @intro1
; Returns: nothing
; Proconditions: none
; Registers changed: none
;----------------------------------------------------------------------------------
	push	ebp
	mov		ebp, esp
	push	edx
	mov		edx, [ebp+8]									; introduce program & programmer
	call	WriteString	
	pop		edx
	pop		ebp
	ret		4
intro ENDP


;----------------------------------------------------------------------------------
getData PROC
; Prompts user to enter number of integers, in range [min..max], then validates number
; Receives: [ebp+8] = @request, [ebp+12] = @prompt, [ebp+16] = @err_str
; Returns: number entered by user in request
; Proconditions:none
; Registers changed: none
;----------------------------------------------------------------------
	push	ebp
	mov		ebp, esp
	pushad
	mov		edi, [ebp+8]								; @request in edi
	
RequestNum:
	mov		edx, [ebp+12]								; edx = @prompt
	call	WriteString									; tell user to enter a number
	call	ReadDec										; save number in eax
	;mov		eax, 4

; verify: request >= MIN && request <= MAX
	cmp		eax, MIN									
	jl		InvalidRequest								; if request < MIN, reprompt
	cmp		eax, MAX
	jg		InvalidRequest								; if request > MAX, reprompt
	jmp		ValidRequest								; else, continue

InvalidRequest:
	mov		edx, [ebp+16]								; edx = @err_str
	call	WriteString
	call	Crlf
	jmp		RequestNum									; re-prompt

ValidRequest:
	mov		[edi], eax									; store number in request




	popad
	pop		ebp
	ret		12
getData ENDP
;----------------------------------------------------------------------

;----------------------------------------------------------------------
DecToASCII PROC
; input = 3 digits dec number
; buff = 4 byte array of BYTES
; uses: eax, ebx, ecx, edx, esi, ebp
; reg changed: eax, ebx, edx, esi
;----------------------------------------------------------------------
	push	ebp
	mov		ebp, esp
	pushad
	
	mov		ax, [ebp+8]					; ebx = dec num
	mov		edx, [ebp+12]				; @buff in edx
	mov		ecx, 3						; loop counter
L1:
; loop sets buff[0], buff[1], buff[2]
	mov		bl, 10						; bl = 10
	div		bl							; AH = digit (7), AL = quotient (65)
	mov		bl, ah						; bl = ah = 7
	add		bl, 48						; bl = ascii form of digit
	mov		ah, 0						; ax = 65 (for next DIV instruction)
	mov		[edx+ecx-1], bl				; buff[ecx] = ascii digit
	loop	L1

; set buff[3], buff[4]
	mov		al, 13
	mov		[edx+3], al
	mov		al, 10
	mov		[edx+4], al
	
	popad	
	pop		ebp
	ret		8
DecToASCII ENDP
;----------------------------------------------------------------------

;----------------------------------------------------------------------
readNums PROC
; Description: Read numbers from file into array
; Receives: ebp+8 = request, ebp+12 = @fname, ebp+16 = @arr
; Returns: arr, with request numbers read from file
; Proconditions: numbers are written one per line in file [fname]
;				 numbers are all 3 digits (leading zeros if needed)
;				 console handle has been initialized
; Registers changed: none
;----------------------------------------------------------------------
	LOCAL	pFname:DWORD
	LOCAL	filehandle: DWORD
	pushad
	mov		eax, [ebp+12]								; @fname
	mov		pFname, eax									; @fname
	mov		esi, [ebp+16]								; @arr

	INVOKE	CreateFile,									; open file [fname] for reading
		pFname, GENERIC_READ, 
		DO_NOT_SHARE, NULL,OPEN_EXISTING, 
		FILE_ATTRIBUTE_NORMAL, 0
	mov		filehandle, eax								; store file handle in fhandle

	mov		ecx, [ebp+8]								; init ecx (loop counter) to request
L1:														; for i = request, i >0, i--
	pushad
	INVOKE	ReadFile,									; Read number from file into buffer
		filehandle,										; handle
		[ebp+20],										; buffer pointer
		5,												; number of bytes to read
		NULL,											; num bytes read
		0												; overlapped execution flag		
	popad

	mov		edi, [ebp+20]								; edi = @buff
	mov		eax, 0
	; get hundreds digit into edx
		mov		al, [edi]
		sub		al, 48										; hundreds digit
		mov		bl, 100
		mul		bl											; eax = hundreds digit * 100
		mov		edx, eax									; store in edx
		inc		edi
	; get tens digit into edx
		mov		eax, 0
		mov		al, [edi]		
		sub		al, 48										; eax = digit in tens place
		mov		bl, 10	
		mul		bl											; eax = tens digit * 10
		add		edx, eax									; add to edx, edx = first two digits
		inc		edi
	; get ones digit into edx
		mov		al, [edi]		
		sub		al, 48										; eax = digit in ones place
		add		edx, eax									; add to edx (edx = all 3 digits)
	; store in array
		mov		[esi], edx

		add		esi, 4										; esi points to next array element
	loop	L1											; loop

	INVOKE	CloseHandle, fHandle						;close file handle
	popad
	ret 16
readNums ENDP
;----------------------------------------------------------------------

;----------------------------------------------------------------------
writeNums PROC
; Description: Generate random numbers and write to file, one number per line
; Receives: ebp+8 = request, ebp+12 = @fname, ebp+16 = @fhandle, ebp+20 = @buff
; Returns: none
; Proconditions: request != null
;				 console handle has been initialized
; Registers changed: none
;----------------------------------------------------------------------
	push	ebp
	mov		ebp, esp
	sub		esp, 4								; make space for 1 local var
	push	esi
	push	eax
	push	ebx
	push	ecx
	push	edx
	mov		esi, [ebp+16]						; store @fhandle in esi
	mov		ecx, [ebp+8]						; store request in ecx (loop counter)
	
	; range = hi - lo + 1
	mov		eax, HI
	sub		eax, LO
	inc		eax									; eax = hi - lo + 1
 	mov		local_1, eax						; store "range" in local1
	
	push	ecx									; save ecx before Win API function
	INVOKE	CreateFile,							; create/overwite file [fname] for writing
		[ebp+12], GENERIC_WRITE, 
		DO_NOT_SHARE, NULL,OPEN_ALWAYS, 
		FILE_ATTRIBUTE_NORMAL, 0
	pop ecx
	mov		[esi], eax							; store file handle in fhandle
	
L1:												; while count < request
	mov		eax, local_1						; eax = range
	call	RandomRange							; random num in eax

	push [ebp+20]								; @buff
	push eax									; random number
	call DecToASCII								; convert random num to ascii digits

	push	ecx									; save ecx before Win API function
	INVOKE WriteFile,							; write to file
		[esi],									; file handle
		[ebp+20],								; buffer pointer
		5,										; number of bytes to write
		NULL,									; num bytes written
		0										; overlapped execution flag
	pop		ecx
	loop	L1									; sub 1 from ecx, or leave if ecx == 0
LeaveArr:
	INVOKE	CloseHandle, fHandle
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		esi
	mov		esp, ebp							; reset esp, remove local var
	pop		ebp
	ret		16									; clean up 4 32-bit variables
writeNums ENDP
;----------------------------------------------------------------------

;----------------------------------------------------------------------
sortList PROC
; Description:
; Receives: 2 params
; Returns:
; Proconditions:
; Registers changed:
;----------------------------------------------------------------------
	push	ebp
	mov		ebp, esp
	push	esi
	push	eax
	push	ebx
	push	ecx
	mov		edi, esp					; edi points to location before adding array

	;mov		esi, [ebp+12]			; store @arr in esi
	mov		ebx, [ebp+8]				; store request in ebx (size)
	mov		eax, ebx					; move size to eax
	mov		ecx, 4						; move 4 to ecx
	mul		ecx							; multiple array size * 4 to get total size
	add		eax, 4						; space for 1 more DWORD variable
	sub		esp, eax					; make space for array
	; now edi - 4 is single variable ; edi - eax is start of array
	mov		esi, esp					; esi points to start of result array

	push	[ebp+12]	; @arr
	push	0			; start
	push	[ebp+8]		; size
	push	esi			; @result
	call	merge

	mov		esp, edi	
	pop		ecx
	pop		ebx
	pop		eax
	pop		esi
	;mov		esp, ebp			; reset esp, remove local var
	pop		ebp
	ret		8
sortList ENDP
;----------------------------------------------------------------------
;----------------------------------------------------------------------
merge PROC
;----------------------------------------------------------------------
	;push	ebp				; these two lines done by OS
	;mov	ebp, esp		;
	LOCAL	left:DWORD
	LOCAL	right:DWORD
	LOCAL	i:DWORD
	LOCAL	len:DWORD
	LOCAL	dist:DWORD
	LOCAL	r:DWORD
	LOCAL	l:DWORD			; l and r are to the positions in the left and right subarrays
	push	eax
	push	ebx
	push	edi
	push	ecx
	push	edx
	push	esi

	; ebp + 8 = @result 
	; ebp + 12 = right
	; ebp + 16 = left
	; ebp + 20 = @arr

	mov		edi, [ebp+20]			; store @arr in edi
	mov		esi, [ebp+8]			; store @result in esi
	mov		eax, [ebp+12]
	mov		right, eax				; store right
	mov		eax, [ebp+16]
	mov		left, eax				; store left 
	mov		l, eax					; l = left

; base case: one element (if r == l+1, return)
	add		eax, 1				; add 1 to left (in eax)
	cmp		eax, right
	je		LeaveProc			; if left+1 = right, exit
	
	; else
	; set len = right - left
	mov		eax, right
	sub		eax, left			; right - left in eax
	mov		len, eax			; length = right - left

	; set dist = right - left / 2
	mov		ebx, 2				; ebx = 2
	mov		edx, 0
	div		ebx					; eax = (right - left) / 2
	mov		dist, eax			; dist = (right - left) / 2

	; set r = left + mid_distance
	mov		ebx, left				; ebx = left
	add		ebx, eax				; ebx = left + dist
	mov		r, ebx					; r = left + dist 

; sort each subarray
	; push parameters for first call
	push	[ebp+20]				; @arr
	push	left					; left
	push	r						;left + dist
	push	[ebp+8]					; @result
	call	merge					; recursive call on left subarray (from 0  -> midpoint)

	; push parameters for second call
	push	[ebp+20]				; @arr
	push	r						; left + dist
	push	right					; right
	push	[ebp+8]					; @result
	call	merge					; recursive call on right subarray (from midpoint -> max)


; merge arrays together
	; Check to see if any elements remain in the left array; 
	; if so, we check if there are any elements left in the right array; 
	; if so, we compare them.  
	; Otherwise, we know that the merge must use take the element from the left array
	
	mov		i, 0								; i = 0
	BeginFor:
	;-------------------------------------------
	; for(i = 0; i < len; i++)
		mov ebx, i
		mov		eax, len
		cmp		i, eax								; compare i to len
		jge		LeaveFor							; if i >= len, exit for-loop

		;if (l < left + dist) AND (r == right || max(arr[l], arr[r]) == arr[l])
			; if l >= r
			mov		eax, left
			add		eax, dist						; eax = left + dist
			cmp		l, eax							; compare l to left+dist
			jge		FromRight

			; if here, first part is true, now check second part
			; (r == right || max(arr[l], arr[r]) == arr[l])
			; if either one is true, whole thing is true, and go to FromLeft
			; (r == right)
			; edi ->arr
			; esi ->result

			; check: (max(arr[l], arr[r]) == arr[l])
				; find max(arr[l], arr[r])
				mov		eax, l
				mov		ebx, 4
				mul		ebx
				mov		ecx, eax								; ecx = l * 4
				mov		eax, r
				mul		ebx
				mov		edx, eax								; edx = r * 4

				mov		eax, [edi+ecx]							; arr[l] in eax
				mov		ebx, [edi+edx]							; arr[r] in ebx
				cmp		eax, ebx
				jge		LeftMax									; if left >= right
				RightMax:										; arr[r] > arr[l]
					mov		eax, [edi+edx]
				LeftMax:										;arr[l] >= arr[r]
																; eax = max already																
				; is max == arr[l]?
				cmp		eax, [edi+ecx]
				je		FromLeft								; if true, FromLeft
																; else check second condition

			; check: r == right
				mov		eax, r
				mov		ebx, right
				cmp		eax, ebx
				je		FromLeft
				; if this isnt true, then second condition is false, so whole condition is false
				; go to FromRight
				jmp		FromRight

		FromLeft:
				;result[i] = arr[l];
				mov		eax, l
				mov		ebx, 4
				mul		ebx										; eax = l * 4
				mov		ecx, [edi+eax]							; move arr[l] to ecx

				mov		eax, i
				mul		ebx										; eax = i * 4
				mov		[esi+eax], ecx							; result[i] = arr[l]
				;l++;
				add		l, 1
				jmp		ContinueFor

			;else
		FromRight:
				;result[i] = arr[r];
				mov		eax, r
				mov		ebx, 4
				mul		ebx										; eax = r * 4
				mov		ecx, [edi+eax]							; move arr[r] to ecx

				mov		eax, i
				mul		ebx										; eax = i * 4
				mov		[esi+eax], ecx							; result[i] = arr[r]
				mov		ebx, [esi+eax]

				;r++;
				add		r, 1

	ContinueFor:
		add		i, 1
		jmp		BeginFor
	; end for-loop
	;-------------------------------------------
	LeaveFor:
	
		mov		eax, left
		mov		i, eax				; i = left
		mov		lf, eax
		mov		ebx, right
		mov		rt, ebx
		mov eax, [esi]
	For2:
	;-------------------------------------------
	; Copy the sorted subarray back to the input
	; for(i = left; i < right; i++) 
		mov		eax, i
		cmp		eax, right
		jge		Leave2			; if i >= right, leave loop

		; arr[i] = result[i - left];
				mov		eax, i
				sub		eax, left					; eax = i - left
				mov		ebx, 4
				mul		ebx							; eax = 4 * (i - left)
				mov		ecx, eax					; ecx = 4 * (i - left)
				mov		eax, i
				mul		ebx							; eax = 4 * i
				mov		edx, eax					; edx = 4 * i
								
				mov		eax, [esi+ecx]				;eax = result[i - left]
				mov		[edi+edx], eax				;arr[i] = result[i - left]	
					
		add		i, 1
		jmp		For2
	;-------------------------------------------
	Leave2:

LeaveProc:
	pop		esi
	pop		edx
	pop		ecx
	pop		edi
	pop		ebx
	pop		eax
	ret		16					; remove 4 parameters from stack
merge ENDP
;----------------------------------------------------------------------




























;----------------------------------------------------------------------
displayMed PROC
; Description:
; Receives:
; Returns:
; Proconditions:
; Registers changed:
;----------------------------------------------------------------------
	ret
displayMed ENDP
;----------------------------------------------------------------------

;----------------------------------------------------------------------
displayList PROC
; Description:
; Receives:
; Returns:
; Proconditions:
; Registers changed:
;----------------------------------------------------------------------
	push	ebp
	mov		ebp, esp
	sub		esp, 12				; make space for local vars
	push	esi
	push	eax
	push	ebx
	push	ecx
	push	edx
	mov		edx, [ebp+16]			; store @title in edx
	mov		esi, [ebp+12]			; store @arr in esi
	mov		ebx, [ebp+8]			; store request in ebx
	mov		local_1, 1				; "columnCount", initialized to 1
	call	Crlf
	call	Crlf
	call	WriteString				; print title
	call	Crlf

	mov		local_2, 00202020h		; move 3 spaces to local_2
	mov		local_3, 1				; "columnCount" in local_3
	mov		ecx, 0					; set "count" to 0 in ecx
L1:	
	cmp		ecx, ebx				; while count < request
	jge		LeaveArr
	cmp		local_3, 10				; check colCount to see if new line needed
	jle		SameLine				; if colCount > 10, new line
	mov		local_3, 1				; reset colCount to 1
	call	Crlf					; move to new line
SameLine:
	mov		eax, [esi]				; arr[count]
	call	WriteDec
	mov		edx, ebp
	sub		edx, 8					; move address of local variable to edx
	call	WriteString	
	add		esi, 4					; esi points to next index
	add		ecx, 1					; increment index number
	add		local_3, 1
	jmp		L1						; loop
LeaveArr:
	call	Crlf
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		esi
	mov		esp, ebp			; reset esp, remove local var
	pop		ebp
	ret		12
displayList ENDP
;----------------------------------------------------------------------


END main