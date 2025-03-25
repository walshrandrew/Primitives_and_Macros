TITLE Project 6 - String Primitives nd Macros     (project6_walshand.asm)

; Author: Andrew Walsh
; Last Modified: 8/14/24
; OSU email address: walshand@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6               Due Date: 8/11/24
; Description: User inputs a signed decimal integer then the program converts that to a string, then back into an integer
;               and calculates then displays the valid numbers entered, the total sum, and the rounded average back to the user.

INCLUDE Irvine32.inc

;---------------------------------------------------------------------------------
;NAME: mGetString
;DESCRIPTION: Displays a prompt message to the user and reads a string of input from the keyboard 
;             into a specified memory buffer. The length of the input string is returned in the 
;             specified output parameter. The macro utilizes the ReadString procedure to perform 
;             the input operation.
;PRECONDITIONS: 
;   - `prompt` is the offset of the string to be displayed as a prompt.
;   - `stringBuffer` is the offset to the memory location where the user input will be stored.
;   - `bufferSize` is the size of the buffer allocated for the user input.
;   - `inpLength` is the offset where the number of bytes read will be stored.
;POSTCONDITIONS: 
;   - User input is stored in `stringBuffer`.
;   - The length of the input string is stored at the location specified by `inpLength`.
;RECIEVES:
;   - `prompt` - Offset to the prompt message.
;   - `stringBuffer` - Offset to the buffer for storing the user input.
;   - `bufferSize` - Size of the buffer for user input.
;   - `inpLength` - Offset to store the length of the user input.
;RETURNS: None
;_________________________________________________________________________________
mGetString MACRO prompt, stringBuffer, bufferSize, inpLength

    ; save registers
    push    edx
    push    ecx
    push    eax

    ; display prompt
mDisplayString prompt

    ; read string
    mov     edx, stringBuffer
    mov     ecx, bufferSize
    call    ReadString
    mov     inpLength, eax

    ; clean stack
    pop     eax
    pop     ecx
    pop     edx
ENDM

;---------------------------------------------------------------------------------
;NAME: mDisplayString
;DESCRIPTION: Prints the string stored in the specified memory location using the WriteString procedure.
;PRECONDITIONS: `stringBuffer` should be the offset to the string that needs to be displayed.
;POSTCONDITIONS: The string at `stringBuffer` is output to the screen.
;RECIEVES:
;   - `stringBuffer` - Offset to the string to be printed.
;RETURNS: None
;_________________________________________________________________________________
mDisplayString MACRO stringBuffer

    ; Save edx and push stringBuffer address
    push    edx                                         
    mov     edx,    stringBuffer                              
    call    WriteString                                 
    pop     edx                                         
ENDM

ASCII_LO		= 48
ASCII_HI		= 57


.data
    intro           BYTE    "Project 6: String primitives and Macros by Andrew Walsh", 10                                                       
                    BYTE    " ", 10
                    BYTE    "Enter 10 signed decimal integers. The number must fit inside a 32 bit register.", 10
                    BYTE    "The integers will be shown as a list of valid inputs, their sum, and their average value.", 0
    prompt          BYTE    "Enter an integer: ", 0
    message         BYTE    "Please input again: ", 0
    errorMsg        BYTE    "Error: The input was too big. Please enter a valid number ; ", 0
    followTitle     BYTE    "Here are the signed decimal integers entered: ", 0
    sumTitle        BYTE    "Here are the sum of the integers: ", 0
    aveTitle        BYTE    "Here are the average (rounded) of the integers: ", 0
    farewell        BYTE    "Have a great summer break!!!", 0
    intString       BYTE    13 DUP(0)
    outString       BYTE    13 DUP(0)
    convString      BYTE    13 DUP(0)
    spaceBlank      BYTE    ", ", 0
    intNum          SDWORD  0
    stringLen       DWORD   ?
    intArray        SDWORD  10 DUP(?)
    stringArray     DWORD   10 DUP(?)
    sumNum          SDWORD  0
    aveNum          SDWORD  0


.code
main PROC

    ; Display introduction message
    mDisplayString  OFFSET  intro
    call    CrLF

    ; Initialize variables and start the loop
    mov     ecx, 10
    mov     edi, OFFSET intArray


    ; Call ReadVal to get an integer from the user ; prompt, buffer, maxLength, bytesRead
