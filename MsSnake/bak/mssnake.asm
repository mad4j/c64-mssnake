;1 block [254b] snake by Diego Barzon - 19/11/2004

*= $0801
; Variables

Pointer = $B0
Points = $39
Direction = $Ea
TailX = $F8
TailY = $F9
Wait = $Fa
HeadX = $Fb
HeadY = $Fc
Speed = $Fd
Mask = $Fe

; Constants

Screen = $08 ; To be ror'd so means $04 / buffer located at $84
InitialSpeed = $14
Pattern = $A0   ; Pattern must have bit 7&5 on (>= $A0) and low nibble 0
Space = $20

; Basic sys call (2004 Sys2130)
;
; 10 bytes

          BYTE           $0B,$08,$D4,$07,$9E,$32,$31,$33,$30,$00
          
          
          



; Construct a pointer to the screen and load value
;
; Input: X = y Coord. ,Y = x Coord.
;        c: 0 - video base, 1 - Buffer
; Output: XY not modified, A pointed value, c=0
;
; 31 bytes

GetBuf Cmp #$00          ;2 Equal to sec but using basic data (Thx NinjaDRM)
GetVid Stx Pointer       ;2 to run GetVid caller must clear carry
       Lda #$FE          ;2 Used to exit loop: bit 0 of [pointer+1] is not
       Sta Pointer+1     ;2 supposed to be set during the 1st run of the loop
       Lda #Screen       ;2
       Ror               ;1 04 => Screen, 84 => buffer
RolLop Asl Pointer       ;2
       Bcc RolFix        ;2
       Adc #$13          ;2 Carry set for sure and it'll rol so ($28/2)-1 =$13
       Bcc RolFix        ;2
       Inc Pointer+1     ;2 Adjust hi-byte
RolFix Asl               ;1 Rol low-byte
       Rol Pointer+1     ;2 Rol hi-byte
       Bcs RolLop        ;2 Loop seven more times (until we reach 0 in $FE)
       Sta Pointer       ;2 Store low byte (hi byte still ready)
       Lda (Pointer),y   ;2 Load pointed value
Return Rts               ;1



; Bonus management
;
; Input: A=$0a
; Output: undefined (output of $Bdc9 kernel routine)
;
; 40 bytes

Bonus Inc Wait           ;2 Increment worm length
      Adc Points         ;2 Update score
      Sta Points         ;2
      Bcc ChkLp          ;2
      Inc Points+1       ;2
ChkLp Ldx $d41b          ;3 Load random coordinates (SID 3rd voice value)
      Cpx #$19           ;2 Y bound
      Bcs ChkLp          ;2
ChkL2 Ldy $d41b          ;3
      Cpy #$28           ;2 X bound
      Bcs ChkL2          ;2 till we get an useful pair
      Jsr GetVid         ;3 Check position
      Eor #Space         ;2
      Bne ChkLp          ;2 Loop until we get a free position
      Sta $D3            ;2 Update current column to 0 (A=0)
      Lda #$2A           ;2 '*'
      Sta (Pointer),y    ;2 Store bonus
      Jmp $Bdc9          ;3 Print score and RTS



; Initialization and start
;
; Input: nothing
; Output: A=Pattern, X=81, Y=0, c=0
;
; 39 bytes

Main   jsr $E544        ;3 Clear screen
       ldy #$81         ;2 was dey (iAN)
       Sty $D40f        ;3 Initialize SID (noise waveform on 3rd voice)
       Sty $D412        ;3
       Sta Direction    ;2 y=131 so worm will be 3 blocks long
       Ldx #$07         ;2 Looks like 7 is a good value to initialize
       Txa              ;1 most of the variables involved... :)
Init   Sta TailX-2,x    ;2
       Dex              ;1
       Bne Init         ;2
       Clc              ;1 X=0 because of the loop so get a pointer
       Jsr GetVid       ;3 to the first screen row
       Ldy #$50         ;2 Write pattern in first and second row
       Lda #Pattern     ;2
RowLp  Dey              ;1
       Sta (Pointer),y  ;2
       Bne RowLp        ;2
       Sty Points       ;2 Clear score
       Sty Points+1     ;2
       Jsr ChkLp        ;3 Print score and put first bonus


