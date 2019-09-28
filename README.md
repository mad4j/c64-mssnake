# c64-mssnake
Commmodore 64 porting of Ms Snake!

## BASIC Launcher

### Code
```
2019 SYS2130
```

### Assembly
```
$0801 $0B
$0802 $08   ; low byte, high byte address of the next basic line

$0803 $E3
$0804 $07   ; low byte, high byte of line number 2019

$0805 $9E   ; SYS command

$0806 $32   ; '2'
$0807 $31   ; '1'
$0808 $33   ; '3'
$0809 $30   ; '0'

$080A $00   ; end of line marker

$080B $00  
$090C $00   ; end of program marker
```