_displayLoop:
    push    OFFSET  intString
    push    SIZEOF  intString
    push    OFFSET  intNum
    push    OFFSET  stringLen
    push    OFFSET  prompt
    push    OFFSET  message
    push    OFFSET  errorMsg
    call    ReadVal

    ; Place into array
    mov     edx,    intNum
    mov     [edi],  edx
    add     edi,    TYPE    intArray

loop    _displayLoop

    ; Calculate sum and then averages
    push    OFFSET  intArray
    push    TYPE    intArray
    push    OFFSET  sumNum
    push    OFFSET  aveNum
    call    SumAverage

    ; display numbers
    mDisplayString  OFFSET  followTitle
    mov     esi,    OFFSET  intArray
    mov     edx,    [esi]
    add     esi,    TYPE    intArray
    push    edx     
    push    OFFSET  outString
    push    OFFSET  convString
    call    WriteVal
    mov     ecx,    9

_saveLoop:
    ;doc string here
    mDisplayString  OFFSET  spaceBlank
    mov     edx,    [esi]
    add     esi,    TYPE    intArray
    push    edx
    push    OFFSET  outString
    push    OFFSET  convString
    call    WriteVal

loop    _saveLoop
    call    CrLF
    
    ; display sum
    mDisplayString  OFFSET  sumTitle
    mov     edx,    sumNum
    push    edx
    push    OFFSET  outString
    push    OFFSET  convString
    call    WriteVal
    call    CrLF

    ;display average
    mDisplayString  OFFSET  aveTitle
    mov     edx,    aveNum
    push    edx
    push    OFFSET  outString
    push    OFFSET  convString
    call    WriteVal
    call    CrLF

; Farewell message
    mDisplayString  OFFSET  farewell
    

    ; End program
    invoke  ExitProcess, 0
main ENDP

ReadVal PROC
;---------------------------------------------------------------------------------------------------------
;;NAME: ReadVal
;DESCRIPTION: Reads a string of digits from the user, converts it to a signed 32-bit integer, 
;             and stores the result in the provided memory location. The input is validated to ensure 
;             it is a valid number with no letters or symbols.
;PRECONDITIONS: Offsets for the memory locations to store the user input string, the length of the 
;               string, and the output memory location for the converted integer should be provided 
;               on the stack.
;POSTCONDITIONS: The integer value is stored at the provided output memory location.
;RECIEVES: 
;   [ebp + 16] - Offset to the input buffer for the user string.
;   [ebp + 32] - Offset to the memory location to store the converted integer.
;   [ebp + 28] - Length of the input string.
;   [ebp + 20] - Offset to the error message string if the input is invalid.
;RETURNS: None
;__________________________________________________________________________________________________________

    push    ebp
    mov     ebp,    esp
    push    esi
    push    edi
    push    ecx
    push    edx
    push    eax
    push    ebx

    ; User enters input
    mGetString [ebp + 16], [ebp + 32], [ebp + 28], [ebp + 20]

_checkInput:
    ; set up memory registers
    mov     esi,    [ebp + 32]
    mov     edi,    [ebp + 24]
    mov     ecx,    [ebp + 20]
    mov     edx,    0
    mov     ebx,    1

    ; check length
    cmp     ecx,    1
    jle     _wrong  
    cmp     ecx,    12
    jge     _wrong

    ; check for "+", otherwise recieve as positive
    lodsb
    dec     ecx
    cmp     al,     '+'
    je      _skip

    ; check for "-", otherwise jump to _empty
    cmp     al,     '-'
    je      _negative
    inc     ecx
    jmp     _empty

_negative:
    mov     ebx,    -1

_skip:
    lodsb
    _empty:
        ; check if integer, if True return number
        cmp     al,     ASCII_LO
        jl      _wrong
        cmp     al,     ASCII_HI
        sub     al,     ASCII_LO

        ; input times 10
        push    ebx
        push    eax
        mov     eax,    edx
        mov     edx,    0
        mov     ebx,    10
        imul    ebx
        cmp     edx,    0
        jne     _wrong
        mov     edx,    eax
        pop     eax

        ; add integer
        movsx   ebx,    al
        add     edx,    ebx
        jo      _stackOverflow
        pop     ebx

    loop    _skip
    jmp     _good

_stackOverflow:
    ; clean up memory
    pop     ebx

_wrong:
    ; display error mesage and ask to try again
    mov     edx,    0
    mDisplayString  [ebp + 8]
    mGetString      [ebp + 12], [ebp + 32], [ebp + 28], [ebp + 20]
    jmp             _checkInput