; Main loop
;
; Input: X=wait time (first one's longer)
; Output: X-1
;
; 5 Bytes

MainLp Stx Speed  ;2 Update timer
       Dex        ;1
       Bne TestK  ;2


; Draw snake head
;
; Input: nothing
; Output: A=0, XY current head position (X is y coord., Y is x coord.)
;
; 61 Bytes

Head  Ldx HeadY          ;2 Set pointer to current position in buffer
      Ldy HeadX          ;2
      Jsr GetBuf         ;3
      Lda $Dc00          ;3 Normal value $7F, microswitch active on 0
      Eor #$7f           ;2
      And Mask           ;2 Normalized => direction in first nibble
      Bne Chng           ;2 Direction change?
      Lda Direction      ;2 No, so load current direction
Chng  Sta Direction      ;2 Store direction
      Sta (Pointer),y    ;2 also in buffer for deleting tail
      Ora #$E0           ;2 => Used to guess if last move is U/D or L/R
      Jsr Update         ;3 Update positions
      Sty HeadX          ;2 Store
      Stx HeadY          ;2
      Bcs Main           ;2 If border crossed GAME OVER, restart
      And #$04           ;2 Calculate mask so that worm can't go
      Beq NoMod          ;2 to the opposite direction in the next cycle
      Eor #$0B           ;2 if current direction is L or R then mask L and R
NoMod Eor #$0C           ;2 if current direction is U or D then mask U and D
      Sta Mask           ;2 Even if masked out, current direction still works
      Jsr GetVid         ;3 Load current position value
      Pha                ;1
      Lda #Pattern       ;2 Store pattern in current position
      Sta (Pointer),y    ;2
      Pla                ;1
      Eor #Space         ;2 Check if previous loaded value is pattern
      Bmi Main           ;2 if so GAME OVER, restart
      Beq Tail           ;2 No: go to tail cut
      Jsr Bonus          ;3 Yes: go updating

; Delete Tail
;
; Input: nothing
; Output: A=undefined (should be 0), XY current tail position
; 25 Bytes

Tail  Lsr Wait               ;2
      Bcs NewTim             ;2 Wait if worm has to grow
      Ldx TailY              ;2 Load current tail position in buffer
      Ldy TailX              ;2
      Jsr GetVid             ;3 Carry is 0 for sure because of GetBuf
      And #$2F               ;2 Update screen deleting tail pattern
      Sta (Pointer),y        ;2
      Jsr GetBuf             ;3 Get real tail position (in buffer)     
      Jsr Update             ;3 Update tail position using the information
      Stx TailY              ;2 in buffer. Store values
      Sty TailX              ;2



; Wait retrace & check keyboard
;
; Input: nothing
; Output: A=0, X=initial speed (for timer), c= 0 for loop or 1 for end
;
; 11 Bytes

NewTim Ldx #InitialSpeed  ;2 Reset speed countdown
TestK  Lsr $C6            ;2 Check button pressed
WaitRT Lda $D012          ;3 Wait retrace
       Bne WaitRT         ;2
       Bcc MainLp         ;2 if button pressed continue and finish with RTS



; Update directions
;
; Input: A=Nibble(LRDU) or #$E0
; Output: Bit 4 of A: 0 if U/D update 1 if L/R update, XY update according
;         to input nibble
;
; 20 Bytes

Update Lsr                ;1 Test UP bit
       Bcc Up             ;2
       Dex                ;1
       Bcs Check          ;2 Exit update, no more lsr to preserve bit 4
Up     Lsr                ;1 Test DOWN bit
       Bcc Down           ;2
       Inx                ;1
       Bcs Check          ;2 Exit update, no more lsr to preserve bit 4
Down   Lsr                ;1 Test RIGHT bit
       Bcc Right          ;2
       Dey                ;1
Right  Lsr                ;1 Test LEFT bit
       Bcc Check          ;2
       Iny                ;1


; Check edges
;
; Input: XY coordinates to check
; Output: c=1 if bound crossed, c=0 if not
;
; 7 Bytes

Check Cpy #$28           ;2 is Y between 0 and $27 (dec 39)
      Bcs SetC           ;2
      Cpx #$19           ;2 is X between 0 and $18 (dec 24)
SetC  Rts                ;1