_good:
    ; if negative store value
    mov     eax,    edx
    imul    ebx
    mov     [edi],  eax

    ; pop and clean up stack
    pop     ebx
    pop     eax
    pop     edx
    pop     ecx
    pop     edi
    pop     esi
    pop     ebp
    ret     28

ReadVal ENDP

WriteVal PROC
;-------------------------------------------------------------------------------------------------
;NAME: WriteVal
;DESCRIPTION: Converts a signed 32-bit integer to a string of ASCII digits and displays it 
;             using the mDisplayString macro. Handles both positive and negative values.
;PRECONDITIONS: The integer value to be converted and displayed should be provided on the stack.
;POSTCONDITIONS: The ASCII representation of the integer value is displayed.
;RECIEVES: 
;   [ebp + 16] - The signed 32-bit integer value to be converted and displayed.
;   [ebp + 12] - Offset to the buffer where the ASCII string representation will be stored.
;   [ebp + 8]  - Offset to the output string for display.
;RETURNS: None
;_________________________________________________________________________________________________

        
    ; save memory address
    push    ebp
    mov     ebp,    esp
    push    edx
    push    eax
    push    ebx
    push    ecx
    push    edi
    push    esi

    ; check sign
    mov     edx,    [ebp + 16]
    cmp     edx,    0
    jl      _neg
    mov     al,     '+'
    jmp     _stack

_neg:
    ; saves negative
    mov     al,     '-'
    neg     edx

_stack:
    ; save memory for stack
    push    eax
    mov     ecx,    0
    mov     edi,    [ebp + 8]

_increment:
    ; num % 10
    mov     eax,    edx
    mov     ebx,    10
    cdq
    idiv    ebx

    ; save R
    push    eax
    mov     eax,    edx
    add     al,     ASCII_LO
    stosb
    pop     eax

    ; incrementing
    inc     ecx
    mov     edx,    eax
    cmp     eax,    0
    jne     _increment

    ; check if negative
    pop     eax
    cmp     al, '-'
    je      _sign
    jmp     _nextsign

_sign:
    ; places a sign
    stosb
    inc     ecx

_nextsign:
    ; increment for next loop
    mov     esi,    [ebp + 8]
    add     esi,    ecx
    dec     esi
    mov     edi,    [ebp + 12]

_convert:
    ; convert back from string to integer
    std
    lodsb
    cld
    stosb
loop    _convert

    mov     al,     0
    stosb

    mDisplayString  [ebp + 12] ; Display the output

    ; restore and clear
    pop     esi
    pop     edi
    pop     ecx
    pop     ebx
    pop     eax
    pop     edx
    pop     ebp
    ret     16

WriteVal ENDP

SumAverage PROC
;-------------------------------------------------------------------------------------------------------
;NAME: SumAverage
;DESCRIPTION: Calculates the sum and average of 10 signed 32-bit integers stored in memory. 
;             The results are stored in the provided memory locations.
;PRECONDITIONS: The memory locations for the integers and the result locations for the sum 
;               and average should be provided on the stack.
;POSTCONDITIONS: The sum and average of the integers are stored at the respective memory locations.
;RECIEVES: 
;   [ebp + 20] - Offset to the array of integers.
;   [ebp + 16] - Number of integers (should be 10).
;   [ebp + 12] - Offset to the memory location for the sum.
;   [ebp + 8]  - Offset to the memory location for the average.
;RETURNS: None
;_______________________________________________________________________________________________________
    push    ebp
    mov     ebp,    esp
    push    esi
    push    edi
    push    ecx
    push    eax

    ; sum loop setup
    mov     esi,    [ebp + 20]
    mov     ecx,    10
    mov     eax,    0

    ;sumNum calculations
_sum:
    add     eax,    [esi]
    add     esi,    [ebp + 16]
loop    _sum

    ; save loop  info
    mov     edi,    [ebp + 12]
    mov     [edi],  eax
    
    ; aveNum calculations
    mov     ecx,    10
    cdq
    idiv    ecx

    ; save loop info
    mov     edi,    [ebp + 8]
    mov     [edi],  eax

    ; clean up stack
    pop     eax
    pop     ecx
    pop     edi
    pop     esi
    pop     ebp
    ret     16

SumAverage ENDP

END MAIN