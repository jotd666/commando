;
; Commando (C) 1985 CAPCOM.
;
; Reverse engineering work by Scott Tunstall, Paisley, Scotland. 
; Tools used: MAME debugger & Visual Studio Code text editor.
; Date: 23 Feb 2020. Keep checking for updates. 
; 
; Please send any questions, corrections and updates to scott.tunstall@ntlworld.com
;
; Be sure to check out my reverse engineering work for Robotron 2084, Galaxian and Scramble too, 
; at http://seanriddle.com/robomame.asm, http://seanriddle.com/galaxian.asm and http://seanriddle.com/scramble.asm respectively.
;


/*
Conventions: 

NUMBERS
=======

The term "@ $" means "at memory address in hexadecimal". 
e.g. @ $1234 means "refer to memory address 1234" or "program code @ memory location 1234" 

The term "#$" means "immediate value in hexadecimal". It's a habit I have kept from 6502 days.
e.g. #$60 means "immediate value of 60 hex" (96 decimal)

If I don't prefix a number with $ or #$ in my comments, treat the value as a decimal number.


LABELS
======
I have a labelling convention in place to help you identify the important parts of the code quicker.
Any subroutine labelled with the SCRIPT_ , DISPLAY_ or HANDLE_ prefix are critical "top-level" functions responsible 
for calling a series of "lower-level" functions to achieve a given result.   

If this helps you any, think of the "top level" as the main entry point to code that achieves a specific purpose.  

Routines prefixed HANDLE_ manage a particular aspect of the game.
    For example, HANDLE_PLAYER_MOVE is the core routine for reading the player joystick and moving the player ship. 
    HANDLE_PLAYER_SHOOT is the core routine for reading the player fire button and spawning a bullet.

I expect the purpose of DISPLAY_ is obvious.

SCRIPTS are documented below - see docs for SCRIPT_NUMBER ($4005)


ARRAYS, LISTS, TABLES
=====================

The terms "entry", "slot", "item", "record" when used in an array, list or table context all mean the same thing.
I try to be consistent with my terminology but obviously with a task this size that might not be the case.

Unless I specify otherwise, I all indexes into arrays/lists/tables are zero-based, 
meaning element [0] is the first element, [1] the second, [2] the third and so on.

FLAGS
=====
The terms "Clear", "Reset", "Unset" in a flag context all mean the flag is set to zero.
                                                                               

COORDINATES
===========

X,Y refer to the X and Y axis in a 2D coordinate system, where X is horizontal and Y is vertical.

*/


Memory map taken from https://github.com/mamedev/mame/blob/master/src/mame/drivers/commando.cpp

MAIN CPU
0000-bfff ROM
d000-d3ff Video RAM
d400-d7ff Color RAM
d800-dbff background video RAM
dc00-dfff background color RAM
e000-ffff RAM
fe00-ff7f Sprites
read:
c000      IN0
c001      IN1
c002      IN2
c003      DSW1
c004      DSW2
write:
c808-c809 background scroll x position
c80a-c80b background scroll y position
SOUND CPU
0000-3fff ROM
4000-47ff RAM
write:
8000      YM2203 #1 control
8001      YM2203 #1 write
8002      YM2203 #2 control
8003      YM2203 #2 write


; Port bits taken from https://github.com/RetroPie/mame4all-pi/blob/master/src/drivers/commando.cpp

PORT_START	/* IN0 */
PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_START1 )
PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_START2 )
PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_UNUSED )
PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_UNUSED )
PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_UNKNOWN )
PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_UNKNOWN )
PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_COIN1 )
PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_COIN2 )

PORT_START	/* IN1 */
PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_JOYSTICK_RIGHT | IPF_8WAY )
PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_JOYSTICK_LEFT | IPF_8WAY )
PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_JOYSTICK_DOWN | IPF_8WAY )
PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_JOYSTICK_UP | IPF_8WAY )
PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_BUTTON1 )
PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_BUTTON2 )
PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_UNUSED )
PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_UNUSED )

PORT_START	/* IN2 */
PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_JOYSTICK_RIGHT | IPF_8WAY | IPF_COCKTAIL )
PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_JOYSTICK_LEFT | IPF_8WAY | IPF_COCKTAIL )
PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_JOYSTICK_DOWN | IPF_8WAY | IPF_COCKTAIL )
PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_JOYSTICK_UP | IPF_8WAY | IPF_COCKTAIL )
PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_BUTTON1 | IPF_COCKTAIL )
PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_BUTTON2 | IPF_COCKTAIL )
PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_UNUSED )
PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_UNUSED )


; And these mappings are taken from https://github.com/mamedev/mame/blob/master/src/mame/drivers/commando.cpp

PORT_START("DSW1")
PORT_DIPNAME( 0x03, 0x03, "Starting Area" ) PORT_DIPLOCATION("SW1:8,7")
PORT_DIPSETTING(    0x03, "0 (Forest 1)" )
PORT_DIPSETTING(    0x01, "2 (Desert 1)" )
PORT_DIPSETTING(    0x02, "4 (Forest 2)" )
PORT_DIPSETTING(    0x00, "6 (Desert 2)" )
PORT_DIPNAME( 0x0c, 0x0c, DEF_STR( Lives ) ) PORT_DIPLOCATION("SW1:6,5")
PORT_DIPSETTING(    0x04, "2" )
PORT_DIPSETTING(    0x0c, "3" )
PORT_DIPSETTING(    0x08, "4" )
PORT_DIPSETTING(    0x00, "5" )
PORT_DIPNAME( 0x30, 0x30, DEF_STR( Coin_B ) ) PORT_DIPLOCATION("SW1:4,3")
PORT_DIPSETTING(    0x00, DEF_STR( 4C_1C ) )
PORT_DIPSETTING(    0x20, DEF_STR( 3C_1C ) )
PORT_DIPSETTING(    0x10, DEF_STR( 2C_1C ) )
PORT_DIPSETTING(    0x30, DEF_STR( 1C_1C ) )
PORT_DIPNAME( 0xc0, 0xc0, DEF_STR( Coin_A ) ) PORT_DIPLOCATION("SW1:1,2")
PORT_DIPSETTING(    0x00, DEF_STR( 2C_1C ) )
PORT_DIPSETTING(    0xc0, DEF_STR( 1C_1C ) )
PORT_DIPSETTING(    0x40, DEF_STR( 1C_2C ) )
PORT_DIPSETTING(    0x80, DEF_STR( 1C_3C ) )

PORT_START("DSW2")
PORT_DIPNAME( 0x07, 0x07, DEF_STR( Bonus_Life ) ) PORT_DIPLOCATION("SW2:8,7,6")
PORT_DIPSETTING(    0x07, "10K 50K+" )
PORT_DIPSETTING(    0x03, "10K 60K+" )
PORT_DIPSETTING(    0x05, "20K 60K+" )
PORT_DIPSETTING(    0x01, "20K 70K+" )
PORT_DIPSETTING(    0x06, "30K 70K+" )
PORT_DIPSETTING(    0x02, "30K 80K+" )
PORT_DIPSETTING(    0x04, "40K 100K+" )
PORT_DIPSETTING(    0x00, DEF_STR( None ) )
PORT_DIPNAME( 0x08, 0x08, DEF_STR( Demo_Sounds ) ) PORT_DIPLOCATION("SW2:5")
PORT_DIPSETTING(    0x00, DEF_STR( Off ) )
PORT_DIPSETTING(    0x08, DEF_STR( On ) )
PORT_DIPNAME( 0x10, 0x10, DEF_STR( Difficulty ) ) PORT_DIPLOCATION("SW2:4")
PORT_DIPSETTING(    0x10, DEF_STR( Normal ) )
PORT_DIPSETTING(    0x00, DEF_STR( Difficult ) )
PORT_DIPNAME( 0x20, 0x00, DEF_STR( Flip_Screen ) ) PORT_DIPLOCATION("SW2:3")
PORT_DIPSETTING(    0x00, DEF_STR( Off ) )
PORT_DIPSETTING(    0x20, DEF_STR( On ) )
PORT_DIPNAME( 0xc0, 0x00, DEF_STR( Cabinet ) ) PORT_DIPLOCATION("SW2:2,1")
PORT_DIPSETTING(    0x00, DEF_STR( Upright ) )
PORT_DIPSETTING(    0x40, "Upright Two Players" )
PORT_DIPSETTING(    0xc0, DEF_STR( Cocktail ) )




ROM_HI_SCORE_TABLE                   EQU $018F        
VULGUS_HI_SCORE                      EQU $018F
SON_SON_HI_SCORE                     EQU $019C
HIGEMARU_HI_SCORE                    EQU $01A9
CAPCOM_HI_SCORE                      EQU $01B6
EXED_EXES_HI_SCORE                   EQU $01C3
COMANDO_HI_SCORE                     EQU $01D0
EMPTY_HI_SCORE                       EQU $01DD

HI_SCORE_TABLE                       EQU $EE00
HI_SCORE_1ST                         EQU $EE00
HI_SCORE_2ND                         EQU $EE0D
HI_SCORE_3RD                         EQU $EE1A
HI_SCORE_4TH                         EQU $EE27
HI_SCORE_5TH                         EQU $EE34
HI_SCORE_6TH                         EQU $EE41
HI_SCORE_7TH                         EQU $EE4E


TIMING_VARIABLE                      EQU $E002
PORT_STATE_C000_IN0                  EQU $E003


; PORT_STATE_C001_IN1 holds the state of IN1 after a bit flip (2's complement) - see $0328
; Bit 0: player moving RIGHT
; Bit 1: player moving LEFT
; Bit 2: player moving DOWN
; Bit 3: player moving UP
; Bit 4: player SHOOT
; Bit 5: player GRENADE
PORT_STATE_C001_IN1                  EQU $E004 
PORT_STATE_C002_IN2                  EQU $E005
PORT_STATE_DSW1                      EQU $E006
PORT_STATE_DSW2                      EQU $E007

; These names are temporary until I work out what they are for.
PORT_STATE_C001_BIT0_BITS            EQU $E008
PORT_STATE_C001_BIT1_BITS            EQU $E009
PORT_STATE_C001_BIT2_BITS            EQU $E00A
PORT_STATE_C001_BIT3_BITS            EQU $E00B
PORT_STATE_C001_BIT4_BITS            EQU $E00C
PORT_STATE_C001_BIT5_BITS            EQU $E00D


IS_CABINET_UPRIGHT                   EQU $E025    ; set to 1 if dip switches report an upright cabinet 
IS_SINGLE_STICK_SETUP                EQU $E029    ; set to 2 if dip switches report upright cabinet with one stick (see $012D)                  
IS_DEMO_SOUNDS_ON                    EQU $E02A    ; set to 16 if dip switches report demo sounds should be OFF (see $0133)
IS_DIFFICULT                         EQU $E02C    ; set to 8 if Difficult difficulty in dip switches, 0 = Normal (see $0139)      
NUM_CREDITS                          EQU $E030    ; number of credits inserted 
IS_SCREEN_YFLIPPED                   EQU $E039    ; temp name: set to 1 if screen is flipped on vertical axis          


PLAYER_BULLETS                       EQU $E200

;
struct PLAYER_BULLET
{
 0    
 1    
 2    
 3 
 4    
 5    
 6    
 7    
 8    
 9    
 A    
 B    
 C    
 D    
 E    
 F    
 10   
 11   
 12 BYTE ShotLength  
 13   
 14   
 15   
 16   
 17   
 18   
 19   
 1A   
 1B   
 1C   
 1D   
 1E   
 1F   
}  - sizeof(INFLIGHT_ALIEN) is 32 bytes



NUM_GRENADES                         EQU $EDA8
HI_SCORE                             EQU $EE97                  ; the hi score seen on screen



;
; Hardware sprite structure
;
; 

struct SPRITE
{
    BYTE Code;                       ; code (animation frame) of sprite to display. 

    ; NOTES ABOUT ATTR FLAGS:
    ; Bit 0: unused
    ; Bit 1: if set, negate X coord
    ; Bit 2: if set, flip sprite horizontally
    ; Bit 3: if set, flip sprite vertically
    ; Bits 4 & 5: sprite colour select (shift right 4 times to get real value)
    ; Bits 6 & 7: sprite bank select
    BYTE Attr;                       ; bit flags used to determine how to display sprite

    BYTE Y;                          ; Y coordinate of sprite
    BYTE X;                          ; LSB of sprite X coordinate
}


0000: 3E 40       ld   a,$04
0002: 32 00 0E    ld   ($E000),a
0005: C3 A4 00    jp   $004A
0008: C9          ret
0009: FF          rst  $38
000A: FF          rst  $38
000B: FF          rst  $38
000C: FF          rst  $38
000D: FF          rst  $38
000E: FF          rst  $38
000F: FF          rst  $38
0010: F3          di
0011: C3 7B 20    jp   $02B7
0014: FF          rst  $38
0015: FF          rst  $38
0016: FF          rst  $38
0017: FF          rst  $38


;
; Add an 8-bit value to HL
; A = 8 bit value to add to HL
;

ADD_A_TO_HL:
0018: 85          add  a,l
0019: 6F          ld   l,a
001A: 30 01       jr   nc,$001D
001C: 24          inc  h
001D: C9          ret


001E: FF          rst  $38
001F: FF          rst  $38

;
; Return the byte at HL + A.
; i.e: in BASIC this would be akin to: result = PEEK (HL + A)
;
; expects:
; A = offset
; HL = pointer
;
; returns:
; A = the contents of (HL + A)
; HL = HL + A

RETURN_BYTE_AT_HL_PLUS_A:
0020: 85          add  a,l
0021: 6F          ld   l,a
0022: 30 01       jr   nc,$0025
0024: 24          inc  h
0025: 7E          ld   a,(hl)
0026: C9          ret

0027: FF          rst  $38

MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL:
0028: 87          add  a,a                   ; multiply a by 2
0029: DF          rst  $18                   ; call ADD_A_TO_HL
002A: 5E          ld   e,(hl)
002B: 23          inc  hl
002C: 56          ld   d,(hl)
002D: 23          inc  hl
002E: C9          ret

002F: FF          rst  $38

0030: E1          pop  hl
0031: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL

0032: EB          ex   de,hl
0033: E9          jp   (hl)
0034: FF          rst  $38
0035: FF          rst  $38
0036: FF          rst  $38
0037: FF          rst  $38



0038: 2A 08 CF    ld   hl,($ED80)
003B: 72          ld   (hl),d
003C: 2C          inc  l
003D: 73          ld   (hl),e
003E: 2C          inc  l
003F: 7D          ld   a,l
0040: FE 04       cp   $40
0042: 38 20       jr   c,$0046
0044: 2E 00       ld   l,$00
0046: 22 08 CF    ld   ($ED80),hl
0049: C9          ret


004A: 31 00 1E    ld   sp,$F000
004D: F3          di
004E: 3E 10       ld   a,$10
0050: 32 40 8C    ld   ($C804),a
0053: AF          xor  a
0054: 32 80 8C    ld   ($C808),a             ; set background scroll X
0057: 32 A1 8C    ld   ($C80B),a             ; set background scroll Y
005A: 32 81 8C    ld   ($C809),a             ; set background scroll X
005D: 32 A0 8C    ld   ($C80A),a             ; set background scroll Y

; clear all RAM
0060: 21 00 0E    ld   hl,$E000
0063: 11 01 0E    ld   de,$E001
0066: 36 00       ld   (hl),$00
0068: 01 FF F1    ld   bc,$1FFF
006B: ED B0       ldir

; clear Video RAM
006D: 21 00 1C    ld   hl,$D000
0070: 11 01 1C    ld   de,$D001
0073: 36 02       ld   (hl),$20
0075: 01 FF 21    ld   bc,$03FF
0078: ED B0       ldir

; clear colour RAM
007A: 21 00 5C    ld   hl,$D400
007D: 11 01 5C    ld   de,$D401
0080: 36 00       ld   (hl),$00
0082: 01 FF 21    ld   bc,$03FF
0085: ED B0       ldir

; clear background video RAM
0087: 21 00 9C    ld   hl,$D800
008A: 11 01 9C    ld   de,$D801
008D: 01 FF 21    ld   bc,$03FF
0090: 36 9E       ld   (hl),$F8
0092: ED B0       ldir

; clear background colour RAM
0094: 21 00 DC    ld   hl,$DC00
0097: 11 01 DC    ld   de,$DC01
009A: 01 FF 21    ld   bc,$03FF
009D: 36 00       ld   (hl),$00
009F: ED B0       ldir

; Copy hi score to RAM
00A1: 21 E9 01    ld   hl,$018F              ; load HL with address of ROM_HI_SCORE_TABLE
00A4: E5          push hl
00A5: 11 79 EE    ld   de,$EE97              ; load DE with address of HI_SCORE 
00A8: ED A0       ldi                        ; copy top score from ROM...
00AA: ED A0       ldi
00AC: ED A0       ldi                        ; ..to current high score in RAM. 
00AE: E1          pop  hl

; Copy high score table from ROM to RAM
00AF: 11 00 EE    ld   de,$EE00
00B2: 01 28 00    ld   bc,$0082
00B5: ED B0       ldir

00B7: 21 00 CF    ld   hl,$ED00
00BA: 22 28 CF    ld   ($ED82),hl
00BD: 22 08 CF    ld   ($ED80),hl
00C0: 11 01 CF    ld   de,$ED01
00C3: 36 FF       ld   (hl),$FF
00C5: 01 F3 00    ld   bc,$003F
00C8: ED B0       ldir

00CA: 21 04 CF    ld   hl,$ED40
00CD: 22 88 CF    ld   ($ED88),hl
00D0: 22 68 CF    ld   ($ED86),hl
00D3: 11 05 CF    ld   de,$ED41
00D6: 36 FF       ld   (hl),$FF
00D8: 01 F1 00    ld   bc,$001F
00DB: ED B0       ldir

00DD: CD 7B 21    call $03B7

00E0: 3E 00       ld   a,$00
00E2: 32 93 0E    ld   ($E039),a
00E5: CD 76 20    call $0276

00E8: 3A 60 0E    ld   a,($E006)
00EB: 47          ld   b,a
00EC: E6 21       and  $03
00EE: 21 67 01    ld   hl,$0167
00F1: 87          add  a,a
00F2: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
00F3: 32 22 0E    ld   ($E022),a
00F6: 23          inc  hl
00F7: 7E          ld   a,(hl)
00F8: 32 02 0E    ld   ($E020),a
00FB: 78          ld   a,b
00FC: 0F          rrca
00FD: 0F          rrca
00FE: E6 21       and  $03
0100: 21 E7 01    ld   hl,$016F
0103: 87          add  a,a
0104: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
0105: 32 23 0E    ld   ($E023),a
0108: 23          inc  hl
0109: 7E          ld   a,(hl)
010A: 32 03 0E    ld   ($E021),a
010D: 78          ld   a,b
010E: 07          rlca
010F: 07          rlca
0110: 07          rlca
0111: 07          rlca
0112: 21 77 01    ld   hl,$0177
0115: E6 21       and  $03
0117: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
0118: 32 42 0E    ld   ($E024),a
011B: 78          ld   a,b
011C: 07          rlca
011D: 07          rlca
011E: E6 21       and  $03
0120: 32 63 0E    ld   ($E027),a
0123: 3A 61 0E    ld   a,($E007)             ; read PORT_STATE_DSW2
0126: 47          ld   b,a
0127: E6 01       and  $01
0129: 32 43 0E    ld   ($E025),a             ; set IS_CABINET_UPRIGHT
012C: 78          ld   a,b
012D: E6 20       and  $02
012F: 32 83 0E    ld   ($E029),a             ; set IS_SINGLE_STICK_SETUP
0132: 78          ld   a,b
0133: E6 10       and  $10
0135: 32 A2 0E    ld   ($E02A),a             ; set DEMO_SOUNDS_ON
0138: 78          ld   a,b
0139: E6 80       and  $08
013B: 32 C2 0E    ld   ($E02C),a             ; set IS_NORMAL_DIFFICULTY
013E: 78          ld   a,b
013F: 07          rlca
0140: 07          rlca
0141: 07          rlca
0142: E6 61       and  $07
0144: 87          add  a,a
0145: 21 F7 01    ld   hl,$017F
0148: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
0149: 32 62 0E    ld   ($E026),a
014C: 23          inc  hl
014D: 7E          ld   a,(hl)
014E: 32 82 0E    ld   ($E028),a
0151: 21 AE 01    ld   hl,$01EA
0154: 22 3B 0E    ld   ($E0B3),hl
0157: 21 94 1C    ld   hl,$D058
015A: 22 1B 0E    ld   ($E0B1),hl
015D: 3E 0A       ld   a,$A0
015F: 32 65 0E    ld   ($E047),a
0162: 00          nop
0163: FB          ei
0164: C3 00 08    jp   $8000


0167: 01 01 01    ld   bc,$0101
016A: 20 01       jr   nz,$016D
016C: 21 20 01    ld   hl,$0102
016F: 01 01 20    ld   bc,$0201
0172: 01 21 01    ld   bc,$0103
0175: 40          ld   b,b
0176: 01 21 20    ld   bc,$0203
0179: 40          ld   b,b
017A: 41          ld   b,c
017B: 00          nop
017C: 10 08       djnz $00FE
017E: 18 01       jr   $0181
0180: 41          ld   b,c
0181: 01 60 20    ld   bc,$0206
0184: 60          ld   h,b
0185: 20 61       jr   nz,$018E
0187: 21 61 21    ld   hl,$0307
018A: 80          add  a,b
018B: 40          ld   b,b
018C: 10 00       djnz $018E
018E: 00          nop

018F:  00 50 00 56 55 4C 47 55 53 2E 2E 2E 2E 00 30 00  .P.VULGUS.....0.
019F:  53 4F 4E 2E 53 4F 4E 2E 2E 2E 00 20 00 48 49 47  SON.SON.... .HIG
01AF:  45 4D 41 52 55 2E 2E 00 19 42 43 41 50 43 4F 4D  EMARU....BCAPCOM
01BF:  2E 2E 2E 2E 00 12 00 45 58 45 44 2E 45 58 45 53  .......EXED.EXES
01CF:  2E 00 10 00 43 4F 4D 41 4E 44 4F 2E 2E 2E 00 08  ....COMANDO.....
01DF:  00 2E 2E 2E 2E 2E 2E 2E 2E 2E 2E 2E              ............

01EA:  55 53 45 20 41 4E 44 20 45 58 50 4F 52 54 20 4F  USE AND EXPORT O
01FA:  46 20 54 48 49 53 20 47 41 4D 45 23 56 D0 57 49  F THIS GAME#V.WI
020A:  54 48 20 49 4E 20 54 48 45 20 23 54 D0 43 4F 55  TH IN THE #T.COU
021A:  4E 54 52 59 20 4F 46 20 54 48 45 20 4A 41 50 41  NTRY OF THE JAPA
022A:  4E 23 52 D0 49 53 20 49 4E 20 56 49 4F 4C 41 54  N#R.IS IN VIOLAT
023A:  49 4F 4E 20 4F 46 20 23 50 D0 43 4F 50 59 52 49  ION OF #P.COPYRI
024A:  47 48 54 20 4C 41 57 23 4E D0 41 4E 44 20 43 4F  GHT LAW#N.AND CO
025A:  4E 53 54 49 54 55 54 45 53 20 23 4C D0 41 20 43  NSTITUTES #L.A C
026A:  52 49 4D 49 4E 41 4C 20 41 43 54 40 B2 03 C0 E3  RIMINAL ACT@....


0276: 3A 21 0C    ld   a,($C003)             ; read DSW1 
0279: 2F          cpl
027A: 17          rla
027B: CB 18       rr   b
027D: 17          rla
027E: CB 18       rr   b
0280: 17          rla
0281: CB 18       rr   b
0283: 17          rla
0284: CB 18       rr   b
0286: 17          rla
0287: CB 18       rr   b
0289: 17          rla
028A: CB 18       rr   b
028C: 17          rla
028D: CB 18       rr   b
028F: 17          rla
0290: CB 18       rr   b
0292: 78          ld   a,b
0293: 32 60 0E    ld   ($E006),a             ; write to PORT_STATE_DSW1
0296: 3A 40 0C    ld   a,($C004)             ; read DSW2
0299: 2F          cpl
029A: 17          rla
029B: CB 18       rr   b
029D: 17          rla
029E: CB 18       rr   b
02A0: 17          rla
02A1: CB 18       rr   b
02A3: 17          rla
02A4: CB 18       rr   b
02A6: 17          rla
02A7: CB 18       rr   b
02A9: 17          rla
02AA: CB 18       rr   b
02AC: 17          rla
02AD: CB 18       rr   b
02AF: 17          rla
02B0: CB 18       rr   b
02B2: 78          ld   a,b
02B3: 32 61 0E    ld   ($E007),a             ; write to PORT_STATE_DSW2 
02B6: C9          ret
02B7: F5          push af
02B8: C5          push bc
02B9: D5          push de
02BA: E5          push hl
02BB: D9          exx
02BC: 08          ex   af,af'
02BD: F5          push af
02BE: C5          push bc
02BF: D5          push de
02C0: E5          push hl
02C1: DD E5       push ix
02C3: FD E5       push iy
02C5: CD 78 21    call $0396
02C8: CD 63 69    call $8727
02CB: CD BE 20    call $02FA
02CE: FD E1       pop  iy
02D0: DD E1       pop  ix
02D2: E1          pop  hl
02D3: D1          pop  de
02D4: C1          pop  bc
02D5: F1          pop  af
02D6: 08          ex   af,af'
02D7: D9          exx
02D8: E1          pop  hl
02D9: D1          pop  de
02DA: C1          pop  bc
02DB: F1          pop  af
02DC: FB          ei
02DD: C9          ret
02DE: 21 04 1C    ld   hl,$D040
02E1: 06 D0       ld   b,$1C
02E3: 0E 11       ld   c,$11
02E5: C3 3E 20    jp   $02F2
02E8: 21 04 1C    ld   hl,$D040
02EB: 06 D0       ld   b,$1C
02ED: 0E 10       ld   c,$10
02EF: C3 3E 20    jp   $02F2
02F2: 71          ld   (hl),c
02F3: 3E 02       ld   a,$20
02F5: DF          rst  $18                   ; call ADD_A_TO_HL 
02F6: 10 BE       djnz $02F2
02F8: C9          ret
02F9: C9          ret

02FA: 21 20 0E    ld   hl,$E002              ; load HL with address of TIMING_VARIABLE
02FD: 34          inc  (hl)                  ; increment TIMING_VARIABLE
02FE: 21 B3 0E    ld   hl,$E03B
0301: 3A 40 0C    ld   a,($C004)             ; read DSW2 
0304: 07          rlca
0305: 07          rlca
0306: E6 08       and  $80
0308: 4F          ld   c,a
0309: 3A 93 0E    ld   a,($E039)
030C: E6 01       and  $01
030E: 28 40       jr   z,$0314
0310: 79          ld   a,c
0311: C6 08       add  a,$80
0313: 4F          ld   c,a
0314: 3A B3 0E    ld   a,($E03B)
0317: E6 F7       and  $7F
0319: 81          add  a,c
031A: 32 B3 0E    ld   ($E03B),a
031D: 3A 00 0C    ld   a,($C000)             ; read IN0
0320: 2F          cpl
0321: 32 21 0E    ld   ($E003),a             ; save in PORT_STATE_C000_IN0  
0324: 3A 01 0C    ld   a,($C001)             ; read IN1
0327: 2F          cpl
0328: 32 40 0E    ld   ($E004),a             ; save in PORT_STATE_C001_IN1
032B: 3A 20 0C    ld   a,($C002)             ; read IN2
032E: 2F          cpl
032F: 32 41 0E    ld   ($E005),a             ; save in PORT_STATE_C005

; Expand PORT_STATE_C001_IN1 bits to flags
0332: 11 40 0E    ld   de,$E004              ; load DE with address of PORT_STATE_C001_IN1
0335: 21 80 0E    ld   hl,$E008
0338: 1A          ld   a,(de)                ; read PORT_STATE_C001_IN1
0339: 0F          rrca                       ; move IPT_JOYSTICK_RIGHT bit into carry 
033A: CB 16       rl   (hl)                  ; shift into PORT_STATE_C001_BIT0_BITS
033C: 2C          inc  l
033D: 0F          rrca                       ; move IPT_JOYSTICK_LEFT bit into carry
033E: CB 16       rl   (hl)                  ; shift into PORT_STATE_C001_BIT1_BITS
0340: 2C          inc  l
0341: 0F          rrca                       ; move IPT_JOYSTICK_DOWN bit into carry
0342: CB 16       rl   (hl)                  ; shift into PORT_STATE_C001_BIT2_BITS
0344: 2C          inc  l
0345: 0F          rrca                       ; move IPT_JOYSTICK_UP bit into carry
0346: CB 16       rl   (hl)                  ; shift into PORT_STATE_C001_BIT3_BITS
0348: 2C          inc  l
0349: 0F          rrca                       ; move IPT_BUTTON1 (shoot) bit into carry 
034A: CB 16       rl   (hl)                  ; shift into PORT_STATE_C001_BIT4_BITS
034C: 2C          inc  l
034D: 0F          rrca                       ; move IPT_BUTTON2 (grenade) bit into carry
034E: CB 16       rl   (hl)                  ; shift into PORT_STATE_C001_BIT5_BITS   


0350: 11 40 0E    ld   de,$E004              ; load DE with address of PORT_STATE_C001_IN1 
0353: 3A 93 0E    ld   a,($E039)             ; read IS_SCREEN_YFLIPPED flag 
0356: E6 01       and  $01                   ; test if flag is set
0358: 20 60       jr   nz,$0360              ; if flag is set, goto $03600

035A: 3A 83 0E    ld   a,($E029)
035D: A7          and  a
035E: 20 01       jr   nz,$0361
0360: 1C          inc  e                     ; bump DE to point to PORT_STATE_C002_IN2
0361: 21 10 0E    ld   hl,$E010
0364: 1A          ld   a,(de)
0365: 0F          rrca
0366: CB 16       rl   (hl)
0368: 2C          inc  l
0369: 0F          rrca
036A: CB 16       rl   (hl)
036C: 2C          inc  l
036D: 0F          rrca
036E: CB 16       rl   (hl)
0370: 2C          inc  l
0371: 0F          rrca
0372: CB 16       rl   (hl)
0374: 2C          inc  l
0375: 0F          rrca
0376: CB 16       rl   (hl)
0378: 2C          inc  l
0379: 0F          rrca
037A: CB 16       rl   (hl)


037C: 3A 21 0E    ld   a,($E003)             ; read PORT_STATE_C000_IN0 bits
037F: 21 96 0E    ld   hl,$E078
0382: 0F          rrca
0383: CB 16       rl   (hl)
0385: CD 73 F8    call $9E37

0388: 3A 00 0E    ld   a,($E000)
038B: E6 21       and  $03
038D: F7          rst  $30
038E: 8D          adc  a,l
038F: 21 00 40    ld   hl,$0400
0392: 26 41       ld   h,$05
0394: 03          inc  bc
0395: 60          ld   h,b
0396: 3A B2 0E    ld   a,($E03A)
0399: 32 00 8C    ld   ($C800),a
039C: 3A B5 0E    ld   a,($E05B)
039F: E6 01       and  $01
03A1: 32 81 8C    ld   ($C809),a
03A4: 3A D4 0E    ld   a,($E05C)
03A7: 32 80 8C    ld   ($C808),a
03AA: 3A B3 0E    ld   a,($E03B)
03AD: 32 40 8C    ld   ($C804),a
03B0: 32 60 8C    ld   ($C806),a
03B3: 00          nop
03B4: 00          nop
03B5: 00          nop
03B6: C9          ret
03B7: DD 21 40 FE ld   ix,$FE04
03BB: 06 F5       ld   b,$5F
03BD: 11 40 00    ld   de,$0004
03C0: AF          xor  a
03C1: DD 77 20    ld   (ix+$02),a
03C4: DD 19       add  ix,de
03C6: 10 9F       djnz $03C1
03C8: C9          ret


03C9: 3A 01 0E    ld   a,($E001)
03CC: F7          rst  $30
03CD: 1D          dec  e
03CE: 21 DF 21    ld   hl,$03FD
03D1: 3A C0 0E    ld   a,($E00C)
03D4: A7          and  a
03D5: C2 DE 41    jp   nz,$05FC
03D8: CD 06 E0    call $0E60
03DB: 3A 20 0E    ld   a,($E002)
03DE: E6 21       and  $03
03E0: C0          ret  nz
03E1: 21 65 0E    ld   hl,$E047
03E4: 35          dec  (hl)
03E5: C0          ret  nz
03E6: 16 81       ld   d,$09
03E8: FF          rst  $38
03E9: 11 01 00    ld   de,$0001
03EC: FF          rst  $38
03ED: 11 21 00    ld   de,$0003
03F0: FF          rst  $38
03F1: 16 20       ld   d,$02
03F3: FF          rst  $38
03F4: 16 21       ld   d,$03
03F6: FF          rst  $38
03F7: 16 40       ld   d,$04
03F9: FF          rst  $38
03FA: C3 01 60    jp   $0601
03FD: C3 BA B2    jp   $3ABA
0400: 21 50 40    ld   hl,$0414
0403: E5          push hl
0404: 3A 01 0E    ld   a,($E001)
0407: F7          rst  $30
0408: 62          ld   h,d
0409: 40          ld   b,b
040A: F4 40 E8    call p,$8E04
040D: 40          ld   b,b
040E: BB          cp   e
040F: 40          ld   b,b
0410: 5C          ld   e,h
0411: 40          ld   b,b
0412: AF          xor  a
0413: 40          ld   b,b
0414: 3A 90 0E    ld   a,($E018)
0417: A7          and  a
0418: C2 16 41    jp   nz,$0570
041B: 3A 12 0E    ld   a,($E030)
041E: A7          and  a
041F: C8          ret  z
0420: 16 81       ld   d,$09
0422: FF          rst  $38
0423: C3 01 60    jp   $0601
0426: 16 20       ld   d,$02
0428: FF          rst  $38
0429: 16 21       ld   d,$03
042B: FF          rst  $38
042C: 11 21 00    ld   de,$0003
042F: FF          rst  $38
0430: 11 51 00    ld   de,$0015
0433: FF          rst  $38
0434: 16 E0       ld   d,$0E
0436: FF          rst  $38
0437: CD 93 41    call $0539
043A: FD 21 92 FF ld   iy,$FF38
043E: FD 36 20 94 ld   (iy+$02),$58
0442: FD 36 60 94 ld   (iy+$06),$58
0446: FD 36 21 1A ld   (iy+$03),$B0
044A: FD 36 61 0A ld   (iy+$07),$A0
044E: AF          xor  a
044F: 32 65 0E    ld   ($E047),a
0452: 21 00 80    ld   hl,$0800
0455: 22 2A CF    ld   ($EDA2),hl
0458: CD E8 4B    call $A58E
045B: C3 DE 41    jp   $05FC
045E: CD D1 41    call $051D
0461: CD 9E 40    call $04F8
0464: 21 65 0E    ld   hl,$E047
0467: 35          dec  (hl)
0468: C0          ret  nz
0469: FD 21 92 FF ld   iy,$FF38
046D: FD 36 20 00 ld   (iy+$02),$00
0471: FD 36 60 00 ld   (iy+$06),$00
0475: FD 36 A0 00 ld   (iy+$0a),$00
0479: CD 81 60    call $0609
047C: 16 80       ld   d,$08
047E: FF          rst  $38
047F: CD 93 41    call $0539
0482: 21 00 90    ld   hl,$1800
0485: 22 2A CF    ld   ($EDA2),hl
0488: CD E8 4B    call $A58E
048B: C3 DE 41    jp   $05FC
048E: 21 65 0E    ld   hl,$E047
0491: 35          dec  (hl)
0492: C0          ret  nz
0493: 21 00 84    ld   hl,$4800
0496: 22 2A CF    ld   ($EDA2),hl
0499: CD E8 4B    call $A58E
049C: CD 81 60    call $0609
049F: CD DC 09    call $81DC
04A2: 11 40 00    ld   de,$0004
04A5: FF          rst  $38
04A6: 16 61       ld   d,$07
04A8: FF          rst  $38
04A9: 16 80       ld   d,$08
04AB: FF          rst  $38
04AC: CD 93 41    call $0539
04AF: 21 00 F1    ld   hl,$1F00
04B2: 22 2A CF    ld   ($EDA2),hl
04B5: CD E8 4B    call $A58E
04B8: C3 DE 41    jp   $05FC
04BB: 21 65 0E    ld   hl,$E047
04BE: 35          dec  (hl)
04BF: C0          ret  nz
04C0: CD 81 60    call $0609
04C3: AF          xor  a
04C4: 32 01 0E    ld   ($E001),a
04C7: C9          ret
04C8: 21 00 D0    ld   hl,$1C00
04CB: 22 2A CF    ld   ($EDA2),hl
04CE: CD E8 4B    call $A58E
04D1: C3 DE 41    jp   $05FC
04D4: CD 07 41    call $0561
04D7: 11 42 00    ld   de,$0024
04DA: FF          rst  $38
04DB: 1C          inc  e
04DC: FF          rst  $38
04DD: 11 F0 00    ld   de,$001E
04E0: FF          rst  $38
04E1: 1C          inc  e
04E2: FF          rst  $38
04E3: 3E 00       ld   a,$00
04E5: 32 65 0E    ld   ($E047),a
04E8: C3 DE 41    jp   $05FC
04EB: 21 65 0E    ld   hl,$E047
04EE: 35          dec  (hl)
04EF: C0          ret  nz
04F0: CD 81 60    call $0609
04F3: AF          xor  a
04F4: 32 01 0E    ld   ($E001),a
04F7: C9          ret
04F8: FD 21 92 FF ld   iy,$FF38
04FC: 21 91 41    ld   hl,$0519
04FF: 3A 20 0E    ld   a,($E002)
0502: 0F          rrca
0503: 0F          rrca
0504: 0F          rrca
0505: E6 21       and  $03
0507: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
0508: FD 77 00    ld   (iy+$00),a
050B: C6 80       add  a,$08
050D: FD 77 40    ld   (iy+$04),a
0510: FD 36 01 00 ld   (iy+$01),$00
0514: FD 36 41 00 ld   (iy+$05),$00
0518: C9          ret
0519: 02          ld   (bc),a
051A: 03          inc  bc
051B: 22 03 3A    ld   ($B221),hl
051E: 20 0E       jr   nz,$0500
0520: 47          ld   b,a
0521: E6 E1       and  $0F
0523: C0          ret  nz
0524: 11 60 00    ld   de,$0006
0527: 3A C2 0E    ld   a,($E02C)
052A: A7          and  a
052B: 28 20       jr   z,$052F
052D: 1E 70       ld   e,$16
052F: CB 60       bit  4,b
0531: CA 92 00    jp   z,$0038
0534: 14          inc  d
0535: C3 92 00    jp   $0038
0538: C9          ret
0539: 11 30 00    ld   de,$0012
053C: FF          rst  $38
053D: 11 31 00    ld   de,$0013
0540: FF          rst  $38
0541: 11 50 00    ld   de,$0014
0544: FF          rst  $38
0545: C9          ret
0546: 3A 20 0E    ld   a,($E002)
0549: 0F          rrca
054A: E6 21       and  $03
054C: 21 D5 41    ld   hl,$055D
054F: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
0550: 06 60       ld   b,$06
0552: 11 02 00    ld   de,$0020
0555: 21 2B 5D    ld   hl,$D5A3
0558: 77          ld   (hl),a
0559: 19          add  hl,de
055A: 10 DE       djnz $0558
055C: C9          ret

055D: C0          ret  nz
055E: 41          ld   b,c
055F: E0          ret  po
0560: 41          ld   b,c
0561: C9          ret
0562: 21 29 41    ld   hl,$0583
0565: E5          push hl
0566: 3A 01 0E    ld   a,($E001)
0569: F7          rst  $30
056A: BC          cp   h
056B: 41          ld   b,c
056C: 1E 41       ld   e,$05
056E: 00          nop
056F: 60          ld   h,b
0570: 3A 20 0E    ld   a,($E002)
0573: 47          ld   b,a
0574: E6 F3       and  $3F
0576: 20 50       jr   nz,$058C
0578: 11 E0 00    ld   de,$000E
057B: CB 70       bit  6,b
057D: 28 01       jr   z,$0580
057F: 14          inc  d
0580: FF          rst  $38
0581: 18 81       jr   $058C
0583: 3A 20 0E    ld   a,($E002)
0586: 47          ld   b,a
0587: E6 F1       and  $1F
0589: CC D8 41    call z,$059C
058C: 3A 21 0E    ld   a,($E003)
058F: CB 4F       bit  1,a
0591: 20 43       jr   nz,$05B8
0593: 3A 21 0E    ld   a,($E003)
0596: CB 47       bit  0,a
0598: C8          ret  z
0599: C3 8A 41    jp   $05A8
059C: 11 80 00    ld   de,$0008
059F: CB 68       bit  5,b
05A1: CA 92 00    jp   z,$0038
05A4: 14          inc  d
05A5: C3 92 00    jp   $0038
05A8: 3A 12 0E    ld   a,($E030)
05AB: D6 01       sub  $01
05AD: 27          daa
05AE: 32 12 0E    ld   ($E030),a
05B1: AF          xor  a
05B2: 32 B0 0E    ld   ($E01A),a
05B5: C3 8D 41    jp   $05C9
05B8: 3A 12 0E    ld   a,($E030)
05BB: FE 01       cp   $01
05BD: C8          ret  z
05BE: D6 20       sub  $02
05C0: 27          daa
05C1: 32 12 0E    ld   ($E030),a
05C4: 3E 01       ld   a,$01
05C6: 32 B0 0E    ld   ($E01A),a
05C9: AF          xor  a
05CA: 32 91 0E    ld   ($E019),a
05CD: 32 01 0E    ld   ($E001),a
05D0: 3E 21       ld   a,$03
05D2: 32 00 0E    ld   ($E000),a
05D5: 16 81       ld   d,$09
05D7: C3 92 00    jp   $0038
05DA: CD 7B 21    call $03B7
05DD: 16 81       ld   d,$09
05DF: FF          rst  $38
05E0: 16 40       ld   d,$04
05E2: FF          rst  $38
05E3: CD 93 41    call $0539
05E6: 16 80       ld   d,$08
05E8: FF          rst  $38
05E9: 11 A0 00    ld   de,$000A
05EC: FF          rst  $38
05ED: C3 DE 41    jp   $05FC

05F0: 3A 12 0E    ld   a,($E030)
05F3: 3D          dec  a
05F4: C8          ret  z
05F5: 11 81 00    ld   de,$0009
05F8: FF          rst  $38
05F9: C3 DE 41    jp   $05FC

05FC: 21 01 0E    ld   hl,$E001
05FF: 34          inc  (hl)
0600: C9          ret

0601: 21 00 0E    ld   hl,$E000
0604: 34          inc  (hl)
0605: 2C          inc  l
0606: 36 00       ld   (hl),$00
0608: C9          ret

0609: 21 04 1C    ld   hl,$D040
060C: 0E D0       ld   c,$1C
060E: 06 F0       ld   b,$1E
0610: 36 02       ld   (hl),$20
0612: CB D4       set  2,h
0614: 36 00       ld   (hl),$00
0616: CB 94       res  2,h
0618: 2C          inc  l
0619: 10 5F       djnz $0610
061B: 23          inc  hl
061C: 23          inc  hl
061D: 0D          dec  c
061E: 20 EE       jr   nz,$060E
0620: C9          ret
0621: 3A 01 0E    ld   a,($E001)
0624: F7          rst  $30
0625: 64          ld   h,h
0626: 60          ld   h,b
0627: DD 60       ld   ixh,b
0629: 87          add  a,a
062A: 61          ld   h,c
062B: CD 61 DE    call $FC07
062E: 61          ld   h,c
062F: C4 81 C7    call nz,$6D09
0632: A0          and  b
0633: AF          xor  a
0634: C0          ret  nz
0635: D0          ret  nc
0636: C1          pop  bc
0637: 37          scf
0638: C1          pop  bc
0639: 7F          ld   a,a
063A: C1          pop  bc
063B: 06 61       ld   b,$07
063D: 11 02 00    ld   de,$0020
0640: 36 02       ld   (hl),$20
0642: 19          add  hl,de
0643: 10 BF       djnz $0640
0645: C9          ret

0646: 11 20 01    ld   de,$0102
0649: FF          rst  $38
064A: 21 19 EE    ld   hl,$EE91
064D: 06 60       ld   b,$06
064F: 36 00       ld   (hl),$00
0651: 2C          inc  l
0652: 10 BF       djnz $064F
0654: 21 F4 1C    ld   hl,$D05E
0657: CD B3 60    call $063B
065A: 21 FE 3C    ld   hl,$D2FE
065D: CD B3 60    call $063B
0660: 11 01 00    ld   de,$0001
0663: FF          rst  $38
0664: CD 3B D8    call $9CB3
0667: 3A 42 0E    ld   a,($E024)
066A: 32 0C CF    ld   ($EDC0),a
066D: 32 0D CF    ld   ($EDC1),a
0670: 3E 60       ld   a,$06
0672: 32 8C CF    ld   ($EDC8),a
0675: 3A 62 0E    ld   a,($E026)
0678: A7          and  a
0679: 28 54       jr   z,$06CF
067B: 6F          ld   l,a
067C: 26 00       ld   h,$00
067E: 29          add  hl,hl
067F: 29          add  hl,hl
0680: 29          add  hl,hl
0681: 29          add  hl,hl
0682: 7C          ld   a,h
0683: 32 4D CF    ld   ($EDC5),a
0686: 7D          ld   a,l
0687: 32 6C CF    ld   ($EDC6),a
068A: 3E 00       ld   a,$00
068C: 32 6D CF    ld   ($EDC7),a
068F: 3A 63 0E    ld   a,($E027)
0692: 21 5D 60    ld   hl,$06D5
0695: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0696: 63          ld   h,e
0697: 2E 00       ld   l,$00
0699: 22 2C CF    ld   ($EDC2),hl
069C: 7A          ld   a,d
069D: 32 8D CF    ld   ($EDC9),a
06A0: 32 4C CF    ld   ($EDC4),a
06A3: 3A B0 0E    ld   a,($E01A)
06A6: A7          and  a
06A7: 28 30       jr   z,$06BB
06A9: CD 8C D8    call $9CC8
06AC: 11 20 00    ld   de,$0002
06AF: FF          rst  $38
06B0: 21 0C CF    ld   hl,$EDC0
06B3: 11 0E CF    ld   de,$EDE0
06B6: 01 02 00    ld   bc,$0020
06B9: ED B0       ldir
06BB: CD 91 98    call $9819
06BE: 3E 06       ld   a,$60
06C0: 32 65 0E    ld   ($E047),a
06C3: CD 38 6B    call $A792
06C6: CD 7B 21    call $03B7
06C9: CD 0C 68    call $86C0
06CC: C3 DE 41    jp   $05FC
06CF: 21 18 99    ld   hl,$9990
06D2: C3 28 60    jp   $0682
06D5: 00          nop
06D6: 00          nop
06D7: 10 20       djnz $06DB
06D9: 04          inc  b
06DA: 40          ld   b,b
06DB: 14          inc  d
06DC: 60          ld   h,b
06DD: CD 7B 21    call $03B7
06E0: AF          xor  a
06E1: 32 F9 0E    ld   ($E09F),a
06E4: CD 52 61    call $0734
06E7: CD 2C 80    call $08C2
06EA: 11 0A CF    ld   de,$EDA0
06ED: 01 02 00    ld   bc,$0020
06F0: ED B0       ldir
06F2: CD B9 61    call $079B
06F5: 16 81       ld   d,$09
06F7: FF          rst  $38
06F8: 16 A0       ld   d,$0A
06FA: FF          rst  $38
06FB: 16 C1       ld   d,$0D
06FD: FF          rst  $38
06FE: 3A 8A CF    ld   a,($EDA8)             ; read NUM_GRENADES
0701: FE 60       cp   $06
0703: 30 41       jr   nc,$070A
0705: 3E 60       ld   a,$06
0707: 32 8A CF    ld   ($EDA8),a             ; update NUM_GRENADES
070A: 16 A1       ld   d,$0B
070C: FF          rst  $38
070D: CD E8 4B    call $A58E
0710: 3A 0B CF    ld   a,($EDA1)
0713: A7          and  a
0714: 20 A1       jr   nz,$0721
0716: 3E 0C       ld   a,$C0
0718: 32 65 0E    ld   ($E047),a
071B: CD 63 61    call $0727
071E: C3 DE 41    jp   $05FC

0721: CD 0C 68    call $86C0
0724: C3 DE 41    jp   $05FC
0727: 3A 8B CF    ld   a,($EDA9)
072A: E6 21       and  $03
072C: FE 21       cp   $03
072E: C2 AC 68    jp   nz,$86CA
0731: C3 FC 68    jp   $86DE

0734: 21 00 6E    ld   hl,$E600
0737: 11 01 6E    ld   de,$E601
073A: 01 FF 00    ld   bc,$00FF
073D: 36 00       ld   (hl),$00
073F: ED B0       ldir
0741: 21 0C 2E    ld   hl,$E2C0
0744: 11 0D 2E    ld   de,$E2C1
0747: 01 FF 00    ld   bc,$00FF
074A: 36 00       ld   (hl),$00
074C: ED B0       ldir
074E: 21 00 4F    ld   hl,$E500
0751: 11 01 4F    ld   de,$E501
0754: 01 FF 00    ld   bc,$00FF
0757: 36 00       ld   (hl),$00
0759: ED B0       ldir
075B: 21 00 8E    ld   hl,$E800
075E: 11 01 8E    ld   de,$E801
0761: 01 E9 00    ld   bc,$008F
0764: 36 00       ld   (hl),$00
0766: ED B0       ldir
0768: C9          ret

0769: 3A 0B CF    ld   a,($EDA1)
076C: A7          and  a
076D: 20 D0       jr   nz,$078B
076F: 21 65 0E    ld   hl,$E047
0772: 35          dec  (hl)
0773: C2 8B 61    jp   nz,$07A9
0776: 16 81       ld   d,$09
0778: FF          rst  $38
0779: 16 A0       ld   d,$0A
077B: FF          rst  $38
077C: 16 A1       ld   d,$0B
077E: FF          rst  $38
077F: 16 C1       ld   d,$0D
0781: FF          rst  $38
0782: CD 60 89    call $8906
0785: 3E 40       ld   a,$04
0787: 32 01 0E    ld   ($E001),a
078A: C9          ret

078B: 21 0B CF    ld   hl,$EDA1
078E: 36 00       ld   (hl),$00
0790: 3E 06       ld   a,$60
0792: 32 65 0E    ld   ($E047),a
0795: CD DA 8B    call $A9BC
0798: C3 DE 41    jp   $05FC

079B: 3A 43 0E    ld   a,($E025)
079E: A7          and  a
079F: C0          ret  nz
07A0: 3A 91 0E    ld   a,($E019)
07A3: E6 01       and  $01
07A5: 32 93 0E    ld   ($E039),a
07A8: C9          ret

07A9: 11 C1 00    ld   de,$000D
07AC: FF          rst  $38
07AD: 3A 20 0E    ld   a,($E002)
07B0: 47          ld   b,a
07B1: E6 E1       and  $0F
07B3: C0          ret  nz
07B4: 78          ld   a,b
07B5: 0F          rrca
07B6: 0F          rrca
07B7: 0F          rrca
07B8: 0F          rrca
07B9: E6 01       and  $01
07BB: 57          ld   d,a
07BC: 3A 91 0E    ld   a,($E019)
07BF: E6 01       and  $01
07C1: C6 A1       add  a,$0B
07C3: 5F          ld   e,a
07C4: FF          rst  $38
07C5: 16 C1       ld   d,$0D
07C7: FF          rst  $38
07C8: 16 A1       ld   d,$0B
07CA: C3 92 00    jp   $0038
07CD: 3A 65 0E    ld   a,($E047)
07D0: A7          and  a
07D1: 28 51       jr   z,$07E8
07D3: CD 8B 61    call $07A9
07D6: 21 65 0E    ld   hl,$E047
07D9: 35          dec  (hl)
07DA: 20 C0       jr   nz,$07E8
07DC: 16 81       ld   d,$09
07DE: FF          rst  $38
07DF: 16 A0       ld   d,$0A
07E1: FF          rst  $38
07E2: 16 A1       ld   d,$0B
07E4: FF          rst  $38
07E5: 16 C1       ld   d,$0D
07E7: FF          rst  $38
07E8: CD 21 AA    call $AA03
07EB: 3A 06 0F    ld   a,($E160)
07EE: A7          and  a
07EF: C0          ret  nz
07F0: 32 02 4E    ld   ($E420),a
07F3: 32 DA 0E    ld   ($E0BC),a
07F6: CD 60 89    call $8906
07F9: C3 DE 41    jp   $05FC
07FC: CD 8B F9    call $9FA9
07FF: CD 81 F9    call $9F09
0802: CD 93 89    call $8939
0805: CD E3 63    call $272F
0808: CD EF 79    call $97EF
080B: CD F8 E1    call $0F9E
080E: CD D1 39    call $931D
0811: CD 39 E8    call $8E93
0814: CD 59 EA    call $AE95
0817: 3A 00 0F    ld   a,($E100)
081A: A7          and  a
081B: 28 E5       jr   z,$086C
081D: 3A 0B 0E    ld   a,($E0A1)
0820: A7          and  a
0821: C2 DE 41    jp   nz,$05FC
0824: 3A F9 0E    ld   a,($E09F)
0827: A7          and  a
0828: 20 42       jr   nz,$084E
082A: 3A D4 0E    ld   a,($E05C)
082D: A7          and  a
082E: C0          ret  nz
082F: 3A B5 0E    ld   a,($E05B)
0832: 3C          inc  a
0833: E6 F7       and  $7F
0835: C8          ret  z
0836: 47          ld   b,a
0837: E6 61       and  $07
0839: C0          ret  nz
083A: 3E 01       ld   a,$01
083C: 32 F9 0E    ld   ($E09F),a
083F: 3D          dec  a
0840: 32 B0 0F    ld   ($E11A),a
0843: 3E 10       ld   a,$10
0845: 32 0A 0E    ld   ($E0A0),a
0848: CD 2A 68    call $86A2
084B: C3 9D 68    jp   $86D9
084E: 3A B0 0F    ld   a,($E11A)
0851: A7          and  a
0852: C0          ret  nz
0853: 3A 0A 0E    ld   a,($E0A0)
0856: A7          and  a
0857: C0          ret  nz
0858: 3A 55 0E    ld   a,($E055)
085B: A7          and  a
085C: C0          ret  nz
085D: 3C          inc  a
085E: 32 B0 0F    ld   ($E11A),a
0861: 3E 0C       ld   a,$C0
0863: 32 D0 0F    ld   ($E11C),a
0866: CD BB 68    call $86BB
0869: C3 8E 68    jp   $86E8
086C: 21 0A CF    ld   hl,$EDA0
086F: 35          dec  (hl)
0870: 28 A2       jr   z,$089C
0872: CD ED 80    call $08CF
0875: CD 2C 80    call $08C2
0878: EB          ex   de,hl
0879: 21 0A CF    ld   hl,$EDA0
087C: 01 02 00    ld   bc,$0020
087F: ED B0       ldir
0881: 3A B0 0E    ld   a,($E01A)
0884: A7          and  a
0885: 28 E1       jr   z,$0896
0887: 21 91 0E    ld   hl,$E019
088A: 34          inc  (hl)
088B: CD 2C 80    call $08C2
088E: 7E          ld   a,(hl)
088F: A7          and  a
0890: 20 40       jr   nz,$0896
0892: 21 91 0E    ld   hl,$E019
0895: 34          inc  (hl)
0896: 3E 01       ld   a,$01
0898: 32 01 0E    ld   ($E001),a
089B: C9          ret
089C: 11 E0 00    ld   de,$000E
089F: FF          rst  $38
08A0: 3A 91 0E    ld   a,($E019)
08A3: E6 01       and  $01
08A5: C6 A1       add  a,$0B
08A7: 5F          ld   e,a
08A8: FF          rst  $38
08A9: CD 2C 80    call $08C2
08AC: 36 00       ld   (hl),$00
08AE: CD D3 68    call $863D
08B1: CD BB 68    call $86BB
08B4: CD 3E 68    call $86F2
08B7: 3E 5A       ld   a,$B4
08B9: 32 65 0E    ld   ($E047),a
08BC: 3E 80       ld   a,$08
08BE: 32 01 0E    ld   ($E001),a
08C1: C9          ret
08C2: 21 0C CF    ld   hl,$EDC0
08C5: 3A 91 0E    ld   a,($E019)
08C8: E6 01       and  $01
08CA: C8          ret  z
08CB: 21 0E CF    ld   hl,$EDE0
08CE: C9          ret

08CF: DD 21 DE 80 ld   ix,$08FC
08D3: ED 5B 2A CF ld   de,($EDA2)
08D7: 01 20 00    ld   bc,$0002
08DA: 21 00 00    ld   hl,$0000
08DD: 22 2A CF    ld   ($EDA2),hl
08E0: DD 66 01    ld   h,(ix+$01)
08E3: DD 6E 00    ld   l,(ix+$00)
08E6: A7          and  a
08E7: ED 52       sbc  hl,de
08E9: 30 81       jr   nc,$08F4
08EB: 19          add  hl,de
08EC: 22 2A CF    ld   ($EDA2),hl
08EF: DD 09       add  ix,bc
08F1: C3 0E 80    jp   $08E0
08F4: 7C          ld   a,h
08F5: B5          or   l
08F6: C0          ret  nz
08F7: 19          add  hl,de
08F8: 22 2A CF    ld   ($EDA2),hl
08FB: C9          ret

08FC: 00          nop
08FD: 00          nop
08FE: 08          ex   af,af'
08FF: 01 00 21    ld   bc,$0300
0902: 00          nop
0903: 21 0C 40    ld   hl,$04C0
0906: 04          inc  b
0907: 60          ld   h,b
0908: 00          nop
0909: 80          add  a,b
090A: 08          ex   af,af'
090B: 81          add  a,c
090C: 0C          inc  c
090D: A0          and  b
090E: 08          ex   af,af'
090F: C0          ret  nz
0910: 00          nop
0911: E0          ret  po
0912: 00          nop
0913: 10 0C       djnz $08D5
0915: 11 08 50    ld   de,$1480
0918: 00          nop
0919: 70          ld   (hl),b
091A: 00          nop
091B: 90          sub  b
091C: 08          ex   af,af'
091D: 91          sub  c
091E: 04          inc  b
091F: B1          or   c
0920: 04          inc  b
0921: D1          pop  de
0922: 04          inc  b
0923: F0          ret  p
0924: 00          nop
0925: 04          inc  b
0926: 0C          inc  c
0927: 05          dec  b
0928: 00          nop
0929: 25          dec  h
092A: 08          ex   af,af'
092B: 44          ld   b,h
092C: 0C          inc  c
092D: 45          ld   b,l
092E: 00          nop
092F: 84          add  a,h
0930: 08          ex   af,af'
0931: 85          add  a,l
0932: 00          nop
0933: A5          and  l
0934: 08          ex   af,af'
0935: C4 0C C5    call nz,$4DC0
0938: 00          nop
0939: 14          inc  d
093A: 0C          inc  c
093B: 15          dec  d
093C: 0C          inc  c
093D: 34          inc  (hl)
093E: 08          ex   af,af'
093F: 54          ld   d,h
0940: 04          inc  b
0941: 74          ld   (hl),h
0942: 00          nop
0943: 94          sub  h
0944: 00          nop
0945: 95          sub  l
0946: 0C          inc  c
0947: B4          or   h
0948: 0C          inc  c
0949: D4 04 F4    call nc,$5E40
094C: CD A7 81    call $096B
094F: CD 85 E0    call $0E49
0952: AF          xor  a
0953: 32 F9 0E    ld   ($E09F),a
0956: 3E 87       ld   a,$69
0958: 32 0B 0E    ld   ($E0A1),a
095B: 3A 8B CF    ld   a,($EDA9)
095E: E6 21       and  $03
0960: FE 21       cp   $03
0962: C2 DE 41    jp   nz,$05FC
0965: CD CF 68    call $86ED
0968: C3 DE 41    jp   $05FC
096B: CD 7B 21    call $03B7
096E: 3A 8B CF    ld   a,($EDA9)
0971: E6 21       and  $03
0973: FE 21       cp   $03
0975: 28 A1       jr   z,$0982
0977: CD 38 6B    call $A792
097A: 3E 01       ld   a,$01
097C: 32 A1 8C    ld   ($C80B),a
097F: C3 18 81    jp   $0990
0982: 21 08 20    ld   hl,$0280
0985: 22 5B 0E    ld   ($E0B5),hl
0988: 3E 00       ld   a,$00
098A: 32 7B 0E    ld   ($E0B7),a
098D: C3 67 8A    jp   $A867
0990: 3A 8B CF    ld   a,($EDA9)
0993: E6 61       and  $07
0995: 21 5B 81    ld   hl,$09B5
0998: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0999: 21 78 BC    ld   hl,$DA96
099C: 0E 21       ld   c,$03
099E: 06 40       ld   b,$04
09A0: 1A          ld   a,(de)
09A1: 13          inc  de
09A2: 77          ld   (hl),a
09A3: 1A          ld   a,(de)
09A4: CB D4       set  2,h
09A6: 77          ld   (hl),a
09A7: CB 94       res  2,h
09A9: 23          inc  hl
09AA: 13          inc  de
09AB: 10 3F       djnz $09A0
09AD: 0D          dec  c
09AE: C8          ret  z
09AF: 3E D0       ld   a,$1C
09B1: DF          rst  $18                   ; call ADD_A_TO_HL
09B2: C3 F8 81    jp   $099E
09B5: 4D          ld   c,l
09B6: 81          add  a,c
09B7: DD          db   $dd
09B8: 81          add  a,c
09B9: 5F          ld   e,a
09BA: 81          add  a,c
09BB: 5F          ld   e,a
09BC: 81          add  a,c
09BD: C1          pop  bc
09BE: A0          and  b
09BF: 43          ld   b,e
09C0: A0          and  b
09C1: D3 A0       out  ($0A),a
09C3: D3 A0       out  ($0A),a
09C5: 16 4D       ld   d,$C5
09C7: 17          rla
09C8: 4D          ld   c,l
09C9: 36 4D       ld   (hl),$C5
09CB: 9E          sbc  a,(hl)
09CC: 00          nop
09CD: 9E          sbc  a,(hl)
09CE: 00          nop
09CF: 87          add  a,a
09D0: 4D          ld   c,l
09D1: A6          and  (hl)
09D2: 4D          ld   c,l
09D3: 9E          sbc  a,(hl)
09D4: 00          nop
09D5: 9E          sbc  a,(hl)
09D6: 00          nop
09D7: 9E          sbc  a,(hl)
09D8: 00          nop
09D9: 26 4D       ld   h,$C5
09DB: 27          daa
09DC: 4D          ld   c,l
09DD: 9E          sbc  a,(hl)
09DE: 00          nop
09DF: 37          scf
09E0: 4D          ld   c,l
09E1: 56          ld   d,(hl)
09E2: 4D          ld   c,l
09E3: 9E          sbc  a,(hl)
09E4: 00          nop
09E5: 9E          sbc  a,(hl)
09E6: 00          nop
09E7: A7          and  a
09E8: 4D          ld   c,l
09E9: C6 4D       add  a,$C5
09EB: 9E          sbc  a,(hl)
09EC: 00          nop
09ED: 9E          sbc  a,(hl)
09EE: 00          nop
09EF: 37          scf
09F0: 4D          ld   c,l
09F1: 46          ld   b,(hl)
09F2: 4D          ld   c,l
09F3: 9E          sbc  a,(hl)
09F4: 00          nop
09F5: 9E          sbc  a,(hl)
09F6: 00          nop
09F7: C7          rst  $00
09F8: 4D          ld   c,l
09F9: E6 4D       and  $C5
09FB: 9E          sbc  a,(hl)
09FC: 00          nop
09FD: 9E          sbc  a,(hl)
09FE: 00          nop
09FF: 47          ld   b,a
0A00: 4D          ld   c,l
0A01: 66          ld   h,(hl)
0A02: 4D          ld   c,l
0A03: 9E          sbc  a,(hl)
0A04: 00          nop
0A05: 9E          sbc  a,(hl)
0A06: 00          nop
0A07: 9E          sbc  a,(hl)
0A08: 00          nop
0A09: 9E          sbc  a,(hl)
0A0A: 00          nop
0A0B: 9E          sbc  a,(hl)
0A0C: 00          nop
0A0D: 9E          sbc  a,(hl)
0A0E: 00          nop
0A0F: 9C          sbc  a,h
0A10: 4D          ld   c,l
0A11: 1C          inc  e
0A12: 4D          ld   c,l
0A13: 9E          sbc  a,(hl)
0A14: 00          nop
0A15: 9E          sbc  a,(hl)
0A16: 00          nop
0A17: 9E          sbc  a,(hl)
0A18: 00          nop
0A19: 8C          adc  a,h
0A1A: 4D          ld   c,l
0A1B: 9E          sbc  a,(hl)
0A1C: 00          nop
0A1D: 9E          sbc  a,(hl)
0A1E: 00          nop
0A1F: 9E          sbc  a,(hl)
0A20: 00          nop
0A21: 0C          inc  c
0A22: 4D          ld   c,l
0A23: 9E          sbc  a,(hl)
0A24: 00          nop
0A25: 8D          adc  a,l
0A26: 4D          ld   c,l
0A27: 1C          inc  e
0A28: 4D          ld   c,l
0A29: 1C          inc  e
0A2A: 4F          ld   c,a
0A2B: 8D          adc  a,l
0A2C: 4F          ld   c,a
0A2D: 0D          dec  c
0A2E: 4D          ld   c,l
0A2F: 9E          sbc  a,(hl)
0A30: 00          nop
0A31: 9E          sbc  a,(hl)
0A32: 00          nop
0A33: 0D          dec  c
0A34: 4F          ld   c,a
0A35: 9E          sbc  a,(hl)
0A36: 00          nop
0A37: 9E          sbc  a,(hl)
0A38: 00          nop
0A39: 0C          inc  c
0A3A: 4D          ld   c,l
0A3B: 9E          sbc  a,(hl)
0A3C: 00          nop
0A3D: 9E          sbc  a,(hl)
0A3E: 00          nop
0A3F: C7          rst  $00
0A40: 4D          ld   c,l
0A41: E6 4D       and  $C5
0A43: 9E          sbc  a,(hl)
0A44: 00          nop
0A45: 9E          sbc  a,(hl)
0A46: 00          nop
0A47: 9E          sbc  a,(hl)
0A48: 00          nop
0A49: 66          ld   h,(hl)
0A4A: 4D          ld   c,l
0A4B: 9E          sbc  a,(hl)
0A4C: 00          nop
0A4D: 9E          sbc  a,(hl)
0A4E: 00          nop
0A4F: 9E          sbc  a,(hl)
0A50: 00          nop
0A51: 9E          sbc  a,(hl)
0A52: 00          nop
0A53: 9E          sbc  a,(hl)
0A54: 00          nop
0A55: 9E          sbc  a,(hl)
0A56: 00          nop
0A57: 9E          sbc  a,(hl)
0A58: 00          nop
0A59: 9E          sbc  a,(hl)
0A5A: 00          nop
0A5B: 9E          sbc  a,(hl)
0A5C: 00          nop
0A5D: 9E          sbc  a,(hl)
0A5E: 00          nop
0A5F: 9E          sbc  a,(hl)
0A60: 00          nop
0A61: 9E          sbc  a,(hl)
0A62: 00          nop
0A63: 9E          sbc  a,(hl)
0A64: 00          nop
0A65: 9E          sbc  a,(hl)
0A66: 00          nop
0A67: 9E          sbc  a,(hl)
0A68: 00          nop
0A69: 9E          sbc  a,(hl)
0A6A: 00          nop
0A6B: 9E          sbc  a,(hl)
0A6C: 00          nop
0A6D: CD 06 E0    call $0E60
0A70: 3A 8B CF    ld   a,($EDA9)
0A73: E6 21       and  $03
0A75: FE 21       cp   $03
0A77: C2 6E A0    jp   nz,$0AE6
0A7A: 3A 00 0F    ld   a,($E100)
0A7D: A7          and  a
0A7E: C4 6A 88    call nz,$88A6
0A81: CD 8A 8A    call $A8A8
0A84: 3A 06 0F    ld   a,($E160)
0A87: A7          and  a
0A88: CA 51 A1    jp   z,$0B15
0A8B: 3A 7B 0E    ld   a,($E0B7)
0A8E: 3D          dec  a
0A8F: C0          ret  nz
0A90: 2A 5B 0E    ld   hl,($E0B5)
0A93: 2B          dec  hl
0A94: 7C          ld   a,h
0A95: B5          or   l
0A96: 22 5B 0E    ld   ($E0B5),hl
0A99: 28 C2       jr   z,$0AC7
0A9B: CD AA A0    call $0AAA
0A9E: 21 00 01    ld   hl,$0100
0AA1: 22 75 0E    ld   ($E057),hl
0AA4: CD 81 F9    call $9F09
0AA7: C3 81 F9    jp   $9F09
0AAA: 3A 20 0E    ld   a,($E002)
0AAD: 47          ld   b,a
0AAE: E6 F1       and  $1F
0AB0: C0          ret  nz
0AB1: 3A 8B CF    ld   a,($EDA9)
0AB4: 0F          rrca
0AB5: E6 20       and  $02
0AB7: 1E 63       ld   e,$27
0AB9: 83          add  a,e
0ABA: 5F          ld   e,a
0ABB: 16 00       ld   d,$00
0ABD: CB 68       bit  5,b
0ABF: CA 2D A0    jp   z,$0AC3
0AC2: 14          inc  d
0AC3: FF          rst  $38
0AC4: 1C          inc  e
0AC5: FF          rst  $38
0AC6: C9          ret
0AC7: 3E 20       ld   a,$02
0AC9: 32 7B 0E    ld   ($E0B7),a
0ACC: AF          xor  a
0ACD: 32 65 0E    ld   ($E047),a
0AD0: 32 0B 0E    ld   ($E0A1),a
0AD3: 21 00 04    ld   hl,$4000
0AD6: 3A B5 0E    ld   a,($E05B)
0AD9: 84          add  a,h
0ADA: E6 04       and  $40
0ADC: 67          ld   h,a
0ADD: 22 2A CF    ld   ($EDA2),hl
0AE0: CD 52 61    call $0734
0AE3: C3 E8 4B    jp   $A58E
0AE6: FD 21 92 FF ld   iy,$FF38
0AEA: CD 82 A1    call $0B28
0AED: 3A 0B 0E    ld   a,($E0A1)
0AF0: A7          and  a
0AF1: C0          ret  nz
0AF2: AF          xor  a
0AF3: 32 64 FF    ld   ($FF46),a
0AF6: 11 8D A1    ld   de,$0BC9
0AF9: CD 68 A1    call $0B86
0AFC: 11 55 A0    ld   de,$0A55
0AFF: CD 99 81    call $0999
0B02: CD 7B 21    call $03B7
0B05: 2A 2A CF    ld   hl,($EDA2)
0B08: 11 00 01    ld   de,$0100
0B0B: 19          add  hl,de
0B0C: 22 2A CF    ld   ($EDA2),hl
0B0F: CD 52 61    call $0734
0B12: CD E8 4B    call $A58E
0B15: 21 8B CF    ld   hl,$EDA9
0B18: 34          inc  (hl)
0B19: 16 81       ld   d,$09
0B1B: FF          rst  $38
0B1C: 16 C1       ld   d,$0D
0B1E: FF          rst  $38
0B1F: 16 A0       ld   d,$0A
0B21: FF          rst  $38
0B22: 16 A1       ld   d,$0B
0B24: FF          rst  $38
0B25: C3 DE 41    jp   $05FC
0B28: CD 72 A1    call $0B36
0B2B: 3A 20 0E    ld   a,($E002)
0B2E: E6 21       and  $03
0B30: C0          ret  nz
0B31: 21 0B 0E    ld   hl,$E0A1
0B34: 35          dec  (hl)
0B35: C0          ret  nz
0B36: 3A 8B CF    ld   a,($EDA9)
0B39: E6 61       and  $07
0B3B: 21 DD A1    ld   hl,$0BDD
0B3E: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0B3F: EB          ex   de,hl
0B40: 3A 20 0E    ld   a,($E002)
0B43: 0F          rrca
0B44: 0F          rrca
0B45: 0F          rrca
0B46: 0F          rrca
0B47: E6 E1       and  $0F
0B49: 32 2A 0E    ld   ($E0A2),a
0B4C: 0F          rrca
0B4D: E6 61       and  $07
0B4F: DD 21 1D A1 ld   ix,$0BD1
0B53: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0B54: CD 88 A3    call $2B88
0B57: 3A 8B CF    ld   a,($EDA9)
0B5A: E6 61       and  $07
0B5C: 28 03       jr   z,$0B7F
0B5E: FE 40       cp   $04
0B60: 28 21       jr   z,$0B65
0B62: FE 41       cp   $05
0B64: C0          ret  nz
0B65: DD 21 7D A1 ld   ix,$0BD7
0B69: 3A 20 0E    ld   a,($E002)
0B6C: 0F          rrca
0B6D: 0F          rrca
0B6E: E6 21       and  $03
0B70: 21 77 A1    ld   hl,$0B77
0B73: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0B74: C3 9C D0    jp   $1CD8
0B77: 37          scf
0B78: 08          ex   af,af'
0B79: 56          ld   d,(hl)
0B7A: 08          ex   af,af'
0B7B: D6 08       sub  $80
0B7D: 56          ld   d,(hl)
0B7E: 88          adc  a,b
0B7F: 21 0B A1    ld   hl,$0BA1
0B82: 3A 2A 0E    ld   a,($E0A2)
0B85: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0B86: 21 ED 1D    ld   hl,$D1CF
0B89: 0E 20       ld   c,$02
0B8B: 06 20       ld   b,$02
0B8D: 1A          ld   a,(de)
0B8E: 77          ld   (hl),a
0B8F: CB D4       set  2,h
0B91: 36 E1       ld   (hl),$0F
0B93: CB 94       res  2,h
0B95: 13          inc  de
0B96: 2B          dec  hl
0B97: 10 5E       djnz $0B8D
0B99: 0D          dec  c
0B9A: C8          ret  z
0B9B: 3E 22       ld   a,$22
0B9D: DF          rst  $18                   ; call ADD_A_TO_HL
0B9E: C3 A9 A1    jp   $0B8B
0BA1: 0D          dec  c
0BA2: A1          and  c
0BA3: 4D          ld   c,l
0BA4: A1          and  c
0BA5: 0D          dec  c
0BA6: A1          and  c
0BA7: 4D          ld   c,l
0BA8: A1          and  c
0BA9: 0D          dec  c
0BAA: A1          and  c
0BAB: 4D          ld   c,l
0BAC: A1          and  c
0BAD: 0D          dec  c
0BAE: A1          and  c
0BAF: 4D          ld   c,l
0BB0: A1          and  c
0BB1: 8D          adc  a,l
0BB2: A1          and  c
0BB3: 8D          adc  a,l
0BB4: A1          and  c
0BB5: 0D          dec  c
0BB6: A1          and  c
0BB7: 4D          ld   c,l
0BB8: A1          and  c
0BB9: 0D          dec  c
0BBA: A1          and  c
0BBB: 4D          ld   c,l
0BBC: A1          and  c
0BBD: 0D          dec  c
0BBE: A1          and  c
0BBF: CD A1 8B    call $A90B
0BC2: 9B          sbc  a,e
0BC3: EB          ex   de,hl
0BC4: EB          ex   de,hl
0BC5: AA          xor  d
0BC6: BA          cp   d
0BC7: EB          ex   de,hl
0BC8: EB          ex   de,hl
0BC9: EB          ex   de,hl
0BCA: EB          ex   de,hl
0BCB: EB          ex   de,hl
0BCC: EB          ex   de,hl
0BCD: EB          ex   de,hl
0BCE: AB          xor  e
0BCF: EB          ex   de,hl
0BD0: CA 00 00    jp   z,$0000
0BD3: 00          nop
0BD4: 16 00       ld   d,$00
0BD6: 06 00       ld   b,$00
0BD8: 00          nop
0BD9: 00          nop
0BDA: 96          sub  (hl)
0BDB: 00          nop
0BDC: 84          add  a,h
0BDD: CF          rst  $08
0BDE: A1          and  c
0BDF: C1          pop  bc
0BE0: C0          ret  nz
0BE1: B3          or   e
0BE2: C0          ret  nz
0BE3: B3          or   e
0BE4: C0          ret  nz
0BE5: 37          scf
0BE6: C0          ret  nz
0BE7: 79          ld   a,c
0BE8: C0          ret  nz
0BE9: FB          ei
0BEA: C0          ret  nz
0BEB: FB          ei
0BEC: C0          ret  nz
0BED: DF          rst  $18
0BEE: A1          and  c
0BEF: DF          rst  $18
0BF0: A1          and  c
0BF1: DF          rst  $18
0BF2: A1          and  c
0BF3: DF          rst  $18
0BF4: A1          and  c
0BF5: 41          ld   b,c
0BF6: C0          ret  nz
0BF7: DF          rst  $18
0BF8: A1          and  c
0BF9: DF          rst  $18
0BFA: A1          and  c
0BFB: DF          rst  $18
0BFC: A1          and  c
0BFD: 21 08 01    ld   hl,$0180
0C00: 58          ld   e,b
0C01: 11 59 00    ld   de,$0095
0C04: D8          ret  c
0C05: 21 08 01    ld   hl,$0180
0C08: 08          ex   af,af'
0C09: 11 09 00    ld   de,$0081
0C0C: 88          adc  a,b
0C0D: 13          inc  de
0C0E: C0          ret  nz
0C0F: 13          inc  de
0C10: C0          ret  nz
0C11: 13          inc  de
0C12: C0          ret  nz
0C13: D1          pop  de
0C14: C0          ret  nz
0C15: 63          ld   h,e
0C16: C0          ret  nz
0C17: D1          pop  de
0C18: C0          ret  nz
0C19: 63          ld   h,e
0C1A: C0          ret  nz
0C1B: D1          pop  de
0C1C: C0          ret  nz
0C1D: 40          ld   b,b
0C1E: 08          ex   af,af'
0C1F: 01 28 11    ld   bc,$1182
0C22: 29          add  hl,hl
0C23: 1E 89       ld   e,$89
0C25: 00          nop
0C26: A8          xor  b
0C27: 40          ld   b,b
0C28: 08          ex   af,af'
0C29: 1F          rra
0C2A: 48          ld   c,b
0C2B: 01 49 11    ld   bc,$1185
0C2E: 68          ld   l,b
0C2F: 00          nop
0C30: C9          ret
0C31: 40          ld   b,b
0C32: 08          ex   af,af'
0C33: 01 E8 11    ld   bc,$118E
0C36: E9          jp   (hl)
0C37: 00          nop
0C38: 78          ld   a,b
0C39: 00          nop
0C3A: FF          rst  $38
0C3B: A5          and  l
0C3C: C0          ret  nz
0C3D: 55          ld   d,l
0C3E: C0          ret  nz
0C3F: F5          push af
0C40: C0          ret  nz
0C41: 87          add  a,a
0C42: C0          ret  nz
0C43: F5          push af
0C44: C0          ret  nz
0C45: 87          add  a,a
0C46: C0          ret  nz
0C47: F5          push af
0C48: C0          ret  nz
0C49: 87          add  a,a
0C4A: C0          ret  nz
0C4B: 40          ld   b,b
0C4C: 08          ex   af,af'
0C4D: 01 18 11    ld   bc,$1190
0C50: 19          add  hl,de
0C51: 00          nop
0C52: 98          sbc  a,b
0C53: 10 99       djnz $0BEE
0C55: 40          ld   b,b
0C56: 08          ex   af,af'
0C57: 01 38 11    ld   bc,$1192
0C5A: 39          add  hl,sp
0C5B: 00          nop
0C5C: B8          cp   b
0C5D: 10 B9       djnz $0BFA
0C5F: 40          ld   b,b
0C60: 08          ex   af,af'
0C61: 01 18 11    ld   bc,$1190
0C64: 19          add  hl,de
0C65: 00          nop
0C66: 98          sbc  a,b
0C67: 10 99       djnz $0C02
0C69: 40          ld   b,b
0C6A: 08          ex   af,af'
0C6B: 01 A9 11    ld   bc,$118B
0C6E: C8          ret  z
0C6F: 00          nop
0C70: 98          sbc  a,b
0C71: 10 99       djnz $0C0C
0C73: 29          add  hl,hl
0C74: C0          ret  nz
0C75: C9          ret
0C76: C0          ret  nz
0C77: 29          add  hl,hl
0C78: C0          ret  nz
0C79: C9          ret
0C7A: C0          ret  nz
0C7B: 29          add  hl,hl
0C7C: C0          ret  nz
0C7D: C9          ret
0C7E: C0          ret  nz
0C7F: 29          add  hl,hl
0C80: C0          ret  nz
0C81: C9          ret
0C82: C0          ret  nz
0C83: 40          ld   b,b
0C84: 08          ex   af,af'
0C85: 01 18 11    ld   bc,$1190
0C88: 19          add  hl,de
0C89: 00          nop
0C8A: 06 E1       ld   b,$0F
0C8C: 86          add  a,(hl)
0C8D: 40          ld   b,b
0C8E: 08          ex   af,af'
0C8F: 01 18 11    ld   bc,$1190
0C92: 19          add  hl,de
0C93: 00          nop
0C94: 07          rlca
0C95: E1          pop  hl
0C96: 87          add  a,a
0C97: 6B          ld   l,e
0C98: C0          ret  nz
0C99: 3B          dec  sp
0C9A: C0          ret  nz
0C9B: 6B          ld   l,e
0C9C: C0          ret  nz
0C9D: 3B          dec  sp
0C9E: C0          ret  nz
0C9F: 6B          ld   l,e
0CA0: C0          ret  nz
0CA1: 3B          dec  sp
0CA2: C0          ret  nz
0CA3: 6B          ld   l,e
0CA4: C0          ret  nz
0CA5: 3B          dec  sp
0CA6: C0          ret  nz
0CA7: 41          ld   b,c
0CA8: 08          ex   af,af'
0CA9: 01 18 11    ld   bc,$1190
0CAC: 19          add  hl,de
0CAD: 00          nop
0CAE: 06 E1       ld   b,$0F
0CB0: 96          sub  (hl)
0CB1: F1          pop  af
0CB2: 97          sub  a
0CB3: 41          ld   b,c
0CB4: 08          ex   af,af'
0CB5: 01 18 11    ld   bc,$1190
0CB8: 19          add  hl,de
0CB9: 00          nop
0CBA: 07          rlca
0CBB: E1          pop  hl
0CBC: B6          or   (hl)
0CBD: F1          pop  af
0CBE: B7          or   a
0CBF: ED          db   $ed
0CC0: C0          ret  nz
0CC1: DD          db   $dd
0CC2: C0          ret  nz
0CC3: ED          db   $ed
0CC4: C0          ret  nz
0CC5: DD          db   $dd
0CC6: C0          ret  nz
0CC7: ED          db   $ed
0CC8: C0          ret  nz
0CC9: DD          db   $dd
0CCA: C0          ret  nz
0CCB: ED          db   $ed
0CCC: C0          ret  nz
0CCD: DD          db   $dd
0CCE: C0          ret  nz
0CCF: 60          ld   h,b
0CD0: 08          ex   af,af'
0CD1: 01 18 11    ld   bc,$1190
0CD4: 27          daa
0CD5: 03          inc  bc
0CD6: 26 00       ld   h,$00
0CD8: A6          and  (hl)
0CD9: 10 A7       djnz $0D46
0CDB: E1          pop  hl
0CDC: 36 60       ld   (hl),$06
0CDE: 08          ex   af,af'
0CDF: 01 18 11    ld   bc,$1190
0CE2: 27          daa
0CE3: 03          inc  bc
0CE4: 26 00       ld   h,$00
0CE6: 16 10       ld   d,$10
0CE8: 17          rla
0CE9: E1          pop  hl
0CEA: 36 16       ld   (hl),$70
0CEC: 41          ld   b,c
0CED: 1E 10       ld   e,$10
0CEF: FF          rst  $38
0CF0: 21 4A CF    ld   hl,$EDA4
0CF3: 34          inc  (hl)
0CF4: 7E          ld   a,(hl)
0CF5: E6 61       and  $07
0CF7: 77          ld   (hl),a
0CF8: CD 81 C1    call $0D09
0CFB: CD 60 89    call $8906
0CFE: 3E 40       ld   a,$04
0D00: 32 01 0E    ld   ($E001),a
0D03: 3E 00       ld   a,$00
0D05: 32 A1 8C    ld   ($C80B),a
0D08: C9          ret
0D09: 3A 8B CF    ld   a,($EDA9)
0D0C: E6 21       and  $03
0D0E: FE 21       cp   $03
0D10: C2 70 C1    jp   nz,$0D16
0D13: C3 2F 68    jp   $86E3
0D16: CD BB 68    call $86BB
0D19: C3 5C 68    jp   $86D4
0D1C: 3A 20 0E    ld   a,($E002)
0D1F: CB 47       bit  0,a
0D21: C0          ret  nz
0D22: 21 65 0E    ld   hl,$E047
0D25: 35          dec  (hl)
0D26: C0          ret  nz
0D27: CD 81 60    call $0609
0D2A: CD 7B 21    call $03B7
0D2D: CD 41 E0    call $0E05
0D30: 3A 6A 0E    ld   a,($E0A6)
0D33: FE 80       cp   $08
0D35: 28 50       jr   z,$0D4B
0D37: 11 03 00    ld   de,$0021
0D3A: FF          rst  $38
0D3B: 11 22 00    ld   de,$0022
0D3E: FF          rst  $38
0D3F: CD F4 98    call $985E
0D42: CD F5 98    call $985F
0D45: CD 7F 68    call $86F7
0D48: C3 DE 41    jp   $05FC
0D4B: 3A B0 0E    ld   a,($E01A)
0D4E: A7          and  a
0D4F: 28 A1       jr   z,$0D5C
0D51: 21 91 0E    ld   hl,$E019
0D54: 34          inc  (hl)
0D55: CD 2C 80    call $08C2
0D58: 7E          ld   a,(hl)
0D59: A7          and  a
0D5A: 20 11       jr   nz,$0D6D
0D5C: 16 81       ld   d,$09
0D5E: FF          rst  $38
0D5F: 3E 01       ld   a,$01
0D61: 32 00 0E    ld   ($E000),a
0D64: 3E 00       ld   a,$00
0D66: 32 01 0E    ld   ($E001),a
0D69: 32 93 0E    ld   ($E039),a
0D6C: C9          ret
0D6D: 3E 01       ld   a,$01
0D6F: 32 01 0E    ld   ($E001),a
0D72: C9          ret
0D73: CD 43 99    call $9925
0D76: 3A 71 0E    ld   a,($E017)
0D79: A7          and  a
0D7A: C8          ret  z
0D7B: CD 7B 21    call $03B7
0D7E: CD 4B C1    call $0DA5
0D81: 16 61       ld   d,$07
0D83: FF          rst  $38
0D84: CD A8 C1    call $0D8A
0D87: C3 DE 41    jp   $05FC
0D8A: CD D3 68    call $863D
0D8D: CD BB 68    call $86BB
0D90: 3E 94       ld   a,$58
0D92: 32 65 0E    ld   ($E047),a
0D95: 3A 6A 0E    ld   a,($E0A6)
0D98: FE 01       cp   $01
0D9A: C2 01 69    jp   nz,$8701
0D9D: 3E 98       ld   a,$98
0D9F: 32 65 0E    ld   ($E047),a
0DA2: C3 DE 68    jp   $86FC
0DA5: 16 81       ld   d,$09
0DA7: FF          rst  $38
0DA8: 3A 6A 0E    ld   a,($E0A6)
0DAB: FE 61       cp   $07
0DAD: 28 10       jr   z,$0DBF
0DAF: 21 1F C1    ld   hl,$0DF1
0DB2: 3D          dec  a
0DB3: DF          rst  $18                   ; call ADD_A_TO_HL
0DB4: 4E          ld   c,(hl)
0DB5: 06 00       ld   b,$00
0DB7: 11 B4 EE    ld   de,$EE5A
0DBA: 21 C5 EE    ld   hl,$EE4D
0DBD: ED B8       lddr
0DBF: 21 2F C1    ld   hl,$0DE3
0DC2: 3A 6A 0E    ld   a,($E0A6)
0DC5: 3D          dec  a
0DC6: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0DC7: 21 19 EE    ld   hl,$EE91
0DCA: 3A 91 0E    ld   a,($E019)
0DCD: E6 01       and  $01
0DCF: 28 21       jr   z,$0DD4
0DD1: 21 58 EE    ld   hl,$EE94
0DD4: ED A0       ldi
0DD6: ED A0       ldi
0DD8: ED A0       ldi
0DDA: 21 B8 EE    ld   hl,$EE9A
0DDD: 01 A0 00    ld   bc,$000A
0DE0: ED B0       ldir
0DE2: C9          ret
0DE3: 00          nop
0DE4: EE C1       xor  $0D
0DE6: EE B0       xor  $1A
0DE8: EE 63       xor  $27
0DEA: EE 52       xor  $34
0DEC: EE 05       xor  $41
0DEE: EE E4       xor  $4E
0DF0: EE E4       xor  $4E
0DF2: 05          dec  b
0DF3: 52          ld   d,d
0DF4: 63          ld   h,e
0DF5: B0          or   b
0DF6: C1          pop  bc
0DF7: 3A 20 0E    ld   a,($E002)
0DFA: E6 21       and  $03
0DFC: C0          ret  nz
0DFD: 21 65 0E    ld   hl,$E047
0E00: 35          dec  (hl)
0E01: C0          ret  nz
0E02: C3 A5 C1    jp   $0D4B
0E05: 3E 80       ld   a,$08
0E07: 32 6A 0E    ld   ($E0A6),a
0E0A: 11 19 EE    ld   de,$EE91
0E0D: 3A 91 0E    ld   a,($E019)
0E10: E6 01       and  $01
0E12: 28 21       jr   z,$0E17
0E14: 11 58 EE    ld   de,$EE94
0E17: 21 E4 EE    ld   hl,$EE4E
0E1A: 0E 61       ld   c,$07
0E1C: 22 CA 0E    ld   ($E0AC),hl
0E1F: ED 53 AA 0E ld   ($E0AA),de
0E23: 06 21       ld   b,$03
0E25: 1A          ld   a,(de)
0E26: BE          cp   (hl)
0E27: 28 40       jr   z,$0E2D
0E29: 38 D1       jr   c,$0E48
0E2B: 18 40       jr   $0E31
0E2D: 13          inc  de
0E2E: 23          inc  hl
0E2F: 10 5E       djnz $0E25
0E31: 3A 6A 0E    ld   a,($E0A6)
0E34: 3D          dec  a
0E35: 32 6A 0E    ld   ($E0A6),a
0E38: 2A CA 0E    ld   hl,($E0AC)
0E3B: ED 5B AA 0E ld   de,($E0AA)
0E3F: 7D          ld   a,l
0E40: D6 C1       sub  $0D
0E42: 6F          ld   l,a
0E43: 0D          dec  c
0E44: C2 D0 E0    jp   nz,$0E1C
0E47: C9          ret
0E48: C9          ret
0E49: 21 8B CF    ld   hl,$EDA9
0E4C: 7E          ld   a,(hl)
0E4D: E6 61       and  $07
0E4F: 21 59 E0    ld   hl,$0E95
0E52: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0E53: EB          ex   de,hl
0E54: 5E          ld   e,(hl)
0E55: 23          inc  hl
0E56: 56          ld   d,(hl)
0E57: 23          inc  hl
0E58: ED 53 1B 0E ld   ($E0B1),de
0E5C: 22 3B 0E    ld   ($E0B3),hl
0E5F: C9          ret


;
; $E0B1 = pointer to video RAM
; $E0B3 = pointer to text to print 
;

0E60: 3A 20 0E    ld   a,($E002)
0E63: E6 21       and  $03
0E65: C0          ret  nz
0E66: ED 5B 1B 0E ld   de,($E0B1)
0E6A: 2A 3B 0E    ld   hl,($E0B3)
0E6D: 7E          ld   a,(hl)
0E6E: FE 04       cp   $40
0E70: C8          ret  z
0E71: FE 23       cp   $23
0E73: 28 31       jr   z,$0E88
0E75: 12          ld   (de),a
0E76: 23          inc  hl
0E77: 22 3B 0E    ld   ($E0B3),hl
0E7A: 21 02 00    ld   hl,$0020
0E7D: 19          add  hl,de
0E7E: 22 1B 0E    ld   ($E0B1),hl
0E81: FE 02       cp   $20
0E83: C8          ret  z
0E84: C3 65 68    jp   $8647
0E87: C9          ret

0E88: 23          inc  hl
0E89: 5E          ld   e,(hl)
0E8A: 23          inc  hl
0E8B: 56          ld   d,(hl)
0E8C: ED 53 1B 0E ld   ($E0B1),de
0E90: 23          inc  hl
0E91: 22 3B 0E    ld   ($E0B3),hl
0E94: C9          ret
0E95: 4B          ld   c,e
0E96: E0          ret  po
0E97: 5D          ld   e,l
0E98: E0          ret  po
0E99: 41          ld   b,c
0E9A: E1          pop  hl
0E9B: 72          ld   (hl),d
0E9C: E1          pop  hl
0E9D: 4B          ld   c,e
0E9E: E0          ret  po
0E9F: 5D          ld   e,l
0EA0: E0          ret  po
0EA1: 41          ld   b,c
0EA2: E1          pop  hl
0EA3: A6          and  (hl)
0EA4: E1          pop  hl
0EA5: 58          ld   e,b
0EA6: 1C          inc  e
0EA7: 24          inc  h
0EA8: 34          inc  (hl)
0EA9: E5          push hl
0EAA: A5          and  l
0EAB: 45          ld   b,l
0EAC: 02          ld   (bc),a
0EAD: 54          ld   d,h
0EAE: 84          add  a,h
0EAF: 45          ld   b,l
0EB0: 02          ld   (bc),a
0EB1: 13          inc  de
0EB2: 35          dec  (hl)
0EB3: 54          ld   d,h
0EB4: 02          ld   (bc),a
0EB5: 05          dec  b
0EB6: 34          inc  (hl)
0EB7: 45          ld   b,l
0EB8: 05          dec  b
0EB9: 23          inc  hl
0EBA: 38 1C       jr   c,$0E8C
0EBC: E4 E5 75    call po,$574F
0EBF: 02          ld   (bc),a
0EC0: 34          inc  (hl)
0EC1: 55          ld   d,l
0EC2: 35          dec  (hl)
0EC3: 84          add  a,h
0EC4: 02          ld   (bc),a
0EC5: 54          ld   d,h
0EC6: E5          push hl
0EC7: 02          ld   (bc),a
0EC8: 54          ld   d,h
0EC9: 84          add  a,h
0ECA: 45          ld   b,l
0ECB: 02          ld   (bc),a
0ECC: 32 E4 44    ld   ($444E),a
0ECF: 02          ld   (bc),a
0ED0: 05          dec  b
0ED1: 34          inc  (hl)
0ED2: 45          ld   b,l
0ED3: 05          dec  b
0ED4: 04          inc  b
0ED5: 58          ld   e,b
0ED6: 1C          inc  e
0ED7: 24          inc  h
0ED8: 34          inc  (hl)
0ED9: E5          push hl
0EDA: A5          and  l
0EDB: 45          ld   b,l
0EDC: 02          ld   (bc),a
0EDD: 54          ld   d,h
0EDE: 84          add  a,h
0EDF: 45          ld   b,l
0EE0: 02          ld   (bc),a
0EE1: 32 E4 44    ld   ($444E),a
0EE4: 02          ld   (bc),a
0EE5: 05          dec  b
0EE6: 34          inc  (hl)
0EE7: 45          ld   b,l
0EE8: 05          dec  b
0EE9: 23          inc  hl
0EEA: 38 1C       jr   c,$0EBC
0EEC: E4 E5 75    call po,$574F
0EEF: 02          ld   (bc),a
0EF0: 34          inc  (hl)
0EF1: 55          ld   d,l
0EF2: 35          dec  (hl)
0EF3: 84          add  a,h
0EF4: 02          ld   (bc),a
0EF5: 54          ld   d,h
0EF6: E5          push hl
0EF7: 02          ld   (bc),a
0EF8: 54          ld   d,h
0EF9: 84          add  a,h
0EFA: 45          ld   b,l
0EFB: 02          ld   (bc),a
0EFC: 33          inc  sp
0EFD: 34          inc  (hl)
0EFE: 44          ld   b,h
0EFF: 02          ld   (bc),a
0F00: 05          dec  b
0F01: 34          inc  (hl)
0F02: 45          ld   b,l
0F03: 05          dec  b
0F04: 04          inc  b
0F05: 5A          ld   e,d
0F06: 1C          inc  e
0F07: 24          inc  h
0F08: 34          inc  (hl)
0F09: E5          push hl
0F0A: A5          and  l
0F0B: 45          ld   b,l
0F0C: 02          ld   (bc),a
0F0D: 54          ld   d,h
0F0E: 84          add  a,h
0F0F: 45          ld   b,l
0F10: 02          ld   (bc),a
0F11: 33          inc  sp
0F12: 34          inc  (hl)
0F13: 44          ld   b,h
0F14: 02          ld   (bc),a
0F15: 05          dec  b
0F16: 34          inc  (hl)
0F17: 45          ld   b,l
0F18: 05          dec  b
0F19: 23          inc  hl
0F1A: 3A 1C E4    ld   a,($4ED0)
0F1D: E5          push hl
0F1E: 75          ld   (hl),l
0F1F: 02          ld   (bc),a
0F20: 34          inc  (hl)
0F21: 55          ld   d,l
0F22: 35          dec  (hl)
0F23: 84          add  a,h
0F24: 02          ld   (bc),a
0F25: 54          ld   d,h
0F26: E5          push hl
0F27: 02          ld   (bc),a
0F28: 54          ld   d,h
0F29: 84          add  a,h
0F2A: 45          ld   b,l
0F2B: 02          ld   (bc),a
0F2C: C4 05 35    call nz,$5341
0F2F: 54          ld   d,h
0F30: 02          ld   (bc),a
0F31: 05          dec  b
0F32: 34          inc  (hl)
0F33: 45          ld   b,l
0F34: 05          dec  b
0F35: 04          inc  b
0F36: 00          nop
0F37: 1C          inc  e
0F38: 04          inc  b
0F39: 78          ld   a,b
0F3A: 1C          inc  e
0F3B: 02          ld   (bc),a
0F3C: 02          ld   (bc),a
0F3D: 02          ld   (bc),a
0F3E: 02          ld   (bc),a
0F3F: 02          ld   (bc),a
0F40: 25          dec  h
0F41: E5          push hl
0F42: E4 65 34    call po,$5247
0F45: 05          dec  b
0F46: 54          ld   d,h
0F47: 55          ld   d,l
0F48: C4 05 54    call nz,$5441
0F4B: 85          add  a,l
0F4C: E5          push hl
0F4D: E4 23 58    call po,$9423
0F50: 1C          inc  e
0F51: 95          sub  l
0F52: E5          push hl
0F53: 55          ld   d,l
0F54: 34          inc  (hl)
0F55: 02          ld   (bc),a
0F56: 64          ld   h,h
0F57: 85          add  a,l
0F58: 34          inc  (hl)
0F59: 35          dec  (hl)
0F5A: 54          ld   d,h
0F5B: 02          ld   (bc),a
0F5C: 44          ld   b,h
0F5D: 55          ld   d,l
0F5E: 54          ld   d,h
0F5F: 95          sub  l
0F60: 02          ld   (bc),a
0F61: 64          ld   h,h
0F62: 85          add  a,l
0F63: E4 85 35    call po,$5349
0F66: 84          add  a,h
0F67: 45          ld   b,l
0F68: 44          ld   b,h
0F69: 04          inc  b
0F6A: 00          nop
0F6B: 1C          inc  e
0F6C: 04          inc  b
0F6D: 78          ld   a,b
0F6E: 1C          inc  e
0F6F: 02          ld   (bc),a
0F70: 02          ld   (bc),a
0F71: 02          ld   (bc),a
0F72: 02          ld   (bc),a
0F73: 02          ld   (bc),a
0F74: 25          dec  h
0F75: E5          push hl
0F76: E4 65 34    call po,$5247
0F79: 05          dec  b
0F7A: 54          ld   d,h
0F7B: 55          ld   d,l
0F7C: C4 05 54    call nz,$5441
0F7F: 85          add  a,l
0F80: E5          push hl
0F81: E4 23 58    call po,$9423
0F84: 1C          inc  e
0F85: 95          sub  l
0F86: E5          push hl
0F87: 55          ld   d,l
0F88: 34          inc  (hl)
0F89: 02          ld   (bc),a
0F8A: 45          ld   b,l
0F8B: 74          ld   (hl),h
0F8C: 45          ld   b,l
0F8D: 34          inc  (hl)
0F8E: 95          sub  l
0F8F: 02          ld   (bc),a
0F90: 44          ld   b,h
0F91: 55          ld   d,l
0F92: 54          ld   d,h
0F93: 95          sub  l
0F94: 02          ld   (bc),a
0F95: 64          ld   h,h
0F96: 85          add  a,l
0F97: E4 85 35    call po,$5349
0F9A: 84          add  a,h
0F9B: 45          ld   b,l
0F9C: 44          ld   b,h
0F9D: 04          inc  b
0F9E: AF          xor  a
0F9F: 32 55 0E    ld   ($E055),a
0FA2: DD 21 00 6E ld   ix,$E600
0FA6: FD 21 9C FE ld   iy,$FED8
0FAA: 06 80       ld   b,$08
0FAC: C5          push bc
0FAD: DD 7E 00    ld   a,(ix+$00)
0FB0: A7          and  a
0FB1: 28 E1       jr   z,$0FC2
0FB3: 21 55 0E    ld   hl,$E055
0FB6: 34          inc  (hl)
0FB7: 21 2C E1    ld   hl,$0FC2
0FBA: E5          push hl
0FBB: 3C          inc  a
0FBC: CA 1C E1    jp   z,$0FD0
0FBF: C3 68 71    jp   $1786
0FC2: C1          pop  bc
0FC3: 11 02 00    ld   de,$0020
0FC6: DD 19       add  ix,de
0FC8: 11 C0 00    ld   de,$000C
0FCB: FD 19       add  iy,de
0FCD: 10 DD       djnz $0FAC
0FCF: C9          ret
0FD0: DD 7E 21    ld   a,(ix+$03)
0FD3: C6 C0       add  a,$0C
0FD5: FE 80       cp   $08
0FD7: DA DD 71    jp   c,$17DD
0FDA: DD 7E 41    ld   a,(ix+$05)
0FDD: FE 21       cp   $03
0FDF: DA DD 71    jp   c,$17DD
0FE2: DD CB 30 6A res  4,(ix+$12)
0FE6: CD 43 10    call $1025
0FE9: CD 88 31    call $1388
0FEC: CD 75 70    call $1657
0FEF: C9          ret
0FF0: DD 7E 11    ld   a,(ix+$11)
0FF3: 3C          inc  a
0FF4: 28 B1       jr   z,$1011
0FF6: DD 7E 01    ld   a,(ix+$01)
0FF9: C6 80       add  a,$08
0FFB: 0F          rrca
0FFC: 0F          rrca
0FFD: 0F          rrca
0FFE: 0F          rrca
0FFF: E6 E1       and  $0F
1001: 21 51 10    ld   hl,$1015
1004: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
1005: DD 77 01    ld   (ix+$01),a
1008: DD 77 20    ld   (ix+$02),a
100B: CD 9B 51    call $15B9
100E: C3 94 31    jp   $1358
1011: E1          pop  hl
1012: C3 DD 71    jp   $17DD
1015: 0A          ld   a,(bc)
1016: 14          inc  d
1017: 06 1C       ld   b,$D0
1019: 0E 1A       ld   c,$B0
101B: 1E 0C       ld   e,$C0
101D: 10 16       djnz $108F
101F: 04          inc  b
1020: 12          ld   (de),a
1021: 02          ld   (bc),a
1022: 08          ex   af,af'
1023: 18 1A       jr   $0FD5
1025: DD 7E 11    ld   a,(ix+$11)
1028: E6 01       and  $01
102A: 20 4C       jr   nz,$0FF0
102C: DD 7E 31    ld   a,(ix+$13)
102F: F7          rst  $30
1030: E2 50 E2    jp   po,$2E14
1033: 50          ld   d,b
1034: 06 30       ld   b,$12
1036: C8          ret  z
1037: 10 2F       djnz $101C
1039: 10 23       djnz $105E
103B: 11 6B 30    ld   de,$12A7
103E: 06 30       ld   b,$12
1040: E2 50 E6    jp   po,$6E14
1043: 30 64       jr   nc,$108B
1045: 10 CD       djnz $1014
1047: 94          sub  h
1048: 31 DD CB    ld   sp,$ADDD
104B: 30 6E       jr   nc,$1033
104D: 3A 20 0E    ld   a,($E002)
1050: 0F          rrca
1051: 0F          rrca
1052: E6 21       and  $03
1054: 21 E6 10    ld   hl,$106E
1057: 0E 16       ld   c,$70
1059: DD CB 91 64 bit  0,(ix+$19)
105D: 28 41       jr   z,$1064
105F: 21 76 10    ld   hl,$1076
1062: 0E 96       ld   c,$78
1064: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1065: EB          ex   de,hl
1066: 7E          ld   a,(hl)
1067: DD 77 F0    ld   (ix+$1e),a
106A: 23          inc  hl
106B: C3 2C C9    jp   $8DC2
106E: F6 10       or   $10
1070: 68          ld   l,b
1071: 10 89       djnz $0FFC
1073: 10 68       djnz $0FFB
1075: 10 28       djnz $0FF9
1077: 10 68       djnz $0FFF
1079: 10 89       djnz $1004
107B: 10 68       djnz $1003
107D: 10 01       djnz $1080
107F: 41          ld   b,c
1080: C1          pop  bc
1081: E0          ret  po
1082: 01 41 E0    ld   bc,$0E05
1085: C1          pop  bc
1086: 00          nop
1087: 72          ld   (hl),d
1088: F2 00 73    jp   p,$3700
108B: F3          di
108C: DD 7E 51    ld   a,(ix+$15)
108F: A7          and  a
1090: CC D9 10    call z,$109D
1093: DD 35 51    dec  (ix+$15)
1096: CD 95 90    call $1859
1099: CD 94 31    call $1358
109C: C9          ret
109D: DD 7E 50    ld   a,(ix+$14)
10A0: FE 02       cp   $20
10A2: D0          ret  nc
10A3: DD 34 50    inc  (ix+$14)
10A6: E6 21       and  $03
10A8: 28 F0       jr   z,$10C8
10AA: CD 2E C6    call $6CE2
10AD: DD 77 01    ld   (ix+$01),a
10B0: CD E3 98    call $982F
10B3: 3C          inc  a
10B4: E6 F3       and  $3F
10B6: DD 77 51    ld   (ix+$15),a
10B9: D6 02       sub  $20
10BB: DD 86 01    add  a,(ix+$01)
10BE: DD 77 01    ld   (ix+$01),a
10C1: DD 36 E1 00 ld   (ix+$0f),$00
10C5: C3 9B 51    jp   $15B9
10C8: DD 7E F1    ld   a,(ix+$1f)
10CB: E6 61       and  $07
10CD: 07          rlca
10CE: 07          rlca
10CF: 07          rlca
10D0: 47          ld   b,a
10D1: 3A 20 0E    ld   a,($E002)
10D4: 80          add  a,b
10D5: DD 77 01    ld   (ix+$01),a
10D8: DD 77 20    ld   (ix+$02),a
10DB: E6 F7       and  $7F
10DD: DD 77 51    ld   (ix+$15),a
10E0: C3 9B 51    jp   $15B9
10E3: DD 7E 51    ld   a,(ix+$15)
10E6: A7          and  a
10E7: CC 40 11    call z,$1104
10EA: DD 7E 71    ld   a,(ix+$17)
10ED: A7          and  a
10EE: 20 A0       jr   nz,$10FA
10F0: DD 35 51    dec  (ix+$15)
10F3: CD 95 90    call $1859
10F6: CD 94 31    call $1358
10F9: C9          ret
10FA: DD 35 51    dec  (ix+$15)
10FD: DD CB 30 6E set  4,(ix+$12)
1101: C3 55 50    jp   $1455
1104: CD E3 98    call $982F
1107: E6 F1       and  $1F
1109: C6 12       add  a,$30
110B: DD 77 51    ld   (ix+$15),a
110E: DD 34 50    inc  (ix+$14)
1111: DD CB 50 64 bit  0,(ix+$14)
1115: DD 36 71 00 ld   (ix+$17),$00
1119: C0          ret  nz
111A: DD 36 51 90 ld   (ix+$15),$18
111E: DD 36 71 01 ld   (ix+$17),$01
1122: C9          ret
1123: DD CB 30 6E set  4,(ix+$12)
1127: CD A6 11    call $116A
112A: DD 7E 50    ld   a,(ix+$14)
112D: E6 21       and  $03
112F: 28 31       jr   z,$1144
1131: FE 20       cp   $02
1133: 20 A0       jr   nz,$113F
1135: DD 7E 70    ld   a,(ix+$16)
1138: 87          add  a,a
1139: 21 46 11    ld   hl,$1164
113C: DF          rst  $18                   ; call ADD_A_TO_HL
113D: 18 30       jr   $1151
113F: 21 26 11    ld   hl,$1162
1142: 18 C1       jr   $1151
1144: 3A 20 0E    ld   a,($E002)
1147: 21 B4 11    ld   hl,$115A
114A: CB 5F       bit  3,a
114C: 28 21       jr   z,$1151
114E: 21 D4 11    ld   hl,$115C
1151: 0E 04       ld   c,$40
1153: DD 36 F0 00 ld   (ix+$1e),$00
1157: C3 2C C9    jp   $8DC2
115A: 10 90       djnz $1174
115C: 11 91 10    ld   de,$1019
115F: 90          sub  b
1160: 11 B0 31    ld   de,$131A
1163: 30 50       jr   nc,$1179
1165: D0          ret  nc
1166: 31 B1 56    ld   sp,$741B
1169: B7          or   a
116A: DD 7E 51    ld   a,(ix+$15)
116D: A7          and  a
116E: 28 E0       jr   z,$117E
1170: DD 35 51    dec  (ix+$15)
1173: DD 7E 50    ld   a,(ix+$14)
1176: E6 21       and  $03
1178: C2 19 51    jp   nz,$1591
117B: C3 94 31    jp   $1358
117E: DD 7E 50    ld   a,(ix+$14)
1181: FE 21       cp   $03
1183: 28 33       jr   z,$11B8
1185: FE 01       cp   $01
1187: 38 C0       jr   c,$1195
1189: CA 0D 11    jp   z,$11C1
118C: DD 36 50 21 ld   (ix+$14),$03
1190: DD 36 51 80 ld   (ix+$15),$08
1194: C9          ret
1195: CD 2E C6    call $6CE2
1198: DD 77 20    ld   (ix+$02),a
119B: C6 94       add  a,$58
119D: FE 12       cp   $30
119F: 38 60       jr   c,$11A7
11A1: E6 F1       and  $1F
11A3: DD 77 51    ld   (ix+$15),a
11A6: C9          ret
11A7: 0F          rrca
11A8: 0F          rrca
11A9: 0F          rrca
11AA: 0F          rrca
11AB: E6 21       and  $03
11AD: DD 77 70    ld   (ix+$16),a
11B0: DD 36 51 00 ld   (ix+$15),$00
11B4: DD 34 50    inc  (ix+$14)
11B7: C9          ret
11B8: DD 36 50 00 ld   (ix+$14),$00
11BC: DD 36 51 A0 ld   (ix+$15),$0A
11C0: C9          ret
11C1: 3A 3F 0E    ld   a,($E0F3)
11C4: A7          and  a
11C5: 20 F2       jr   nz,$1205
11C7: 3A 1F 0E    ld   a,($E0F1)
11CA: 57          ld   d,a
11CB: 87          add  a,a
11CC: 3C          inc  a
11CD: 5F          ld   e,a
11CE: DD 66 21    ld   h,(ix+$03)
11D1: DD 6E 41    ld   l,(ix+$05)
11D4: 3A 21 0F    ld   a,($E103)
11D7: 94          sub  h
11D8: 82          add  a,d
11D9: BB          cp   e
11DA: 30 80       jr   nc,$11E4
11DC: 3A 41 0F    ld   a,($E105)
11DF: 95          sub  l
11E0: 82          add  a,d
11E1: BB          cp   e
11E2: 38 03       jr   c,$1205
11E4: DD E5       push ix
11E6: E5          push hl
11E7: DD 6E 70    ld   l,(ix+$16)
11EA: DD 4E 20    ld   c,(ix+$02)
11ED: 3A 1E 0E    ld   a,($E0F0)
11F0: 47          ld   b,a
11F1: DD 21 0C 2E ld   ix,$E2C0
11F5: 11 02 00    ld   de,$0020
11F8: DD 7E 00    ld   a,(ix+$00)
11FB: A7          and  a
11FC: 28 10       jr   z,$120E
11FE: DD 19       add  ix,de
1200: 10 7E       djnz $11F8
1202: E1          pop  hl
1203: DD E1       pop  ix
1205: DD 36 51 A0 ld   (ix+$15),$0A
1209: DD 36 50 00 ld   (ix+$14),$00
120D: C9          ret
120E: DD 35 00    dec  (ix+$00)
1211: DD 71 01    ld   (ix+$01),c
1214: DD 36 31 01 ld   (ix+$13),$01
1218: DD 75 91    ld   (ix+$19),l
121B: 7D          ld   a,l
121C: 21 B4 30    ld   hl,$125A
121F: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1220: E1          pop  hl
1221: 7B          ld   a,e
1222: 84          add  a,h
1223: DD 77 21    ld   (ix+$03),a
1226: 7A          ld   a,d
1227: 85          add  a,l
1228: DD 77 41    ld   (ix+$05),a
122B: DD 36 E1 60 ld   (ix+$0f),$06
122F: DD 7E 01    ld   a,(ix+$01)
1232: CD 46 C6    call $6C64
1235: DD 72 A1    ld   (ix+$0b),d
1238: DD 73 C0    ld   (ix+$0c),e
123B: DD 70 C1    ld   (ix+$0d),b
123E: DD 71 E0    ld   (ix+$0e),c
1241: DD 36 30 84 ld   (ix+$12),$48
1245: DD 36 50 00 ld   (ix+$14),$00
1249: DD 36 51 80 ld   (ix+$15),$08
124D: DD E1       pop  ix
124F: DD 34 50    inc  (ix+$14)
1252: DD 36 51 80 ld   (ix+$15),$08
1256: CD 24 68    call $8642
1259: C9          ret
125A: 7E          ld   a,(hl)
125B: 9E          sbc  a,(hl)
125C: BF          cp   a
125D: 7E          ld   a,(hl)
125E: 20 5E       jr   nz,$1254
1260: DD 7E 51    ld   a,(ix+$15)
1263: A7          and  a
1264: C2 90 31    jp   nz,$1318
1267: CD 95 90    call $1859
126A: CD 94 31    call $1358
126D: C9          ret
126E: DD 7E 50    ld   a,(ix+$14)
1271: A7          and  a
1272: CA 9D 30    jp   z,$12D9
1275: DD 7E 71    ld   a,(ix+$17)
1278: A7          and  a
1279: 20 C1       jr   nz,$1288
127B: CD 95 90    call $1859
127E: DD 35 51    dec  (ix+$15)
1281: CC 58 30    call z,$1294
1284: CD 94 31    call $1358
1287: C9          ret
1288: DD 35 51    dec  (ix+$15)
128B: 28 61       jr   z,$1294
128D: DD CB 30 6E set  4,(ix+$12)
1291: C3 55 50    jp   $1455
1294: DD 34 50    inc  (ix+$14)
1297: E6 20       and  $02
1299: 0F          rrca
129A: DD 77 71    ld   (ix+$17),a
129D: 20 21       jr   nz,$12A2
129F: C3 4C 30    jp   $12C4
12A2: DD 36 51 90 ld   (ix+$15),$18
12A6: C9          ret
12A7: DD 7E 50    ld   a,(ix+$14)
12AA: A7          and  a
12AB: 28 C2       jr   z,$12D9
12AD: CD 95 90    call $1859
12B0: CD 7B 30    call $12B7
12B3: CD 94 31    call $1358
12B6: C9          ret
12B7: DD 35 51    dec  (ix+$15)
12BA: C0          ret  nz
12BB: DD 7E 50    ld   a,(ix+$14)
12BE: FE 80       cp   $08
12C0: D0          ret  nc
12C1: DD 34 50    inc  (ix+$14)
12C4: CD 2E C6    call $6CE2
12C7: DD 77 20    ld   (ix+$02),a
12CA: DD 77 01    ld   (ix+$01),a
12CD: 0F          rrca
12CE: 0F          rrca
12CF: E6 F1       and  $1F
12D1: C6 02       add  a,$20
12D3: DD 77 51    ld   (ix+$15),a
12D6: C3 9B 51    jp   $15B9
12D9: DD 7E 31    ld   a,(ix+$13)
12DC: 21 CB 70    ld   hl,$16AD
12DF: DF          rst  $18                   ; call ADD_A_TO_HL
12E0: 4E          ld   c,(hl)
12E1: DD 35 51    dec  (ix+$15)
12E4: 28 50       jr   z,$12FA
12E6: DD CB 30 6E set  4,(ix+$12)
12EA: CD 19 51    call $1591
12ED: 1E E7       ld   e,$6F
12EF: DD 7E 71    ld   a,(ix+$17)
12F2: E6 01       and  $01
12F4: 20 B1       jr   nz,$1311
12F6: 51          ld   d,c
12F7: C3 9C D0    jp   $1CD8
12FA: DD 36 01 0C ld   (ix+$01),$C0
12FE: DD 36 20 0C ld   (ix+$02),$C0
1302: DD 36 50 01 ld   (ix+$14),$01
1306: DD 36 51 10 ld   (ix+$15),$10
130A: DD 36 71 00 ld   (ix+$17),$00
130E: C3 9B 51    jp   $15B9
1311: 79          ld   a,c
1312: C6 80       add  a,$08
1314: 57          ld   d,a
1315: C3 9C D0    jp   $1CD8
1318: DD 7E 31    ld   a,(ix+$13)
131B: 21 CB 70    ld   hl,$16AD
131E: DF          rst  $18                   ; call ADD_A_TO_HL
131F: 56          ld   d,(hl)
1320: DD 35 51    dec  (ix+$15)
1323: DD CB 30 6E set  4,(ix+$12)
1327: CD 19 51    call $1591
132A: 3A 20 0E    ld   a,($E002)
132D: E6 21       and  $03
132F: CC 25 31    call z,$1343
1332: 1E 4A       ld   e,$A4
1334: DD 7E 51    ld   a,(ix+$15)
1337: FE 61       cp   $07
1339: D2 9C D0    jp   nc,$1CD8
133C: 1E AB       ld   e,$AB
133E: C3 9C D0    jp   $1CD8
1341: AB          xor  e
1342: 4A          ld   c,d
1343: DD 7E 21    ld   a,(ix+$03)
1346: FE 08       cp   $80
1348: 30 61       jr   nc,$1351
134A: DD 34 21    inc  (ix+$03)
134D: DD 34 61    inc  (ix+$07)
1350: C9          ret
1351: DD 35 21    dec  (ix+$03)
1354: DD 35 61    dec  (ix+$07)
1357: C9          ret
1358: DD 66 21    ld   h,(ix+$03)
135B: DD 6E 40    ld   l,(ix+$04)
135E: DD 56 A1    ld   d,(ix+$0b)
1361: DD 5E C0    ld   e,(ix+$0c)
1364: 19          add  hl,de
1365: DD 74 61    ld   (ix+$07),h
1368: DD 75 80    ld   (ix+$08),l
136B: 3A 26 0E    ld   a,($E062)
136E: A7          and  a
136F: 28 21       jr   z,$1374
1371: DD 35 41    dec  (ix+$05)
1374: DD 66 41    ld   h,(ix+$05)
1377: DD 6E 60    ld   l,(ix+$06)
137A: DD 56 C1    ld   d,(ix+$0d)
137D: DD 5E E0    ld   e,(ix+$0e)
1380: 19          add  hl,de
1381: DD 74 81    ld   (ix+$09),h
1384: DD 75 A0    ld   (ix+$0a),l
1387: C9          ret
1388: DD 7E 31    ld   a,(ix+$13)
138B: E6 E1       and  $0F
138D: 28 17       jr   z,$1400
138F: DD CB 31 F6 bit  7,(ix+$13)
1393: C0          ret  nz
1394: DD 7E 90    ld   a,(ix+$18)
1397: A7          and  a
1398: 28 60       jr   z,$13A0
139A: DD 35 90    dec  (ix+$18)
139D: C3 00 50    jp   $1400
13A0: CD 39 A9    call $8B93
13A3: A7          and  a
13A4: C2 D1 50    jp   nz,$141D
13A7: DD 7E 81    ld   a,(ix+$09)
13AA: 47          ld   b,a
13AB: 3A 30 EF    ld   a,($EF12)
13AE: E6 E1       and  $0F
13B0: 80          add  a,b
13B1: 47          ld   b,a
13B2: DD 7E 61    ld   a,(ix+$07)
13B5: C6 61       add  a,$07
13B7: 4F          ld   c,a
13B8: 3A 10 EF    ld   a,($EF10)
13BB: 57          ld   d,a
13BC: 3A 11 EF    ld   a,($EF11)
13BF: 5F          ld   e,a
13C0: 78          ld   a,b
13C1: E6 1E       and  $F0
13C3: 6F          ld   l,a
13C4: 26 00       ld   h,$00
13C6: 29          add  hl,hl
13C7: 19          add  hl,de
13C8: 79          ld   a,c
13C9: CB 3F       srl  a
13CB: 4F          ld   c,a
13CC: CB 3F       srl  a
13CE: CB 3F       srl  a
13D0: E6 F0       and  $1E
13D2: DF          rst  $18                   ; call ADD_A_TO_HL
13D3: 7C          ld   a,h
13D4: E6 BF       and  $FB
13D6: 67          ld   h,a
13D7: 7E          ld   a,(hl)
13D8: A7          and  a
13D9: 28 43       jr   z,$1400
13DB: 5F          ld   e,a
13DC: 23          inc  hl
13DD: 7E          ld   a,(hl)
13DE: A7          and  a
13DF: 28 21       jr   z,$13E4
13E1: 79          ld   a,c
13E2: 2F          cpl
13E3: 4F          ld   c,a
13E4: 6B          ld   l,e
13E5: 26 00       ld   h,$00
13E7: 29          add  hl,hl
13E8: 29          add  hl,hl
13E9: 29          add  hl,hl
13EA: 78          ld   a,b
13EB: 0F          rrca
13EC: 2F          cpl
13ED: E6 61       and  $07
13EF: DF          rst  $18                   ; call ADD_A_TO_HL
13F0: 11 46 46    ld   de,$6464
13F3: 19          add  hl,de
13F4: 56          ld   d,(hl)
13F5: 79          ld   a,c
13F6: E6 61       and  $07
13F8: 21 62 50    ld   hl,$1426
13FB: DF          rst  $18                   ; call ADD_A_TO_HL
13FC: 7E          ld   a,(hl)
13FD: A2          and  d
13FE: 20 D1       jr   nz,$141D
1400: DD 36 11 00 ld   (ix+$11),$00
1404: DD 66 61    ld   h,(ix+$07)
1407: DD 6E 80    ld   l,(ix+$08)
140A: DD 56 81    ld   d,(ix+$09)
140D: DD 5E A0    ld   e,(ix+$0a)
1410: DD 74 21    ld   (ix+$03),h
1413: DD 75 40    ld   (ix+$04),l
1416: DD 72 41    ld   (ix+$05),d
1419: DD 73 60    ld   (ix+$06),e
141C: C9          ret
141D: DD CB 11 70 rl   (ix+$11)
1421: DD CB 11 6C set  0,(ix+$11)
1425: C9          ret
1426: 08          ex   af,af'
1427: 04          inc  b
1428: 02          ld   (bc),a
1429: 10 80       djnz $1433
142B: 40          ld   b,b
142C: 20 01       jr   nz,$142F
142E: DD 7E 51    ld   a,(ix+$15)
1431: A7          and  a
1432: CC D9 51    call z,$159D
1435: DD 35 51    dec  (ix+$15)
1438: DD 7E 50    ld   a,(ix+$14)
143B: A7          and  a
143C: 20 60       jr   nz,$1444
143E: CD 94 31    call $1358
1441: C3 95 90    jp   $1859
1444: F7          rst  $30
1445: F2 50 F2    jp   p,$3E14
1448: 50          ld   d,b
1449: F2 50 F2    jp   p,$3E14
144C: 50          ld   d,b
144D: 55          ld   d,l
144E: 50          ld   d,b
144F: 2D          dec  l
1450: 50          ld   d,b
1451: 74          ld   (hl),h
1452: 51          ld   d,c
1453: F2 50 DD    jp   p,$DD14
1456: 7E          ld   a,(hl)
1457: 51          ld   d,c
1458: FE 80       cp   $08
145A: CC 96 50    call z,$1478
145D: CD 19 51    call $1591
1460: 0E 00       ld   c,$00
1462: 21 86 50    ld   hl,$1468
1465: C3 D4 51    jp   $155C
1468: E6 50       and  $14
146A: 17          rla
146B: 50          ld   d,b
146C: 57          ld   d,a
146D: 50          ld   d,b
146E: 10 6C       djnz $1436
1470: 5D          ld   e,l
1471: 30 7C       jr   nc,$1449
1473: 7D          ld   a,l
1474: FD          db   $fd
1475: 10 6D       djnz $143E
1477: ED          db   $ed
1478: DD E5       push ix
147A: 21 0C 50    ld   hl,$14C0
147D: E5          push hl
147E: DD 66 21    ld   h,(ix+$03)
1481: DD 6E 41    ld   l,(ix+$05)
1484: D9          exx
1485: DD 21 0E 4F ld   ix,$E5E0
1489: 21 50 FE    ld   hl,$FE14
148C: 3E 41       ld   a,$05
148E: 08          ex   af,af'
148F: 01 40 00    ld   bc,$0004
1492: 11 0E FF    ld   de,$FFE0
1495: DD 7E 00    ld   a,(ix+$00)
1498: A7          and  a
1499: 28 81       jr   z,$14A4
149B: 09          add  hl,bc
149C: DD 19       add  ix,de
149E: 08          ex   af,af'
149F: 3D          dec  a
14A0: C8          ret  z
14A1: 08          ex   af,af'
14A2: 18 1F       jr   $1495
14A4: DD 74 B1    ld   (ix+$1b),h
14A7: DD 75 D0    ld   (ix+$1c),l
14AA: D9          exx
14AB: DD 74 21    ld   (ix+$03),h
14AE: DD 75 41    ld   (ix+$05),l
14B1: DD 36 00 FF ld   (ix+$00),$FF
14B5: DD 36 31 C1 ld   (ix+$13),$0D
14B9: DD 36 B0 01 ld   (ix+$1a),$01
14BD: C3 06 02    jp   $2060
14C0: DD E1       pop  ix
14C2: C9          ret
14C3: CD 19 51    call $1591
14C6: 21 E0 51    ld   hl,$150E
14C9: CD B6 51    call $157A
14CC: DD 66 21    ld   h,(ix+$03)
14CF: DD 6E 40    ld   l,(ix+$04)
14D2: DD 7E 01    ld   a,(ix+$01)
14D5: C6 04       add  a,$40
14D7: FE 08       cp   $80
14D9: 30 90       jr   nc,$14F3
14DB: 11 08 00    ld   de,$0080
14DE: 19          add  hl,de
14DF: DD 74 61    ld   (ix+$07),h
14E2: DD 75 80    ld   (ix+$08),l
14E5: DD 7E 31    ld   a,(ix+$13)
14E8: 21 CB 70    ld   hl,$16AD
14EB: DF          rst  $18                   ; call ADD_A_TO_HL
14EC: 4E          ld   c,(hl)
14ED: 21 F0 51    ld   hl,$151E
14F0: C3 D4 51    jp   $155C
14F3: 11 08 FF    ld   de,$FF80
14F6: 19          add  hl,de
14F7: DD 74 61    ld   (ix+$07),h
14FA: DD 75 80    ld   (ix+$08),l
14FD: DD 7E 31    ld   a,(ix+$13)
1500: 21 CB 70    ld   hl,$16AD
1503: DF          rst  $18                   ; call ADD_A_TO_HL
1504: 7E          ld   a,(hl)
1505: C6 80       add  a,$08
1507: 4F          ld   c,a
1508: 21 F2 51    ld   hl,$153E
150B: C3 D4 51    jp   $155C
150E: 00          nop
150F: 00          nop
1510: 16 FE       ld   d,$FE
1512: 02          ld   (bc),a
1513: FF          rst  $38
1514: 16 FF       ld   d,$FF
1516: 1A          ld   a,(de)
1517: FF          rst  $38
1518: 04          inc  b
1519: 00          nop
151A: 08          ex   af,af'
151B: 00          nop
151C: 00          nop
151D: 00          nop
151E: E2 51 B2    jp   po,$3A15
1521: 51          ld   d,c
1522: B2          or   d
1523: 51          ld   d,c
1524: B2          or   d
1525: 51          ld   d,c
1526: B2          or   d
1527: 51          ld   d,c
1528: 72          ld   (hl),d
1529: 51          ld   d,c
152A: 32 51 E2    ld   ($2E15),a
152D: 51          ld   d,c
152E: 00          nop
152F: 18 98       jr   $14C9
1531: 00          nop
1532: 00          nop
1533: 58          ld   e,b
1534: D8          ret  c
1535: 00          nop
1536: 20 38       jr   nz,$14CA
1538: 39          add  hl,sp
1539: 19          add  hl,de
153A: 20 B8       jr   nz,$14D6
153C: B9          cp   c
153D: 99          sbc  a,c
153E: E2 51 34    jp   po,$5215
1541: 51          ld   d,c
1542: 34          inc  (hl)
1543: 51          ld   d,c
1544: 34          inc  (hl)
1545: 51          ld   d,c
1546: 34          inc  (hl)
1547: 51          ld   d,c
1548: E4 51 32    call po,$3215
154B: 51          ld   d,c
154C: E2 51 20    jp   po,$0215
154F: 39          add  hl,sp
1550: 38 19       jr   c,$14E3
1552: 20 B9       jr   nz,$14EF
1554: B8          cp   b
1555: 99          sbc  a,c
1556: CD 19 51    call $1591
1559: C3 95 90    jp   $1859
155C: DD 7E 51    ld   a,(ix+$15)
155F: 0F          rrca
1560: 0F          rrca
1561: 0F          rrca
1562: E6 F1       and  $1F
1564: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1565: EB          ex   de,hl
1566: 7E          ld   a,(hl)
1567: 47          ld   b,a
1568: E6 DE       and  $FC
156A: 81          add  a,c
156B: 4F          ld   c,a
156C: 78          ld   a,b
156D: E6 21       and  $03
156F: DD 77 F0    ld   (ix+$1e),a
1572: 23          inc  hl
1573: DD CB 30 6E set  4,(ix+$12)
1577: C3 2C C9    jp   $8DC2
157A: DD 7E 51    ld   a,(ix+$15)
157D: 0F          rrca
157E: 0F          rrca
157F: 0F          rrca
1580: E6 F1       and  $1F
1582: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1583: DD 66 41    ld   h,(ix+$05)
1586: DD 6E 60    ld   l,(ix+$06)
1589: 19          add  hl,de
158A: DD 74 81    ld   (ix+$09),h
158D: DD 75 A0    ld   (ix+$0a),l
1590: C9          ret
1591: 3A 26 0E    ld   a,($E062)
1594: A7          and  a
1595: C8          ret  z
1596: DD 35 41    dec  (ix+$05)
1599: DD 35 81    dec  (ix+$09)
159C: C9          ret
159D: CD 8D 51    call $15C9
15A0: 47          ld   b,a
15A1: E6 F1       and  $1F
15A3: FE F1       cp   $1F
15A5: 28 13       jr   z,$15D8
15A7: DD 36 50 00 ld   (ix+$14),$00
15AB: DD 70 01    ld   (ix+$01),b
15AE: DD 70 20    ld   (ix+$02),b
15B1: 7E          ld   a,(hl)
15B2: DD 77 51    ld   (ix+$15),a
15B5: 23          inc  hl
15B6: CD 1D 51    call $15D1
15B9: CD 46 C6    call $6C64
15BC: DD 72 A1    ld   (ix+$0b),d
15BF: DD 73 C0    ld   (ix+$0c),e
15C2: DD 70 C1    ld   (ix+$0d),b
15C5: DD 71 E0    ld   (ix+$0e),c
15C8: C9          ret
15C9: DD 66 70    ld   h,(ix+$16)
15CC: DD 6E 71    ld   l,(ix+$17)
15CF: 7E          ld   a,(hl)
15D0: 23          inc  hl
15D1: DD 74 70    ld   (ix+$16),h
15D4: DD 75 71    ld   (ix+$17),l
15D7: C9          ret
15D8: 78          ld   a,b
15D9: 07          rlca
15DA: 07          rlca
15DB: 07          rlca
15DC: E6 61       and  $07
15DE: F7          rst  $30
15DF: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
15E0: 51          ld   d,c
15E1: 9F          sbc  a,a
15E2: 51          ld   d,c
15E3: 00          nop
15E4: 70          ld   (hl),b
15E5: A0          and  b
15E6: 70          ld   (hl),b
15E7: 03          inc  bc
15E8: 70          ld   (hl),b
15E9: A2          and  d
15EA: 70          ld   (hl),b
15EB: 33          inc  sp
15EC: 70          ld   (hl),b
15ED: F2 70 3E    jp   p,$F216
15F0: 01 32 58    ld   bc,$9432
15F3: 0E DD       ld   c,$DD
15F5: 36 51       ld   (hl),$15
15F7: 01 C9 CD    ld   bc,$CD8D
15FA: 8D          adc  a,l
15FB: 51          ld   d,c
15FC: DD 77 E1    ld   (ix+$0f),a
15FF: C9          ret
1600: DD 36 31 01 ld   (ix+$13),$01
1604: DD 36 51 00 ld   (ix+$15),$00
1608: E1          pop  hl
1609: C9          ret
160A: CD 2E C6    call $6CE2
160D: DD 77 01    ld   (ix+$01),a
1610: DD 77 20    ld   (ix+$02),a
1613: CD 8D 51    call $15C9
1616: DD 77 51    ld   (ix+$15),a
1619: CD 9B 51    call $15B9
161C: DD 36 50 21 ld   (ix+$14),$03
1620: C9          ret
1621: DD 36 50 40 ld   (ix+$14),$04
1625: DD 36 51 90 ld   (ix+$15),$18
1629: C9          ret
162A: DD 36 50 41 ld   (ix+$14),$05
162E: DD 36 51 04 ld   (ix+$15),$40
1632: C9          ret
1633: DD 36 50 60 ld   (ix+$14),$06
1637: CD 8D 51    call $15C9
163A: DD 77 51    ld   (ix+$15),a
163D: C9          ret
163E: CD 9B 51    call $15B9
1641: DD 36 50 00 ld   (ix+$14),$00
1645: DD 36 51 FF ld   (ix+$15),$FF
1649: DD 66 70    ld   h,(ix+$16)
164C: DD 6E 71    ld   l,(ix+$17)
164F: 2B          dec  hl
1650: DD 74 70    ld   (ix+$16),h
1653: DD 75 71    ld   (ix+$17),l
1656: C9          ret
1657: DD CB 30 66 bit  4,(ix+$12)
165B: C0          ret  nz
165C: CB 6F       bit  5,a
165E: 20 11       jr   nz,$1671
1660: 3A 20 0E    ld   a,($E002)
1663: E6 21       and  $03
1665: 47          ld   b,a
1666: DD 7E F1    ld   a,(ix+$1f)
1669: E6 21       and  $03
166B: B8          cp   b
166C: 20 21       jr   nz,$1671
166E: DD 34 10    inc  (ix+$10)
1671: DD 7E 31    ld   a,(ix+$13)
1674: 21 CB 70    ld   hl,$16AD
1677: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
1678: 08          ex   af,af'
1679: DD 7E 20    ld   a,(ix+$02)
167C: C6 61       add  a,$07
167E: 0F          rrca
167F: 0F          rrca
1680: 0F          rrca
1681: 0F          rrca
1682: E6 E1       and  $0F
1684: 47          ld   b,a
1685: 21 7A 70    ld   hl,$16B6
1688: DF          rst  $18                   ; call ADD_A_TO_HL
1689: 4E          ld   c,(hl)
168A: 08          ex   af,af'
168B: 81          add  a,c
168C: 4F          ld   c,a
168D: 78          ld   a,b
168E: 87          add  a,a
168F: 87          add  a,a
1690: 47          ld   b,a
1691: 87          add  a,a
1692: 80          add  a,b
1693: 47          ld   b,a
1694: DD 7E 10    ld   a,(ix+$10)
1697: E6 21       and  $03
1699: FE 21       cp   $03
169B: 20 20       jr   nz,$169F
169D: 3E 01       ld   a,$01
169F: 87          add  a,a
16A0: 87          add  a,a
16A1: 80          add  a,b
16A2: 21 6C 70    ld   hl,$16C6
16A5: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
16A6: DD 77 F0    ld   (ix+$1e),a
16A9: 23          inc  hl
16AA: C3 2C C9    jp   $8DC2
16AD: 00          nop
16AE: 00          nop
16AF: 10 00       djnz $16B1
16B1: 10 00       djnz $16B3
16B3: 10 02       djnz $16D5
16B5: 12          ld   (de),a
16B6: 00          nop
16B7: 00          nop
16B8: 00          nop
16B9: 00          nop
16BA: 00          nop
16BB: 80          add  a,b
16BC: 80          add  a,b
16BD: 80          add  a,b
16BE: 80          add  a,b
16BF: 80          add  a,b
16C0: 80          add  a,b
16C1: 80          add  a,b
16C2: 00          nop
16C3: 00          nop
16C4: 00          nop
16C5: 00          nop
16C6: 01 04 84    ld   bc,$4840
16C9: 85          add  a,l
16CA: 00          nop
16CB: 24          inc  h
16CC: A4          and  h
16CD: 00          nop
16CE: 00          nop
16CF: 04          inc  b
16D0: 05          dec  b
16D1: 00          nop
16D2: 00          nop
16D3: 25          dec  h
16D4: A5          and  l
16D5: 00          nop
16D6: 00          nop
16D7: 44          ld   b,h
16D8: C4 00 00    call nz,$0000
16DB: 44          ld   b,h
16DC: 45          ld   b,l
16DD: 00          nop
16DE: 00          nop
16DF: 64          ld   h,h
16E0: E4 00 00    call po,$0000
16E3: 65          ld   h,l
16E4: E5          push hl
16E5: 00          nop
16E6: 00          nop
16E7: 64          ld   h,h
16E8: C5          push bc
16E9: 00          nop
16EA: 00          nop
16EB: 14          inc  d
16EC: 94          sub  h
16ED: 00          nop
16EE: 00          nop
16EF: 15          dec  d
16F0: 95          sub  l
16F1: 00          nop
16F2: 00          nop
16F3: 15          dec  d
16F4: 34          inc  (hl)
16F5: 00          nop
16F6: 00          nop
16F7: 35          dec  (hl)
16F8: B5          or   l
16F9: 00          nop
16FA: 00          nop
16FB: 54          ld   d,h
16FC: D4 00 00    call nc,$0000
16FF: 35          dec  (hl)
1700: B4          or   h
1701: 00          nop
1702: 00          nop
1703: 14          inc  d
1704: 94          sub  h
1705: 00          nop
1706: 00          nop
1707: 15          dec  d
1708: 95          sub  l
1709: 00          nop
170A: 00          nop
170B: 15          dec  d
170C: 34          inc  (hl)
170D: 00          nop
170E: 00          nop
170F: 64          ld   h,h
1710: E4 00 00    call po,$0000
1713: 65          ld   h,l
1714: E5          push hl
1715: 00          nop
1716: 00          nop
1717: 64          ld   h,h
1718: C5          push bc
1719: 00          nop
171A: 00          nop
171B: 25          dec  h
171C: A5          and  l
171D: 00          nop
171E: 00          nop
171F: 44          ld   b,h
1720: C4 00 00    call nz,$0000
1723: 44          ld   b,h
1724: 45          ld   b,l
1725: 00          nop
1726: 01 04 85    ld   bc,$4940
1729: 84          add  a,h
172A: 00          nop
172B: 24          inc  h
172C: A4          and  h
172D: 00          nop
172E: 00          nop
172F: 04          inc  b
1730: 05          dec  b
1731: 00          nop
1732: 00          nop
1733: 47          ld   b,a
1734: C7          rst  $00
1735: 00          nop
1736: 00          nop
1737: 66          ld   h,(hl)
1738: E6 00       and  $00
173A: 00          nop
173B: 66          ld   h,(hl)
173C: 67          ld   h,a
173D: 00          nop
173E: 00          nop
173F: 27          daa
1740: A7          and  a
1741: 00          nop
1742: 00          nop
1743: 46          ld   b,(hl)
1744: C6 00       add  a,$00
1746: 00          nop
1747: 27          daa
1748: A6          and  (hl)
1749: 00          nop
174A: 00          nop
174B: 06 86       ld   b,$68
174D: B5          or   l
174E: 00          nop
174F: 07          rlca
1750: 87          add  a,a
1751: B5          or   l
1752: 00          nop
1753: 06 26       ld   b,$62
1755: B5          or   l
1756: 00          nop
1757: 55          ld   d,l
1758: D5          push de
1759: 00          nop
175A: 00          nop
175B: 74          ld   (hl),h
175C: F4 00 00    call p,$0000
175F: 55          ld   d,l
1760: 75          ld   (hl),l
1761: 00          nop
1762: 00          nop
1763: 06 86       ld   b,$68
1765: B5          or   l
1766: 00          nop
1767: 07          rlca
1768: 87          add  a,a
1769: B5          or   l
176A: 00          nop
176B: 06 26       ld   b,$62
176D: B5          or   l
176E: 00          nop
176F: 27          daa
1770: A7          and  a
1771: 00          nop
1772: 00          nop
1773: 46          ld   b,(hl)
1774: C6 00       add  a,$00
1776: 00          nop
1777: 27          daa
1778: A6          and  (hl)
1779: 00          nop
177A: 00          nop
177B: 47          ld   b,a
177C: C7          rst  $00
177D: 00          nop
177E: 00          nop
177F: 66          ld   h,(hl)
1780: E6 00       and  $00
1782: 00          nop
1783: 66          ld   h,(hl)
1784: 67          ld   h,a
1785: 00          nop
1786: CD 19 51    call $1591
1789: DD 7E 00    ld   a,(ix+$00)
178C: FE F3       cp   $3F
178E: D2 EE 71    jp   nc,$17EE
1791: 47          ld   b,a
1792: DD 35 00    dec  (ix+$00)
1795: CA DD 71    jp   z,$17DD
1798: DD 7E 31    ld   a,(ix+$13)
179B: FE A0       cp   $0A
179D: C8          ret  z
179E: 78          ld   a,b
179F: CB 47       bit  0,a
17A1: 28 B1       jr   z,$17BE
17A3: 21 7A 71    ld   hl,$17B6
17A6: CB 5F       bit  3,a
17A8: 28 21       jr   z,$17AD
17AA: 21 BA 71    ld   hl,$17BA
17AD: 4E          ld   c,(hl)
17AE: 23          inc  hl
17AF: DD 36 F0 20 ld   (ix+$1e),$02
17B3: C3 2C C9    jp   $8DC2
17B6: 80          add  a,b
17B7: 17          rla
17B8: 16 96       ld   d,$78
17BA: 00          nop
17BB: 16 17       ld   d,$71
17BD: 96          sub  (hl)
17BE: DD 7E 21    ld   a,(ix+$03)
17C1: FD 77 20    ld   (iy+$02),a
17C4: DD 7E 41    ld   a,(ix+$05)
17C7: C6 80       add  a,$08
17C9: FD 77 21    ld   (iy+$03),a
17CC: FD 36 00 97 ld   (iy+$00),$79
17D0: FD 36 01 00 ld   (iy+$01),$00
17D4: FD 36 60 00 ld   (iy+$06),$00
17D8: FD 36 A0 00 ld   (iy+$0a),$00
17DC: C9          ret
17DD: AF          xor  a
17DE: DD 77 00    ld   (ix+$00),a
17E1: DD 77 21    ld   (ix+$03),a
17E4: FD 77 20    ld   (iy+$02),a
17E7: FD 77 60    ld   (iy+$06),a
17EA: FD 77 A0    ld   (iy+$0a),a
17ED: C9          ret
17EE: DD 36 00 02 ld   (ix+$00),$20
17F2: CD 98 68    call $8698
17F5: DD 7E 31    ld   a,(ix+$13)
17F8: E6 E1       and  $0F
17FA: 21 63 90    ld   hl,$1827
17FD: DF          rst  $18                   ; call ADD_A_TO_HL
17FE: 16 41       ld   d,$05
1800: 5E          ld   e,(hl)
1801: FF          rst  $38
1802: DD 7E 31    ld   a,(ix+$13)
1805: FE A0       cp   $0A
1807: C0          ret  nz
1808: DD 36 40 00 ld   (ix+$04),$00
180C: 11 71 90    ld   de,$1817
180F: FD E5       push iy
1811: CD 88 A3    call $2B88
1814: FD E1       pop  iy
1816: C9          ret
1817: 21 06 00    ld   hl,$0060
181A: 55          ld   d,l
181B: 10 75       djnz $1874
181D: 00          nop
181E: FF          rst  $38
181F: 20 16       jr   nz,$1891
1821: 17          rla
1822: 96          sub  (hl)
1823: 20 97       jr   nz,$189E
1825: B6          or   (hl)
1826: 36 21       ld   (hl),$03
1828: 21 41 20    ld   hl,$0205
182B: 21 40 21    ld   hl,$0304
182E: 41          ld   b,c
182F: 41          ld   b,c
1830: 41          ld   b,c
1831: A0          and  b
1832: 20 20       jr   nz,$1836
1834: 20 20       jr   nz,$1838
1836: 20 3A       jr   nz,$17EA
1838: 26 0E       ld   h,$E0
183A: A7          and  a
183B: 28 21       jr   z,$1840
183D: DD 35 41    dec  (ix+$05)
1840: DD 66 21    ld   h,(ix+$03)
1843: DD 6E 40    ld   l,(ix+$04)
1846: DD 56 41    ld   d,(ix+$05)
1849: DD 5E 60    ld   e,(ix+$06)
184C: DD 74 61    ld   (ix+$07),h
184F: DD 75 80    ld   (ix+$08),l
1852: DD 72 81    ld   (ix+$09),d
1855: DD 73 A0    ld   (ix+$0a),e
1858: C9          ret
1859: DD 7E F1    ld   a,(ix+$1f)
185C: E6 E1       and  $0F
185E: 47          ld   b,a
185F: 3A 20 0E    ld   a,($E002)
1862: E6 E1       and  $0F
1864: B8          cp   b
1865: C0          ret  nz
1866: C3 11 58    jp   $9411
1869: 21 55 0E    ld   hl,$E055
186C: 34          inc  (hl)
186D: CD C9 B2    call $3A8D
1870: 3A D8 0E    ld   a,($E09C)
1873: A7          and  a
1874: 28 81       jr   z,$187F
1876: 21 03 10    ld   hl,$1021
1879: 11 03 10    ld   de,$1021
187C: CD 0F B0    call $1AE1
187F: DD 7E 41    ld   a,(ix+$05)
1882: A7          and  a
1883: CA 6B B2    jp   z,$3AA7
1886: FE 56       cp   $74
1888: DA 71 D0    jp   c,$1C17
188B: CD 0F B1    call $1BE1
188E: DD 7E 80    ld   a,(ix+$08)
1891: 21 7D 90    ld   hl,$18D7
1894: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1895: C3 9C D0    jp   $1CD8
1898: 21 55 0E    ld   hl,$E055
189B: 34          inc  (hl)
189C: CD F1 91    call $191F
189F: 3A 00 0F    ld   a,($E100)
18A2: 3C          inc  a
18A3: 20 43       jr   nz,$18CA
18A5: 06 10       ld   b,$10
18A7: DD CB 50 E4 bit  1,(ix+$14)
18AB: 28 20       jr   z,$18AF
18AD: 06 80       ld   b,$08
18AF: 3A 41 0F    ld   a,($E105)
18B2: DD 96 41    sub  (ix+$05)
18B5: FE 80       cp   $08
18B7: 30 11       jr   nc,$18CA
18B9: 3A 21 0F    ld   a,($E103)
18BC: DD 96 21    sub  (ix+$03)
18BF: C6 10       add  a,$10
18C1: FE 04       cp   $40
18C3: 30 41       jr   nc,$18CA
18C5: 3E F3       ld   a,$3F
18C7: 32 00 0F    ld   ($E100),a
18CA: 11 EF 90    ld   de,$18EF
18CD: DD 7E 50    ld   a,(ix+$14)
18D0: 21 6F 90    ld   hl,$18E7
18D3: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
18D4: C3 88 A3    jp   $2B88
18D7: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
18D8: 90          sub  b
18D9: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
18DA: 90          sub  b
18DB: 7F          ld   a,a
18DC: 90          sub  b
18DD: 7E          ld   a,(hl)
18DE: 90          sub  b
18DF: 5F          ld   e,a
18E0: 10 7E       djnz $18D8
18E2: 10 7F       djnz $18DB
18E4: 10 EF       djnz $18D5
18E6: 10 EF       djnz $18D7
18E8: 90          sub  b
18E9: DF          rst  $18
18EA: 90          sub  b
18EB: A1          and  c
18EC: 91          sub  c
18ED: 51          ld   d,c
18EE: 91          sub  c
18EF: 60          ld   h,b
18F0: 14          inc  d
18F1: 00          nop
18F2: 95          sub  l
18F3: 10 B4       djnz $194F
18F5: 02          ld   (bc),a
18F6: B5          or   l
18F7: 01 15 11    ld   bc,$1151
18FA: 34          inc  (hl)
18FB: 03          inc  bc
18FC: 35          dec  (hl)
18FD: 60          ld   h,b
18FE: 94          sub  h
18FF: 02          ld   (bc),a
1900: 95          sub  l
1901: 10 B4       djnz $195D
1903: 00          nop
1904: B5          or   l
1905: 03          inc  bc
1906: 15          dec  d
1907: 11 34 01    ld   de,$0152
190A: 35          dec  (hl)
190B: 40          ld   b,b
190C: 16 00       ld   d,$00
190E: 86          add  a,(hl)
190F: 10 87       djnz $197A
1911: 02          ld   (bc),a
1912: A6          and  (hl)
1913: 11 06 40    ld   de,$0460
1916: 96          sub  (hl)
1917: 02          ld   (bc),a
1918: 86          add  a,(hl)
1919: 10 87       djnz $1984
191B: 00          nop
191C: A6          and  (hl)
191D: 11 06 CD    ld   de,$CD60
1920: C9          ret
1921: B2          or   d
1922: 3A 20 0E    ld   a,($E002)
1925: E6 61       and  $07
1927: 20 11       jr   nz,$193A
1929: DD 46 41    ld   b,(ix+$05)
192C: 3A 41 0F    ld   a,($E105)
192F: 90          sub  b
1930: 30 41       jr   nc,$1937
1932: DD 35 41    dec  (ix+$05)
1935: 18 21       jr   $193A
1937: DD 34 41    inc  (ix+$05)
193A: 3A 00 0F    ld   a,($E100)
193D: DD 7E 41    ld   a,(ix+$05)
1940: FE 20       cp   $02
1942: 30 40       jr   nc,$1948
1944: E1          pop  hl
1945: C3 6B B2    jp   $3AA7
1948: DD CB 50 64 bit  0,(ix+$14)
194C: 28 90       jr   z,$1966
194E: DD 34 21    inc  (ix+$03)
1951: 3A 20 0E    ld   a,($E002)
1954: E6 01       and  $01
1956: C8          ret  z
1957: DD 34 21    inc  (ix+$03)
195A: DD 7E 21    ld   a,(ix+$03)
195D: C6 02       add  a,$20
195F: FE 21       cp   $03
1961: D0          ret  nc
1962: E1          pop  hl
1963: C3 6B B2    jp   $3AA7
1966: DD 35 21    dec  (ix+$03)
1969: 3A 20 0E    ld   a,($E002)
196C: E6 01       and  $01
196E: C8          ret  z
196F: DD 35 21    dec  (ix+$03)
1972: DD 7E 21    ld   a,(ix+$03)
1975: C6 10       add  a,$10
1977: FE 21       cp   $03
1979: D0          ret  nc
197A: E1          pop  hl
197B: C3 6B B2    jp   $3AA7
197E: CD C9 B2    call $3A8D
1981: DD 66 40    ld   h,(ix+$04)
1984: DD 6E 41    ld   l,(ix+$05)
1987: 11 FE FF    ld   de,$FFFE
198A: 19          add  hl,de
198B: DD 74 40    ld   (ix+$04),h
198E: DD 75 41    ld   (ix+$05),l
1991: 7C          ld   a,h
1992: A7          and  a
1993: C8          ret  z
1994: 7D          ld   a,l
1995: FE 1C       cp   $D0
1997: D0          ret  nc
1998: E1          pop  hl
1999: C3 6B B2    jp   $3AA7
199C: CD F6 91    call $197E
199F: CD 8A 91    call $19A8
19A2: 11 6D 91    ld   de,$19C7
19A5: C3 88 A3    jp   $2B88
19A8: 3A 00 0F    ld   a,($E100)
19AB: 3C          inc  a
19AC: C0          ret  nz
19AD: 3A 41 0F    ld   a,($E105)
19B0: DD 96 41    sub  (ix+$05)
19B3: FE 02       cp   $20
19B5: D0          ret  nc
19B6: 3A 21 0F    ld   a,($E103)
19B9: DD 96 21    sub  (ix+$03)
19BC: C6 C0       add  a,$0C
19BE: FE 83       cp   $29
19C0: D0          ret  nc
19C1: 3E F3       ld   a,$3F
19C3: 32 00 0F    ld   ($E100),a
19C6: C9          ret
19C7: 40          ld   b,b
19C8: 14          inc  d
19C9: 00          nop
19CA: 9E          sbc  a,(hl)
19CB: 10 9F       djnz $19C6
19CD: 01 1E 11    ld   bc,$11F0
19D0: 1F          rra
19D1: CD F6 91    call $197E
19D4: CD 8A 91    call $19A8
19D7: 11 0E 91    ld   de,$19E0
19DA: CD 88 A3    call $2B88
19DD: C3 88 A3    jp   $2B88
19E0: 21 14 00    ld   hl,$0050
19E3: 5F          ld   e,a
19E4: 01 CF 20    ld   bc,$02ED
19E7: 4F          ld   c,a
19E8: 21 94 10    ld   hl,$1058
19EB: 5F          ld   e,a
19EC: 11 CF 30    ld   de,$12ED
19EF: 4F          ld   c,a
19F0: CD C9 B2    call $3A8D
19F3: CD 55 B0    call $1A55
19F6: CD 22 B0    call $1A22
19F9: 11 85 B0    ld   de,$1A49
19FC: CD 88 A3    call $2B88
19FF: DD 46 21    ld   b,(ix+$03)
1A02: DD 4E 41    ld   c,(ix+$05)
1A05: C5          push bc
1A06: DD 7E 70    ld   a,(ix+$16)
1A09: 67          ld   h,a
1A0A: 80          add  a,b
1A0B: C6 FE       add  a,$FE
1A0D: DD 77 21    ld   (ix+$03),a
1A10: 7C          ld   a,h
1A11: 81          add  a,c
1A12: C6 C0       add  a,$0C
1A14: DD 77 41    ld   (ix+$05),a
1A17: D4 88 A3    call nc,$2B88
1A1A: C1          pop  bc
1A1B: DD 70 21    ld   (ix+$03),b
1A1E: DD 71 41    ld   (ix+$05),c
1A21: C9          ret
1A22: 3A 20 0E    ld   a,($E002)
1A25: E6 21       and  $03
1A27: C0          ret  nz
1A28: DD 7E 50    ld   a,(ix+$14)
1A2B: E6 21       and  $03
1A2D: C8          ret  z
1A2E: 3D          dec  a
1A2F: 28 20       jr   z,$1A33
1A31: 18 C1       jr   $1A40
1A33: DD 35 70    dec  (ix+$16)
1A36: DD 7E 70    ld   a,(ix+$16)
1A39: FE 5E       cp   $F4
1A3B: D0          ret  nc
1A3C: DD 34 50    inc  (ix+$14)
1A3F: C9          ret
1A40: DD 34 70    inc  (ix+$16)
1A43: C0          ret  nz
1A44: DD 36 50 00 ld   (ix+$14),$00
1A48: C9          ret
1A49: 20 18       jr   nz,$19DB
1A4B: 01 55 00    ld   bc,$0055
1A4E: D5          push de
1A4F: 20 18       jr   nz,$19E1
1A51: 11 54 10    ld   de,$1054
1A54: D4 DD 7E    call nc,$F6DD
1A57: 50          ld   d,b
1A58: A7          and  a
1A59: C0          ret  nz
1A5A: DD 7E 40    ld   a,(ix+$04)
1A5D: A7          and  a
1A5E: C0          ret  nz
1A5F: DD 7E 41    ld   a,(ix+$05)
1A62: FE 02       cp   $20
1A64: D8          ret  c
1A65: 3A 7E 0E    ld   a,($E0F6)
1A68: A7          and  a
1A69: C0          ret  nz
1A6A: DD 7E 21    ld   a,(ix+$03)
1A6D: C6 C1       add  a,$0D
1A6F: 67          ld   h,a
1A70: DD 7E 41    ld   a,(ix+$05)
1A73: C6 C1       add  a,$0D
1A75: 6F          ld   l,a
1A76: DD E5       push ix
1A78: DD 21 00 6E ld   ix,$E600
1A7C: 3A 5E 0E    ld   a,($E0F4)
1A7F: 47          ld   b,a
1A80: 11 02 00    ld   de,$0020
1A83: DD 7E 00    ld   a,(ix+$00)
1A86: A7          and  a
1A87: 28 61       jr   z,$1A90
1A89: DD 19       add  ix,de
1A8B: 10 7E       djnz $1A83
1A8D: DD E1       pop  ix
1A8F: C9          ret
1A90: DD 36 00 FF ld   (ix+$00),$FF
1A94: DD 36 01 0C ld   (ix+$01),$C0
1A98: DD 36 20 0C ld   (ix+$02),$C0
1A9C: DD 74 21    ld   (ix+$03),h
1A9F: DD 74 61    ld   (ix+$07),h
1AA2: DD 75 41    ld   (ix+$05),l
1AA5: DD 75 81    ld   (ix+$09),l
1AA8: DD 36 31 81 ld   (ix+$13),$09
1AAC: DD 36 50 00 ld   (ix+$14),$00
1AB0: DD 36 51 C0 ld   (ix+$15),$0C
1AB4: DD 36 90 90 ld   (ix+$18),$18
1AB8: DD 71 71    ld   (ix+$17),c
1ABB: DD 70 F1    ld   (ix+$1f),b
1ABE: DD 36 A1 00 ld   (ix+$0b),$00
1AC2: DD 36 C0 00 ld   (ix+$0c),$00
1AC6: DD 36 C1 FF ld   (ix+$0d),$FF
1ACA: DD 36 E0 00 ld   (ix+$0e),$00
1ACE: DD 36 E1 00 ld   (ix+$0f),$00
1AD2: CD 4C 59    call $95C4
1AD5: 3A 5F 0E    ld   a,($E0F5)
1AD8: 32 7E 0E    ld   ($E0F6),a
1ADB: DD E1       pop  ix
1ADD: DD 34 50    inc  (ix+$14)
1AE0: C9          ret
1AE1: 3A D9 0E    ld   a,($E09D)
1AE4: DD 96 21    sub  (ix+$03)
1AE7: 84          add  a,h
1AE8: BD          cp   l
1AE9: D0          ret  nc
1AEA: 3A F8 0E    ld   a,($E09E)
1AED: DD 96 41    sub  (ix+$05)
1AF0: 82          add  a,d
1AF1: BB          cp   e
1AF2: D0          ret  nc
1AF3: DD 36 00 F3 ld   (ix+$00),$3F
1AF7: C9          ret
1AF8: CD C9 B2    call $3A8D
1AFB: CD 78 B1    call $1B96
1AFE: CD 84 B1    call $1B48
1B01: DD 7E 41    ld   a,(ix+$05)
1B04: FE 0E       cp   $E0
1B06: D0          ret  nc
1B07: F5          push af
1B08: DD 46 51    ld   b,(ix+$15)
1B0B: 80          add  a,b
1B0C: C6 61       add  a,$07
1B0E: DD 77 41    ld   (ix+$05),a
1B11: 78          ld   a,b
1B12: FE 81       cp   $09
1B14: 30 A1       jr   nc,$1B21
1B16: 11 C2 B1    ld   de,$1B2C
1B19: CD 88 A3    call $2B88
1B1C: F1          pop  af
1B1D: DD 77 41    ld   (ix+$05),a
1B20: C9          ret
1B21: 11 F2 B1    ld   de,$1B3E
1B24: CD 88 A3    call $2B88
1B27: F1          pop  af
1B28: DD 77 41    ld   (ix+$05),a
1B2B: C9          ret
1B2C: 80          add  a,b
1B2D: 14          inc  d
1B2E: 00          nop
1B2F: EB          ex   de,hl
1B30: 10 EB       djnz $1AE1
1B32: 02          ld   (bc),a
1B33: EB          ex   de,hl
1B34: 12          ld   (de),a
1B35: EB          ex   de,hl
1B36: 01 EB 11    ld   bc,$11AF
1B39: EB          ex   de,hl
1B3A: 03          inc  bc
1B3B: EB          ex   de,hl
1B3C: 13          inc  de
1B3D: EB          ex   de,hl
1B3E: 40          ld   b,b
1B3F: 14          inc  d
1B40: 00          nop
1B41: EB          ex   de,hl
1B42: 10 EB       djnz $1AF3
1B44: 02          ld   (bc),a
1B45: EB          ex   de,hl
1B46: 12          ld   (de),a
1B47: EB          ex   de,hl
1B48: 3A 58 0E    ld   a,($E094)
1B4B: A7          and  a
1B4C: 28 81       jr   z,$1B57
1B4E: DD 36 50 01 ld   (ix+$14),$01
1B52: 3E 00       ld   a,$00
1B54: 32 58 0E    ld   ($E094),a
1B57: DD 7E 50    ld   a,(ix+$14)
1B5A: F7          rst  $30
1B5B: 27          daa
1B5C: B1          or   c
1B5D: 46          ld   b,(hl)
1B5E: B1          or   c
1B5F: 96          sub  (hl)
1B60: B1          or   c
1B61: 69          ld   l,c
1B62: B1          or   c
1B63: C9          ret
1B64: DD 7E 51    ld   a,(ix+$15)
1B67: FE 91       cp   $19
1B69: 30 40       jr   nc,$1B6F
1B6B: DD 34 51    inc  (ix+$15)
1B6E: C9          ret
1B6F: DD 36 70 F0 ld   (ix+$16),$1E
1B73: DD 36 50 20 ld   (ix+$14),$02
1B77: C9          ret
1B78: DD 7E 70    ld   a,(ix+$16)
1B7B: A7          and  a
1B7C: 28 40       jr   z,$1B82
1B7E: DD 35 70    dec  (ix+$16)
1B81: C9          ret
1B82: DD 36 50 21 ld   (ix+$14),$03
1B86: C9          ret
1B87: DD 7E 51    ld   a,(ix+$15)
1B8A: A7          and  a
1B8B: 28 40       jr   z,$1B91
1B8D: DD 35 51    dec  (ix+$15)
1B90: C9          ret
1B91: DD 36 50 00 ld   (ix+$14),$00
1B95: C9          ret
1B96: 11 F9 B1    ld   de,$1B9F
1B99: CD 88 A3    call $2B88
1B9C: C3 88 A3    jp   $2B88
1B9F: 40          ld   b,b
1BA0: 14          inc  d
1BA1: 00          nop
1BA2: 7A          ld   a,d
1BA3: 01 EA 20    ld   bc,$02AE
1BA6: 6A          ld   l,d
1BA7: 30 6B       jr   nc,$1B50
1BA9: 40          ld   b,b
1BAA: 94          sub  h
1BAB: 12          ld   (de),a
1BAC: 7A          ld   a,d
1BAD: 13          inc  de
1BAE: EA 32 6A    jp   pe,$A632
1BB1: 22 6B 21    ld   ($03A7),hl
1BB4: 55          ld   d,l
1BB5: 0E 34       ld   c,$52
1BB7: CD C9 B2    call $3A8D
1BBA: 3A D8 0E    ld   a,($E09C)
1BBD: A7          and  a
1BBE: 28 81       jr   z,$1BC9
1BC0: 21 03 10    ld   hl,$1021
1BC3: 11 03 10    ld   de,$1021
1BC6: CD 0F B0    call $1AE1
1BC9: DD 7E 41    ld   a,(ix+$05)
1BCC: A7          and  a
1BCD: CA 6B B2    jp   z,$3AA7
1BD0: FE 56       cp   $74
1BD2: 38 25       jr   c,$1C17
1BD4: CD 0F B1    call $1BE1
1BD7: DD 7E 80    ld   a,(ix+$08)
1BDA: 21 04 D0    ld   hl,$1C40
1BDD: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1BDE: C3 9C D0    jp   $1CD8
1BE1: DD 35 51    dec  (ix+$15)
1BE4: 28 44       jr   z,$1C2A
1BE6: DD CB 50 64 bit  0,(ix+$14)
1BEA: C8          ret  z
1BEB: DD 7E 51    ld   a,(ix+$15)
1BEE: 47          ld   b,a
1BEF: E6 E1       and  $0F
1BF1: C0          ret  nz
1BF2: CD 2E C6    call $6CE2
1BF5: 47          ld   b,a
1BF6: FE D8       cp   $9C
1BF8: 38 D0       jr   c,$1C16
1BFA: FE 4E       cp   $E4
1BFC: 30 90       jr   nc,$1C16
1BFE: DD 70 20    ld   (ix+$02),b
1C01: C6 80       add  a,$08
1C03: 0F          rrca
1C04: 0F          rrca
1C05: 0F          rrca
1C06: 0F          rrca
1C07: E6 61       and  $07
1C09: DD 77 80    ld   (ix+$08),a
1C0C: 21 B0 D0    ld   hl,$1C1A
1C0F: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1C10: 63          ld   h,e
1C11: 6A          ld   l,d
1C12: CD DF 39    call $93FD
1C15: C9          ret
1C16: E1          pop  hl
1C17: C3 14 D0    jp   $1C50
1C1A: 3E 5E       ld   a,$F4
1C1C: 3E 5E       ld   a,$F4
1C1E: 5E          ld   e,(hl)
1C1F: 5E          ld   e,(hl)
1C20: DE 5E       sbc  a,$F4
1C22: 01 5E 40    ld   bc,$04F4
1C25: 5E          ld   e,(hl)
1C26: C0          ret  nz
1C27: 5E          ld   e,(hl)
1C28: E0          ret  po
1C29: 5E          ld   e,(hl)
1C2A: DD 7E 50    ld   a,(ix+$14)
1C2D: 3C          inc  a
1C2E: E6 01       and  $01
1C30: DD 77 50    ld   (ix+$14),a
1C33: A7          and  a
1C34: 28 41       jr   z,$1C3B
1C36: DD 36 51 08 ld   (ix+$15),$80
1C3A: C9          ret
1C3B: DD 36 51 D2 ld   (ix+$15),$3C
1C3F: C9          ret
1C40: 2B          dec  hl
1C41: 90          sub  b
1C42: 2B          dec  hl
1C43: 90          sub  b
1C44: 2A 90 0B    ld   hl,($A118)
1C47: 90          sub  b
1C48: 0A          ld   a,(bc)
1C49: 10 0B       djnz $1BEC
1C4B: 10 2A       djnz $1BEF
1C4D: 10 2B       djnz $1BF2
1C4F: 10 DD       djnz $1C2E
1C51: E5          push hl
1C52: DD 66 21    ld   h,(ix+$03)
1C55: DD 7E 41    ld   a,(ix+$05)
1C58: C6 61       add  a,$07
1C5A: 6F          ld   l,a
1C5B: DD 4E F1    ld   c,(ix+$1f)
1C5E: DD 21 00 6E ld   ix,$E600
1C62: 11 02 00    ld   de,$0020
1C65: 06 80       ld   b,$08
1C67: DD 7E 00    ld   a,(ix+$00)
1C6A: A7          and  a
1C6B: 28 61       jr   z,$1C74
1C6D: DD 19       add  ix,de
1C6F: 10 7E       djnz $1C67
1C71: DD E1       pop  ix
1C73: C9          ret
1C74: DD 36 00 FF ld   (ix+$00),$FF
1C78: DD 36 01 04 ld   (ix+$01),$40
1C7C: DD 36 20 04 ld   (ix+$02),$40
1C80: DD 74 21    ld   (ix+$03),h
1C83: DD 74 61    ld   (ix+$07),h
1C86: DD 75 41    ld   (ix+$05),l
1C89: DD 75 81    ld   (ix+$09),l
1C8C: DD 36 31 20 ld   (ix+$13),$02
1C90: DD 36 50 00 ld   (ix+$14),$00
1C94: DD 36 90 00 ld   (ix+$18),$00
1C98: DD 36 51 10 ld   (ix+$15),$10
1C9C: DD 70 F1    ld   (ix+$1f),b
1C9F: 79          ld   a,c
1CA0: E6 21       and  $03
1CA2: 21 0D D0    ld   hl,$1CC1
1CA5: 87          add  a,a
1CA6: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1CA7: DD 72 A1    ld   (ix+$0b),d
1CAA: DD 73 C0    ld   (ix+$0c),e
1CAD: 4E          ld   c,(hl)
1CAE: 23          inc  hl
1CAF: 46          ld   b,(hl)
1CB0: DD 70 C1    ld   (ix+$0d),b
1CB3: DD 71 E0    ld   (ix+$0e),c
1CB6: DD E1       pop  ix
1CB8: DD 36 00 00 ld   (ix+$00),$00
1CBC: FD 36 20 00 ld   (iy+$02),$00
1CC0: C9          ret
1CC1: 0A          ld   a,(bc)
1CC2: FF          rst  $38
1CC3: 9A          sbc  a,d
1CC4: 00          nop
1CC5: 06 00       ld   b,$00
1CC7: 9A          sbc  a,d
1CC8: 00          nop
1CC9: 1C          inc  e
1CCA: FF          rst  $38
1CCB: 8C          adc  a,h
1CCC: 00          nop
1CCD: 12          ld   (de),a
1CCE: 00          nop
1CCF: 8C          adc  a,h
1CD0: 00          nop
1CD1: 0F          rrca
1CD2: 0F          rrca
1CD3: 0F          rrca
1CD4: 0F          rrca
1CD5: E6 E1       and  $0F
1CD7: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1CD8: FD 73 00    ld   (iy+$00),e
1CDB: FD 72 01    ld   (iy+$01),d
1CDE: DD 7E 21    ld   a,(ix+$03)
1CE1: FD 77 20    ld   (iy+$02),a
1CE4: DD 7E 41    ld   a,(ix+$05)
1CE7: FD 77 21    ld   (iy+$03),a
1CEA: C9          ret
1CEB: DD 36 00 F3 ld   (ix+$00),$3F
1CEF: DD 36 40 00 ld   (ix+$04),$00
1CF3: C9          ret
1CF4: 21 55 0E    ld   hl,$E055
1CF7: 34          inc  (hl)
1CF8: 3A DA 0E    ld   a,($E0BC)
1CFB: A7          and  a
1CFC: 28 CF       jr   z,$1CEB
1CFE: CD 10 D1    call $1D10
1D01: 21 0B F0    ld   hl,$1EA1
1D04: 3A 20 0E    ld   a,($E002)
1D07: 0F          rrca
1D08: 0F          rrca
1D09: 0F          rrca
1D0A: E6 21       and  $03
1D0C: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1D0D: C3 88 A3    jp   $2B88
1D10: 3A 26 0E    ld   a,($E062)
1D13: A7          and  a
1D14: 28 21       jr   z,$1D19
1D16: DD 35 41    dec  (ix+$05)
1D19: DD 7E 50    ld   a,(ix+$14)
1D1C: E6 01       and  $01
1D1E: 28 93       jr   z,$1D59
1D20: DD 66 21    ld   h,(ix+$03)
1D23: DD 6E 40    ld   l,(ix+$04)
1D26: DD 56 A1    ld   d,(ix+$0b)
1D29: DD 5E C0    ld   e,(ix+$0c)
1D2C: 19          add  hl,de
1D2D: DD 74 21    ld   (ix+$03),h
1D30: DD 75 40    ld   (ix+$04),l
1D33: 7C          ld   a,h
1D34: FE 9E       cp   $F8
1D36: 38 40       jr   c,$1D3C
1D38: E1          pop  hl
1D39: C3 6B B2    jp   $3AA7
1D3C: DD 66 41    ld   h,(ix+$05)
1D3F: DD 6E 60    ld   l,(ix+$06)
1D42: DD 56 C1    ld   d,(ix+$0d)
1D45: DD 5E E0    ld   e,(ix+$0e)
1D48: 19          add  hl,de
1D49: DD 74 41    ld   (ix+$05),h
1D4C: DD 75 60    ld   (ix+$06),l
1D4F: DD 7E 41    ld   a,(ix+$05)
1D52: FE 9E       cp   $F8
1D54: D8          ret  c
1D55: E1          pop  hl
1D56: C3 6B B2    jp   $3AA7
1D59: DD 7E 41    ld   a,(ix+$05)
1D5C: FE 0A       cp   $A0
1D5E: D0          ret  nc
1D5F: DD 34 50    inc  (ix+$14)
1D62: C9          ret
1D63: CD 10 D1    call $1D10
1D66: CD 96 D1    call $1D78
1D69: 21 BB F0    ld   hl,$1EBB
1D6C: 3A 20 0E    ld   a,($E002)
1D6F: 0F          rrca
1D70: 0F          rrca
1D71: 0F          rrca
1D72: E6 21       and  $03
1D74: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1D75: C3 88 A3    jp   $2B88


;
; IX = pointer to ???
; Looks like player bullet to enemy collision detection here.

1D78: DD 66 21    ld   h,(ix+$03)
1D7B: DD 6E 41    ld   l,(ix+$05)
1D7E: DD E5       push ix
1D80: DD 21 00 2E ld   ix,$E200
1D84: 11 02 00    ld   de,$0020
1D87: 06 60       ld   b,$06
1D89: DD 7E 00    ld   a,(ix+$00)
1D8C: 3C          inc  a
1D8D: 20 03       jr   nz,$1DB0
1D8F: 7D          ld   a,l
1D90: DD 96 41    sub  (ix+$05)
1D93: FE 10       cp   $10
1D95: 30 91       jr   nc,$1DB0
1D97: DD 7E 21    ld   a,(ix+$03)
1D9A: 94          sub  h
1D9B: C6 80       add  a,$08
1D9D: FE 11       cp   $11
1D9F: 30 E1       jr   nc,$1DB0
1DA1: DD 36 00 F3 ld   (ix+$00),$3F
1DA5: DD E1       pop  ix
1DA7: DD 36 00 F3 ld   (ix+$00),$3F
1DAB: DD 36 40 00 ld   (ix+$04),$00
1DAF: C9          ret

1DB0: DD 19       add  ix,de
1DB2: 10 5D       djnz $1D89
1DB4: DD E1       pop  ix
1DB6: C9          ret

1DB7: DD 7E 70    ld   a,(ix+$16)
1DBA: A7          and  a
1DBB: 20 52       jr   nz,$1DF1
1DBD: 21 55 0E    ld   hl,$E055
1DC0: 34          inc  (hl)
1DC1: 3A D8 0E    ld   a,($E09C)
1DC4: A7          and  a
1DC5: 28 81       jr   z,$1DD0
1DC7: 21 03 10    ld   hl,$1021
1DCA: 11 83 10    ld   de,$1029
1DCD: CD 0F B0    call $1AE1
1DD0: CD B7 F0    call $1E7B
1DD3: DD 7E 80    ld   a,(ix+$08)
1DD6: 21 92 F1    ld   hl,$1F38
1DD9: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1DDA: CD 9C D0    call $1CD8
1DDD: DD 7E 70    ld   a,(ix+$16)
1DE0: A7          and  a
1DE1: C0          ret  nz
1DE2: 11 40 00    ld   de,$0004
1DE5: FD 19       add  iy,de
1DE7: DD 7E 50    ld   a,(ix+$14)
1DEA: 21 D0 F1    ld   hl,$1F1C
1DED: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1DEE: C3 88 A3    jp   $2B88
1DF1: CD C9 B2    call $3A8D
1DF4: DD 7E 41    ld   a,(ix+$05)
1DF7: A7          and  a
1DF8: CA 6B B2    jp   z,$3AA7
1DFB: DD 7E 80    ld   a,(ix+$08)
1DFE: 21 92 F1    ld   hl,$1F38
1E01: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1E02: C3 9C D0    jp   $1CD8
1E05: DD E5       push ix
1E07: DD 66 21    ld   h,(ix+$03)
1E0A: DD 7E 41    ld   a,(ix+$05)
1E0D: C6 61       add  a,$07
1E0F: 6F          ld   l,a
1E10: DD 4E F1    ld   c,(ix+$1f)
1E13: DD 21 00 6E ld   ix,$E600
1E17: 11 02 00    ld   de,$0020
1E1A: 06 80       ld   b,$08
1E1C: DD 7E 00    ld   a,(ix+$00)
1E1F: A7          and  a
1E20: 28 61       jr   z,$1E29
1E22: DD 19       add  ix,de
1E24: 10 7E       djnz $1E1C
1E26: DD E1       pop  ix
1E28: C9          ret
1E29: DD 36 00 FF ld   (ix+$00),$FF
1E2D: DD 36 01 04 ld   (ix+$01),$40
1E31: DD 36 20 04 ld   (ix+$02),$40
1E35: DD 74 21    ld   (ix+$03),h
1E38: DD 74 61    ld   (ix+$07),h
1E3B: DD 75 41    ld   (ix+$05),l
1E3E: DD 75 81    ld   (ix+$09),l
1E41: DD 36 31 61 ld   (ix+$13),$07
1E45: DD 36 50 00 ld   (ix+$14),$00
1E49: DD 36 90 00 ld   (ix+$18),$00
1E4D: DD 36 51 10 ld   (ix+$15),$10
1E51: DD 70 F1    ld   (ix+$1f),b
1E54: 79          ld   a,c
1E55: E6 21       and  $03
1E57: 21 0D D0    ld   hl,$1CC1
1E5A: 87          add  a,a
1E5B: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1E5C: DD 72 A1    ld   (ix+$0b),d
1E5F: DD 73 C0    ld   (ix+$0c),e
1E62: 4E          ld   c,(hl)
1E63: 23          inc  hl
1E64: 46          ld   b,(hl)
1E65: DD 70 C1    ld   (ix+$0d),b
1E68: DD 71 E0    ld   (ix+$0e),c
1E6B: DD E1       pop  ix
1E6D: DD 36 70 01 ld   (ix+$16),$01
1E71: FD 36 60 00 ld   (iy+$06),$00
1E75: FD 36 A0 00 ld   (iy+$0a),$00
1E79: E1          pop  hl
1E7A: C9          ret
1E7B: CD C9 B2    call $3A8D
1E7E: DD 7E 41    ld   a,(ix+$05)
1E81: FE 96       cp   $78
1E83: DC 41 F0    call c,$1E05
1E86: DD 7E 50    ld   a,(ix+$14)
1E89: A7          and  a
1E8A: 28 34       jr   z,$1EDE
1E8C: DD 35 51    dec  (ix+$15)
1E8F: C0          ret  nz
1E90: DD 7E 50    ld   a,(ix+$14)
1E93: DD 34 50    inc  (ix+$14)
1E96: F7          rst  $30
1E97: EE F0       xor  $1E
1E99: A1          and  c
1E9A: F1          pop  af
1E9B: 71          ld   (hl),c
1E9C: F1          pop  af
1E9D: 71          ld   (hl),c
1E9E: F1          pop  af
1E9F: 5D          ld   e,l
1EA0: F0          ret  p
1EA1: 8B          adc  a,e
1EA2: F0          ret  p
1EA3: EB          ex   de,hl
1EA4: F0          ret  p
1EA5: 5B          ld   e,e
1EA6: F0          ret  p
1EA7: EB          ex   de,hl
1EA8: F0          ret  p
1EA9: 20 00       jr   nz,$1EAB
1EAB: 01 0E 00    ld   bc,$00E0
1EAE: 8E          adc  a,(hl)
1EAF: 20 00       jr   nz,$1EB1
1EB1: 01 0F 00    ld   bc,$00E1
1EB4: 8F          adc  a,a
1EB5: 20 00       jr   nz,$1EB7
1EB7: 01 2E 00    ld   bc,$00E2
1EBA: AE          xor  (hl)
1EBB: 2D          dec  l
1EBC: F0          ret  p
1EBD: 8D          adc  a,l
1EBE: F0          ret  p
1EBF: ED          db   $ed
1EC0: F0          ret  p
1EC1: 8D          adc  a,l
1EC2: F0          ret  p
1EC3: 20 00       jr   nz,$1EC5
1EC5: 01 1E 00    ld   bc,$00F0
1EC8: 9E          sbc  a,(hl)
1EC9: 20 00       jr   nz,$1ECB
1ECB: 01 1F 00    ld   bc,$00F1
1ECE: 9F          sbc  a,a
1ECF: 20 00       jr   nz,$1ED1
1ED1: 01 3E 00    ld   bc,$00F2
1ED4: BE          cp   (hl)
1ED5: DD 36 50 00 ld   (ix+$14),$00
1ED9: DD 36 51 10 ld   (ix+$15),$10
1EDD: C9          ret
1EDE: 3A 20 0E    ld   a,($E002)
1EE1: E6 F3       and  $3F
1EE3: 47          ld   b,a
1EE4: DD 7E F1    ld   a,(ix+$1f)
1EE7: E6 61       and  $07
1EE9: 87          add  a,a
1EEA: 87          add  a,a
1EEB: 87          add  a,a
1EEC: B8          cp   b
1EED: C0          ret  nz
1EEE: DD 34 50    inc  (ix+$14)
1EF1: DD 36 51 80 ld   (ix+$15),$08
1EF5: CD 2E C6    call $6CE2
1EF8: CB 7F       bit  7,a
1EFA: 28 9D       jr   z,$1ED5
1EFC: DD 77 20    ld   (ix+$02),a
1EFF: C6 80       add  a,$08
1F01: 0F          rrca
1F02: 0F          rrca
1F03: 0F          rrca
1F04: 0F          rrca
1F05: E6 61       and  $07
1F07: DD 77 80    ld   (ix+$08),a
1F0A: C9          ret
1F0B: DD 36 51 80 ld   (ix+$15),$08
1F0F: DD E5       push ix
1F11: CD 84 F1    call $1F48
1F14: DD E1       pop  ix
1F16: C9          ret
1F17: DD 36 51 10 ld   (ix+$15),$10
1F1B: C9          ret
1F1C: 62          ld   h,d
1F1D: F1          pop  af
1F1E: C2 F1 32    jp   nz,$321F
1F21: F1          pop  af
1F22: C2 F1 62    jp   nz,$261F
1F25: F1          pop  af
1F26: 20 02       jr   nz,$1F48
1F28: 01 1C 00    ld   bc,$00D0
1F2B: 9C          sbc  a,h
1F2C: 20 02       jr   nz,$1F4E
1F2E: 01 1D 00    ld   bc,$00D1
1F31: 9D          sbc  a,l
1F32: 20 02       jr   nz,$1F54
1F34: 01 3C 00    ld   bc,$00D2
1F37: BC          cp   h
1F38: FC 90 FC    call m,$DE18
1F3B: 90          sub  b
1F3C: DD          db   $dd
1F3D: 90          sub  b
1F3E: DC 90 BD    call c,$DB18
1F41: 10 DC       djnz $1F1F
1F43: 10 DD       djnz $1F22
1F45: 10 FC       djnz $1F25
1F47: 10 DD       djnz $1F26
1F49: 4E          ld   c,(hl)
1F4A: 80          add  a,b
1F4B: DD 66 21    ld   h,(ix+$03)
1F4E: DD 6E 41    ld   l,(ix+$05)
1F51: 11 50 FE    ld   de,$FE14
1F54: DD 21 0E 4F ld   ix,$E5E0
1F58: DD 7E 00    ld   a,(ix+$00)
1F5B: A7          and  a
1F5C: 28 B1       jr   z,$1F79
1F5E: 11 90 FE    ld   de,$FE18
1F61: DD 21 0C 4F ld   ix,$E5C0
1F65: DD 7E 00    ld   a,(ix+$00)
1F68: A7          and  a
1F69: 28 E0       jr   z,$1F79
1F6B: 11 D0 FE    ld   de,$FE1C
1F6E: DD 21 0A 4F ld   ix,$E5A0
1F72: DD 7E 00    ld   a,(ix+$00)
1F75: A7          and  a
1F76: 28 01       jr   z,$1F79
1F78: C9          ret
1F79: DD 36 00 FF ld   (ix+$00),$FF
1F7D: DD 36 31 40 ld   (ix+$13),$04
1F81: DD 36 50 00 ld   (ix+$14),$00
1F85: DD 36 51 40 ld   (ix+$15),$04
1F89: DD 36 B0 01 ld   (ix+$1a),$01
1F8D: DD 72 B1    ld   (ix+$1b),d
1F90: DD 73 D0    ld   (ix+$1c),e
1F93: DD 71 20    ld   (ix+$02),c
1F96: DD 74 21    ld   (ix+$03),h
1F99: DD 75 41    ld   (ix+$05),l
1F9C: DD 7E 20    ld   a,(ix+$02)
1F9F: 21 5B F1    ld   hl,$1FB5
1FA2: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1FA3: DD 7E 21    ld   a,(ix+$03)
1FA6: 83          add  a,e
1FA7: DD 77 21    ld   (ix+$03),a
1FAA: DD 7E 41    ld   a,(ix+$05)
1FAD: 82          add  a,d
1FAE: DD 77 41    ld   (ix+$05),a
1FB1: CD 24 68    call $8642
1FB4: C9          ret
1FB5: BE          cp   (hl)
1FB6: 81          add  a,c
1FB7: BE          cp   (hl)
1FB8: 80          add  a,b
1FB9: BE          cp   (hl)
1FBA: 61          ld   h,c
1FBB: DE 60       sbc  a,$06
1FBD: 40          ld   b,b
1FBE: 60          ld   h,b
1FBF: 60          ld   h,b
1FC0: 61          ld   h,c
1FC1: 60          ld   h,b
1FC2: 80          add  a,b
1FC3: 60          ld   h,b
1FC4: 81          add  a,c
1FC5: CD 01 02    call $2001
1FC8: 0E 80       ld   c,$08
1FCA: DD 7E 20    ld   a,(ix+$02)
1FCD: FE 40       cp   $04
1FCF: 38 20       jr   c,$1FD3
1FD1: 0E 00       ld   c,$00
1FD3: FD 71 01    ld   (iy+$01),c
1FD6: DD 7E 50    ld   a,(ix+$14)
1FD9: FE 20       cp   $02
1FDB: 28 30       jr   z,$1FEF
1FDD: C6 3D       add  a,$D3
1FDF: FD 77 00    ld   (iy+$00),a
1FE2: DD 7E 21    ld   a,(ix+$03)
1FE5: FD 77 20    ld   (iy+$02),a
1FE8: DD 7E 41    ld   a,(ix+$05)
1FEB: FD 77 21    ld   (iy+$03),a
1FEE: C9          ret
1FEF: 16 00       ld   d,$00
1FF1: 1E 1B       ld   e,$B1
1FF3: DD 7E 51    ld   a,(ix+$15)
1FF6: D6 02       sub  $20
1FF8: FE 04       cp   $40
1FFA: D2 9C D0    jp   nc,$1CD8
1FFD: 1D          dec  e
1FFE: C3 9C D0    jp   $1CD8
2001: DD 35 51    dec  (ix+$15)
2004: CA B3 02    jp   z,$203B
2007: DD 7E 50    ld   a,(ix+$14)
200A: FE 20       cp   $02
200C: DA C9 B2    jp   c,$3A8D
200F: DD 7E 51    ld   a,(ix+$15)
2012: 0F          rrca
2013: 0F          rrca
2014: 0F          rrca
2015: 0F          rrca
2016: E6 61       and  $07
2018: 87          add  a,a
2019: 21 A3 02    ld   hl,$202B
201C: DF          rst  $18                   ; call ADD_A_TO_HL
201D: 4E          ld   c,(hl)
201E: 23          inc  hl
201F: 46          ld   b,(hl)
2020: CD 5C E9    call $8FD4
2023: 09          add  hl,bc
2024: DD 74 41    ld   (ix+$05),h
2027: DD 75 60    ld   (ix+$06),l
202A: C9          ret
202B: 08          ex   af,af'
202C: FE 0E       cp   $E0
202E: FE 04       cp   $40
2030: FF          rst  $38
2031: 0C          inc  c
2032: FF          rst  $38
2033: 04          inc  b
2034: 00          nop
2035: 0C          inc  c
2036: 00          nop
2037: 02          ld   (bc),a
2038: 01 08 01    ld   bc,$0180
203B: DD 7E 50    ld   a,(ix+$14)
203E: DD 34 50    inc  (ix+$14)
2041: F7          rst  $30
2042: B5          or   l
2043: 02          ld   (bc),a
2044: 06 02       ld   b,$20
2046: 84          add  a,h
2047: 02          ld   (bc),a
2048: E1          pop  hl
2049: DD 36 00 00 ld   (ix+$00),$00
204D: DD 66 21    ld   h,(ix+$03)
2050: DD 6E 41    ld   l,(ix+$05)
2053: FD 36 20 00 ld   (iy+$02),$00
2057: CD C1 38    call $920D
205A: C9          ret
205B: DD 36 51 40 ld   (ix+$15),$04
205F: C9          ret
2060: DD 36 51 08 ld   (ix+$15),$80
2064: 3A 41 0F    ld   a,($E105)
2067: 67          ld   h,a
2068: 2E 00       ld   l,$00
206A: DD 56 41    ld   d,(ix+$05)
206D: 1E 00       ld   e,$00
206F: A7          and  a
2070: ED 52       sbc  hl,de
2072: CB 1C       rr   h
2074: CB 1D       rr   l
2076: CB 2C       sra  h
2078: CB 1D       rr   l
207A: CB 2C       sra  h
207C: CB 1D       rr   l
207E: CB 2C       sra  h
2080: CB 1D       rr   l
2082: CB 2C       sra  h
2084: CB 1D       rr   l
2086: CB 2C       sra  h
2088: CB 1D       rr   l
208A: CB 2C       sra  h
208C: CB 1D       rr   l
208E: DD 74 C1    ld   (ix+$0d),h
2091: DD 75 E0    ld   (ix+$0e),l
2094: DD 36 60 00 ld   (ix+$06),$00
2098: 3A 21 0F    ld   a,($E103)
209B: 67          ld   h,a
209C: 2E 00       ld   l,$00
209E: DD 56 21    ld   d,(ix+$03)
20A1: 1E 00       ld   e,$00
20A3: A7          and  a
20A4: ED 52       sbc  hl,de
20A6: CB 1C       rr   h
20A8: CB 1D       rr   l
20AA: CB 2C       sra  h
20AC: CB 1D       rr   l
20AE: CB 2C       sra  h
20B0: CB 1D       rr   l
20B2: CB 2C       sra  h
20B4: CB 1D       rr   l
20B6: CB 2C       sra  h
20B8: CB 1D       rr   l
20BA: CB 2C       sra  h
20BC: CB 1D       rr   l
20BE: CB 2C       sra  h
20C0: CB 1D       rr   l
20C2: DD 74 A1    ld   (ix+$0b),h
20C5: DD 75 C0    ld   (ix+$0c),l
20C8: DD 36 40 00 ld   (ix+$04),$00
20CC: C9          ret
20CD: C6 61       add  a,$07
20CF: 0F          rrca
20D0: 0F          rrca
20D1: 0F          rrca
20D2: 0F          rrca
20D3: E6 E1       and  $0F
20D5: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
20D6: C9          ret
20D7: 21 55 0E    ld   hl,$E055
20DA: 34          inc  (hl)
20DB: 3E 01       ld   a,$01
20DD: 32 4A 0E    ld   ($E0A4),a
20E0: 3A D8 0E    ld   a,($E09C)
20E3: A7          and  a
20E4: 28 81       jr   z,$20EF
20E6: 21 03 10    ld   hl,$1021
20E9: 11 03 10    ld   de,$1021
20EC: CD 0F B0    call $1AE1
20EF: CD C9 B2    call $3A8D
20F2: DD 7E 40    ld   a,(ix+$04)
20F5: A7          and  a
20F6: 28 A0       jr   z,$2102
20F8: DD 7E 41    ld   a,(ix+$05)
20FB: FE 0E       cp   $E0
20FD: 30 21       jr   nc,$2102
20FF: C3 6B B2    jp   $3AA7
2102: DD 7E 21    ld   a,(ix+$03)
2105: FE 08       cp   $80
2107: 30 02       jr   nc,$2129
2109: CD A8 03    call $218A
210C: 11 B2 03    ld   de,$213A
210F: DD 7E 90    ld   a,(ix+$18)
2112: A7          and  a
2113: 28 21       jr   z,$2118
2115: 11 C4 03    ld   de,$214C
2118: CD 88 A3    call $2B88
211B: DD 7E 70    ld   a,(ix+$16)
211E: 21 F4 03    ld   hl,$215E
2121: DF          rst  $18                   ; call ADD_A_TO_HL
2122: 5E          ld   e,(hl)
2123: FD 56 CF    ld   d,(iy-$13)
2126: C3 9C D0    jp   $1CD8
2129: CD 4D 03    call $21C5
212C: 11 66 03    ld   de,$2166
212F: DD 7E 90    ld   a,(ix+$18)
2132: A7          and  a
2133: 28 2F       jr   z,$2118
2135: 11 96 03    ld   de,$2178
2138: 18 FC       jr   $2118
213A: 80          add  a,b
213B: 18 1F       jr   $212E
213D: 0B          dec  bc
213E: 01 2A 0E    ld   bc,$E0A2
2141: 8A          adc  a,d
2142: 1E 8B       ld   e,$A9
2144: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
2145: 1A          ld   a,(de)
2146: FF          rst  $38
2147: 1B          dec  de
2148: E1          pop  hl
2149: 3A FE 9B    ld   a,($B9FE)
214C: 80          add  a,b
214D: 18 1F       jr   $2140
214F: 4A          ld   c,d
2150: 01 4B 0E    ld   bc,$E0A5
2153: AB          xor  e
2154: 1E CA       ld   e,$AC
2156: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
2157: 3B          dec  sp
2158: FF          rst  $38
2159: 5A          ld   e,d
215A: E1          pop  hl
215B: 5B          ld   e,e
215C: FE DA       cp   $BC
215E: 2B          dec  hl
215F: AA          xor  d
2160: AA          xor  d
2161: CB CB       set  1,e
2163: 0A          ld   a,(bc)
2164: 0A          ld   a,(bc)
2165: 0A          ld   a,(bc)
2166: 80          add  a,b
2167: 98          sbc  a,b
2168: 11 0B 01    ld   de,$01A1
216B: 2A 02 8A    ld   hl,($A820)
216E: 10 8B       djnz $2119
2170: E3          ex   (sp),hl
2171: 1A          ld   a,(de)
2172: F1          pop  af
2173: 1B          dec  de
2174: E1          pop  hl
2175: 3A F0 9B    ld   a,($B91E)
2178: 80          add  a,b
2179: 98          sbc  a,b
217A: 11 4A 01    ld   de,$01A4
217D: 4B          ld   c,e
217E: 02          ld   (bc),a
217F: AB          xor  e
2180: 10 CA       djnz $212E
2182: E3          ex   (sp),hl
2183: 3B          dec  sp
2184: F1          pop  af
2185: 5A          ld   e,d
2186: E1          pop  hl
2187: 5B          ld   e,e
2188: F0          ret  p
2189: DA DD 7E    jp   c,$F6DD
218C: 40          ld   b,b
218D: A7          and  a
218E: C0          ret  nz
218F: 3A 20 0E    ld   a,($E002)
2192: 47          ld   b,a
2193: E6 61       and  $07
2195: C0          ret  nz
2196: 78          ld   a,b
2197: 0F          rrca
2198: 0F          rrca
2199: 0F          rrca
219A: E6 61       and  $07
219C: 47          ld   b,a
219D: DD 7E F1    ld   a,(ix+$1f)
21A0: E6 61       and  $07
21A2: B8          cp   b
21A3: C0          ret  nz
21A4: CD 2E C6    call $6CE2
21A7: 47          ld   b,a
21A8: C6 80       add  a,$08
21AA: D6 8C       sub  $C8
21AC: FE 86       cp   $68
21AE: D0          ret  nc
21AF: DD 70 20    ld   (ix+$02),b
21B2: 0F          rrca
21B3: 0F          rrca
21B4: 0F          rrca
21B5: 0F          rrca
21B6: E6 E1       and  $0F
21B8: DD 77 70    ld   (ix+$16),a
21BB: DD 36 71 00 ld   (ix+$17),$00
21BF: 21 BF 03    ld   hl,$21FB
21C2: C3 43 22    jp   $2225
21C5: DD 7E F1    ld   a,(ix+$1f)
21C8: 87          add  a,a
21C9: 87          add  a,a
21CA: 87          add  a,a
21CB: 87          add  a,a
21CC: E6 F3       and  $3F
21CE: 47          ld   b,a
21CF: 3A 20 0E    ld   a,($E002)
21D2: E6 F3       and  $3F
21D4: B8          cp   b
21D5: C0          ret  nz
21D6: CD 2E C6    call $6CE2
21D9: 47          ld   b,a
21DA: C6 80       add  a,$08
21DC: D6 14       sub  $50
21DE: FE 86       cp   $68
21E0: D0          ret  nc
21E1: DD 70 20    ld   (ix+$02),b
21E4: 0F          rrca
21E5: 0F          rrca
21E6: 0F          rrca
21E7: 0F          rrca
21E8: E6 E1       and  $0F
21EA: 47          ld   b,a
21EB: 3E 60       ld   a,$06
21ED: 90          sub  b
21EE: DD 77 70    ld   (ix+$16),a
21F1: DD 36 71 80 ld   (ix+$17),$08
21F5: 21 10 22    ld   hl,$2210
21F8: C3 43 22    jp   $2225
21FB: 60          ld   h,b
21FC: 7E          ld   a,(hl)
21FD: BB          cp   e
21FE: 81          add  a,c
21FF: 7E          ld   a,(hl)
2200: BB          cp   e
2201: 81          add  a,c
2202: 7E          ld   a,(hl)
2203: BB          cp   e
2204: C0          ret  nz
2205: BF          cp   a
2206: BA          cp   d
2207: C0          ret  nz
2208: BF          cp   a
2209: BA          cp   d
220A: A0          and  b
220B: 41          ld   b,c
220C: 9A          sbc  a,d
220D: A0          and  b
220E: 41          ld   b,c
220F: 9A          sbc  a,d
2210: BE          cp   (hl)
2211: 7E          ld   a,(hl)
2212: BB          cp   e
2213: 7F          ld   a,a
2214: 7E          ld   a,(hl)
2215: BB          cp   e
2216: 7F          ld   a,a
2217: 7E          ld   a,(hl)
2218: BB          cp   e
2219: 5E          ld   e,(hl)
221A: BF          cp   a
221B: BA          cp   d
221C: 5E          ld   e,(hl)
221D: BF          cp   a
221E: BA          cp   d
221F: 7E          ld   a,(hl)
2220: 41          ld   b,c
2221: 9A          sbc  a,d
2222: 7E          ld   a,(hl)
2223: 41          ld   b,c
2224: 9A          sbc  a,d
2225: DD E5       push ix
2227: 11 6A 22    ld   de,$22A6
222A: D5          push de
222B: DD 7E 70    ld   a,(ix+$16)
222E: 47          ld   b,a
222F: 87          add  a,a
2230: 80          add  a,b
2231: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
2232: DD 86 21    add  a,(ix+$03)
2235: 57          ld   d,a
2236: 23          inc  hl
2237: 7E          ld   a,(hl)
2238: DD 86 41    add  a,(ix+$05)
223B: 5F          ld   e,a
223C: 23          inc  hl
223D: 4E          ld   c,(hl)
223E: DD 46 20    ld   b,(ix+$02)
2241: DD 21 0E 4F ld   ix,$E5E0
2245: 21 50 FE    ld   hl,$FE14
2248: DD 7E 00    ld   a,(ix+$00)
224B: A7          and  a
224C: 28 B1       jr   z,$2269
224E: DD 21 0C 4F ld   ix,$E5C0
2252: 21 90 FE    ld   hl,$FE18
2255: DD 7E 00    ld   a,(ix+$00)
2258: A7          and  a
2259: 28 E0       jr   z,$2269
225B: DD 21 0A 4F ld   ix,$E5A0
225F: 21 D0 FE    ld   hl,$FE1C
2262: DD 7E 00    ld   a,(ix+$00)
2265: A7          and  a
2266: 28 01       jr   z,$2269
2268: C9          ret
2269: DD 36 B0 01 ld   (ix+$1a),$01
226D: DD 74 B1    ld   (ix+$1b),h
2270: DD 75 D0    ld   (ix+$1c),l
2273: DD 36 00 FF ld   (ix+$00),$FF
2277: DD 70 01    ld   (ix+$01),b
227A: DD 70 20    ld   (ix+$02),b
227D: DD 71 30    ld   (ix+$12),c
2280: DD 72 21    ld   (ix+$03),d
2283: DD 73 41    ld   (ix+$05),e
2286: DD 36 E1 40 ld   (ix+$0f),$04
228A: CD 46 C6    call $6C64
228D: DD 72 A1    ld   (ix+$0b),d
2290: DD 73 C0    ld   (ix+$0c),e
2293: DD 70 C1    ld   (ix+$0d),b
2296: DD 71 E0    ld   (ix+$0e),c
2299: DD 36 31 60 ld   (ix+$13),$06
229D: DD 36 50 00 ld   (ix+$14),$00
22A1: DD 36 51 40 ld   (ix+$15),$04
22A5: C9          ret
22A6: DD E1       pop  ix
22A8: C9          ret
22A9: DD 35 51    dec  (ix+$15)
22AC: 28 45       jr   z,$22F3
22AE: DD 7E 50    ld   a,(ix+$14)
22B1: A7          and  a
22B2: 28 C3       jr   z,$22E1
22B4: CD 5C E9    call $8FD4
22B7: 3A 00 0F    ld   a,($E100)
22BA: 3C          inc  a
22BB: 20 D1       jr   nz,$22DA
22BD: 3A 21 0F    ld   a,($E103)
22C0: DD 96 21    sub  (ix+$03)
22C3: C6 C0       add  a,$0C
22C5: FE 91       cp   $19
22C7: 30 11       jr   nc,$22DA
22C9: 3A 41 0F    ld   a,($E105)
22CC: DD 96 41    sub  (ix+$05)
22CF: C6 C0       add  a,$0C
22D1: FE 91       cp   $19
22D3: 30 41       jr   nc,$22DA
22D5: 3E F3       ld   a,$3F
22D7: 32 00 0F    ld   ($E100),a
22DA: 1E 1B       ld   e,$B1
22DC: 16 12       ld   d,$30
22DE: C3 9C D0    jp   $1CD8
22E1: 16 08       ld   d,$80
22E3: DD 5E 30    ld   e,(ix+$12)
22E6: DD 7E 21    ld   a,(ix+$03)
22E9: FE 08       cp   $80
22EB: DA 9C D0    jp   c,$1CD8
22EE: 16 88       ld   d,$88
22F0: C3 9C D0    jp   $1CD8
22F3: DD 7E 50    ld   a,(ix+$14)
22F6: DD 34 50    inc  (ix+$14)
22F9: A7          and  a
22FA: 28 11       jr   z,$230D
22FC: DD 66 21    ld   h,(ix+$03)
22FF: DD 6E 41    ld   l,(ix+$05)
2302: DD 36 00 00 ld   (ix+$00),$00
2306: FD 36 20 00 ld   (iy+$02),$00
230A: C3 C1 38    jp   $920D
230D: DD 36 51 14 ld   (ix+$15),$50
2311: C9          ret
2312: C9          ret
2313: C9          ret
2314: 21 55 0E    ld   hl,$E055
2317: 34          inc  (hl)
2318: 3A D8 0E    ld   a,($E09C)
231B: A7          and  a
231C: 28 81       jr   z,$2327
231E: 21 13 00    ld   hl,$0031
2321: 11 03 10    ld   de,$1021
2324: CD 0F B0    call $1AE1
2327: CD C9 B2    call $3A8D
232A: CD 13 23    call $2331
232D: CD 10 42    call $2410
2330: C9          ret
2331: DD 7E 41    ld   a,(ix+$05)
2334: FE 8E       cp   $E8
2336: D0          ret  nc
2337: DD 7E 50    ld   a,(ix+$14)
233A: E6 01       and  $01
233C: 20 51       jr   nz,$2353
233E: DD 35 51    dec  (ix+$15)
2341: C0          ret  nz
2342: DD 34 50    inc  (ix+$14)
2345: DD 36 51 71 ld   (ix+$15),$17
2349: CD B6 68    call $867A
234C: C9          ret
234D: CD F7 68    call $867F
2350: C3 6B B2    jp   $3AA7
2353: 3A 20 0E    ld   a,($E002)
2356: E6 01       and  $01
2358: C0          ret  nz
2359: DD 35 21    dec  (ix+$03)
235C: DD 7E 21    ld   a,(ix+$03)
235F: FE EF       cp   $EF
2361: CA C5 23    jp   z,$234D
2364: DD 7E 70    ld   a,(ix+$16)
2367: FE 41       cp   $05
2369: D0          ret  nc
236A: DD 7E 40    ld   a,(ix+$04)
236D: A7          and  a
236E: C0          ret  nz
236F: DD 35 51    dec  (ix+$15)
2372: C0          ret  nz
2373: DD 34 50    inc  (ix+$14)
2376: DD 36 51 02 ld   (ix+$15),$20
237A: CD 56 68    call $8674
237D: DD 4E 70    ld   c,(ix+$16)
2380: DD 34 70    inc  (ix+$16)
2383: DD E5       push ix
2385: 21 C1 42    ld   hl,$240D
2388: E5          push hl
2389: DD 7E 21    ld   a,(ix+$03)
238C: C6 12       add  a,$30
238E: 67          ld   h,a
238F: DD 7E 41    ld   a,(ix+$05)
2392: C6 80       add  a,$08
2394: 6F          ld   l,a
2395: DD 21 00 6E ld   ix,$E600
2399: 06 80       ld   b,$08
239B: 11 02 00    ld   de,$0020
239E: DD 7E 00    ld   a,(ix+$00)
23A1: A7          and  a
23A2: 28 41       jr   z,$23A9
23A4: DD 19       add  ix,de
23A6: 10 7E       djnz $239E
23A8: C9          ret
23A9: DD 35 00    dec  (ix+$00)
23AC: DD 74 21    ld   (ix+$03),h
23AF: DD 74 61    ld   (ix+$07),h
23B2: DD 75 41    ld   (ix+$05),l
23B5: DD 75 81    ld   (ix+$09),l
23B8: DD 36 E1 00 ld   (ix+$0f),$00
23BC: DD 36 11 00 ld   (ix+$11),$00
23C0: DD 36 31 80 ld   (ix+$13),$08
23C4: DD 36 50 00 ld   (ix+$14),$00
23C8: DD 36 51 00 ld   (ix+$15),$00
23CC: 79          ld   a,c
23CD: 21 BD 23    ld   hl,$23DB
23D0: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
23D1: DD 72 70    ld   (ix+$16),d
23D4: DD 73 71    ld   (ix+$17),e
23D7: CD 4C 59    call $95C4
23DA: C9          ret
23DB: 4F          ld   c,a
23DC: 23          inc  hl
23DD: CF          rst  $08
23DE: 23          inc  hl
23DF: 5F          ld   e,a
23E0: 23          inc  hl
23E1: DF          rst  $18
23E2: 23          inc  hl
23E3: 41          ld   b,c
23E4: 42          ld   b,d
23E5: FB          ei
23E6: 0C          inc  c
23E7: 04          inc  b
23E8: 0E 04       ld   c,$40
23EA: 1E 08       ld   e,$80
23EC: FF          rst  $38
23ED: FB          ei
23EE: 0C          inc  c
23EF: 04          inc  b
23F0: 0E 04       ld   c,$40
23F2: 1E 08       ld   e,$80
23F4: FF          rst  $38
23F5: FB          ei
23F6: 0C          inc  c
23F7: 04          inc  b
23F8: 0E 04       ld   c,$40
23FA: 1E 08       ld   e,$80
23FC: FF          rst  $38
23FD: FB          ei
23FE: 0C          inc  c
23FF: 04          inc  b
2400: 0E 04       ld   c,$40
2402: 1E 08       ld   e,$80
2404: FF          rst  $38
2405: FB          ei
2406: 0C          inc  c
2407: 04          inc  b
2408: 0E 04       ld   c,$40
240A: 1E 08       ld   e,$80
240C: FF          rst  $38
240D: DD E1       pop  ix
240F: C9          ret
2410: 11 70 42    ld   de,$2416
2413: C3 88 A3    jp   $2B88
2416: 80          add  a,b
2417: 14          inc  d
2418: 01 0E 11    ld   bc,$11E0
241B: 0F          rrca
241C: 03          inc  bc
241D: 2E 13       ld   l,$31
241F: 2F          cpl
2420: 00          nop
2421: 8E          adc  a,(hl)
2422: 10 8F       djnz $240D
2424: 02          ld   (bc),a
2425: AE          xor  (hl)
2426: 12          ld   (de),a
2427: AF          xor  a
2428: 21 55 0E    ld   hl,$E055
242B: 34          inc  (hl)
242C: 3A D8 0E    ld   a,($E09C)
242F: A7          and  a
2430: 28 81       jr   z,$243B
2432: 21 03 10    ld   hl,$1021
2435: 11 03 10    ld   de,$1021
2438: CD 0F B0    call $1AE1
243B: 3A 26 0E    ld   a,($E062)
243E: A7          and  a
243F: 28 60       jr   z,$2447
2441: DD 35 41    dec  (ix+$05)
2444: CA AC 42    jp   z,$24CA
2447: CD E4 42    call $244E
244A: CD 3D 42    call $24D3
244D: C9          ret
244E: DD 35 51    dec  (ix+$15)
2451: 20 55       jr   nz,$24A8
2453: DD 7E 41    ld   a,(ix+$05)
2456: 47          ld   b,a
2457: 3A 41 0F    ld   a,($E105)
245A: B8          cp   b
245B: 30 82       jr   nc,$2485
245D: DD 34 50    inc  (ix+$14)
2460: DD 7E 50    ld   a,(ix+$14)
2463: FE 20       cp   $02
2465: 28 22       jr   z,$2489
2467: FE 41       cp   $05
2469: 28 A1       jr   z,$2476
246B: CD E3 98    call $982F
246E: E6 61       and  $07
2470: C6 61       add  a,$07
2472: DD 77 51    ld   (ix+$15),a
2475: C9          ret
2476: CD E3 98    call $982F
2479: E6 F3       and  $3F
247B: C6 02       add  a,$20
247D: DD 77 51    ld   (ix+$15),a
2480: DD 36 50 00 ld   (ix+$14),$00
2484: C9          ret
2485: E1          pop  hl
2486: C3 AC 42    jp   $24CA
2489: CD 2E C6    call $6CE2
248C: 47          ld   b,a
248D: D6 18       sub  $90
248F: FE 06       cp   $60
2491: 38 10       jr   c,$24A3
2493: DD 36 50 00 ld   (ix+$14),$00
2497: CD E3 98    call $982F
249A: E6 F1       and  $1F
249C: 87          add  a,a
249D: C6 02       add  a,$20
249F: DD 77 51    ld   (ix+$15),a
24A2: C9          ret
24A3: DD 36 51 04 ld   (ix+$15),$40
24A7: C9          ret
24A8: DD 7E 50    ld   a,(ix+$14)
24AB: FE 20       cp   $02
24AD: C0          ret  nz
24AE: 3A 20 0E    ld   a,($E002)
24B1: E6 E1       and  $0F
24B3: 47          ld   b,a
24B4: DD 7E F1    ld   a,(ix+$1f)
24B7: E6 E1       and  $0F
24B9: B8          cp   b
24BA: C0          ret  nz
24BB: CD 2E C6    call $6CE2
24BE: 47          ld   b,a
24BF: D6 0A       sub  $A0
24C1: FE 04       cp   $40
24C3: D0          ret  nc
24C4: DD 70 20    ld   (ix+$02),b
24C7: C3 11 58    jp   $9411
24CA: DD 36 00 00 ld   (ix+$00),$00
24CE: FD 36 20 00 ld   (iy+$02),$00
24D2: C9          ret
24D3: DD 7E 50    ld   a,(ix+$14)
24D6: FE 20       cp   $02
24D8: 28 71       jr   z,$24F1
24DA: 47          ld   b,a
24DB: DD 7E 71    ld   a,(ix+$17)
24DE: 21 91 43    ld   hl,$2519
24E1: 16 10       ld   d,$10
24E3: A7          and  a
24E4: 28 41       jr   z,$24EB
24E6: 21 62 43    ld   hl,$2526
24E9: 16 00       ld   d,$00
24EB: 78          ld   a,b
24EC: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
24ED: 5F          ld   e,a
24EE: C3 9C D0    jp   $1CD8
24F1: 16 10       ld   d,$10
24F3: 21 11 43    ld   hl,$2511
24F6: DD 7E 71    ld   a,(ix+$17)
24F9: A7          and  a
24FA: 28 41       jr   z,$2501
24FC: 21 F0 43    ld   hl,$251E
24FF: 16 00       ld   d,$00
2501: DD 7E 20    ld   a,(ix+$02)
2504: C6 61       add  a,$07
2506: 0F          rrca
2507: 0F          rrca
2508: 0F          rrca
2509: 0F          rrca
250A: E6 61       and  $07
250C: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
250D: 5F          ld   e,a
250E: C3 9C D0    jp   $1CD8
2511: 79          ld   a,c
2512: 79          ld   a,c
2513: 79          ld   a,c
2514: 79          ld   a,c
2515: 28 F9       jr   z,$24B6
2517: F9          ld   sp,hl
2518: F9          ld   sp,hl
2519: 08          ex   af,af'
251A: 09          add  hl,bc
251B: 28 09       jr   z,$249E
251D: 08          ex   af,af'
251E: FE FE       cp   $FE
2520: FE FE       cp   $FE
2522: A8          xor  b
2523: DF          rst  $18
2524: DF          rst  $18
2525: DF          rst  $18
2526: 88          adc  a,b
2527: 89          adc  a,c
2528: A8          xor  b
2529: 89          adc  a,c
252A: 88          adc  a,b
252B: DD 35 51    dec  (ix+$15)
252E: 28 F0       jr   z,$254E
2530: CD F5 43    call $255F
2533: DD 7E 51    ld   a,(ix+$15)
2536: 21 64 43    ld   hl,$2546
2539: 0F          rrca
253A: 0F          rrca
253B: 0F          rrca
253C: 0F          rrca
253D: E6 E1       and  $0F
253F: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
2540: 5F          ld   e,a
2541: 16 10       ld   d,$10
2543: C3 9C D0    jp   $1CD8
2546: 5A          ld   e,d
2547: 3B          dec  sp
2548: 3B          dec  sp
2549: 3A 3A 3B    ld   a,($B3B2)
254C: 3B          dec  sp
254D: 5A          ld   e,d
254E: DD 36 00 00 ld   (ix+$00),$00
2552: DD 66 21    ld   h,(ix+$03)
2555: DD 6E 41    ld   l,(ix+$05)
2558: FD 36 20 00 ld   (iy+$02),$00
255C: C3 C1 38    jp   $920D
255F: DD 7E 51    ld   a,(ix+$15)
2562: 0F          rrca
2563: 0F          rrca
2564: 0F          rrca
2565: 0F          rrca
2566: E6 61       and  $07
2568: 87          add  a,a
2569: 21 88 43    ld   hl,$2588
256C: DF          rst  $18                   ; call ADD_A_TO_HL
256D: 4E          ld   c,(hl)
256E: 23          inc  hl
256F: 46          ld   b,(hl)
2570: CD 5C E9    call $8FD4
2573: 09          add  hl,bc
2574: DD 74 41    ld   (ix+$05),h
2577: DD 75 60    ld   (ix+$06),l
257A: 7C          ld   a,h
257B: FE 9E       cp   $F8
257D: D8          ret  c
257E: E1          pop  hl
257F: DD 36 00 00 ld   (ix+$00),$00
2583: FD 36 20 00 ld   (iy+$02),$00
2587: C9          ret
2588: 08          ex   af,af'
2589: FE 0E       cp   $E0
258B: FE 04       cp   $40
258D: FF          rst  $38
258E: 0C          inc  c
258F: FF          rst  $38
2590: 04          inc  b
2591: 00          nop
2592: 0C          inc  c
2593: 00          nop
2594: 02          ld   (bc),a
2595: 01 08 01    ld   bc,$0180
2598: DD 7E 00    ld   a,(ix+$00)
259B: FE FE       cp   $FE
259D: C8          ret  z
259E: CD 5C E9    call $8FD4
25A1: 1E 7E       ld   e,$F6
25A3: 16 16       ld   d,$70
25A5: CD 9C D0    call $1CD8
25A8: DD 35 51    dec  (ix+$15)
25AB: C0          ret  nz
25AC: DD 36 00 00 ld   (ix+$00),$00
25B0: FD 36 20 00 ld   (iy+$02),$00
25B4: DD 66 21    ld   h,(ix+$03)
25B7: DD 6E 41    ld   l,(ix+$05)
25BA: C3 C1 38    jp   $920D
25BD: C9          ret
25BE: 21 55 0E    ld   hl,$E055
25C1: 34          inc  (hl)
25C2: 3A D8 0E    ld   a,($E09C)
25C5: A7          and  a
25C6: 28 81       jr   z,$25D1
25C8: 21 03 10    ld   hl,$1021
25CB: 11 13 80    ld   de,$0831
25CE: CD 0F B0    call $1AE1
25D1: CD C9 B2    call $3A8D
25D4: CD 20 62    call $2602
25D7: CD C6 62    call $266C
25DA: DD 7E 50    ld   a,(ix+$14)
25DD: 21 B1 63    ld   hl,$271B
25E0: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
25E1: 5F          ld   e,a
25E2: 16 14       ld   d,$50
25E4: DD 7E 21    ld   a,(ix+$03)
25E7: F5          push af
25E8: C6 80       add  a,$08
25EA: DD 77 21    ld   (ix+$03),a
25ED: CD 9C D0    call $1CD8
25F0: F1          pop  af
25F1: DD 77 21    ld   (ix+$03),a
25F4: 11 40 00    ld   de,$0004
25F7: FD 19       add  iy,de
25F9: 11 F1 63    ld   de,$271F
25FC: CD 88 A3    call $2B88
25FF: C3 88 A3    jp   $2B88
2602: CD 15 62    call $2651
2605: DD 7E 71    ld   a,(ix+$17)
2608: A7          and  a
2609: 28 92       jr   z,$2643
260B: 11 06 01    ld   de,$0160
260E: DD 7E 40    ld   a,(ix+$04)
2611: DD 66 41    ld   h,(ix+$05)
2614: DD 6E 60    ld   l,(ix+$06)
2617: 19          add  hl,de
2618: DD 74 41    ld   (ix+$05),h
261B: DD 75 60    ld   (ix+$06),l
261E: CE 00       adc  a,$00
2620: DD 77 40    ld   (ix+$04),a
2623: A7          and  a
2624: 28 C0       jr   z,$2632
2626: DD 7E 41    ld   a,(ix+$05)
2629: FE 10       cp   $10
262B: D2 32 62    jp   nc,$2632
262E: E1          pop  hl
262F: C3 6B B2    jp   $3AA7
2632: DD 7E 90    ld   a,(ix+$18)
2635: A7          and  a
2636: C0          ret  nz
2637: 7C          ld   a,h
2638: FE 1E       cp   $F0
263A: D8          ret  c
263B: DD 36 71 00 ld   (ix+$17),$00
263F: CD 56 68    call $8674
2642: C9          ret
2643: DD 7E 41    ld   a,(ix+$05)
2646: FE 18       cp   $90
2648: D0          ret  nc
2649: CD B6 68    call $867A
264C: DD 36 71 01 ld   (ix+$17),$01
2650: C9          ret
2651: DD 7E 90    ld   a,(ix+$18)
2654: A7          and  a
2655: C0          ret  nz
2656: 3A 20 0E    ld   a,($E002)
2659: CB 4F       bit  1,a
265B: C8          ret  z
265C: DD 35 70    dec  (ix+$16)
265F: C0          ret  nz
2660: DD 36 90 01 ld   (ix+$18),$01
2664: DD 36 71 01 ld   (ix+$17),$01
2668: CD B6 68    call $867A
266B: C9          ret
266C: DD 7E 50    ld   a,(ix+$14)
266F: A7          and  a
2670: 28 A7       jr   z,$26DD
2672: DD 35 51    dec  (ix+$15)
2675: C0          ret  nz
2676: DD 34 50    inc  (ix+$14)
2679: DD 7E 50    ld   a,(ix+$14)
267C: FE 21       cp   $03
267E: 28 81       jr   z,$2689
2680: FE 40       cp   $04
2682: 28 54       jr   z,$26D8
2684: DD 36 51 80 ld   (ix+$15),$08
2688: C9          ret
2689: DD 36 51 80 ld   (ix+$15),$08
268D: DD E5       push ix
268F: DD 66 E1    ld   h,(ix+$0f)
2692: DD 6E 10    ld   l,(ix+$10)
2695: DD 56 21    ld   d,(ix+$03)
2698: DD 5E 41    ld   e,(ix+$05)
269B: DD 46 11    ld   b,(ix+$11)
269E: DD 4E 30    ld   c,(ix+$12)
26A1: E5          push hl
26A2: DD E1       pop  ix
26A4: DD 36 00 FF ld   (ix+$00),$FF
26A8: DD 36 31 C0 ld   (ix+$13),$0C
26AC: DD 72 21    ld   (ix+$03),d
26AF: DD 73 41    ld   (ix+$05),e
26B2: DD 70 B1    ld   (ix+$1b),b
26B5: DD 71 D0    ld   (ix+$1c),c
26B8: CD 2E C6    call $6CE2
26BB: DD 77 01    ld   (ix+$01),a
26BE: DD 36 E1 01 ld   (ix+$0f),$01
26C2: CD 46 C6    call $6C64
26C5: DD 72 A1    ld   (ix+$0b),d
26C8: DD 73 C0    ld   (ix+$0c),e
26CB: DD 70 C1    ld   (ix+$0d),b
26CE: DD 71 E0    ld   (ix+$0e),c
26D1: DD 36 51 12 ld   (ix+$15),$30
26D5: DD E1       pop  ix
26D7: C9          ret
26D8: DD 36 50 00 ld   (ix+$14),$00
26DC: C9          ret
26DD: DD 7E 40    ld   a,(ix+$04)
26E0: A7          and  a
26E1: C0          ret  nz
26E2: 3A 20 0E    ld   a,($E002)
26E5: E6 F3       and  $3F
26E7: C0          ret  nz
26E8: 21 0E 4F    ld   hl,$E5E0
26EB: 11 50 FE    ld   de,$FE14
26EE: 7E          ld   a,(hl)
26EF: A7          and  a
26F0: 28 31       jr   z,$2705
26F2: 21 0C 4F    ld   hl,$E5C0
26F5: 11 90 FE    ld   de,$FE18
26F8: 7E          ld   a,(hl)
26F9: A7          and  a
26FA: 28 81       jr   z,$2705
26FC: 21 0A 4F    ld   hl,$E5A0
26FF: 11 D0 FE    ld   de,$FE1C
2702: 7E          ld   a,(hl)
2703: A7          and  a
2704: C0          ret  nz
2705: 36 FE       ld   (hl),$FE
2707: DD 74 E1    ld   (ix+$0f),h
270A: DD 75 10    ld   (ix+$10),l
270D: DD 72 11    ld   (ix+$11),d
2710: DD 73 30    ld   (ix+$12),e
2713: DD 34 50    inc  (ix+$14)
2716: DD 36 51 80 ld   (ix+$15),$08
271A: C9          ret
271B: 6E          ld   l,(hl)
271C: 6F          ld   l,a
271D: EE EF       xor  $EF
271F: 21 14 20    ld   hl,$0250
2722: 4E          ld   c,(hl)
2723: 01 CE 00    ld   bc,$00EC
2726: 5E          ld   e,(hl)
2727: 21 94 30    ld   hl,$1258
272A: 4E          ld   c,(hl)
272B: 11 CE 10    ld   de,$10EC
272E: 5E          ld   e,(hl)
272F: CD 65 63    call $2747
2732: 3A 4A 0E    ld   a,($E0A4)
2735: 32 4B 0E    ld   ($E0A5),a
2738: AF          xor  a
2739: 32 4A 0E    ld   ($E0A4),a
273C: CD F2 A2    call $2A3E
273F: C9          ret
2740: 21 EA 17    ld   hl,$71AE
2743: 22 E9 0E    ld   ($E08F),hl
2746: C9          ret
2747: FD 2A E9 0E ld   iy,($E08F)
274B: FD 6E 00    ld   l,(iy+$00)
274E: FD 7E 01    ld   a,(iy+$01)
2751: 67          ld   h,a
2752: FE FF       cp   $FF
2754: C8          ret  z
2755: ED 5B B5 0E ld   de,($E05B)
2759: 7A          ld   a,d
275A: 53          ld   d,e
275B: 5F          ld   e,a
275C: A7          and  a
275D: ED 52       sbc  hl,de
275F: 7C          ld   a,h
2760: A7          and  a
2761: 28 A0       jr   z,$276D
2763: CB 7F       bit  7,a
2765: C8          ret  z
2766: 11 60 00    ld   de,$0006
2769: FD 19       add  iy,de
276B: 18 FC       jr   $274B
276D: FD 66 20    ld   h,(iy+$02)
2770: FD 4E 21    ld   c,(iy+$03)
2773: FD 5E 40    ld   e,(iy+$04)
2776: FD 56 41    ld   d,(iy+$05)
2779: DD 21 00 4F ld   ix,$E500
277D: D9          exx
277E: 11 02 00    ld   de,$0020
2781: 06 80       ld   b,$08
2783: DD 7E 00    ld   a,(ix+$00)
2786: A7          and  a
2787: 28 81       jr   z,$2792
2789: DD 19       add  ix,de
278B: 10 7E       djnz $2783
278D: FD 22 E9 0E ld   ($E08F),iy
2791: C9          ret
2792: DD 70 F1    ld   (ix+$1f),b
2795: DD 36 00 FF ld   (ix+$00),$FF
2799: D9          exx
279A: DD 72 B1    ld   (ix+$1b),d
279D: DD 73 D0    ld   (ix+$1c),e
27A0: DD 74 31    ld   (ix+$13),h
27A3: DD 71 21    ld   (ix+$03),c
27A6: DD 75 41    ld   (ix+$05),l
27A9: DD 36 40 00 ld   (ix+$04),$00
27AD: 11 60 00    ld   de,$0006
27B0: FD 19       add  iy,de
27B2: FD 22 E9 0E ld   ($E08F),iy
27B6: DD 7E 31    ld   a,(ix+$13)
27B9: 47          ld   b,a
27BA: 21 E0 A2    ld   hl,$2A0E
27BD: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
27BE: DD 77 B0    ld   (ix+$1a),a
27C1: 78          ld   a,b
27C2: F7          rst  $30
27C3: A9          xor  c
27C4: 83          add  a,e
27C5: 0A          ld   a,(bc)
27C6: 83          add  a,e
27C7: D8          ret  c
27C8: 83          add  a,e
27C9: FB          ei
27CA: 83          add  a,e
27CB: 84          add  a,h
27CC: F1          pop  af
27CD: CC 83 43    call z,$2529
27D0: 22 D9 82    ld   ($289D),hl
27D3: DD          db   $dd
27D4: 83          add  a,e
27D5: 2E 83       ld   l,$29
27D7: AE          xor  (hl)
27D8: 83          add  a,e
27D9: BE          cp   (hl)
27DA: 83          add  a,e
27DB: D9          exx
27DC: 82          add  a,d
27DD: D9          exx
27DE: 82          add  a,d
27DF: F6 83       or   $29
27E1: D4 83 D9    call nc,$9D29
27E4: 82          add  a,d
27E5: D9          exx
27E6: 82          add  a,d
27E7: 35          dec  (hl)
27E8: 83          add  a,e
27E9: D9          exx
27EA: 82          add  a,d
27EB: E4 83 44    call po,$4429
27EE: 83          add  a,e
27EF: C5          push bc
27F0: 83          add  a,e
27F1: F3          di
27F2: 83          add  a,e
27F3: F3          di
27F4: 83          add  a,e
27F5: 90          sub  b
27F6: 83          add  a,e
27F7: D9          exx
27F8: 82          add  a,d
27F9: D9          exx
27FA: 82          add  a,d
27FB: D9          exx
27FC: 82          add  a,d
27FD: D9          exx
27FE: 82          add  a,d
27FF: 63          ld   h,e
2800: 72          ld   (hl),d
2801: DC 82 D9    call c,$9D28
2804: 82          add  a,d
2805: 6B          ld   l,e
2806: 82          add  a,d
2807: D9          exx
2808: 82          add  a,d
2809: 97          sub  a
280A: 82          add  a,d
280B: F8          ret  m
280C: 82          add  a,d
280D: D9          exx
280E: 82          add  a,d
280F: A9          xor  c
2810: 83          add  a,e
2811: 89          adc  a,c
2812: 82          add  a,d
2813: C6 82       add  a,$28
2815: 0C          inc  c
2816: 82          add  a,d
2817: 90          sub  b
2818: 83          add  a,e
2819: 24          inc  h
281A: 82          add  a,d
281B: 23          inc  hl
281C: 82          add  a,d
281D: 23          inc  hl
281E: 82          add  a,d
281F: 17          rla
2820: 83          add  a,e
2821: A9          xor  c
2822: 83          add  a,e
2823: CD E7 68    call $866F
2826: DD 7E 41    ld   a,(ix+$05)
2829: FE 1E       cp   $F0
282B: D2 33 82    jp   nc,$2833
282E: DD 36 00 00 ld   (ix+$00),$00
2832: C9          ret
2833: 3A 21 0F    ld   a,($E103)
2836: 47          ld   b,a
2837: 3A 20 0E    ld   a,($E002)
283A: E6 F1       and  $1F
283C: 2F          cpl
283D: 80          add  a,b
283E: DD 77 21    ld   (ix+$03),a
2841: C9          ret
2842: CD E7 68    call $866F
2845: DD 7E 41    ld   a,(ix+$05)
2848: FE 1E       cp   $F0
284A: D2 34 82    jp   nc,$2852
284D: DD 36 00 00 ld   (ix+$00),$00
2851: C9          ret
2852: DD 36 41 14 ld   (ix+$05),$50
2856: DD 7E 21    ld   a,(ix+$03)
2859: E6 21       and  $03
285B: DD 77 50    ld   (ix+$14),a
285E: CB 47       bit  0,a
2860: 28 41       jr   z,$2867
2862: DD 36 21 1E ld   (ix+$03),$F0
2866: C9          ret
2867: DD 36 21 0E ld   (ix+$03),$E0
286B: C9          ret
286C: DD 36 50 00 ld   (ix+$14),$00
2870: DD 36 51 00 ld   (ix+$15),$00
2874: DD 36 70 00 ld   (ix+$16),$00
2878: C9          ret
2879: DD 7E 21    ld   a,(ix+$03)
287C: 47          ld   b,a
287D: E6 21       and  $03
287F: DD 77 50    ld   (ix+$14),a
2882: 78          ld   a,b
2883: E6 DE       and  $FC
2885: DD 77 21    ld   (ix+$03),a
2888: C9          ret
2889: DD 7E 21    ld   a,(ix+$03)
288C: DD CB 21 68 res  0,(ix+$03)
2890: E6 01       and  $01
2892: DD 77 71    ld   (ix+$17),a
2895: DD 36 A0 0C ld   (ix+$0a),$C0
2899: CD D9 68    call $869D
289C: C9          ret
289D: C9          ret
289E: DD 36 50 00 ld   (ix+$14),$00
28A2: DD 36 51 00 ld   (ix+$15),$00
28A6: C9          ret
28A7: DD 7E 21    ld   a,(ix+$03)
28AA: E6 01       and  $01
28AC: DD CB 21 68 res  0,(ix+$03)
28B0: DD 77 71    ld   (ix+$17),a
28B3: DD 36 50 00 ld   (ix+$14),$00
28B7: DD 36 51 00 ld   (ix+$15),$00
28BB: DD 36 70 00 ld   (ix+$16),$00
28BF: C9          ret
28C0: DD 7E 21    ld   a,(ix+$03)
28C3: 47          ld   b,a
28C4: E6 21       and  $03
28C6: DD 77 71    ld   (ix+$17),a
28C9: 78          ld   a,b
28CA: E6 DE       and  $FC
28CC: DD 77 21    ld   (ix+$03),a
28CF: DD 36 50 00 ld   (ix+$14),$00
28D3: DD 36 51 00 ld   (ix+$15),$00
28D7: DD 36 70 00 ld   (ix+$16),$00
28DB: C9          ret
28DC: 3A 20 0E    ld   a,($E002)
28DF: E6 08       and  $80
28E1: D6 04       sub  $40
28E3: 47          ld   b,a
28E4: 3A 21 0F    ld   a,($E103)
28E7: 80          add  a,b
28E8: DD 77 21    ld   (ix+$03),a
28EB: DD 36 20 0C ld   (ix+$02),$C0
28EF: DD 36 41 00 ld   (ix+$05),$00
28F3: DD 36 50 00 ld   (ix+$14),$00
28F7: DD 36 51 00 ld   (ix+$15),$00
28FB: DD 36 71 00 ld   (ix+$17),$00
28FF: CD E7 68    call $866F
2902: C9          ret
2903: 25          dec  h
2904: E5          push hl
2905: 14          inc  d
2906: 95          sub  l
2907: 34          inc  (hl)
2908: 85          add  a,l
2909: 65          ld   h,l
290A: 84          add  a,h
290B: 54          ld   d,h
290C: 02          ld   (bc),a
290D: 25          dec  h
290E: 05          dec  b
290F: 14          inc  d
2910: 25          dec  h
2911: E5          push hl
2912: C5          push bc
2913: 02          ld   (bc),a
2914: 13          inc  de
2915: 93          sub  e
2916: 92          sub  d
2917: 53          ld   d,e
2918: 11 0C FE    ld   de,$FEC0
291B: DD 72 A1    ld   (ix+$0b),d
291E: DD 73 C0    ld   (ix+$0c),e
2921: 11 00 00    ld   de,$0000
2924: DD 36 C1 00 ld   (ix+$0d),$00
2928: DD 36 E0 00 ld   (ix+$0e),$00
292C: DD 36 E1 00 ld   (ix+$0f),$00
2930: DD 36 10 00 ld   (ix+$10),$00
2934: DD 36 50 00 ld   (ix+$14),$00
2938: DD 36 51 82 ld   (ix+$15),$28
293C: C3 E7 68    jp   $866F
293F: DD 36 50 00 ld   (ix+$14),$00
2943: C9          ret
2944: DD 36 50 00 ld   (ix+$14),$00
2948: DD 36 51 06 ld   (ix+$15),$60
294C: C9          ret
294D: C9          ret
294E: DD 36 50 00 ld   (ix+$14),$00
2952: C9          ret
2953: DD 36 50 00 ld   (ix+$14),$00
2957: DD 36 70 00 ld   (ix+$16),$00
295B: C9          ret
295C: DD 36 20 0C ld   (ix+$02),$C0
2960: DD 36 50 00 ld   (ix+$14),$00
2964: DD 36 51 04 ld   (ix+$15),$40
2968: DD 7E 21    ld   a,(ix+$03)
296B: C6 9E       add  a,$F8
296D: DD 77 61    ld   (ix+$07),a
2970: C9          ret
2971: DD 36 50 01 ld   (ix+$14),$01
2975: DD 36 51 A0 ld   (ix+$15),$0A
2979: DD 36 71 01 ld   (ix+$17),$01
297D: C9          ret
297E: DD 36 50 01 ld   (ix+$14),$01
2982: DD 36 51 A0 ld   (ix+$15),$0A
2986: DD 36 71 00 ld   (ix+$17),$00
298A: C9          ret
298B: DD 36 20 0C ld   (ix+$02),$C0
298F: DD 36 50 01 ld   (ix+$14),$01
2993: DD 36 51 01 ld   (ix+$15),$01
2997: DD 36 80 40 ld   (ix+$08),$04
299B: C9          ret
299C: 21 DA 0E    ld   hl,$E0BC
299F: 34          inc  (hl)
29A0: DD 7E 21    ld   a,(ix+$03)
29A3: 47          ld   b,a
29A4: E6 1E       and  $F0
29A6: DD 77 21    ld   (ix+$03),a
29A9: 78          ld   a,b
29AA: E6 E1       and  $0F
29AC: 87          add  a,a
29AD: 87          add  a,a
29AE: 87          add  a,a
29AF: 87          add  a,a
29B0: DD 77 01    ld   (ix+$01),a
29B3: DD 36 E1 00 ld   (ix+$0f),$00
29B7: CD 9B 51    call $15B9
29BA: DD 36 50 00 ld   (ix+$14),$00
29BE: C9          ret
29BF: DD 36 20 0C ld   (ix+$02),$C0
29C3: DD 36 50 00 ld   (ix+$14),$00
29C7: DD 36 70 00 ld   (ix+$16),$00
29CB: C9          ret
29CC: DD 36 20 00 ld   (ix+$02),$00
29D0: DD 36 50 00 ld   (ix+$14),$00
29D4: DD 36 70 21 ld   (ix+$16),$03
29D8: DD 36 90 00 ld   (ix+$18),$00
29DC: C9          ret
29DD: DD 36 50 00 ld   (ix+$14),$00
29E1: C9          ret
29E2: DD 36 50 00 ld   (ix+$14),$00
29E6: CD E7 68    call $866F
29E9: C9          ret
29EA: DD 36 50 01 ld   (ix+$14),$01
29EE: DD 36 51 04 ld   (ix+$15),$40
29F2: DD 36 70 00 ld   (ix+$16),$00
29F6: CD E7 68    call $866F
29F9: C9          ret
29FA: DD 36 50 00 ld   (ix+$14),$00
29FE: DD 36 70 1E ld   (ix+$16),$F0
2A02: DD 36 71 00 ld   (ix+$17),$00
2A06: DD 36 90 00 ld   (ix+$18),$00
2A0A: CD E7 68    call $866F
2A0D: C9          ret
2A0E: 01 20 20    ld   bc,$0202
2A11: 21 01 81    ld   hl,$0901
2A14: 01 50 30    ld   bc,$1214
2A17: 41          ld   b,c
2A18: 80          add  a,b
2A19: 61          ld   h,c
2A1A: 01 01 01    ld   bc,$0101
2A1D: 41          ld   b,c
2A1E: 01 81 40    ld   bc,$0409
2A21: 50          ld   d,b
2A22: 30 21       jr   nc,$2A27
2A24: 01 40 01    ld   bc,$0104
2A27: 41          ld   b,c
2A28: E0          ret  po
2A29: E0          ret  po
2A2A: 60          ld   h,b
2A2B: C1          pop  bc
2A2C: 10 41       djnz $2A33
2A2E: 01 40 50    ld   bc,$1404
2A31: 20 81       jr   nz,$2A3C
2A33: 80          add  a,b
2A34: 01 E0 10    ld   bc,$100E
2A37: 21 41 60    ld   hl,$0605
2A3A: 40          ld   b,b
2A3B: 60          ld   h,b
2A3C: 01 01 DD    ld   bc,$DD01
2A3F: 21 00 4F    ld   hl,$E500
2A42: 06 80       ld   b,$08
2A44: C5          push bc
2A45: DD 7E 00    ld   a,(ix+$00)
2A48: A7          and  a
2A49: 28 10       jr   z,$2A5B
2A4B: DD 66 B1    ld   h,(ix+$1b)
2A4E: DD 6E D0    ld   l,(ix+$1c)
2A51: E5          push hl
2A52: FD E1       pop  iy
2A54: FE FF       cp   $FF
2A56: 38 C0       jr   c,$2A64
2A58: CD E7 A2    call $2A6F
2A5B: 11 02 00    ld   de,$0020
2A5E: DD 19       add  ix,de
2A60: C1          pop  bc
2A61: 10 0F       djnz $2A44
2A63: C9          ret
2A64: FE FE       cp   $FE
2A66: CA B5 A2    jp   z,$2A5B
2A69: CD 3D A2    call $2AD3
2A6C: C3 B5 A2    jp   $2A5B
2A6F: DD 7E 31    ld   a,(ix+$13)
2A72: F7          rst  $30
2A73: 3B          dec  sp
2A74: B1          or   c
2A75: 5E          ld   e,(hl)
2A76: D0          ret  nc
2A77: 27          daa
2A78: D1          pop  de
2A79: 7B          ld   a,e
2A7A: D1          pop  de
2A7B: 4D          ld   c,l
2A7C: F1          pop  af
2A7D: 7D          ld   a,l
2A7E: 02          ld   (bc),a
2A7F: 8B          adc  a,e
2A80: 22 31 23    ld   ($2313),hl
2A83: 31 23 30    ld   sp,$1223
2A86: 23          inc  hl
2A87: 50          ld   d,b
2A88: 23          inc  hl
2A89: FA 43 98    jp   m,$9825
2A8C: 43          ld   b,e
2A8D: A3          and  e
2A8E: 43          ld   b,e
2A8F: 82          add  a,d
2A90: 42          ld   b,d
2A91: C8          ret  z
2A92: B2          or   d
2A93: C8          ret  z
2A94: B2          or   d
2A95: C8          ret  z
2A96: B2          or   d
2A97: 1E 91       ld   e,$19
2A99: CA 93 CB    jp   z,$AD39
2A9C: 93          sub  e
2A9D: 98          sbc  a,b
2A9E: 92          sub  d
2A9F: 99          sbc  a,c
2AA0: 92          sub  d
2AA1: 23          inc  hl
2AA2: 92          sub  d
2AA3: 0C          inc  c
2AA4: 73          ld   (hl),e
2AA5: 6B          ld   l,e
2AA6: 72          ld   (hl),d
2AA7: 36 72       ld   (hl),$36
2AA9: 64          ld   h,h
2AAA: 72          ld   (hl),d
2AAB: 25          dec  h
2AAC: 72          ld   (hl),d
2AAD: 43          ld   b,e
2AAE: 72          ld   (hl),d
2AAF: 63          ld   h,e
2AB0: 72          ld   (hl),d
2AB1: AC          xor  h
2AB2: 52          ld   d,d
2AB3: 8D          adc  a,l
2AB4: 52          ld   d,d
2AB5: 96          sub  (hl)
2AB6: 13          inc  de
2AB7: B3          or   e
2AB8: 13          inc  de
2AB9: 38 12       jr   c,$2AEB
2ABB: 19          add  hl,de
2ABC: 12          ld   (de),a
2ABD: 40          ld   b,b
2ABE: 12          ld   (de),a
2ABF: 42          ld   b,d
2AC0: 12          ld   (de),a
2AC1: 6B          ld   l,e
2AC2: E2 9E B0    jp   po,$1AF8
2AC5: 2D          dec  l
2AC6: 32 82 C3    ld   ($2D28),a
2AC9: 98          sbc  a,b
2ACA: 90          sub  b
2ACB: D8          ret  c
2ACC: 91          sub  c
2ACD: 1D          dec  e
2ACE: 91          sub  c
2ACF: 82          add  a,d
2AD0: 42          ld   b,d
2AD1: 87          add  a,a
2AD2: 90          sub  b
2AD3: CD C9 B2    call $3A8D
2AD6: DD 7E 31    ld   a,(ix+$13)
2AD9: F7          rst  $30
2ADA: B2          or   d
2ADB: A3          and  e
2ADC: 8D          adc  a,l
2ADD: A3          and  e
2ADE: 1E A3       ld   e,$2B
2AE0: 31 C2 46    ld   sp,$642C
2AE3: C2 46 C2    jp   nz,$2C64
2AE6: C8          ret  z
2AE7: C2 31 23    jp   nz,$2313
2AEA: 31 23 C9    ld   sp,$8D23
2AED: C2 58 C2    jp   nz,$2C94
2AF0: 9B          sbc  a,e
2AF1: C2 FC C2    jp   nz,$2CDE
2AF4: FC C2 FC    call m,$DE2C
2AF7: C2 D1 C3    jp   nz,$2D1D
2AFA: D1          pop  de
2AFB: C3 D1 C3    jp   $2D1D
2AFE: D1          pop  de
2AFF: C3 D1 C3    jp   $2D1D
2B02: D1          pop  de
2B03: C3 D1 C3    jp   $2D1D
2B06: D1          pop  de
2B07: C3 D1 C3    jp   $2D1D
2B0A: D1          pop  de
2B0B: C3 F0 C3    jp   $2D1E
2B0E: 43          ld   b,e
2B0F: C3 43 C3    jp   $2D25
2B12: 43          ld   b,e
2B13: C3 43 C3    jp   $2D25
2B16: 46          ld   b,(hl)
2B17: C2 B2 A3    jp   nz,$2B3A
2B1A: B2          or   d
2B1B: A3          and  e
2B1C: B2          or   d
2B1D: A3          and  e
2B1E: B2          or   d
2B1F: A3          and  e
2B20: B2          or   d
2B21: A3          and  e
2B22: B2          or   d
2B23: A3          and  e
2B24: B2          or   d
2B25: A3          and  e
2B26: B2          or   d
2B27: A3          and  e
2B28: B2          or   d
2B29: A3          and  e
2B2A: B2          or   d
2B2B: A3          and  e
2B2C: B2          or   d
2B2D: A3          and  e
2B2E: F0          ret  p
2B2F: C3 B2 A3    jp   $2B3A
2B32: B2          or   d
2B33: A3          and  e
2B34: B2          or   d
2B35: A3          and  e
2B36: FC C2 B2    call m,$3A2C
2B39: A3          and  e
2B3A: DD 7E 00    ld   a,(ix+$00)
2B3D: FE F3       cp   $3F
2B3F: CC 74 A3    call z,$2B56
2B42: DD 35 51    dec  (ix+$15)
2B45: CA 6B B2    jp   z,$3AA7
2B48: 21 E7 A3    ld   hl,$2B6F
2B4B: 0F          rrca
2B4C: 0F          rrca
2B4D: E6 21       and  $03
2B4F: DF          rst  $18                   ; call ADD_A_TO_HL
2B50: 5E          ld   e,(hl)
2B51: 16 00       ld   d,$00
2B53: C3 9C D0    jp   $1CD8
2B56: CD 98 68    call $8698
2B59: DD 36 00 01 ld   (ix+$00),$01
2B5D: DD 36 51 10 ld   (ix+$15),$10
2B61: DD 7E 41    ld   a,(ix+$05)
2B64: C6 21       add  a,$03
2B66: DD 77 41    ld   (ix+$05),a
2B69: 16 41       ld   d,$05
2B6B: 1E 41       ld   e,$05
2B6D: FF          rst  $38
2B6E: C9          ret
2B6F: 48          ld   c,b
2B70: C8          ret  z
2B71: 29          add  hl,hl
2B72: 97          sub  a
2B73: DD 7E 51    ld   a,(ix+$15)
2B76: 0F          rrca
2B77: 0F          rrca
2B78: 0F          rrca
2B79: E6 F1       and  $1F
2B7B: C3 69 A3    jp   $2B87
2B7E: DD 7E 51    ld   a,(ix+$15)
2B81: 0F          rrca
2B82: 0F          rrca
2B83: 0F          rrca
2B84: 0F          rrca
2B85: E6 E1       and  $0F
2B87: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
2B88: DD 46 40    ld   b,(ix+$04)
2B8B: DD 4E 41    ld   c,(ix+$05)
2B8E: 1A          ld   a,(de)
2B8F: 13          inc  de
2B90: 08          ex   af,af'
2B91: 1A          ld   a,(de)
2B92: 13          inc  de
2B93: D9          exx
2B94: 4F          ld   c,a
2B95: 08          ex   af,af'
2B96: 47          ld   b,a
2B97: 11 40 00    ld   de,$0004
2B9A: D9          exx
2B9B: 1A          ld   a,(de)
2B9C: E6 1E       and  $F0
2B9E: DD 86 21    add  a,(ix+$03)
2BA1: FD 77 20    ld   (iy+$02),a
2BA4: 1A          ld   a,(de)
2BA5: 13          inc  de
2BA6: 87          add  a,a
2BA7: 87          add  a,a
2BA8: 87          add  a,a
2BA9: 87          add  a,a
2BAA: 6F          ld   l,a
2BAB: 26 00       ld   h,$00
2BAD: 07          rlca
2BAE: CB 14       rl   h
2BB0: 09          add  hl,bc
2BB1: FD 75 21    ld   (iy+$03),l
2BB4: 7C          ld   a,h
2BB5: E6 01       and  $01
2BB7: D9          exx
2BB8: 81          add  a,c
2BB9: FD 77 01    ld   (iy+$01),a
2BBC: D9          exx
2BBD: 1A          ld   a,(de)
2BBE: 13          inc  de
2BBF: FD 77 00    ld   (iy+$00),a
2BC2: D9          exx
2BC3: FD 19       add  iy,de
2BC5: 10 3D       djnz $2B9A
2BC7: D9          exx
2BC8: C9          ret
2BC9: DD 7E 00    ld   a,(ix+$00)
2BCC: FE F3       cp   $3F
2BCE: 28 51       jr   z,$2BE5
2BD0: DD 35 00    dec  (ix+$00)
2BD3: CA 6B B2    jp   z,$3AA7
2BD6: DD 7E 00    ld   a,(ix+$00)
2BD9: 21 82 C2    ld   hl,$2C28
2BDC: 0F          rrca
2BDD: 0F          rrca
2BDE: 0F          rrca
2BDF: E6 21       and  $03
2BE1: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
2BE2: C3 88 A3    jp   $2B88
2BE5: DD 35 00    dec  (ix+$00)
2BE8: 16 41       ld   d,$05
2BEA: 1E 80       ld   e,$08
2BEC: FF          rst  $38
2BED: C3 CA 68    jp   $86AC
2BF0: DD 7E 00    ld   a,(ix+$00)
2BF3: FE F3       cp   $3F
2BF5: 28 C0       jr   z,$2C03
2BF7: DD 35 00    dec  (ix+$00)
2BFA: CA 6B B2    jp   z,$3AA7
2BFD: 11 24 C2    ld   de,$2C42
2C00: C3 88 A3    jp   $2B88
2C03: DD 35 00    dec  (ix+$00)
2C06: 21 DA 0E    ld   hl,$E0BC
2C09: 35          dec  (hl)
2C0A: CD 98 68    call $8698
2C0D: 16 41       ld   d,$05
2C0F: 1E 80       ld   e,$08
2C11: FF          rst  $38
2C12: C9          ret
2C13: DD 7E 00    ld   a,(ix+$00)
2C16: FE F3       cp   $3F
2C18: 28 B2       jr   z,$2C54
2C1A: DD 35 51    dec  (ix+$15)
2C1D: CA 6B B2    jp   z,$3AA7
2C20: 21 84 C2    ld   hl,$2C48
2C23: 0E 02       ld   c,$20
2C25: C3 D4 51    jp   $155C
2C28: 12          ld   (de),a
2C29: C2 D2 C2    jp   nz,$2C3C
2C2C: 72          ld   (hl),d
2C2D: C2 D2 C2    jp   nz,$2C3C
2C30: 20 00       jr   nz,$2C32
2C32: 01 2F 00    ld   bc,$00E3
2C35: AF          xor  a
2C36: 20 00       jr   nz,$2C38
2C38: 01 4E 00    ld   bc,$00E4
2C3B: CE 20       adc  a,$02
2C3D: 00          nop
2C3E: 01 4F 00    ld   bc,$00E5
2C41: CF          rst  $08
2C42: 20 04       jr   nz,$2C84
2C44: 1E 74       ld   e,$56
2C46: 00          nop
2C47: 75          ld   (hl),l
2C48: 14          inc  d
2C49: C2 14 C2    jp   nz,$2C50
2C4C: 14          inc  d
2C4D: C2 14 C2    jp   nz,$2C50
2C50: 20 16       jr   nz,$2CC2
2C52: 17          rla
2C53: 96          sub  (hl)
2C54: CD 98 68    call $8698
2C57: DD 35 00    dec  (ix+$00)
2C5A: DD 36 51 02 ld   (ix+$15),$20
2C5E: 16 41       ld   d,$05
2C60: 1E 41       ld   e,$05
2C62: FF          rst  $38
2C63: C9          ret
2C64: DD 7E 90    ld   a,(ix+$18)
2C67: A7          and  a
2C68: 28 30       jr   z,$2C7C
2C6A: CD 47 68    call $8665
2C6D: 16 41       ld   d,$05
2C6F: 1E 80       ld   e,$08
2C71: FF          rst  $38
2C72: CD 6B B2    call $3AA7
2C75: DD 36 00 FF ld   (ix+$00),$FF
2C79: C3 83 72    jp   $3629
2C7C: CD 47 68    call $8665
2C7F: DD 34 90    inc  (ix+$18)
2C82: DD 36 00 FF ld   (ix+$00),$FF
2C86: 16 41       ld   d,$05
2C88: 1E 41       ld   e,$05
2C8A: FF          rst  $38
2C8B: C9          ret
2C8C: C9          ret
2C8D: CD 06 68    call $8660
2C90: CD F7 68    call $867F
2C93: C9          ret
2C94: CD 06 68    call $8660
2C97: CD F7 68    call $867F
2C9A: 16 41       ld   d,$05
2C9C: 1E 41       ld   e,$05
2C9E: FF          rst  $38
2C9F: DD 7E 21    ld   a,(ix+$03)
2CA2: C6 90       add  a,$18
2CA4: DD 77 21    ld   (ix+$03),a
2CA7: DD 7E 41    ld   a,(ix+$05)
2CAA: C6 80       add  a,$08
2CAC: DD 77 41    ld   (ix+$05),a
2CAF: CD 6B B2    call $3AA7
2CB2: DD 36 00 FF ld   (ix+$00),$FF
2CB6: C3 83 72    jp   $3629
2CB9: CD 06 68    call $8660
2CBC: CD F7 68    call $867F
2CBF: DD 7E 21    ld   a,(ix+$03)
2CC2: C6 80       add  a,$08
2CC4: DD 77 21    ld   (ix+$03),a
2CC7: DD 7E 41    ld   a,(ix+$05)
2CCA: C6 10       add  a,$10
2CCC: DD 77 41    ld   (ix+$05),a
2CCF: CD 6B B2    call $3AA7
2CD2: 16 41       ld   d,$05
2CD4: 1E 80       ld   e,$08
2CD6: FF          rst  $38
2CD7: DD 36 00 FF ld   (ix+$00),$FF
2CDB: C3 83 72    jp   $3629
2CDE: DD 7E 00    ld   a,(ix+$00)
2CE1: FE F3       cp   $3F
2CE3: 28 82       jr   z,$2D0D
2CE5: 21 DF C2    ld   hl,$2CFD
2CE8: DD 7E B0    ld   a,(ix+$1a)
2CEB: A7          and  a
2CEC: 28 21       jr   z,$2CF1
2CEE: 21 41 C3    ld   hl,$2D05
2CF1: DD 35 51    dec  (ix+$15)
2CF4: CA 6B B2    jp   z,$3AA7
2CF7: DD 7E 51    ld   a,(ix+$15)
2CFA: C3 3C D0    jp   $1CD2
2CFD: 29          add  hl,hl
2CFE: 00          nop
2CFF: C8          ret  z
2D00: 00          nop
2D01: 48          ld   c,b
2D02: 00          nop
2D03: 97          sub  a
2D04: 00          nop
2D05: 56          ld   d,(hl)
2D06: 10 F3       djnz $2D47
2D08: 10 B7       djnz $2D85
2D0A: 10 97       djnz $2D85
2D0C: 10 CD       djnz $2CDB
2D0E: 98          sbc  a,b
2D0F: 68          ld   l,b
2D10: 16 41       ld   d,$05
2D12: 1E 20       ld   e,$02
2D14: FF          rst  $38
2D15: DD 35 00    dec  (ix+$00)
2D18: DD 36 51 02 ld   (ix+$15),$20
2D1C: C9          ret
2D1D: C9          ret
2D1E: CD F7 68    call $867F
2D21: CD 06 68    call $8660
2D24: C9          ret
2D25: C3 6B B2    jp   $3AA7
2D28: CD F8 72    call $369E
2D2B: DD 7E 41    ld   a,(ix+$05)
2D2E: A7          and  a
2D2F: CA 6B B2    jp   z,$3AA7
2D32: CD 96 C3    call $2D78
2D35: DD 7E 50    ld   a,(ix+$14)
2D38: 47          ld   b,a
2D39: E6 21       and  $03
2D3B: FE 20       cp   $02
2D3D: 28 70       jr   z,$2D55
2D3F: 21 C6 73    ld   hl,$376C
2D42: CB 50       bit  2,b
2D44: 28 21       jr   z,$2D49
2D46: 21 F5 E2    ld   hl,$2E5F
2D49: DD 7E 51    ld   a,(ix+$15)
2D4C: 0F          rrca
2D4D: 0F          rrca
2D4E: 0F          rrca
2D4F: E6 01       and  $01
2D51: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
2D52: C3 86 C3    jp   $2D68
2D55: 21 88 73    ld   hl,$3788
2D58: CB 50       bit  2,b
2D5A: 28 21       jr   z,$2D5F
2D5C: 21 B7 E2    ld   hl,$2E7B
2D5F: DD 7E 51    ld   a,(ix+$15)
2D62: 0F          rrca
2D63: 0F          rrca
2D64: 0F          rrca
2D65: E6 21       and  $03
2D67: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
2D68: DD 7E 40    ld   a,(ix+$04)
2D6B: F5          push af
2D6C: DD CB 40 68 res  0,(ix+$04)
2D70: CD 88 A3    call $2B88
2D73: F1          pop  af
2D74: DD 77 40    ld   (ix+$04),a
2D77: C9          ret
2D78: DD 35 51    dec  (ix+$15)
2D7B: CA DC C3    jp   z,$2DDC
2D7E: DD 7E 50    ld   a,(ix+$14)
2D81: E6 21       and  $03
2D83: F7          rst  $30
2D84: C8          ret  z
2D85: C3 C8 C3    jp   $2D8C
2D88: CB C3       set  0,e
2D8A: C8          ret  z
2D8B: C3 DD 56    jp   $74DD
2D8E: E1          pop  hl
2D8F: DD 5E 10    ld   e,(ix+$10)
2D92: DD 66 A1    ld   h,(ix+$0b)
2D95: DD 6E C0    ld   l,(ix+$0c)
2D98: 19          add  hl,de
2D99: DD 74 A1    ld   (ix+$0b),h
2D9C: DD 75 C0    ld   (ix+$0c),l
2D9F: DD 56 21    ld   d,(ix+$03)
2DA2: DD 5E 40    ld   e,(ix+$04)
2DA5: 19          add  hl,de
2DA6: DD 74 21    ld   (ix+$03),h
2DA9: DD 75 40    ld   (ix+$04),l
2DAC: C9          ret
2DAD: DD CB 50 74 bit  2,(ix+$14)
2DB1: 28 E0       jr   z,$2DC1
2DB3: DD 7E 51    ld   a,(ix+$15)
2DB6: FE 01       cp   $01
2DB8: C0          ret  nz
2DB9: CD 96 50    call $1478
2DBC: DD 36 51 02 ld   (ix+$15),$20
2DC0: C9          ret
2DC1: 3A 41 0F    ld   a,($E105)
2DC4: 47          ld   b,a
2DC5: DD 7E 41    ld   a,(ix+$05)
2DC8: 90          sub  b
2DC9: FE 12       cp   $30
2DCB: DA 22 E2    jp   c,$2E22
2DCE: DD 7E 51    ld   a,(ix+$15)
2DD1: FE 01       cp   $01
2DD3: C0          ret  nz
2DD4: CD 96 50    call $1478
2DD7: DD 36 51 02 ld   (ix+$15),$20
2DDB: C9          ret
2DDC: DD 7E 50    ld   a,(ix+$14)
2DDF: 47          ld   b,a
2DE0: E6 21       and  $03
2DE2: FE 20       cp   $02
2DE4: C8          ret  z
2DE5: DD 34 50    inc  (ix+$14)
2DE8: 78          ld   a,b
2DE9: F7          rst  $30
2DEA: 52          ld   d,d
2DEB: E2 50 E2    jp   po,$2E14
2DEE: 22 E2 9E    ld   ($F82E),hl
2DF1: C3 93 E2    jp   $2E39
2DF4: 50          ld   d,b
2DF5: E2 B3 E2    jp   po,$2E3B
2DF8: DD 36 21 00 ld   (ix+$03),$00
2DFC: 21 04 01    ld   hl,$0140
2DFF: DD 74 A1    ld   (ix+$0b),h
2E02: DD 75 C0    ld   (ix+$0c),l
2E05: DD 7E 41    ld   a,(ix+$05)
2E08: C6 10       add  a,$10
2E0A: DD 77 41    ld   (ix+$05),a
2E0D: CD E7 68    call $866F
2E10: 3E 21       ld   a,$03
2E12: 18 63       jr   $2E3B
2E14: 21 00 00    ld   hl,$0000
2E17: DD 74 A1    ld   (ix+$0b),h
2E1A: DD 75 C0    ld   (ix+$0c),l
2E1D: DD 36 51 02 ld   (ix+$15),$20
2E21: C9          ret
2E22: 21 00 00    ld   hl,$0000
2E25: DD 74 A1    ld   (ix+$0b),h
2E28: DD 75 C0    ld   (ix+$0c),l
2E2B: DD 36 50 21 ld   (ix+$14),$03
2E2F: 3E 20       ld   a,$02
2E31: C3 B3 E2    jp   $2E3B
2E34: 3E 00       ld   a,$00
2E36: C3 B3 E2    jp   $2E3B
2E39: 3E 40       ld   a,$04
2E3B: 21 14 E2    ld   hl,$2E50
2E3E: 47          ld   b,a
2E3F: 87          add  a,a
2E40: 80          add  a,b
2E41: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
2E42: DD 77 51    ld   (ix+$15),a
2E45: 23          inc  hl
2E46: 5E          ld   e,(hl)
2E47: 23          inc  hl
2E48: 56          ld   d,(hl)
2E49: DD 72 E1    ld   (ix+$0f),d
2E4C: DD 73 10    ld   (ix+$10),e
2E4F: C9          ret
2E50: 92          sub  d
2E51: 41          ld   b,c
2E52: 00          nop
2E53: 02          ld   (bc),a
2E54: 00          nop
2E55: 00          nop
2E56: C6 BE       add  a,$FA
2E58: FF          rst  $38
2E59: C4 00 00    call nz,$0000
2E5C: 02          ld   (bc),a
2E5D: 7E          ld   a,(hl)
2E5E: FF          rst  $38
2E5F: 27          daa
2E60: E2 E7 E2    jp   po,$2E6F
2E63: 41          ld   b,c
2E64: 94          sub  h
2E65: 01 06 1F    ld   bc,$F160
2E68: FF          rst  $38
2E69: 10 86       djnz $2ED3
2E6B: 00          nop
2E6C: 87          add  a,a
2E6D: 1E A6       ld   e,$6A
2E6F: 41          ld   b,c
2E70: 94          sub  h
2E71: 01 A7 1F    ld   bc,$F16B
2E74: FF          rst  $38
2E75: 10 07       djnz $2ED8
2E77: 00          nop
2E78: 26 1E       ld   h,$F0
2E7A: 27          daa
2E7B: 29          add  hl,hl
2E7C: E2 E9 E2    jp   po,$2E8F
2E7F: B9          cp   c
2E80: E2 29 E2    jp   po,$2E83
2E83: 41          ld   b,c
2E84: 94          sub  h
2E85: 01 16 1F    ld   bc,$F170
2E88: 17          rla
2E89: 10 86       djnz $2EF3
2E8B: 00          nop
2E8C: 96          sub  (hl)
2E8D: 1E 97       ld   e,$79
2E8F: 41          ld   b,c
2E90: 94          sub  h
2E91: 01 36 1F    ld   bc,$F172
2E94: 37          scf
2E95: 10 86       djnz $2EFF
2E97: 00          nop
2E98: B6          or   (hl)
2E99: 1E 97       ld   e,$79
2E9B: 41          ld   b,c
2E9C: 94          sub  h
2E9D: 01 46 1F    ld   bc,$F164
2EA0: 47          ld   b,a
2EA1: 10 86       djnz $2F0B
2EA3: 00          nop
2EA4: C6 1E       add  a,$F0
2EA6: 97          sub  a
2EA7: 21 55 0E    ld   hl,$E055
2EAA: 34          inc  (hl)
2EAB: CD C9 B2    call $3A8D
2EAE: CD 49 E3    call $2F85
2EB1: CD 4C E2    call $2EC4
2EB4: 11 4E E3    ld   de,$2FE4
2EB7: DD 7E 71    ld   a,(ix+$17)
2EBA: A7          and  a
2EBB: CA 88 A3    jp   z,$2B88
2EBE: 11 5E E3    ld   de,$2FF4
2EC1: C3 88 A3    jp   $2B88
2EC4: DD 7E 40    ld   a,(ix+$04)
2EC7: A7          and  a
2EC8: 20 95       jr   nz,$2F23
2ECA: 21 75 E3    ld   hl,$2F57
2ECD: DD 7E 71    ld   a,(ix+$17)
2ED0: A7          and  a
2ED1: 28 21       jr   z,$2ED6
2ED3: 21 37 E3    ld   hl,$2F73
2ED6: DD 7E 80    ld   a,(ix+$08)
2ED9: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
2EDA: CD 9C D0    call $1CD8
2EDD: 11 40 00    ld   de,$0004
2EE0: FD 19       add  iy,de
2EE2: DD 46 21    ld   b,(ix+$03)
2EE5: DD 4E 41    ld   c,(ix+$05)
2EE8: C5          push bc
2EE9: 21 13 E3    ld   hl,$2F31
2EEC: DD 7E 71    ld   a,(ix+$17)
2EEF: A7          and  a
2EF0: 28 21       jr   z,$2EF5
2EF2: 21 B3 E3    ld   hl,$2F3B
2EF5: DD 7E 80    ld   a,(ix+$08)
2EF8: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
2EF9: 78          ld   a,b
2EFA: 83          add  a,e
2EFB: DD 77 21    ld   (ix+$03),a
2EFE: 79          ld   a,c
2EFF: 82          add  a,d
2F00: DD 77 41    ld   (ix+$05),a
2F03: 21 C5 E3    ld   hl,$2F4D
2F06: DD 7E 71    ld   a,(ix+$17)
2F09: A7          and  a
2F0A: 28 21       jr   z,$2F0F
2F0C: 21 07 E3    ld   hl,$2F61
2F0F: DD 7E 80    ld   a,(ix+$08)
2F12: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
2F13: CD 9C D0    call $1CD8
2F16: 11 40 00    ld   de,$0004
2F19: FD 19       add  iy,de
2F1B: C1          pop  bc
2F1C: DD 70 21    ld   (ix+$03),b
2F1F: DD 71 41    ld   (ix+$05),c
2F22: C9          ret
2F23: FD 36 20 00 ld   (iy+$02),$00
2F27: FD 36 60 00 ld   (iy+$06),$00
2F2B: 11 80 00    ld   de,$0008
2F2E: FD 19       add  iy,de
2F30: C9          ret
2F31: BE          cp   (hl)
2F32: BE          cp   (hl)
2F33: BE          cp   (hl)
2F34: BE          cp   (hl)
2F35: BE          cp   (hl)
2F36: BE          cp   (hl)
2F37: DE BE       sbc  a,$FA
2F39: DE BE       sbc  a,$FA
2F3B: 60          ld   h,b
2F3C: BE          cp   (hl)
2F3D: 60          ld   h,b
2F3E: BE          cp   (hl)
2F3F: 60          ld   h,b
2F40: BE          cp   (hl)
2F41: 40          ld   b,b
2F42: BE          cp   (hl)
2F43: 40          ld   b,b
2F44: BE          cp   (hl)
2F45: 40          ld   b,b
2F46: BE          cp   (hl)
2F47: 60          ld   h,b
2F48: BE          cp   (hl)
2F49: 60          ld   h,b
2F4A: BE          cp   (hl)
2F4B: 60          ld   h,b
2F4C: BE          cp   (hl)
2F4D: 76          halt
2F4E: 08          ex   af,af'
2F4F: 76          halt
2F50: 08          ex   af,af'
2F51: 57          ld   d,a
2F52: 08          ex   af,af'
2F53: D7          rst  $10
2F54: 08          ex   af,af'
2F55: D7          rst  $10
2F56: 08          ex   af,af'
2F57: E5          push hl
2F58: 18 E5       jr   $2FA9
2F5A: 18 35       jr   $2FAF
2F5C: 18 B5       jr   $2FB9
2F5E: 18 B5       jr   $2FBB
2F60: 18 76       jr   $2FD8
2F62: 88          adc  a,b
2F63: 76          halt
2F64: 88          adc  a,b
2F65: 57          ld   d,a
2F66: 88          adc  a,b
2F67: D7          rst  $10
2F68: 88          adc  a,b
2F69: D7          rst  $10
2F6A: 88          adc  a,b
2F6B: D7          rst  $10
2F6C: 88          adc  a,b
2F6D: 57          ld   d,a
2F6E: 88          adc  a,b
2F6F: 76          halt
2F70: 88          adc  a,b
2F71: 76          halt
2F72: 88          adc  a,b
2F73: E5          push hl
2F74: 98          sbc  a,b
2F75: E5          push hl
2F76: 98          sbc  a,b
2F77: 35          dec  (hl)
2F78: 98          sbc  a,b
2F79: B5          or   l
2F7A: 98          sbc  a,b
2F7B: B5          or   l
2F7C: 98          sbc  a,b
2F7D: B5          or   l
2F7E: 98          sbc  a,b
2F7F: 35          dec  (hl)
2F80: 98          sbc  a,b
2F81: E5          push hl
2F82: 98          sbc  a,b
2F83: E5          push hl
2F84: 98          sbc  a,b
2F85: DD 7E 40    ld   a,(ix+$04)
2F88: A7          and  a
2F89: 20 98       jr   nz,$2F23
2F8B: 3A 20 0E    ld   a,($E002)
2F8E: E6 61       and  $07
2F90: C0          ret  nz
2F91: CD 2E C6    call $6CE2
2F94: CB 7F       bit  7,a
2F96: C8          ret  z
2F97: DD 77 20    ld   (ix+$02),a
2F9A: C6 80       add  a,$08
2F9C: 0F          rrca
2F9D: 0F          rrca
2F9E: 0F          rrca
2F9F: 0F          rrca
2FA0: E6 61       and  $07
2FA2: 47          ld   b,a
2FA3: DD 7E 71    ld   a,(ix+$17)
2FA6: A7          and  a
2FA7: 28 81       jr   z,$2FB2
2FA9: 78          ld   a,b
2FAA: FE 40       cp   $04
2FAC: D8          ret  c
2FAD: 21 5C E3    ld   hl,$2FD4
2FB0: 18 61       jr   $2FB9
2FB2: 78          ld   a,b
2FB3: FE 41       cp   $05
2FB5: D0          ret  nc
2FB6: 21 2C E3    ld   hl,$2FC2
2FB9: DD 77 80    ld   (ix+$08),a
2FBC: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
2FBD: 63          ld   h,e
2FBE: 6A          ld   l,d
2FBF: C3 DF 39    jp   $93FD
2FC2: 1E 7E       ld   e,$F6
2FC4: 1E 7E       ld   e,$F6
2FC6: 5E          ld   e,(hl)
2FC7: 3F          ccf
2FC8: 9E          sbc  a,(hl)
2FC9: 3E 9E       ld   a,$F8
2FCB: 3E A0       ld   a,$0A
2FCD: E0          ret  po
2FCE: A0          and  b
2FCF: E0          ret  po
2FD0: A0          and  b
2FD1: E0          ret  po
2FD2: A0          and  b
2FD3: E0          ret  po
2FD4: A0          and  b
2FD5: E0          ret  po
2FD6: A0          and  b
2FD7: E0          ret  po
2FD8: A0          and  b
2FD9: E0          ret  po
2FDA: A0          and  b
2FDB: E0          ret  po
2FDC: 80          add  a,b
2FDD: 3E 80       ld   a,$08
2FDF: 3E C0       ld   a,$0C
2FE1: 3F          ccf
2FE2: 10 7E       djnz $2FDA
2FE4: 61          ld   h,c
2FE5: 18 1E       jr   $2FD7
2FE7: E4 1F C4    call po,$4CF1
2FEA: 01 C5 3E    ld   bc,$F24D
2FED: 44          ld   b,h
2FEE: 20 45       jr   nz,$3035
2FF0: 21 64 31    ld   hl,$1346
2FF3: 65          ld   h,l
2FF4: 61          ld   h,c
2FF5: 98          sbc  a,b
2FF6: 10 E4       djnz $3046
2FF8: 11 C4 01    ld   de,$014C
2FFB: C5          push bc
2FFC: 30 44       jr   nc,$3042
2FFE: 20 45       jr   nz,$3045
3000: 21 64 3F    ld   hl,$F346
3003: 65          ld   h,l
3004: CD C9 B2    call $3A8D
3007: 11 10 12    ld   de,$3010
300A: CD 88 A3    call $2B88
300D: C3 88 A3    jp   $2B88
3010: 40          ld   b,b
3011: 06 11       ld   b,$11
3013: 25          dec  h
3014: 03          inc  bc
3015: 44          ld   b,h
3016: 10 45       djnz $305D
3018: 02          ld   (bc),a
3019: E4 40 86    call po,$6804
301C: 0F          rrca
301D: 25          dec  h
301E: 1D          dec  e
301F: 44          ld   b,h
3020: 0E 45       ld   c,$45
3022: 1C          inc  e
3023: E4 3A B0    call po,$1AB2
3026: 0F          rrca
3027: A7          and  a
3028: C2 6B B2    jp   nz,$3AA7
302B: 3A D8 0E    ld   a,($E09C)
302E: A7          and  a
302F: 28 81       jr   z,$303A
3031: 21 03 10    ld   hl,$1021
3034: 11 03 10    ld   de,$1021
3037: CD 0F B0    call $1AE1
303A: CD C9 B2    call $3A8D
303D: CD B4 12    call $305A
3040: DD 7E 80    ld   a,(ix+$08)
3043: 21 A4 12    ld   hl,$304A
3046: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
3047: C3 9C D0    jp   $1CD8
304A: 2B          dec  hl
304B: 80          add  a,b
304C: 2B          dec  hl
304D: 80          add  a,b
304E: 2A 80 0B    ld   hl,($A108)
3051: 80          add  a,b
3052: 0A          ld   a,(bc)
3053: 00          nop
3054: 0B          dec  bc
3055: 00          nop
3056: 2A 00 2B    ld   hl,($A300)
3059: 00          nop
305A: 3A 20 0E    ld   a,($E002)
305D: E6 61       and  $07
305F: 47          ld   b,a
3060: DD 7E F1    ld   a,(ix+$1f)
3063: E6 61       and  $07
3065: B8          cp   b
3066: C0          ret  nz
3067: CD 2E C6    call $6CE2
306A: DD 77 20    ld   (ix+$02),a
306D: C6 61       add  a,$07
306F: 0F          rrca
3070: 0F          rrca
3071: 0F          rrca
3072: 0F          rrca
3073: E6 61       and  $07
3075: DD 77 80    ld   (ix+$08),a
3078: 21 09 12    ld   hl,$3081
307B: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
307C: 63          ld   h,e
307D: 6A          ld   l,d
307E: C3 DF 39    jp   $93FD
3081: 3E 5E       ld   a,$F4
3083: 3E 5E       ld   a,$F4
3085: 5E          ld   e,(hl)
3086: 5E          ld   e,(hl)
3087: DE 5E       sbc  a,$F4
3089: 01 5E 40    ld   bc,$04F4
308C: 5E          ld   e,(hl)
308D: C0          ret  nz
308E: 5E          ld   e,(hl)
308F: E0          ret  po
3090: 5E          ld   e,(hl)
3091: C9          ret
3092: CD BC 12    call $30DA
3095: 3A 20 0E    ld   a,($E002)
3098: 0F          rrca
3099: 0F          rrca
309A: 0F          rrca
309B: E6 01       and  $01
309D: 47          ld   b,a
309E: DD 7E 50    ld   a,(ix+$14)
30A1: 87          add  a,a
30A2: 80          add  a,b
30A3: 21 AA 12    ld   hl,$30AA
30A6: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
30A7: C3 88 A3    jp   $2B88
30AA: BA          cp   d
30AB: 12          ld   (de),a
30AC: AC          xor  h
30AD: 12          ld   (de),a
30AE: FA 12 EC    jp   m,$CE30
30B1: 12          ld   (de),a
30B2: 4C          ld   c,h
30B3: 12          ld   (de),a
30B4: 5C          ld   e,h
30B5: 12          ld   (de),a
30B6: AC          xor  h
30B7: 12          ld   (de),a
30B8: 5C          ld   e,h
30B9: 12          ld   (de),a
30BA: 01 08 00    ld   bc,$0080
30BD: 67          ld   h,a
30BE: 20 08       jr   nz,$3040
30C0: 1E E6       ld   e,$6E
30C2: 00          nop
30C3: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
30C4: 20 08       jr   nz,$3046
30C6: 1E F6       ld   e,$7E
30C8: 00          nop
30C9: F7          rst  $30
30CA: 01 1A 00    ld   bc,$00B0
30CD: 67          ld   h,a
30CE: 20 1A       jr   nz,$3080
30D0: 1E E6       ld   e,$6E
30D2: 00          nop
30D3: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
30D4: 20 1A       jr   nz,$3086
30D6: 1E F6       ld   e,$7E
30D8: 00          nop
30D9: F7          rst  $30
30DA: CD C9 B2    call $3A8D
30DD: DD 7E 41    ld   a,(ix+$05)
30E0: A7          and  a
30E1: 28 92       jr   z,$311B
30E3: 3A 00 0F    ld   a,($E100)
30E6: 3C          inc  a
30E7: C0          ret  nz
30E8: 3A 21 0F    ld   a,($E103)
30EB: DD 96 21    sub  (ix+$03)
30EE: C6 10       add  a,$10
30F0: FE 03       cp   $21
30F2: D0          ret  nc
30F3: 3A 41 0F    ld   a,($E105)
30F6: DD 96 41    sub  (ix+$05)
30F9: C6 10       add  a,$10
30FB: FE 03       cp   $21
30FD: D0          ret  nc
30FE: CD 6B 68    call $86A7
3101: DD 7E 50    ld   a,(ix+$14)
3104: 21 53 13    ld   hl,$3135
3107: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
3108: 3A 8A CF    ld   a,($EDA8)             ; read NUM_GRENADES
310B: BA          cp   d
310C: 30 70       jr   nc,$3124
310E: 83          add  a,e
310F: 27          daa
3110: 32 8A CF    ld   ($EDA8),a             ; update NUM_GRENADES 
3113: 16 A1       ld   d,$0B
3115: FF          rst  $38
3116: 16 41       ld   d,$05
3118: 1E 80       ld   e,$08
311A: FF          rst  $38
311B: DD 36 00 00 ld   (ix+$00),$00
311F: DD 36 21 00 ld   (ix+$03),$00
3123: C9          ret
3124: DD 36 00 00 ld   (ix+$00),$00
3128: DD 36 21 00 ld   (ix+$03),$00
312C: 3E 99       ld   a,$99
312E: 32 8A CF    ld   ($EDA8),a             ; set NUM_GRENADES
3131: 16 A1       ld   d,$0B
3133: FF          rst  $38
3134: C9          ret
3135: 01 98 21    ld   bc,$0398
3138: 78          ld   a,b
3139: 41          ld   b,c
313A: 58          ld   e,b
313B: CD C9 B2    call $3A8D
313E: 3A 4B 0E    ld   a,($E0A5)
3141: A7          and  a
3142: C0          ret  nz
3143: 11 C4 13    ld   de,$314C
3146: CD 88 A3    call $2B88
3149: C3 88 A3    jp   $2B88
314C: C0          ret  nz
314D: 86          add  a,(hl)
314E: 11 25 01    ld   de,$0143
3151: 44          ld   b,h
3152: 10 45       djnz $3199
3154: 00          nop
3155: E4 51 25    call po,$4315
3158: 41          ld   b,c
3159: 44          ld   b,h
315A: 50          ld   d,b
315B: 45          ld   b,l
315C: 40          ld   b,b
315D: E4 D1 25    call po,$431D
3160: C1          pop  bc
3161: 44          ld   b,h
3162: D0          ret  nc
3163: 45          ld   b,l
3164: C0          ret  nz
3165: E4 80 06    call po,$6008
3168: 05          dec  b
3169: 25          dec  h
316A: 15          dec  d
316B: 44          ld   b,h
316C: 04          inc  b
316D: 45          ld   b,l
316E: 14          inc  d
316F: E4 45 25    call po,$4345
3172: 55          ld   d,l
3173: 44          ld   b,h
3174: 44          ld   b,h
3175: 45          ld   b,l
3176: 54          ld   d,h
3177: E4 21 55    call po,$5503
317A: 0E 34       ld   c,$52
317C: CD C9 B2    call $3A8D
317F: CD 5E 13    call $31F4
3182: 11 6B 32    ld   de,$32A7
3185: DD 7E 71    ld   a,(ix+$17)
3188: E6 01       and  $01
318A: 28 21       jr   z,$318F
318C: 11 5B 32    ld   de,$32B5
318F: DD 46 40    ld   b,(ix+$04)
3192: DD 4E 41    ld   c,(ix+$05)
3195: 21 31 00    ld   hl,$0013
3198: 09          add  hl,bc
3199: DD 74 40    ld   (ix+$04),h
319C: DD 75 41    ld   (ix+$05),l
319F: C5          push bc
31A0: CD 88 A3    call $2B88
31A3: C1          pop  bc
31A4: DD 70 40    ld   (ix+$04),b
31A7: DD 71 41    ld   (ix+$05),c
31AA: DD 7E 50    ld   a,(ix+$14)
31AD: A7          and  a
31AE: CA 88 A3    jp   z,$2B88
31B1: DD 7E 70    ld   a,(ix+$16)
31B4: FE 50       cp   $14
31B6: 30 33       jr   nc,$31EB
31B8: FE A0       cp   $0A
31BA: 30 10       jr   nc,$31CC
31BC: 6F          ld   l,a
31BD: 26 00       ld   h,$00
31BF: 09          add  hl,bc
31C0: C5          push bc
31C1: DD 74 40    ld   (ix+$04),h
31C4: DD 75 41    ld   (ix+$05),l
31C7: CD 88 A3    call $2B88
31CA: 18 71       jr   $31E3
31CC: 21 60 00    ld   hl,$0006
31CF: 19          add  hl,de
31D0: EB          ex   de,hl
31D1: 6F          ld   l,a
31D2: 26 00       ld   h,$00
31D4: 09          add  hl,bc
31D5: C5          push bc
31D6: DD 74 40    ld   (ix+$04),h
31D9: DD 75 41    ld   (ix+$05),l
31DC: CD 88 A3    call $2B88
31DF: FD 36 20 00 ld   (iy+$02),$00
31E3: C1          pop  bc
31E4: DD 70 40    ld   (ix+$04),b
31E7: DD 71 41    ld   (ix+$05),c
31EA: C9          ret
31EB: FD 36 20 00 ld   (iy+$02),$00
31EF: FD 36 60 00 ld   (iy+$06),$00
31F3: C9          ret
31F4: DD 7E 40    ld   a,(ix+$04)
31F7: A7          and  a
31F8: C0          ret  nz
31F9: DD 7E 50    ld   a,(ix+$14)
31FC: A7          and  a
31FD: C2 C9 32    jp   nz,$328D
3200: 3A 20 0E    ld   a,($E002)
3203: 0F          rrca
3204: 0F          rrca
3205: E6 61       and  $07
3207: 47          ld   b,a
3208: DD 7E F1    ld   a,(ix+$1f)
320B: B8          cp   b
320C: C0          ret  nz
320D: 3A 7E 0E    ld   a,($E0F6)
3210: A7          and  a
3211: C0          ret  nz
3212: DD E5       push ix
3214: DD 4E 71    ld   c,(ix+$17)
3217: DD 66 21    ld   h,(ix+$03)
321A: DD 7E 41    ld   a,(ix+$05)
321D: C6 40       add  a,$04
321F: 6F          ld   l,a
3220: DD 21 00 6E ld   ix,$E600
3224: 11 02 00    ld   de,$0020
3227: 3A 5E 0E    ld   a,($E0F4)
322A: 47          ld   b,a
322B: DD 7E 00    ld   a,(ix+$00)
322E: A7          and  a
322F: 28 61       jr   z,$3238
3231: DD 19       add  ix,de
3233: 10 7E       djnz $322B
3235: DD E1       pop  ix
3237: C9          ret
3238: DD 36 00 FF ld   (ix+$00),$FF
323C: DD 36 01 0C ld   (ix+$01),$C0
3240: DD 36 20 0C ld   (ix+$02),$C0
3244: DD 74 21    ld   (ix+$03),h
3247: DD 74 61    ld   (ix+$07),h
324A: DD 75 41    ld   (ix+$05),l
324D: DD 75 81    ld   (ix+$09),l
3250: DD 36 31 60 ld   (ix+$13),$06
3254: DD 36 50 00 ld   (ix+$14),$00
3258: DD 36 51 C0 ld   (ix+$15),$0C
325C: DD 36 90 90 ld   (ix+$18),$18
3260: DD 71 71    ld   (ix+$17),c
3263: DD 70 F1    ld   (ix+$1f),b
3266: DD 36 A1 00 ld   (ix+$0b),$00
326A: DD 36 C0 00 ld   (ix+$0c),$00
326E: DD 36 C1 FF ld   (ix+$0d),$FF
3272: DD 36 E0 00 ld   (ix+$0e),$00
3276: DD 36 E1 00 ld   (ix+$0f),$00
327A: 3A 5F 0E    ld   a,($E0F5)
327D: 32 7E 0E    ld   ($E0F6),a
3280: CD 4C 59    call $95C4
3283: DD E1       pop  ix
3285: DD 34 50    inc  (ix+$14)
3288: DD 36 51 02 ld   (ix+$15),$20
328C: C9          ret
328D: DD 7E 50    ld   a,(ix+$14)
3290: 3D          dec  a
3291: 28 81       jr   z,$329C
3293: DD 35 70    dec  (ix+$16)
3296: C0          ret  nz
3297: DD 36 50 00 ld   (ix+$14),$00
329B: C9          ret
329C: DD 34 70    inc  (ix+$16)
329F: DD 35 51    dec  (ix+$15)
32A2: C0          ret  nz
32A3: DD 34 50    inc  (ix+$14)
32A6: C9          ret
32A7: 01 98 00    ld   bc,$0098
32AA: 75          ld   (hl),l
32AB: 20 98       jr   nz,$3245
32AD: 01 74 00    ld   bc,$0056
32B0: F4 01 98    call p,$9801
32B3: 00          nop
32B4: F4 01 18    call p,$9001
32B7: 00          nop
32B8: 75          ld   (hl),l
32B9: 20 18       jr   nz,$324B
32BB: 01 74 00    ld   bc,$0056
32BE: F4 01 18    call p,$9001
32C1: 00          nop
32C2: F4 21 55    call p,$5503
32C5: 0E 34       ld   c,$52
32C7: CD C9 B2    call $3A8D
32CA: DD 7E 41    ld   a,(ix+$05)
32CD: A7          and  a
32CE: CA 6B B2    jp   z,$3AA7
32D1: CD 80 52    call $3408
32D4: CD 9C 32    call $32D8
32D7: C9          ret
32D8: DD 46 21    ld   b,(ix+$03)
32DB: DD 4E 41    ld   c,(ix+$05)
32DE: C5          push bc
32DF: 79          ld   a,c
32E0: C6 51       add  a,$15
32E2: FE 31       cp   $13
32E4: 38 31       jr   c,$32F9
32E6: DD 77 41    ld   (ix+$05),a
32E9: 16 18       ld   d,$90
32EB: 1E 05       ld   e,$41
32ED: DD 7E 71    ld   a,(ix+$17)
32F0: FE 20       cp   $02
32F2: 20 20       jr   nz,$32F6
32F4: 16 98       ld   d,$98
32F6: CD 9C D0    call $1CD8
32F9: 11 40 00    ld   de,$0004
32FC: FD 19       add  iy,de
32FE: C1          pop  bc
32FF: DD 7E 70    ld   a,(ix+$16)
3302: C5          push bc
3303: 81          add  a,c
3304: C6 BF       add  a,$FB
3306: DD 77 41    ld   (ix+$05),a
3309: 21 5E 33    ld   hl,$33F4
330C: E5          push hl
330D: DD 7E 71    ld   a,(ix+$17)
3310: FE 01       cp   $01
3312: 28 87       jr   z,$337D
3314: 38 77       jr   c,$338D
3316: DD 7E 70    ld   a,(ix+$16)
3319: FE 81       cp   $09
331B: 30 C3       jr   nc,$334A
331D: 21 47 33    ld   hl,$3365
3320: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
3321: DD 86 21    add  a,(ix+$03)
3324: DD 77 21    ld   (ix+$03),a
3327: 1E A4       ld   e,$4A
3329: 16 18       ld   d,$90
332B: CD 9C D0    call $1CD8
332E: 11 40 00    ld   de,$0004
3331: FD 19       add  iy,de
3333: 3E 21       ld   a,$03
3335: DD 86 21    add  a,(ix+$03)
3338: DD 77 21    ld   (ix+$03),a
333B: 3E 10       ld   a,$10
333D: DD 86 41    add  a,(ix+$05)
3340: DD 77 41    ld   (ix+$05),a
3343: 1E 24       ld   e,$42
3345: 16 18       ld   d,$90
3347: C3 9C D0    jp   $1CD8
334A: 21 47 33    ld   hl,$3365
334D: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
334E: DD 86 21    add  a,(ix+$03)
3351: DD 77 21    ld   (ix+$03),a
3354: 1E 24       ld   e,$42
3356: 16 18       ld   d,$90
3358: CD 9C D0    call $1CD8
335B: 11 40 00    ld   de,$0004
335E: FD 19       add  iy,de
3360: FD 36 20 00 ld   (iy+$02),$00
3364: C9          ret
3365: 9F          sbc  a,a
3366: 9F          sbc  a,a
3367: 9F          sbc  a,a
3368: BF          cp   a
3369: BF          cp   a
336A: BF          cp   a
336B: BE          cp   (hl)
336C: BE          cp   (hl)
336D: BE          cp   (hl)
336E: DE DE       sbc  a,$FC
3370: DE DF       sbc  a,$FD
3372: DF          rst  $18
3373: DF          rst  $18
3374: FE FE       cp   $FE
3376: FE FF       cp   $FF
3378: FF          rst  $38
3379: FF          rst  $38
337A: 00          nop
337B: 00          nop
337C: 00          nop
337D: 11 20 52    ld   de,$3402
3380: DD 7E 70    ld   a,(ix+$16)
3383: FE 80       cp   $08
3385: 38 21       jr   c,$338A
3387: 11 DE 33    ld   de,$33FC
338A: C3 88 A3    jp   $2B88
338D: DD 7E 70    ld   a,(ix+$16)
3390: FE 41       cp   $05
3392: 30 C3       jr   nc,$33C1
3394: 21 DC 33    ld   hl,$33DC
3397: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
3398: DD 86 21    add  a,(ix+$03)
339B: DD 77 21    ld   (ix+$03),a
339E: 16 98       ld   d,$98
33A0: 1E A4       ld   e,$4A
33A2: CD 9C D0    call $1CD8
33A5: 11 40 00    ld   de,$0004
33A8: FD 19       add  iy,de
33AA: 3E DF       ld   a,$FD
33AC: DD 86 21    add  a,(ix+$03)
33AF: DD 77 21    ld   (ix+$03),a
33B2: 3E 10       ld   a,$10
33B4: DD 86 41    add  a,(ix+$05)
33B7: DD 77 41    ld   (ix+$05),a
33BA: 16 98       ld   d,$98
33BC: 1E 24       ld   e,$42
33BE: C3 9C D0    jp   $1CD8
33C1: 21 DC 33    ld   hl,$33DC
33C4: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
33C5: DD 86 21    add  a,(ix+$03)
33C8: DD 77 21    ld   (ix+$03),a
33CB: 16 98       ld   d,$98
33CD: 1E A4       ld   e,$4A
33CF: CD 9C D0    call $1CD8
33D2: 11 40 00    ld   de,$0004
33D5: FD 19       add  iy,de
33D7: FD 36 20 00 ld   (iy+$02),$00
33DB: C9          ret
33DC: 61          ld   h,c
33DD: 61          ld   h,c
33DE: 61          ld   h,c
33DF: 41          ld   b,c
33E0: 41          ld   b,c
33E1: 41          ld   b,c
33E2: 60          ld   h,b
33E3: 60          ld   h,b
33E4: 60          ld   h,b
33E5: 40          ld   b,b
33E6: 40          ld   b,b
33E7: 40          ld   b,b
33E8: 21 21 21    ld   hl,$0303
33EB: 20 20       jr   nz,$33EF
33ED: 20 01       jr   nz,$33F0
33EF: 01 01 00    ld   bc,$0001
33F2: 00          nop
33F3: 00          nop
33F4: C1          pop  bc
33F5: DD 70 21    ld   (ix+$03),b
33F8: DD 71 41    ld   (ix+$05),c
33FB: C9          ret
33FC: 20 18       jr   nz,$338E
33FE: 00          nop
33FF: 15          dec  d
3400: 00          nop
3401: FF          rst  $38
3402: 20 18       jr   nz,$3394
3404: 00          nop
3405: 15          dec  d
3406: 01 85 DD    ld   bc,$DD49
3409: 7E          ld   a,(hl)
340A: 40          ld   b,b
340B: A7          and  a
340C: C0          ret  nz
340D: DD 7E 50    ld   a,(ix+$14)
3410: F7          rst  $30
3411: 91          sub  c
3412: 52          ld   d,d
3413: 8A          adc  a,d
3414: 52          ld   d,d
3415: 9B          sbc  a,e
3416: 52          ld   d,d
3417: 0D          dec  c
3418: 52          ld   d,d
3419: 3A 20 0E    ld   a,($E002)
341C: 0F          rrca
341D: 0F          rrca
341E: E6 61       and  $07
3420: 47          ld   b,a
3421: DD 7E F1    ld   a,(ix+$1f)
3424: E6 61       and  $07
3426: B8          cp   b
3427: C0          ret  nz
3428: 3A 7E 0E    ld   a,($E0F6)
342B: A7          and  a
342C: C0          ret  nz
342D: DD E5       push ix
342F: DD 4E 71    ld   c,(ix+$17)
3432: DD 66 21    ld   h,(ix+$03)
3435: DD 7E 41    ld   a,(ix+$05)
3438: C6 00       add  a,$00
343A: 6F          ld   l,a
343B: DD 21 00 6E ld   ix,$E600
343F: 11 02 00    ld   de,$0020
3442: 3A 5E 0E    ld   a,($E0F4)
3445: 47          ld   b,a
3446: DD 7E 00    ld   a,(ix+$00)
3449: A7          and  a
344A: 28 61       jr   z,$3453
344C: DD 19       add  ix,de
344E: 10 7E       djnz $3446
3450: DD E1       pop  ix
3452: C9          ret
3453: DD 36 00 FF ld   (ix+$00),$FF
3457: DD 36 01 0C ld   (ix+$01),$C0
345B: DD 36 20 0C ld   (ix+$02),$C0
345F: DD 74 21    ld   (ix+$03),h
3462: DD 74 61    ld   (ix+$07),h
3465: DD 75 41    ld   (ix+$05),l
3468: DD 75 81    ld   (ix+$09),l
346B: DD 36 31 81 ld   (ix+$13),$09
346F: DD 36 50 00 ld   (ix+$14),$00
3473: DD 36 51 C0 ld   (ix+$15),$0C
3477: DD 36 90 90 ld   (ix+$18),$18
347B: DD 71 71    ld   (ix+$17),c
347E: DD 70 F1    ld   (ix+$1f),b
3481: DD 36 A1 00 ld   (ix+$0b),$00
3485: DD 36 C0 00 ld   (ix+$0c),$00
3489: DD 36 C1 FF ld   (ix+$0d),$FF
348D: DD 36 E0 00 ld   (ix+$0e),$00
3491: DD 36 E1 00 ld   (ix+$0f),$00
3495: 3A 5F 0E    ld   a,($E0F5)
3498: 32 7E 0E    ld   ($E0F6),a
349B: CD 4C 59    call $95C4
349E: DD E1       pop  ix
34A0: DD 34 50    inc  (ix+$14)
34A3: DD 36 70 00 ld   (ix+$16),$00
34A7: C9          ret
34A8: DD 34 70    inc  (ix+$16)
34AB: DD 7E 70    ld   a,(ix+$16)
34AE: FE 70       cp   $16
34B0: D8          ret  c
34B1: DD 34 50    inc  (ix+$14)
34B4: DD 36 51 F0 ld   (ix+$15),$1E
34B8: C9          ret
34B9: DD 35 51    dec  (ix+$15)
34BC: C0          ret  nz
34BD: DD 34 50    inc  (ix+$14)
34C0: C9          ret
34C1: DD 35 70    dec  (ix+$16)
34C4: C0          ret  nz
34C5: DD 36 50 00 ld   (ix+$14),$00
34C9: C9          ret
34CA: CD 5C 53    call $35D4
34CD: CD B0 53    call $351A
34D0: CD 6B 53    call $35A7
34D3: CD 5F 52    call $34F5
34D6: 3A 00 0F    ld   a,($E100)
34D9: 3C          inc  a
34DA: C0          ret  nz
34DB: 3A 21 0F    ld   a,($E103)
34DE: DD 96 21    sub  (ix+$03)
34E1: C6 C0       add  a,$0C
34E3: FE 91       cp   $19
34E5: D0          ret  nc
34E6: 3A 41 0F    ld   a,($E105)
34E9: DD 96 41    sub  (ix+$05)
34EC: FE 91       cp   $19
34EE: D0          ret  nc
34EF: 3E F3       ld   a,$3F
34F1: 32 00 0F    ld   ($E100),a
34F4: C9          ret
34F5: DD 7E 70    ld   a,(ix+$16)
34F8: 21 77 53    ld   hl,$3577
34FB: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
34FC: DD 7E 41    ld   a,(ix+$05)
34FF: C6 41       add  a,$05
3501: DD 77 41    ld   (ix+$05),a
3504: CD 9C D0    call $1CD8
3507: DD 7E 41    ld   a,(ix+$05)
350A: C6 BF       add  a,$FB
350C: DD 77 41    ld   (ix+$05),a
350F: 11 40 00    ld   de,$0004
3512: FD 19       add  iy,de
3514: 11 79 53    ld   de,$3597
3517: C3 88 A3    jp   $2B88
351A: 3A 20 0E    ld   a,($E002)
351D: E6 01       and  $01
351F: C8          ret  z
3520: FD E5       push iy
3522: FD 21 00 2E ld   iy,$E200
3526: 11 02 00    ld   de,$0020              ; sizeof (PLAYER_BULLET)
3529: 06 60       ld   b,$06
352B: DD 66 21    ld   h,(ix+$03)
352E: DD 6E 41    ld   l,(ix+$05)
3531: FD 7E 00    ld   a,(iy+$00)
3534: 3C          inc  a
3535: 20 93       jr   nz,$3570
3537: FD 7E 21    ld   a,(iy+$03)
353A: 94          sub  h
353B: C6 90       add  a,$18
353D: FE 03       cp   $21
353F: 30 E3       jr   nc,$3570
3541: FD 7E 41    ld   a,(iy+$05)
3544: 95          sub  l
3545: C6 80       add  a,$08
3547: FE 03       cp   $21
3549: 30 43       jr   nc,$3570
354B: FD 36 00 F3 ld   (iy+$00),$3F
354F: FD E1       pop  iy
3551: CD 15 68    call $8651
3554: 16 41       ld   d,$05
3556: 1E 20       ld   e,$02
3558: FF          rst  $38
3559: DD 34 71    inc  (ix+$17)
355C: DD 7E 71    ld   a,(ix+$17)
355F: FE 61       cp   $07
3561: 38 11       jr   c,$3574
3563: E1          pop  hl
3564: DD 66 21    ld   h,(ix+$03)
3567: DD 6E 41    ld   l,(ix+$05)
356A: CD 6B B2    call $3AA7
356D: C3 C1 38    jp   $920D
3570: FD 19       add  iy,de
3572: 10 DB       djnz $3531
3574: FD E1       pop  iy
3576: C9          ret
3577: 2B          dec  hl
3578: 80          add  a,b
3579: 2B          dec  hl
357A: 80          add  a,b
357B: 2A 80 0B    ld   hl,($A108)
357E: 80          add  a,b
357F: 0A          ld   a,(bc)
3580: 00          nop
3581: 0B          dec  bc
3582: 00          nop
3583: 2A 00 2B    ld   hl,($A300)
3586: 00          nop
3587: 3E BF       ld   a,$FB
3589: 3E BF       ld   a,$FB
358B: 5E          ld   e,(hl)
358C: BE          cp   (hl)
358D: DE 9F       sbc  a,$F9
358F: 01 9E 40    ld   bc,$04F8
3592: 9F          sbc  a,a
3593: 30 BE       jr   nc,$358F
3595: 50          ld   d,b
3596: BF          cp   a
3597: 40          ld   b,b
3598: 14          inc  d
3599: 1F          rra
359A: 3E 01       ld   a,$01
359C: 3F          ccf
359D: 1E BE       ld   e,$FA
359F: 00          nop
35A0: BF          cp   a
35A1: 18 01       jr   $35A4
35A3: 08          ex   af,af'
35A4: 00          nop
35A5: 16 01       ld   d,$01
35A7: DD 7E 41    ld   a,(ix+$05)
35AA: FE 12       cp   $30
35AC: D8          ret  c
35AD: FE 1E       cp   $F0
35AF: D0          ret  nc
35B0: 3A 20 0E    ld   a,($E002)
35B3: E6 E1       and  $0F
35B5: C0          ret  nz
35B6: CD 2E C6    call $6CE2
35B9: 47          ld   b,a
35BA: C6 61       add  a,$07
35BC: CB 7F       bit  7,a
35BE: C8          ret  z
35BF: DD 70 20    ld   (ix+$02),b
35C2: 0F          rrca
35C3: 0F          rrca
35C4: 0F          rrca
35C5: 0F          rrca
35C6: E6 61       and  $07
35C8: DD 77 70    ld   (ix+$16),a
35CB: 21 69 53    ld   hl,$3587
35CE: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
35CF: 63          ld   h,e
35D0: 6A          ld   l,d
35D1: C3 DF 39    jp   $93FD
35D4: CD C9 B2    call $3A8D
35D7: DD 7E 50    ld   a,(ix+$14)
35DA: 21 0B 53    ld   hl,$35A1
35DD: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
35DE: DD 7E 40    ld   a,(ix+$04)
35E1: DD 66 41    ld   h,(ix+$05)
35E4: DD 6E 60    ld   l,(ix+$06)
35E7: 19          add  hl,de
35E8: DD 74 41    ld   (ix+$05),h
35EB: DD 75 60    ld   (ix+$06),l
35EE: CE 00       adc  a,$00
35F0: DD 77 40    ld   (ix+$04),a
35F3: A7          and  a
35F4: 28 81       jr   z,$35FF
35F6: 7C          ld   a,h
35F7: FE 0E       cp   $E0
35F9: 30 40       jr   nc,$35FF
35FB: E1          pop  hl
35FC: C3 6B B2    jp   $3AA7
35FF: DD 7E 50    ld   a,(ix+$14)
3602: FE 01       cp   $01
3604: 28 E0       jr   z,$3614
3606: D0          ret  nc
3607: DD 7E 41    ld   a,(ix+$05)
360A: FE 0A       cp   $A0
360C: D8          ret  c
360D: DD 34 50    inc  (ix+$14)
3610: CD 56 68    call $8674
3613: C9          ret
3614: DD 35 51    dec  (ix+$15)
3617: 28 60       jr   z,$361F
3619: DD 7E 41    ld   a,(ix+$05)
361C: FE 08       cp   $80
361E: D0          ret  nc
361F: DD 34 50    inc  (ix+$14)
3622: CD B6 68    call $867A
3625: C9          ret
3626: 00          nop
3627: C9          ret
3628: 63          ld   h,e
3629: DD 36 31 70 ld   (ix+$13),$16
362D: DD 36 50 01 ld   (ix+$14),$01
3631: DD 36 51 02 ld   (ix+$15),$20
3635: DD 36 B0 10 ld   (ix+$1a),$10
3639: 21 02 FE    ld   hl,$FE20
363C: DD 74 B1    ld   (ix+$1b),h
363F: DD 75 D0    ld   (ix+$1c),l
3642: C9          ret
3643: C9          ret
3644: 02          ld   (bc),a
3645: FB          ei
3646: CD C9 B2    call $3A8D
3649: 11 34 72    ld   de,$3652
364C: CD 88 A3    call $2B88
364F: C3 88 A3    jp   $2B88
3652: 61          ld   h,c
3653: 0A          ld   a,(bc)
3654: 21 40 31    ld   hl,$1304
3657: 41          ld   b,c
3658: 20 C0       jr   nz,$3666
365A: 30 C1       jr   nc,$3669
365C: 01 F0 11    ld   bc,$111E
365F: F1          pop  af
3660: 00          nop
3661: 70          ld   (hl),b
3662: 61          ld   h,c
3663: 8A          adc  a,d
3664: 33          inc  sp
3665: 40          ld   b,b
3666: 23          inc  hl
3667: 41          ld   b,c
3668: 32 C0 22    ld   ($220C),a
366B: C1          pop  bc
366C: 13          inc  de
366D: F0          ret  p
366E: 03          inc  bc
366F: F1          pop  af
3670: 12          ld   (de),a
3671: 70          ld   (hl),b
3672: CD C9 B2    call $3A8D
3675: 11 F6 72    ld   de,$367E
3678: CD 88 A3    call $2B88
367B: C3 88 A3    jp   $2B88
367E: 61          ld   h,c
367F: 1A          ld   a,(de)
3680: 21 E1 31    ld   hl,$130F
3683: E1          pop  hl
3684: 20 71       jr   nz,$369D
3686: 30 71       jr   nc,$369F
3688: 01 60 11    ld   bc,$1106
368B: 61          ld   h,c
368C: 00          nop
368D: E0          ret  po
368E: 61          ld   h,c
368F: 9A          sbc  a,d
3690: 33          inc  sp
3691: E1          pop  hl
3692: 23          inc  hl
3693: E1          pop  hl
3694: 32 71 22    ld   ($2217),a
3697: 71          ld   (hl),c
3698: 13          inc  de
3699: 60          ld   h,b
369A: 03          inc  bc
369B: 61          ld   h,c
369C: 12          ld   (de),a
369D: E0          ret  po
369E: 3A 26 0E    ld   a,($E062)
36A1: A7          and  a
36A2: C8          ret  z
36A3: DD 35 41    dec  (ix+$05)
36A6: C9          ret
36A7: 21 55 0E    ld   hl,$E055
36AA: 34          inc  (hl)
36AB: CD FD 72    call $36DF
36AE: DD 7E 50    ld   a,(ix+$14)
36B1: FE 20       cp   $02
36B3: 28 E0       jr   z,$36C3
36B5: 3A 20 0E    ld   a,($E002)
36B8: 0F          rrca
36B9: 0F          rrca
36BA: 0F          rrca
36BB: E6 01       and  $01
36BD: 21 C6 73    ld   hl,$376C
36C0: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
36C1: 18 C0       jr   $36CF
36C3: DD 7E 51    ld   a,(ix+$15)
36C6: 0F          rrca
36C7: 0F          rrca
36C8: 0F          rrca
36C9: E6 21       and  $03
36CB: 21 88 73    ld   hl,$3788
36CE: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
36CF: DD 7E 40    ld   a,(ix+$04)
36D2: F5          push af
36D3: DD 36 40 00 ld   (ix+$04),$00
36D7: CD 88 A3    call $2B88
36DA: F1          pop  af
36DB: DD 77 40    ld   (ix+$04),a
36DE: C9          ret
36DF: DD 7E 50    ld   a,(ix+$14)
36E2: FE 20       cp   $02
36E4: 28 B1       jr   z,$3701
36E6: DD 35 51    dec  (ix+$15)
36E9: 28 C4       jr   z,$3737
36EB: DD 56 E1    ld   d,(ix+$0f)
36EE: DD 5E 10    ld   e,(ix+$10)
36F1: DD 66 A1    ld   h,(ix+$0b)
36F4: DD 6E C0    ld   l,(ix+$0c)
36F7: 19          add  hl,de
36F8: DD 74 A1    ld   (ix+$0b),h
36FB: DD 75 C0    ld   (ix+$0c),l
36FE: C3 5C E9    jp   $8FD4
3701: CD F8 72    call $369E
3704: 3A 41 0F    ld   a,($E105)
3707: 47          ld   b,a
3708: DD 7E 41    ld   a,(ix+$05)
370B: 90          sub  b
370C: FE 12       cp   $30
370E: 38 30       jr   c,$3722
3710: DD 7E 51    ld   a,(ix+$15)
3713: A7          and  a
3714: 28 40       jr   z,$371A
3716: DD 35 51    dec  (ix+$15)
3719: C9          ret
371A: CD 96 50    call $1478
371D: DD 36 51 02 ld   (ix+$15),$20
3721: C9          ret
3722: DD 34 50    inc  (ix+$14)
3725: CD B6 68    call $867A
3728: 3E 20       ld   a,$02
372A: 18 B1       jr   $3747
372C: DD 7E 50    ld   a,(ix+$14)
372F: A7          and  a
3730: C8          ret  z
3731: FE 20       cp   $02
3733: CA E7 68    jp   z,$866F
3736: C9          ret
3737: CD C2 73    call $372C
373A: DD 7E 50    ld   a,(ix+$14)
373D: FE 20       cp   $02
373F: C8          ret  z
3740: DD 34 50    inc  (ix+$14)
3743: FE 40       cp   $04
3745: 28 03       jr   z,$3768
3747: 21 D4 73    ld   hl,$375C
374A: 47          ld   b,a
374B: 87          add  a,a
374C: 80          add  a,b
374D: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
374E: DD 77 51    ld   (ix+$15),a
3751: 23          inc  hl
3752: 5E          ld   e,(hl)
3753: 23          inc  hl
3754: 56          ld   d,(hl)
3755: DD 72 E1    ld   (ix+$0f),d
3758: DD 73 10    ld   (ix+$10),e
375B: C9          ret
375C: 04          inc  b
375D: 41          ld   b,c
375E: 00          nop
375F: 00          nop
3760: 00          nop
3761: 00          nop
3762: 12          ld   (de),a
3763: BE          cp   (hl)
3764: FF          rst  $38
3765: 04          inc  b
3766: DE FF       sbc  a,$FF
3768: E1          pop  hl
3769: C3 6B B2    jp   $3AA7
376C: 16 73       ld   d,$37
376E: D6 73       sub  $37
3770: 41          ld   b,c
3771: 14          inc  d
3772: 01 06 11    ld   bc,$1160
3775: FF          rst  $38
3776: 1E 86       ld   e,$68
3778: 00          nop
3779: 87          add  a,a
377A: 10 A6       djnz $37E6
377C: 41          ld   b,c
377D: 14          inc  d
377E: 01 A7 11    ld   bc,$116B
3781: FF          rst  $38
3782: 1E 07       ld   e,$61
3784: 00          nop
3785: 26 10       ld   h,$10
3787: 27          daa
3788: 18 73       jr   $37C1
378A: D8          ret  c
378B: 73          ld   (hl),e
378C: 8A          adc  a,d
378D: 73          ld   (hl),e
378E: 5A          ld   e,d
378F: 73          ld   (hl),e
3790: 41          ld   b,c
3791: 14          inc  d
3792: 01 76 11    ld   bc,$1176
3795: 77          ld   (hl),a
3796: 1E 86       ld   e,$68
3798: 00          nop
3799: F6 10       or   $10
379B: F7          rst  $30
379C: 41          ld   b,c
379D: 14          inc  d
379E: 01 57 11    ld   bc,$1175
37A1: 77          ld   (hl),a
37A2: 1E 86       ld   e,$68
37A4: 00          nop
37A5: F6 10       or   $10
37A7: F7          rst  $30
37A8: 41          ld   b,c
37A9: 14          inc  d
37AA: 01 D6 11    ld   bc,$117C
37AD: 77          ld   (hl),a
37AE: 1E 86       ld   e,$68
37B0: 00          nop
37B1: F6 10       or   $10
37B3: F7          rst  $30
37B4: 41          ld   b,c
37B5: 14          inc  d
37B6: 01 66 11    ld   bc,$1166
37B9: 67          ld   h,a
37BA: 1E 86       ld   e,$68
37BC: 00          nop
37BD: E6 10       and  $10
37BF: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
37C0: DD 35 51    dec  (ix+$15)
37C3: 28 72       jr   z,$37FB
37C5: DD 7E 50    ld   a,(ix+$14)
37C8: E6 21       and  $03
37CA: FE 01       cp   $01
37CC: 38 23       jr   c,$37F1
37CE: 28 20       jr   z,$37D2
37D0: 18 A0       jr   $37DC
37D2: CD 5C E9    call $8FD4
37D5: 1E 5B       ld   e,$B5
37D7: 16 00       ld   d,$00
37D9: C3 9C D0    jp   $1CD8
37DC: CD F8 72    call $369E
37DF: 21 CE 73    ld   hl,$37EC
37E2: DD 7E 51    ld   a,(ix+$15)
37E5: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
37E6: 5F          ld   e,a
37E7: 16 00       ld   d,$00
37E9: C3 9C D0    jp   $1CD8
37EC: DA DA BB    jp   c,$BBBC
37EF: 9B          sbc  a,e
37F0: 9A          sbc  a,d
37F1: CD F8 72    call $369E
37F4: 1E FA       ld   e,$BE
37F6: 16 00       ld   d,$00
37F8: C3 9C D0    jp   $1CD8
37FB: DD 7E 50    ld   a,(ix+$14)
37FE: E6 21       and  $03
3800: DD 34 50    inc  (ix+$14)
3803: FE 00       cp   $00
3805: 28 A0       jr   z,$3811
3807: FE 20       cp   $02
3809: CA 6B B2    jp   z,$3AA7
380C: DD 36 51 41 ld   (ix+$15),$05
3810: C9          ret
3811: DD 36 51 12 ld   (ix+$15),$30
3815: C9          ret
3816: DD 36 00 00 ld   (ix+$00),$00
381A: FD 36 20 00 ld   (iy+$02),$00
381E: FD 36 60 00 ld   (iy+$06),$00
3822: C9          ret
3823: CD F8 72    call $369E
3826: DD 7E 41    ld   a,(ix+$05)
3829: A7          and  a
382A: 28 AE       jr   z,$3816
382C: CD 95 92    call $3859
382F: CD 33 92    call $3833
3832: C9          ret
3833: DD 7E 50    ld   a,(ix+$14)
3836: E6 21       and  $03
3838: 21 F3 92    ld   hl,$383F
383B: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
383C: C3 88 A3    jp   $2B88
383F: 65          ld   h,l
3840: 92          sub  d
3841: C5          push bc
3842: 92          sub  d
3843: 35          dec  (hl)
3844: 92          sub  d
3845: C5          push bc
3846: 92          sub  d
3847: 20 04       jr   nz,$3889
3849: 1E 04       ld   e,$40
384B: 00          nop
384C: 05          dec  b
384D: 20 04       jr   nz,$388F
384F: 1E 04       ld   e,$40
3851: 00          nop
3852: 24          inc  h
3853: 20 04       jr   nz,$3895
3855: 1E 04       ld   e,$40
3857: 00          nop
3858: A4          and  h
3859: DD 7E 50    ld   a,(ix+$14)
385C: E6 21       and  $03
385E: 20 31       jr   nz,$3873
3860: CD 2E C6    call $6CE2
3863: C6 60       add  a,$06
3865: 47          ld   b,a
3866: D6 9C       sub  $D8
3868: FE 02       cp   $20
386A: D0          ret  nc
386B: DD 70 20    ld   (ix+$02),b
386E: DD 34 50    inc  (ix+$14)
3871: 18 61       jr   $387A
3873: DD 35 51    dec  (ix+$15)
3876: C0          ret  nz
3877: DD 34 50    inc  (ix+$14)
387A: DD 36 51 20 ld   (ix+$15),$02
387E: DD 7E 50    ld   a,(ix+$14)
3881: E6 01       and  $01
3883: C8          ret  z
3884: DD 7E 50    ld   a,(ix+$14)
3887: E6 20       and  $02
3889: 21 58 92    ld   hl,$3894
388C: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
388D: 57          ld   d,a
388E: 23          inc  hl
388F: 5E          ld   e,(hl)
3890: EB          ex   de,hl
3891: C3 DF 39    jp   $93FD
3894: 60          ld   h,b
3895: BE          cp   (hl)
3896: A1          and  c
3897: 00          nop
3898: C9          ret
3899: CD F8 72    call $369E
389C: DD 35 51    dec  (ix+$15)
389F: CA 98 93    jp   z,$3998
38A2: DD 7E 50    ld   a,(ix+$14)
38A5: A7          and  a
38A6: 20 70       jr   nz,$38BE
38A8: 1E B4       ld   e,$5A
38AA: 16 14       ld   d,$50
38AC: C3 9C D0    jp   $1CD8
38AF: FD E5       push iy
38B1: E1          pop  hl
38B2: 11 40 00    ld   de,$0004
38B5: 06 10       ld   b,$10
38B7: 3E FF       ld   a,$FF
38B9: 77          ld   (hl),a
38BA: 19          add  hl,de
38BB: 10 DE       djnz $38B9
38BD: C9          ret
38BE: CD EB 92    call $38AF
38C1: DD 7E 51    ld   a,(ix+$15)
38C4: 0F          rrca
38C5: 0F          rrca
38C6: E6 E1       and  $0F
38C8: FE 61       cp   $07
38CA: CA 5E 92    jp   z,$38F4
38CD: FE 60       cp   $06
38CF: CA 5E 92    jp   z,$38F4
38D2: 21 F0 93    ld   hl,$391E
38D5: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
38D6: DD 46 21    ld   b,(ix+$03)
38D9: DD 4E 41    ld   c,(ix+$05)
38DC: C5          push bc
38DD: 1A          ld   a,(de)
38DE: 13          inc  de
38DF: 80          add  a,b
38E0: DD 77 21    ld   (ix+$03),a
38E3: 1A          ld   a,(de)
38E4: 13          inc  de
38E5: 81          add  a,c
38E6: DD 77 41    ld   (ix+$05),a
38E9: CD 88 A3    call $2B88
38EC: C1          pop  bc
38ED: DD 70 21    ld   (ix+$03),b
38F0: DD 71 41    ld   (ix+$05),c
38F3: C9          ret
38F4: 3E 9E       ld   a,$F8
38F6: DD 86 21    add  a,(ix+$03)
38F9: DD 77 21    ld   (ix+$03),a
38FC: 3E 9E       ld   a,$F8
38FE: DD 86 41    add  a,(ix+$05)
3901: DD 77 41    ld   (ix+$05),a
3904: 11 F4 93    ld   de,$395E
3907: CD 88 A3    call $2B88
390A: CD 88 A3    call $2B88
390D: 3E 80       ld   a,$08
390F: DD 86 21    add  a,(ix+$03)
3912: DD 77 21    ld   (ix+$03),a
3915: 3E 80       ld   a,$08
3917: DD 86 41    add  a,(ix+$05)
391A: DD 77 41    ld   (ix+$05),a
391D: C9          ret
391E: 12          ld   (de),a
391F: 93          sub  e
3920: D2 93 84    jp   nc,$4839
3923: 93          sub  e
3924: 84          add  a,h
3925: 93          sub  e
3926: 28 93       jr   z,$3961
3928: 28 93       jr   z,$3963
392A: F4 93 F4    call p,$5E39
392D: 93          sub  e
392E: 84          add  a,h
392F: 93          sub  e
3930: 9E          sbc  a,(hl)
3931: 9E          sbc  a,(hl)
3932: 40          ld   b,b
3933: 16 01       ld   d,$01
3935: 08          ex   af,af'
3936: 11 09 00    ld   de,$0081
3939: 88          adc  a,b
393A: 10 89       djnz $38C5
393C: 9E          sbc  a,(hl)
393D: 9E          sbc  a,(hl)
393E: 40          ld   b,b
393F: 16 01       ld   d,$01
3941: 28 11       jr   z,$3954
3943: 29          add  hl,hl
3944: 00          nop
3945: A8          xor  b
3946: 10 A9       djnz $38D3
3948: 00          nop
3949: 00          nop
394A: 81          add  a,c
394B: 16 1F       ld   d,$F1
394D: 08          ex   af,af'
394E: 01 8C 11    ld   bc,$11C8
3951: 09          add  hl,bc
3952: 1E 0C       ld   e,$C0
3954: 00          nop
3955: 0D          dec  c
3956: 10 2C       djnz $391A
3958: FF          rst  $38
3959: 88          adc  a,b
395A: E1          pop  hl
395B: 8D          adc  a,l
395C: F1          pop  af
395D: 89          adc  a,c
395E: C0          ret  nz
395F: 16 3E       ld   d,$F2
3961: C8          ret  z
3962: 20 C9       jr   nz,$38F1
3964: 30 E8       jr   nc,$38F4
3966: 22 E9 1F    ld   ($F18F),hl
3969: 58          ld   e,b
396A: 01 59 11    ld   bc,$1195
396D: 78          ld   a,b
396E: 03          inc  bc
396F: 79          ld   a,c
3970: 1E D8       ld   e,$9C
3972: 00          nop
3973: D9          exx
3974: 10 F8       djnz $3914
3976: 02          ld   (bc),a
3977: F9          ld   sp,hl
3978: 40          ld   b,b
3979: 56          ld   d,(hl)
397A: E3          ex   (sp),hl
397B: E9          jp   (hl)
397C: F1          pop  af
397D: E8          ret  pe
397E: E1          pop  hl
397F: C9          ret
3980: FF          rst  $38
3981: C8          ret  z
3982: 00          nop
3983: 00          nop
3984: 81          add  a,c
3985: 16 1F       ld   d,$F1
3987: 18 01       jr   $398A
3989: 9C          sbc  a,h
398A: 11 19 1E    ld   de,$F091
398D: 1C          inc  e
398E: 00          nop
398F: 1D          dec  e
3990: 10 3C       djnz $3964
3992: FF          rst  $38
3993: 99          sbc  a,c
3994: E1          pop  hl
3995: 9D          sbc  a,l
3996: F1          pop  af
3997: 19          add  hl,de
3998: DD 7E 50    ld   a,(ix+$14)
399B: A7          and  a
399C: C2 6B B2    jp   nz,$3AA7
399F: DD 34 50    inc  (ix+$14)
39A2: DD 36 51 02 ld   (ix+$15),$20
39A6: 3E 01       ld   a,$01
39A8: 32 B9 0E    ld   ($E09B),a
39AB: C9          ret
39AC: A0          and  b
39AD: 21 58 0E    ld   hl,$E094
39B0: 7E          ld   a,(hl)
39B1: A7          and  a
39B2: 28 F1       jr   z,$39D3
39B4: 36 00       ld   (hl),$00
39B6: DD 7E 50    ld   a,(ix+$14)
39B9: FE 01       cp   $01
39BB: 38 C0       jr   c,$39C9
39BD: 28 50       jr   z,$39D3
39BF: DD 36 50 01 ld   (ix+$14),$01
39C3: DD 36 51 01 ld   (ix+$15),$01
39C7: 18 A0       jr   $39D3
39C9: DD 36 50 01 ld   (ix+$14),$01
39CD: DD 36 51 10 ld   (ix+$15),$10
39D1: 18 00       jr   $39D3
39D3: CD 4F 93    call $39E5
39D6: DD 7E 50    ld   a,(ix+$14)
39D9: E6 21       and  $03
39DB: 21 C0 B2    ld   hl,$3A0C
39DE: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
39DF: CD 88 A3    call $2B88
39E2: C3 88 A3    jp   $2B88
39E5: CD C9 B2    call $3A8D
39E8: DD 7E 50    ld   a,(ix+$14)
39EB: A7          and  a
39EC: C8          ret  z
39ED: DD 35 51    dec  (ix+$15)
39F0: C0          ret  nz
39F1: DD 7E 50    ld   a,(ix+$14)
39F4: FE 21       cp   $03
39F6: 28 A1       jr   z,$3A03
39F8: DD 34 50    inc  (ix+$14)
39FB: 21 80 B2    ld   hl,$3A08
39FE: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
39FF: DD 77 51    ld   (ix+$15),a
3A02: C9          ret
3A03: DD 36 50 00 ld   (ix+$14),$00
3A07: C9          ret
3A08: 04          inc  b
3A09: 14          inc  d
3A0A: 04          inc  b
3A0B: 00          nop
3A0C: 50          ld   d,b
3A0D: B2          or   d
3A0E: D2 B2 46    jp   nc,$643A
3A11: B2          or   d
3A12: D2 B2 81    jp   nc,$093A
3A15: 14          inc  d
3A16: 20 0A       jr   nz,$39B8
3A18: 30 0B       jr   nc,$39BB
3A1A: 22 2A 01    ld   ($01A2),hl
3A1D: 8A          adc  a,d
3A1E: 11 8B 03    ld   de,$21A9
3A21: AA          xor  d
3A22: 00          nop
3A23: 1A          ld   a,(de)
3A24: 10 1B       djnz $39D7
3A26: 02          ld   (bc),a
3A27: 3A 81 94    ld   a,($5809)
3A2A: 34          inc  (hl)
3A2B: 0A          ld   a,(bc)
3A2C: 24          inc  h
3A2D: 0B          dec  bc
3A2E: 32 2A 15    ld   ($51A2),a
3A31: 8A          adc  a,d
3A32: 05          dec  b
3A33: 8B          adc  a,e
3A34: 13          inc  de
3A35: AA          xor  d
3A36: 14          inc  d
3A37: 1A          ld   a,(de)
3A38: 04          inc  b
3A39: 1B          dec  de
3A3A: 12          ld   (de),a
3A3B: 3A 81 14    ld   a,($5009)
3A3E: 20 4A       jr   nz,$39E4
3A40: 30 4B       jr   nc,$39E7
3A42: 01 CA 11    ld   bc,$11AC
3A45: CB 00       rlc  b
3A47: 5A          ld   e,d
3A48: 10 5B       djnz $39FF
3A4A: F1          pop  af
3A4B: DB 00       in   a,($00)
3A4D: FF          rst  $38
3A4E: 00          nop
3A4F: FF          rst  $38
3A50: 81          add  a,c
3A51: 94          sub  h
3A52: 34          inc  (hl)
3A53: 4A          ld   c,d
3A54: 24          inc  h
3A55: 4B          ld   c,e
3A56: 15          dec  d
3A57: CA 05 CB    jp   z,$AD41
3A5A: 14          inc  d
3A5B: 5A          ld   e,d
3A5C: 04          inc  b
3A5D: 5B          ld   e,e
3A5E: E5          push hl
3A5F: DB 00       in   a,($00)
3A61: FF          rst  $38
3A62: 00          nop
3A63: FF          rst  $38
3A64: 81          add  a,c
3A65: 14          inc  d
3A66: 20 2B       jr   nz,$3A0B
3A68: 01 AB 00    ld   bc,$00AB
3A6B: 3B          dec  sp
3A6C: E1          pop  hl
3A6D: BB          cp   e
3A6E: 00          nop
3A6F: FF          rst  $38
3A70: 00          nop
3A71: FF          rst  $38
3A72: 00          nop
3A73: FF          rst  $38
3A74: 00          nop
3A75: FF          rst  $38
3A76: 00          nop
3A77: FF          rst  $38
3A78: 81          add  a,c
3A79: 94          sub  h
3A7A: 34          inc  (hl)
3A7B: 2B          dec  hl
3A7C: 15          dec  d
3A7D: AB          xor  e
3A7E: 14          inc  d
3A7F: 3B          dec  sp
3A80: F5          push af
3A81: BB          cp   e
3A82: 00          nop
3A83: FF          rst  $38
3A84: 00          nop
3A85: FF          rst  $38
3A86: 00          nop
3A87: FF          rst  $38
3A88: 00          nop
3A89: FF          rst  $38
3A8A: 00          nop
3A8B: FF          rst  $38
3A8C: C9          ret
3A8D: 3A 26 0E    ld   a,($E062)
3A90: A7          and  a
3A91: C8          ret  z
3A92: DD 66 40    ld   h,(ix+$04)
3A95: DD 6E 41    ld   l,(ix+$05)
3A98: 2B          dec  hl
3A99: DD 74 40    ld   (ix+$04),h
3A9C: DD 75 41    ld   (ix+$05),l
3A9F: 7C          ld   a,h
3AA0: A7          and  a
3AA1: C8          ret  z
3AA2: 7D          ld   a,l
3AA3: FE 0C       cp   $C0
3AA5: D0          ret  nc
3AA6: E1          pop  hl
3AA7: DD 36 00 00 ld   (ix+$00),$00
3AAB: DD 46 B0    ld   b,(ix+$1a)
3AAE: 11 40 00    ld   de,$0004
3AB1: FD 36 20 00 ld   (iy+$02),$00
3AB5: FD 19       add  iy,de
3AB7: 10 9E       djnz $3AB1
3AB9: C9          ret
3ABA: CD 2D B2    call $3AC3
3ABD: CD A8 D3    call $3D8A
3AC0: C3 80 F3    jp   $3F08
3AC3: 21 40 D2    ld   hl,$3C04
3AC6: 06 C0       ld   b,$0C
3AC8: CD 6C B3    call $3BC6
3ACB: 10 BF       djnz $3AC8
3ACD: CD 76 20    call $0276
3AD0: 3A 21 0E    ld   a,($E003)
3AD3: 32 B3 0E    ld   ($E03B),a
3AD6: 3A 60 0E    ld   a,($E006)
3AD9: 47          ld   b,a
3ADA: E6 21       and  $03
3ADC: 87          add  a,a
3ADD: 21 6E B3    ld   hl,$3BE6
3AE0: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
3AE1: 32 F4 1D    ld   ($D15E),a
3AE4: 23          inc  hl
3AE5: 7E          ld   a,(hl)
3AE6: 32 F4 3C    ld   ($D25E),a
3AE9: 78          ld   a,b
3AEA: 0F          rrca
3AEB: 0F          rrca
3AEC: E6 21       and  $03
3AEE: 87          add  a,a
3AEF: 21 6E B3    ld   hl,$3BE6
3AF2: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
3AF3: 32 D5 1D    ld   ($D15D),a
3AF6: 23          inc  hl
3AF7: 7E          ld   a,(hl)
3AF8: 32 D5 3C    ld   ($D25D),a
3AFB: 78          ld   a,b
3AFC: 07          rlca
3AFD: 07          rlca
3AFE: 07          rlca
3AFF: 07          rlca
3B00: E6 21       and  $03
3B02: 21 2E B3    ld   hl,$3BE2
3B05: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
3B06: 32 D4 1D    ld   ($D15C),a
3B09: 78          ld   a,b
3B0A: 07          rlca
3B0B: 07          rlca
3B0C: E6 21       and  $03
3B0E: 21 BE B3    ld   hl,$3BFA
3B11: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
3B12: 32 B7 3C    ld   ($D27B),a
3B15: 3A 61 0E    ld   a,($E007)
3B18: 47          ld   b,a
3B19: E6 01       and  $01
3B1B: CA 78 B3    jp   z,$3B96
3B1E: CB 48       bit  1,b
3B20: CA F9 B3    jp   z,$3B9F
3B23: 21 71 D3    ld   hl,$3D17
3B26: CD 6C B3    call $3BC6
3B29: CB 58       bit  3,b
3B2B: CA 48 B3    jp   z,$3B84
3B2E: 21 25 D3    ld   hl,$3D43
3B31: CD 6C B3    call $3BC6
3B34: CB 60       bit  4,b
3B36: CA C9 B3    jp   z,$3B8D
3B39: 21 EF D2    ld   hl,$3CEF
3B3C: CD 6C B3    call $3BC6
3B3F: 78          ld   a,b
3B40: 07          rlca
3B41: 07          rlca
3B42: 07          rlca
3B43: E6 61       and  $07
3B45: FE 61       cp   $07
3B47: CA 7B B3    jp   z,$3BB7
3B4A: 21 B5 D3    ld   hl,$3D5B
3B4D: CD 6C B3    call $3BC6
3B50: 21 56 D3    ld   hl,$3D74
3B53: CD 6C B3    call $3BC6
3B56: 78          ld   a,b
3B57: 07          rlca
3B58: 07          rlca
3B59: 07          rlca
3B5A: E6 61       and  $07
3B5C: FE 60       cp   $06
3B5E: CA 8A B3    jp   z,$3BA8
3B61: 87          add  a,a
3B62: 21 EE B3    ld   hl,$3BEE
3B65: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
3B66: 32 71 3C    ld   ($D217),a
3B69: 23          inc  hl
3B6A: 7E          ld   a,(hl)
3B6B: 32 70 3C    ld   ($D216),a
3B6E: 21 54 1C    ld   hl,$D054
3B71: 06 A1       ld   b,$0B
3B73: CD 9D B3    call $3BD9
3B76: 21 FE B3    ld   hl,$3BFE
3B79: CD 6C B3    call $3BC6
3B7C: 21 54 3C    ld   hl,$D254
3B7F: 06 A1       ld   b,$0B
3B81: C3 9D B3    jp   $3BD9
3B84: 21 E5 D3    ld   hl,$3D4F
3B87: CD 6C B3    call $3BC6
3B8A: C3 52 B3    jp   $3B34
3B8D: 21 8F D2    ld   hl,$3CE9
3B90: CD 6C B3    call $3BC6
3B93: C3 F3 B3    jp   $3B3F
3B96: 21 01 D3    ld   hl,$3D01
3B99: CD 6C B3    call $3BC6
3B9C: C3 83 B3    jp   $3B29
3B9F: 21 C3 D3    ld   hl,$3D2D
3BA2: CD 6C B3    call $3BC6
3BA5: C3 83 B3    jp   $3B29
3BA8: 21 B8 D2    ld   hl,$3C9A
3BAB: CD 6C B3    call $3BC6
3BAE: 21 F8 D2    ld   hl,$3C9E
3BB1: CD 6C B3    call $3BC6
3BB4: C3 E6 B3    jp   $3B6E
3BB7: 21 2B D2    ld   hl,$3CA3
3BBA: CD 6C B3    call $3BC6
3BBD: 21 6C D2    ld   hl,$3CC6
3BC0: CD 6C B3    call $3BC6
3BC3: C3 E6 B3    jp   $3B6E
3BC6: 5E          ld   e,(hl)
3BC7: 23          inc  hl
3BC8: 56          ld   d,(hl)
3BC9: 23          inc  hl
3BCA: 7E          ld   a,(hl)
3BCB: 23          inc  hl
3BCC: FE 04       cp   $40
3BCE: C8          ret  z
3BCF: 12          ld   (de),a
3BD0: 7B          ld   a,e
3BD1: C6 02       add  a,$20
3BD3: 5F          ld   e,a
3BD4: 30 5E       jr   nc,$3BCA
3BD6: 14          inc  d
3BD7: 18 1F       jr   $3BCA
3BD9: 11 02 00    ld   de,$0020
3BDC: 36 B5       ld   (hl),$5B
3BDE: 19          add  hl,de
3BDF: 10 9E       djnz $3BD9
3BE1: C9          ret
3BE2: 33          inc  sp
3BE3: 32 52 53    ld   ($3534),a
3BE6: 13          inc  de
3BE7: 13          inc  de
3BE8: 13          inc  de
3BE9: 32 13 33    ld   ($3331),a
3BEC: 32 13 13    ld   ($3131),a
3BEF: 53          ld   d,e
3BF0: 13          inc  de
3BF1: 72          ld   (hl),d
3BF2: 32 72 32    ld   ($3236),a
3BF5: 73          ld   (hl),e
3BF6: 33          inc  sp
3BF7: 73          ld   (hl),e
3BF8: 33          inc  sp
3BF9: 92          sub  d
3BFA: 13          inc  de
3BFB: 33          inc  sp
3BFC: 53          ld   d,e
3BFD: 73          ld   (hl),e
3BFE: 5C          ld   e,h
3BFF: 1D          dec  e
3C00: 24          inc  h
3C01: 85          add  a,l
3C02: 54          ld   d,h
3C03: 04          inc  b
3C04: F4 1C 02    call p,$20D0
3C07: 25          dec  h
3C08: E5          push hl
3C09: 85          add  a,l
3C0A: E4 13 04    call po,$4031
3C0D: F8          ret  m
3C0E: 1D          dec  e
3C0F: 25          dec  h
3C10: E5          push hl
3C11: 85          add  a,l
3C12: E4 04 F8    call po,$9E40
3C15: 3C          inc  a
3C16: 25          dec  h
3C17: 34          inc  (hl)
3C18: 45          ld   b,l
3C19: 44          ld   b,h
3C1A: 85          add  a,l
3C1B: 54          ld   d,h
3C1C: 04          inc  b
3C1D: D5          push de
3C1E: 1C          inc  e
3C1F: 02          ld   (bc),a
3C20: 25          dec  h
3C21: E5          push hl
3C22: 85          add  a,l
3C23: E4 32 04    call po,$4032
3C26: D9          exx
3C27: 1D          dec  e
3C28: 25          dec  h
3C29: E5          push hl
3C2A: 85          add  a,l
3C2B: E4 02 04    call po,$4020
3C2E: D9          exx
3C2F: 3C          inc  a
3C30: 25          dec  h
3C31: 34          inc  (hl)
3C32: 45          ld   b,l
3C33: 44          ld   b,h
3C34: 85          add  a,l
3C35: 54          ld   d,h
3C36: 04          inc  b
3C37: D4 1C 02    call nc,$20D0
3C3A: 14          inc  d
3C3B: C4 05 95    call nz,$5941
3C3E: 45          ld   b,l
3C3F: 34          inc  (hl)
3C40: 04          inc  b
3C41: 94          sub  h
3C42: 1C          inc  e
3C43: 02          ld   (bc),a
3C44: 35          dec  (hl)
3C45: E5          push hl
3C46: 55          ld   d,l
3C47: E4 44 04    call po,$4044
3C4A: B4          or   h
3C4B: 1C          inc  e
3C4C: 02          ld   (bc),a
3C4D: 54          ld   d,h
3C4E: 95          sub  l
3C4F: 14          inc  d
3C50: 45          ld   b,l
3C51: 04          inc  b
3C52: 94          sub  h
3C53: 1C          inc  e
3C54: 02          ld   (bc),a
3C55: 35          dec  (hl)
3C56: E5          push hl
3C57: 55          ld   d,l
3C58: E4 44 02    call po,$2044
3C5B: 04          inc  b
3C5C: B5          or   l
3C5D: 1C          inc  e
3C5E: 02          ld   (bc),a
3C5F: 35          dec  (hl)
3C60: 54          ld   d,h
3C61: 05          dec  b
3C62: 34          inc  (hl)
3C63: 54          ld   d,h
3C64: 85          add  a,l
3C65: E4 65 02    call po,$2047
3C68: 35          dec  (hl)
3C69: 54          ld   d,h
3C6A: 05          dec  b
3C6B: 65          ld   h,l
3C6C: 45          ld   b,l
3C6D: 04          inc  b
3C6E: 95          sub  l
3C6F: 1C          inc  e
3C70: 02          ld   (bc),a
3C71: 44          ld   b,h
3C72: 45          ld   b,l
3C73: 64          ld   h,h
3C74: 64          ld   h,h
3C75: 85          add  a,l
3C76: 25          dec  h
3C77: 55          ld   d,l
3C78: C4 54 95    call nz,$5954
3C7B: 04          inc  b
3C7C: 25          dec  h
3C7D: 3D          dec  a
3C7E: 44          ld   b,h
3C7F: 85          add  a,l
3C80: 14          inc  d
3C81: 02          ld   (bc),a
3C82: 35          dec  (hl)
3C83: 75          ld   (hl),l
3C84: 02          ld   (bc),a
3C85: E5          push hl
3C86: A5          and  l
3C87: 02          ld   (bc),a
3C88: 02          ld   (bc),a
3C89: 02          ld   (bc),a
3C8A: 04          inc  b
3C8B: 25          dec  h
3C8C: 3D          dec  a
3C8D: 44          ld   b,h
3C8E: 85          add  a,l
3C8F: 14          inc  d
3C90: 02          ld   (bc),a
3C91: 35          dec  (hl)
3C92: 75          ld   (hl),l
3C93: 02          ld   (bc),a
3C94: 25          dec  h
3C95: 84          add  a,h
3C96: 45          ld   b,l
3C97: 25          dec  h
3C98: A5          and  l
3C99: 04          inc  b
3C9A: 71          ld   (hl),c
3C9B: 3C          inc  a
3C9C: 52          ld   d,d
3C9D: 04          inc  b
3C9E: 7E          ld   a,(hl)
3C9F: 1D          dec  e
3CA0: 13          inc  de
3CA1: 12          ld   (de),a
3CA2: 04          inc  b
3CA3: 75          ld   (hl),l
3CA4: 1C          inc  e
3CA5: 02          ld   (bc),a
3CA6: 24          inc  h
3CA7: E5          push hl
3CA8: E4 55 35    call po,$5355
3CAB: 02          ld   (bc),a
3CAC: E4 45 25    call po,$4345
3CAF: 45          ld   b,l
3CB0: 35          dec  (hl)
3CB1: 35          dec  (hl)
3CB2: 05          dec  b
3CB3: 34          inc  (hl)
3CB4: 95          sub  l
3CB5: 02          ld   (bc),a
3CB6: 02          ld   (bc),a
3CB7: 02          ld   (bc),a
3CB8: 02          ld   (bc),a
3CB9: 02          ld   (bc),a
3CBA: 02          ld   (bc),a
3CBB: 02          ld   (bc),a
3CBC: 02          ld   (bc),a
3CBD: 02          ld   (bc),a
3CBE: 02          ld   (bc),a
3CBF: 02          ld   (bc),a
3CC0: 02          ld   (bc),a
3CC1: 02          ld   (bc),a
3CC2: 02          ld   (bc),a
3CC3: 02          ld   (bc),a
3CC4: 02          ld   (bc),a
3CC5: 04          inc  b
3CC6: 7A          ld   a,d
3CC7: 1C          inc  e
3CC8: 02          ld   (bc),a
3CC9: 02          ld   (bc),a
3CCA: 02          ld   (bc),a
3CCB: 02          ld   (bc),a
3CCC: 02          ld   (bc),a
3CCD: 02          ld   (bc),a
3CCE: 02          ld   (bc),a
3CCF: 02          ld   (bc),a
3CD0: 02          ld   (bc),a
3CD1: 02          ld   (bc),a
3CD2: 02          ld   (bc),a
3CD3: 02          ld   (bc),a
3CD4: 02          ld   (bc),a
3CD5: 02          ld   (bc),a
3CD6: 02          ld   (bc),a
3CD7: 02          ld   (bc),a
3CD8: 02          ld   (bc),a
3CD9: 02          ld   (bc),a
3CDA: 02          ld   (bc),a
3CDB: 02          ld   (bc),a
3CDC: 02          ld   (bc),a
3CDD: 02          ld   (bc),a
3CDE: 02          ld   (bc),a
3CDF: 02          ld   (bc),a
3CE0: 02          ld   (bc),a
3CE1: 02          ld   (bc),a
3CE2: 02          ld   (bc),a
3CE3: 02          ld   (bc),a
3CE4: 02          ld   (bc),a
3CE5: 02          ld   (bc),a
3CE6: 02          ld   (bc),a
3CE7: 02          ld   (bc),a
3CE8: 04          inc  b
3CE9: 94          sub  h
3CEA: 1D          dec  e
3CEB: E5          push hl
3CEC: E4 02 04    call po,$4020
3CEF: 94          sub  h
3CF0: 1D          dec  e
3CF1: E5          push hl
3CF2: 64          ld   h,h
3CF3: 64          ld   h,h
3CF4: 04          inc  b
3CF5: 89          adc  a,c
3CF6: 3C          inc  a
3CF7: E5          push hl
3CF8: E4 02 04    call po,$4020
3CFB: 89          adc  a,c
3CFC: 3C          inc  a
3CFD: E5          push hl
3CFE: 64          ld   h,h
3CFF: 64          ld   h,h
3D00: 04          inc  b
3D01: B4          or   h
3D02: 1D          dec  e
3D03: 54          ld   d,h
3D04: 05          dec  b
3D05: 24          inc  h
3D06: C4 45 02    call nz,$2045
3D09: 02          ld   (bc),a
3D0A: 02          ld   (bc),a
3D0B: 02          ld   (bc),a
3D0C: 02          ld   (bc),a
3D0D: 02          ld   (bc),a
3D0E: 02          ld   (bc),a
3D0F: 02          ld   (bc),a
3D10: 02          ld   (bc),a
3D11: 02          ld   (bc),a
3D12: 02          ld   (bc),a
3D13: 02          ld   (bc),a
3D14: 02          ld   (bc),a
3D15: 02          ld   (bc),a
3D16: 04          inc  b
3D17: B4          or   h
3D18: 1D          dec  e
3D19: 55          ld   d,l
3D1A: 14          inc  d
3D1B: 34          inc  (hl)
3D1C: 85          add  a,l
3D1D: 65          ld   h,l
3D1E: 84          add  a,h
3D1F: 54          ld   d,h
3D20: F5          push af
3D21: E5          push hl
3D22: E4 45 02    call po,$2045
3D25: 14          inc  d
3D26: C4 05 95    call nz,$5941
3D29: 45          ld   b,l
3D2A: 34          inc  (hl)
3D2B: 02          ld   (bc),a
3D2C: 04          inc  b
3D2D: B4          or   h
3D2E: 1D          dec  e
3D2F: 55          ld   d,l
3D30: 14          inc  d
3D31: 34          inc  (hl)
3D32: 85          add  a,l
3D33: 65          ld   h,l
3D34: 84          add  a,h
3D35: 54          ld   d,h
3D36: F5          push af
3D37: 54          ld   d,h
3D38: 75          ld   (hl),l
3D39: E5          push hl
3D3A: 02          ld   (bc),a
3D3B: 14          inc  d
3D3C: C4 05 95    call nz,$5941
3D3F: 45          ld   b,l
3D40: 34          inc  (hl)
3D41: 35          dec  (hl)
3D42: 04          inc  b
3D43: 91          sub  c
3D44: 3C          inc  a
3D45: 44          ld   b,h
3D46: 85          add  a,l
3D47: 64          ld   h,h
3D48: 64          ld   h,h
3D49: 85          add  a,l
3D4A: 25          dec  h
3D4B: 55          ld   d,l
3D4C: C4 54 04    call nz,$4054
3D4F: 91          sub  c
3D50: 3C          inc  a
3D51: E4 E5 34    call po,$524F
3D54: C5          push bc
3D55: 05          dec  b
3D56: C4 02 02    call nz,$2020
3D59: 02          ld   (bc),a
3D5A: 04          inc  b
3D5B: 75          ld   (hl),l
3D5C: 1C          inc  e
3D5D: 02          ld   (bc),a
3D5E: 64          ld   h,h
3D5F: 85          add  a,l
3D60: 34          inc  (hl)
3D61: 35          dec  (hl)
3D62: 54          ld   d,h
3D63: 02          ld   (bc),a
3D64: 24          inc  h
3D65: E5          push hl
3D66: E4 55 35    call po,$5355
3D69: 02          ld   (bc),a
3D6A: 02          ld   (bc),a
3D6B: 13          inc  de
3D6C: 12          ld   (de),a
3D6D: 12          ld   (de),a
3D6E: 12          ld   (de),a
3D6F: 12          ld   (de),a
3D70: 14          inc  d
3D71: 54          ld   d,h
3D72: 35          dec  (hl)
3D73: 04          inc  b
3D74: 7A          ld   a,d
3D75: 1C          inc  e
3D76: 05          dec  b
3D77: E4 44 02    call po,$2044
3D7A: 05          dec  b
3D7B: 64          ld   h,h
3D7C: 54          ld   d,h
3D7D: 45          ld   b,l
3D7E: 34          inc  (hl)
3D7F: 02          ld   (bc),a
3D80: 02          ld   (bc),a
3D81: 53          ld   d,e
3D82: 12          ld   (de),a
3D83: 12          ld   (de),a
3D84: 12          ld   (de),a
3D85: 12          ld   (de),a
3D86: 14          inc  d
3D87: 54          ld   d,h
3D88: 35          dec  (hl)
3D89: 04          inc  b
3D8A: 21 D2 F2    ld   hl,$3E3C
3D8D: 06 30       ld   b,$12
3D8F: CD 6C B3    call $3BC6
3D92: 10 BF       djnz $3D8F
3D94: 3A 60 0E    ld   a,($E006)
3D97: 4F          ld   c,a
3D98: 21 32 3C    ld   hl,$D232
3D9B: 11 02 00    ld   de,$0020
3D9E: 06 80       ld   b,$08
3DA0: E6 01       and  $01
3DA2: 77          ld   (hl),a
3DA3: 19          add  hl,de
3DA4: CB 09       rrc  c
3DA6: 79          ld   a,c
3DA7: 10 7F       djnz $3DA0
3DA9: 3A 61 0E    ld   a,($E007)
3DAC: 4F          ld   c,a
3DAD: 21 13 3C    ld   hl,$D231
3DB0: 06 80       ld   b,$08
3DB2: E6 01       and  $01
3DB4: 77          ld   (hl),a
3DB5: 19          add  hl,de
3DB6: CB 09       rrc  c
3DB8: 79          ld   a,c
3DB9: 10 7F       djnz $3DB2
3DBB: 3A 40 0E    ld   a,($E004)
3DBE: 4F          ld   c,a
3DBF: 21 CA 1D    ld   hl,$D1AC
3DC2: 06 40       ld   b,$04
3DC4: E6 01       and  $01
3DC6: 77          ld   (hl),a
3DC7: 23          inc  hl
3DC8: CB 09       rrc  c
3DCA: 79          ld   a,c
3DCB: 10 7F       djnz $3DC4
3DCD: 21 AB 1D    ld   hl,$D1AB
3DD0: E6 01       and  $01
3DD2: 77          ld   (hl),a
3DD3: 2B          dec  hl
3DD4: CB 09       rrc  c
3DD6: 79          ld   a,c
3DD7: E6 01       and  $01
3DD9: 77          ld   (hl),a
3DDA: 3A 41 0E    ld   a,($E005)
3DDD: 4F          ld   c,a
3DDE: 21 C8 3D    ld   hl,$D38C
3DE1: 06 40       ld   b,$04
3DE3: E6 01       and  $01
3DE5: 77          ld   (hl),a
3DE6: 23          inc  hl
3DE7: CB 09       rrc  c
3DE9: 79          ld   a,c
3DEA: 10 7F       djnz $3DE3
3DEC: 21 A9 3D    ld   hl,$D38B
3DEF: E6 01       and  $01
3DF1: 77          ld   (hl),a
3DF2: 2B          dec  hl
3DF3: CB 09       rrc  c
3DF5: 79          ld   a,c
3DF6: E6 01       and  $01
3DF8: 77          ld   (hl),a
3DF9: 3A 21 0E    ld   a,($E003)
3DFC: 47          ld   b,a
3DFD: E6 01       and  $01
3DFF: 21 89 3D    ld   hl,$D389
3E02: 77          ld   (hl),a
3E03: 2B          dec  hl
3E04: CB 08       rrc  b
3E06: 78          ld   a,b
3E07: E6 01       and  $01
3E09: 77          ld   (hl),a
3E0A: 3A 21 0E    ld   a,($E003)
3E0D: 07          rlca
3E0E: 47          ld   b,a
3E0F: 21 8A 1D    ld   hl,$D1A8
3E12: E6 01       and  $01
3E14: 77          ld   (hl),a
3E15: 23          inc  hl
3E16: CB 00       rlc  b
3E18: 78          ld   a,b
3E19: E6 01       and  $01
3E1B: 77          ld   (hl),a
3E1C: 21 64 1C    ld   hl,$D046
3E1F: 06 A1       ld   b,$0B
3E21: CD 9D B3    call $3BD9
3E24: 21 33 F2    ld   hl,$3E33
3E27: CD 6C B3    call $3BC6
3E2A: 21 66 3C    ld   hl,$D266
3E2D: 06 A1       ld   b,$0B
3E2F: CD 9D B3    call $3BD9
3E32: C9          ret
3E33: 6A          ld   l,d
3E34: 1D          dec  e
3E35: E5          push hl
3E36: 55          ld   d,l
3E37: 54          ld   d,h
3E38: 14          inc  d
3E39: 55          ld   d,l
3E3A: 54          ld   d,h
3E3B: 04          inc  b
3E3C: 34          inc  (hl)
3E3D: 1C          inc  e
3E3E: 02          ld   (bc),a
3E3F: 44          ld   b,h
3E40: 85          add  a,l
3E41: 14          inc  d
3E42: 02          ld   (bc),a
3E43: 35          dec  (hl)
3E44: 75          ld   (hl),l
3E45: 85          add  a,l
3E46: 25          dec  h
3E47: 54          ld   d,h
3E48: 84          add  a,h
3E49: 02          ld   (bc),a
3E4A: 05          dec  b
3E4B: 04          inc  b
3E4C: 15          dec  d
3E4D: 1C          inc  e
3E4E: 02          ld   (bc),a
3E4F: 44          ld   b,h
3E50: 85          add  a,l
3E51: 14          inc  d
3E52: 02          ld   (bc),a
3E53: 35          dec  (hl)
3E54: 75          ld   (hl),l
3E55: 85          add  a,l
3E56: 25          dec  h
3E57: 54          ld   d,h
3E58: 84          add  a,h
3E59: 02          ld   (bc),a
3E5A: 24          inc  h
3E5B: 04          inc  b
3E5C: E5          push hl
3E5D: 1C          inc  e
3E5E: 02          ld   (bc),a
3E5F: 13          inc  de
3E60: 14          inc  d
3E61: 02          ld   (bc),a
3E62: 55          ld   d,l
3E63: 14          inc  d
3E64: 04          inc  b
3E65: E4 1C 02    call po,$20D0
3E68: 13          inc  de
3E69: 14          inc  d
3E6A: 02          ld   (bc),a
3E6B: 44          ld   b,h
3E6C: E5          push hl
3E6D: 75          ld   (hl),l
3E6E: E4 04 C5    call po,$4D40
3E71: 1C          inc  e
3E72: 02          ld   (bc),a
3E73: 13          inc  de
3E74: 14          inc  d
3E75: 02          ld   (bc),a
3E76: C4 45 64    call nz,$4645
3E79: 54          ld   d,h
3E7A: 04          inc  b
3E7B: C4 1C 02    call nz,$20D0
3E7E: 13          inc  de
3E7F: 14          inc  d
3E80: 02          ld   (bc),a
3E81: 34          inc  (hl)
3E82: 85          add  a,l
3E83: 65          ld   h,l
3E84: 84          add  a,h
3E85: 54          ld   d,h
3E86: 04          inc  b
3E87: A5          and  l
3E88: 1C          inc  e
3E89: 02          ld   (bc),a
3E8A: 13          inc  de
3E8B: 14          inc  d
3E8C: 02          ld   (bc),a
3E8D: 35          dec  (hl)
3E8E: 84          add  a,h
3E8F: E5          push hl
3E90: E5          push hl
3E91: 54          ld   d,h
3E92: 13          inc  de
3E93: 04          inc  b
3E94: A4          and  h
3E95: 1C          inc  e
3E96: 02          ld   (bc),a
3E97: 13          inc  de
3E98: 14          inc  d
3E99: 02          ld   (bc),a
3E9A: 35          dec  (hl)
3E9B: 84          add  a,h
3E9C: E5          push hl
3E9D: E5          push hl
3E9E: 54          ld   d,h
3E9F: 32 04 85    ld   ($4940),a
3EA2: 1C          inc  e
3EA3: 02          ld   (bc),a
3EA4: 25          dec  h
3EA5: E5          push hl
3EA6: 85          add  a,l
3EA7: E4 13 04    call po,$4031
3EAA: 84          add  a,h
3EAB: 1C          inc  e
3EAC: 02          ld   (bc),a
3EAD: 25          dec  h
3EAE: E5          push hl
3EAF: 85          add  a,l
3EB0: E4 32 04    call po,$4032
3EB3: E5          push hl
3EB4: 3C          inc  a
3EB5: 32 14 02    ld   ($2050),a
3EB8: 55          ld   d,l
3EB9: 14          inc  d
3EBA: 04          inc  b
3EBB: E4 3C 32    call po,$32D2
3EBE: 14          inc  d
3EBF: 02          ld   (bc),a
3EC0: 44          ld   b,h
3EC1: E5          push hl
3EC2: 75          ld   (hl),l
3EC3: E4 04 C5    call po,$4D40
3EC6: 3C          inc  a
3EC7: 32 14 02    ld   ($2050),a
3ECA: C4 45 64    call nz,$4645
3ECD: 54          ld   d,h
3ECE: 04          inc  b
3ECF: C4 3C 32    call nz,$32D2
3ED2: 14          inc  d
3ED3: 02          ld   (bc),a
3ED4: 34          inc  (hl)
3ED5: 85          add  a,l
3ED6: 65          ld   h,l
3ED7: 84          add  a,h
3ED8: 54          ld   d,h
3ED9: 04          inc  b
3EDA: A5          and  l
3EDB: 3C          inc  a
3EDC: 32 14 02    ld   ($2050),a
3EDF: 35          dec  (hl)
3EE0: 84          add  a,h
3EE1: E5          push hl
3EE2: E5          push hl
3EE3: 54          ld   d,h
3EE4: 13          inc  de
3EE5: 04          inc  b
3EE6: A4          and  h
3EE7: 3C          inc  a
3EE8: 32 14 02    ld   ($2050),a
3EEB: 35          dec  (hl)
3EEC: 84          add  a,h
3EED: E5          push hl
3EEE: E5          push hl
3EEF: 54          ld   d,h
3EF0: 32 04 85    ld   ($4940),a
3EF3: 3C          inc  a
3EF4: 13          inc  de
3EF5: 14          inc  d
3EF6: F5          push af
3EF7: 35          dec  (hl)
3EF8: 54          ld   d,h
3EF9: 05          dec  b
3EFA: 34          inc  (hl)
3EFB: 54          ld   d,h
3EFC: 04          inc  b
3EFD: 84          add  a,h
3EFE: 3C          inc  a
3EFF: 32 14 F5    ld   ($5F50),a
3F02: 35          dec  (hl)
3F03: 54          ld   d,h
3F04: 05          dec  b
3F05: 34          inc  (hl)
3F06: 54          ld   d,h
3F07: 04          inc  b
3F08: 21 C5 F3    ld   hl,$3F4D
3F0B: 06 41       ld   b,$05
3F0D: CD 6C B3    call $3BC6
3F10: 10 BF       djnz $3F0D
3F12: 3A 44 0E    ld   a,($E044)
3F15: 21 48 3C    ld   hl,$D284
3F18: 0E 00       ld   c,$00
3F1A: CD D8 D8    call $9C9C
3F1D: 21 44 0E    ld   hl,$E044
3F20: CD 12 F3    call $3F30
3F23: 3A C0 0E    ld   a,($E00C)
3F26: E6 61       and  $07
3F28: FE 01       cp   $01
3F2A: C0          ret  nz
3F2B: 7E          ld   a,(hl)
3F2C: 32 B2 0E    ld   ($E03A),a
3F2F: C9          ret
3F30: 3A 80 0E    ld   a,($E008)
3F33: E6 61       and  $07
3F35: FE 01       cp   $01
3F37: 28 E0       jr   z,$3F47
3F39: 3A 81 0E    ld   a,($E009)
3F3C: E6 61       and  $07
3F3E: FE 01       cp   $01
3F40: C0          ret  nz
3F41: 35          dec  (hl)
3F42: 7E          ld   a,(hl)
3F43: E6 F3       and  $3F
3F45: 77          ld   (hl),a
3F46: C9          ret
3F47: 34          inc  (hl)
3F48: 7E          ld   a,(hl)
3F49: E6 F3       and  $3F
3F4B: 77          ld   (hl),a
3F4C: C9          ret
3F4D: 44          ld   b,h
3F4E: 1C          inc  e
3F4F: 02          ld   (bc),a
3F50: 54          ld   d,h
3F51: 45          ld   b,l
3F52: 35          dec  (hl)
3F53: 54          ld   d,h
3F54: 02          ld   (bc),a
3F55: 35          dec  (hl)
3F56: E5          push hl
3F57: 55          ld   d,l
3F58: E4 44 02    call po,$2044
3F5B: 25          dec  h
3F5C: E5          push hl
3F5D: 44          ld   b,h
3F5E: 45          ld   b,l
3F5F: 04          inc  b
3F60: 24          inc  h
3F61: 1C          inc  e
3F62: 02          ld   (bc),a
3F63: 25          dec  h
3F64: E5          push hl
3F65: 55          ld   d,l
3F66: E4 54 45    call po,$4554
3F69: 34          inc  (hl)
3F6A: 13          inc  de
3F6B: 02          ld   (bc),a
3F6C: D3 04       out  ($40),a
3F6E: 05          dec  b
3F6F: 1C          inc  e
3F70: 02          ld   (bc),a
3F71: 25          dec  h
3F72: E5          push hl
3F73: 55          ld   d,l
3F74: E4 54 45    call po,$4554
3F77: 34          inc  (hl)
3F78: 32 02 D3    ld   ($3D20),a
3F7B: 04          inc  b
3F7C: 2C          inc  l
3F7D: 1D          dec  e
3F7E: 14          inc  d
3F7F: 55          ld   d,l
3F80: 35          dec  (hl)
3F81: 84          add  a,h
3F82: 02          ld   (bc),a
3F83: 13          inc  de
3F84: 14          inc  d
3F85: 02          ld   (bc),a
3F86: 35          dec  (hl)
3F87: 54          ld   d,h
3F88: 05          dec  b
3F89: 34          inc  (hl)
3F8A: 54          ld   d,h
3F8B: 04          inc  b
3F8C: 0D          dec  c
3F8D: 1D          dec  e
3F8E: 14          inc  d
3F8F: 55          ld   d,l
3F90: 35          dec  (hl)
3F91: 84          add  a,h
3F92: 02          ld   (bc),a
3F93: 32 14 02    ld   ($2050),a
3F96: 35          dec  (hl)
3F97: 54          ld   d,h
3F98: 05          dec  b
3F99: 34          inc  (hl)
3F9A: 54          ld   d,h
3F9B: 04          inc  b
3F9C: FF          rst  $38
3F9D: 00          nop
3F9E: FF          rst  $38
3F9F: 00          nop
3FA0: 00          nop
3FA1: FF          rst  $38
3FA2: 00          nop
3FA3: FF          rst  $38
3FA4: 00          nop
3FA5: FF          rst  $38
3FA6: 00          nop
3FA7: FF          rst  $38
3FA8: 00          nop
3FA9: FF          rst  $38
3FAA: 00          nop
3FAB: FF          rst  $38
3FAC: 00          nop
3FAD: FF          rst  $38
3FAE: 00          nop
3FAF: FF          rst  $38
3FB0: FF          rst  $38
3FB1: 00          nop
3FB2: FF          rst  $38
3FB3: 00          nop
3FB4: FF          rst  $38
3FB5: 00          nop
3FB6: FF          rst  $38
3FB7: 00          nop
3FB8: FF          rst  $38
3FB9: 00          nop
3FBA: FF          rst  $38
3FBB: 00          nop
3FBC: FF          rst  $38
3FBD: 00          nop
3FBE: FF          rst  $38
3FBF: 00          nop
3FC0: 12          ld   (de),a
3FC1: FF          rst  $38
3FC2: 00          nop
3FC3: FF          rst  $38
3FC4: 00          nop
3FC5: FF          rst  $38
3FC6: 00          nop
3FC7: FF          rst  $38
3FC8: 00          nop
3FC9: FF          rst  $38
3FCA: 00          nop
3FCB: FF          rst  $38
3FCC: 00          nop
3FCD: FF          rst  $38
3FCE: 00          nop
3FCF: FF          rst  $38
3FD0: FF          rst  $38
3FD1: 00          nop
3FD2: FF          rst  $38
3FD3: 00          nop
3FD4: FF          rst  $38
3FD5: 00          nop
3FD6: FF          rst  $38
3FD7: 00          nop
3FD8: FF          rst  $38
3FD9: 00          nop
3FDA: FF          rst  $38
3FDB: 00          nop
3FDC: FF          rst  $38
3FDD: 00          nop
3FDE: FF          rst  $38
3FDF: 00          nop
3FE0: 00          nop
3FE1: FF          rst  $38
3FE2: 00          nop
3FE3: FF          rst  $38
3FE4: 00          nop
3FE5: FF          rst  $38
3FE6: 00          nop
3FE7: FF          rst  $38
3FE8: 00          nop
3FE9: FF          rst  $38
3FEA: 00          nop
3FEB: FF          rst  $38
3FEC: 00          nop
3FED: FF          rst  $38
3FEE: 00          nop
3FEF: FF          rst  $38
3FF0: FF          rst  $38
3FF1: 00          nop
3FF2: FF          rst  $38
3FF3: 00          nop
3FF4: FF          rst  $38
3FF5: 00          nop
3FF6: FF          rst  $38
3FF7: 00          nop
3FF8: FF          rst  $38
3FF9: 00          nop
3FFA: FF          rst  $38
3FFB: 00          nop
3FFC: FF          rst  $38
3FFD: 00          nop
3FFE: FF          rst  $38
3FFF: 00          nop
4000: 08          ex   af,af'
4001: A0          and  b
4002: 10 00       djnz $4004
4004: 0A          ld   a,(bc)
4005: A0          and  b
4006: 90          sub  b
4007: 00          nop
4008: 18 A0       jr   $4014
400A: 02          ld   (bc),a
400B: 00          nop
400C: 10 A0       djnz $4018
400E: 06 00       ld   b,$00
4010: 1C          inc  e
4011: A0          and  b
4012: 86          add  a,(hl)
4013: 00          nop
4014: 14          inc  d
4015: A0          and  b
4016: 0E 00       ld   c,$00
4018: 08          ex   af,af'
4019: A0          and  b
401A: 10 01       djnz $401D
401C: 0A          ld   a,(bc)
401D: A0          and  b
401E: 90          sub  b
401F: 01 18 A0    ld   bc,$0A90
4022: 02          ld   (bc),a
4023: 01 14 A0    ld   bc,$0A50
4026: 06 01       ld   b,$01
4028: 00          nop
4029: A0          and  b
402A: 1C          inc  e
402B: 01 02 A0    ld   bc,$0A20
402E: 9C          sbc  a,h
402F: 01 10 A0    ld   bc,$0A10
4032: 0E 01       ld   c,$01
4034: 18 A0       jr   $4040
4036: 8E          adc  a,(hl)
4037: 01 14 A0    ld   bc,$0A50
403A: 02          ld   (bc),a
403B: 20 18       jr   nz,$3FCD
403D: A0          and  b
403E: 06 20       ld   b,$02
4040: 1C          inc  e
4041: A0          and  b
4042: 0A          ld   a,(bc)
4043: 20 10       jr   nz,$4055
4045: A0          and  b
4046: 06 21       ld   b,$03
4048: 18 A0       jr   $4054
404A: 86          add  a,(hl)
404B: 21 14 A0    ld   hl,$0A50
404E: 0A          ld   a,(bc)
404F: 21 16 00    ld   hl,$0070
4052: 19          add  hl,de
4053: 40          ld   b,b
4054: 10 00       djnz $4056
4056: 1B          dec  de
4057: 40          ld   b,b
4058: 0E 00       ld   c,$00
405A: 1D          dec  e
405B: 40          ld   b,b
405C: 04          inc  b
405D: 00          nop
405E: 1F          rra
405F: 40          ld   b,b
4060: 0A          ld   a,(bc)
4061: 00          nop
4062: 11 41 10    ld   de,$1005
4065: 00          nop
4066: 17          rla
4067: 41          ld   b,c
4068: 16 00       ld   d,$00
406A: 17          rla
406B: 41          ld   b,c
406C: 1C          inc  e
406D: 00          nop
406E: 17          rla
406F: 41          ld   b,c
4070: 10 A0       djnz $407C
4072: 02          ld   (bc),a
4073: B0          or   b
4074: 08          ex   af,af'
4075: A0          and  b
4076: 14          inc  d
4077: B0          or   b
4078: 0A          ld   a,(bc)
4079: A0          and  b
407A: 94          sub  h
407B: B0          or   b
407C: 18 A0       jr   $4088
407E: 06 B0       ld   b,$1A
4080: 0A          ld   a,(bc)
4081: A0          and  b
4082: 02          ld   (bc),a
4083: D0          ret  nc
4084: 10 00       djnz $4086
4086: 17          rla
4087: 02          ld   (bc),a
4088: 16 00       ld   d,$00
408A: 17          rla
408B: 02          ld   (bc),a
408C: 1C          inc  e
408D: 00          nop
408E: 17          rla
408F: 02          ld   (bc),a
4090: 10 A0       djnz $409C
4092: 06 03       ld   b,$21
4094: 18 A0       jr   $40A0
4096: 86          add  a,(hl)
4097: 03          inc  bc
4098: 14          inc  d
4099: A0          and  b
409A: 0A          ld   a,(bc)
409B: 03          inc  bc
409C: 0A          ld   a,(bc)
409D: 00          nop
409E: 11 23 10    ld   de,$1023
40A1: 00          nop
40A2: 17          rla
40A3: 23          inc  hl
40A4: 16 00       ld   d,$00
40A6: 17          rla
40A7: 23          inc  hl
40A8: 1C          inc  e
40A9: 00          nop
40AA: 17          rla
40AB: 23          inc  hl
40AC: 14          inc  d
40AD: A0          and  b
40AE: 02          ld   (bc),a
40AF: 42          ld   b,d
40B0: 14          inc  d
40B1: A0          and  b
40B2: 02          ld   (bc),a
40B3: 04          inc  b
40B4: 04          inc  b
40B5: A0          and  b
40B6: 1C          inc  e
40B7: 05          dec  b
40B8: 06 A0       ld   b,$0A
40BA: 9C          sbc  a,h
40BB: 05          dec  b
40BC: 14          inc  d
40BD: A0          and  b
40BE: 0E 05       ld   c,$41
40C0: 04          inc  b
40C1: A0          and  b
40C2: 1C          inc  e
40C3: 24          inc  h
40C4: 06 A0       ld   b,$0A
40C6: 9C          sbc  a,h
40C7: 24          inc  h
40C8: 14          inc  d
40C9: A0          and  b
40CA: 0E 24       ld   c,$42
40CC: 0A          ld   a,(bc)
40CD: 00          nop
40CE: 11 45 12    ld   de,$3045
40D1: 00          nop
40D2: 13          inc  de
40D3: 45          ld   b,l
40D4: 02          ld   (bc),a
40D5: 00          nop
40D6: 19          add  hl,de
40D7: 45          ld   b,l
40D8: 16 00       ld   d,$00
40DA: 1B          dec  de
40DB: 45          ld   b,l
40DC: 1A          ld   a,(de)
40DD: 00          nop
40DE: 1D          dec  e
40DF: 45          ld   b,l
40E0: 10 00       djnz $40E2
40E2: 13          inc  de
40E3: 64          ld   h,h
40E4: 06 00       ld   b,$00
40E6: 15          dec  d
40E7: 64          ld   h,h
40E8: 18 00       jr   $40EA
40EA: 17          rla
40EB: 64          ld   h,h
40EC: 0C          inc  c
40ED: 00          nop
40EE: 1B          dec  de
40EF: 64          ld   h,h
40F0: 10 00       djnz $40F2
40F2: 17          rla
40F3: 06 16       ld   b,$70
40F5: 00          nop
40F6: 17          rla
40F7: 06 1C       ld   b,$D0
40F9: 00          nop
40FA: 17          rla
40FB: 06 10       ld   b,$10
40FD: A0          and  b
40FE: 06 07       ld   b,$61
4100: 18 A0       jr   $410C
4102: 86          add  a,(hl)
4103: 07          rlca
4104: 14          inc  d
4105: A0          and  b
4106: 0A          ld   a,(bc)
4107: 07          rlca
4108: 0A          ld   a,(bc)
4109: 00          nop
410A: 11 27 10    ld   de,$1063
410D: 00          nop
410E: 17          rla
410F: 27          daa
4110: 16 00       ld   d,$00
4112: 17          rla
4113: 27          daa
4114: 1C          inc  e
4115: 00          nop
4116: 17          rla
4117: 27          daa
4118: 08          ex   af,af'
4119: A0          and  b
411A: 10 46       djnz $4180
411C: 0A          ld   a,(bc)
411D: A0          and  b
411E: 90          sub  b
411F: 46          ld   b,(hl)
4120: 18 A0       jr   $412C
4122: 02          ld   (bc),a
4123: 46          ld   b,(hl)
4124: 10 A0       djnz $4130
4126: 06 46       ld   b,$64
4128: 1C          inc  e
4129: A0          and  b
412A: 86          add  a,(hl)
412B: 46          ld   b,(hl)
412C: 14          inc  d
412D: A0          and  b
412E: 0E 46       ld   c,$64
4130: 0A          ld   a,(bc)
4131: 00          nop
4132: 02          ld   (bc),a
4133: FF          rst  $38
4134: E0          ret  po
4135: E1          pop  hl
4136: B0          or   b
4137: 02          ld   (bc),a
4138: 03          inc  bc
4139: F1          pop  af
413A: D1          pop  de
413B: 22 63 C2    ld   ($2C27),hl
413E: B1          or   c
413F: 00          nop
4140: 30 31       jr   nc,$4155
4142: 23          inc  hl
4143: 43          ld   b,e
4144: D1          pop  de
4145: 81          add  a,c
4146: B0          or   b
4147: 52          ld   d,d
4148: 63          ld   h,e
4149: E2 12 A1    jp   po,$0B30
414C: A4          and  h
414D: 83          add  a,e
414E: 62          ld   h,d
414F: 01 B0 02    ld   bc,$201A
4152: 42          ld   b,d
4153: 43          ld   b,e
4154: F0          ret  p
4155: D0          ret  nc
4156: 78          ld   a,b
4157: 02          ld   (bc),a
4158: C0          ret  nz
4159: 52          ld   d,d
415A: 03          inc  bc
415B: 81          add  a,c
415C: 20 21       jr   nz,$4161
415E: 83          add  a,e
415F: E2 52 50    jp   po,$1434
4162: 51          ld   d,c
4163: 83          add  a,e
4164: 52          ld   d,d
4165: 02          ld   (bc),a
4166: F1          pop  af
4167: 52          ld   d,d
4168: 03          inc  bc
4169: C2 42 43    jp   nz,$2524
416C: 23          inc  hl
416D: D0          ret  nc
416E: 52          ld   d,d
416F: 52          ld   d,d
4170: 52          ld   d,d
4171: 52          ld   d,d
4172: 52          ld   d,d
4173: 78          ld   a,b
4174: 8D          adc  a,l
4175: AC          xor  h
4176: AD          xor  l
4177: CC 89 88    call z,$8889
417A: 69          ld   l,c
417B: 68          ld   l,b
417C: E3          ex   (sp),hl
417D: 32 33 52    ld   ($3433),a
4180: 52          ld   d,d
4181: D2 52 C3    jp   nc,$2D34
4184: 52          ld   d,d
4185: 52          ld   d,d
4186: C3 52 E3    jp   $2F34
4189: A2          and  d
418A: A3          and  e
418B: E3          ex   (sp),hl
418C: 52          ld   d,d
418D: 52          ld   d,d
418E: 52          ld   d,d
418F: 52          ld   d,d
4190: 52          ld   d,d
4191: 78          ld   a,b
4192: 52          ld   d,d
4193: 52          ld   d,d
4194: 52          ld   d,d
4195: 52          ld   d,d
4196: 6C          ld   l,h
4197: 6D          ld   l,l
4198: 78          ld   a,b
4199: 52          ld   d,d
419A: 52          ld   d,d
419B: 52          ld   d,d
419C: 52          ld   d,d
419D: 8C          adc  a,h
419E: 6D          ld   l,l
419F: 52          ld   d,d
41A0: 79          ld   a,c
41A1: 98          sbc  a,b
41A2: 52          ld   d,d
41A3: 52          ld   d,d
41A4: 52          ld   d,d
41A5: 52          ld   d,d
41A6: 52          ld   d,d
41A7: 78          ld   a,b
41A8: 52          ld   d,d
41A9: 52          ld   d,d
41AA: 52          ld   d,d
41AB: 52          ld   d,d
41AC: 52          ld   d,d
41AD: 52          ld   d,d
41AE: 52          ld   d,d
41AF: 52          ld   d,d
41B0: 54          ld   d,h
41B1: 55          ld   d,l
41B2: 74          ld   (hl),h
41B3: 75          ld   (hl),l
41B4: 59          ld   e,c
41B5: F9          ld   sp,hl
41B6: 59          ld   e,c
41B7: F9          ld   sp,hl
41B8: F9          ld   sp,hl
41B9: 59          ld   e,c
41BA: F9          ld   sp,hl
41BB: 59          ld   e,c
41BC: 59          ld   e,c
41BD: F9          ld   sp,hl
41BE: 59          ld   e,c
41BF: F9          ld   sp,hl
41C0: F9          ld   sp,hl
41C1: 59          ld   e,c
41C2: F9          ld   sp,hl
41C3: 59          ld   e,c
41C4: 59          ld   e,c
41C5: F9          ld   sp,hl
41C6: 59          ld   e,c
41C7: F9          ld   sp,hl
41C8: F9          ld   sp,hl
41C9: 59          ld   e,c
41CA: F9          ld   sp,hl
41CB: 59          ld   e,c
41CC: 59          ld   e,c
41CD: F9          ld   sp,hl
41CE: 59          ld   e,c
41CF: F9          ld   sp,hl
41D0: 3D          dec  a
41D1: 5A          ld   e,d
41D2: F9          ld   sp,hl
41D3: 59          ld   e,c
41D4: 59          ld   e,c
41D5: F9          ld   sp,hl
41D6: EC ED 1C    call pe,$D0CF
41D9: ED          db   $ed
41DA: 3D          dec  a
41DB: 3C          inc  a
41DC: 59          ld   e,c
41DD: EC ED F9    call pe,$9FCF
41E0: F9          ld   sp,hl
41E1: 59          ld   e,c
41E2: 1D          dec  e
41E3: 1C          inc  e
41E4: 3D          dec  a
41E5: 5A          ld   e,d
41E6: 59          ld   e,c
41E7: F9          ld   sp,hl
41E8: F9          ld   sp,hl
41E9: 1D          dec  e
41EA: 1C          inc  e
41EB: 82          add  a,d
41EC: 1D          dec  e
41ED: 82          add  a,d
41EE: 59          ld   e,c
41EF: F9          ld   sp,hl
41F0: F9          ld   sp,hl
41F1: 59          ld   e,c
41F2: F9          ld   sp,hl
41F3: 59          ld   e,c
41F4: FA FB 0C    jp   m,$C0BF
41F7: 0D          dec  c
41F8: 49          ld   c,c
41F9: 48          ld   c,b
41FA: 29          add  hl,hl
41FB: 28 F9       jr   z,$419C
41FD: 59          ld   e,c
41FE: F9          ld   sp,hl
41FF: 59          ld   e,c
4200: B9          cp   c
4201: D8          ret  c
4202: 59          ld   e,c
4203: F9          ld   sp,hl
4204: D9          exx
4205: 59          ld   e,c
4206: F9          ld   sp,hl
4207: 59          ld   e,c
4208: C5          push bc
4209: E5          push hl
420A: 15          dec  d
420B: 35          dec  (hl)
420C: C4 E4 14    call nz,$504E
420F: 34          inc  (hl)
4210: 99          sbc  a,c
4211: F9          ld   sp,hl
4212: 59          ld   e,c
4213: F9          ld   sp,hl
4214: F9          ld   sp,hl
4215: 59          ld   e,c
4216: F9          ld   sp,hl
4217: 59          ld   e,c
4218: 59          ld   e,c
4219: F9          ld   sp,hl
421A: 59          ld   e,c
421B: B8          cp   b
421C: F9          ld   sp,hl
421D: 59          ld   e,c
421E: F9          ld   sp,hl
421F: 59          ld   e,c
4220: 99          sbc  a,c
4221: F9          ld   sp,hl
4222: 59          ld   e,c
4223: 60          ld   h,b
4224: B3          or   e
4225: 59          ld   e,c
4226: F9          ld   sp,hl
4227: 61          ld   h,c
4228: F3          di
4229: F9          ld   sp,hl
422A: 59          ld   e,c
422B: 61          ld   h,c
422C: F3          di
422D: 59          ld   e,c
422E: F9          ld   sp,hl
422F: 61          ld   h,c
4230: 53          ld   d,e
4231: 7A          ld   a,d
4232: 7B          ld   a,e
4233: 13          inc  de
4234: 05          dec  b
4235: 04          inc  b
4236: 05          dec  b
4237: 04          inc  b
4238: 04          inc  b
4239: 1A          ld   a,(de)
423A: 04          inc  b
423B: EB          ex   de,hl
423C: 05          dec  b
423D: 04          inc  b
423E: 3B          dec  sp
423F: 04          inc  b
4240: 3B          dec  sp
4241: 05          dec  b
4242: 04          inc  b
4243: 05          dec  b
4244: 05          dec  b
4245: EB          ex   de,hl
4246: EA 04 3A    jp   pe,$B240
4249: 1B          dec  de
424A: 3A 1B EA    ld   a,($AEB1)
424D: 05          dec  b
424E: 1A          ld   a,(de)
424F: 05          dec  b
4250: 05          dec  b
4251: 3B          dec  sp
4252: 05          dec  b
4253: 04          inc  b
4254: 04          inc  b
4255: 05          dec  b
4256: 04          inc  b
4257: 1A          ld   a,(de)
4258: 3B          dec  sp
4259: 04          inc  b
425A: CB CA       set  1,d
425C: 04          inc  b
425D: 3A 1B 05    ld   a,($41B1)
4260: EB          ex   de,hl
4261: EA 05 EB    jp   pe,$AF41
4264: CB CA       set  1,d
4266: 3B          dec  sp
4267: 05          dec  b
4268: 05          dec  b
4269: 3B          dec  sp
426A: AB          xor  e
426B: CA AB CA    jp   z,$ACAB
426E: EB          ex   de,hl
426F: EA 05 04    jp   pe,$4041
4272: 05          dec  b
4273: 04          inc  b
4274: AA          xor  d
4275: 8B          adc  a,e
4276: 8A          adc  a,d
4277: F8          ret  m
4278: 39          add  hl,sp
4279: E8          ret  pe
427A: A8          xor  b
427B: CD 04 24    call $4240
427E: 04          inc  b
427F: 05          dec  b
4280: 05          dec  b
4281: 04          inc  b
4282: 05          dec  b
4283: 04          inc  b
4284: 04          inc  b
4285: 05          dec  b
4286: 04          inc  b
4287: 05          dec  b
4288: 05          dec  b
4289: 04          inc  b
428A: 05          dec  b
428B: 04          inc  b
428C: 04          inc  b
428D: 05          dec  b
428E: 04          inc  b
428F: 05          dec  b
4290: 05          dec  b
4291: 04          inc  b
4292: 05          dec  b
4293: 04          inc  b
4294: 04          inc  b
4295: 05          dec  b
4296: 04          inc  b
4297: 05          dec  b
4298: 05          dec  b
4299: 04          inc  b
429A: 05          dec  b
429B: 04          inc  b
429C: 04          inc  b
429D: 05          dec  b
429E: 04          inc  b
429F: 05          dec  b
42A0: 05          dec  b
42A1: 04          inc  b
42A2: 05          dec  b
42A3: 04          inc  b
42A4: 04          inc  b
42A5: 05          dec  b
42A6: 04          inc  b
42A7: 05          dec  b
42A8: 05          dec  b
42A9: 04          inc  b
42AA: 05          dec  b
42AB: 04          inc  b
42AC: DB 05       in   a,($41)
42AE: 04          inc  b
42AF: 25          dec  h
42B0: 9B          sbc  a,e
42B1: BA          cp   d
42B2: BB          cp   e
42B3: DA 52 52    jp   c,$3434
42B6: 52          ld   d,d
42B7: 52          ld   d,d
42B8: 52          ld   d,d
42B9: 52          ld   d,d
42BA: 52          ld   d,d
42BB: 52          ld   d,d
42BC: 27          daa
42BD: 27          daa
42BE: 26 27       ld   h,$63
42C0: 52          ld   d,d
42C1: 52          ld   d,d
42C2: 52          ld   d,d
42C3: 52          ld   d,d
42C4: 27          daa
42C5: 07          rlca
42C6: 06 27       ld   b,$63
42C8: 52          ld   d,d
42C9: 52          ld   d,d
42CA: 52          ld   d,d
42CB: 52          ld   d,d
42CC: 52          ld   d,d
42CD: 52          ld   d,d
42CE: 52          ld   d,d
42CF: 52          ld   d,d
42D0: 27          daa
42D1: 76          halt
42D2: 27          daa
42D3: 27          daa
42D4: 91          sub  c
42D5: 52          ld   d,d
42D6: 52          ld   d,d
42D7: 52          ld   d,d
42D8: 52          ld   d,d
42D9: 52          ld   d,d
42DA: B0          or   b
42DB: 52          ld   d,d
42DC: 79          ld   a,c
42DD: 98          sbc  a,b
42DE: 71          ld   (hl),c
42DF: 70          ld   (hl),b
42E0: 71          ld   (hl),c
42E1: 70          ld   (hl),b
42E2: 44          ld   b,h
42E3: 44          ld   b,h
42E4: 44          ld   b,h
42E5: 44          ld   b,h
42E6: 44          ld   b,h
42E7: 80          add  a,b
42E8: 44          ld   b,h
42E9: D3 F2       out  ($3E),a
42EB: 11 F2 44    ld   de,$443E
42EE: 65          ld   h,l
42EF: 84          add  a,h
42F0: D3 64       out  ($46),a
42F2: 56          ld   d,(hl)
42F3: 57          ld   d,a
42F4: 73          ld   (hl),e
42F5: 44          ld   b,h
42F6: 90          sub  b
42F7: 37          scf
42F8: 10 45       djnz $433F
42FA: F2 44 70    jp   p,$1644
42FD: 44          ld   b,h
42FE: 44          ld   b,h
42FF: D3 44       out  ($44),a
4301: D3 F2       out  ($3E),a
4303: 44          ld   b,h
4304: F2 44 65    jp   p,$4744
4307: 84          add  a,h
4308: 65          ld   h,l
4309: 84          add  a,h
430A: B2          or   d
430B: 93          sub  e
430C: 52          ld   d,d
430D: 52          ld   d,d
430E: 52          ld   d,d
430F: 92          sub  d
4310: 52          ld   d,d
4311: 52          ld   d,d
4312: 52          ld   d,d
4313: 52          ld   d,d
4314: C8          ret  z
4315: C9          ret
4316: 52          ld   d,d
4317: 52          ld   d,d
4318: A9          xor  c
4319: 52          ld   d,d
431A: 52          ld   d,d
431B: 52          ld   d,d
431C: 52          ld   d,d
431D: 52          ld   d,d
431E: 52          ld   d,d
431F: 52          ld   d,d
4320: 52          ld   d,d
4321: 52          ld   d,d
4322: 52          ld   d,d
4323: 52          ld   d,d
4324: 52          ld   d,d
4325: 52          ld   d,d
4326: 52          ld   d,d
4327: 52          ld   d,d
4328: 52          ld   d,d
4329: 52          ld   d,d
432A: 52          ld   d,d
432B: 52          ld   d,d
432C: 2A 2B 6A    ld   hl,($A6A3)
432F: 6B          ld   l,e
4330: 0A          ld   a,(bc)
4331: 0B          dec  bc
4332: 4A          ld   c,d
4333: 4B          ld   c,e
4334: E9          jp   (hl)
4335: 18 19       jr   $42C8
4337: 38 E3       jr   c,$4368
4339: A2          and  d
433A: A3          and  e
433B: E3          ex   (sp),hl
433C: 52          ld   d,d
433D: 52          ld   d,d
433E: 52          ld   d,d
433F: 52          ld   d,d
4340: 52          ld   d,d
4341: 78          ld   a,b
4342: 52          ld   d,d
4343: 52          ld   d,d
4344: 52          ld   d,d
4345: 02          ld   (bc),a
4346: F1          pop  af
4347: 52          ld   d,d
4348: 03          inc  bc
4349: C2 42 43    jp   nz,$2524
434C: 23          inc  hl
434D: D0          ret  nc
434E: 52          ld   d,d
434F: 52          ld   d,d
4350: 52          ld   d,d
4351: 52          ld   d,d
4352: 52          ld   d,d
4353: 78          ld   a,b
4354: 52          ld   d,d
4355: 52          ld   d,d
4356: 6C          ld   l,h
4357: 6D          ld   l,l
4358: 78          ld   a,b
4359: 52          ld   d,d
435A: 52          ld   d,d
435B: 52          ld   d,d
435C: 52          ld   d,d
435D: 8C          adc  a,h
435E: 6D          ld   l,l
435F: 52          ld   d,d
4360: 79          ld   a,c
4361: 98          sbc  a,b
4362: 52          ld   d,d
4363: 52          ld   d,d
4364: 52          ld   d,d
4365: 52          ld   d,d
4366: C3 52 E3    jp   $2F34
4369: A2          and  d
436A: A3          and  e
436B: E3          ex   (sp),hl
436C: 52          ld   d,d
436D: 52          ld   d,d
436E: 52          ld   d,d
436F: 52          ld   d,d
4370: 52          ld   d,d
4371: 78          ld   a,b
4372: 52          ld   d,d
4373: 52          ld   d,d
4374: 10 91       djnz $438F
4376: 40          ld   b,b
4377: 41          ld   b,c
4378: 52          ld   d,d
4379: 52          ld   d,d
437A: 52          ld   d,d
437B: 52          ld   d,d
437C: 4C          ld   c,h
437D: 4D          ld   c,l
437E: 52          ld   d,d
437F: 52          ld   d,d
4380: 2C          inc  l
4381: 2D          dec  l
4382: 52          ld   d,d
4383: A1          and  c
4384: A0          and  b
4385: 52          ld   d,d
4386: 52          ld   d,d
4387: 01 95 C0    ld   bc,$0C59
438A: 52          ld   d,d
438B: 85          add  a,l
438C: 94          sub  h
438D: 20 21       jr   nz,$4392
438F: A1          and  c
4390: 52          ld   d,d
4391: B0          or   b
4392: 52          ld   d,d
4393: 01 52 A1    ld   bc,$0B34
4396: 77          ld   (hl),a
4397: 52          ld   d,d
4398: 52          ld   d,d
4399: 01 C7 A1    ld   bc,$0B6D
439C: A0          and  b
439D: 52          ld   d,d
439E: 52          ld   d,d
439F: 01 52 B0    ld   bc,$1A34
43A2: 52          ld   d,d
43A3: 52          ld   d,d
43A4: C0          ret  nz
43A5: 52          ld   d,d
43A6: E0          ret  po
43A7: E1          pop  hl
43A8: 20 21       jr   nz,$43AD
43AA: A1          and  c
43AB: B5          or   l
43AC: 52          ld   d,d
43AD: 52          ld   d,d
43AE: 01 B4 52    ld   bc,$345A
43B1: 52          ld   d,d
43B2: 52          ld   d,d
43B3: 52          ld   d,d
43B4: 8D          adc  a,l
43B5: AC          xor  h
43B6: AD          xor  l
43B7: CC 89 88    call z,$8889
43BA: 69          ld   l,c
43BB: 68          ld   l,b
43BC: 85          add  a,l
43BD: A4          and  h
43BE: F4 F5 52    call p,$345F
43C1: 52          ld   d,d
43C2: D4 D5 A2    call nc,$2A5D
43C5: A3          and  e
43C6: C3 52 52    jp   $3434
43C9: 85          add  a,l
43CA: A4          and  h
43CB: 6C          ld   l,h
43CC: C3 A2 A3    jp   $2B2A
43CF: 52          ld   d,d
43D0: 78          ld   a,b
43D1: 52          ld   d,d
43D2: 32 33 E3    ld   ($2F33),a
43D5: 52          ld   d,d
43D6: 85          add  a,l
43D7: A4          and  h
43D8: 52          ld   d,d
43D9: C3 E3 52    jp   $342F
43DC: 4C          ld   c,h
43DD: 4D          ld   c,l
43DE: 52          ld   d,d
43DF: D2 2C 2D    jp   nc,$C3C2
43E2: 78          ld   a,b
43E3: 52          ld   d,d
43E4: 52          ld   d,d
43E5: 52          ld   d,d
43E6: 52          ld   d,d
43E7: 52          ld   d,d
43E8: 52          ld   d,d
43E9: 85          add  a,l
43EA: A4          and  h
43EB: 52          ld   d,d
43EC: A5          and  l
43ED: 98          sbc  a,b
43EE: A5          and  l
43EF: 98          sbc  a,b
43F0: 54          ld   d,h
43F1: 55          ld   d,l
43F2: 74          ld   (hl),h
43F3: 75          ld   (hl),l
43F4: 59          ld   e,c
43F5: F9          ld   sp,hl
43F6: 59          ld   e,c
43F7: F9          ld   sp,hl
43F8: F9          ld   sp,hl
43F9: 59          ld   e,c
43FA: F9          ld   sp,hl
43FB: 59          ld   e,c
43FC: 99          sbc  a,c
43FD: F9          ld   sp,hl
43FE: 59          ld   e,c
43FF: F9          ld   sp,hl
4400: F9          ld   sp,hl
4401: 59          ld   e,c
4402: F9          ld   sp,hl
4403: B8          cp   b
4404: 59          ld   e,c
4405: F9          ld   sp,hl
4406: 59          ld   e,c
4407: F9          ld   sp,hl
4408: 99          sbc  a,c
4409: 59          ld   e,c
440A: F9          ld   sp,hl
440B: 59          ld   e,c
440C: F9          ld   sp,hl
440D: 59          ld   e,c
440E: F9          ld   sp,hl
440F: 59          ld   e,c
4410: 59          ld   e,c
4411: F9          ld   sp,hl
4412: 59          ld   e,c
4413: B8          cp   b
4414: F9          ld   sp,hl
4415: 59          ld   e,c
4416: F9          ld   sp,hl
4417: 59          ld   e,c
4418: B3          or   e
4419: F9          ld   sp,hl
441A: 59          ld   e,c
441B: 60          ld   h,b
441C: F3          di
441D: 59          ld   e,c
441E: F9          ld   sp,hl
441F: 61          ld   h,c
4420: F3          di
4421: F9          ld   sp,hl
4422: 59          ld   e,c
4423: 61          ld   h,c
4424: F3          di
4425: 59          ld   e,c
4426: F9          ld   sp,hl
4427: 61          ld   h,c
4428: F3          di
4429: F9          ld   sp,hl
442A: 59          ld   e,c
442B: 61          ld   h,c
442C: F3          di
442D: 59          ld   e,c
442E: F9          ld   sp,hl
442F: 61          ld   h,c
4430: 46          ld   b,(hl)
4431: F9          ld   sp,hl
4432: 59          ld   e,c
4433: 47          ld   b,a
4434: FA FB 0C    jp   m,$C0BF
4437: 0D          dec  c
4438: 49          ld   c,c
4439: 48          ld   c,b
443A: 29          add  hl,hl
443B: 28 3C       jr   z,$440F
443D: 5A          ld   e,d
443E: 59          ld   e,c
443F: 1D          dec  e
4440: 5A          ld   e,d
4441: F9          ld   sp,hl
4442: EC ED 35    call pe,$53CF
4445: C5          push bc
4446: E5          push hl
4447: 15          dec  d
4448: 34          inc  (hl)
4449: C4 E4 14    call nz,$504E
444C: 59          ld   e,c
444D: 3D          dec  a
444E: 3C          inc  a
444F: 5A          ld   e,d
4450: 3C          inc  a
4451: 5A          ld   e,d
4452: 59          ld   e,c
4453: F9          ld   sp,hl
4454: 5A          ld   e,d
4455: F9          ld   sp,hl
4456: EC ED F9    call pe,$9FCF
4459: 59          ld   e,c
445A: 3D          dec  a
445B: 5A          ld   e,d
445C: E5          push hl
445D: 15          dec  d
445E: 35          dec  (hl)
445F: C5          push bc
4460: E4 14 34    call po,$5250
4463: C4 3D 3C    call nz,$D2D3
4466: 5A          ld   e,d
4467: F9          ld   sp,hl
4468: F9          ld   sp,hl
4469: 59          ld   e,c
446A: 1D          dec  e
446B: 1C          inc  e
446C: 1C          inc  e
446D: ED          db   $ed
446E: F9          ld   sp,hl
446F: 1D          dec  e
4470: 5B          ld   e,e
4471: 7A          ld   a,d
4472: 7B          ld   a,e
4473: 9A          sbc  a,d
4474: 04          inc  b
4475: 05          dec  b
4476: 04          inc  b
4477: 05          dec  b
4478: 66          ld   h,(hl)
4479: 67          ld   h,a
447A: 05          dec  b
447B: 86          add  a,(hl)
447C: B6          or   (hl)
447D: 05          dec  b
447E: 96          sub  (hl)
447F: 97          sub  a
4480: 16 04       ld   d,$40
4482: E6 E7       and  $6F
4484: D7          rst  $10
4485: F6 F7       or   $7F
4487: 05          dec  b
4488: B6          or   (hl)
4489: 04          inc  b
448A: 96          sub  (hl)
448B: 97          sub  a
448C: 16 05       ld   d,$41
448E: E6 E7       and  $6F
4490: 66          ld   h,(hl)
4491: 67          ld   h,a
4492: 05          dec  b
4493: 04          inc  b
4494: 04          inc  b
4495: 05          dec  b
4496: 04          inc  b
4497: 05          dec  b
4498: 66          ld   h,(hl)
4499: 67          ld   h,a
449A: 36 D6       ld   (hl),$7C
449C: 04          inc  b
449D: 05          dec  b
449E: 04          inc  b
449F: 05          dec  b
44A0: 05          dec  b
44A1: 87          add  a,a
44A2: A6          and  (hl)
44A3: 04          inc  b
44A4: B6          or   (hl)
44A5: 05          dec  b
44A6: 04          inc  b
44A7: B7          or   a
44A8: 16 08       ld   d,$80
44AA: 09          add  hl,bc
44AB: 17          rla
44AC: 04          inc  b
44AD: 05          dec  b
44AE: 04          inc  b
44AF: 05          dec  b
44B0: 05          dec  b
44B1: 04          inc  b
44B2: 05          dec  b
44B3: 04          inc  b
44B4: AA          xor  d
44B5: 8B          adc  a,e
44B6: 8A          adc  a,d
44B7: F8          ret  m
44B8: 39          add  hl,sp
44B9: E8          ret  pe
44BA: A8          xor  b
44BB: CD 04 05    call $4140
44BE: 04          inc  b
44BF: 05          dec  b
44C0: 05          dec  b
44C1: 04          inc  b
44C2: 05          dec  b
44C3: 04          inc  b
44C4: 04          inc  b
44C5: 05          dec  b
44C6: 04          inc  b
44C7: 05          dec  b
44C8: 05          dec  b
44C9: 04          inc  b
44CA: 05          dec  b
44CB: 04          inc  b
44CC: 04          inc  b
44CD: 05          dec  b
44CE: 04          inc  b
44CF: 05          dec  b
44D0: 05          dec  b
44D1: 04          inc  b
44D2: 05          dec  b
44D3: 04          inc  b
44D4: 04          inc  b
44D5: 05          dec  b
44D6: 04          inc  b
44D7: 05          dec  b
44D8: 05          dec  b
44D9: 04          inc  b
44DA: 05          dec  b
44DB: 04          inc  b
44DC: 04          inc  b
44DD: 05          dec  b
44DE: 04          inc  b
44DF: 05          dec  b
44E0: 05          dec  b
44E1: 04          inc  b
44E2: 05          dec  b
44E3: 04          inc  b
44E4: 04          inc  b
44E5: 05          dec  b
44E6: 04          inc  b
44E7: 05          dec  b
44E8: 05          dec  b
44E9: 04          inc  b
44EA: 05          dec  b
44EB: 04          inc  b
44EC: 04          inc  b
44ED: 05          dec  b
44EE: 04          inc  b
44EF: 05          dec  b
44F0: 9B          sbc  a,e
44F1: BA          cp   d
44F2: BB          cp   e
44F3: DA 52 52    jp   c,$3434
44F6: 52          ld   d,d
44F7: 52          ld   d,d
44F8: 52          ld   d,d
44F9: 79          ld   a,c
44FA: 98          sbc  a,b
44FB: 52          ld   d,d
44FC: 27          daa
44FD: 07          rlca
44FE: 06 27       ld   b,$63
4500: 27          daa
4501: 76          halt
4502: 26 27       ld   h,$63
4504: 6C          ld   l,h
4505: 6D          ld   l,l
4506: 52          ld   d,d
4507: 6C          ld   l,h
4508: 52          ld   d,d
4509: 52          ld   d,d
450A: 52          ld   d,d
450B: 52          ld   d,d
450C: C8          ret  z
450D: C9          ret
450E: 52          ld   d,d
450F: 71          ld   (hl),c
4510: A9          xor  c
4511: 71          ld   (hl),c
4512: 70          ld   (hl),b
4513: 44          ld   b,h
4514: 70          ld   (hl),b
4515: 44          ld   b,h
4516: D3 F2       out  ($3E),a
4518: D3 F2       out  ($3E),a
451A: 44          ld   b,h
451B: 44          ld   b,h
451C: 44          ld   b,h
451D: 44          ld   b,h
451E: 65          ld   h,l
451F: 84          add  a,h
4520: 44          ld   b,h
4521: 64          ld   h,h
4522: 52          ld   d,d
4523: 52          ld   d,d
4524: 73          ld   (hl),e
4525: 44          ld   b,h
4526: 72          ld   (hl),d
4527: 71          ld   (hl),c
4528: 52          ld   d,d
4529: 45          ld   b,l
452A: 44          ld   b,h
452B: 80          add  a,b
452C: 70          ld   (hl),b
452D: 44          ld   b,h
452E: 44          ld   b,h
452F: 11 5C 44    ld   de,$44D4
4532: D3 F2       out  ($3E),a
4534: D3 F2       out  ($3E),a
4536: 44          ld   b,h
4537: 44          ld   b,h
4538: 44          ld   b,h
4539: 44          ld   b,h
453A: 65          ld   h,l
453B: 84          add  a,h
453C: 65          ld   h,l
453D: 84          add  a,h
453E: 52          ld   d,d
453F: 52          ld   d,d
4540: C8          ret  z
4541: C9          ret
4542: 52          ld   d,d
4543: 52          ld   d,d
4544: A9          xor  c
4545: 52          ld   d,d
4546: 52          ld   d,d
4547: 52          ld   d,d
4548: 52          ld   d,d
4549: 52          ld   d,d
454A: 52          ld   d,d
454B: 52          ld   d,d
454C: 52          ld   d,d
454D: 52          ld   d,d
454E: 52          ld   d,d
454F: 52          ld   d,d
4550: B2          or   d
4551: 93          sub  e
4552: C6 52       add  a,$34
4554: 52          ld   d,d
4555: 92          sub  d
4556: A7          and  a
4557: 71          ld   (hl),c
4558: 72          ld   (hl),d
4559: 71          ld   (hl),c
455A: 70          ld   (hl),b
455B: 44          ld   b,h
455C: 44          ld   b,h
455D: 44          ld   b,h
455E: D3 F2       out  ($3E),a
4560: D3 F2       out  ($3E),a
4562: 44          ld   b,h
4563: 44          ld   b,h
4564: 44          ld   b,h
4565: 44          ld   b,h
4566: 65          ld   h,l
4567: 84          add  a,h
4568: 65          ld   h,l
4569: 84          add  a,h
456A: 52          ld   d,d
456B: 52          ld   d,d
456C: 2A 2B 6A    ld   hl,($A6A3)
456F: 6B          ld   l,e
4570: 0A          ld   a,(bc)
4571: 0B          dec  bc
4572: 4A          ld   c,d
4573: 4B          ld   c,e
4574: E9          jp   (hl)
4575: 18 19       jr   $4508
4577: 38 E3       jr   c,$45A8
4579: A2          and  d
457A: A3          and  e
457B: E3          ex   (sp),hl
457C: 52          ld   d,d
457D: 52          ld   d,d
457E: 52          ld   d,d
457F: 52          ld   d,d
4580: 52          ld   d,d
4581: 78          ld   a,b
4582: 52          ld   d,d
4583: 52          ld   d,d
4584: 52          ld   d,d
4585: 02          ld   (bc),a
4586: F1          pop  af
4587: 52          ld   d,d
4588: 03          inc  bc
4589: C2 42 43    jp   nz,$2524
458C: 23          inc  hl
458D: D0          ret  nc
458E: 52          ld   d,d
458F: 52          ld   d,d
4590: 52          ld   d,d
4591: 52          ld   d,d
4592: 52          ld   d,d
4593: 78          ld   a,b
4594: 52          ld   d,d
4595: 52          ld   d,d
4596: 6C          ld   l,h
4597: 6D          ld   l,l
4598: 78          ld   a,b
4599: 52          ld   d,d
459A: 52          ld   d,d
459B: 52          ld   d,d
459C: 52          ld   d,d
459D: 8C          adc  a,h
459E: 6D          ld   l,l
459F: 52          ld   d,d
45A0: 79          ld   a,c
45A1: 98          sbc  a,b
45A2: 52          ld   d,d
45A3: 52          ld   d,d
45A4: 52          ld   d,d
45A5: 52          ld   d,d
45A6: C3 52 E3    jp   $2F34
45A9: A2          and  d
45AA: A3          and  e
45AB: E3          ex   (sp),hl
45AC: 52          ld   d,d
45AD: 52          ld   d,d
45AE: 52          ld   d,d
45AF: 52          ld   d,d
45B0: 52          ld   d,d
45B1: 78          ld   a,b
45B2: 52          ld   d,d
45B3: 52          ld   d,d
45B4: E0          ret  po
45B5: E1          pop  hl
45B6: B0          or   b
45B7: 02          ld   (bc),a
45B8: 03          inc  bc
45B9: F1          pop  af
45BA: D1          pop  de
45BB: 22 63 C2    ld   ($2C27),hl
45BE: B1          or   c
45BF: 00          nop
45C0: 30 31       jr   nc,$45D5
45C2: 23          inc  hl
45C3: 43          ld   b,e
45C4: 88          adc  a,b
45C5: 01 89 01    ld   bc,$0189
45C8: A8          xor  b
45C9: 01 00 00    ld   bc,$0000
45CC: 18 01       jr   $45CF
45CE: 19          add  hl,de
45CF: 01 38 01    ld   bc,$0192
45D2: 00          nop
45D3: 00          nop
45D4: 98          sbc  a,b
45D5: 01 99 01    ld   bc,$0199
45D8: B8          cp   b
45D9: 01 00 00    ld   bc,$0000
45DC: 73          ld   (hl),e
45DD: 48          ld   c,b
45DE: B3          or   e
45DF: 48          ld   c,b
45E0: 73          ld   (hl),e
45E1: 4A          ld   c,d
45E2: 00          nop
45E3: 00          nop
45E4: B3          or   e
45E5: 48          ld   c,b
45E6: B3          or   e
45E7: 4A          ld   c,d
45E8: 73          ld   (hl),e
45E9: 48          ld   c,b
45EA: B3          or   e
45EB: 48          ld   c,b
45EC: 73          ld   (hl),e
45ED: 48          ld   c,b
45EE: 29          add  hl,hl
45EF: 03          inc  bc
45F0: 97          sub  a
45F1: 03          inc  bc
45F2: 96          sub  (hl)
45F3: 03          inc  bc
45F4: 47          ld   b,a
45F5: 03          inc  bc
45F6: 46          ld   b,(hl)
45F7: 03          inc  bc
45F8: 27          daa
45F9: 03          inc  bc
45FA: 26 03       ld   h,$21
45FC: C7          rst  $00
45FD: 03          inc  bc
45FE: C6 03       add  a,$21
4600: A7          and  a
4601: 03          inc  bc
4602: A6          and  (hl)
4603: 03          inc  bc
4604: 96          sub  (hl)
4605: 01 96 01    ld   bc,$0178
4608: 97          sub  a
4609: 01 29 01    ld   bc,$0183
460C: 26 01       ld   h,$01
460E: 26 01       ld   h,$01
4610: 26 01       ld   h,$01
4612: D8          ret  c
4613: 01 26 01    ld   bc,$0162
4616: 26 01       ld   h,$01
4618: 46          ld   b,(hl)
4619: 01 66 01    ld   bc,$0166
461C: A6          and  (hl)
461D: 01 A7 01    ld   bc,$016B
4620: C6 01       add  a,$01
4622: E6 01       and  $01
4624: B2          or   d
4625: 48          ld   c,b
4626: 93          sub  e
4627: 48          ld   c,b
4628: F8          ret  m
4629: 01 F9 01    ld   bc,$019F
462C: D9          exx
462D: 01 B2 48    ld   bc,$843A
4630: B3          or   e
4631: 48          ld   c,b
4632: 73          ld   (hl),e
4633: 48          ld   c,b
4634: 67          ld   h,a
4635: 01 B3 48    ld   bc,$843B
4638: B2          or   d
4639: 48          ld   c,b
463A: 93          sub  e
463B: 48          ld   c,b
463C: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
463D: 01 73 48    ld   bc,$8437
4640: B3          or   e
4641: 48          ld   c,b
4642: B2          or   d
4643: 48          ld   c,b
4644: 73          ld   (hl),e
4645: 48          ld   c,b
4646: B3          or   e
4647: 48          ld   c,b
4648: B2          or   d
4649: 48          ld   c,b
464A: 24          inc  h
464B: 21 B3 4A    ld   hl,$A43B
464E: 84          add  a,h
464F: 21 85 21    ld   hl,$0349
4652: A4          and  h
4653: 21 B2 4A    ld   hl,$A43A
4656: 14          inc  d
4657: 21 15 21    ld   hl,$0351
465A: 34          inc  (hl)
465B: 20 93       jr   nz,$4696
465D: 4A          ld   c,d
465E: 94          sub  h
465F: 21 95 20    ld   hl,$0259
4662: B4          or   h
4663: 20 25       jr   nz,$46A8
4665: 21 44 21    ld   hl,$0344
4668: B2          or   d
4669: 48          ld   c,b
466A: 93          sub  e
466B: 48          ld   c,b
466C: A5          and  l
466D: 21 C4 21    ld   hl,$034C
4670: 73          ld   (hl),e
4671: 4A          ld   c,d
4672: B3          or   e
4673: 48          ld   c,b
4674: 35          dec  (hl)
4675: 20 54       jr   nz,$46CB
4677: 20 73       jr   nz,$46B0
4679: 48          ld   c,b
467A: B2          or   d
467B: 48          ld   c,b
467C: B5          or   l
467D: 20 73       jr   nz,$46B6
467F: 48          ld   c,b
4680: F8          ret  m
4681: 01 F9 01    ld   bc,$019F
4684: 2D          dec  l
4685: C2 7C C2    jp   nz,$2CD6
4688: 5D          ld   e,l
4689: C2 00 00    jp   nz,$0000
468C: D4 AB 2D    call nc,$C3AB
468F: C2 2C C2    jp   nz,$2CC2
4692: 00          nop
4693: 00          nop
4694: D5          push de
4695: AB          xor  e
4696: F4 AB F5    call p,$5FAB
4699: AB          xor  e
469A: 00          nop
469B: 00          nop
469C: D4 AB D5    call nc,$5DAB
469F: AB          xor  e
46A0: F4 AB 00    call p,$00AB
46A3: 00          nop
46A4: CC C2 AD    call z,$CB2C
46A7: C2 AC C2    jp   nz,$2CCA
46AA: 00          nop
46AB: 00          nop
46AC: 5C          ld   e,h
46AD: C2 3D C2    jp   nz,$2CD3
46B0: 3C          inc  a
46B1: C2 00 00    jp   nz,$0000
46B4: DC C2 BD    call c,$DB2C
46B7: C2 BC C2    jp   nz,$2CDA
46BA: 00          nop
46BB: 00          nop
46BC: ED          db   $ed
46BD: C2 EC C2    jp   nz,$2CCE
46C0: CD C2 00    call $002C
46C3: 00          nop
46C4: 3A EF 1B    ld   a,($B1EF)
46C7: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
46C8: 1A          ld   a,(de)
46C9: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
46CA: 00          nop
46CB: 00          nop
46CC: BA          cp   d
46CD: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
46CE: 9B          sbc  a,e
46CF: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
46D0: 9A          sbc  a,d
46D1: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
46D2: 00          nop
46D3: 00          nop
46D4: 97          sub  a
46D5: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
46D6: 96          sub  (hl)
46D7: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
46D8: 45          ld   b,l
46D9: A8          xor  b
46DA: 00          nop
46DB: 00          nop
46DC: 45          ld   b,l
46DD: A8          xor  b
46DE: 45          ld   b,l
46DF: A8          xor  b
46E0: 45          ld   b,l
46E1: A8          xor  b
46E2: 00          nop
46E3: 00          nop
46E4: D5          push de
46E5: 40          ld   b,b
46E6: C2 48 60    jp   nz,$0684
46E9: 48          ld   c,b
46EA: 61          ld   h,c
46EB: 48          ld   c,b
46EC: 91          sub  c
46ED: 4A          ld   c,d
46EE: 90          sub  b
46EF: 4A          ld   c,d
46F0: 73          ld   (hl),e
46F1: 48          ld   c,b
46F2: B3          or   e
46F3: 48          ld   c,b
46F4: 31 4A 73    ld   sp,$37A4
46F7: 48          ld   c,b
46F8: B3          or   e
46F9: 4A          ld   c,d
46FA: B2          or   d
46FB: 48          ld   c,b
46FC: 55          ld   d,l
46FD: 40          ld   b,b
46FE: 41          ld   b,c
46FF: 48          ld   c,b
4700: 40          ld   b,b
4701: 48          ld   c,b
4702: 83          add  a,e
4703: 4A          ld   c,d
4704: 00          nop
4705: 00          nop
4706: 00          nop
4707: 21 01 21    ld   hl,$0301
470A: B3          or   e
470B: 48          ld   c,b
470C: 00          nop
470D: 00          nop
470E: 80          add  a,b
470F: 21 81 21    ld   hl,$0309
4712: B2          or   d
4713: 48          ld   c,b
4714: 00          nop
4715: 00          nop
4716: 10 21       djnz $471B
4718: 11 21 B3    ld   de,$3B03
471B: 4A          ld   c,d
471C: 00          nop
471D: 00          nop
471E: 90          sub  b
471F: 21 91 21    ld   hl,$0319
4722: B2          or   d
4723: 4A          ld   c,d
4724: 76          halt
4725: 03          inc  bc
4726: 56          ld   d,(hl)
4727: 03          inc  bc
4728: 37          scf
4729: 03          inc  bc
472A: 36 03       ld   (hl),$21
472C: D7          rst  $10
472D: 03          inc  bc
472E: D6 03       sub  $21
4730: B7          or   a
4731: 03          inc  bc
4732: B6          or   (hl)
4733: 03          inc  bc
4734: B3          or   e
4735: 48          ld   c,b
4736: 4A          ld   c,d
4737: 03          inc  bc
4738: 2B          dec  hl
4739: 03          inc  bc
473A: 2A 03 B2    ld   hl,($3A21)
473D: 48          ld   c,b
473E: B3          or   e
473F: 48          ld   c,b
4740: B2          or   d
4741: 48          ld   c,b
4742: B3          or   e
4743: 48          ld   c,b
4744: 36 01       ld   (hl),$01
4746: 37          scf
4747: 01 56 01    ld   bc,$0174
474A: 76          halt
474B: 01 B6 01    ld   bc,$017A
474E: B7          or   a
474F: 01 D6 01    ld   bc,$017C
4752: D7          rst  $10
4753: 01 2A 01    ld   bc,$01A2
4756: 2B          dec  hl
4757: 01 4A 01    ld   bc,$01A4
475A: 73          ld   (hl),e
475B: 48          ld   c,b
475C: 73          ld   (hl),e
475D: 48          ld   c,b
475E: 73          ld   (hl),e
475F: 4A          ld   c,d
4760: B3          or   e
4761: 4A          ld   c,d
4762: B3          or   e
4763: 48          ld   c,b
4764: 41          ld   b,c
4765: 21 60 21    ld   hl,$0306
4768: 61          ld   h,c
4769: 21 00 00    ld   hl,$0000
476C: C1          pop  bc
476D: 21 E0 21    ld   hl,$030E
4770: E1          pop  hl
4771: 21 00 00    ld   hl,$0000
4774: 51          ld   d,c
4775: 21 70 21    ld   hl,$0316
4778: 71          ld   (hl),c
4779: 21 00 00    ld   hl,$0000
477C: D1          pop  de
477D: 21 F0 21    ld   hl,$031E
4780: F1          pop  af
4781: 21 00 00    ld   hl,$0000
4784: B3          or   e
4785: 48          ld   c,b
4786: 73          ld   (hl),e
4787: 48          ld   c,b
4788: 03          inc  bc
4789: 21 22 21    ld   hl,$0322
478C: B2          or   d
478D: 4A          ld   c,d
478E: 82          add  a,d
478F: 21 83 21    ld   hl,$0329
4792: A2          and  d
4793: 21 B3 4A    ld   hl,$A43B
4796: 12          ld   (de),a
4797: 21 13 21    ld   hl,$0331
479A: 32 21 B2    ld   ($3A03),a
479D: 4A          ld   c,d
479E: 92          sub  d
479F: 20 93       jr   nz,$47DA
47A1: 20 B2       jr   nz,$47DD
47A3: 20 23       jr   nz,$47C8
47A5: 21 42 21    ld   hl,$0324
47A8: 73          ld   (hl),e
47A9: 4A          ld   c,d
47AA: B3          or   e
47AB: 48          ld   c,b
47AC: A3          and  e
47AD: 21 C2 21    ld   hl,$032C
47B0: B3          or   e
47B1: 48          ld   c,b
47B2: B2          or   d
47B3: 48          ld   c,b
47B4: 33          inc  sp
47B5: 21 52 21    ld   hl,$0334
47B8: EA 01 73    jp   pe,$3701
47BB: 4A          ld   c,d
47BC: B3          or   e
47BD: 20 D2       jr   nz,$47FB
47BF: 20 73       jr   nz,$47F8
47C1: 48          ld   c,b
47C2: EB          ex   de,hl
47C3: 01 00 00    ld   bc,$0000
47C6: 61          ld   h,c
47C7: 23          inc  hl
47C8: 60          ld   h,b
47C9: 23          inc  hl
47CA: 41          ld   b,c
47CB: 23          inc  hl
47CC: 00          nop
47CD: 00          nop
47CE: E1          pop  hl
47CF: 23          inc  hl
47D0: E0          ret  po
47D1: 23          inc  hl
47D2: C1          pop  bc
47D3: 23          inc  hl
47D4: 00          nop
47D5: 00          nop
47D6: 71          ld   (hl),c
47D7: 23          inc  hl
47D8: 70          ld   (hl),b
47D9: 23          inc  hl
47DA: 51          ld   d,c
47DB: 23          inc  hl
47DC: 00          nop
47DD: 00          nop
47DE: F1          pop  af
47DF: 23          inc  hl
47E0: F0          ret  p
47E1: 23          inc  hl
47E2: D1          pop  de
47E3: 23          inc  hl
47E4: 45          ld   b,l
47E5: A8          xor  b
47E6: 45          ld   b,l
47E7: A8          xor  b
47E8: 45          ld   b,l
47E9: A8          xor  b
47EA: 00          nop
47EB: 00          nop
47EC: 45          ld   b,l
47ED: A8          xor  b
47EE: 45          ld   b,l
47EF: A8          xor  b
47F0: 45          ld   b,l
47F1: A8          xor  b
47F2: 00          nop
47F3: 00          nop
47F4: 2A EF 0B    ld   hl,($A1EF)
47F7: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
47F8: 0A          ld   a,(bc)
47F9: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
47FA: 00          nop
47FB: 00          nop
47FC: AA          xor  d
47FD: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
47FE: 8B          adc  a,e
47FF: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
4800: 8A          adc  a,d
4801: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
4802: 00          nop
4803: 00          nop
4804: 68          ld   l,b
4805: 01 69 01    ld   bc,$0187
4808: F8          ret  m
4809: 01 F9 01    ld   bc,$019F
480C: E8          ret  pe
480D: 01 E9 01    ld   bc,$018F
4810: 1A          ld   a,(de)
4811: 01 B3 48    ld   bc,$843B
4814: 78          ld   a,b
4815: 01 79 01    ld   bc,$0197
4818: 9A          sbc  a,d
4819: 01 B2 4A    ld   bc,$A43A
481C: 73          ld   (hl),e
481D: 48          ld   c,b
481E: B3          or   e
481F: 48          ld   c,b
4820: B2          or   d
4821: 48          ld   c,b
4822: 93          sub  e
4823: 48          ld   c,b
4824: 61          ld   h,c
4825: 4A          ld   c,d
4826: 60          ld   h,b
4827: 4A          ld   c,d
4828: C2 4A C5    jp   nz,$4DA4
482B: 40          ld   b,b
482C: 73          ld   (hl),e
482D: 48          ld   c,b
482E: B3          or   e
482F: 48          ld   c,b
4830: 90          sub  b
4831: 48          ld   c,b
4832: 91          sub  c
4833: 48          ld   c,b
4834: B2          or   d
4835: 48          ld   c,b
4836: D2 09 D3    jp   nc,$3D81
4839: 09          add  hl,bc
483A: 31 48 83    ld   sp,$2984
483D: 48          ld   c,b
483E: 40          ld   b,b
483F: 4A          ld   c,d
4840: 41          ld   b,c
4841: 4A          ld   c,d
4842: C5          push bc
4843: 40          ld   b,b
4844: B2          or   d
4845: 48          ld   c,b
4846: B3          or   e
4847: 48          ld   c,b
4848: 73          ld   (hl),e
4849: 48          ld   c,b
484A: AA          xor  d
484B: 01 B3 4A    ld   bc,$A43B
484E: 48          ld   c,b
484F: 01 1B 01    ld   bc,$01B1
4852: 3A 01 B2    ld   a,($3A01)
4855: 4A          ld   c,d
4856: C8          ret  z
4857: 01 9B 01    ld   bc,$01B9
485A: BA          cp   d
485B: 01 93 4A    ld   bc,$A439
485E: 58          ld   e,b
485F: 01 59 01    ld   bc,$0195
4862: 78          ld   a,b
4863: 01 AB 01    ld   bc,$01AB
4866: CA 01 28    jp   z,$8201
4869: 03          inc  bc
486A: 09          add  hl,bc
486B: 03          inc  bc
486C: 3B          dec  sp
486D: 01 5A 01    ld   bc,$01B4
4870: 5B          ld   e,e
4871: 01 B3 4A    ld   bc,$A43B
4874: BB          cp   e
4875: 01 DA 01    ld   bc,$01BC
4878: DB 01       in   a,($01)
487A: 73          ld   (hl),e
487B: 4A          ld   c,d
487C: 79          ld   a,c
487D: 01 9A 01    ld   bc,$01B8
4880: 73          ld   (hl),e
4881: 48          ld   c,b
4882: B3          or   e
4883: 4A          ld   c,d
4884: 45          ld   b,l
4885: A8          xor  b
4886: 45          ld   b,l
4887: A8          xor  b
4888: 45          ld   b,l
4889: A8          xor  b
488A: 45          ld   b,l
488B: A8          xor  b
488C: 45          ld   b,l
488D: A8          xor  b
488E: 45          ld   b,l
488F: A8          xor  b
4890: 45          ld   b,l
4891: A8          xor  b
4892: 45          ld   b,l
4893: A8          xor  b
4894: 64          ld   h,h
4895: A8          xor  b
4896: 65          ld   h,l
4897: A8          xor  b
4898: 45          ld   b,l
4899: A8          xor  b
489A: 45          ld   b,l
489B: A8          xor  b
489C: B3          or   e
489D: 48          ld   c,b
489E: B2          or   d
489F: 48          ld   c,b
48A0: 64          ld   h,h
48A1: A8          xor  b
48A2: 65          ld   h,l
48A3: A8          xor  b
48A4: 64          ld   h,h
48A5: A8          xor  b
48A6: 65          ld   h,l
48A7: A8          xor  b
48A8: 45          ld   b,l
48A9: A8          xor  b
48AA: 45          ld   b,l
48AB: A8          xor  b
48AC: B3          or   e
48AD: 48          ld   c,b
48AE: B2          or   d
48AF: 48          ld   c,b
48B0: 64          ld   h,h
48B1: A8          xor  b
48B2: 65          ld   h,l
48B3: A8          xor  b
48B4: B2          or   d
48B5: 48          ld   c,b
48B6: B3          or   e
48B7: 48          ld   c,b
48B8: 93          sub  e
48B9: 48          ld   c,b
48BA: 92          sub  d
48BB: 48          ld   c,b
48BC: 73          ld   (hl),e
48BD: 48          ld   c,b
48BE: B2          or   d
48BF: 48          ld   c,b
48C0: B3          or   e
48C1: 48          ld   c,b
48C2: 93          sub  e
48C3: 48          ld   c,b
48C4: 45          ld   b,l
48C5: A8          xor  b
48C6: 45          ld   b,l
48C7: A8          xor  b
48C8: 45          ld   b,l
48C9: A8          xor  b
48CA: 07          rlca
48CB: AE          xor  (hl)
48CC: 45          ld   b,l
48CD: A8          xor  b
48CE: 45          ld   b,l
48CF: A8          xor  b
48D0: 07          rlca
48D1: AE          xor  (hl)
48D2: B3          or   e
48D3: 48          ld   c,b
48D4: 45          ld   b,l
48D5: A8          xor  b
48D6: 07          rlca
48D7: AE          xor  (hl)
48D8: D2 09 D3    jp   nc,$3D81
48DB: 09          add  hl,bc
48DC: 07          rlca
48DD: AE          xor  (hl)
48DE: 93          sub  e
48DF: 48          ld   c,b
48E0: 92          sub  d
48E1: 48          ld   c,b
48E2: B3          or   e
48E3: 48          ld   c,b
48E4: 73          ld   (hl),e
48E5: 48          ld   c,b
48E6: B3          or   e
48E7: 48          ld   c,b
48E8: B2          or   d
48E9: 48          ld   c,b
48EA: 93          sub  e
48EB: 48          ld   c,b
48EC: B3          or   e
48ED: 48          ld   c,b
48EE: B2          or   d
48EF: 48          ld   c,b
48F0: 93          sub  e
48F1: 48          ld   c,b
48F2: B2          or   d
48F3: 48          ld   c,b
48F4: B2          or   d
48F5: 48          ld   c,b
48F6: D2 09 D3    jp   nc,$3D81
48F9: 09          add  hl,bc
48FA: B3          or   e
48FB: 48          ld   c,b
48FC: 93          sub  e
48FD: 48          ld   c,b
48FE: 92          sub  d
48FF: 48          ld   c,b
4900: 93          sub  e
4901: 48          ld   c,b
4902: B2          or   d
4903: 48          ld   c,b
4904: 93          sub  e
4905: 48          ld   c,b
4906: 92          sub  d
4907: 48          ld   c,b
4908: 93          sub  e
4909: 48          ld   c,b
490A: B2          or   d
490B: 48          ld   c,b
490C: B2          or   d
490D: 48          ld   c,b
490E: 93          sub  e
490F: 48          ld   c,b
4910: B2          or   d
4911: 48          ld   c,b
4912: B3          or   e
4913: 48          ld   c,b
4914: B3          or   e
4915: 48          ld   c,b
4916: D2 09 D3    jp   nc,$3D81
4919: 09          add  hl,bc
491A: 73          ld   (hl),e
491B: 48          ld   c,b
491C: D2 09 D3    jp   nc,$3D81
491F: 09          add  hl,bc
4920: D3 0B       out  ($A1),a
4922: D2 0B 00    jp   nc,$00A1
4925: 4A          ld   c,d
4926: 11 48 81    ld   de,$0984
4929: 48          ld   c,b
492A: 01 48 B0    ld   bc,$1A84
492D: 58          ld   e,b
492E: F0          ret  p
492F: 4A          ld   c,d
4930: F8          ret  m
4931: 01 F9 01    ld   bc,$019F
4934: 55          ld   d,l
4935: 40          ld   b,b
4936: C5          push bc
4937: 40          ld   b,b
4938: 13          inc  de
4939: 48          ld   c,b
493A: 73          ld   (hl),e
493B: 48          ld   c,b
493C: C5          push bc
493D: 40          ld   b,b
493E: 55          ld   d,l
493F: 40          ld   b,b
4940: 63          ld   h,e
4941: 58          ld   e,b
4942: 83          add  a,e
4943: 4A          ld   c,d
4944: 93          sub  e
4945: 48          ld   c,b
4946: 92          sub  d
4947: 48          ld   c,b
4948: 93          sub  e
4949: 48          ld   c,b
494A: B2          or   d
494B: 48          ld   c,b
494C: B2          or   d
494D: 48          ld   c,b
494E: 93          sub  e
494F: 48          ld   c,b
4950: B2          or   d
4951: 48          ld   c,b
4952: B3          or   e
4953: 48          ld   c,b
4954: 31 4A D2    ld   sp,$3CA4
4957: 09          add  hl,bc
4958: D3 09       out  ($81),a
495A: 73          ld   (hl),e
495B: 48          ld   c,b
495C: 55          ld   d,l
495D: 40          ld   b,b
495E: 63          ld   h,e
495F: 58          ld   e,b
4960: 60          ld   h,b
4961: 58          ld   e,b
4962: 61          ld   h,c
4963: 58          ld   e,b
4964: 61          ld   h,c
4965: 4A          ld   c,d
4966: 60          ld   h,b
4967: 4A          ld   c,d
4968: 11 4A 00    ld   de,$00A4
496B: 48          ld   c,b
496C: 73          ld   (hl),e
496D: 48          ld   c,b
496E: B3          or   e
496F: 48          ld   c,b
4970: B2          or   d
4971: 48          ld   c,b
4972: 80          add  a,b
4973: 48          ld   c,b
4974: B3          or   e
4975: 48          ld   c,b
4976: B2          or   d
4977: 48          ld   c,b
4978: 10 48       djnz $48FE
497A: 20 4A       jr   nz,$4920
497C: B2          or   d
497D: 48          ld   c,b
497E: 93          sub  e
497F: 48          ld   c,b
4980: 90          sub  b
4981: 48          ld   c,b
4982: 91          sub  c
4983: 48          ld   c,b
4984: A1          and  c
4985: 48          ld   c,b
4986: 73          ld   (hl),e
4987: 48          ld   c,b
4988: B3          or   e
4989: 48          ld   c,b
498A: B2          or   d
498B: 48          ld   c,b
498C: 55          ld   d,l
498D: 40          ld   b,b
498E: 41          ld   b,c
498F: 48          ld   c,b
4990: 30 4A       jr   nc,$4936
4992: F0          ret  p
4993: 4A          ld   c,d
4994: D5          push de
4995: 40          ld   b,b
4996: 55          ld   d,l
4997: 40          ld   b,b
4998: C5          push bc
4999: 40          ld   b,b
499A: 45          ld   b,l
499B: 40          ld   b,b
499C: 61          ld   h,c
499D: 4A          ld   c,d
499E: 60          ld   h,b
499F: 4A          ld   c,d
49A0: 81          add  a,c
49A1: 4A          ld   c,d
49A2: 63          ld   h,e
49A3: 4A          ld   c,d
49A4: C5          push bc
49A5: 40          ld   b,b
49A6: 45          ld   b,l
49A7: 40          ld   b,b
49A8: C2 48 01    jp   nz,$0184
49AB: 48          ld   c,b
49AC: 55          ld   d,l
49AD: 40          ld   b,b
49AE: C5          push bc
49AF: 40          ld   b,b
49B0: C2 58 83    jp   nz,$2994
49B3: 4A          ld   c,d
49B4: D5          push de
49B5: 40          ld   b,b
49B6: 00          nop
49B7: 4A          ld   c,d
49B8: 11 48 83    ld   de,$2984
49BB: 5A          ld   e,d
49BC: 91          sub  c
49BD: 4A          ld   c,d
49BE: 90          sub  b
49BF: 4A          ld   c,d
49C0: B3          or   e
49C1: 48          ld   c,b
49C2: 73          ld   (hl),e
49C3: 48          ld   c,b
49C4: 01 4A C2    ld   bc,$2CA4
49C7: 4A          ld   c,d
49C8: 45          ld   b,l
49C9: 40          ld   b,b
49CA: C5          push bc
49CB: 40          ld   b,b
49CC: 83          add  a,e
49CD: 48          ld   c,b
49CE: C2 5A C5    jp   nz,$4DB4
49D1: 40          ld   b,b
49D2: 55          ld   d,l
49D3: 40          ld   b,b
49D4: 83          add  a,e
49D5: 58          ld   e,b
49D6: 11 4A 00    ld   de,$00A4
49D9: 48          ld   c,b
49DA: D5          push de
49DB: 40          ld   b,b
49DC: 73          ld   (hl),e
49DD: 48          ld   c,b
49DE: B3          or   e
49DF: 48          ld   c,b
49E0: 90          sub  b
49E1: 48          ld   c,b
49E2: 91          sub  c
49E3: 48          ld   c,b
49E4: 31 58 55    ld   sp,$5594
49E7: 40          ld   b,b
49E8: D5          push de
49E9: 40          ld   b,b
49EA: 55          ld   d,l
49EB: 40          ld   b,b
49EC: 31 48 C5    ld   sp,$4D84
49EF: 40          ld   b,b
49F0: 45          ld   b,l
49F1: 40          ld   b,b
49F2: C5          push bc
49F3: 40          ld   b,b
49F4: 31 58 53    ld   sp,$3594
49F7: 48          ld   c,b
49F8: 72          ld   (hl),d
49F9: 48          ld   c,b
49FA: 55          ld   d,l
49FB: 40          ld   b,b
49FC: B3          or   e
49FD: 48          ld   c,b
49FE: 61          ld   h,c
49FF: 4A          ld   c,d
4A00: 42          ld   b,d
4A01: 58          ld   e,b
4A02: 91          sub  c
4A03: 48          ld   c,b
4A04: A1          and  c
4A05: 48          ld   c,b
4A06: 92          sub  d
4A07: 48          ld   c,b
4A08: 93          sub  e
4A09: 48          ld   c,b
4A0A: B2          or   d
4A0B: 48          ld   c,b
4A0C: 70          ld   (hl),b
4A0D: 48          ld   c,b
4A0E: 93          sub  e
4A0F: 48          ld   c,b
4A10: B2          or   d
4A11: 48          ld   c,b
4A12: 92          sub  d
4A13: 48          ld   c,b
4A14: 22 48 D3    ld   ($3D84),hl
4A17: 0B          dec  bc
4A18: D2 0B 73    jp   nc,$37A1
4A1B: 48          ld   c,b
4A1C: C5          push bc
4A1D: 40          ld   b,b
4A1E: 51          ld   d,c
4A1F: 4A          ld   c,d
4A20: E2 48 F0    jp   po,$1E84
4A23: 4A          ld   c,d
4A24: 51          ld   d,c
4A25: 4A          ld   c,d
4A26: E2 4A 90    jp   po,$18A4
4A29: 5A          ld   e,d
4A2A: 73          ld   (hl),e
4A2B: 48          ld   c,b
4A2C: 55          ld   d,l
4A2D: 40          ld   b,b
4A2E: D5          push de
4A2F: 40          ld   b,b
4A30: E3          ex   (sp),hl
4A31: 4A          ld   c,d
4A32: F0          ret  p
4A33: 4A          ld   c,d
4A34: C5          push bc
4A35: 40          ld   b,b
4A36: 55          ld   d,l
4A37: 40          ld   b,b
4A38: C5          push bc
4A39: 40          ld   b,b
4A3A: 45          ld   b,l
4A3B: 40          ld   b,b
4A3C: 55          ld   d,l
4A3D: 40          ld   b,b
4A3E: D5          push de
4A3F: 40          ld   b,b
4A40: 55          ld   d,l
4A41: 40          ld   b,b
4A42: C5          push bc
4A43: 40          ld   b,b
4A44: A1          and  c
4A45: 48          ld   c,b
4A46: 73          ld   (hl),e
4A47: 48          ld   c,b
4A48: B3          or   e
4A49: 48          ld   c,b
4A4A: B2          or   d
4A4B: 48          ld   c,b
4A4C: 55          ld   d,l
4A4D: 40          ld   b,b
4A4E: 41          ld   b,c
4A4F: 48          ld   c,b
4A50: 30 4A       jr   nc,$49F6
4A52: F0          ret  p
4A53: 4A          ld   c,d
4A54: D5          push de
4A55: 40          ld   b,b
4A56: 72          ld   (hl),d
4A57: 4A          ld   c,d
4A58: 53          ld   d,e
4A59: 4A          ld   c,d
4A5A: 55          ld   d,l
4A5B: 40          ld   b,b
4A5C: 55          ld   d,l
4A5D: 40          ld   b,b
4A5E: C5          push bc
4A5F: 40          ld   b,b
4A60: 45          ld   b,l
4A61: 40          ld   b,b
4A62: C5          push bc
4A63: 40          ld   b,b
4A64: 73          ld   (hl),e
4A65: 48          ld   c,b
4A66: B3          or   e
4A67: 48          ld   c,b
4A68: B2          or   d
4A69: 48          ld   c,b
4A6A: A1          and  c
4A6B: 4A          ld   c,d
4A6C: F0          ret  p
4A6D: 48          ld   c,b
4A6E: 30 48       jr   nc,$49F4
4A70: 41          ld   b,c
4A71: 4A          ld   c,d
4A72: 55          ld   d,l
4A73: 40          ld   b,b
4A74: 45          ld   b,l
4A75: 40          ld   b,b
4A76: C5          push bc
4A77: 40          ld   b,b
4A78: 55          ld   d,l
4A79: 40          ld   b,b
4A7A: D5          push de
4A7B: 40          ld   b,b
4A7C: 63          ld   h,e
4A7D: 48          ld   c,b
4A7E: 81          add  a,c
4A7F: 48          ld   c,b
4A80: 60          ld   h,b
4A81: 48          ld   c,b
4A82: 61          ld   h,c
4A83: 48          ld   c,b
4A84: 55          ld   d,l
4A85: 40          ld   b,b
4A86: D5          push de
4A87: 40          ld   b,b
4A88: 63          ld   h,e
4A89: 48          ld   c,b
4A8A: 01 48 C2    ld   bc,$2C84
4A8D: 48          ld   c,b
4A8E: 01 48 73    ld   bc,$3784
4A91: 48          ld   c,b
4A92: B3          or   e
4A93: 48          ld   c,b
4A94: E3          ex   (sp),hl
4A95: 4A          ld   c,d
4A96: 32 48 B3    ld   ($3B84),a
4A99: 48          ld   c,b
4A9A: B2          or   d
4A9B: 48          ld   c,b
4A9C: C5          push bc
4A9D: 40          ld   b,b
4A9E: 70          ld   (hl),b
4A9F: 58          ld   e,b
4AA0: B2          or   d
4AA1: 48          ld   c,b
4AA2: 93          sub  e
4AA3: 48          ld   c,b
4AA4: 73          ld   (hl),e
4AA5: 48          ld   c,b
4AA6: 90          sub  b
4AA7: 58          ld   e,b
4AA8: E2 48 51    jp   po,$1584
4AAB: 48          ld   c,b
4AAC: F0          ret  p
4AAD: 48          ld   c,b
4AAE: E3          ex   (sp),hl
4AAF: 48          ld   c,b
4AB0: D5          push de
4AB1: 42          ld   b,d
4AB2: 55          ld   d,l
4AB3: 40          ld   b,b
4AB4: 45          ld   b,l
4AB5: 40          ld   b,b
4AB6: C5          push bc
4AB7: 40          ld   b,b
4AB8: 55          ld   d,l
4AB9: 40          ld   b,b
4ABA: C5          push bc
4ABB: 40          ld   b,b
4ABC: C5          push bc
4ABD: 40          ld   b,b
4ABE: 55          ld   d,l
4ABF: 40          ld   b,b
4AC0: C5          push bc
4AC1: 40          ld   b,b
4AC2: 55          ld   d,l
4AC3: 40          ld   b,b
4AC4: F4 A9 D5    call p,$5D8B
4AC7: A9          xor  c
4AC8: F4 A9 F5    call p,$5F8B
4ACB: A9          xor  c
4ACC: D5          push de
4ACD: A9          xor  c
4ACE: F4 A9 D4    call p,$5C8B
4AD1: A9          xor  c
4AD2: D5          push de
4AD3: A9          xor  c
4AD4: 11 AF 10    ld   de,$10EB
4AD7: AF          xor  a
4AD8: D5          push de
4AD9: A9          xor  c
4ADA: F4 A9 F4    call p,$5E8B
4ADD: A9          xor  c
4ADE: D5          push de
4ADF: A9          xor  c
4AE0: D4 A9 D5    call nc,$5D8B
4AE3: A9          xor  c
4AE4: 73          ld   (hl),e
4AE5: 48          ld   c,b
4AE6: B3          or   e
4AE7: 48          ld   c,b
4AE8: 21 48 41    ld   hl,$0584
4AEB: 4A          ld   c,d
4AEC: B3          or   e
4AED: 48          ld   c,b
4AEE: B2          or   d
4AEF: 48          ld   c,b
4AF0: 93          sub  e
4AF1: 48          ld   c,b
4AF2: C0          ret  nz
4AF3: 48          ld   c,b
4AF4: B2          or   d
4AF5: 48          ld   c,b
4AF6: 50          ld   d,b
4AF7: 48          ld   c,b
4AF8: 51          ld   d,c
4AF9: 48          ld   c,b
4AFA: 55          ld   d,l
4AFB: 40          ld   b,b
4AFC: 31 48 55    ld   sp,$5584
4AFF: 40          ld   b,b
4B00: D5          push de
4B01: 40          ld   b,b
4B02: D5          push de
4B03: 40          ld   b,b
4B04: 92          sub  d
4B05: 48          ld   c,b
4B06: 93          sub  e
4B07: 48          ld   c,b
4B08: B2          or   d
4B09: 48          ld   c,b
4B0A: B3          or   e
4B0B: 48          ld   c,b
4B0C: B2          or   d
4B0D: 48          ld   c,b
4B0E: 93          sub  e
4B0F: 48          ld   c,b
4B10: B3          or   e
4B11: 48          ld   c,b
4B12: F2 48 93    jp   p,$3984
4B15: 48          ld   c,b
4B16: B2          or   d
4B17: 48          ld   c,b
4B18: 93          sub  e
4B19: 48          ld   c,b
4B1A: B2          or   d
4B1B: 48          ld   c,b
4B1C: 92          sub  d
4B1D: 48          ld   c,b
4B1E: 93          sub  e
4B1F: 48          ld   c,b
4B20: B2          or   d
4B21: 48          ld   c,b
4B22: B3          or   e
4B23: 48          ld   c,b
4B24: B2          or   d
4B25: 48          ld   c,b
4B26: 93          sub  e
4B27: 48          ld   c,b
4B28: 93          sub  e
4B29: 48          ld   c,b
4B2A: B2          or   d
4B2B: 48          ld   c,b
4B2C: F3          di
4B2D: 48          ld   c,b
4B2E: 93          sub  e
4B2F: 48          ld   c,b
4B30: B2          or   d
4B31: 48          ld   c,b
4B32: 93          sub  e
4B33: 48          ld   c,b
4B34: 93          sub  e
4B35: 48          ld   c,b
4B36: 92          sub  d
4B37: 48          ld   c,b
4B38: 93          sub  e
4B39: 48          ld   c,b
4B3A: B2          or   d
4B3B: 48          ld   c,b
4B3C: B2          or   d
4B3D: 48          ld   c,b
4B3E: 93          sub  e
4B3F: 48          ld   c,b
4B40: 92          sub  d
4B41: 48          ld   c,b
4B42: 93          sub  e
4B43: 48          ld   c,b
4B44: D5          push de
4B45: 40          ld   b,b
4B46: 55          ld   d,l
4B47: 40          ld   b,b
4B48: C5          push bc
4B49: 40          ld   b,b
4B4A: 45          ld   b,l
4B4B: 40          ld   b,b
4B4C: 55          ld   d,l
4B4D: 40          ld   b,b
4B4E: C5          push bc
4B4F: 42          ld   b,d
4B50: 45          ld   b,l
4B51: 40          ld   b,b
4B52: C5          push bc
4B53: 40          ld   b,b
4B54: D5          push de
4B55: 40          ld   b,b
4B56: 55          ld   d,l
4B57: 40          ld   b,b
4B58: C5          push bc
4B59: 42          ld   b,d
4B5A: 45          ld   b,l
4B5B: 42          ld   b,d
4B5C: C5          push bc
4B5D: 40          ld   b,b
4B5E: 55          ld   d,l
4B5F: 42          ld   b,d
4B60: D5          push de
4B61: 40          ld   b,b
4B62: 55          ld   d,l
4B63: 40          ld   b,b
4B64: 92          sub  d
4B65: 48          ld   c,b
4B66: 93          sub  e
4B67: 48          ld   c,b
4B68: B2          or   d
4B69: 48          ld   c,b
4B6A: B3          or   e
4B6B: 48          ld   c,b
4B6C: 93          sub  e
4B6D: 48          ld   c,b
4B6E: 92          sub  d
4B6F: 48          ld   c,b
4B70: 93          sub  e
4B71: 48          ld   c,b
4B72: B2          or   d
4B73: 48          ld   c,b
4B74: B2          or   d
4B75: 48          ld   c,b
4B76: 93          sub  e
4B77: 48          ld   c,b
4B78: B2          or   d
4B79: 48          ld   c,b
4B7A: B3          or   e
4B7B: 48          ld   c,b
4B7C: B3          or   e
4B7D: 48          ld   c,b
4B7E: 93          sub  e
4B7F: 48          ld   c,b
4B80: F2 48 F3    jp   p,$3F84
4B83: 48          ld   c,b
4B84: 45          ld   b,l
4B85: 40          ld   b,b
4B86: 55          ld   d,l
4B87: 40          ld   b,b
4B88: D5          push de
4B89: 40          ld   b,b
4B8A: 55          ld   d,l
4B8B: 40          ld   b,b
4B8C: C5          push bc
4B8D: 40          ld   b,b
4B8E: 55          ld   d,l
4B8F: 40          ld   b,b
4B90: C5          push bc
4B91: 40          ld   b,b
4B92: D5          push de
4B93: 40          ld   b,b
4B94: 55          ld   d,l
4B95: 40          ld   b,b
4B96: 53          ld   d,e
4B97: 48          ld   c,b
4B98: 72          ld   (hl),d
4B99: 48          ld   c,b
4B9A: 55          ld   d,l
4B9B: 40          ld   b,b
4B9C: C5          push bc
4B9D: 40          ld   b,b
4B9E: 45          ld   b,l
4B9F: 40          ld   b,b
4BA0: C5          push bc
4BA1: 40          ld   b,b
4BA2: D5          push de
4BA3: 40          ld   b,b
4BA4: B3          or   e
4BA5: 48          ld   c,b
4BA6: B2          or   d
4BA7: 48          ld   c,b
4BA8: 93          sub  e
4BA9: 48          ld   c,b
4BAA: B2          or   d
4BAB: 48          ld   c,b
4BAC: B2          or   d
4BAD: 48          ld   c,b
4BAE: F2 48 F3    jp   p,$3F84
4BB1: 48          ld   c,b
4BB2: 93          sub  e
4BB3: 48          ld   c,b
4BB4: 93          sub  e
4BB5: 48          ld   c,b
4BB6: 92          sub  d
4BB7: 48          ld   c,b
4BB8: 93          sub  e
4BB9: 48          ld   c,b
4BBA: B2          or   d
4BBB: 48          ld   c,b
4BBC: B2          or   d
4BBD: 48          ld   c,b
4BBE: 93          sub  e
4BBF: 48          ld   c,b
4BC0: B2          or   d
4BC1: 48          ld   c,b
4BC2: B3          or   e
4BC3: 48          ld   c,b
4BC4: 55          ld   d,l
4BC5: 40          ld   b,b
4BC6: D5          push de
4BC7: 40          ld   b,b
4BC8: 41          ld   b,c
4BC9: 48          ld   c,b
4BCA: 10 4A       djnz $4B70
4BCC: C5          push bc
4BCD: 40          ld   b,b
4BCE: 55          ld   d,l
4BCF: 40          ld   b,b
4BD0: 00          nop
4BD1: 4A          ld   c,d
4BD2: 10 5A       djnz $4B88
4BD4: 55          ld   d,l
4BD5: 40          ld   b,b
4BD6: 00          nop
4BD7: 4A          ld   c,d
4BD8: 10 5A       djnz $4B8E
4BDA: 73          ld   (hl),e
4BDB: 48          ld   c,b
4BDC: 41          ld   b,c
4BDD: 58          ld   e,b
4BDE: 10 5A       djnz $4B94
4BE0: B2          or   d
4BE1: 48          ld   c,b
4BE2: B3          or   e
4BE3: 48          ld   c,b
4BE4: 4C          ld   c,h
4BE5: AA          xor  d
4BE6: 2D          dec  l
4BE7: AA          xor  d
4BE8: 2C          inc  l
4BE9: AA          xor  d
4BEA: 00          nop
4BEB: 00          nop
4BEC: CC AA AD    call z,$CBAA
4BEF: AA          xor  d
4BF0: AC          xor  h
4BF1: AA          xor  d
4BF2: 00          nop
4BF3: 00          nop
4BF4: 5C          ld   e,h
4BF5: EB          ex   de,hl
4BF6: 3D          dec  a
4BF7: EB          ex   de,hl
4BF8: 3C          inc  a
4BF9: EB          ex   de,hl
4BFA: 00          nop
4BFB: 00          nop
4BFC: FD          db   $fd
4BFD: C2 FC C2    jp   nz,$2CDE
4C00: DD          db   $dd
4C01: C2 00 00    jp   nz,$0000
4C04: 92          sub  d
4C05: 48          ld   c,b
4C06: 93          sub  e
4C07: 48          ld   c,b
4C08: B2          or   d
4C09: 48          ld   c,b
4C0A: B3          or   e
4C0B: 48          ld   c,b
4C0C: B2          or   d
4C0D: 48          ld   c,b
4C0E: 93          sub  e
4C0F: 48          ld   c,b
4C10: B3          or   e
4C11: 48          ld   c,b
4C12: B2          or   d
4C13: 48          ld   c,b
4C14: 93          sub  e
4C15: 48          ld   c,b
4C16: B2          or   d
4C17: 48          ld   c,b
4C18: 93          sub  e
4C19: 48          ld   c,b
4C1A: B2          or   d
4C1B: 48          ld   c,b
4C1C: 92          sub  d
4C1D: 48          ld   c,b
4C1E: 93          sub  e
4C1F: 48          ld   c,b
4C20: B2          or   d
4C21: 48          ld   c,b
4C22: F2 48 B2    jp   p,$3A84
4C25: 48          ld   c,b
4C26: 93          sub  e
4C27: 48          ld   c,b
4C28: 93          sub  e
4C29: 48          ld   c,b
4C2A: B2          or   d
4C2B: 48          ld   c,b
4C2C: 93          sub  e
4C2D: 48          ld   c,b
4C2E: 93          sub  e
4C2F: 48          ld   c,b
4C30: B2          or   d
4C31: 48          ld   c,b
4C32: 93          sub  e
4C33: 48          ld   c,b
4C34: 93          sub  e
4C35: 48          ld   c,b
4C36: 92          sub  d
4C37: 48          ld   c,b
4C38: 93          sub  e
4C39: 48          ld   c,b
4C3A: B2          or   d
4C3B: 48          ld   c,b
4C3C: F3          di
4C3D: 48          ld   c,b
4C3E: 93          sub  e
4C3F: 48          ld   c,b
4C40: 92          sub  d
4C41: 48          ld   c,b
4C42: 93          sub  e
4C43: 48          ld   c,b
4C44: 93          sub  e
4C45: 48          ld   c,b
4C46: B2          or   d
4C47: 48          ld   c,b
4C48: B3          or   e
4C49: 48          ld   c,b
4C4A: 73          ld   (hl),e
4C4B: 48          ld   c,b
4C4C: 92          sub  d
4C4D: 48          ld   c,b
4C4E: 93          sub  e
4C4F: 48          ld   c,b
4C50: B2          or   d
4C51: 48          ld   c,b
4C52: B3          or   e
4C53: 48          ld   c,b
4C54: 93          sub  e
4C55: 4A          ld   c,d
4C56: 92          sub  d
4C57: 4A          ld   c,d
4C58: 93          sub  e
4C59: 48          ld   c,b
4C5A: B2          or   d
4C5B: 48          ld   c,b
4C5C: 92          sub  d
4C5D: 48          ld   c,b
4C5E: 93          sub  e
4C5F: 48          ld   c,b
4C60: B2          or   d
4C61: 48          ld   c,b
4C62: B3          or   e
4C63: 48          ld   c,b
4C64: 00          nop
4C65: 00          nop
4C66: 2C          inc  l
4C67: A8          xor  b
4C68: 2D          dec  l
4C69: A8          xor  b
4C6A: 4C          ld   c,h
4C6B: A8          xor  b
4C6C: 00          nop
4C6D: 00          nop
4C6E: AC          xor  h
4C6F: A8          xor  b
4C70: AD          xor  l
4C71: A8          xor  b
4C72: CC A8 00    call z,$008A
4C75: 00          nop
4C76: 3C          inc  a
4C77: E9          jp   (hl)
4C78: 3D          dec  a
4C79: E9          jp   (hl)
4C7A: 5C          ld   e,h
4C7B: E9          jp   (hl)
4C7C: 00          nop
4C7D: 00          nop
4C7E: DD          db   $dd
4C7F: C0          ret  nz
4C80: FC C0 FD    call m,$DF0C
4C83: C0          ret  nz
4C84: 45          ld   b,l
4C85: A8          xor  b
4C86: 45          ld   b,l
4C87: A8          xor  b
4C88: 45          ld   b,l
4C89: A8          xor  b
4C8A: 07          rlca
4C8B: AE          xor  (hl)
4C8C: 45          ld   b,l
4C8D: A8          xor  b
4C8E: 45          ld   b,l
4C8F: A8          xor  b
4C90: 07          rlca
4C91: AE          xor  (hl)
4C92: B3          or   e
4C93: 48          ld   c,b
4C94: 45          ld   b,l
4C95: A8          xor  b
4C96: 07          rlca
4C97: AE          xor  (hl)
4C98: 93          sub  e
4C99: 48          ld   c,b
4C9A: B2          or   d
4C9B: 48          ld   c,b
4C9C: 07          rlca
4C9D: AE          xor  (hl)
4C9E: 93          sub  e
4C9F: 48          ld   c,b
4CA0: 92          sub  d
4CA1: 48          ld   c,b
4CA2: B3          or   e
4CA3: 48          ld   c,b
4CA4: 73          ld   (hl),e
4CA5: 48          ld   c,b
4CA6: B2          or   d
4CA7: 48          ld   c,b
4CA8: 93          sub  e
4CA9: 48          ld   c,b
4CAA: 06 AE       ld   b,$EA
4CAC: B3          or   e
4CAD: 48          ld   c,b
4CAE: 93          sub  e
4CAF: 48          ld   c,b
4CB0: 06 AE       ld   b,$EA
4CB2: 45          ld   b,l
4CB3: A8          xor  b
4CB4: B2          or   d
4CB5: 48          ld   c,b
4CB6: 06 AE       ld   b,$EA
4CB8: 45          ld   b,l
4CB9: A8          xor  b
4CBA: 45          ld   b,l
4CBB: A8          xor  b
4CBC: 06 AE       ld   b,$EA
4CBE: 45          ld   b,l
4CBF: A8          xor  b
4CC0: 45          ld   b,l
4CC1: A8          xor  b
4CC2: 45          ld   b,l
4CC3: A8          xor  b
4CC4: B3          or   e
4CC5: 48          ld   c,b
4CC6: E8          ret  pe
4CC7: AC          xor  h
4CC8: E9          jp   (hl)
4CC9: AC          xor  h
4CCA: E8          ret  pe
4CCB: AE          xor  (hl)
4CCC: C9          ret
4CCD: AC          xor  h
4CCE: C8          ret  z
4CCF: AC          xor  h
4CD0: C8          ret  z
4CD1: AC          xor  h
4CD2: C8          ret  z
4CD3: AE          xor  (hl)
4CD4: 59          ld   e,c
4CD5: AC          xor  h
4CD6: 78          ld   a,b
4CD7: AC          xor  h
4CD8: 79          ld   a,c
4CD9: AC          xor  h
4CDA: 78          ld   a,b
4CDB: AE          xor  (hl)
4CDC: D9          exx
4CDD: AC          xor  h
4CDE: F8          ret  m
4CDF: AC          xor  h
4CE0: F9          ld   sp,hl
4CE1: AC          xor  h
4CE2: F8          ret  m
4CE3: AE          xor  (hl)
4CE4: 2B          dec  hl
4CE5: AC          xor  h
4CE6: 4A          ld   c,d
4CE7: AC          xor  h
4CE8: 4B          ld   c,e
4CE9: AC          xor  h
4CEA: 4A          ld   c,d
4CEB: AE          xor  (hl)
4CEC: AB          xor  e
4CED: AC          xor  h
4CEE: CA AC CB    jp   z,$ADCA
4CF1: AC          xor  h
4CF2: CA AE 3B    jp   z,$B3EA
4CF5: AC          xor  h
4CF6: 5A          ld   e,d
4CF7: AC          xor  h
4CF8: 5B          ld   e,e
4CF9: AC          xor  h
4CFA: 5A          ld   e,d
4CFB: AE          xor  (hl)
4CFC: BB          cp   e
4CFD: AC          xor  h
4CFE: DA AC DB    jp   c,$BDCA
4D01: AC          xor  h
4D02: DA AE B3    jp   c,$3BEA
4D05: 48          ld   c,b
4D06: B2          or   d
4D07: 48          ld   c,b
4D08: 93          sub  e
4D09: 48          ld   c,b
4D0A: D6 AC       sub  $CA
4D0C: B2          or   d
4D0D: 48          ld   c,b
4D0E: 93          sub  e
4D0F: 48          ld   c,b
4D10: 92          sub  d
4D11: 48          ld   c,b
4D12: B6          or   (hl)
4D13: AC          xor  h
4D14: B3          or   e
4D15: 48          ld   c,b
4D16: 73          ld   (hl),e
4D17: 48          ld   c,b
4D18: B3          or   e
4D19: 48          ld   c,b
4D1A: B7          or   a
4D1B: AC          xor  h
4D1C: 73          ld   (hl),e
4D1D: 48          ld   c,b
4D1E: B3          or   e
4D1F: 48          ld   c,b
4D20: B2          or   d
4D21: 48          ld   c,b
4D22: 93          sub  e
4D23: 48          ld   c,b
4D24: 00          nop
4D25: 00          nop
4D26: 5D          ld   e,l
4D27: C0          ret  nz
4D28: 7C          ld   a,h
4D29: C0          ret  nz
4D2A: 2D          dec  l
4D2B: C0          ret  nz
4D2C: 00          nop
4D2D: 00          nop
4D2E: 2C          inc  l
4D2F: C0          ret  nz
4D30: 2D          dec  l
4D31: C0          ret  nz
4D32: D4 C8 00    call nc,$008C
4D35: 00          nop
4D36: F5          push af
4D37: C8          ret  z
4D38: F4 C8 D5    call p,$5D8C
4D3B: C8          ret  z
4D3C: 00          nop
4D3D: 00          nop
4D3E: F4 C8 D5    call p,$5D8C
4D41: C8          ret  z
4D42: D4 C8 B2    call nc,$3A8C
4D45: 48          ld   c,b
4D46: 93          sub  e
4D47: 48          ld   c,b
4D48: 93          sub  e
4D49: 48          ld   c,b
4D4A: B2          or   d
4D4B: 48          ld   c,b
4D4C: F2 48 F3    jp   p,$3F84
4D4F: 48          ld   c,b
4D50: B2          or   d
4D51: 48          ld   c,b
4D52: 93          sub  e
4D53: 48          ld   c,b
4D54: 93          sub  e
4D55: 48          ld   c,b
4D56: 92          sub  d
4D57: 48          ld   c,b
4D58: 93          sub  e
4D59: 48          ld   c,b
4D5A: B2          or   d
4D5B: 48          ld   c,b
4D5C: B2          or   d
4D5D: 48          ld   c,b
4D5E: 93          sub  e
4D5F: 48          ld   c,b
4D60: 92          sub  d
4D61: 48          ld   c,b
4D62: 93          sub  e
4D63: 48          ld   c,b
4D64: BC          cp   h
4D65: A8          xor  b
4D66: BD          cp   l
4D67: A8          xor  b
4D68: 45          ld   b,l
4D69: A8          xor  b
4D6A: 45          ld   b,l
4D6B: A8          xor  b
4D6C: 45          ld   b,l
4D6D: A8          xor  b
4D6E: 45          ld   b,l
4D6F: A8          xor  b
4D70: BC          cp   h
4D71: A8          xor  b
4D72: BD          cp   l
4D73: A8          xor  b
4D74: 45          ld   b,l
4D75: A8          xor  b
4D76: 45          ld   b,l
4D77: A8          xor  b
4D78: 45          ld   b,l
4D79: A8          xor  b
4D7A: 45          ld   b,l
4D7B: A8          xor  b
4D7C: 45          ld   b,l
4D7D: A8          xor  b
4D7E: 45          ld   b,l
4D7F: A8          xor  b
4D80: 45          ld   b,l
4D81: A8          xor  b
4D82: 45          ld   b,l
4D83: A8          xor  b
4D84: 45          ld   b,l
4D85: A8          xor  b
4D86: 45          ld   b,l
4D87: A8          xor  b
4D88: 45          ld   b,l
4D89: A8          xor  b
4D8A: 45          ld   b,l
4D8B: A8          xor  b
4D8C: 45          ld   b,l
4D8D: A8          xor  b
4D8E: 45          ld   b,l
4D8F: A8          xor  b
4D90: 45          ld   b,l
4D91: A8          xor  b
4D92: 45          ld   b,l
4D93: A8          xor  b
4D94: BC          cp   h
4D95: A8          xor  b
4D96: BD          cp   l
4D97: A8          xor  b
4D98: 45          ld   b,l
4D99: A8          xor  b
4D9A: 45          ld   b,l
4D9B: A8          xor  b
4D9C: 45          ld   b,l
4D9D: A8          xor  b
4D9E: 45          ld   b,l
4D9F: A8          xor  b
4DA0: BC          cp   h
4DA1: A8          xor  b
4DA2: BD          cp   l
4DA3: A8          xor  b
4DA4: 00          nop
4DA5: 00          nop
4DA6: AC          xor  h
4DA7: C0          ret  nz
4DA8: AD          xor  l
4DA9: C0          ret  nz
4DAA: CC C0 00    call z,$000C
4DAD: 00          nop
4DAE: 3C          inc  a
4DAF: C0          ret  nz
4DB0: 3D          dec  a
4DB1: C0          ret  nz
4DB2: 5C          ld   e,h
4DB3: C0          ret  nz
4DB4: 00          nop
4DB5: 00          nop
4DB6: BC          cp   h
4DB7: C0          ret  nz
4DB8: BD          cp   l
4DB9: C0          ret  nz
4DBA: DC C0 00    call c,$000C
4DBD: 00          nop
4DBE: CD C0 EC    call $CE0C
4DC1: C0          ret  nz
4DC2: ED          db   $ed
4DC3: C0          ret  nz
4DC4: 04          inc  b
4DC5: 68          ld   l,b
4DC6: 05          dec  b
4DC7: 68          ld   l,b
4DC8: 24          inc  h
4DC9: 68          ld   l,b
4DCA: 25          dec  h
4DCB: 68          ld   l,b
4DCC: 05          dec  b
4DCD: 68          ld   l,b
4DCE: 24          inc  h
4DCF: 68          ld   l,b
4DD0: 24          inc  h
4DD1: 68          ld   l,b
4DD2: 44          ld   b,h
4DD3: 68          ld   l,b
4DD4: 05          dec  b
4DD5: 68          ld   l,b
4DD6: 25          dec  h
4DD7: 68          ld   l,b
4DD8: 25          dec  h
4DD9: 68          ld   l,b
4DDA: 44          ld   b,h
4DDB: 68          ld   l,b
4DDC: 05          dec  b
4DDD: 68          ld   l,b
4DDE: 24          inc  h
4DDF: 68          ld   l,b
4DE0: 44          ld   b,h
4DE1: 68          ld   l,b
4DE2: 25          dec  h
4DE3: 68          ld   l,b
4DE4: 44          ld   b,h
4DE5: 68          ld   l,b
4DE6: 24          inc  h
4DE7: 68          ld   l,b
4DE8: 05          dec  b
4DE9: 68          ld   l,b
4DEA: 04          inc  b
4DEB: 68          ld   l,b
4DEC: 25          dec  h
4DED: 68          ld   l,b
4DEE: 24          inc  h
4DEF: 68          ld   l,b
4DF0: 24          inc  h
4DF1: 68          ld   l,b
4DF2: 05          dec  b
4DF3: 68          ld   l,b
4DF4: 24          inc  h
4DF5: 68          ld   l,b
4DF6: 44          ld   b,h
4DF7: 68          ld   l,b
4DF8: 24          inc  h
4DF9: 68          ld   l,b
4DFA: 24          inc  h
4DFB: 68          ld   l,b
4DFC: 44          ld   b,h
4DFD: 68          ld   l,b
4DFE: 05          dec  b
4DFF: 68          ld   l,b
4E00: 24          inc  h
4E01: 68          ld   l,b
4E02: 05          dec  b
4E03: 68          ld   l,b
4E04: 24          inc  h
4E05: 68          ld   l,b
4E06: 85          add  a,l
4E07: 68          ld   l,b
4E08: A4          and  h
4E09: 68          ld   l,b
4E0A: A5          and  l
4E0B: 68          ld   l,b
4E0C: 14          inc  d
4E0D: 68          ld   l,b
4E0E: 15          dec  d
4E0F: 68          ld   l,b
4E10: 34          inc  (hl)
4E11: 68          ld   l,b
4E12: 35          dec  (hl)
4E13: 68          ld   l,b
4E14: 94          sub  h
4E15: 68          ld   l,b
4E16: 95          sub  l
4E17: 68          ld   l,b
4E18: B4          or   h
4E19: 68          ld   l,b
4E1A: B5          or   l
4E1B: 68          ld   l,b
4E1C: 25          dec  h
4E1D: 68          ld   l,b
4E1E: 44          ld   b,h
4E1F: 68          ld   l,b
4E20: 25          dec  h
4E21: 68          ld   l,b
4E22: 24          inc  h
4E23: 68          ld   l,b
4E24: 44          ld   b,h
4E25: 68          ld   l,b
4E26: 25          dec  h
4E27: 68          ld   l,b
4E28: 24          inc  h
4E29: 68          ld   l,b
4E2A: 44          ld   b,h
4E2B: 68          ld   l,b
4E2C: C4 68 C5    call nz,$4D86
4E2F: 68          ld   l,b
4E30: E4 68 24    call po,$4286
4E33: 68          ld   l,b
4E34: 54          ld   d,h
4E35: 68          ld   l,b
4E36: 55          ld   d,l
4E37: 68          ld   l,b
4E38: 74          ld   (hl),h
4E39: 68          ld   l,b
4E3A: 05          dec  b
4E3B: 68          ld   l,b
4E3C: 05          dec  b
4E3D: 68          ld   l,b
4E3E: 24          inc  h
4E3F: 68          ld   l,b
4E40: 25          dec  h
4E41: 68          ld   l,b
4E42: 25          dec  h
4E43: 68          ld   l,b
4E44: 48          ld   c,b
4E45: ED 49       out  (c),c
4E47: ED 68       in   l,(c)
4E49: ED 69       out  (c),l
4E4B: ED 49       out  (c),c
4E4D: ED 68       in   l,(c)
4E4F: ED 49       out  (c),c
4E51: ED 69       out  (c),l
4E53: ED 68       in   l,(c)
4E55: ED 49       out  (c),c
4E57: ED 48       in   c,(c)
4E59: ED 49       out  (c),c
4E5B: ED 69       out  (c),l
4E5D: ED 68       in   l,(c)
4E5F: ED 49       out  (c),c
4E61: ED 48       in   c,(c)
4E63: ED 64       neg  *
4E65: A8          xor  b
4E66: 65          ld   h,l
4E67: A8          xor  b
4E68: 45          ld   b,l
4E69: A8          xor  b
4E6A: 45          ld   b,l
4E6B: A8          xor  b
4E6C: B3          or   e
4E6D: 48          ld   c,b
4E6E: B2          or   d
4E6F: 48          ld   c,b
4E70: E5          push hl
4E71: A8          xor  b
4E72: 45          ld   b,l
4E73: A8          xor  b
4E74: B2          or   d
4E75: 48          ld   c,b
4E76: 96          sub  (hl)
4E77: A8          xor  b
4E78: 45          ld   b,l
4E79: A8          xor  b
4E7A: 45          ld   b,l
4E7B: A8          xor  b
4E7C: 96          sub  (hl)
4E7D: A8          xor  b
4E7E: 45          ld   b,l
4E7F: A8          xor  b
4E80: 45          ld   b,l
4E81: A8          xor  b
4E82: 45          ld   b,l
4E83: A8          xor  b
4E84: 45          ld   b,l
4E85: A8          xor  b
4E86: 45          ld   b,l
4E87: A8          xor  b
4E88: 45          ld   b,l
4E89: A8          xor  b
4E8A: 27          daa
4E8B: A8          xor  b
4E8C: 45          ld   b,l
4E8D: A8          xor  b
4E8E: 45          ld   b,l
4E8F: A8          xor  b
4E90: 27          daa
4E91: A8          xor  b
4E92: B3          or   e
4E93: 48          ld   c,b
4E94: 45          ld   b,l
4E95: A8          xor  b
4E96: 75          ld   (hl),l
4E97: A8          xor  b
4E98: 93          sub  e
4E99: 48          ld   c,b
4E9A: B2          or   d
4E9B: 48          ld   c,b
4E9C: 45          ld   b,l
4E9D: A8          xor  b
4E9E: 45          ld   b,l
4E9F: A8          xor  b
4EA0: 97          sub  a
4EA1: A8          xor  b
4EA2: B6          or   (hl)
4EA3: A8          xor  b
4EA4: 97          sub  a
4EA5: A8          xor  b
4EA6: B6          or   (hl)
4EA7: A8          xor  b
4EA8: B3          or   e
4EA9: 48          ld   c,b
4EAA: B2          or   d
4EAB: 48          ld   c,b
4EAC: 45          ld   b,l
4EAD: A8          xor  b
4EAE: 45          ld   b,l
4EAF: A8          xor  b
4EB0: 97          sub  a
4EB1: A8          xor  b
4EB2: B6          or   (hl)
4EB3: A8          xor  b
4EB4: 45          ld   b,l
4EB5: A8          xor  b
4EB6: 45          ld   b,l
4EB7: A8          xor  b
4EB8: 45          ld   b,l
4EB9: A8          xor  b
4EBA: 45          ld   b,l
4EBB: A8          xor  b
4EBC: 45          ld   b,l
4EBD: A8          xor  b
4EBE: 45          ld   b,l
4EBF: A8          xor  b
4EC0: 45          ld   b,l
4EC1: A8          xor  b
4EC2: 45          ld   b,l
4EC3: A8          xor  b
4EC4: B3          or   e
4EC5: 48          ld   c,b
4EC6: B2          or   d
4EC7: 48          ld   c,b
4EC8: 93          sub  e
4EC9: 48          ld   c,b
4ECA: B2          or   d
4ECB: 48          ld   c,b
4ECC: B2          or   d
4ECD: 48          ld   c,b
4ECE: 93          sub  e
4ECF: 48          ld   c,b
4ED0: 92          sub  d
4ED1: 48          ld   c,b
4ED2: B3          or   e
4ED3: 48          ld   c,b
4ED4: 97          sub  a
4ED5: A8          xor  b
4ED6: B6          or   (hl)
4ED7: A8          xor  b
4ED8: 93          sub  e
4ED9: 48          ld   c,b
4EDA: B2          or   d
4EDB: 48          ld   c,b
4EDC: 45          ld   b,l
4EDD: A8          xor  b
4EDE: 45          ld   b,l
4EDF: A8          xor  b
4EE0: 97          sub  a
4EE1: A8          xor  b
4EE2: B6          or   (hl)
4EE3: A8          xor  b
4EE4: 73          ld   (hl),e
4EE5: 48          ld   c,b
4EE6: 28 88       jr   z,$4E70
4EE8: 09          add  hl,bc
4EE9: 88          adc  a,b
4EEA: 08          ex   af,af'
4EEB: 88          adc  a,b
4EEC: B3          or   e
4EED: 48          ld   c,b
4EEE: 29          add  hl,hl
4EEF: 88          adc  a,b
4EF0: 48          ld   c,b
4EF1: 88          adc  a,b
4EF2: 48          ld   c,b
4EF3: 88          adc  a,b
4EF4: B2          or   d
4EF5: 48          ld   c,b
4EF6: B3          or   e
4EF7: 4A          ld   c,d
4EF8: 49          ld   c,c
4EF9: 88          adc  a,b
4EFA: 68          ld   l,b
4EFB: 88          adc  a,b
4EFC: 93          sub  e
4EFD: 48          ld   c,b
4EFE: B2          or   d
4EFF: 4A          ld   c,d
4F00: 93          sub  e
4F01: 4A          ld   c,d
4F02: B2          or   d
4F03: 48          ld   c,b
4F04: C8          ret  z
4F05: 88          adc  a,b
4F06: B2          or   d
4F07: 48          ld   c,b
4F08: 73          ld   (hl),e
4F09: 48          ld   c,b
4F0A: B3          or   e
4F0B: 48          ld   c,b
4F0C: 48          ld   c,b
4F0D: 88          adc  a,b
4F0E: A9          xor  c
4F0F: 88          adc  a,b
4F10: A8          xor  b
4F11: 88          adc  a,b
4F12: 73          ld   (hl),e
4F13: 48          ld   c,b
4F14: 69          ld   l,c
4F15: 88          adc  a,b
4F16: 88          adc  a,b
4F17: 88          adc  a,b
4F18: 89          adc  a,c
4F19: 88          adc  a,b
4F1A: B3          or   e
4F1B: 48          ld   c,b
4F1C: 93          sub  e
4F1D: 48          ld   c,b
4F1E: 92          sub  d
4F1F: 48          ld   c,b
4F20: 93          sub  e
4F21: 4A          ld   c,d
4F22: B2          or   d
4F23: 48          ld   c,b
4F24: B2          or   d
4F25: 48          ld   c,b
4F26: 93          sub  e
4F27: 48          ld   c,b
4F28: B2          or   d
4F29: 48          ld   c,b
4F2A: B3          or   e
4F2B: 48          ld   c,b
4F2C: 93          sub  e
4F2D: 48          ld   c,b
4F2E: B2          or   d
4F2F: 48          ld   c,b
4F30: B3          or   e
4F31: 48          ld   c,b
4F32: B2          or   d
4F33: 48          ld   c,b
4F34: B3          or   e
4F35: 48          ld   c,b
4F36: 73          ld   (hl),e
4F37: 48          ld   c,b
4F38: 4C          ld   c,h
4F39: C1          pop  bc
4F3A: 4D          ld   c,l
4F3B: C1          pop  bc
4F3C: B2          or   d
4F3D: 48          ld   c,b
4F3E: 93          sub  e
4F3F: 48          ld   c,b
4F40: B2          or   d
4F41: 48          ld   c,b
4F42: B3          or   e
4F43: 48          ld   c,b
4F44: 38 08       jr   c,$4EC6
4F46: 39          add  hl,sp
4F47: 08          ex   af,af'
4F48: 58          ld   e,b
4F49: 08          ex   af,af'
4F4A: 59          ld   e,c
4F4B: 08          ex   af,af'
4F4C: B8          cp   b
4F4D: 08          ex   af,af'
4F4E: 0A          ld   a,(bc)
4F4F: 08          ex   af,af'
4F50: 99          sbc  a,c
4F51: 88          adc  a,b
4F52: 8A          adc  a,d
4F53: 88          adc  a,b
4F54: 98          sbc  a,b
4F55: 88          adc  a,b
4F56: 99          sbc  a,c
4F57: 88          adc  a,b
4F58: 98          sbc  a,b
4F59: 88          adc  a,b
4F5A: 1A          ld   a,(de)
4F5B: 88          adc  a,b
4F5C: 99          sbc  a,c
4F5D: 88          adc  a,b
4F5E: 98          sbc  a,b
4F5F: 88          adc  a,b
4F60: 99          sbc  a,c
4F61: 88          adc  a,b
4F62: 9A          sbc  a,d
4F63: 88          adc  a,b
4F64: 98          sbc  a,b
4F65: 88          adc  a,b
4F66: 99          sbc  a,c
4F67: 88          adc  a,b
4F68: 98          sbc  a,b
4F69: 88          adc  a,b
4F6A: 9A          sbc  a,d
4F6B: 88          adc  a,b
4F6C: 99          sbc  a,c
4F6D: 88          adc  a,b
4F6E: 98          sbc  a,b
4F6F: 88          adc  a,b
4F70: 99          sbc  a,c
4F71: 88          adc  a,b
4F72: 78          ld   a,b
4F73: 88          adc  a,b
4F74: B9          cp   c
4F75: 08          ex   af,af'
4F76: D8          ret  c
4F77: 08          ex   af,af'
4F78: D9          exx
4F79: 08          ex   af,af'
4F7A: F8          ret  m
4F7B: 08          ex   af,af'
4F7C: D4 A9 D5    call nc,$5D8B
4F7F: A9          xor  c
4F80: F4 A9 F5    call p,$5F8B
4F83: A9          xor  c
4F84: 0B          dec  bc
4F85: 89          adc  a,c
4F86: 2A 89 2B    ld   hl,($A389)
4F89: 89          adc  a,c
4F8A: 4A          ld   c,d
4F8B: 89          adc  a,c
4F8C: 8B          adc  a,e
4F8D: 89          adc  a,c
4F8E: AA          xor  d
4F8F: 89          adc  a,c
4F90: AB          xor  e
4F91: 89          adc  a,c
4F92: CA 89 1B    jp   z,$B189
4F95: 89          adc  a,c
4F96: 3A 89 3B    ld   a,($B389)
4F99: 89          adc  a,c
4F9A: 5A          ld   e,d
4F9B: 89          adc  a,c
4F9C: 9B          sbc  a,e
4F9D: 89          adc  a,c
4F9E: AA          xor  d
4F9F: 89          adc  a,c
4FA0: BB          cp   e
4FA1: 89          adc  a,c
4FA2: DA 89 9B    jp   c,$B989
4FA5: 89          adc  a,c
4FA6: BA          cp   d
4FA7: 89          adc  a,c
4FA8: 6B          ld   l,e
4FA9: 89          adc  a,c
4FAA: 0C          inc  c
4FAB: 89          adc  a,c
4FAC: 79          ld   a,c
4FAD: 89          adc  a,c
4FAE: EA 89 EB    jp   pe,$AF89
4FB1: 89          adc  a,c
4FB2: 8C          adc  a,h
4FB3: 89          adc  a,c
4FB4: 79          ld   a,c
4FB5: 89          adc  a,c
4FB6: 7A          ld   a,d
4FB7: 89          adc  a,c
4FB8: 7B          ld   a,e
4FB9: 89          adc  a,c
4FBA: 1C          inc  e
4FBB: 89          adc  a,c
4FBC: F9          ld   sp,hl
4FBD: 08          ex   af,af'
4FBE: FA 89 FB    jp   m,$BF89
4FC1: 89          adc  a,c
4FC2: 9C          sbc  a,h
4FC3: 89          adc  a,c
4FC4: 4B          ld   c,e
4FC5: 89          adc  a,c
4FC6: 0B          dec  bc
4FC7: 8B          adc  a,e
4FC8: 59          ld   e,c
4FC9: 0A          ld   a,(bc)
4FCA: 39          add  hl,sp
4FCB: 0A          ld   a,(bc)
4FCC: CB 89       res  1,c
4FCE: 8B          adc  a,e
4FCF: 8B          adc  a,e
4FD0: 8A          adc  a,d
4FD1: 8A          adc  a,d
4FD2: D6 0A       sub  $A0
4FD4: 5B          ld   e,e
4FD5: 89          adc  a,c
4FD6: 1B          dec  de
4FD7: 8B          adc  a,e
4FD8: 1A          ld   a,(de)
4FD9: 8A          adc  a,d
4FDA: 99          sbc  a,c
4FDB: 88          adc  a,b
4FDC: DB 89       in   a,($89)
4FDE: 9B          sbc  a,e
4FDF: 8B          adc  a,e
4FE0: 9A          sbc  a,d
4FE1: 8A          adc  a,d
4FE2: 98          sbc  a,b
4FE3: 88          adc  a,b
4FE4: 0D          dec  c
4FE5: 89          adc  a,c
4FE6: 9B          sbc  a,e
4FE7: 8B          adc  a,e
4FE8: 9A          sbc  a,d
4FE9: 8A          adc  a,d
4FEA: 99          sbc  a,c
4FEB: 88          adc  a,b
4FEC: 8D          adc  a,l
4FED: 89          adc  a,c
4FEE: 79          ld   a,c
4FEF: 8B          adc  a,e
4FF0: 78          ld   a,b
4FF1: 8A          adc  a,d
4FF2: 98          sbc  a,b
4FF3: 88          adc  a,b
4FF4: 1D          dec  e
4FF5: 89          adc  a,c
4FF6: 79          ld   a,c
4FF7: 8B          adc  a,e
4FF8: B9          cp   c
4FF9: 08          ex   af,af'
4FFA: D8          ret  c
4FFB: 08          ex   af,af'
4FFC: 9D          sbc  a,l
4FFD: 89          adc  a,c
4FFE: F4 A9 F4    call p,$5E8B
5001: A9          xor  c
5002: D5          push de
5003: A9          xor  c
5004: 39          add  hl,sp
5005: 0A          ld   a,(bc)
5006: 39          add  hl,sp
5007: 08          ex   af,af'
5008: 39          add  hl,sp
5009: 0A          ld   a,(bc)
500A: 38 0A       jr   c,$4FAC
500C: D6 0A       sub  $A0
500E: D6 08       sub  $80
5010: D6 0A       sub  $A0
5012: B8          cp   b
5013: 0A          ld   a,(bc)
5014: 99          sbc  a,c
5015: 88          adc  a,b
5016: 98          sbc  a,b
5017: 88          adc  a,b
5018: 99          sbc  a,c
5019: 88          adc  a,b
501A: 98          sbc  a,b
501B: 88          adc  a,b
501C: 98          sbc  a,b
501D: 88          adc  a,b
501E: 99          sbc  a,c
501F: 88          adc  a,b
5020: 98          sbc  a,b
5021: 88          adc  a,b
5022: 99          sbc  a,c
5023: 88          adc  a,b
5024: 99          sbc  a,c
5025: 88          adc  a,b
5026: 98          sbc  a,b
5027: 88          adc  a,b
5028: 99          sbc  a,c
5029: 88          adc  a,b
502A: 98          sbc  a,b
502B: 88          adc  a,b
502C: 98          sbc  a,b
502D: 88          adc  a,b
502E: 99          sbc  a,c
502F: 88          adc  a,b
5030: 98          sbc  a,b
5031: 88          adc  a,b
5032: 99          sbc  a,c
5033: 88          adc  a,b
5034: D9          exx
5035: 08          ex   af,af'
5036: D9          exx
5037: 0A          ld   a,(bc)
5038: D8          ret  c
5039: 0A          ld   a,(bc)
503A: B9          cp   c
503B: 0A          ld   a,(bc)
503C: F4 A9 D5    call p,$5D8B
503F: A9          xor  c
5040: D4 A9 D5    call nc,$5D8B
5043: A9          xor  c
5044: 00          nop
5045: 00          nop
5046: 2C          inc  l
5047: A8          xor  b
5048: 2D          dec  l
5049: A8          xor  b
504A: 4C          ld   c,h
504B: A8          xor  b
504C: 00          nop
504D: 00          nop
504E: AC          xor  h
504F: A8          xor  b
5050: AD          xor  l
5051: A8          xor  b
5052: CC A8 00    call z,$008A
5055: 00          nop
5056: 3C          inc  a
5057: A8          xor  b
5058: 3D          dec  a
5059: A8          xor  b
505A: 5C          ld   e,h
505B: A8          xor  b
505C: 00          nop
505D: 00          nop
505E: 73          ld   (hl),e
505F: 48          ld   c,b
5060: B3          or   e
5061: 48          ld   c,b
5062: B2          or   d
5063: 48          ld   c,b
5064: 4D          ld   c,l
5065: A8          xor  b
5066: 6C          ld   l,h
5067: A8          xor  b
5068: 73          ld   (hl),e
5069: 48          ld   c,b
506A: B3          or   e
506B: 48          ld   c,b
506C: CD A8 EC    call $CE8A
506F: A8          xor  b
5070: B3          or   e
5071: 48          ld   c,b
5072: B2          or   d
5073: 48          ld   c,b
5074: 5D          ld   e,l
5075: A8          xor  b
5076: 7C          ld   a,h
5077: A8          xor  b
5078: B2          or   d
5079: 48          ld   c,b
507A: 93          sub  e
507B: 48          ld   c,b
507C: B2          or   d
507D: 48          ld   c,b
507E: B3          or   e
507F: 48          ld   c,b
5080: 73          ld   (hl),e
5081: 48          ld   c,b
5082: B3          or   e
5083: 48          ld   c,b
5084: 73          ld   (hl),e
5085: 48          ld   c,b
5086: B3          or   e
5087: 48          ld   c,b
5088: 6C          ld   l,h
5089: AA          xor  d
508A: 4D          ld   c,l
508B: AA          xor  d
508C: B3          or   e
508D: 48          ld   c,b
508E: B2          or   d
508F: 48          ld   c,b
5090: EC AA CD    call pe,$CDAA
5093: AA          xor  d
5094: B2          or   d
5095: 48          ld   c,b
5096: 93          sub  e
5097: 48          ld   c,b
5098: 7C          ld   a,h
5099: AA          xor  d
509A: 5D          ld   e,l
509B: AA          xor  d
509C: 93          sub  e
509D: 48          ld   c,b
509E: 92          sub  d
509F: 48          ld   c,b
50A0: 93          sub  e
50A1: 48          ld   c,b
50A2: B2          or   d
50A3: 48          ld   c,b
50A4: 4C          ld   c,h
50A5: AA          xor  d
50A6: 2D          dec  l
50A7: AA          xor  d
50A8: 2C          inc  l
50A9: AA          xor  d
50AA: 00          nop
50AB: 00          nop
50AC: CC AA AD    call z,$CBAA
50AF: AA          xor  d
50B0: AC          xor  h
50B1: AA          xor  d
50B2: 00          nop
50B3: 00          nop
50B4: 5C          ld   e,h
50B5: AA          xor  d
50B6: 3D          dec  a
50B7: AA          xor  d
50B8: 3C          inc  a
50B9: AA          xor  d
50BA: 00          nop
50BB: 00          nop
50BC: 73          ld   (hl),e
50BD: 48          ld   c,b
50BE: B3          or   e
50BF: 48          ld   c,b
50C0: B2          or   d
50C1: 48          ld   c,b
50C2: 00          nop
50C3: 00          nop
50C4: 96          sub  (hl)
50C5: 01 97 03    ld   bc,$2179
50C8: 96          sub  (hl)
50C9: 03          inc  bc
50CA: 96          sub  (hl)
50CB: 03          inc  bc
50CC: 96          sub  (hl)
50CD: 01 26 01    ld   bc,$0162
50D0: 26 01       ld   h,$01
50D2: 6A          ld   l,d
50D3: 01 96 01    ld   bc,$0178
50D6: 26 01       ld   h,$01
50D8: 26 01       ld   h,$01
50DA: 26 01       ld   h,$01
50DC: 96          sub  (hl)
50DD: 01 26 01    ld   bc,$0162
50E0: 26 01       ld   h,$01
50E2: F7          rst  $30
50E3: 01 00 00    ld   bc,$0000
50E6: 06 01       ld   b,$01
50E8: 07          rlca
50E9: 01 C6 01    ld   bc,$016C
50EC: 00          nop
50ED: 00          nop
50EE: 86          add  a,(hl)
50EF: 01 87 01    ld   bc,$0169
50F2: 56          ld   d,(hl)
50F3: 01 00 00    ld   bc,$0000
50F6: 16 01       ld   d,$01
50F8: 17          rla
50F9: 01 D6 01    ld   bc,$017C
50FC: 00          nop
50FD: 00          nop
50FE: 2A 01 2B    ld   hl,($A301)
5101: 01 6B 01    ld   bc,$01A7
5104: B3          or   e
5105: 48          ld   c,b
5106: B2          or   d
5107: 48          ld   c,b
5108: 29          add  hl,hl
5109: 03          inc  bc
510A: 00          nop
510B: 00          nop
510C: 96          sub  (hl)
510D: 01 96 03    ld   bc,$2178
5110: 26 01       ld   h,$01
5112: D8          ret  c
5113: 01 26 01    ld   bc,$0162
5116: 6A          ld   l,d
5117: 01 26 01    ld   bc,$0162
511A: 66          ld   h,(hl)
511B: 01 26 01    ld   bc,$0162
511E: 26 01       ld   h,$01
5120: 26 01       ld   h,$01
5122: E6 01       and  $01
5124: C6 03       add  a,$21
5126: 07          rlca
5127: 03          inc  bc
5128: 06 03       ld   b,$21
512A: 00          nop
512B: 00          nop
512C: 56          ld   d,(hl)
512D: 03          inc  bc
512E: 87          add  a,a
512F: 03          inc  bc
5130: 86          add  a,(hl)
5131: 03          inc  bc
5132: 00          nop
5133: 00          nop
5134: D6 03       sub  $21
5136: 17          rla
5137: 03          inc  bc
5138: 16 03       ld   d,$21
513A: 00          nop
513B: 00          nop
513C: 6B          ld   l,e
513D: 03          inc  bc
513E: 2B          dec  hl
513F: 03          inc  bc
5140: 2A 03 00    ld   hl,($0021)
5143: 00          nop
5144: 73          ld   (hl),e
5145: 48          ld   c,b
5146: B3          or   e
5147: 48          ld   c,b
5148: B2          or   d
5149: 48          ld   c,b
514A: 21 84 B3    ld   hl,$3B48
514D: 48          ld   c,b
514E: 01 84 20    ld   bc,$0248
5151: 84          add  a,h
5152: A1          and  c
5153: 84          add  a,h
5154: 00          nop
5155: 84          add  a,h
5156: 81          add  a,c
5157: 84          add  a,h
5158: 98          sbc  a,b
5159: 88          adc  a,b
515A: 99          sbc  a,c
515B: 88          adc  a,b
515C: 80          add  a,b
515D: 84          add  a,h
515E: 98          sbc  a,b
515F: 88          adc  a,b
5160: 99          sbc  a,c
5161: 88          adc  a,b
5162: 98          sbc  a,b
5163: 88          adc  a,b
5164: 40          ld   b,b
5165: 84          add  a,h
5166: 41          ld   b,c
5167: 84          add  a,h
5168: 60          ld   h,b
5169: 84          add  a,h
516A: 24          inc  h
516B: A5          and  l
516C: C0          ret  nz
516D: 84          add  a,h
516E: 98          sbc  a,b
516F: 88          adc  a,b
5170: 99          sbc  a,c
5171: 88          adc  a,b
5172: A4          and  h
5173: A5          and  l
5174: 98          sbc  a,b
5175: 88          adc  a,b
5176: 99          sbc  a,c
5177: 88          adc  a,b
5178: 98          sbc  a,b
5179: 88          adc  a,b
517A: 99          sbc  a,c
517B: 88          adc  a,b
517C: 99          sbc  a,c
517D: 88          adc  a,b
517E: 98          sbc  a,b
517F: 88          adc  a,b
5180: 99          sbc  a,c
5181: 88          adc  a,b
5182: 98          sbc  a,b
5183: 88          adc  a,b
5184: 10 84       djnz $51CE
5186: 99          sbc  a,c
5187: 88          adc  a,b
5188: 98          sbc  a,b
5189: 88          adc  a,b
518A: 99          sbc  a,c
518B: 88          adc  a,b
518C: 90          sub  b
518D: 84          add  a,h
518E: 91          sub  c
518F: 84          add  a,h
5190: 99          sbc  a,c
5191: 88          adc  a,b
5192: 98          sbc  a,b
5193: 88          adc  a,b
5194: B2          or   d
5195: 48          ld   c,b
5196: 93          sub  e
5197: 48          ld   c,b
5198: B0          or   b
5199: 84          add  a,h
519A: 99          sbc  a,c
519B: 88          adc  a,b
519C: 93          sub  e
519D: 48          ld   c,b
519E: 92          sub  d
519F: 48          ld   c,b
51A0: B1          or   c
51A1: 84          add  a,h
51A2: D0          ret  nc
51A3: 84          add  a,h
51A4: 98          sbc  a,b
51A5: 88          adc  a,b
51A6: 99          sbc  a,c
51A7: 88          adc  a,b
51A8: 98          sbc  a,b
51A9: 88          adc  a,b
51AA: 99          sbc  a,c
51AB: 88          adc  a,b
51AC: 99          sbc  a,c
51AD: 88          adc  a,b
51AE: 98          sbc  a,b
51AF: 88          adc  a,b
51B0: 99          sbc  a,c
51B1: 88          adc  a,b
51B2: 99          sbc  a,c
51B3: 88          adc  a,b
51B4: 98          sbc  a,b
51B5: 88          adc  a,b
51B6: 99          sbc  a,c
51B7: 88          adc  a,b
51B8: 98          sbc  a,b
51B9: 88          adc  a,b
51BA: 99          sbc  a,c
51BB: 88          adc  a,b
51BC: D1          pop  de
51BD: 84          add  a,h
51BE: F0          ret  p
51BF: 84          add  a,h
51C0: F1          pop  af
51C1: 84          add  a,h
51C2: 99          sbc  a,c
51C3: 88          adc  a,b
51C4: 76          halt
51C5: 6C          ld   l,h
51C6: 57          ld   d,a
51C7: 6C          ld   l,h
51C8: E5          push hl
51C9: 6C          ld   l,h
51CA: C5          push bc
51CB: 6C          ld   l,h
51CC: F6 AC       or   $CA
51CE: D7          rst  $10
51CF: AE          xor  (hl)
51D0: 75          ld   (hl),l
51D1: 6C          ld   l,h
51D2: 55          ld   d,l
51D3: 6C          ld   l,h
51D4: F7          rst  $30
51D5: EC 77 EE    call pe,$EE77
51D8: F5          push af
51D9: 6C          ld   l,h
51DA: D5          push de
51DB: 6C          ld   l,h
51DC: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
51DD: EC 67 EE    call pe,$EE67
51E0: 86          add  a,(hl)
51E1: 6C          ld   l,h
51E2: 94          sub  h
51E3: 6C          ld   l,h
51E4: C5          push bc
51E5: 6C          ld   l,h
51E6: E4 6C E5    call po,$4FC6
51E9: 6C          ld   l,h
51EA: 57          ld   d,a
51EB: 6C          ld   l,h
51EC: 55          ld   d,l
51ED: 6C          ld   l,h
51EE: 74          ld   (hl),h
51EF: 6C          ld   l,h
51F0: 75          ld   (hl),l
51F1: 6C          ld   l,h
51F2: D7          rst  $10
51F3: AC          xor  h
51F4: D5          push de
51F5: 6C          ld   l,h
51F6: F4 6C F5    call p,$5FC6
51F9: 6C          ld   l,h
51FA: 77          ld   (hl),a
51FB: EC 94 6C    call pe,$C658
51FE: 95          sub  l
51FF: 6C          ld   l,h
5200: B4          or   h
5201: 6C          ld   l,h
5202: 67          ld   h,a
5203: EC E5 6C    call pe,$C64F
5206: 57          ld   d,a
5207: 6C          ld   l,h
5208: 76          halt
5209: 6C          ld   l,h
520A: 57          ld   d,a
520B: 6C          ld   l,h
520C: 75          ld   (hl),l
520D: 6C          ld   l,h
520E: D7          rst  $10
520F: AC          xor  h
5210: F6 AC       or   $CA
5212: D7          rst  $10
5213: AE          xor  (hl)
5214: F5          push af
5215: 6C          ld   l,h
5216: 77          ld   (hl),a
5217: EC F7 EC    call pe,$CE7F
521A: 77          ld   (hl),a
521B: EE B4       xor  $5A
521D: 6C          ld   l,h
521E: 67          ld   h,a
521F: EC E7 EC    call pe,$CE6F
5222: 67          ld   h,a
5223: EE C5       xor  $4D
5225: 6C          ld   l,h
5226: E4 6C E5    call po,$4FC6
5229: 6C          ld   l,h
522A: C5          push bc
522B: 6C          ld   l,h
522C: 55          ld   d,l
522D: 6C          ld   l,h
522E: 74          ld   (hl),h
522F: 6C          ld   l,h
5230: 75          ld   (hl),l
5231: 6C          ld   l,h
5232: 55          ld   d,l
5233: 6C          ld   l,h
5234: D5          push de
5235: 6C          ld   l,h
5236: F4 6C F5    call p,$5FC6
5239: 6C          ld   l,h
523A: D5          push de
523B: 6C          ld   l,h
523C: 94          sub  h
523D: 6C          ld   l,h
523E: 95          sub  l
523F: 6C          ld   l,h
5240: B4          or   h
5241: 6C          ld   l,h
5242: 94          sub  h
5243: 6C          ld   l,h
5244: D4 A9 F4    call nc,$5E8B
5247: A9          xor  c
5248: D5          push de
5249: A9          xor  c
524A: F5          push af
524B: A9          xor  c
524C: F4 A9 D5    call p,$5D8B
524F: A9          xor  c
5250: F4 A9 D5    call p,$5D8B
5253: A9          xor  c
5254: D5          push de
5255: A9          xor  c
5256: D4 A9 D5    call nc,$5D8B
5259: A9          xor  c
525A: F4 A9 D4    call p,$5C8B
525D: A9          xor  c
525E: DD          db   $dd
525F: C0          ret  nz
5260: FC C0 FD    call m,$DF0C
5263: C0          ret  nz
5264: F4 A9 D5    call p,$5D8B
5267: A9          xor  c
5268: D5          push de
5269: A9          xor  c
526A: D5          push de
526B: A9          xor  c
526C: F4 A9 D5    call p,$5D8B
526F: A9          xor  c
5270: D4 A9 D5    call nc,$5D8B
5273: A9          xor  c
5274: F5          push af
5275: A9          xor  c
5276: F4 A9 D5    call p,$5D8B
5279: A9          xor  c
527A: F4 A9 FD    call p,$DF8B
527D: C2 FC C2    jp   nz,$2CDE
5280: DD          db   $dd
5281: C2 FD C0    jp   nz,$0CDF
5284: 00          nop
5285: 00          nop
5286: 24          inc  h
5287: 68          ld   l,b
5288: 05          dec  b
5289: 68          ld   l,b
528A: 24          inc  h
528B: 68          ld   l,b
528C: 00          nop
528D: 00          nop
528E: 92          sub  d
528F: E4 93 E4    call po,$4E39
5292: 23          inc  hl
5293: E4 00 00    call po,$0000
5296: B2          or   d
5297: E4 B3 E4    call po,$4E3B
529A: A3          and  e
529B: E4 00 00    call po,$0000
529E: D2 E4 D3    jp   nc,$3D4E
52A1: E4 33 E4    call po,$4E33
52A4: 24          inc  h
52A5: 68          ld   l,b
52A6: 25          dec  h
52A7: 68          ld   l,b
52A8: 05          dec  b
52A9: 68          ld   l,b
52AA: 24          inc  h
52AB: 68          ld   l,b
52AC: 42          ld   b,d
52AD: E4 11 E4    call po,$4E11
52B0: 30 E4       jr   nc,$5300
52B2: 43          ld   b,e
52B3: E4 C2 E4    call po,$4E2C
52B6: 51          ld   d,c
52B7: E4 70 E4    call po,$4E16
52BA: C3 E4 52    jp   $344E
52BD: E4 C1 E4    call po,$4E0D
52C0: E0          ret  po
52C1: E4 53 E4    call po,$4E35
52C4: 04          inc  b
52C5: 68          ld   l,b
52C6: 05          dec  b
52C7: 68          ld   l,b
52C8: 24          inc  h
52C9: 68          ld   l,b
52CA: 00          nop
52CB: 00          nop
52CC: 02          ld   (bc),a
52CD: E4 03 E4    call po,$4E21
52D0: 22 E4 00    ld   ($004E),hl
52D3: 00          nop
52D4: 82          add  a,d
52D5: E4 83 E4    call po,$4E29
52D8: A2          and  d
52D9: E4 00 00    call po,$0000
52DC: 12          ld   (de),a
52DD: E4 13 E4    call po,$4E31
52E0: 32 E4 00    ld   ($004E),a
52E3: 00          nop
52E4: 04          inc  b
52E5: 68          ld   l,b
52E6: 05          dec  b
52E7: 68          ld   l,b
52E8: 24          inc  h
52E9: 68          ld   l,b
52EA: 25          dec  h
52EB: 68          ld   l,b
52EC: A0          and  b
52ED: E4 11 E4    call po,$4E11
52F0: 30 E4       jr   nc,$5340
52F2: 62          ld   h,d
52F3: E4 50 E4    call po,$4E14
52F6: 51          ld   d,c
52F7: E4 70 E4    call po,$4E16
52FA: E2 E4 61    jp   po,$074E
52FD: E4 C1 E4    call po,$4E0D
5300: E0          ret  po
5301: E4 72 E4    call po,$4E36
5304: 24          inc  h
5305: 68          ld   l,b
5306: 24          inc  h
5307: 68          ld   l,b
5308: 05          dec  b
5309: 68          ld   l,b
530A: 04          inc  b
530B: 68          ld   l,b
530C: 63          ld   h,e
530D: E4 11 E4    call po,$4E11
5310: 30 E4       jr   nc,$5360
5312: 31 E4 E3    ld   sp,$2F4E
5315: E4 51 E4    call po,$4E15
5318: 70          ld   (hl),b
5319: E4 71 E4    call po,$4E17
531C: 73          ld   (hl),e
531D: E4 C1 E4    call po,$4E0D
5320: E0          ret  po
5321: E4 E1 E4    call po,$4E0F
5324: B3          or   e
5325: 48          ld   c,b
5326: B2          or   d
5327: 48          ld   c,b
5328: 93          sub  e
5329: 48          ld   c,b
532A: B2          or   d
532B: 48          ld   c,b
532C: C9          ret
532D: AE          xor  (hl)
532E: 93          sub  e
532F: 48          ld   c,b
5330: 92          sub  d
5331: 48          ld   c,b
5332: 93          sub  e
5333: 48          ld   c,b
5334: 59          ld   e,c
5335: AE          xor  (hl)
5336: 73          ld   (hl),e
5337: 48          ld   c,b
5338: B3          or   e
5339: 48          ld   c,b
533A: B2          or   d
533B: 48          ld   c,b
533C: D9          exx
533D: AE          xor  (hl)
533E: B3          or   e
533F: 48          ld   c,b
5340: B2          or   d
5341: 48          ld   c,b
5342: 93          sub  e
5343: 48          ld   c,b
5344: 2B          dec  hl
5345: AE          xor  (hl)
5346: D6 AE       sub  $EA
5348: B3          or   e
5349: 48          ld   c,b
534A: B2          or   d
534B: 48          ld   c,b
534C: AB          xor  e
534D: AE          xor  (hl)
534E: B6          or   (hl)
534F: AE          xor  (hl)
5350: B2          or   d
5351: 48          ld   c,b
5352: 93          sub  e
5353: 48          ld   c,b
5354: 3B          dec  sp
5355: AE          xor  (hl)
5356: B7          or   a
5357: AE          xor  (hl)
5358: 93          sub  e
5359: 48          ld   c,b
535A: B2          or   d
535B: 48          ld   c,b
535C: BB          cp   e
535D: AE          xor  (hl)
535E: 93          sub  e
535F: 48          ld   c,b
5360: 92          sub  d
5361: 48          ld   c,b
5362: 93          sub  e
5363: 48          ld   c,b
5364: 73          ld   (hl),e
5365: 48          ld   c,b
5366: B3          or   e
5367: 48          ld   c,b
5368: B2          or   d
5369: 48          ld   c,b
536A: B3          or   e
536B: 48          ld   c,b
536C: 96          sub  (hl)
536D: 01 97 01    ld   bc,$0179
5370: 29          add  hl,hl
5371: 01 B2 48    ld   bc,$843A
5374: 26 01       ld   h,$01
5376: 27          daa
5377: 01 46 01    ld   bc,$0164
537A: 47          ld   b,a
537B: 01 A6 01    ld   bc,$016A
537E: A7          and  a
537F: 01 C6 01    ld   bc,$016C
5382: C7          rst  $00
5383: 01 05 68    ld   bc,$8641
5386: 04          inc  b
5387: 68          ld   l,b
5388: 05          dec  b
5389: 68          ld   l,b
538A: 24          inc  h
538B: 68          ld   l,b
538C: 04          inc  b
538D: 68          ld   l,b
538E: 05          dec  b
538F: 68          ld   l,b
5390: 04          inc  b
5391: 68          ld   l,b
5392: 05          dec  b
5393: 68          ld   l,b
5394: 24          inc  h
5395: 68          ld   l,b
5396: 24          inc  h
5397: 68          ld   l,b
5398: 05          dec  b
5399: 68          ld   l,b
539A: 24          inc  h
539B: 68          ld   l,b
539C: 43          ld   b,e
539D: E6 30       and  $12
539F: E6 11       and  $11
53A1: E6 42       and  $24
53A3: E6 05       and  $41
53A5: 68          ld   l,b
53A6: 24          inc  h
53A7: 68          ld   l,b
53A8: 24          inc  h
53A9: 68          ld   l,b
53AA: 25          dec  h
53AB: 68          ld   l,b
53AC: 05          dec  b
53AD: 68          ld   l,b
53AE: 24          inc  h
53AF: 68          ld   l,b
53B0: 25          dec  h
53B1: 68          ld   l,b
53B2: 44          ld   b,h
53B3: 68          ld   l,b
53B4: 24          inc  h
53B5: 68          ld   l,b
53B6: 25          dec  h
53B7: 68          ld   l,b
53B8: 44          ld   b,h
53B9: 68          ld   l,b
53BA: 44          ld   b,h
53BB: 68          ld   l,b
53BC: 23          inc  hl
53BD: E6 93       and  $39
53BF: E6 92       and  $38
53C1: E6 00       and  $00
53C3: 00          nop
53C4: 00          nop
53C5: 00          nop
53C6: 25          dec  h
53C7: 68          ld   l,b
53C8: 24          inc  h
53C9: 68          ld   l,b
53CA: 04          inc  b
53CB: 68          ld   l,b
53CC: 00          nop
53CD: 00          nop
53CE: 24          inc  h
53CF: 68          ld   l,b
53D0: 24          inc  h
53D1: 68          ld   l,b
53D2: 05          dec  b
53D3: 68          ld   l,b
53D4: 00          nop
53D5: 00          nop
53D6: 05          dec  b
53D7: 68          ld   l,b
53D8: 05          dec  b
53D9: 68          ld   l,b
53DA: 24          inc  h
53DB: 68          ld   l,b
53DC: 00          nop
53DD: 00          nop
53DE: 22 E6 03    ld   ($216E),hl
53E1: E6 02       and  $20
53E3: E6 25       and  $43
53E5: 68          ld   l,b
53E6: 24          inc  h
53E7: 68          ld   l,b
53E8: 05          dec  b
53E9: 68          ld   l,b
53EA: 00          nop
53EB: 00          nop
53EC: 24          inc  h
53ED: 68          ld   l,b
53EE: 24          inc  h
53EF: 68          ld   l,b
53F0: 05          dec  b
53F1: 68          ld   l,b
53F2: 00          nop
53F3: 00          nop
53F4: 04          inc  b
53F5: 68          ld   l,b
53F6: 05          dec  b
53F7: 68          ld   l,b
53F8: 24          inc  h
53F9: 68          ld   l,b
53FA: 00          nop
53FB: 00          nop
53FC: 02          ld   (bc),a
53FD: E4 03 E4    call po,$4E21
5400: 22 E4 00    ld   ($004E),hl
5403: 00          nop
5404: 04          inc  b
5405: 68          ld   l,b
5406: 05          dec  b
5407: 68          ld   l,b
5408: 24          inc  h
5409: 68          ld   l,b
540A: 05          dec  b
540B: 68          ld   l,b
540C: 05          dec  b
540D: 68          ld   l,b
540E: 24          inc  h
540F: 68          ld   l,b
5410: 02          ld   (bc),a
5411: E4 03 E4    call po,$4E21
5414: 24          inc  h
5415: 68          ld   l,b
5416: 25          dec  h
5417: 68          ld   l,b
5418: 82          add  a,d
5419: E4 83 E4    call po,$4E29
541C: 05          dec  b
541D: 68          ld   l,b
541E: 24          inc  h
541F: 68          ld   l,b
5420: 12          ld   (de),a
5421: E4 13 E4    call po,$4E31
5424: F7          rst  $30
5425: A8          xor  b
5426: 65          ld   h,l
5427: A8          xor  b
5428: 45          ld   b,l
5429: A8          xor  b
542A: 00          nop
542B: 00          nop
542C: B3          or   e
542D: 48          ld   c,b
542E: B2          or   d
542F: 48          ld   c,b
5430: 64          ld   h,h
5431: A8          xor  b
5432: 00          nop
5433: 00          nop
5434: B2          or   d
5435: 48          ld   c,b
5436: 93          sub  e
5437: 48          ld   c,b
5438: B3          or   e
5439: 48          ld   c,b
543A: 00          nop
543B: 00          nop
543C: 93          sub  e
543D: A8          xor  b
543E: 6A          ld   l,d
543F: AE          xor  (hl)
5440: 58          ld   e,b
5441: AE          xor  (hl)
5442: 00          nop
5443: 00          nop
5444: B2          or   d
5445: 48          ld   c,b
5446: 93          sub  e
5447: 48          ld   c,b
5448: 92          sub  d
5449: 48          ld   c,b
544A: 7A          ld   a,d
544B: AE          xor  (hl)
544C: B3          or   e
544D: 48          ld   c,b
544E: B2          or   d
544F: 48          ld   c,b
5450: 93          sub  e
5451: 48          ld   c,b
5452: FA AE B2    jp   m,$3AEA
5455: 48          ld   c,b
5456: 93          sub  e
5457: 48          ld   c,b
5458: 92          sub  d
5459: 48          ld   c,b
545A: 6B          ld   l,e
545B: AE          xor  (hl)
545C: B3          or   e
545D: 48          ld   c,b
545E: B2          or   d
545F: 48          ld   c,b
5460: 93          sub  e
5461: 48          ld   c,b
5462: 92          sub  d
5463: 48          ld   c,b
5464: EA AE 09    jp   pe,$81EA
5467: AE          xor  (hl)
5468: 08          ex   af,af'
5469: AE          xor  (hl)
546A: 00          nop
546B: 00          nop
546C: A8          xor  b
546D: AE          xor  (hl)
546E: 89          adc  a,c
546F: AE          xor  (hl)
5470: 88          adc  a,b
5471: AE          xor  (hl)
5472: 00          nop
5473: 00          nop
5474: 38 AE       jr   c,$5460
5476: 19          add  hl,de
5477: AE          xor  (hl)
5478: 18 AE       jr   $5464
547A: 00          nop
547B: 00          nop
547C: EB          ex   de,hl
547D: AE          xor  (hl)
547E: 7B          ld   a,e
547F: AE          xor  (hl)
5480: FB          ei
5481: AE          xor  (hl)
5482: 00          nop
5483: 00          nop
5484: 57          ld   d,a
5485: 6C          ld   l,h
5486: 76          halt
5487: 6C          ld   l,h
5488: 57          ld   d,a
5489: 6C          ld   l,h
548A: E5          push hl
548B: 6C          ld   l,h
548C: D7          rst  $10
548D: AC          xor  h
548E: F6 AC       or   $CA
5490: D7          rst  $10
5491: AE          xor  (hl)
5492: 75          ld   (hl),l
5493: 6C          ld   l,h
5494: 77          ld   (hl),a
5495: EC F7 EC    call pe,$CE7F
5498: 77          ld   (hl),a
5499: EE F5       xor  $5F
549B: 6C          ld   l,h
549C: 67          ld   h,a
549D: EC E7 EC    call pe,$CE6F
54A0: 67          ld   h,a
54A1: EE 86       xor  $68
54A3: 6C          ld   l,h
54A4: 36 01       ld   (hl),$01
54A6: 37          scf
54A7: 01 56 01    ld   bc,$0174
54AA: 57          ld   d,a
54AB: 01 B6 01    ld   bc,$017A
54AE: B7          or   a
54AF: 01 D6 01    ld   bc,$017C
54B2: D7          rst  $10
54B3: 01 2A 01    ld   bc,$01A2
54B6: 2B          dec  hl
54B7: 01 4A 01    ld   bc,$01A4
54BA: 4B          ld   c,e
54BB: 01 B2 48    ld   bc,$843A
54BE: 93          sub  e
54BF: 48          ld   c,b
54C0: B2          or   d
54C1: 48          ld   c,b
54C2: B3          or   e
54C3: 48          ld   c,b
54C4: C3 E6 70    jp   $166E
54C7: E6 51       and  $15
54C9: E6 C2       and  $2C
54CB: E6 53       and  $35
54CD: E6 E0       and  $0E
54CF: E6 C1       and  $0D
54D1: E6 52       and  $34
54D3: E6 04       and  $40
54D5: 68          ld   l,b
54D6: 05          dec  b
54D7: 68          ld   l,b
54D8: 24          inc  h
54D9: 68          ld   l,b
54DA: 25          dec  h
54DB: 68          ld   l,b
54DC: 05          dec  b
54DD: 68          ld   l,b
54DE: 24          inc  h
54DF: 68          ld   l,b
54E0: 25          dec  h
54E1: 68          ld   l,b
54E2: 24          inc  h
54E3: 68          ld   l,b
54E4: A3          and  e
54E5: E6 B3       and  $3B
54E7: E6 B2       and  $3A
54E9: E6 00       and  $00
54EB: 00          nop
54EC: 33          inc  sp
54ED: E6 D3       and  $3D
54EF: E6 D2       and  $3C
54F1: E6 00       and  $00
54F3: 00          nop
54F4: 24          inc  h
54F5: 68          ld   l,b
54F6: 44          ld   b,h
54F7: 68          ld   l,b
54F8: 24          inc  h
54F9: 68          ld   l,b
54FA: 00          nop
54FB: 00          nop
54FC: 05          dec  b
54FD: 68          ld   l,b
54FE: 24          inc  h
54FF: 68          ld   l,b
5500: 05          dec  b
5501: 68          ld   l,b
5502: 00          nop
5503: 00          nop
5504: 00          nop
5505: 00          nop
5506: A2          and  d
5507: E6 83       and  $29
5509: E6 82       and  $28
550B: E6 00       and  $00
550D: 00          nop
550E: 32 E6 13    ld   ($316E),a
5511: E6 12       and  $30
5513: E6 00       and  $00
5515: 00          nop
5516: 44          ld   b,h
5517: 68          ld   l,b
5518: 25          dec  h
5519: 68          ld   l,b
551A: 24          inc  h
551B: 68          ld   l,b
551C: 00          nop
551D: 00          nop
551E: 24          inc  h
551F: 68          ld   l,b
5520: 04          inc  b
5521: 68          ld   l,b
5522: 05          dec  b
5523: 68          ld   l,b
5524: 82          add  a,d
5525: E4 83 E4    call po,$4E29
5528: A2          and  d
5529: E4 00 00    call po,$0000
552C: 12          ld   (de),a
552D: E4 13 E4    call po,$4E31
5530: 32 E4 00    ld   ($004E),a
5533: 00          nop
5534: 05          dec  b
5535: 68          ld   l,b
5536: 24          inc  h
5537: 68          ld   l,b
5538: 25          dec  h
5539: 68          ld   l,b
553A: 44          ld   b,h
553B: 68          ld   l,b
553C: 05          dec  b
553D: 68          ld   l,b
553E: 24          inc  h
553F: 68          ld   l,b
5540: 05          dec  b
5541: 68          ld   l,b
5542: 25          dec  h
5543: 68          ld   l,b
5544: 24          inc  h
5545: 68          ld   l,b
5546: 24          inc  h
5547: 68          ld   l,b
5548: 25          dec  h
5549: 68          ld   l,b
554A: 05          dec  b
554B: 68          ld   l,b
554C: 22 E4 31    ld   ($134E),hl
554F: E4 24 68    call po,$8642
5552: 04          inc  b
5553: 68          ld   l,b
5554: A2          and  d
5555: E4 71 E4    call po,$4E17
5558: 24          inc  h
5559: 68          ld   l,b
555A: 05          dec  b
555B: 68          ld   l,b
555C: 32 E4 E1    ld   ($0F4E),a
555F: E4 05 68    call po,$8641
5562: 24          inc  h
5563: 68          ld   l,b
5564: 00          nop
5565: 00          nop
5566: 04          inc  b
5567: 68          ld   l,b
5568: 05          dec  b
5569: 68          ld   l,b
556A: 24          inc  h
556B: 68          ld   l,b
556C: 00          nop
556D: 00          nop
556E: 92          sub  d
556F: E4 93 E4    call po,$4E39
5572: 23          inc  hl
5573: E4 00 00    call po,$0000
5576: B2          or   d
5577: E4 B3 E4    call po,$4E3B
557A: A3          and  e
557B: E4 00 00    call po,$0000
557E: D2 E4 D3    jp   nc,$3D4E
5581: E4 33 E4    call po,$4E33
5584: 05          dec  b
5585: 68          ld   l,b
5586: 04          inc  b
5587: 68          ld   l,b
5588: 05          dec  b
5589: 68          ld   l,b
558A: 24          inc  h
558B: 68          ld   l,b
558C: 42          ld   b,d
558D: E4 11 E4    call po,$4E11
5590: 30 E4       jr   nc,$55E0
5592: 62          ld   h,d
5593: E4 C2 E4    call po,$4E2C
5596: 51          ld   d,c
5597: E4 70 E4    call po,$4E16
559A: E2 E4 52    jp   po,$344E
559D: E4 C1 E4    call po,$4E0D
55A0: E0          ret  po
55A1: E4 72 E4    call po,$4E36
55A4: 05          dec  b
55A5: 68          ld   l,b
55A6: 04          inc  b
55A7: 68          ld   l,b
55A8: 05          dec  b
55A9: 68          ld   l,b
55AA: 24          inc  h
55AB: 68          ld   l,b
55AC: 63          ld   h,e
55AD: E4 11 E4    call po,$4E11
55B0: 30 E4       jr   nc,$5600
55B2: 31 E4 E3    ld   sp,$2F4E
55B5: E4 51 E4    call po,$4E15
55B8: 70          ld   (hl),b
55B9: E4 71 E4    call po,$4E17
55BC: 73          ld   (hl),e
55BD: E4 C1 E4    call po,$4E0D
55C0: E0          ret  po
55C1: E4 E1 E4    call po,$4E0F
55C4: 04          inc  b
55C5: 68          ld   l,b
55C6: 05          dec  b
55C7: 68          ld   l,b
55C8: 24          inc  h
55C9: 68          ld   l,b
55CA: 24          inc  h
55CB: 68          ld   l,b
55CC: 25          dec  h
55CD: 68          ld   l,b
55CE: 24          inc  h
55CF: 68          ld   l,b
55D0: A0          and  b
55D1: E4 11 E4    call po,$4E11
55D4: 44          ld   b,h
55D5: 68          ld   l,b
55D6: 25          dec  h
55D7: 68          ld   l,b
55D8: 50          ld   d,b
55D9: E4 51 E4    call po,$4E15
55DC: 24          inc  h
55DD: 68          ld   l,b
55DE: 05          dec  b
55DF: 68          ld   l,b
55E0: 61          ld   h,c
55E1: E4 C1 E4    call po,$4E0D
55E4: 25          dec  h
55E5: 68          ld   l,b
55E6: 24          inc  h
55E7: 68          ld   l,b
55E8: 24          inc  h
55E9: 68          ld   l,b
55EA: 05          dec  b
55EB: 68          ld   l,b
55EC: 30 E4       jr   nc,$563C
55EE: 31 E4 05    ld   sp,$414E
55F1: 68          ld   l,b
55F2: 04          inc  b
55F3: 68          ld   l,b
55F4: 70          ld   (hl),b
55F5: E4 71 E4    call po,$4E17
55F8: 24          inc  h
55F9: 68          ld   l,b
55FA: 05          dec  b
55FB: 68          ld   l,b
55FC: E0          ret  po
55FD: E4 E1 E4    call po,$4E0F
5600: 04          inc  b
5601: 68          ld   l,b
5602: 04          inc  b
5603: 68          ld   l,b
5604: D5          push de
5605: A9          xor  c
5606: F4 A9 F5    call p,$5F8B
5609: A9          xor  c
560A: F4 A9 D4    call p,$5C8B
560D: A9          xor  c
560E: D5          push de
560F: A9          xor  c
5610: F4 A9 F5    call p,$5F8B
5613: A9          xor  c
5614: F5          push af
5615: A9          xor  c
5616: F4 A9 F5    call p,$5F8B
5619: A9          xor  c
561A: F4 A9 03    call p,$218B
561D: AF          xor  a
561E: 83          add  a,e
561F: AF          xor  a
5620: 83          add  a,e
5621: AF          xor  a
5622: 83          add  a,e
5623: AF          xor  a
5624: F5          push af
5625: A9          xor  c
5626: F4 A9 D5    call p,$5D8B
5629: A9          xor  c
562A: D4 A9 F4    call nc,$5E8B
562D: A9          xor  c
562E: F5          push af
562F: A9          xor  c
5630: F4 A9 D5    call p,$5D8B
5633: A9          xor  c
5634: D5          push de
5635: A9          xor  c
5636: D4 A9 D5    call nc,$5D8B
5639: A9          xor  c
563A: F4 A9 D4    call p,$5C8B
563D: A9          xor  c
563E: F4 A9 03    call p,$218B
5641: AF          xor  a
5642: 03          inc  bc
5643: AF          xor  a
5644: D5          push de
5645: A9          xor  c
5646: F4 A9 F5    call p,$5F8B
5649: A9          xor  c
564A: F4 A9 D4    call p,$5C8B
564D: A9          xor  c
564E: D5          push de
564F: A9          xor  c
5650: F4 A9 F5    call p,$5F8B
5653: A9          xor  c
5654: D5          push de
5655: A9          xor  c
5656: F4 A9 F5    call p,$5F8B
5659: A9          xor  c
565A: F4 A9 03    call p,$218B
565D: AD          xor  l
565E: 03          inc  bc
565F: AD          xor  l
5660: F4 A9 F5    call p,$5F8B
5663: A9          xor  c
5664: F5          push af
5665: A9          xor  c
5666: F4 A9 D5    call p,$5D8B
5669: A9          xor  c
566A: D4 A9 F4    call nc,$5E8B
566D: A9          xor  c
566E: F5          push af
566F: A9          xor  c
5670: F4 A9 D5    call p,$5D8B
5673: A9          xor  c
5674: D5          push de
5675: A9          xor  c
5676: D4 A9 D5    call nc,$5D8B
5679: A9          xor  c
567A: D4 A9 83    call nc,$298B
567D: AD          xor  l
567E: 83          add  a,e
567F: AD          xor  l
5680: 83          add  a,e
5681: AD          xor  l
5682: 03          inc  bc
5683: AD          xor  l
5684: 92          sub  d
5685: 48          ld   c,b
5686: B3          or   e
5687: 48          ld   c,b
5688: B2          or   d
5689: 48          ld   c,b
568A: 93          sub  e
568B: 48          ld   c,b
568C: 93          sub  e
568D: 48          ld   c,b
568E: B3          or   e
568F: 48          ld   c,b
5690: B2          or   d
5691: 48          ld   c,b
5692: 93          sub  e
5693: 48          ld   c,b
5694: 92          sub  d
5695: 48          ld   c,b
5696: B3          or   e
5697: 48          ld   c,b
5698: B2          or   d
5699: 48          ld   c,b
569A: 93          sub  e
569B: 48          ld   c,b
569C: 01 6E 81    ld   bc,$09E6
569F: 6E          ld   l,(hl)
56A0: 81          add  a,c
56A1: 6E          ld   l,(hl)
56A2: 81          add  a,c
56A3: 6E          ld   l,(hl)
56A4: 73          ld   (hl),e
56A5: 48          ld   c,b
56A6: B3          or   e
56A7: 48          ld   c,b
56A8: B2          or   d
56A9: 48          ld   c,b
56AA: 93          sub  e
56AB: 48          ld   c,b
56AC: B3          or   e
56AD: 48          ld   c,b
56AE: B2          or   d
56AF: 48          ld   c,b
56B0: 93          sub  e
56B1: 48          ld   c,b
56B2: 92          sub  d
56B3: 48          ld   c,b
56B4: 73          ld   (hl),e
56B5: 48          ld   c,b
56B6: B3          or   e
56B7: 48          ld   c,b
56B8: B2          or   d
56B9: 48          ld   c,b
56BA: 93          sub  e
56BB: 48          ld   c,b
56BC: A0          and  b
56BD: 6C          ld   l,h
56BE: 20 6E       jr   nz,$56A6
56C0: 01 6E 01    ld   bc,$01E6
56C3: 6E          ld   l,(hl)
56C4: B2          or   d
56C5: 48          ld   c,b
56C6: B3          or   e
56C7: 48          ld   c,b
56C8: 73          ld   (hl),e
56C9: 48          ld   c,b
56CA: B3          or   e
56CB: 48          ld   c,b
56CC: 93          sub  e
56CD: 48          ld   c,b
56CE: B2          or   d
56CF: 48          ld   c,b
56D0: B3          or   e
56D1: 48          ld   c,b
56D2: 73          ld   (hl),e
56D3: 48          ld   c,b
56D4: B2          or   d
56D5: 48          ld   c,b
56D6: B3          or   e
56D7: 48          ld   c,b
56D8: 73          ld   (hl),e
56D9: 48          ld   c,b
56DA: B3          or   e
56DB: 48          ld   c,b
56DC: 01 6C 01    ld   bc,$01C6
56DF: 6C          ld   l,h
56E0: 20 6C       jr   nz,$56A8
56E2: A0          and  b
56E3: 6C          ld   l,h
56E4: 73          ld   (hl),e
56E5: 48          ld   c,b
56E6: B3          or   e
56E7: 48          ld   c,b
56E8: B2          or   d
56E9: 48          ld   c,b
56EA: 93          sub  e
56EB: 48          ld   c,b
56EC: B3          or   e
56ED: 48          ld   c,b
56EE: B2          or   d
56EF: 48          ld   c,b
56F0: 93          sub  e
56F1: 48          ld   c,b
56F2: 92          sub  d
56F3: 48          ld   c,b
56F4: B2          or   d
56F5: 48          ld   c,b
56F6: 93          sub  e
56F7: 48          ld   c,b
56F8: 92          sub  d
56F9: 48          ld   c,b
56FA: 93          sub  e
56FB: 48          ld   c,b
56FC: 81          add  a,c
56FD: 6C          ld   l,h
56FE: 81          add  a,c
56FF: 6C          ld   l,h
5700: 81          add  a,c
5701: 6C          ld   l,h
5702: 01 6C 04    ld   bc,$40C6
5705: 68          ld   l,b
5706: 05          dec  b
5707: 68          ld   l,b
5708: 24          inc  h
5709: 68          ld   l,b
570A: 25          dec  h
570B: 68          ld   l,b
570C: 05          dec  b
570D: 68          ld   l,b
570E: 24          inc  h
570F: 68          ld   l,b
5710: 25          dec  h
5711: 68          ld   l,b
5712: 44          ld   b,h
5713: 68          ld   l,b
5714: 24          inc  h
5715: 68          ld   l,b
5716: 25          dec  h
5717: 68          ld   l,b
5718: 25          dec  h
5719: 68          ld   l,b
571A: 25          dec  h
571B: 68          ld   l,b
571C: 71          ld   (hl),c
571D: 6E          ld   l,(hl)
571E: 70          ld   (hl),b
571F: 6E          ld   l,(hl)
5720: 01 6E 01    ld   bc,$01E6
5723: 6E          ld   l,(hl)
5724: 00          nop
5725: 00          nop
5726: B2          or   d
5727: 48          ld   c,b
5728: 93          sub  e
5729: 48          ld   c,b
572A: 92          sub  d
572B: 48          ld   c,b
572C: 00          nop
572D: 00          nop
572E: 93          sub  e
572F: 48          ld   c,b
5730: B2          or   d
5731: 48          ld   c,b
5732: 93          sub  e
5733: 48          ld   c,b
5734: 00          nop
5735: 00          nop
5736: 73          ld   (hl),e
5737: 48          ld   c,b
5738: B3          or   e
5739: 48          ld   c,b
573A: B2          or   d
573B: 48          ld   c,b
573C: 00          nop
573D: 00          nop
573E: 58          ld   e,b
573F: AC          xor  h
5740: 6A          ld   l,d
5741: AC          xor  h
5742: B3          or   e
5743: 48          ld   c,b
5744: 00          nop
5745: 00          nop
5746: 08          ex   af,af'
5747: AC          xor  h
5748: 09          add  hl,bc
5749: AC          xor  h
574A: EA AC 00    jp   pe,$00CA
574D: 00          nop
574E: 88          adc  a,b
574F: AC          xor  h
5750: 89          adc  a,c
5751: AC          xor  h
5752: A8          xor  b
5753: AC          xor  h
5754: 00          nop
5755: 00          nop
5756: 18 AC       jr   $5722
5758: 19          add  hl,de
5759: AC          xor  h
575A: 38 AC       jr   c,$5726
575C: 00          nop
575D: 00          nop
575E: FB          ei
575F: AC          xor  h
5760: 7B          ld   a,e
5761: AC          xor  h
5762: EB          ex   de,hl
5763: AC          xor  h
5764: 7A          ld   a,d
5765: AC          xor  h
5766: 92          sub  d
5767: 48          ld   c,b
5768: 93          sub  e
5769: 48          ld   c,b
576A: B2          or   d
576B: 48          ld   c,b
576C: FA AC 93    jp   m,$39CA
576F: 48          ld   c,b
5770: B2          or   d
5771: 48          ld   c,b
5772: B3          or   e
5773: 48          ld   c,b
5774: 6B          ld   l,e
5775: AC          xor  h
5776: B2          or   d
5777: 48          ld   c,b
5778: B3          or   e
5779: 48          ld   c,b
577A: 73          ld   (hl),e
577B: 48          ld   c,b
577C: B2          or   d
577D: 48          ld   c,b
577E: B3          or   e
577F: 48          ld   c,b
5780: B2          or   d
5781: 48          ld   c,b
5782: B3          or   e
5783: 48          ld   c,b
5784: 44          ld   b,h
5785: 68          ld   l,b
5786: 25          dec  h
5787: 68          ld   l,b
5788: 24          inc  h
5789: 68          ld   l,b
578A: 05          dec  b
578B: 68          ld   l,b
578C: 25          dec  h
578D: 68          ld   l,b
578E: 24          inc  h
578F: 68          ld   l,b
5790: 05          dec  b
5791: 68          ld   l,b
5792: 04          inc  b
5793: 68          ld   l,b
5794: 44          ld   b,h
5795: 68          ld   l,b
5796: 25          dec  h
5797: 68          ld   l,b
5798: 24          inc  h
5799: 68          ld   l,b
579A: 05          dec  b
579B: 68          ld   l,b
579C: 01 6C 01    ld   bc,$01C6
579F: 6C          ld   l,h
57A0: 70          ld   (hl),b
57A1: 6C          ld   l,h
57A2: 71          ld   (hl),c
57A3: 6C          ld   l,h
57A4: 00          nop
57A5: 00          nop
57A6: B3          or   e
57A7: 48          ld   c,b
57A8: B2          or   d
57A9: 48          ld   c,b
57AA: 93          sub  e
57AB: 48          ld   c,b
57AC: 00          nop
57AD: 00          nop
57AE: 6A          ld   l,d
57AF: A4          and  h
57B0: 6B          ld   l,e
57B1: A4          and  h
57B2: DB A4       in   a,($4A)
57B4: 00          nop
57B5: 00          nop
57B6: EA A4 EB    jp   pe,$AF4A
57B9: A4          and  h
57BA: 1A          ld   a,(de)
57BB: A4          and  h
57BC: 00          nop
57BD: 00          nop
57BE: 7A          ld   a,d
57BF: A4          and  h
57C0: 7B          ld   a,e
57C1: A4          and  h
57C2: 9A          sbc  a,d
57C3: A4          and  h
57C4: 92          sub  d
57C5: 48          ld   c,b
57C6: 93          sub  e
57C7: 48          ld   c,b
57C8: B2          or   d
57C9: 48          ld   c,b
57CA: B3          or   e
57CB: 48          ld   c,b
57CC: FA A4 FB    jp   m,$BF4A
57CF: A4          and  h
57D0: 4A          ld   c,d
57D1: A4          and  h
57D2: 4B          ld   c,e
57D3: A4          and  h
57D4: E9          jp   (hl)
57D5: A4          and  h
57D6: E9          jp   (hl)
57D7: A4          and  h
57D8: E9          jp   (hl)
57D9: A4          and  h
57DA: E9          jp   (hl)
57DB: A4          and  h
57DC: 9B          sbc  a,e
57DD: A4          and  h
57DE: BA          cp   d
57DF: A4          and  h
57E0: BB          cp   e
57E1: A4          and  h
57E2: DA A4 B3    jp   c,$3B4A
57E5: 4A          ld   c,d
57E6: B2          or   d
57E7: 4A          ld   c,d
57E8: 93          sub  e
57E9: 4A          ld   c,d
57EA: 92          sub  d
57EB: 4A          ld   c,d
57EC: 4B          ld   c,e
57ED: A6          and  (hl)
57EE: 4A          ld   c,d
57EF: A6          and  (hl)
57F0: FB          ei
57F1: A6          and  (hl)
57F2: FA A6 E9    jp   m,$8F6A
57F5: A6          and  (hl)
57F6: E9          jp   (hl)
57F7: A6          and  (hl)
57F8: E9          jp   (hl)
57F9: A6          and  (hl)
57FA: E9          jp   (hl)
57FB: A6          and  (hl)
57FC: DA A6 BB    jp   c,$BB6A
57FF: A6          and  (hl)
5800: BA          cp   d
5801: A6          and  (hl)
5802: 9B          sbc  a,e
5803: A6          and  (hl)
5804: 93          sub  e
5805: 4A          ld   c,d
5806: B2          or   d
5807: 4A          ld   c,d
5808: B3          or   e
5809: 4A          ld   c,d
580A: 00          nop
580B: 00          nop
580C: DB A6       in   a,($6A)
580E: 6B          ld   l,e
580F: A6          and  (hl)
5810: 6A          ld   l,d
5811: A6          and  (hl)
5812: 00          nop
5813: 00          nop
5814: 1A          ld   a,(de)
5815: A6          and  (hl)
5816: EB          ex   de,hl
5817: A6          and  (hl)
5818: EA A6 00    jp   pe,$006A
581B: 00          nop
581C: 9A          sbc  a,d
581D: A6          and  (hl)
581E: 7B          ld   a,e
581F: A6          and  (hl)
5820: 7A          ld   a,d
5821: A6          and  (hl)
5822: 00          nop
5823: 00          nop
5824: 04          inc  b
5825: 68          ld   l,b
5826: 05          dec  b
5827: 68          ld   l,b
5828: 24          inc  h
5829: 68          ld   l,b
582A: 25          dec  h
582B: 68          ld   l,b
582C: 05          dec  b
582D: 68          ld   l,b
582E: 24          inc  h
582F: 68          ld   l,b
5830: 25          dec  h
5831: 68          ld   l,b
5832: 44          ld   b,h
5833: 68          ld   l,b
5834: 24          inc  h
5835: 68          ld   l,b
5836: 25          dec  h
5837: 68          ld   l,b
5838: 25          dec  h
5839: 68          ld   l,b
583A: 25          dec  h
583B: 68          ld   l,b
583C: 81          add  a,c
583D: 6C          ld   l,h
583E: 81          add  a,c
583F: 6C          ld   l,h
5840: 81          add  a,c
5841: 6C          ld   l,h
5842: 01 6C 45    ld   bc,$45C6
5845: 69          ld   l,c
5846: 45          ld   b,l
5847: 69          ld   l,c
5848: 73          ld   (hl),e
5849: 48          ld   c,b
584A: B3          or   e
584B: 48          ld   c,b
584C: 45          ld   b,l
584D: 69          ld   l,c
584E: 45          ld   b,l
584F: 69          ld   l,c
5850: B3          or   e
5851: 48          ld   c,b
5852: B2          or   d
5853: 48          ld   c,b
5854: 45          ld   b,l
5855: 69          ld   l,c
5856: 45          ld   b,l
5857: 69          ld   l,c
5858: B2          or   d
5859: 48          ld   c,b
585A: 73          ld   (hl),e
585B: 48          ld   c,b
585C: 45          ld   b,l
585D: 69          ld   l,c
585E: 45          ld   b,l
585F: 69          ld   l,c
5860: 93          sub  e
5861: 48          ld   c,b
5862: B2          or   d
5863: 48          ld   c,b
5864: D4 A9 D5    call nc,$5D8B
5867: A9          xor  c
5868: F4 A9 F5    call p,$5F8B
586B: A9          xor  c
586C: F4 A9 D5    call p,$5D8B
586F: A9          xor  c
5870: F5          push af
5871: A9          xor  c
5872: F5          push af
5873: A9          xor  c
5874: D5          push de
5875: A9          xor  c
5876: F4 A9 D5    call p,$5D8B
5879: A9          xor  c
587A: F4 A9 D4    call p,$5C8B
587D: A9          xor  c
587E: D5          push de
587F: A9          xor  c
5880: F4 A9 F5    call p,$5F8B
5883: A9          xor  c
5884: 73          ld   (hl),e
5885: 48          ld   c,b
5886: B3          or   e
5887: 48          ld   c,b
5888: B2          or   d
5889: 48          ld   c,b
588A: 93          sub  e
588B: 48          ld   c,b
588C: B3          or   e
588D: 48          ld   c,b
588E: B2          or   d
588F: 48          ld   c,b
5890: 93          sub  e
5891: 48          ld   c,b
5892: 92          sub  d
5893: 48          ld   c,b
5894: 4C          ld   c,h
5895: C1          pop  bc
5896: 4D          ld   c,l
5897: C1          pop  bc
5898: 6C          ld   l,h
5899: C1          pop  bc
589A: 6D          ld   l,l
589B: C1          pop  bc
589C: B2          or   d
589D: 48          ld   c,b
589E: 93          sub  e
589F: 48          ld   c,b
58A0: B3          or   e
58A1: 48          ld   c,b
58A2: 73          ld   (hl),e
58A3: 48          ld   c,b
58A4: 73          ld   (hl),e
58A5: 48          ld   c,b
58A6: B3          or   e
58A7: 48          ld   c,b
58A8: B2          or   d
58A9: 48          ld   c,b
58AA: 93          sub  e
58AB: 48          ld   c,b
58AC: B3          or   e
58AD: 48          ld   c,b
58AE: B2          or   d
58AF: 48          ld   c,b
58B0: 93          sub  e
58B1: 48          ld   c,b
58B2: 93          sub  e
58B3: 48          ld   c,b
58B4: 4C          ld   c,h
58B5: C1          pop  bc
58B6: 4D          ld   c,l
58B7: C1          pop  bc
58B8: 4D          ld   c,l
58B9: C1          pop  bc
58BA: 6C          ld   l,h
58BB: C1          pop  bc
58BC: B3          or   e
58BD: 48          ld   c,b
58BE: B2          or   d
58BF: 48          ld   c,b
58C0: 93          sub  e
58C1: 48          ld   c,b
58C2: B2          or   d
58C3: 48          ld   c,b
58C4: B3          or   e
58C5: 48          ld   c,b
58C6: B2          or   d
58C7: 48          ld   c,b
58C8: 93          sub  e
58C9: 48          ld   c,b
58CA: 93          sub  e
58CB: 48          ld   c,b
58CC: B2          or   d
58CD: 48          ld   c,b
58CE: 93          sub  e
58CF: 48          ld   c,b
58D0: 92          sub  d
58D1: 48          ld   c,b
58D2: 93          sub  e
58D3: 48          ld   c,b
58D4: 6C          ld   l,h
58D5: C1          pop  bc
58D6: 6D          ld   l,l
58D7: C1          pop  bc
58D8: B2          or   d
58D9: 48          ld   c,b
58DA: 93          sub  e
58DB: 48          ld   c,b
58DC: 93          sub  e
58DD: 48          ld   c,b
58DE: 92          sub  d
58DF: 48          ld   c,b
58E0: 93          sub  e
58E1: 48          ld   c,b
58E2: B2          or   d
58E3: 48          ld   c,b
58E4: D4 A9 D5    call nc,$5D8B
58E7: A9          xor  c
58E8: F4 A9 F5    call p,$5F8B
58EB: A9          xor  c
58EC: F4 A9 D5    call p,$5D8B
58EF: A9          xor  c
58F0: 8C          adc  a,h
58F1: E1          pop  hl
58F2: F4 A9 D5    call p,$5D8B
58F5: A9          xor  c
58F6: 1C          inc  e
58F7: E1          pop  hl
58F8: 1D          dec  e
58F9: E1          pop  hl
58FA: 8D          adc  a,l
58FB: E1          pop  hl
58FC: F4 A9 9C    call p,$D88B
58FF: E1          pop  hl
5900: 9D          sbc  a,l
5901: E1          pop  hl
5902: D5          push de
5903: A9          xor  c
5904: F5          push af
5905: A9          xor  c
5906: F4 A9 D5    call p,$5D8B
5909: A9          xor  c
590A: D2 A9 D5    jp   nc,$5D8B
590D: A9          xor  c
590E: 8C          adc  a,h
590F: E3          ex   (sp),hl
5910: D4 A9 D5    call nc,$5D8B
5913: A9          xor  c
5914: 8D          adc  a,l
5915: E3          ex   (sp),hl
5916: 1D          dec  e
5917: E3          ex   (sp),hl
5918: 1C          inc  e
5919: E3          ex   (sp),hl
591A: F4 A9 F5    call p,$5F8B
591D: A9          xor  c
591E: 9D          sbc  a,l
591F: E3          ex   (sp),hl
5920: 9C          sbc  a,h
5921: E3          ex   (sp),hl
5922: D5          push de
5923: A9          xor  c
5924: 00          nop
5925: 00          nop
5926: 08          ex   af,af'
5927: ED          db   $ed
5928: 09          add  hl,bc
5929: ED          db   $ed
592A: 28 ED       jr   z,$58FB
592C: 00          nop
592D: 00          nop
592E: 88          adc  a,b
592F: ED          db   $ed
5930: 89          adc  a,c
5931: ED A8       ldd
5933: ED          db   $ed
5934: 00          nop
5935: 00          nop
5936: 18 ED       jr   $5907
5938: 19          add  hl,de
5939: ED          db   $ed
593A: 38 ED       jr   c,$590B
593C: 00          nop
593D: 00          nop
593E: 98          sbc  a,b
593F: ED          db   $ed
5940: 99          sbc  a,c
5941: ED B8       lddr
5943: ED          db   $ed
5944: 29          add  hl,hl
5945: ED          db   $ed
5946: F4 A9 D5    call p,$5D8B
5949: A9          xor  c
594A: D4 A9 A9    call nc,$8B8B
594D: ED          db   $ed
594E: F5          push af
594F: A9          xor  c
5950: F4 A9 D5    call p,$5D8B
5953: A9          xor  c
5954: 39          add  hl,sp
5955: ED          db   $ed
5956: F4 A9 D5    call p,$5D8B
5959: A9          xor  c
595A: F4 A9 D4    call p,$5C8B
595D: A9          xor  c
595E: D5          push de
595F: A9          xor  c
5960: F4 A9 F5    call p,$5F8B
5963: A9          xor  c
5964: 00          nop
5965: 00          nop
5966: F4 A9 D5    call p,$5D8B
5969: A9          xor  c
596A: D4 A9 00    call nc,$008B
596D: 00          nop
596E: F5          push af
596F: A9          xor  c
5970: F4 A9 D5    call p,$5D8B
5973: A9          xor  c
5974: 00          nop
5975: 00          nop
5976: F4 A9 D5    call p,$5D8B
5979: A9          xor  c
597A: F4 A9 00    call p,$008B
597D: 00          nop
597E: B9          cp   c
597F: ED          db   $ed
5980: D8          ret  c
5981: ED          db   $ed
5982: F5          push af
5983: A9          xor  c
5984: 00          nop
5985: 6E          ld   l,(hl)
5986: 80          add  a,b
5987: 6E          ld   l,(hl)
5988: 80          add  a,b
5989: 6E          ld   l,(hl)
598A: 80          add  a,b
598B: 6E          ld   l,(hl)
598C: 61          ld   h,c
598D: 6E          ld   l,(hl)
598E: 60          ld   h,b
598F: 6E          ld   l,(hl)
5990: 60          ld   h,b
5991: 6E          ld   l,(hl)
5992: 60          ld   h,b
5993: 6E          ld   l,(hl)
5994: 40          ld   b,b
5995: 6E          ld   l,(hl)
5996: 21 6E 21    ld   hl,$03E6
5999: 6E          ld   l,(hl)
599A: 21 6E C0    ld   hl,$0CE6
599D: 6E          ld   l,(hl)
599E: A1          and  c
599F: 6E          ld   l,(hl)
59A0: A1          and  c
59A1: 6E          ld   l,(hl)
59A2: A1          and  c
59A3: 6E          ld   l,(hl)
59A4: F4 A9 D5    call p,$5D8B
59A7: A9          xor  c
59A8: D5          push de
59A9: A9          xor  c
59AA: F4 A9 D5    call p,$5D8B
59AD: A9          xor  c
59AE: D5          push de
59AF: A9          xor  c
59B0: F4 A9 D5    call p,$5D8B
59B3: A9          xor  c
59B4: D5          push de
59B5: A9          xor  c
59B6: D4 A9 D5    call nc,$5D8B
59B9: A9          xor  c
59BA: F4 A9 F4    call p,$5E8B
59BD: A9          xor  c
59BE: D5          push de
59BF: A9          xor  c
59C0: D4 A9 D5    call nc,$5D8B
59C3: A9          xor  c
59C4: 79          ld   a,c
59C5: A4          and  h
59C6: 08          ex   af,af'
59C7: A4          and  h
59C8: 09          add  hl,bc
59C9: A4          and  h
59CA: 28 A4       jr   z,$5A16
59CC: 79          ld   a,c
59CD: A4          and  h
59CE: 88          adc  a,b
59CF: A4          and  h
59D0: 89          adc  a,c
59D1: A4          and  h
59D2: A8          xor  b
59D3: A4          and  h
59D4: 79          ld   a,c
59D5: A4          and  h
59D6: 18 A4       jr   $5A22
59D8: 19          add  hl,de
59D9: A4          and  h
59DA: 38 A4       jr   c,$5A26
59DC: F9          ld   sp,hl
59DD: A4          and  h
59DE: 98          sbc  a,b
59DF: A4          and  h
59E0: 99          sbc  a,c
59E1: A4          and  h
59E2: B8          cp   b
59E3: A4          and  h
59E4: 29          add  hl,hl
59E5: A4          and  h
59E6: 48          ld   c,b
59E7: A4          and  h
59E8: 49          ld   c,c
59E9: A4          and  h
59EA: 68          ld   l,b
59EB: A4          and  h
59EC: A9          xor  c
59ED: A4          and  h
59EE: C8          ret  z
59EF: A4          and  h
59F0: C9          ret
59F1: A4          and  h
59F2: E8          ret  pe
59F3: A4          and  h
59F4: 39          add  hl,sp
59F5: A4          and  h
59F6: 58          ld   e,b
59F7: A4          and  h
59F8: 59          ld   e,c
59F9: A4          and  h
59FA: 78          ld   a,b
59FB: A4          and  h
59FC: B9          cp   c
59FD: A4          and  h
59FE: D8          ret  c
59FF: A4          and  h
5A00: D9          exx
5A01: A4          and  h
5A02: F8          ret  m
5A03: A4          and  h
5A04: B3          or   e
5A05: 48          ld   c,b
5A06: 0A          ld   a,(bc)
5A07: A4          and  h
5A08: 0B          dec  bc
5A09: A4          and  h
5A0A: 2A A4 B2    ld   hl,($3A4A)
5A0D: 48          ld   c,b
5A0E: 8A          adc  a,d
5A0F: A4          and  h
5A10: 8B          adc  a,e
5A11: A4          and  h
5A12: AA          xor  d
5A13: A4          and  h
5A14: 93          sub  e
5A15: 48          ld   c,b
5A16: 92          sub  d
5A17: 48          ld   c,b
5A18: 1B          dec  de
5A19: A4          and  h
5A1A: 3A A4 B2    ld   a,($3A4A)
5A1D: 48          ld   c,b
5A1E: 93          sub  e
5A1F: 48          ld   c,b
5A20: B2          or   d
5A21: 48          ld   c,b
5A22: B3          or   e
5A23: 58          ld   e,b
5A24: 0B          dec  bc
5A25: A4          and  h
5A26: 2A A4 0B    ld   hl,($A14A)
5A29: A4          and  h
5A2A: 2B          dec  hl
5A2B: A4          and  h
5A2C: AB          xor  e
5A2D: A4          and  h
5A2E: 8B          adc  a,e
5A2F: A4          and  h
5A30: CA A4 CB    jp   z,$AD4A
5A33: A4          and  h
5A34: 3B          dec  sp
5A35: A4          and  h
5A36: 3A A4 5A    ld   a,($B44A)
5A39: A4          and  h
5A3A: 5B          ld   e,e
5A3B: A4          and  h
5A3C: 73          ld   (hl),e
5A3D: 48          ld   c,b
5A3E: B3          or   e
5A3F: 48          ld   c,b
5A40: B2          or   d
5A41: 48          ld   c,b
5A42: 93          sub  e
5A43: 58          ld   e,b
5A44: 68          ld   l,b
5A45: A6          and  (hl)
5A46: 49          ld   c,c
5A47: A6          and  (hl)
5A48: 48          ld   c,b
5A49: A6          and  (hl)
5A4A: 29          add  hl,hl
5A4B: A6          and  (hl)
5A4C: E8          ret  pe
5A4D: A6          and  (hl)
5A4E: C9          ret
5A4F: A6          and  (hl)
5A50: C8          ret  z
5A51: A6          and  (hl)
5A52: A9          xor  c
5A53: A6          and  (hl)
5A54: 78          ld   a,b
5A55: A6          and  (hl)
5A56: 59          ld   e,c
5A57: A6          and  (hl)
5A58: 58          ld   e,b
5A59: A6          and  (hl)
5A5A: 39          add  hl,sp
5A5B: A6          and  (hl)
5A5C: F8          ret  m
5A5D: A6          and  (hl)
5A5E: D9          exx
5A5F: A6          and  (hl)
5A60: D8          ret  c
5A61: A6          and  (hl)
5A62: B9          cp   c
5A63: A6          and  (hl)
5A64: 28 A6       jr   z,$5AD0
5A66: 09          add  hl,bc
5A67: A6          and  (hl)
5A68: 08          ex   af,af'
5A69: A6          and  (hl)
5A6A: 79          ld   a,c
5A6B: A6          and  (hl)
5A6C: A8          xor  b
5A6D: A6          and  (hl)
5A6E: 89          adc  a,c
5A6F: A6          and  (hl)
5A70: 88          adc  a,b
5A71: A6          and  (hl)
5A72: 79          ld   a,c
5A73: A6          and  (hl)
5A74: 38 A6       jr   c,$5AE0
5A76: 19          add  hl,de
5A77: A6          and  (hl)
5A78: 18 A6       jr   $5AE4
5A7A: 79          ld   a,c
5A7B: A6          and  (hl)
5A7C: B8          cp   b
5A7D: A6          and  (hl)
5A7E: 99          sbc  a,c
5A7F: A6          and  (hl)
5A80: 98          sbc  a,b
5A81: A6          and  (hl)
5A82: F9          ld   sp,hl
5A83: A6          and  (hl)
5A84: 2B          dec  hl
5A85: A6          and  (hl)
5A86: 0B          dec  bc
5A87: A6          and  (hl)
5A88: 2A A6 0B    ld   hl,($A16A)
5A8B: A6          and  (hl)
5A8C: CB A6       res  4,(hl)
5A8E: CA A6 8B    jp   z,$A96A
5A91: A6          and  (hl)
5A92: AB          xor  e
5A93: A6          and  (hl)
5A94: 5B          ld   e,e
5A95: A6          and  (hl)
5A96: 5A          ld   e,d
5A97: A6          and  (hl)
5A98: 3A A6 3B    ld   a,($B36A)
5A9B: A6          and  (hl)
5A9C: B2          or   d
5A9D: 48          ld   c,b
5A9E: B3          or   e
5A9F: 48          ld   c,b
5AA0: B2          or   d
5AA1: 48          ld   c,b
5AA2: 93          sub  e
5AA3: 48          ld   c,b
5AA4: 2A A6 0B    ld   hl,($A16A)
5AA7: A6          and  (hl)
5AA8: 0A          ld   a,(bc)
5AA9: A6          and  (hl)
5AAA: 73          ld   (hl),e
5AAB: 48          ld   c,b
5AAC: AA          xor  d
5AAD: A6          and  (hl)
5AAE: 8B          adc  a,e
5AAF: A6          and  (hl)
5AB0: 8A          adc  a,d
5AB1: A6          and  (hl)
5AB2: B3          or   e
5AB3: 48          ld   c,b
5AB4: 3A A6 1B    ld   a,($B16A)
5AB7: A6          and  (hl)
5AB8: B3          or   e
5AB9: 48          ld   c,b
5ABA: B2          or   d
5ABB: 48          ld   c,b
5ABC: 92          sub  d
5ABD: 48          ld   c,b
5ABE: 93          sub  e
5ABF: 48          ld   c,b
5AC0: B2          or   d
5AC1: 48          ld   c,b
5AC2: B3          or   e
5AC3: 48          ld   c,b
5AC4: 71          ld   (hl),c
5AC5: 6E          ld   l,(hl)
5AC6: 70          ld   (hl),b
5AC7: 6E          ld   l,(hl)
5AC8: 00          nop
5AC9: 6E          ld   l,(hl)
5ACA: 00          nop
5ACB: 6E          ld   l,(hl)
5ACC: 71          ld   (hl),c
5ACD: 6E          ld   l,(hl)
5ACE: 70          ld   (hl),b
5ACF: 6E          ld   l,(hl)
5AD0: 61          ld   h,c
5AD1: 6E          ld   l,(hl)
5AD2: 61          ld   h,c
5AD3: 6E          ld   l,(hl)
5AD4: 71          ld   (hl),c
5AD5: 6E          ld   l,(hl)
5AD6: 70          ld   (hl),b
5AD7: 6E          ld   l,(hl)
5AD8: 41          ld   b,c
5AD9: 6E          ld   l,(hl)
5ADA: 40          ld   b,b
5ADB: 6E          ld   l,(hl)
5ADC: F1          pop  af
5ADD: 6E          ld   l,(hl)
5ADE: F0          ret  p
5ADF: 6E          ld   l,(hl)
5AE0: C1          pop  bc
5AE1: 6E          ld   l,(hl)
5AE2: C0          ret  nz
5AE3: 6E          ld   l,(hl)
5AE4: 00          nop
5AE5: 6C          ld   l,h
5AE6: 00          nop
5AE7: 6C          ld   l,h
5AE8: 70          ld   (hl),b
5AE9: 6C          ld   l,h
5AEA: 71          ld   (hl),c
5AEB: 6C          ld   l,h
5AEC: 61          ld   h,c
5AED: 6C          ld   l,h
5AEE: 61          ld   h,c
5AEF: 6C          ld   l,h
5AF0: 70          ld   (hl),b
5AF1: 6C          ld   l,h
5AF2: 71          ld   (hl),c
5AF3: 6C          ld   l,h
5AF4: 40          ld   b,b
5AF5: 6C          ld   l,h
5AF6: 41          ld   b,c
5AF7: 6C          ld   l,h
5AF8: 70          ld   (hl),b
5AF9: 6C          ld   l,h
5AFA: 71          ld   (hl),c
5AFB: 6C          ld   l,h
5AFC: C0          ret  nz
5AFD: 6C          ld   l,h
5AFE: C1          pop  bc
5AFF: 6C          ld   l,h
5B00: F0          ret  p
5B01: 6C          ld   l,h
5B02: F1          pop  af
5B03: 6C          ld   l,h
5B04: 80          add  a,b
5B05: 6C          ld   l,h
5B06: 80          add  a,b
5B07: 6C          ld   l,h
5B08: 80          add  a,b
5B09: 6C          ld   l,h
5B0A: 00          nop
5B0B: 6C          ld   l,h
5B0C: 60          ld   h,b
5B0D: 6C          ld   l,h
5B0E: 60          ld   h,b
5B0F: 6C          ld   l,h
5B10: 60          ld   h,b
5B11: 6C          ld   l,h
5B12: 61          ld   h,c
5B13: 6C          ld   l,h
5B14: 21 6C 21    ld   hl,$03C6
5B17: 6C          ld   l,h
5B18: 21 6C 40    ld   hl,$04C6
5B1B: 6C          ld   l,h
5B1C: A1          and  c
5B1D: 6C          ld   l,h
5B1E: A1          and  c
5B1F: 6C          ld   l,h
5B20: A1          and  c
5B21: 6C          ld   l,h
5B22: C0          ret  nz
5B23: 6C          ld   l,h
5B24: 04          inc  b
5B25: 68          ld   l,b
5B26: 24          inc  h
5B27: 68          ld   l,b
5B28: 25          dec  h
5B29: 68          ld   l,b
5B2A: 24          inc  h
5B2B: 68          ld   l,b
5B2C: 25          dec  h
5B2D: 68          ld   l,b
5B2E: 05          dec  b
5B2F: 68          ld   l,b
5B30: 04          inc  b
5B31: 68          ld   l,b
5B32: 05          dec  b
5B33: 68          ld   l,b
5B34: 24          inc  h
5B35: 68          ld   l,b
5B36: 04          inc  b
5B37: 68          ld   l,b
5B38: 04          inc  b
5B39: 6C          ld   l,h
5B3A: 05          dec  b
5B3B: 6C          ld   l,h
5B3C: 25          dec  h
5B3D: 68          ld   l,b
5B3E: 05          dec  b
5B3F: 68          ld   l,b
5B40: 24          inc  h
5B41: 68          ld   l,b
5B42: 25          dec  h
5B43: 68          ld   l,b
5B44: 44          ld   b,h
5B45: 68          ld   l,b
5B46: 25          dec  h
5B47: 68          ld   l,b
5B48: 24          inc  h
5B49: 68          ld   l,b
5B4A: 05          dec  b
5B4B: 68          ld   l,b
5B4C: 25          dec  h
5B4D: 68          ld   l,b
5B4E: 24          inc  h
5B4F: 68          ld   l,b
5B50: 05          dec  b
5B51: 68          ld   l,b
5B52: 04          inc  b
5B53: 68          ld   l,b
5B54: 05          dec  b
5B55: 6E          ld   l,(hl)
5B56: 04          inc  b
5B57: 6E          ld   l,(hl)
5B58: 25          dec  h
5B59: 68          ld   l,b
5B5A: 24          inc  h
5B5B: 68          ld   l,b
5B5C: 24          inc  h
5B5D: 68          ld   l,b
5B5E: 05          dec  b
5B5F: 68          ld   l,b
5B60: 04          inc  b
5B61: 68          ld   l,b
5B62: 05          dec  b
5B63: 68          ld   l,b
5B64: 04          inc  b
5B65: 68          ld   l,b
5B66: 05          dec  b
5B67: 68          ld   l,b
5B68: 24          inc  h
5B69: 68          ld   l,b
5B6A: 25          dec  h
5B6B: 68          ld   l,b
5B6C: 05          dec  b
5B6D: 68          ld   l,b
5B6E: 24          inc  h
5B6F: 68          ld   l,b
5B70: 25          dec  h
5B71: 68          ld   l,b
5B72: 44          ld   b,h
5B73: 68          ld   l,b
5B74: 04          inc  b
5B75: 6C          ld   l,h
5B76: 05          dec  b
5B77: 6C          ld   l,h
5B78: 24          inc  h
5B79: 6C          ld   l,h
5B7A: 24          inc  h
5B7B: 6E          ld   l,(hl)
5B7C: 24          inc  h
5B7D: 68          ld   l,b
5B7E: 25          dec  h
5B7F: 68          ld   l,b
5B80: 44          ld   b,h
5B81: 68          ld   l,b
5B82: 25          dec  h
5B83: 68          ld   l,b
5B84: 44          ld   b,h
5B85: 68          ld   l,b
5B86: 25          dec  h
5B87: 68          ld   l,b
5B88: 24          inc  h
5B89: 68          ld   l,b
5B8A: 05          dec  b
5B8B: 68          ld   l,b
5B8C: D3 EE       out  ($EE),a
5B8E: D2 EE 05    jp   nc,$41EE
5B91: 68          ld   l,b
5B92: 04          inc  b
5B93: 68          ld   l,b
5B94: 91          sub  c
5B95: EE 90       xor  $18
5B97: EE 44       xor  $44
5B99: 68          ld   l,b
5B9A: 24          inc  h
5B9B: 68          ld   l,b
5B9C: D1          pop  de
5B9D: EE D0       xor  $1C
5B9F: EE 44       xor  $44
5BA1: 68          ld   l,b
5BA2: 25          dec  h
5BA3: 68          ld   l,b
5BA4: 04          inc  b
5BA5: 68          ld   l,b
5BA6: 05          dec  b
5BA7: 68          ld   l,b
5BA8: 24          inc  h
5BA9: 68          ld   l,b
5BAA: 25          dec  h
5BAB: 68          ld   l,b
5BAC: 05          dec  b
5BAD: 68          ld   l,b
5BAE: 24          inc  h
5BAF: 68          ld   l,b
5BB0: F3          di
5BB1: EE F2       xor  $3E
5BB3: EE 24       xor  $42
5BB5: 68          ld   l,b
5BB6: 25          dec  h
5BB7: 68          ld   l,b
5BB8: B1          or   c
5BB9: EE B0       xor  $1A
5BBB: EE 05       xor  $41
5BBD: 68          ld   l,b
5BBE: 24          inc  h
5BBF: 68          ld   l,b
5BC0: B3          or   e
5BC1: EE B2       xor  $3A
5BC3: EE 44       xor  $44
5BC5: 68          ld   l,b
5BC6: 44          ld   b,h
5BC7: 68          ld   l,b
5BC8: 25          dec  h
5BC9: 68          ld   l,b
5BCA: 24          inc  h
5BCB: 68          ld   l,b
5BCC: D2 EC D3    jp   nc,$3DCE
5BCF: EC F2 EC    call pe,$CE3E
5BD2: F3          di
5BD3: EC 90 EC    call pe,$CE18
5BD6: 91          sub  c
5BD7: EC B0 EC    call pe,$CE1A
5BDA: B1          or   c
5BDB: EC D0 EC    call pe,$CE1C
5BDE: D1          pop  de
5BDF: EC B2 EC    call pe,$CE3A
5BE2: B3          or   e
5BE3: EC 44 68    call pe,$8644
5BE6: 25          dec  h
5BE7: 68          ld   l,b
5BE8: 24          inc  h
5BE9: 68          ld   l,b
5BEA: 05          dec  b
5BEB: 68          ld   l,b
5BEC: 72          ld   (hl),d
5BED: EC 73 EC    call pe,$CE37
5BF0: 05          dec  b
5BF1: 68          ld   l,b
5BF2: 04          inc  b
5BF3: 68          ld   l,b
5BF4: 32 EC 33    ld   ($33CE),a
5BF7: EC 24 68    call pe,$8642
5BFA: 24          inc  h
5BFB: 68          ld   l,b
5BFC: B2          or   d
5BFD: EC B3 EC    call pe,$CE3B
5C00: 25          dec  h
5C01: 68          ld   l,b
5C02: 44          ld   b,h
5C03: 68          ld   l,b
5C04: 04          inc  b
5C05: 68          ld   l,b
5C06: 05          dec  b
5C07: 68          ld   l,b
5C08: 24          inc  h
5C09: 68          ld   l,b
5C0A: 25          dec  h
5C0B: 68          ld   l,b
5C0C: 05          dec  b
5C0D: 68          ld   l,b
5C0E: 24          inc  h
5C0F: 68          ld   l,b
5C10: 52          ld   d,d
5C11: EC 53 EC    call pe,$CE35
5C14: 24          inc  h
5C15: 68          ld   l,b
5C16: 25          dec  h
5C17: 68          ld   l,b
5C18: 12          ld   (de),a
5C19: EC 13 EC    call pe,$CE31
5C1C: 25          dec  h
5C1D: 68          ld   l,b
5C1E: 44          ld   b,h
5C1F: 68          ld   l,b
5C20: 92          sub  d
5C21: EC 93 EC    call pe,$CE39
5C24: 04          inc  b
5C25: 68          ld   l,b
5C26: 05          dec  b
5C27: 68          ld   l,b
5C28: 24          inc  h
5C29: 68          ld   l,b
5C2A: 25          dec  h
5C2B: 68          ld   l,b
5C2C: 73          ld   (hl),e
5C2D: EE 72       xor  $36
5C2F: EE 53       xor  $35
5C31: EE 52       xor  $34
5C33: EE 33       xor  $33
5C35: EE 32       xor  $32
5C37: EE 13       xor  $31
5C39: EE 12       xor  $30
5C3B: EE B3       xor  $3B
5C3D: EE B2       xor  $3A
5C3F: EE 93       xor  $39
5C41: EE 92       xor  $38
5C43: EE F4       xor  $5E
5C45: A9          xor  c
5C46: D5          push de
5C47: A9          xor  c
5C48: D4 A9 D5    call nc,$5D8B
5C4B: A9          xor  c
5C4C: 11 AF 10    ld   de,$10EB
5C4F: AF          xor  a
5C50: D5          push de
5C51: A9          xor  c
5C52: F4 A9 F4    call p,$5E8B
5C55: A9          xor  c
5C56: D5          push de
5C57: A9          xor  c
5C58: D4 A9 F4    call nc,$5E8B
5C5B: A9          xor  c
5C5C: D5          push de
5C5D: A9          xor  c
5C5E: F4 A9 F5    call p,$5F8B
5C61: A9          xor  c
5C62: F4 A9 00    call p,$008B
5C65: 00          nop
5C66: 2C          inc  l
5C67: A8          xor  b
5C68: 2D          dec  l
5C69: A8          xor  b
5C6A: 4C          ld   c,h
5C6B: A8          xor  b
5C6C: 00          nop
5C6D: 00          nop
5C6E: AC          xor  h
5C6F: A8          xor  b
5C70: AD          xor  l
5C71: A8          xor  b
5C72: CC A8 00    call z,$008A
5C75: 00          nop
5C76: 3C          inc  a
5C77: E9          jp   (hl)
5C78: 3D          dec  a
5C79: E9          jp   (hl)
5C7A: 5C          ld   e,h
5C7B: E9          jp   (hl)
5C7C: 00          nop
5C7D: 00          nop
5C7E: D4 A9 D5    call nc,$5D8B
5C81: A9          xor  c
5C82: F4 A9 4D    call p,$C58B
5C85: A8          xor  b
5C86: 6C          ld   l,h
5C87: E9          jp   (hl)
5C88: D5          push de
5C89: A9          xor  c
5C8A: F4 A9 CD    call p,$CD8B
5C8D: A8          xor  b
5C8E: EC E9 F4    call pe,$5E8F
5C91: A9          xor  c
5C92: F5          push af
5C93: A9          xor  c
5C94: 5D          ld   e,l
5C95: E9          jp   (hl)
5C96: 7C          ld   a,h
5C97: E9          jp   (hl)
5C98: F5          push af
5C99: A9          xor  c
5C9A: F4 A9 D4    call p,$5C8B
5C9D: A9          xor  c
5C9E: D5          push de
5C9F: A9          xor  c
5CA0: F4 A9 F5    call p,$5F8B
5CA3: A9          xor  c
5CA4: D5          push de
5CA5: A9          xor  c
5CA6: D4 A9 6C    call nc,$C68B
5CA9: EB          ex   de,hl
5CAA: 4D          ld   c,l
5CAB: AA          xor  d
5CAC: D4 A9 D5    call nc,$5D8B
5CAF: A9          xor  c
5CB0: EC EB CD    call pe,$CDAF
5CB3: AA          xor  d
5CB4: D5          push de
5CB5: A9          xor  c
5CB6: F4 A9 7C    call p,$D68B
5CB9: EB          ex   de,hl
5CBA: 5D          ld   e,l
5CBB: EB          ex   de,hl
5CBC: F4 A9 F5    call p,$5F8B
5CBF: A9          xor  c
5CC0: F4 A9 D5    call p,$5D8B
5CC3: A9          xor  c
5CC4: 4C          ld   c,h
5CC5: AA          xor  d
5CC6: 2D          dec  l
5CC7: AA          xor  d
5CC8: 2C          inc  l
5CC9: AA          xor  d
5CCA: 00          nop
5CCB: 00          nop
5CCC: CC AA AD    call z,$CBAA
5CCF: AA          xor  d
5CD0: AC          xor  h
5CD1: AA          xor  d
5CD2: 00          nop
5CD3: 00          nop
5CD4: 5C          ld   e,h
5CD5: EB          ex   de,hl
5CD6: 3D          dec  a
5CD7: EB          ex   de,hl
5CD8: 3C          inc  a
5CD9: EB          ex   de,hl
5CDA: 00          nop
5CDB: 00          nop
5CDC: D4 A9 D5    call nc,$5D8B
5CDF: A9          xor  c
5CE0: F4 A9 00    call p,$008B
5CE3: 00          nop
5CE4: 00          nop
5CE5: 00          nop
5CE6: 2C          inc  l
5CE7: A8          xor  b
5CE8: 2D          dec  l
5CE9: A8          xor  b
5CEA: 4C          ld   c,h
5CEB: A8          xor  b
5CEC: 00          nop
5CED: 00          nop
5CEE: AC          xor  h
5CEF: A8          xor  b
5CF0: AD          xor  l
5CF1: A8          xor  b
5CF2: CC A8 00    call z,$008A
5CF5: 00          nop
5CF6: 86          add  a,(hl)
5CF7: A8          xor  b
5CF8: 87          add  a,a
5CF9: A8          xor  b
5CFA: A6          and  (hl)
5CFB: A8          xor  b
5CFC: 00          nop
5CFD: 00          nop
5CFE: 04          inc  b
5CFF: 68          ld   l,b
5D00: 05          dec  b
5D01: 68          ld   l,b
5D02: 24          inc  h
5D03: 68          ld   l,b
5D04: 4D          ld   c,l
5D05: A8          xor  b
5D06: 06 A8       ld   b,$8A
5D08: 04          inc  b
5D09: 68          ld   l,b
5D0A: 05          dec  b
5D0B: 68          ld   l,b
5D0C: CD A8 07    call $618A
5D0F: A8          xor  b
5D10: 05          dec  b
5D11: 68          ld   l,b
5D12: 24          inc  h
5D13: 68          ld   l,b
5D14: A7          and  a
5D15: A8          xor  b
5D16: 26 A8       ld   h,$8A
5D18: 25          dec  h
5D19: 68          ld   l,b
5D1A: 05          dec  b
5D1B: 68          ld   l,b
5D1C: 04          inc  b
5D1D: 68          ld   l,b
5D1E: 05          dec  b
5D1F: 68          ld   l,b
5D20: 24          inc  h
5D21: 68          ld   l,b
5D22: 25          dec  h
5D23: 68          ld   l,b
5D24: 04          inc  b
5D25: 68          ld   l,b
5D26: 05          dec  b
5D27: 68          ld   l,b
5D28: 06 AA       ld   b,$AA
5D2A: 4D          ld   c,l
5D2B: AA          xor  d
5D2C: 05          dec  b
5D2D: 68          ld   l,b
5D2E: 24          inc  h
5D2F: 68          ld   l,b
5D30: 07          rlca
5D31: AA          xor  d
5D32: CD AA 25    call $43AA
5D35: 68          ld   l,b
5D36: 44          ld   b,h
5D37: 68          ld   l,b
5D38: 26 AA       ld   h,$AA
5D3A: A7          and  a
5D3B: AA          xor  d
5D3C: 05          dec  b
5D3D: 68          ld   l,b
5D3E: 24          inc  h
5D3F: 68          ld   l,b
5D40: 25          dec  h
5D41: 68          ld   l,b
5D42: 44          ld   b,h
5D43: 68          ld   l,b
5D44: 4C          ld   c,h
5D45: AA          xor  d
5D46: 2D          dec  l
5D47: AA          xor  d
5D48: 2C          inc  l
5D49: AA          xor  d
5D4A: 00          nop
5D4B: 00          nop
5D4C: CC AA AD    call z,$CBAA
5D4F: AA          xor  d
5D50: AC          xor  h
5D51: AA          xor  d
5D52: 00          nop
5D53: 00          nop
5D54: A6          and  (hl)
5D55: AA          xor  d
5D56: 87          add  a,a
5D57: AA          xor  d
5D58: 86          add  a,(hl)
5D59: AA          xor  d
5D5A: 00          nop
5D5B: 00          nop
5D5C: 04          inc  b
5D5D: 68          ld   l,b
5D5E: 05          dec  b
5D5F: 68          ld   l,b
5D60: 24          inc  h
5D61: 68          ld   l,b
5D62: 00          nop
5D63: 00          nop
5D64: 44          ld   b,h
5D65: 68          ld   l,b
5D66: 25          dec  h
5D67: 68          ld   l,b
5D68: 24          inc  h
5D69: 68          ld   l,b
5D6A: 44          ld   b,h
5D6B: 68          ld   l,b
5D6C: 25          dec  h
5D6D: 68          ld   l,b
5D6E: E4 6A C5    call po,$4DA6
5D71: 6A          ld   l,d
5D72: C4 6A 24    call nz,$42A6
5D75: 68          ld   l,b
5D76: 74          ld   (hl),h
5D77: 6A          ld   l,d
5D78: 55          ld   d,l
5D79: 6A          ld   l,d
5D7A: 54          ld   d,h
5D7B: 6A          ld   l,d
5D7C: 05          dec  b
5D7D: 68          ld   l,b
5D7E: 24          inc  h
5D7F: 68          ld   l,b
5D80: 25          dec  h
5D81: 68          ld   l,b
5D82: 25          dec  h
5D83: 68          ld   l,b
5D84: 82          add  a,d
5D85: AD          xor  l
5D86: 82          add  a,d
5D87: AD          xor  l
5D88: 82          add  a,d
5D89: AD          xor  l
5D8A: 02          ld   (bc),a
5D8B: AD          xor  l
5D8C: 62          ld   h,d
5D8D: AD          xor  l
5D8E: 62          ld   h,d
5D8F: AD          xor  l
5D90: 62          ld   h,d
5D91: AD          xor  l
5D92: 63          ld   h,e
5D93: AD          xor  l
5D94: 23          inc  hl
5D95: AD          xor  l
5D96: 23          inc  hl
5D97: AD          xor  l
5D98: 23          inc  hl
5D99: AD          xor  l
5D9A: 42          ld   b,d
5D9B: AD          xor  l
5D9C: A3          and  e
5D9D: AD          xor  l
5D9E: A3          and  e
5D9F: AD          xor  l
5DA0: A3          and  e
5DA1: AD          xor  l
5DA2: C2 AD 02    jp   nz,$20CB
5DA5: AD          xor  l
5DA6: 02          ld   (bc),a
5DA7: AD          xor  l
5DA8: 22 AD A2    ld   ($2ACB),hl
5DAB: AD          xor  l
5DAC: 63          ld   h,e
5DAD: AD          xor  l
5DAE: 63          ld   h,e
5DAF: AD          xor  l
5DB0: 22 AD A2    ld   ($2ACB),hl
5DB3: AD          xor  l
5DB4: 42          ld   b,d
5DB5: AD          xor  l
5DB6: 43          ld   b,e
5DB7: AD          xor  l
5DB8: 22 AD A2    ld   ($2ACB),hl
5DBB: AD          xor  l
5DBC: C2 AD C3    jp   nz,$2DCB
5DBF: AD          xor  l
5DC0: E2 AD E3    jp   po,$2FCB
5DC3: AD          xor  l
5DC4: A2          and  d
5DC5: AF          xor  a
5DC6: 22 AF 02    ld   ($20EB),hl
5DC9: AF          xor  a
5DCA: 02          ld   (bc),a
5DCB: AF          xor  a
5DCC: A2          and  d
5DCD: AF          xor  a
5DCE: 22 AF 63    ld   ($27EB),hl
5DD1: AF          xor  a
5DD2: 63          ld   h,e
5DD3: AF          xor  a
5DD4: A2          and  d
5DD5: AF          xor  a
5DD6: 22 AF 43    ld   ($25EB),hl
5DD9: AF          xor  a
5DDA: 42          ld   b,d
5DDB: AF          xor  a
5DDC: E3          ex   (sp),hl
5DDD: AF          xor  a
5DDE: E2 AF C3    jp   po,$2DEB
5DE1: AF          xor  a
5DE2: C2 AF 02    jp   nz,$20EB
5DE5: AF          xor  a
5DE6: 82          add  a,d
5DE7: AF          xor  a
5DE8: 82          add  a,d
5DE9: AF          xor  a
5DEA: 82          add  a,d
5DEB: AF          xor  a
5DEC: 63          ld   h,e
5DED: AF          xor  a
5DEE: 62          ld   h,d
5DEF: AF          xor  a
5DF0: 62          ld   h,d
5DF1: AF          xor  a
5DF2: 62          ld   h,d
5DF3: AF          xor  a
5DF4: 42          ld   b,d
5DF5: AF          xor  a
5DF6: 23          inc  hl
5DF7: AF          xor  a
5DF8: 23          inc  hl
5DF9: AF          xor  a
5DFA: 23          inc  hl
5DFB: AF          xor  a
5DFC: C2 AF A3    jp   nz,$2BEB
5DFF: AF          xor  a
5E00: A3          and  e
5E01: AF          xor  a
5E02: A3          and  e
5E03: AF          xor  a
5E04: 98          sbc  a,b
5E05: 88          adc  a,b
5E06: 60          ld   h,b
5E07: 86          add  a,(hl)
5E08: 41          ld   b,c
5E09: 86          add  a,(hl)
5E0A: 40          ld   b,b
5E0B: 86          add  a,(hl)
5E0C: 99          sbc  a,c
5E0D: 88          adc  a,b
5E0E: 99          sbc  a,c
5E0F: 88          adc  a,b
5E10: 98          sbc  a,b
5E11: 88          adc  a,b
5E12: C0          ret  nz
5E13: 86          add  a,(hl)
5E14: 98          sbc  a,b
5E15: 88          adc  a,b
5E16: 98          sbc  a,b
5E17: 88          adc  a,b
5E18: 99          sbc  a,c
5E19: 88          adc  a,b
5E1A: 98          sbc  a,b
5E1B: 88          adc  a,b
5E1C: D1          pop  de
5E1D: 84          add  a,h
5E1E: 99          sbc  a,c
5E1F: 88          adc  a,b
5E20: 98          sbc  a,b
5E21: 88          adc  a,b
5E22: 99          sbc  a,c
5E23: 88          adc  a,b
5E24: 21 84 B2    ld   hl,$3A48
5E27: 48          ld   c,b
5E28: B3          or   e
5E29: 48          ld   c,b
5E2A: 73          ld   (hl),e
5E2B: 48          ld   c,b
5E2C: A1          and  c
5E2D: 86          add  a,(hl)
5E2E: 20 86       jr   nz,$5E98
5E30: 01 86 B3    ld   bc,$3B68
5E33: 48          ld   c,b
5E34: 99          sbc  a,c
5E35: 88          adc  a,b
5E36: 98          sbc  a,b
5E37: 88          adc  a,b
5E38: 81          add  a,c
5E39: 86          add  a,(hl)
5E3A: 00          nop
5E3B: 86          add  a,(hl)
5E3C: 98          sbc  a,b
5E3D: 88          adc  a,b
5E3E: 99          sbc  a,c
5E3F: 88          adc  a,b
5E40: 98          sbc  a,b
5E41: 88          adc  a,b
5E42: 80          add  a,b
5E43: 86          add  a,(hl)
5E44: 98          sbc  a,b
5E45: 88          adc  a,b
5E46: 98          sbc  a,b
5E47: 88          adc  a,b
5E48: 99          sbc  a,c
5E49: 88          adc  a,b
5E4A: 98          sbc  a,b
5E4B: 88          adc  a,b
5E4C: 99          sbc  a,c
5E4D: 88          adc  a,b
5E4E: 99          sbc  a,c
5E4F: 88          adc  a,b
5E50: 98          sbc  a,b
5E51: 88          adc  a,b
5E52: 99          sbc  a,c
5E53: 88          adc  a,b
5E54: 98          sbc  a,b
5E55: 88          adc  a,b
5E56: 98          sbc  a,b
5E57: 88          adc  a,b
5E58: 99          sbc  a,c
5E59: 88          adc  a,b
5E5A: 98          sbc  a,b
5E5B: 88          adc  a,b
5E5C: F1          pop  af
5E5D: 84          add  a,h
5E5E: F1          pop  af
5E5F: 86          add  a,(hl)
5E60: F0          ret  p
5E61: 84          add  a,h
5E62: D1          pop  de
5E63: 86          add  a,(hl)
5E64: 99          sbc  a,c
5E65: 88          adc  a,b
5E66: 98          sbc  a,b
5E67: 88          adc  a,b
5E68: 99          sbc  a,c
5E69: 88          adc  a,b
5E6A: 10 86       djnz $5ED4
5E6C: 98          sbc  a,b
5E6D: 88          adc  a,b
5E6E: 99          sbc  a,c
5E6F: 88          adc  a,b
5E70: 91          sub  c
5E71: 86          add  a,(hl)
5E72: 90          sub  b
5E73: 86          add  a,(hl)
5E74: 99          sbc  a,c
5E75: 88          adc  a,b
5E76: B0          or   b
5E77: 86          add  a,(hl)
5E78: B2          or   d
5E79: 48          ld   c,b
5E7A: B3          or   e
5E7B: 48          ld   c,b
5E7C: D0          ret  nc
5E7D: 86          add  a,(hl)
5E7E: B1          or   c
5E7F: 86          add  a,(hl)
5E80: 93          sub  e
5E81: 48          ld   c,b
5E82: B2          or   d
5E83: 48          ld   c,b
5E84: 4C          ld   c,h
5E85: C1          pop  bc
5E86: 4D          ld   c,l
5E87: C1          pop  bc
5E88: 6C          ld   l,h
5E89: C1          pop  bc
5E8A: 4D          ld   c,l
5E8B: C1          pop  bc
5E8C: B2          or   d
5E8D: 48          ld   c,b
5E8E: 93          sub  e
5E8F: 48          ld   c,b
5E90: 92          sub  d
5E91: 48          ld   c,b
5E92: 93          sub  e
5E93: 48          ld   c,b
5E94: 93          sub  e
5E95: 48          ld   c,b
5E96: 92          sub  d
5E97: 48          ld   c,b
5E98: 93          sub  e
5E99: 48          ld   c,b
5E9A: B2          or   d
5E9B: 48          ld   c,b
5E9C: B2          or   d
5E9D: 48          ld   c,b
5E9E: 93          sub  e
5E9F: 48          ld   c,b
5EA0: 92          sub  d
5EA1: 48          ld   c,b
5EA2: 93          sub  e
5EA3: 48          ld   c,b
5EA4: 6C          ld   l,h
5EA5: C1          pop  bc
5EA6: 6D          ld   l,l
5EA7: C1          pop  bc
5EA8: 73          ld   (hl),e
5EA9: 48          ld   c,b
5EAA: B3          or   e
5EAB: 48          ld   c,b
5EAC: B3          or   e
5EAD: 48          ld   c,b
5EAE: 73          ld   (hl),e
5EAF: 48          ld   c,b
5EB0: B3          or   e
5EB1: 48          ld   c,b
5EB2: B2          or   d
5EB3: 48          ld   c,b
5EB4: 93          sub  e
5EB5: 48          ld   c,b
5EB6: B3          or   e
5EB7: 48          ld   c,b
5EB8: 73          ld   (hl),e
5EB9: 48          ld   c,b
5EBA: B3          or   e
5EBB: 48          ld   c,b
5EBC: 92          sub  d
5EBD: 48          ld   c,b
5EBE: B2          or   d
5EBF: 48          ld   c,b
5EC0: 93          sub  e
5EC1: 48          ld   c,b
5EC2: B2          or   d
5EC3: 48          ld   c,b
5EC4: B3          or   e
5EC5: 48          ld   c,b
5EC6: 93          sub  e
5EC7: 48          ld   c,b
5EC8: 4C          ld   c,h
5EC9: C1          pop  bc
5ECA: 4D          ld   c,l
5ECB: C1          pop  bc
5ECC: 73          ld   (hl),e
5ECD: 48          ld   c,b
5ECE: B2          or   d
5ECF: 48          ld   c,b
5ED0: 93          sub  e
5ED1: 48          ld   c,b
5ED2: 92          sub  d
5ED3: 48          ld   c,b
5ED4: B2          or   d
5ED5: 48          ld   c,b
5ED6: 93          sub  e
5ED7: 48          ld   c,b
5ED8: 92          sub  d
5ED9: 48          ld   c,b
5EDA: 93          sub  e
5EDB: 48          ld   c,b
5EDC: B3          or   e
5EDD: 48          ld   c,b
5EDE: B2          or   d
5EDF: 48          ld   c,b
5EE0: 93          sub  e
5EE1: 48          ld   c,b
5EE2: 92          sub  d
5EE3: 48          ld   c,b
5EE4: 80          add  a,b
5EE5: 6C          ld   l,h
5EE6: 80          add  a,b
5EE7: 6C          ld   l,h
5EE8: 80          add  a,b
5EE9: 6C          ld   l,h
5EEA: 00          nop
5EEB: 6C          ld   l,h
5EEC: 60          ld   h,b
5EED: 6C          ld   l,h
5EEE: 60          ld   h,b
5EEF: 6C          ld   l,h
5EF0: 60          ld   h,b
5EF1: 6C          ld   l,h
5EF2: 61          ld   h,c
5EF3: 6C          ld   l,h
5EF4: 21 6C 21    ld   hl,$03C6
5EF7: 6C          ld   l,h
5EF8: 21 6C 40    ld   hl,$04C6
5EFB: 6C          ld   l,h
5EFC: A1          and  c
5EFD: 6C          ld   l,h
5EFE: A1          and  c
5EFF: 6C          ld   l,h
5F00: A1          and  c
5F01: 6C          ld   l,h
5F02: C0          ret  nz
5F03: 6C          ld   l,h
5F04: 00          nop
5F05: 6C          ld   l,h
5F06: 00          nop
5F07: 6C          ld   l,h
5F08: 20 6C       jr   nz,$5ED0
5F0A: A0          and  b
5F0B: 6C          ld   l,h
5F0C: 61          ld   h,c
5F0D: 6C          ld   l,h
5F0E: 61          ld   h,c
5F0F: 6C          ld   l,h
5F10: 20 6C       jr   nz,$5ED8
5F12: A0          and  b
5F13: 6C          ld   l,h
5F14: 40          ld   b,b
5F15: 6C          ld   l,h
5F16: 41          ld   b,c
5F17: 6C          ld   l,h
5F18: 20 6C       jr   nz,$5EE0
5F1A: A0          and  b
5F1B: 6C          ld   l,h
5F1C: C0          ret  nz
5F1D: 6C          ld   l,h
5F1E: C1          pop  bc
5F1F: 6C          ld   l,h
5F20: E0          ret  po
5F21: 6C          ld   l,h
5F22: E1          pop  hl
5F23: 6C          ld   l,h
5F24: A0          and  b
5F25: 6E          ld   l,(hl)
5F26: 20 6E       jr   nz,$5F0E
5F28: 00          nop
5F29: 6E          ld   l,(hl)
5F2A: 00          nop
5F2B: 6E          ld   l,(hl)
5F2C: A0          and  b
5F2D: 6E          ld   l,(hl)
5F2E: 20 6E       jr   nz,$5F16
5F30: 61          ld   h,c
5F31: 6E          ld   l,(hl)
5F32: 61          ld   h,c
5F33: 6E          ld   l,(hl)
5F34: A0          and  b
5F35: 6E          ld   l,(hl)
5F36: 20 6E       jr   nz,$5F1E
5F38: 41          ld   b,c
5F39: 6E          ld   l,(hl)
5F3A: 40          ld   b,b
5F3B: 6E          ld   l,(hl)
5F3C: E1          pop  hl
5F3D: 6E          ld   l,(hl)
5F3E: E0          ret  po
5F3F: 6E          ld   l,(hl)
5F40: C1          pop  bc
5F41: 6E          ld   l,(hl)
5F42: C0          ret  nz
5F43: 6E          ld   l,(hl)
5F44: 00          nop
5F45: 6E          ld   l,(hl)
5F46: 80          add  a,b
5F47: 6E          ld   l,(hl)
5F48: 80          add  a,b
5F49: 6E          ld   l,(hl)
5F4A: 80          add  a,b
5F4B: 6E          ld   l,(hl)
5F4C: 61          ld   h,c
5F4D: 6E          ld   l,(hl)
5F4E: 60          ld   h,b
5F4F: 6E          ld   l,(hl)
5F50: 60          ld   h,b
5F51: 6E          ld   l,(hl)
5F52: 60          ld   h,b
5F53: 6E          ld   l,(hl)
5F54: 40          ld   b,b
5F55: 6E          ld   l,(hl)
5F56: 21 6E 21    ld   hl,$03E6
5F59: 6E          ld   l,(hl)
5F5A: 21 6E C0    ld   hl,$0CE6
5F5D: 6E          ld   l,(hl)
5F5E: A1          and  c
5F5F: 6E          ld   l,(hl)
5F60: A1          and  c
5F61: 6E          ld   l,(hl)
5F62: A1          and  c
5F63: 6E          ld   l,(hl)
5F64: 44          ld   b,h
5F65: 68          ld   l,b
5F66: 25          dec  h
5F67: 68          ld   l,b
5F68: 24          inc  h
5F69: 68          ld   l,b
5F6A: 05          dec  b
5F6B: 68          ld   l,b
5F6C: 25          dec  h
5F6D: 68          ld   l,b
5F6E: 24          inc  h
5F6F: 68          ld   l,b
5F70: 05          dec  b
5F71: 68          ld   l,b
5F72: 04          inc  b
5F73: 68          ld   l,b
5F74: 44          ld   b,h
5F75: 68          ld   l,b
5F76: 25          dec  h
5F77: 68          ld   l,b
5F78: 24          inc  h
5F79: 68          ld   l,b
5F7A: 05          dec  b
5F7B: 68          ld   l,b
5F7C: 01 6E 81    ld   bc,$09E6
5F7F: 6E          ld   l,(hl)
5F80: 81          add  a,c
5F81: 6E          ld   l,(hl)
5F82: 81          add  a,c
5F83: 6E          ld   l,(hl)
5F84: F4 A9 D5    call p,$5D8B
5F87: A9          xor  c
5F88: D5          push de
5F89: A9          xor  c
5F8A: F4 A9 D5    call p,$5D8B
5F8D: A9          xor  c
5F8E: D4 A9 50    call nc,$148B
5F91: AD          xor  l
5F92: D5          push de
5F93: A9          xor  c
5F94: 10 AD       djnz $5F61
5F96: 11 AD 30    ld   de,$12CB
5F99: AD          xor  l
5F9A: 31 AD F4    ld   sp,$5ECB
5F9D: A9          xor  c
5F9E: D5          push de
5F9F: A9          xor  c
5FA0: D4 A9 D5    call nc,$5D8B
5FA3: A9          xor  c
5FA4: D5          push de
5FA5: A9          xor  c
5FA6: D4 A9 F4    call nc,$5E8B
5FA9: A9          xor  c
5FAA: F5          push af
5FAB: A9          xor  c
5FAC: D4 A9 F4    call nc,$5E8B
5FAF: A9          xor  c
5FB0: F5          push af
5FB1: A9          xor  c
5FB2: F4 A9 30    call p,$128B
5FB5: AF          xor  a
5FB6: 11 AF 10    ld   de,$10EB
5FB9: AF          xor  a
5FBA: D5          push de
5FBB: A9          xor  c
5FBC: D5          push de
5FBD: A9          xor  c
5FBE: F4 A9 D5    call p,$5D8B
5FC1: A9          xor  c
5FC2: F4 A9 D4    call p,$5C8B
5FC5: A9          xor  c
5FC6: D5          push de
5FC7: A9          xor  c
5FC8: F4 A9 D5    call p,$5D8B
5FCB: A9          xor  c
5FCC: 50          ld   d,b
5FCD: AD          xor  l
5FCE: F4 A9 D5    call p,$5D8B
5FD1: A9          xor  c
5FD2: D4 A9 30    call nc,$128B
5FD5: AD          xor  l
5FD6: 31 AD 31    ld   sp,$13CB
5FD9: AF          xor  a
5FDA: 30 AF       jr   nc,$5FC7
5FDC: D5          push de
5FDD: A9          xor  c
5FDE: D4 A9 D5    call nc,$5D8B
5FE1: A9          xor  c
5FE2: F4 A9 F5    call p,$5F8B
5FE5: A9          xor  c
5FE6: F4 A9 D5    call p,$5D8B
5FE9: A9          xor  c
5FEA: D4 A9 F4    call nc,$5E8B
5FED: A9          xor  c
5FEE: D5          push de
5FEF: A9          xor  c
5FF0: D4 A9 50    call nc,$148B
5FF3: AD          xor  l
5FF4: F5          push af
5FF5: A9          xor  c
5FF6: 10 AD       djnz $5FC3
5FF8: 11 AD 30    ld   de,$12CB
5FFB: AD          xor  l
5FFC: D5          push de
5FFD: A9          xor  c
5FFE: D4 A9 D5    call nc,$5D8B
6001: A9          xor  c
6002: F4 A9 50    call p,$148B
6005: AD          xor  l
6006: F4 A9 D5    call p,$5D8B
6009: A9          xor  c
600A: 51          ld   d,c
600B: BD          cp   l
600C: 30 AD       jr   nc,$5FD9
600E: 31 AD 31    ld   sp,$13CB
6011: AF          xor  a
6012: 30 AF       jr   nc,$5FFF
6014: D5          push de
6015: A9          xor  c
6016: D4 A9 D5    call nc,$5D8B
6019: A9          xor  c
601A: F4 A9 D4    call p,$5C8B
601D: A9          xor  c
601E: D5          push de
601F: A9          xor  c
6020: F4 A9 F5    call p,$5F8B
6023: A9          xor  c
6024: F4 A9 D5    call p,$5D8B
6027: A9          xor  c
6028: D4 A9 50    call nc,$148B
602B: AD          xor  l
602C: F5          push af
602D: A9          xor  c
602E: 10 AD       djnz $5FFB
6030: 11 AD 30    ld   de,$12CB
6033: AD          xor  l
6034: F4 A9 D5    call p,$5D8B
6037: A9          xor  c
6038: D4 A9 D5    call nc,$5D8B
603B: A9          xor  c
603C: D5          push de
603D: A9          xor  c
603E: D4 A9 D5    call nc,$5D8B
6041: A9          xor  c
6042: F4 A9 00    call p,$008B
6045: 00          nop
6046: 2C          inc  l
6047: ED 45       retn
6049: A8          xor  b
604A: 45          ld   b,l
604B: A8          xor  b
604C: 00          nop
604D: 00          nop
604E: AC          xor  h
604F: ED 45       retn
6051: A8          xor  b
6052: 45          ld   b,l
6053: A8          xor  b
6054: 00          nop
6055: 00          nop
6056: 3C          inc  a
6057: ED 45       retn
6059: A8          xor  b
605A: 45          ld   b,l
605B: A8          xor  b
605C: 00          nop
605D: 00          nop
605E: BC          cp   h
605F: ED 45       retn
6061: A8          xor  b
6062: 45          ld   b,l
6063: A8          xor  b
6064: 01 20 00    ld   bc,$0002
6067: 21 60 41    ld   hl,$0506
606A: 60          ld   h,b
606B: 60          ld   h,b
606C: 60          ld   h,b
606D: 61          ld   h,c
606E: 81          add  a,c
606F: 60          ld   h,b
6070: 60          ld   h,b
6071: 60          ld   h,b
6072: 60          ld   h,b
6073: 60          ld   h,b
6074: 60          ld   h,b
6075: 92          sub  d
6076: A1          and  c
6077: 60          ld   h,b
6078: 91          sub  c
6079: C0          ret  nz
607A: 60          ld   h,b
607B: 60          ld   h,b
607C: 60          ld   h,b
607D: C1          pop  bc
607E: 00          nop
607F: E0          ret  po
6080: E1          pop  hl
6081: 33          inc  sp
6082: E3          ex   (sp),hl
6083: 12          ld   (de),a
6084: 00          nop
6085: 10 60       djnz $608D
6087: 30 00       jr   nc,$6089
6089: 21 31 00    ld   hl,$0013
608C: 50          ld   d,b
608D: 60          ld   h,b
608E: 60          ld   h,b
608F: 60          ld   h,b
6090: 51          ld   d,c
6091: 60          ld   h,b
6092: 60          ld   h,b
6093: 70          ld   (hl),b
6094: 71          ld   (hl),c
6095: 60          ld   h,b
6096: 60          ld   h,b
6097: 60          ld   h,b
6098: 60          ld   h,b
6099: 60          ld   h,b
609A: 60          ld   h,b
609B: 90          sub  b
609C: 0E 2F       ld   c,$E3
609E: 2F          cpl
609F: 2F          cpl
60A0: 2E B1       ld   l,$1B
60A2: D0          ret  nc
60A3: 60          ld   h,b
60A4: 00          nop
60A5: 00          nop
60A6: D1          pop  de
60A7: F0          ret  p
60A8: F1          pop  af
60A9: 00          nop
60AA: 02          ld   (bc),a
60AB: 03          inc  bc
60AC: 22 23 60    ld   ($0623),hl
60AF: 60          ld   h,b
60B0: 60          ld   h,b
60B1: 00          nop
60B2: 60          ld   h,b
60B3: 60          ld   h,b
60B4: 60          ld   h,b
60B5: 60          ld   h,b
60B6: 60          ld   h,b
60B7: 60          ld   h,b
60B8: A2          and  d
60B9: 00          nop
60BA: 60          ld   h,b
60BB: 60          ld   h,b
60BC: 60          ld   h,b
60BD: 4E          ld   c,(hl)
60BE: 4E          ld   c,(hl)
60BF: 4F          ld   c,a
60C0: 00          nop
60C1: 00          nop
60C2: 83          add  a,e
60C3: 43          ld   b,e
60C4: C2 C3 60    jp   nz,$062D
60C7: 60          ld   h,b
60C8: 60          ld   h,b
60C9: E2 60 A0    jp   po,$0A06
60CC: 00          nop
60CD: 00          nop
60CE: 60          ld   h,b
60CF: 60          ld   h,b
60D0: 60          ld   h,b
60D1: 13          inc  de
60D2: 60          ld   h,b
60D3: 32 00 00    ld   ($0000),a
60D6: 60          ld   h,b
60D7: 60          ld   h,b
60D8: 60          ld   h,b
60D9: 52          ld   d,d
60DA: 42          ld   b,d
60DB: 53          ld   d,e
60DC: 91          sub  c
60DD: 72          ld   (hl),d
60DE: 60          ld   h,b
60DF: 60          ld   h,b
60E0: 73          ld   (hl),e
60E1: B0          or   b
60E2: 00          nop
60E3: 60          ld   h,b
60E4: 00          nop
60E5: 00          nop
60E6: 00          nop
60E7: F8          ret  m
60E8: F9          ld   sp,hl
60E9: 0A          ld   a,(bc)
60EA: 0B          dec  bc
60EB: 2A 2B 4A    ld   hl,($A4A3)
60EE: 60          ld   h,b
60EF: 6A          ld   l,d
60F0: 6B          ld   l,e
60F1: 60          ld   h,b
60F2: 60          ld   h,b
60F3: 60          ld   h,b
60F4: EB          ex   de,hl
60F5: 60          ld   h,b
60F6: 60          ld   h,b
60F7: 8A          adc  a,d
60F8: 8B          adc  a,e
60F9: AA          xor  d
60FA: 60          ld   h,b
60FB: AB          xor  e
60FC: CA 60 65    jp   z,$4706
60FF: CB 60       bit  4,b
6101: EA 00 00    jp   pe,$0000
6104: 00          nop
6105: 00          nop
6106: 5B          ld   e,e
6107: 7A          ld   a,d
6108: 00          nop
6109: 00          nop
610A: 00          nop
610B: 00          nop
610C: 7B          ld   a,e
610D: 00          nop
610E: 9A          sbc  a,d
610F: 9B          sbc  a,e
6110: BA          cp   d
6111: 00          nop
6112: 00          nop
6113: 00          nop
6114: BB          cp   e
6115: 60          ld   h,b
6116: 60          ld   h,b
6117: 60          ld   h,b
6118: 60          ld   h,b
6119: DA 00 00    jp   c,$0000
611C: DB 60       in   a,($06)
611E: 60          ld   h,b
611F: 60          ld   h,b
6120: 60          ld   h,b
6121: FA 00 00    jp   m,$0000
6124: 00          nop
6125: 00          nop
6126: 00          nop
6127: 00          nop
6128: F2 40 40    jp   p,$0404
612B: F3          di
612C: 04          inc  b
612D: 05          dec  b
612E: 60          ld   h,b
612F: 60          ld   h,b
6130: A0          and  b
6131: 60          ld   h,b
6132: 60          ld   h,b
6133: A0          and  b
6134: 44          ld   b,h
6135: 1A          ld   a,(de)
6136: 60          ld   h,b
6137: 60          ld   h,b
6138: A0          and  b
6139: 60          ld   h,b
613A: 60          ld   h,b
613B: 00          nop
613C: 64          ld   h,h
613D: 00          nop
613E: 60          ld   h,b
613F: 60          ld   h,b
6140: A0          and  b
6141: 00          nop
6142: 00          nop
6143: 00          nop
6144: 00          nop
6145: 00          nop
6146: 00          nop
6147: 00          nop
6148: 00          nop
6149: 00          nop
614A: 00          nop
614B: 00          nop
614C: 00          nop
614D: 00          nop
614E: 00          nop
614F: 00          nop
6150: 00          nop
6151: 00          nop
6152: 00          nop
6153: 00          nop
6154: 00          nop
6155: 00          nop
6156: 00          nop
6157: 00          nop
6158: 00          nop
6159: 00          nop
615A: 00          nop
615B: 00          nop
615C: 00          nop
615D: 00          nop
615E: 00          nop
615F: 00          nop
6160: 00          nop
6161: 00          nop
6162: 00          nop
6163: 00          nop
6164: 00          nop
6165: 00          nop
6166: 7D          ld   a,l
6167: 00          nop
6168: 00          nop
6169: 7D          ld   a,l
616A: 7D          ld   a,l
616B: 67          ld   h,a
616C: 00          nop
616D: DC 23 BD    call c,$DB23
6170: 0F          rrca
6171: 60          ld   h,b
6172: 60          ld   h,b
6173: 86          add  a,(hl)
6174: 00          nop
6175: 23          inc  hl
6176: 23          inc  hl
6177: 23          inc  hl
6178: 60          ld   h,b
6179: 60          ld   h,b
617A: 60          ld   h,b
617B: A6          and  (hl)
617C: 00          nop
617D: BC          cp   h
617E: BC          cp   h
617F: 00          nop
6180: 9D          sbc  a,l
6181: 9D          sbc  a,l
6182: 9D          sbc  a,l
6183: 9C          sbc  a,h
6184: A7          and  a
6185: 23          inc  hl
6186: 23          inc  hl
6187: 23          inc  hl
6188: 23          inc  hl
6189: 23          inc  hl
618A: 23          inc  hl
618B: 23          inc  hl
618C: C6 60       add  a,$06
618E: 60          ld   h,b
618F: 60          ld   h,b
6190: 60          ld   h,b
6191: 60          ld   h,b
6192: 60          ld   h,b
6193: 60          ld   h,b
6194: 60          ld   h,b
6195: 60          ld   h,b
6196: 60          ld   h,b
6197: 60          ld   h,b
6198: 60          ld   h,b
6199: 60          ld   h,b
619A: 60          ld   h,b
619B: 60          ld   h,b
619C: 23          inc  hl
619D: 23          inc  hl
619E: 60          ld   h,b
619F: 60          ld   h,b
61A0: 60          ld   h,b
61A1: 60          ld   h,b
61A2: 00          nop
61A3: 00          nop
61A4: 00          nop
61A5: 00          nop
61A6: 00          nop
61A7: 00          nop
61A8: 00          nop
61A9: 00          nop
61AA: 00          nop
61AB: 00          nop
61AC: 00          nop
61AD: 00          nop
61AE: 00          nop
61AF: 00          nop
61B0: 00          nop
61B1: 00          nop
61B2: 00          nop
61B3: 00          nop
61B4: 00          nop
61B5: 00          nop
61B6: 00          nop
61B7: 00          nop
61B8: 00          nop
61B9: 00          nop
61BA: 00          nop
61BB: 00          nop
61BC: 00          nop
61BD: 00          nop
61BE: 00          nop
61BF: 00          nop
61C0: 00          nop
61C1: 00          nop
61C2: 00          nop
61C3: 00          nop
61C4: 00          nop
61C5: 00          nop
61C6: 00          nop
61C7: 00          nop
61C8: 00          nop
61C9: 00          nop
61CA: 00          nop
61CB: 00          nop
61CC: 00          nop
61CD: 00          nop
61CE: 00          nop
61CF: 00          nop
61D0: 00          nop
61D1: 00          nop
61D2: 00          nop
61D3: 00          nop
61D4: 00          nop
61D5: 00          nop
61D6: 00          nop
61D7: 00          nop
61D8: 00          nop
61D9: 00          nop
61DA: 00          nop
61DB: 00          nop
61DC: 00          nop
61DD: 00          nop
61DE: 00          nop
61DF: 00          nop
61E0: 00          nop
61E1: 00          nop
61E2: 00          nop
61E3: 00          nop
61E4: 60          ld   h,b
61E5: 60          ld   h,b
61E6: 60          ld   h,b
61E7: 60          ld   h,b
61E8: 60          ld   h,b
61E9: 60          ld   h,b
61EA: 60          ld   h,b
61EB: 00          nop
61EC: 60          ld   h,b
61ED: 60          ld   h,b
61EE: 60          ld   h,b
61EF: 60          ld   h,b
61F0: 60          ld   h,b
61F1: 60          ld   h,b
61F2: 60          ld   h,b
61F3: 60          ld   h,b
61F4: 60          ld   h,b
61F5: 60          ld   h,b
61F6: 60          ld   h,b
61F7: 60          ld   h,b
61F8: 60          ld   h,b
61F9: 60          ld   h,b
61FA: 60          ld   h,b
61FB: 60          ld   h,b
61FC: 60          ld   h,b
61FD: 60          ld   h,b
61FE: 60          ld   h,b
61FF: 60          ld   h,b
6200: 60          ld   h,b
6201: 60          ld   h,b
6202: 60          ld   h,b
6203: 60          ld   h,b
6204: 60          ld   h,b
6205: 60          ld   h,b
6206: 60          ld   h,b
6207: 60          ld   h,b
6208: 00          nop
6209: 00          nop
620A: 23          inc  hl
620B: C7          rst  $00
620C: 60          ld   h,b
620D: 60          ld   h,b
620E: 60          ld   h,b
620F: 60          ld   h,b
6210: 00          nop
6211: 00          nop
6212: 60          ld   h,b
6213: 60          ld   h,b
6214: 60          ld   h,b
6215: 60          ld   h,b
6216: 60          ld   h,b
6217: 60          ld   h,b
6218: 00          nop
6219: 00          nop
621A: 60          ld   h,b
621B: 60          ld   h,b
621C: 60          ld   h,b
621D: 60          ld   h,b
621E: 60          ld   h,b
621F: 60          ld   h,b
6220: 00          nop
6221: 00          nop
6222: 60          ld   h,b
6223: 60          ld   h,b
6224: 00          nop
6225: 00          nop
6226: 00          nop
6227: 00          nop
6228: 00          nop
6229: 00          nop
622A: 00          nop
622B: 00          nop
622C: 00          nop
622D: 00          nop
622E: 00          nop
622F: 00          nop
6230: 00          nop
6231: 00          nop
6232: 00          nop
6233: 00          nop
6234: 00          nop
6235: 00          nop
6236: 00          nop
6237: 00          nop
6238: 00          nop
6239: 00          nop
623A: 00          nop
623B: 00          nop
623C: 00          nop
623D: 00          nop
623E: 00          nop
623F: 00          nop
6240: 00          nop
6241: 00          nop
6242: 00          nop
6243: 00          nop
6244: 00          nop
6245: 00          nop
6246: 00          nop
6247: 00          nop
6248: 00          nop
6249: 00          nop
624A: 00          nop
624B: 00          nop
624C: 00          nop
624D: 00          nop
624E: 00          nop
624F: 00          nop
6250: 00          nop
6251: 00          nop
6252: 00          nop
6253: 00          nop
6254: 00          nop
6255: 00          nop
6256: 00          nop
6257: 00          nop
6258: 00          nop
6259: 00          nop
625A: 00          nop
625B: 00          nop
625C: 00          nop
625D: 00          nop
625E: 00          nop
625F: 00          nop
6260: 00          nop
6261: 00          nop
6262: 00          nop
6263: 00          nop
6264: 00          nop
6265: 00          nop
6266: 00          nop
6267: 00          nop
6268: 00          nop
6269: 00          nop
626A: 00          nop
626B: 00          nop
626C: 00          nop
626D: 00          nop
626E: 00          nop
626F: 00          nop
6270: 00          nop
6271: 00          nop
6272: 00          nop
6273: 00          nop
6274: 00          nop
6275: 00          nop
6276: 00          nop
6277: 00          nop
6278: 00          nop
6279: 00          nop
627A: 00          nop
627B: 00          nop
627C: 00          nop
627D: 00          nop
627E: 00          nop
627F: 00          nop
6280: 00          nop
6281: 00          nop
6282: 00          nop
6283: 00          nop
6284: 00          nop
6285: 00          nop
6286: 00          nop
6287: 00          nop
6288: 00          nop
6289: 00          nop
628A: 00          nop
628B: 00          nop
628C: 00          nop
628D: 00          nop
628E: 00          nop
628F: 00          nop
6290: 00          nop
6291: 00          nop
6292: 00          nop
6293: 00          nop
6294: 00          nop
6295: 00          nop
6296: 00          nop
6297: 00          nop
6298: 00          nop
6299: 00          nop
629A: 00          nop
629B: 00          nop
629C: 00          nop
629D: 00          nop
629E: 00          nop
629F: 00          nop
62A0: 00          nop
62A1: 00          nop
62A2: 00          nop
62A3: 00          nop
62A4: 00          nop
62A5: 00          nop
62A6: 00          nop
62A7: 00          nop
62A8: 00          nop
62A9: 00          nop
62AA: 00          nop
62AB: 00          nop
62AC: 00          nop
62AD: A5          and  l
62AE: C4 C5 E4    call nz,$4E4D
62B1: E5          push hl
62B2: 14          inc  d
62B3: 00          nop
62B4: 15          dec  d
62B5: 34          inc  (hl)
62B6: 60          ld   h,b
62B7: A0          and  b
62B8: 54          ld   d,h
62B9: 55          ld   d,l
62BA: 74          ld   (hl),h
62BB: 00          nop
62BC: 75          ld   (hl),l
62BD: 94          sub  h
62BE: 95          sub  l
62BF: B4          or   h
62C0: 00          nop
62C1: 00          nop
62C2: 00          nop
62C3: 00          nop
62C4: 60          ld   h,b
62C5: 60          ld   h,b
62C6: 39          add  hl,sp
62C7: 00          nop
62C8: 00          nop
62C9: 00          nop
62CA: 00          nop
62CB: 00          nop
62CC: 39          add  hl,sp
62CD: 39          add  hl,sp
62CE: 39          add  hl,sp
62CF: 39          add  hl,sp
62D0: 00          nop
62D1: 00          nop
62D2: 00          nop
62D3: 00          nop
62D4: 00          nop
62D5: 00          nop
62D6: 00          nop
62D7: 00          nop
62D8: 00          nop
62D9: 00          nop
62DA: 00          nop
62DB: 00          nop
62DC: 00          nop
62DD: 00          nop
62DE: 00          nop
62DF: 00          nop
62E0: 00          nop
62E1: 3D          dec  a
62E2: 5C          ld   e,h
62E3: 00          nop
62E4: 6F          ld   l,a
62E5: 8E          adc  a,(hl)
62E6: 8F          adc  a,a
62E7: AE          xor  (hl)
62E8: 0F          rrca
62E9: AF          xor  a
62EA: CE CF       adc  a,$ED
62EC: EE EF       xor  $EF
62EE: 1E 1F       ld   e,$F1
62F0: 3E 3F       ld   a,$F3
62F2: 5E          ld   e,(hl)
62F3: 5F          ld   e,a
62F4: 7E          ld   a,(hl)
62F5: 7F          ld   a,a
62F6: 00          nop
62F7: 9E          sbc  a,(hl)
62F8: 00          nop
62F9: BE          cp   (hl)
62FA: 0F          rrca
62FB: E2 0F 0F    jp   po,$E1E1
62FE: 1C          inc  e
62FF: BF          cp   a
6300: DE DF       sbc  a,$FD
6302: 00          nop
6303: 00          nop
6304: 0F          rrca
6305: A3          and  e
6306: 00          nop
6307: 00          nop
6308: 00          nop
6309: 00          nop
630A: 00          nop
630B: 00          nop
630C: 0F          rrca
630D: E2 00 00    jp   po,$0000
6310: 00          nop
6311: 00          nop
6312: 00          nop
6313: 00          nop
6314: 0F          rrca
6315: E2 00 00    jp   po,$0000
6318: 00          nop
6319: 00          nop
631A: 00          nop
631B: 00          nop
631C: 0F          rrca
631D: E2 00 00    jp   po,$0000
6320: 00          nop
6321: 00          nop
6322: 00          nop
6323: 00          nop
6324: 00          nop
6325: 00          nop
6326: 60          ld   h,b
6327: 60          ld   h,b
6328: 60          ld   h,b
6329: 60          ld   h,b
632A: 60          ld   h,b
632B: 00          nop
632C: 00          nop
632D: 00          nop
632E: 60          ld   h,b
632F: 60          ld   h,b
6330: 60          ld   h,b
6331: 60          ld   h,b
6332: 60          ld   h,b
6333: 00          nop
6334: 00          nop
6335: 00          nop
6336: 39          add  hl,sp
6337: 39          add  hl,sp
6338: 39          add  hl,sp
6339: 39          add  hl,sp
633A: 39          add  hl,sp
633B: 00          nop
633C: 00          nop
633D: 00          nop
633E: 00          nop
633F: 00          nop
6340: 00          nop
6341: 00          nop
6342: 00          nop
6343: 00          nop
6344: 00          nop
6345: 00          nop
6346: 00          nop
6347: 00          nop
6348: 00          nop
6349: 00          nop
634A: 00          nop
634B: 00          nop
634C: 00          nop
634D: 00          nop
634E: 00          nop
634F: 00          nop
6350: 00          nop
6351: 00          nop
6352: 00          nop
6353: 00          nop
6354: 00          nop
6355: 00          nop
6356: 00          nop
6357: 00          nop
6358: 00          nop
6359: 00          nop
635A: 00          nop
635B: 00          nop
635C: 00          nop
635D: 00          nop
635E: 00          nop
635F: 00          nop
6360: 00          nop
6361: 00          nop
6362: 00          nop
6363: 00          nop
6364: 60          ld   h,b
6365: 60          ld   h,b
6366: 61          ld   h,c
6367: 60          ld   h,b
6368: 60          ld   h,b
6369: 60          ld   h,b
636A: 60          ld   h,b
636B: 60          ld   h,b
636C: 60          ld   h,b
636D: 60          ld   h,b
636E: 00          nop
636F: 60          ld   h,b
6370: 60          ld   h,b
6371: 60          ld   h,b
6372: 61          ld   h,c
6373: 00          nop
6374: AD          xor  l
6375: 22 22 22    ld   ($2222),hl
6378: 00          nop
6379: 00          nop
637A: 61          ld   h,c
637B: 00          nop
637C: 60          ld   h,b
637D: 60          ld   h,b
637E: 60          ld   h,b
637F: E2 F4 F5    jp   po,$5F5E
6382: 61          ld   h,c
6383: 00          nop
6384: 60          ld   h,b
6385: 60          ld   h,b
6386: 92          sub  d
6387: 60          ld   h,b
6388: 60          ld   h,b
6389: 60          ld   h,b
638A: 60          ld   h,b
638B: 60          ld   h,b
638C: 60          ld   h,b
638D: 60          ld   h,b
638E: 00          nop
638F: 60          ld   h,b
6390: 60          ld   h,b
6391: 60          ld   h,b
6392: 61          ld   h,c
6393: 00          nop
6394: 60          ld   h,b
6395: 60          ld   h,b
6396: 60          ld   h,b
6397: E2 06 07    jp   po,$6160
639A: 27          daa
639B: 46          ld   b,(hl)
639C: F4 F5 47    call p,$655F
639F: 00          nop
63A0: 06 07       ld   b,$61
63A2: 27          daa
63A3: 46          ld   b,(hl)
63A4: AD          xor  l
63A5: 22 22 22    ld   ($2222),hl
63A8: 00          nop
63A9: 00          nop
63AA: 00          nop
63AB: 00          nop
63AC: 00          nop
63AD: 00          nop
63AE: 00          nop
63AF: 00          nop
63B0: 00          nop
63B1: 00          nop
63B2: 00          nop
63B3: 00          nop
63B4: 00          nop
63B5: 00          nop
63B6: 00          nop
63B7: 00          nop
63B8: 00          nop
63B9: CD CD CD    call $CDCD
63BC: ED          db   $ed
63BD: ED          db   $ed
63BE: ED          db   $ed
63BF: 00          nop
63C0: 00          nop
63C1: EC EC EC    call pe,$CECE
63C4: 00          nop
63C5: 00          nop
63C6: 00          nop
63C7: 00          nop
63C8: 00          nop
63C9: 00          nop
63CA: 00          nop
63CB: 00          nop
63CC: ED          db   $ed
63CD: 00          nop
63CE: 00          nop
63CF: 00          nop
63D0: 00          nop
63D1: 00          nop
63D2: 00          nop
63D3: 00          nop
63D4: 00          nop
63D5: 00          nop
63D6: 00          nop
63D7: 00          nop
63D8: 00          nop
63D9: 00          nop
63DA: 00          nop
63DB: 00          nop
63DC: 62          ld   h,d
63DD: 60          ld   h,b
63DE: 93          sub  e
63DF: 82          add  a,d
63E0: 00          nop
63E1: 00          nop
63E2: 00          nop
63E3: 00          nop
63E4: 60          ld   h,b
63E5: 60          ld   h,b
63E6: 24          inc  h
63E7: 25          dec  h
63E8: 00          nop
63E9: 00          nop
63EA: 00          nop
63EB: 00          nop
63EC: 60          ld   h,b
63ED: 60          ld   h,b
63EE: 60          ld   h,b
63EF: 60          ld   h,b
63F0: 60          ld   h,b
63F1: 00          nop
63F2: 00          nop
63F3: 00          nop
63F4: 60          ld   h,b
63F5: 60          ld   h,b
63F6: 60          ld   h,b
63F7: 45          ld   b,l
63F8: 24          inc  h
63F9: 00          nop
63FA: 60          ld   h,b
63FB: 60          ld   h,b
63FC: 84          add  a,h
63FD: 60          ld   h,b
63FE: A4          and  h
63FF: 24          inc  h
6400: 25          dec  h
6401: 00          nop
6402: 60          ld   h,b
6403: 60          ld   h,b
6404: B3          or   e
6405: 85          add  a,l
6406: 35          dec  (hl)
6407: 60          ld   h,b
6408: 60          ld   h,b
6409: 60          ld   h,b
640A: D5          push de
640B: 45          ld   b,l
640C: 60          ld   h,b
640D: 60          ld   h,b
640E: 26 60       ld   h,$06
6410: 60          ld   h,b
6411: 60          ld   h,b
6412: 24          inc  h
6413: A4          and  h
6414: 60          ld   h,b
6415: 60          ld   h,b
6416: 87          add  a,a
6417: 60          ld   h,b
6418: 60          ld   h,b
6419: 60          ld   h,b
641A: 25          dec  h
641B: 60          ld   h,b
641C: 60          ld   h,b
641D: 60          ld   h,b
641E: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
641F: B7          or   a
6420: D6 D6       sub  $7C
6422: 60          ld   h,b
6423: 84          add  a,h
6424: 00          nop
6425: 00          nop
6426: 00          nop
6427: 00          nop
6428: 00          nop
6429: 00          nop
642A: 00          nop
642B: 00          nop
642C: 00          nop
642D: 00          nop
642E: 00          nop
642F: 00          nop
6430: 00          nop
6431: 00          nop
6432: 00          nop
6433: 00          nop
6434: 00          nop
6435: 00          nop
6436: 00          nop
6437: 00          nop
6438: 00          nop
6439: 00          nop
643A: 00          nop
643B: 00          nop
643C: 00          nop
643D: 00          nop
643E: 00          nop
643F: 00          nop
6440: 00          nop
6441: 00          nop
6442: 00          nop
6443: 00          nop
6444: 00          nop
6445: 00          nop
6446: 00          nop
6447: 00          nop
6448: 00          nop
6449: 00          nop
644A: 00          nop
644B: 00          nop
644C: 00          nop
644D: 00          nop
644E: 00          nop
644F: 00          nop
6450: 00          nop
6451: 00          nop
6452: 00          nop
6453: 00          nop
6454: 00          nop
6455: 00          nop
6456: 00          nop
6457: 00          nop
6458: 00          nop
6459: 00          nop
645A: 00          nop
645B: 00          nop
645C: 00          nop
645D: 00          nop
645E: 00          nop
645F: 00          nop
6460: 00          nop
6461: 00          nop
6462: 00          nop
6463: 00          nop
6464: 00          nop
6465: 00          nop
6466: 00          nop
6467: 00          nop
6468: 00          nop
6469: 00          nop
646A: 00          nop
646B: 00          nop
646C: F1          pop  af
646D: F1          pop  af
646E: F1          pop  af
646F: F1          pop  af
6470: F1          pop  af
6471: F1          pop  af
6472: F1          pop  af
6473: F1          pop  af
6474: 0C          inc  c
6475: 0C          inc  c
6476: 0C          inc  c
6477: 0C          inc  c
6478: 0C          inc  c
6479: 0C          inc  c
647A: 0C          inc  c
647B: 0C          inc  c
647C: 00          nop
647D: F3          di
647E: FF          rst  $38
647F: FF          rst  $38
6480: FF          rst  $38
6481: FF          rst  $38
6482: FF          rst  $38
6483: FF          rst  $38
6484: 00          nop
6485: FF          rst  $38
6486: FF          rst  $38
6487: FF          rst  $38
6488: FF          rst  $38
6489: FF          rst  $38
648A: FF          rst  $38
648B: FF          rst  $38
648C: 00          nop
648D: 21 61 E1    ld   hl,$0F07
6490: F3          di
6491: FF          rst  $38
6492: FF          rst  $38
6493: FF          rst  $38
6494: FF          rst  $38
6495: FF          rst  $38
6496: FF          rst  $38
6497: FF          rst  $38
6498: FF          rst  $38
6499: FF          rst  $38
649A: FF          rst  $38
649B: FF          rst  $38
649C: 9E          sbc  a,(hl)
649D: 9E          sbc  a,(hl)
649E: 9E          sbc  a,(hl)
649F: 9E          sbc  a,(hl)
64A0: 9E          sbc  a,(hl)
64A1: 9E          sbc  a,(hl)
64A2: 9E          sbc  a,(hl)
64A3: 9E          sbc  a,(hl)
64A4: F7          rst  $30
64A5: F7          rst  $30
64A6: F7          rst  $30
64A7: F7          rst  $30
64A8: F7          rst  $30
64A9: F7          rst  $30
64AA: F7          rst  $30
64AB: F1          pop  af
64AC: F1          pop  af
64AD: F1          pop  af
64AE: FF          rst  $38
64AF: FF          rst  $38
64B0: FF          rst  $38
64B1: FF          rst  $38
64B2: FF          rst  $38
64B3: FF          rst  $38
64B4: DE DE       sbc  a,$FC
64B6: DE DE       sbc  a,$FC
64B8: DE DE       sbc  a,$FC
64BA: DE DE       sbc  a,$FC
64BC: F7          rst  $30
64BD: F7          rst  $30
64BE: F7          rst  $30
64BF: E3          ex   (sp),hl
64C0: F1          pop  af
64C1: F1          pop  af
64C2: F1          pop  af
64C3: E1          pop  hl
64C4: F7          rst  $30
64C5: F3          di
64C6: F3          di
64C7: F3          di
64C8: F3          di
64C9: F3          di
64CA: F3          di
64CB: F3          di
64CC: FE FE       cp   $FE
64CE: FE FE       cp   $FE
64D0: DE 1E       sbc  a,$F0
64D2: 0C          inc  c
64D3: 0C          inc  c
64D4: FF          rst  $38
64D5: FF          rst  $38
64D6: FF          rst  $38
64D7: FF          rst  $38
64D8: FF          rst  $38
64D9: F1          pop  af
64DA: 00          nop
64DB: 00          nop
64DC: FF          rst  $38
64DD: FF          rst  $38
64DE: FF          rst  $38
64DF: FF          rst  $38
64E0: FF          rst  $38
64E1: 9E          sbc  a,(hl)
64E2: 1E 00       ld   e,$00
64E4: 00          nop
64E5: E1          pop  hl
64E6: F3          di
64E7: FF          rst  $38
64E8: FF          rst  $38
64E9: FF          rst  $38
64EA: FF          rst  $38
64EB: FF          rst  $38
64EC: 0C          inc  c
64ED: 0C          inc  c
64EE: 0C          inc  c
64EF: 0C          inc  c
64F0: 08          ex   af,af'
64F1: 08          ex   af,af'
64F2: 00          nop
64F3: 00          nop
64F4: 0E 1E       ld   c,$F0
64F6: DE FF       sbc  a,$FF
64F8: FF          rst  $38
64F9: FF          rst  $38
64FA: FF          rst  $38
64FB: FF          rst  $38
64FC: 00          nop
64FD: 00          nop
64FE: 08          ex   af,af'
64FF: 0E DE       ld   c,$FC
6501: FF          rst  $38
6502: FF          rst  $38
6503: FF          rst  $38
6504: F1          pop  af
6505: F1          pop  af
6506: F1          pop  af
6507: F3          di
6508: F3          di
6509: F3          di
650A: F3          di
650B: F3          di
650C: DE DE       sbc  a,$FC
650E: FF          rst  $38
650F: FF          rst  $38
6510: FF          rst  $38
6511: FF          rst  $38
6512: FF          rst  $38
6513: FF          rst  $38
6514: 0C          inc  c
6515: 0E 1E       ld   c,$F0
6517: 1E 1E       ld   e,$F0
6519: 9E          sbc  a,(hl)
651A: DE FE       sbc  a,$FE
651C: F1          pop  af
651D: 61          ld   h,c
651E: 21 61 61    ld   hl,$0707
6521: 61          ld   h,c
6522: 61          ld   h,c
6523: 61          ld   h,c
6524: FF          rst  $38
6525: FF          rst  $38
6526: FF          rst  $38
6527: FF          rst  $38
6528: FF          rst  $38
6529: FF          rst  $38
652A: DE 9E       sbc  a,$F8
652C: FF          rst  $38
652D: FF          rst  $38
652E: FF          rst  $38
652F: FF          rst  $38
6530: FF          rst  $38
6531: DE DE       sbc  a,$FC
6533: DE 1E       sbc  a,$F0
6535: 0E 0C       ld   c,$C0
6537: 08          ex   af,af'
6538: 00          nop
6539: 00          nop
653A: 00          nop
653B: 00          nop
653C: FF          rst  $38
653D: FF          rst  $38
653E: FF          rst  $38
653F: FF          rst  $38
6540: FF          rst  $38
6541: FF          rst  $38
6542: FF          rst  $38
6543: 1E FF       ld   e,$FF
6545: FF          rst  $38
6546: FF          rst  $38
6547: FF          rst  $38
6548: DE 1E       sbc  a,$F0
654A: 00          nop
654B: 00          nop
654C: 00          nop
654D: 00          nop
654E: 00          nop
654F: F3          di
6550: F7          rst  $30
6551: FF          rst  $38
6552: FF          rst  $38
6553: FF          rst  $38
6554: 00          nop
6555: F3          di
6556: FF          rst  $38
6557: FF          rst  $38
6558: FF          rst  $38
6559: FF          rst  $38
655A: FF          rst  $38
655B: FF          rst  $38
655C: 00          nop
655D: 0C          inc  c
655E: 1E 1E       ld   e,$F0
6560: FE FF       cp   $FF
6562: FF          rst  $38
6563: FF          rst  $38
6564: E1          pop  hl
6565: F3          di
6566: F7          rst  $30
6567: FF          rst  $38
6568: FF          rst  $38
6569: FF          rst  $38
656A: FF          rst  $38
656B: FF          rst  $38
656C: 0E 1E       ld   c,$F0
656E: FF          rst  $38
656F: FF          rst  $38
6570: FF          rst  $38
6571: FF          rst  $38
6572: FF          rst  $38
6573: FF          rst  $38
6574: 00          nop
6575: 00          nop
6576: 00          nop
6577: FF          rst  $38
6578: FF          rst  $38
6579: FF          rst  $38
657A: FF          rst  $38
657B: FF          rst  $38
657C: 00          nop
657D: 00          nop
657E: FF          rst  $38
657F: FF          rst  $38
6580: FF          rst  $38
6581: FF          rst  $38
6582: FF          rst  $38
6583: FF          rst  $38
6584: FE FE       cp   $FE
6586: FE FE       cp   $FE
6588: DE DE       sbc  a,$FC
658A: DE 9E       sbc  a,$F8
658C: FF          rst  $38
658D: FF          rst  $38
658E: FF          rst  $38
658F: FF          rst  $38
6590: FF          rst  $38
6591: 00          nop
6592: 00          nop
6593: 00          nop
6594: FF          rst  $38
6595: FF          rst  $38
6596: FF          rst  $38
6597: FF          rst  $38
6598: FF          rst  $38
6599: F3          di
659A: 61          ld   h,c
659B: 00          nop
659C: 00          nop
659D: 00          nop
659E: 00          nop
659F: 00          nop
65A0: 00          nop
65A1: 00          nop
65A2: 00          nop
65A3: 00          nop
65A4: F3          di
65A5: F3          di
65A6: F3          di
65A7: F3          di
65A8: F1          pop  af
65A9: E1          pop  hl
65AA: 61          ld   h,c
65AB: 00          nop
65AC: F7          rst  $30
65AD: F3          di
65AE: F1          pop  af
65AF: F1          pop  af
65B0: E1          pop  hl
65B1: 00          nop
65B2: 00          nop
65B3: 00          nop
65B4: 01 21 21    ld   bc,$0303
65B7: 61          ld   h,c
65B8: 61          ld   h,c
65B9: E1          pop  hl
65BA: E1          pop  hl
65BB: F1          pop  af
65BC: 00          nop
65BD: 0E 0E       ld   c,$E0
65BF: 0E 0E       ld   c,$E0
65C1: 0E 0E       ld   c,$E0
65C3: 0E F1       ld   c,$1F
65C5: F1          pop  af
65C6: F1          pop  af
65C7: FF          rst  $38
65C8: FF          rst  $38
65C9: FF          rst  $38
65CA: FF          rst  $38
65CB: FF          rst  $38
65CC: 00          nop
65CD: 0E 9E       ld   c,$F8
65CF: 9E          sbc  a,(hl)
65D0: 9E          sbc  a,(hl)
65D1: 9E          sbc  a,(hl)
65D2: 9E          sbc  a,(hl)
65D3: 9E          sbc  a,(hl)
65D4: 0E 0E       ld   c,$E0
65D6: 0E 0E       ld   c,$E0
65D8: 0E 0E       ld   c,$E0
65DA: 0E 0E       ld   c,$E0
65DC: FF          rst  $38
65DD: FF          rst  $38
65DE: FF          rst  $38
65DF: F7          rst  $30
65E0: F3          di
65E1: F1          pop  af
65E2: E1          pop  hl
65E3: 00          nop
65E4: FF          rst  $38
65E5: FF          rst  $38
65E6: FF          rst  $38
65E7: FF          rst  $38
65E8: FF          rst  $38
65E9: DE 9E       sbc  a,$F8
65EB: 00          nop
65EC: 9E          sbc  a,(hl)
65ED: DE DE       sbc  a,$FC
65EF: DE DE       sbc  a,$FC
65F1: FE FE       cp   $FE
65F3: FE DE       cp   $FC
65F5: DE DE       sbc  a,$FC
65F7: DE DE       sbc  a,$FC
65F9: 9E          sbc  a,(hl)
65FA: 1E 0E       ld   e,$E0
65FC: F7          rst  $30
65FD: F3          di
65FE: F1          pop  af
65FF: 00          nop
6600: 00          nop
6601: 00          nop
6602: 00          nop
6603: 00          nop
6604: 9E          sbc  a,(hl)
6605: 9E          sbc  a,(hl)
6606: 9E          sbc  a,(hl)
6607: DE DE       sbc  a,$FC
6609: DE 9E       sbc  a,$F8
660B: 1E 00       ld   e,$00
660D: 00          nop
660E: DE FE       sbc  a,$FE
6610: FF          rst  $38
6611: FF          rst  $38
6612: FF          rst  $38
6613: FF          rst  $38
6614: 00          nop
6615: 1E FE       ld   e,$FE
6617: FF          rst  $38
6618: FF          rst  $38
6619: FF          rst  $38
661A: FF          rst  $38
661B: FF          rst  $38
661C: FF          rst  $38
661D: FF          rst  $38
661E: FF          rst  $38
661F: FF          rst  $38
6620: FF          rst  $38
6621: DE 9E       sbc  a,$F8
6623: 0E FE       ld   c,$FE
6625: FE FE       cp   $FE
6627: FE FE       cp   $FE
6629: FE FE       cp   $FE
662B: FE F3       cp   $3F
662D: F3          di
662E: FF          rst  $38
662F: FF          rst  $38
6630: FF          rst  $38
6631: FF          rst  $38
6632: FF          rst  $38
6633: FF          rst  $38
6634: 21 21 21    ld   hl,$0303
6637: 21 21 21    ld   hl,$0303
663A: 21 21 00    ld   hl,$0003
663D: 00          nop
663E: 00          nop
663F: 21 E1 F3    ld   hl,$3F0F
6642: FF          rst  $38
6643: FF          rst  $38
6644: 00          nop
6645: 00          nop
6646: 00          nop
6647: 00          nop
6648: 00          nop
6649: 00          nop
664A: 00          nop
664B: 00          nop
664C: 00          nop
664D: 00          nop
664E: 00          nop
664F: 00          nop
6650: 00          nop
6651: 00          nop
6652: 00          nop
6653: 00          nop
6654: 00          nop
6655: F7          rst  $30
6656: F7          rst  $30
6657: FF          rst  $38
6658: FF          rst  $38
6659: FF          rst  $38
665A: FF          rst  $38
665B: FF          rst  $38
665C: 00          nop
665D: 08          ex   af,af'
665E: 0C          inc  c
665F: 0C          inc  c
6660: 0C          inc  c
6661: 0E 0E       ld   c,$E0
6663: 0E 00       ld   c,$00
6665: 00          nop
6666: 12          ld   (de),a
6667: 96          sub  (hl)
6668: FE FF       cp   $FF
666A: FF          rst  $38
666B: FF          rst  $38
666C: 08          ex   af,af'
666D: 0C          inc  c
666E: 0E 0E       ld   c,$E0
6670: 00          nop
6671: 00          nop
6672: 00          nop
6673: 00          nop
6674: 00          nop
6675: 0C          inc  c
6676: 1E DE       ld   e,$FC
6678: FF          rst  $38
6679: FF          rst  $38
667A: FF          rst  $38
667B: FF          rst  $38
667C: 00          nop
667D: 00          nop
667E: 00          nop
667F: 00          nop
6680: 00          nop
6681: 0C          inc  c
6682: 1E DE       ld   e,$FC
6684: 00          nop
6685: 01 21 21    ld   bc,$0303
6688: 21 E1 E1    ld   hl,$0F0F
668B: E1          pop  hl
668C: FF          rst  $38
668D: FF          rst  $38
668E: FF          rst  $38
668F: FE DE       cp   $FC
6691: 9E          sbc  a,(hl)
6692: 0E 08       ld   c,$80
6694: F3          di
6695: F6 F6       or   $7E
6697: F6 F6       or   $7E
6699: F6 F7       or   $7F
669B: 61          ld   h,c
669C: FF          rst  $38
669D: FF          rst  $38
669E: FF          rst  $38
669F: FF          rst  $38
66A0: FF          rst  $38
66A1: FF          rst  $38
66A2: FF          rst  $38
66A3: DE FF       sbc  a,$FF
66A5: FF          rst  $38
66A6: FF          rst  $38
66A7: F7          rst  $30
66A8: F3          di
66A9: 61          ld   h,c
66AA: 21 00 F1    ld   hl,$1F00
66AD: F3          di
66AE: FF          rst  $38
66AF: FF          rst  $38
66B0: FF          rst  $38
66B1: FF          rst  $38
66B2: FF          rst  $38
66B3: FF          rst  $38
66B4: FF          rst  $38
66B5: FE DE       cp   $FC
66B7: 9E          sbc  a,(hl)
66B8: 9E          sbc  a,(hl)
66B9: 1E 0E       ld   e,$E0
66BB: 0C          inc  c
66BC: 00          nop
66BD: 00          nop
66BE: 00          nop
66BF: 00          nop
66C0: 00          nop
66C1: 00          nop
66C2: 21 E1 00    ld   hl,$000F
66C5: 00          nop
66C6: 00          nop
66C7: 21 F3 FF    ld   hl,$FF3F
66CA: FF          rst  $38
66CB: FF          rst  $38
66CC: 00          nop
66CD: 00          nop
66CE: 00          nop
66CF: 0E 0E       ld   c,$E0
66D1: 0E 9E       ld   c,$F8
66D3: DE D6       sbc  a,$7C
66D5: FE FE       cp   $FE
66D7: FF          rst  $38
66D8: FF          rst  $38
66D9: FF          rst  $38
66DA: FF          rst  $38
66DB: F7          rst  $30
66DC: 00          nop
66DD: 00          nop
66DE: 00          nop
66DF: 61          ld   h,c
66E0: E9          jp   (hl)
66E1: ED          db   $ed
66E2: FF          rst  $38
66E3: FF          rst  $38
66E4: 00          nop
66E5: 00          nop
66E6: 00          nop
66E7: 08          ex   af,af'
66E8: 0C          inc  c
66E9: 0E 0E       ld   c,$E0
66EB: 0E 00       ld   c,$00
66ED: 00          nop
66EE: 00          nop
66EF: 00          nop
66F0: 01 61 E1    ld   bc,$0F07
66F3: F1          pop  af
66F4: F3          di
66F5: F3          di
66F6: F3          di
66F7: FF          rst  $38
66F8: FF          rst  $38
66F9: FF          rst  $38
66FA: FF          rst  $38
66FB: FF          rst  $38
66FC: FF          rst  $38
66FD: FF          rst  $38
66FE: FF          rst  $38
66FF: FF          rst  $38
6700: FF          rst  $38
6701: FE DE       cp   $FC
6703: 9E          sbc  a,(hl)
6704: E1          pop  hl
6705: 61          ld   h,c
6706: 01 00 00    ld   bc,$0000
6709: 00          nop
670A: 00          nop
670B: 00          nop
670C: FF          rst  $38
670D: FF          rst  $38
670E: FF          rst  $38
670F: F7          rst  $30
6710: F1          pop  af
6711: 00          nop
6712: 00          nop
6713: 00          nop
6714: 1E 1E       ld   e,$F0
6716: 1E 0E       ld   e,$E0
6718: 0C          inc  c
6719: 00          nop
671A: 00          nop
671B: 00          nop
671C: F1          pop  af
671D: F1          pop  af
671E: F1          pop  af
671F: F1          pop  af
6720: F1          pop  af
6721: F1          pop  af
6722: C0          ret  nz
6723: 00          nop
6724: FF          rst  $38
6725: FF          rst  $38
6726: FE 1E       cp   $F0
6728: 0C          inc  c
6729: 00          nop
672A: 00          nop
672B: 00          nop
672C: FF          rst  $38
672D: FF          rst  $38
672E: F3          di
672F: E1          pop  hl
6730: 21 00 00    ld   hl,$0000
6733: 00          nop
6734: 9E          sbc  a,(hl)
6735: 9E          sbc  a,(hl)
6736: 1E 0E       ld   e,$E0
6738: 00          nop
6739: 00          nop
673A: 00          nop
673B: 00          nop
673C: 00          nop
673D: 00          nop
673E: 00          nop
673F: 00          nop
6740: 00          nop
6741: 00          nop
6742: 00          nop
6743: 00          nop
6744: 00          nop
6745: 00          nop
6746: 00          nop
6747: 00          nop
6748: 00          nop
6749: 00          nop
674A: 00          nop
674B: 00          nop
674C: 00          nop
674D: 00          nop
674E: 00          nop
674F: 00          nop
6750: 0C          inc  c
6751: 1E DE       ld   e,$FC
6753: FF          rst  $38
6754: FF          rst  $38
6755: FF          rst  $38
6756: FF          rst  $38
6757: F7          rst  $30
6758: F1          pop  af
6759: 61          ld   h,c
675A: 01 00 FF    ld   bc,$FF00
675D: FF          rst  $38
675E: FF          rst  $38
675F: FF          rst  $38
6760: FF          rst  $38
6761: FF          rst  $38
6762: FF          rst  $38
6763: F7          rst  $30
6764: 00          nop
6765: 00          nop
6766: 21 E1 F3    ld   hl,$3F0F
6769: FF          rst  $38
676A: FF          rst  $38
676B: FF          rst  $38
676C: F1          pop  af
676D: FF          rst  $38
676E: FF          rst  $38
676F: FF          rst  $38
6770: FF          rst  $38
6771: FF          rst  $38
6772: FF          rst  $38
6773: FF          rst  $38
6774: 9E          sbc  a,(hl)
6775: 1E 0E       ld   e,$E0
6777: 0C          inc  c
6778: 08          ex   af,af'
6779: 00          nop
677A: 00          nop
677B: 00          nop
677C: 00          nop
677D: 0E 9E       ld   c,$F8
677F: FE FF       cp   $FF
6781: FF          rst  $38
6782: FF          rst  $38
6783: FF          rst  $38
6784: 00          nop
6785: 00          nop
6786: 00          nop
6787: 00          nop
6788: 08          ex   af,af'
6789: 08          ex   af,af'
678A: 08          ex   af,af'
678B: 08          ex   af,af'
678C: FF          rst  $38
678D: FF          rst  $38
678E: FF          rst  $38
678F: FE DE       cp   $FC
6791: 9E          sbc  a,(hl)
6792: 1E 0E       ld   e,$E0
6794: 1E 1E       ld   e,$F0
6796: 1E 1E       ld   e,$F0
6798: 1E 1E       ld   e,$F0
679A: 1E 1E       ld   e,$F0
679C: F7          rst  $30
679D: F7          rst  $30
679E: F7          rst  $30
679F: F7          rst  $30
67A0: F3          di
67A1: F3          di
67A2: F3          di
67A3: F3          di
67A4: FE FE       cp   $FE
67A6: FE FE       cp   $FE
67A8: DE DE       sbc  a,$FC
67AA: DE DE       sbc  a,$FC
67AC: 0C          inc  c
67AD: 0C          inc  c
67AE: 0C          inc  c
67AF: 0E 0E       ld   c,$E0
67B1: 1E 9E       ld   e,$F8
67B3: DE FF       sbc  a,$FF
67B5: FF          rst  $38
67B6: FF          rst  $38
67B7: FF          rst  $38
67B8: FE FE       cp   $FE
67BA: FE FE       cp   $FE
67BC: 00          nop
67BD: 00          nop
67BE: F3          di
67BF: F3          di
67C0: F3          di
67C1: F3          di
67C2: F7          rst  $30
67C3: F7          rst  $30
67C4: F7          rst  $30
67C5: F7          rst  $30
67C6: FF          rst  $38
67C7: FF          rst  $38
67C8: FF          rst  $38
67C9: FF          rst  $38
67CA: FF          rst  $38
67CB: FF          rst  $38
67CC: 61          ld   h,c
67CD: 61          ld   h,c
67CE: FF          rst  $38
67CF: FF          rst  $38
67D0: FF          rst  $38
67D1: FF          rst  $38
67D2: FF          rst  $38
67D3: FF          rst  $38
67D4: 00          nop
67D5: 00          nop
67D6: 00          nop
67D7: 00          nop
67D8: 00          nop
67D9: 00          nop
67DA: 00          nop
67DB: 00          nop
67DC: 9E          sbc  a,(hl)
67DD: DE DE       sbc  a,$FC
67DF: DE FE       sbc  a,$FE
67E1: FE FF       cp   $FF
67E3: FF          rst  $38
67E4: 00          nop
67E5: 00          nop
67E6: 00          nop
67E7: 00          nop
67E8: 00          nop
67E9: 00          nop
67EA: 00          nop
67EB: 00          nop
67EC: 00          nop
67ED: 00          nop
67EE: 00          nop
67EF: 00          nop
67F0: 00          nop
67F1: 00          nop
67F2: 00          nop
67F3: 00          nop
67F4: 00          nop
67F5: 00          nop
67F6: 00          nop
67F7: 00          nop
67F8: 00          nop
67F9: 00          nop
67FA: 00          nop
67FB: 00          nop
67FC: 00          nop
67FD: 00          nop
67FE: 00          nop
67FF: 00          nop
6800: 00          nop
6801: 00          nop
6802: 00          nop
6803: 00          nop
6804: 00          nop
6805: 00          nop
6806: 00          nop
6807: 00          nop
6808: 00          nop
6809: 00          nop
680A: 00          nop
680B: 00          nop
680C: 00          nop
680D: 00          nop
680E: 00          nop
680F: 00          nop
6810: 00          nop
6811: 00          nop
6812: 00          nop
6813: 00          nop
6814: 00          nop
6815: 00          nop
6816: 00          nop
6817: 00          nop
6818: 00          nop
6819: 00          nop
681A: 00          nop
681B: 00          nop
681C: 00          nop
681D: 00          nop
681E: 00          nop
681F: 00          nop
6820: 00          nop
6821: 00          nop
6822: 00          nop
6823: 00          nop
6824: 00          nop
6825: 00          nop
6826: 00          nop
6827: 00          nop
6828: 00          nop
6829: 00          nop
682A: 00          nop
682B: 00          nop
682C: 00          nop
682D: 00          nop
682E: 00          nop
682F: 00          nop
6830: 00          nop
6831: 00          nop
6832: 00          nop
6833: 00          nop
6834: 00          nop
6835: 00          nop
6836: 00          nop
6837: 00          nop
6838: 00          nop
6839: 00          nop
683A: 00          nop
683B: 00          nop
683C: FF          rst  $38
683D: FF          rst  $38
683E: F3          di
683F: F1          pop  af
6840: E1          pop  hl
6841: 61          ld   h,c
6842: 21 00 FF    ld   hl,$FF00
6845: FF          rst  $38
6846: FF          rst  $38
6847: FF          rst  $38
6848: FF          rst  $38
6849: FF          rst  $38
684A: FF          rst  $38
684B: 00          nop
684C: 00          nop
684D: 00          nop
684E: 00          nop
684F: 00          nop
6850: 00          nop
6851: 00          nop
6852: 00          nop
6853: 00          nop
6854: 00          nop
6855: 00          nop
6856: 00          nop
6857: 00          nop
6858: 00          nop
6859: 00          nop
685A: 00          nop
685B: 00          nop
685C: 00          nop
685D: 00          nop
685E: 00          nop
685F: 00          nop
6860: 00          nop
6861: 00          nop
6862: 00          nop
6863: 00          nop
6864: 00          nop
6865: 00          nop
6866: 00          nop
6867: 00          nop
6868: 00          nop
6869: 00          nop
686A: 00          nop
686B: 00          nop
686C: 00          nop
686D: 00          nop
686E: 00          nop
686F: 00          nop
6870: 00          nop
6871: 00          nop
6872: 00          nop
6873: 00          nop
6874: 00          nop
6875: 00          nop
6876: 00          nop
6877: 00          nop
6878: 00          nop
6879: 00          nop
687A: 00          nop
687B: 00          nop
687C: 00          nop
687D: 00          nop
687E: 00          nop
687F: 00          nop
6880: 00          nop
6881: 00          nop
6882: 00          nop
6883: 00          nop
6884: 00          nop
6885: 00          nop
6886: 00          nop
6887: 00          nop
6888: 00          nop
6889: 00          nop
688A: 00          nop
688B: 00          nop
688C: 00          nop
688D: 00          nop
688E: 00          nop
688F: 00          nop
6890: 00          nop
6891: 00          nop
6892: 00          nop
6893: 00          nop
6894: 00          nop
6895: 00          nop
6896: 00          nop
6897: 00          nop
6898: 00          nop
6899: 00          nop
689A: 00          nop
689B: 00          nop
689C: 00          nop
689D: 21 E1 F3    ld   hl,$3F0F
68A0: FF          rst  $38
68A1: FF          rst  $38
68A2: FF          rst  $38
68A3: FF          rst  $38
68A4: 00          nop
68A5: 00          nop
68A6: 00          nop
68A7: 00          nop
68A8: 00          nop
68A9: 00          nop
68AA: 00          nop
68AB: 00          nop
68AC: 00          nop
68AD: 00          nop
68AE: 00          nop
68AF: 00          nop
68B0: 00          nop
68B1: 00          nop
68B2: 00          nop
68B3: 00          nop
68B4: 00          nop
68B5: 00          nop
68B6: 00          nop
68B7: 00          nop
68B8: 00          nop
68B9: 00          nop
68BA: 00          nop
68BB: 00          nop
68BC: 00          nop
68BD: 00          nop
68BE: 00          nop
68BF: 00          nop
68C0: 00          nop
68C1: 00          nop
68C2: 00          nop
68C3: 00          nop
68C4: 00          nop
68C5: 00          nop
68C6: 00          nop
68C7: 00          nop
68C8: 00          nop
68C9: 00          nop
68CA: 00          nop
68CB: 00          nop
68CC: 00          nop
68CD: 00          nop
68CE: 00          nop
68CF: 00          nop
68D0: 00          nop
68D1: 00          nop
68D2: 00          nop
68D3: 00          nop
68D4: 00          nop
68D5: 00          nop
68D6: 00          nop
68D7: 00          nop
68D8: 00          nop
68D9: 00          nop
68DA: 00          nop
68DB: 00          nop
68DC: 00          nop
68DD: 00          nop
68DE: 00          nop
68DF: 00          nop
68E0: 00          nop
68E1: 00          nop
68E2: 00          nop
68E3: 00          nop
68E4: 00          nop
68E5: 00          nop
68E6: 00          nop
68E7: 00          nop
68E8: 00          nop
68E9: 00          nop
68EA: 00          nop
68EB: 00          nop
68EC: 00          nop
68ED: 00          nop
68EE: 00          nop
68EF: 00          nop
68F0: 00          nop
68F1: 00          nop
68F2: 00          nop
68F3: 00          nop
68F4: 00          nop
68F5: 00          nop
68F6: 00          nop
68F7: 00          nop
68F8: 00          nop
68F9: 00          nop
68FA: 00          nop
68FB: 00          nop
68FC: FF          rst  $38
68FD: FF          rst  $38
68FE: FF          rst  $38
68FF: FF          rst  $38
6900: FF          rst  $38
6901: FF          rst  $38
6902: FF          rst  $38
6903: 00          nop
6904: 00          nop
6905: 00          nop
6906: 00          nop
6907: 00          nop
6908: 00          nop
6909: 00          nop
690A: 00          nop
690B: 00          nop
690C: 00          nop
690D: 00          nop
690E: 00          nop
690F: 00          nop
6910: 00          nop
6911: 00          nop
6912: 00          nop
6913: 00          nop
6914: 00          nop
6915: 00          nop
6916: 00          nop
6917: 00          nop
6918: 00          nop
6919: 00          nop
691A: 00          nop
691B: 00          nop
691C: 00          nop
691D: 00          nop
691E: 00          nop
691F: 00          nop
6920: 00          nop
6921: 00          nop
6922: 00          nop
6923: 00          nop
6924: 00          nop
6925: 00          nop
6926: 00          nop
6927: 00          nop
6928: 00          nop
6929: 00          nop
692A: 00          nop
692B: 00          nop
692C: 00          nop
692D: 00          nop
692E: 00          nop
692F: 00          nop
6930: 00          nop
6931: 00          nop
6932: 00          nop
6933: 00          nop
6934: 00          nop
6935: 00          nop
6936: 00          nop
6937: 00          nop
6938: 00          nop
6939: 00          nop
693A: 00          nop
693B: 00          nop
693C: 00          nop
693D: 00          nop
693E: 00          nop
693F: 00          nop
6940: 00          nop
6941: 00          nop
6942: 00          nop
6943: 00          nop
6944: 00          nop
6945: 00          nop
6946: 00          nop
6947: 00          nop
6948: 00          nop
6949: 00          nop
694A: 00          nop
694B: 00          nop
694C: 00          nop
694D: 00          nop
694E: 00          nop
694F: 00          nop
6950: 00          nop
6951: 00          nop
6952: 00          nop
6953: 00          nop
6954: 00          nop
6955: 00          nop
6956: 00          nop
6957: 00          nop
6958: 0C          inc  c
6959: 9E          sbc  a,(hl)
695A: DE FF       sbc  a,$FF
695C: 00          nop
695D: 01 21 61    ld   bc,$0703
6960: E1          pop  hl
6961: E1          pop  hl
6962: E1          pop  hl
6963: F1          pop  af
6964: D2 FF FF    jp   nc,$FFFF
6967: FF          rst  $38
6968: FF          rst  $38
6969: FF          rst  $38
696A: FF          rst  $38
696B: FF          rst  $38
696C: 00          nop
696D: 1E DE       ld   e,$FC
696F: FF          rst  $38
6970: FF          rst  $38
6971: FF          rst  $38
6972: FF          rst  $38
6973: FF          rst  $38
6974: 00          nop
6975: 00          nop
6976: 00          nop
6977: 9E          sbc  a,(hl)
6978: DE FF       sbc  a,$FF
697A: FF          rst  $38
697B: FF          rst  $38
697C: 00          nop
697D: 01 21 61    ld   bc,$0703
6980: F1          pop  af
6981: F3          di
6982: F7          rst  $30
6983: F7          rst  $30
6984: F3          di
6985: FF          rst  $38
6986: FF          rst  $38
6987: FF          rst  $38
6988: FF          rst  $38
6989: FF          rst  $38
698A: FF          rst  $38
698B: FF          rst  $38
698C: 00          nop
698D: 00          nop
698E: 00          nop
698F: 00          nop
6990: 00          nop
6991: 00          nop
6992: 00          nop
6993: 00          nop
6994: 00          nop
6995: 08          ex   af,af'
6996: 0C          inc  c
6997: 1E 9E       ld   e,$F8
6999: 9E          sbc  a,(hl)
699A: 9E          sbc  a,(hl)
699B: 9E          sbc  a,(hl)
699C: F1          pop  af
699D: F3          di
699E: F3          di
699F: F7          rst  $30
69A0: F7          rst  $30
69A1: F7          rst  $30
69A2: F7          rst  $30
69A3: F3          di
69A4: 9E          sbc  a,(hl)
69A5: 9E          sbc  a,(hl)
69A6: 9E          sbc  a,(hl)
69A7: 9E          sbc  a,(hl)
69A8: DE FF       sbc  a,$FF
69AA: FF          rst  $38
69AB: FF          rst  $38
69AC: F7          rst  $30
69AD: F7          rst  $30
69AE: F3          di
69AF: F1          pop  af
69B0: E1          pop  hl
69B1: 00          nop
69B2: 00          nop
69B3: 00          nop
69B4: FF          rst  $38
69B5: FF          rst  $38
69B6: FF          rst  $38
69B7: FF          rst  $38
69B8: FF          rst  $38
69B9: FF          rst  $38
69BA: F3          di
69BB: 21 FF FF    ld   hl,$FFFF
69BE: FF          rst  $38
69BF: FF          rst  $38
69C0: FF          rst  $38
69C1: FF          rst  $38
69C2: FF          rst  $38
69C3: 1E F7       ld   e,$7F
69C5: F7          rst  $30
69C6: F7          rst  $30
69C7: F7          rst  $30
69C8: F3          di
69C9: F1          pop  af
69CA: 61          ld   h,c
69CB: 00          nop
69CC: FF          rst  $38
69CD: FE DE       cp   $FC
69CF: 9E          sbc  a,(hl)
69D0: 9E          sbc  a,(hl)
69D1: 0E 08       ld   c,$80
69D3: 00          nop
69D4: 0C          inc  c
69D5: 0E 9E       ld   c,$F8
69D7: DE DE       sbc  a,$FC
69D9: FE FE       cp   $FE
69DB: FE F7       cp   $7F
69DD: F7          rst  $30
69DE: F7          rst  $30
69DF: F7          rst  $30
69E0: F7          rst  $30
69E1: F7          rst  $30
69E2: F7          rst  $30
69E3: F7          rst  $30
69E4: FF          rst  $38
69E5: FF          rst  $38
69E6: 0E 0C       ld   c,$C0
69E8: 08          ex   af,af'
69E9: 00          nop
69EA: 00          nop
69EB: 00          nop
69EC: 00          nop
69ED: 00          nop
69EE: 00          nop
69EF: 00          nop
69F0: 00          nop
69F1: 00          nop
69F2: 00          nop
69F3: 00          nop
69F4: 00          nop
69F5: 00          nop
69F6: 00          nop
69F7: 00          nop
69F8: 00          nop
69F9: 00          nop
69FA: 00          nop
69FB: 00          nop
69FC: 00          nop
69FD: 00          nop
69FE: 00          nop
69FF: 00          nop
6A00: 00          nop
6A01: 00          nop
6A02: 00          nop
6A03: 00          nop
6A04: FF          rst  $38
6A05: 00          nop
6A06: 00          nop
6A07: 00          nop
6A08: 00          nop
6A09: 00          nop
6A0A: 00          nop
6A0B: 00          nop
6A0C: FF          rst  $38
6A0D: FF          rst  $38
6A0E: FF          rst  $38
6A0F: FF          rst  $38
6A10: 00          nop
6A11: 00          nop
6A12: 00          nop
6A13: 00          nop
6A14: 9E          sbc  a,(hl)
6A15: 0E 0C       ld   c,$C0
6A17: 00          nop
6A18: 00          nop
6A19: 00          nop
6A1A: 00          nop
6A1B: 00          nop
6A1C: FF          rst  $38
6A1D: FF          rst  $38
6A1E: FF          rst  $38
6A1F: FF          rst  $38
6A20: FF          rst  $38
6A21: DE 0C       sbc  a,$C0
6A23: 00          nop
6A24: 00          nop
6A25: 00          nop
6A26: 00          nop
6A27: E1          pop  hl
6A28: F1          pop  af
6A29: F3          di
6A2A: FF          rst  $38
6A2B: FF          rst  $38
6A2C: F2 F7 FF    jp   p,$FF7F
6A2F: 00          nop
6A30: 00          nop
6A31: 00          nop
6A32: 00          nop
6A33: 00          nop
6A34: 00          nop
6A35: 00          nop
6A36: 0C          inc  c
6A37: 1E 1E       ld   e,$F0
6A39: 9E          sbc  a,(hl)
6A3A: DE FE       sbc  a,$FE
6A3C: 0C          inc  c
6A3D: 0C          inc  c
6A3E: DE DE       sbc  a,$FC
6A40: DE DE       sbc  a,$FC
6A42: DE DE       sbc  a,$FC
6A44: 00          nop
6A45: 08          ex   af,af'
6A46: 0C          inc  c
6A47: 0E 1E       ld   c,$F0
6A49: DE FE       sbc  a,$FE
6A4B: FF          rst  $38
6A4C: FE DE       cp   $FC
6A4E: 9E          sbc  a,(hl)
6A4F: 1E 0E       ld   e,$E0
6A51: 0C          inc  c
6A52: 00          nop
6A53: 00          nop
6A54: FF          rst  $38
6A55: FF          rst  $38
6A56: FF          rst  $38
6A57: FF          rst  $38
6A58: FF          rst  $38
6A59: FF          rst  $38
6A5A: DE DE       sbc  a,$FC
6A5C: 00          nop
6A5D: 00          nop
6A5E: 00          nop
6A5F: 00          nop
6A60: 00          nop
6A61: 00          nop
6A62: 00          nop
6A63: 00          nop
6A64: 00          nop
6A65: 00          nop
6A66: 00          nop
6A67: 00          nop
6A68: 00          nop
6A69: 00          nop
6A6A: 00          nop
6A6B: 00          nop
6A6C: 00          nop
6A6D: 00          nop
6A6E: 00          nop
6A6F: 00          nop
6A70: 00          nop
6A71: 00          nop
6A72: 00          nop
6A73: 00          nop
6A74: 00          nop
6A75: 00          nop
6A76: 00          nop
6A77: 00          nop
6A78: 00          nop
6A79: 00          nop
6A7A: 00          nop
6A7B: 00          nop
6A7C: 00          nop
6A7D: 00          nop
6A7E: 00          nop
6A7F: 00          nop
6A80: 00          nop
6A81: 00          nop
6A82: 00          nop
6A83: 00          nop
6A84: 00          nop
6A85: 00          nop
6A86: 00          nop
6A87: 00          nop
6A88: 00          nop
6A89: 00          nop
6A8A: 00          nop
6A8B: 00          nop
6A8C: 00          nop
6A8D: 00          nop
6A8E: 00          nop
6A8F: 00          nop
6A90: 00          nop
6A91: 00          nop
6A92: 00          nop
6A93: 00          nop
6A94: 00          nop
6A95: 00          nop
6A96: 00          nop
6A97: 00          nop
6A98: 00          nop
6A99: 00          nop
6A9A: 00          nop
6A9B: 00          nop
6A9C: 00          nop
6A9D: 00          nop
6A9E: 00          nop
6A9F: 00          nop
6AA0: 00          nop
6AA1: 00          nop
6AA2: 00          nop
6AA3: 00          nop
6AA4: 00          nop
6AA5: 00          nop
6AA6: 00          nop
6AA7: 00          nop
6AA8: 00          nop
6AA9: 00          nop
6AAA: 00          nop
6AAB: 00          nop
6AAC: 00          nop
6AAD: 00          nop
6AAE: 00          nop
6AAF: 00          nop
6AB0: 00          nop
6AB1: 00          nop
6AB2: 00          nop
6AB3: 00          nop
6AB4: 00          nop
6AB5: 00          nop
6AB6: 00          nop
6AB7: 00          nop
6AB8: 00          nop
6AB9: 00          nop
6ABA: 00          nop
6ABB: 00          nop
6ABC: 00          nop
6ABD: 00          nop
6ABE: 00          nop
6ABF: 00          nop
6AC0: 21 61 61    ld   hl,$0707
6AC3: 01 00 00    ld   bc,$0000
6AC6: FF          rst  $38
6AC7: FF          rst  $38
6AC8: FF          rst  $38
6AC9: FF          rst  $38
6ACA: FF          rst  $38
6ACB: FF          rst  $38
6ACC: 00          nop
6ACD: 00          nop
6ACE: 00          nop
6ACF: 00          nop
6AD0: FF          rst  $38
6AD1: FF          rst  $38
6AD2: FF          rst  $38
6AD3: FF          rst  $38
6AD4: FF          rst  $38
6AD5: FF          rst  $38
6AD6: FF          rst  $38
6AD7: FF          rst  $38
6AD8: FF          rst  $38
6AD9: FF          rst  $38
6ADA: FF          rst  $38
6ADB: FF          rst  $38
6ADC: FF          rst  $38
6ADD: FF          rst  $38
6ADE: FF          rst  $38
6ADF: FF          rst  $38
6AE0: FF          rst  $38
6AE1: 00          nop
6AE2: 00          nop
6AE3: 00          nop
6AE4: 00          nop
6AE5: E1          pop  hl
6AE6: FF          rst  $38
6AE7: FF          rst  $38
6AE8: FF          rst  $38
6AE9: FF          rst  $38
6AEA: FF          rst  $38
6AEB: FF          rst  $38
6AEC: 00          nop
6AED: 00          nop
6AEE: 00          nop
6AEF: 00          nop
6AF0: 00          nop
6AF1: 00          nop
6AF2: 00          nop
6AF3: 00          nop
6AF4: 00          nop
6AF5: 00          nop
6AF6: 00          nop
6AF7: 00          nop
6AF8: 00          nop
6AF9: 00          nop
6AFA: 00          nop
6AFB: 00          nop
6AFC: 00          nop
6AFD: 00          nop
6AFE: 00          nop
6AFF: 00          nop
6B00: 21 F1 FF    ld   hl,$FF1F
6B03: FF          rst  $38
6B04: 00          nop
6B05: 00          nop
6B06: E1          pop  hl
6B07: F7          rst  $30
6B08: FF          rst  $38
6B09: FF          rst  $38
6B0A: FF          rst  $38
6B0B: FF          rst  $38
6B0C: FF          rst  $38
6B0D: FE FE       cp   $FE
6B0F: FE DE       cp   $FC
6B11: DE 9E       sbc  a,$F8
6B13: 9E          sbc  a,(hl)
6B14: 0E 0C       ld   c,$C0
6B16: 08          ex   af,af'
6B17: 00          nop
6B18: 00          nop
6B19: 00          nop
6B1A: 00          nop
6B1B: 00          nop
6B1C: 00          nop
6B1D: 00          nop
6B1E: 00          nop
6B1F: 00          nop
6B20: 00          nop
6B21: 00          nop
6B22: 00          nop
6B23: FF          rst  $38
6B24: FF          rst  $38
6B25: FF          rst  $38
6B26: FF          rst  $38
6B27: F3          di
6B28: F1          pop  af
6B29: 61          ld   h,c
6B2A: 21 00 FF    ld   hl,$FF00
6B2D: FF          rst  $38
6B2E: FF          rst  $38
6B2F: 00          nop
6B30: 00          nop
6B31: 00          nop
6B32: 00          nop
6B33: 00          nop
6B34: FF          rst  $38
6B35: FF          rst  $38
6B36: FF          rst  $38
6B37: F3          di
6B38: E1          pop  hl
6B39: 21 00 00    ld   hl,$0000
6B3C: 00          nop
6B3D: 00          nop
6B3E: 00          nop
6B3F: 21 F1 FF    ld   hl,$FF1F
6B42: FF          rst  $38
6B43: FF          rst  $38
6B44: 61          ld   h,c
6B45: E1          pop  hl
6B46: F1          pop  af
6B47: F3          di
6B48: F7          rst  $30
6B49: FF          rst  $38
6B4A: FF          rst  $38
6B4B: FF          rst  $38
6B4C: 00          nop
6B4D: 00          nop
6B4E: 00          nop
6B4F: F7          rst  $30
6B50: F7          rst  $30
6B51: F7          rst  $30
6B52: F7          rst  $30
6B53: F7          rst  $30
6B54: 00          nop
6B55: 00          nop
6B56: FF          rst  $38
6B57: FF          rst  $38
6B58: FF          rst  $38
6B59: FF          rst  $38
6B5A: FF          rst  $38
6B5B: FF          rst  $38
6B5C: 00          nop
6B5D: 00          nop
6B5E: 21 E1 E1    ld   hl,$0F0F
6B61: E1          pop  hl
6B62: 61          ld   h,c
6B63: 01 E1 F1    ld   bc,$1F0F
6B66: F3          di
6B67: F3          di
6B68: F3          di
6B69: F3          di
6B6A: F1          pop  af
6B6B: 00          nop
6B6C: FF          rst  $38
6B6D: FF          rst  $38
6B6E: FF          rst  $38
6B6F: FF          rst  $38
6B70: FF          rst  $38
6B71: FF          rst  $38
6B72: FF          rst  $38
6B73: FF          rst  $38
6B74: 9E          sbc  a,(hl)
6B75: DE FE       sbc  a,$FE
6B77: FE DE       cp   $FC
6B79: 1E 00       ld   e,$00
6B7B: 00          nop
6B7C: FF          rst  $38
6B7D: FF          rst  $38
6B7E: FF          rst  $38
6B7F: FF          rst  $38
6B80: FF          rst  $38
6B81: FF          rst  $38
6B82: 00          nop
6B83: 00          nop
6B84: FF          rst  $38
6B85: FF          rst  $38
6B86: FF          rst  $38
6B87: FF          rst  $38
6B88: FF          rst  $38
6B89: 00          nop
6B8A: 00          nop
6B8B: 00          nop
6B8C: FE FE       cp   $FE
6B8E: DE 9E       sbc  a,$F8
6B90: 00          nop
6B91: 00          nop
6B92: 00          nop
6B93: 00          nop
6B94: 61          ld   h,c
6B95: 61          ld   h,c
6B96: 61          ld   h,c
6B97: 61          ld   h,c
6B98: 61          ld   h,c
6B99: 61          ld   h,c
6B9A: 61          ld   h,c
6B9B: 61          ld   h,c
6B9C: 00          nop
6B9D: 00          nop
6B9E: 00          nop
6B9F: 00          nop
6BA0: FF          rst  $38
6BA1: FF          rst  $38
6BA2: FF          rst  $38
6BA3: FF          rst  $38
6BA4: 00          nop
6BA5: 00          nop
6BA6: 00          nop
6BA7: 00          nop
6BA8: 00          nop
6BA9: F7          rst  $30
6BAA: FF          rst  $38
6BAB: FF          rst  $38
6BAC: 00          nop
6BAD: 00          nop
6BAE: 00          nop
6BAF: 00          nop
6BB0: 00          nop
6BB1: 00          nop
6BB2: 61          ld   h,c
6BB3: F1          pop  af
6BB4: F3          di
6BB5: F3          di
6BB6: F3          di
6BB7: F1          pop  af
6BB8: E1          pop  hl
6BB9: 61          ld   h,c
6BBA: 21 01 F7    ld   hl,$7F01
6BBD: F3          di
6BBE: E1          pop  hl
6BBF: 61          ld   h,c
6BC0: 01 00 00    ld   bc,$0000
6BC3: 00          nop
6BC4: FF          rst  $38
6BC5: FF          rst  $38
6BC6: FF          rst  $38
6BC7: FF          rst  $38
6BC8: FF          rst  $38
6BC9: 00          nop
6BCA: 00          nop
6BCB: 00          nop
6BCC: FF          rst  $38
6BCD: FF          rst  $38
6BCE: FF          rst  $38
6BCF: FF          rst  $38
6BD0: FF          rst  $38
6BD1: 61          ld   h,c
6BD2: 21 00 FF    ld   hl,$FF00
6BD5: FF          rst  $38
6BD6: FF          rst  $38
6BD7: FF          rst  $38
6BD8: FF          rst  $38
6BD9: FF          rst  $38
6BDA: FF          rst  $38
6BDB: 00          nop
6BDC: 1E 9E       ld   e,$F8
6BDE: 9E          sbc  a,(hl)
6BDF: 9E          sbc  a,(hl)
6BE0: 1E 0E       ld   e,$E0
6BE2: 0C          inc  c
6BE3: 00          nop
6BE4: 00          nop
6BE5: 00          nop
6BE6: 00          nop
6BE7: 00          nop
6BE8: 1E 9E       ld   e,$F8
6BEA: DE DE       sbc  a,$FC
6BEC: 00          nop
6BED: 0C          inc  c
6BEE: 0E DE       ld   c,$FC
6BF0: FF          rst  $38
6BF1: FF          rst  $38
6BF2: FF          rst  $38
6BF3: FF          rst  $38
6BF4: 00          nop
6BF5: 00          nop
6BF6: 00          nop
6BF7: 00          nop
6BF8: 1E DE       ld   e,$FC
6BFA: FE FF       cp   $FF
6BFC: 21 E1 E1    ld   hl,$0F0F
6BFF: E1          pop  hl
6C00: E1          pop  hl
6C01: E1          pop  hl
6C02: 61          ld   h,c
6C03: 21 F3 F1    ld   hl,$1F3F
6C06: E1          pop  hl
6C07: 61          ld   h,c
6C08: 21 01 00    ld   hl,$0001
6C0B: 00          nop
6C0C: 08          ex   af,af'
6C0D: 0E 1E       ld   c,$F0
6C0F: 1E 1E       ld   e,$F0
6C11: 1E 0E       ld   e,$E0
6C13: 00          nop
6C14: 00          nop
6C15: 00          nop
6C16: 00          nop
6C17: 00          nop
6C18: 00          nop
6C19: FE FF       cp   $FF
6C1B: FF          rst  $38
6C1C: 00          nop
6C1D: 00          nop
6C1E: 00          nop
6C1F: 00          nop
6C20: 00          nop
6C21: 61          ld   h,c
6C22: F3          di
6C23: F7          rst  $30
6C24: 00          nop
6C25: 00          nop
6C26: 00          nop
6C27: 00          nop
6C28: 00          nop
6C29: 00          nop
6C2A: F7          rst  $30
6C2B: FF          rst  $38
6C2C: 00          nop
6C2D: 00          nop
6C2E: 00          nop
6C2F: 00          nop
6C30: 00          nop
6C31: 00          nop
6C32: 00          nop
6C33: 00          nop
6C34: 00          nop
6C35: 00          nop
6C36: 00          nop
6C37: 00          nop
6C38: 00          nop
6C39: 00          nop
6C3A: 00          nop
6C3B: FF          rst  $38
6C3C: FF          rst  $38
6C3D: FF          rst  $38
6C3E: FF          rst  $38
6C3F: FF          rst  $38
6C40: 0E 00       ld   c,$00
6C42: 00          nop
6C43: 00          nop
6C44: FF          rst  $38
6C45: FF          rst  $38
6C46: FF          rst  $38
6C47: 1E 00       ld   e,$00
6C49: 00          nop
6C4A: 00          nop
6C4B: 00          nop
6C4C: FF          rst  $38
6C4D: 00          nop
6C4E: 00          nop
6C4F: 00          nop
6C50: 00          nop
6C51: 00          nop
6C52: 00          nop
6C53: 00          nop
6C54: 00          nop
6C55: 00          nop
6C56: FF          rst  $38
6C57: FF          rst  $38
6C58: FF          rst  $38
6C59: FF          rst  $38
6C5A: FF          rst  $38
6C5B: FF          rst  $38
6C5C: FF          rst  $38
6C5D: FF          rst  $38
6C5E: FF          rst  $38
6C5F: FF          rst  $38
6C60: 00          nop
6C61: 00          nop
6C62: 00          nop
6C63: 00          nop
6C64: DD 7E E1    ld   a,(ix+$0f)
6C67: 21 30 E6    ld   hl,$6E12
6C6A: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
6C6B: EB          ex   de,hl
6C6C: DD 7E 01    ld   a,(ix+$01)
6C6F: C6 01       add  a,$01
6C71: 47          ld   b,a
6C72: 0F          rrca
6C73: E6 F1       and  $1F
6C75: 28 92       jr   z,$6CAF
6C77: CB 70       bit  6,b
6C79: 20 80       jr   nz,$6C83
6C7B: 47          ld   b,a
6C7C: 2F          cpl
6C7D: E6 F1       and  $1F
6C7F: 4F          ld   c,a
6C80: C3 88 C6    jp   $6C88
6C83: 4F          ld   c,a
6C84: 2F          cpl
6C85: E6 F1       and  $1F
6C87: 47          ld   b,a
6C88: E5          push hl
6C89: 79          ld   a,c
6C8A: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
6C8B: 78          ld   a,b
6C8C: 42          ld   b,d
6C8D: 4B          ld   c,e
6C8E: E1          pop  hl
6C8F: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
6C90: DD CB 01 F6 bit  7,(ix+$01)
6C94: 28 80       jr   z,$6C9E
6C96: 21 00 00    ld   hl,$0000
6C99: A7          and  a
6C9A: ED 42       sbc  hl,bc
6C9C: 44          ld   b,h
6C9D: 4D          ld   c,l
6C9E: DD 7E 01    ld   a,(ix+$01)
6CA1: C6 04       add  a,$40
6CA3: CB 7F       bit  7,a
6CA5: C8          ret  z
6CA6: 21 00 00    ld   hl,$0000
6CA9: A7          and  a
6CAA: ED 52       sbc  hl,de
6CAC: 54          ld   d,h
6CAD: 5D          ld   e,l
6CAE: C9          ret
6CAF: 78          ld   a,b
6CB0: 4E          ld   c,(hl)
6CB1: 23          inc  hl
6CB2: 46          ld   b,(hl)
6CB3: 07          rlca
6CB4: 07          rlca
6CB5: E6 21       and  $03
6CB7: F7          rst  $30
6CB8: 0C          inc  c
6CB9: C6 6C       add  a,$C6
6CBB: C6 AC       add  a,$CA
6CBD: C6 7C       add  a,$D6
6CBF: C6 50       add  a,$14
6CC1: 59          ld   e,c
6CC2: 01 00 00    ld   bc,$0000
6CC5: C9          ret
6CC6: 11 00 00    ld   de,$0000
6CC9: C9          ret
6CCA: 21 00 00    ld   hl,$0000
6CCD: A7          and  a
6CCE: ED 42       sbc  hl,bc
6CD0: 54          ld   d,h
6CD1: 5D          ld   e,l
6CD2: 01 00 00    ld   bc,$0000
6CD5: C9          ret
6CD6: 21 00 00    ld   hl,$0000
6CD9: A7          and  a
6CDA: ED 42       sbc  hl,bc
6CDC: 44          ld   b,h
6CDD: 4D          ld   c,l
6CDE: 11 00 00    ld   de,$0000
6CE1: C9          ret
6CE2: 21 21 0F    ld   hl,$E103
6CE5: 0E 00       ld   c,$00
6CE7: 7E          ld   a,(hl)
6CE8: 2C          inc  l
6CE9: 2C          inc  l
6CEA: DD 46 21    ld   b,(ix+$03)
6CED: 90          sub  b
6CEE: 28 37       jr   z,$6D63
6CF0: CB 19       rr   c
6CF2: CB 79       bit  7,c
6CF4: 28 20       jr   z,$6CF8
6CF6: ED 44       neg
6CF8: 57          ld   d,a
6CF9: 7E          ld   a,(hl)
6CFA: DD 46 41    ld   b,(ix+$05)
6CFD: 90          sub  b
6CFE: 28 C7       jr   z,$6D6D
6D00: CB 19       rr   c
6D02: CB 79       bit  7,c
6D04: 28 20       jr   z,$6D08
6D06: ED 44       neg
6D08: 5F          ld   e,a
6D09: 92          sub  d
6D0A: 28 27       jr   z,$6D6F
6D0C: CB 19       rr   c
6D0E: CB 79       bit  7,c
6D10: 20 41       jr   nz,$6D17
6D12: 62          ld   h,d
6D13: 2E 00       ld   l,$00
6D15: 18 40       jr   $6D1B
6D17: 63          ld   h,e
6D18: 5A          ld   e,d
6D19: 2E 00       ld   l,$00
6D1B: 06 80       ld   b,$08
6D1D: AF          xor  a
6D1E: ED 6A       adc  hl,hl
6D20: 7C          ld   a,h
6D21: 38 21       jr   c,$6D26
6D23: BB          cp   e
6D24: 38 21       jr   c,$6D29
6D26: 93          sub  e
6D27: 67          ld   h,a
6D28: AF          xor  a
6D29: 3F          ccf
6D2A: 10 3E       djnz $6D1E
6D2C: CB 15       rl   l
6D2E: 7D          ld   a,l
6D2F: 0F          rrca
6D30: 0F          rrca
6D31: 0F          rrca
6D32: E6 F1       and  $1F
6D34: 47          ld   b,a
6D35: 21 A5 C7    ld   hl,$6D4B
6D38: 79          ld   a,c
6D39: 07          rlca
6D3A: 07          rlca
6D3B: 07          rlca
6D3C: E6 61       and  $07
6D3E: 87          add  a,a
6D3F: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
6D40: 4F          ld   c,a
6D41: 23          inc  hl
6D42: 7E          ld   a,(hl)
6D43: CB 41       bit  0,c
6D45: 20 20       jr   nz,$6D49
6D47: 80          add  a,b
6D48: C9          ret
6D49: 90          sub  b
6D4A: C9          ret
6D4B: 01 04 00    ld   bc,$0040
6D4E: 04          inc  b
6D4F: 00          nop
6D50: 0C          inc  c
6D51: 01 0C 00    ld   bc,$00C0
6D54: 00          nop
6D55: 01 08 01    ld   bc,$0180
6D58: 00          nop
6D59: 00          nop
6D5A: 08          ex   af,af'
6D5B: 01 04 00    ld   bc,$0040
6D5E: 04          inc  b
6D5F: 00          nop
6D60: 0C          inc  c
6D61: 01 0C 7E    ld   bc,$F6C0
6D64: DD 96 41    sub  (ix+$05)
6D67: CB 19       rr   c
6D69: 3E 04       ld   a,$40
6D6B: 81          add  a,c
6D6C: C9          ret
6D6D: 79          ld   a,c
6D6E: C9          ret
6D6F: 79          ld   a,c
6D70: 07          rlca
6D71: 07          rlca
6D72: E6 21       and  $03
6D74: 21 97 C7    ld   hl,$6D79
6D77: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
6D78: C9          ret
6D79: 02          ld   (bc),a
6D7A: 06 0E       ld   b,$E0
6D7C: 0A          ld   a,(bc)
6D7D: FD 21 40 FE ld   iy,$FE04
6D81: 3A A1 0E    ld   a,($E00B)
6D84: E6 01       and  $01
6D86: 28 21       jr   z,$6D8B
6D88: FD 34 21    inc  (iy+$03)
6D8B: 3A A0 0E    ld   a,($E00A)
6D8E: E6 01       and  $01
6D90: 28 21       jr   z,$6D95
6D92: FD 35 21    dec  (iy+$03)
6D95: 3A 81 0E    ld   a,($E009)
6D98: E6 01       and  $01
6D9A: 28 21       jr   z,$6D9F
6D9C: FD 35 20    dec  (iy+$02)
6D9F: 3A 80 0E    ld   a,($E008)
6DA2: E6 01       and  $01
6DA4: 28 21       jr   z,$6DA9
6DA6: FD 34 20    inc  (iy+$02)
6DA9: FD 36 01 00 ld   (iy+$01),$00
6DAD: FD 36 00 BA ld   (iy+$00),$BA
6DB1: FD 21 80 FE ld   iy,$FE08
6DB5: 3A 31 0E    ld   a,($E013)
6DB8: E6 01       and  $01
6DBA: 28 21       jr   z,$6DBF
6DBC: FD 34 21    inc  (iy+$03)
6DBF: 3A 30 0E    ld   a,($E012)
6DC2: E6 01       and  $01
6DC4: 28 21       jr   z,$6DC9
6DC6: FD 35 21    dec  (iy+$03)
6DC9: 3A 11 0E    ld   a,($E011)
6DCC: E6 01       and  $01
6DCE: 28 21       jr   z,$6DD3
6DD0: FD 35 20    dec  (iy+$02)
6DD3: 3A 10 0E    ld   a,($E010)
6DD6: E6 01       and  $01
6DD8: 28 21       jr   z,$6DDD
6DDA: FD 34 20    inc  (iy+$02)
6DDD: FD 36 01 00 ld   (iy+$01),$00
6DE1: FD 36 00 9A ld   (iy+$00),$B8
6DE5: FD 7E 20    ld   a,(iy+$02)
6DE8: 32 D7 0E    ld   ($E07D),a
6DEB: FD 7E 21    ld   a,(iy+$03)
6DEE: 32 F7 0E    ld   ($E07F),a
6DF1: DD 21 00 6E ld   ix,$E600
6DF5: FD 21 40 FE ld   iy,$FE04
6DF9: FD 7E 20    ld   a,(iy+$02)
6DFC: DD 77 21    ld   (ix+$03),a
6DFF: FD 7E 21    ld   a,(iy+$03)
6E02: DD 77 41    ld   (ix+$05),a
6E05: 21 D7 0E    ld   hl,$E07D
6E08: CD 4F C6    call $6CE5
6E0B: 21 D4 1C    ld   hl,$D05C
6E0E: C3 D8 D8    jp   $9C9C
6E11: C9          ret
6E12: E2 E6 E6    jp   po,$6E6E
6E15: E6 EA       and  $AE
6E17: E6 EE       and  $EE
6E19: E6 E2       and  $2E
6E1B: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
6E1C: E6 E7       and  $6F
6E1E: EA E7 EE    jp   pe,$EE6F
6E21: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
6E22: E2 16 E6    jp   po,$6E70
6E25: 16 EA       ld   d,$AE
6E27: 16 EE       ld   d,$EE
6E29: 16 E2       ld   d,$2E
6E2B: 17          rla
6E2C: E6 17       and  $71
6E2E: 8C          adc  a,h
6E2F: 00          nop
6E30: 6D          ld   l,l
6E31: 00          nop
6E32: 6D          ld   l,l
6E33: 00          nop
6E34: 4D          ld   c,l
6E35: 00          nop
6E36: 4C          ld   c,h
6E37: 00          nop
6E38: 2C          inc  l
6E39: 00          nop
6E3A: FB          ei
6E3B: 00          nop
6E3C: DA 00 9A    jp   c,$B800
6E3F: 00          nop
6E40: 5A          ld   e,d
6E41: 00          nop
6E42: 1A          ld   a,(de)
6E43: 00          nop
6E44: AB          xor  e
6E45: 00          nop
6E46: 6A          ld   l,d
6E47: 00          nop
6E48: 0A          ld   a,(bc)
6E49: 00          nop
6E4A: B8          cp   b
6E4B: 00          nop
6E4C: 58          ld   e,b
6E4D: 00          nop
6E4E: C9          ret
6E4F: 00          nop
6E50: 68          ld   l,b
6E51: 00          nop
6E52: F6 00       or   $00
6E54: 77          ld   (hl),a
6E55: 00          nop
6E56: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
6E57: 00          nop
6E58: 66          ld   h,(hl)
6E59: 00          nop
6E5A: F4 00 55    call p,$5500
6E5D: 00          nop
6E5E: C4 00 25    call nz,$4300
6E61: 00          nop
6E62: B2          or   d
6E63: 00          nop
6E64: 12          ld   (de),a
6E65: 00          nop
6E66: 63          ld   h,e
6E67: 00          nop
6E68: D1          pop  de
6E69: 00          nop
6E6A: 31 00 81    ld   sp,$0900
6E6D: 00          nop
6E6E: B0          or   b
6E6F: 01 91 01    ld   bc,$0119
6E72: 90          sub  b
6E73: 01 70 01    ld   bc,$0116
6E76: 50          ld   d,b
6E77: 01 11 01    ld   bc,$0111
6E7A: C1          pop  bc
6E7B: 01 81 01    ld   bc,$0109
6E7E: 40          ld   b,b
6E7F: 01 FE 00    ld   bc,$00FE
6E82: 9E          sbc  a,(hl)
6E83: 00          nop
6E84: 1F          rra
6E85: 00          nop
6E86: AE          xor  (hl)
6E87: 00          nop
6E88: 2E 00       ld   l,$00
6E8A: 9D          sbc  a,l
6E8B: 00          nop
6E8C: 1C          inc  e
6E8D: 00          nop
6E8E: 6D          ld   l,l
6E8F: 00          nop
6E90: DB 00       in   a,($00)
6E92: 3A 00 6B    ld   a,($A700)
6E95: 00          nop
6E96: D8          ret  c
6E97: 00          nop
6E98: 18 00       jr   $6E9A
6E9A: 48          ld   c,b
6E9B: 00          nop
6E9C: 96          sub  (hl)
6E9D: 00          nop
6E9E: A7          and  a
6E9F: 00          nop
6EA0: F4 00 15    call p,$5100
6EA3: 00          nop
6EA4: 44          ld   b,h
6EA5: 00          nop
6EA6: 72          ld   (hl),d
6EA7: 00          nop
6EA8: 83          add  a,e
6EA9: 00          nop
6EAA: B1          or   c
6EAB: 00          nop
6EAC: C1          pop  bc
6EAD: 00          nop
6EAE: 33          inc  sp
6EAF: 01 32 01    ld   bc,$0132
6EB2: 13          inc  de
6EB3: 01 E3 01    ld   bc,$012F
6EB6: C2 01 83    jp   nz,$2901
6EB9: 01 43 01    ld   bc,$0125
6EBC: 02          ld   (bc),a
6EBD: 01 B1 01    ld   bc,$011B
6EC0: 51          ld   d,c
6EC1: 01 E0 01    ld   bc,$010E
6EC4: 61          ld   h,c
6EC5: 01 FF 00    ld   bc,$00FF
6EC8: 7E          ld   a,(hl)
6EC9: 00          nop
6ECA: CF          rst  $08
6ECB: 00          nop
6ECC: 2F          cpl
6ECD: 00          nop
6ECE: 9D          sbc  a,l
6ECF: 00          nop
6ED0: CD 00 2C    call $C200
6ED3: 00          nop
6ED4: 7A          ld   a,d
6ED5: 00          nop
6ED6: AA          xor  d
6ED7: 00          nop
6ED8: D9          exx
6ED9: 00          nop
6EDA: 18 00       jr   $6EDC
6EDC: 29          add  hl,hl
6EDD: 00          nop
6EDE: 57          ld   d,a
6EDF: 00          nop
6EE0: 67          ld   h,a
6EE1: 00          nop
6EE2: 95          sub  l
6EE3: 00          nop
6EE4: A4          and  h
6EE5: 00          nop
6EE6: B3          or   e
6EE7: 00          nop
6EE8: C2 00 F0    jp   nz,$1E00
6EEB: 00          nop
6EEC: E1          pop  hl
6EED: 00          nop
6EEE: C5          push bc
6EEF: 01 C4 01    ld   bc,$014C
6EF2: A5          and  l
6EF3: 01 85 01    ld   bc,$0149
6EF6: 64          ld   h,h
6EF7: 01 25 01    ld   bc,$0143
6EFA: F2 01 93    jp   p,$3901
6EFD: 01 33 01    ld   bc,$0133
6F00: C2 01 43    jp   nz,$2501
6F03: 01 D1 01    ld   bc,$011D
6F06: 50          ld   d,b
6F07: 01 A1 01    ld   bc,$010B
6F0A: 01 01 7E    ld   bc,$F601
6F0D: 00          nop
6F0E: AF          xor  a
6F0F: 00          nop
6F10: FD          db   $fd
6F11: 00          nop
6F12: 3D          dec  a
6F13: 00          nop
6F14: 6C          ld   l,h
6F15: 00          nop
6F16: 9A          sbc  a,d
6F17: 00          nop
6F18: AB          xor  e
6F19: 00          nop
6F1A: D8          ret  c
6F1B: 00          nop
6F1C: E8          ret  pe
6F1D: 00          nop
6F1E: F7          rst  $30
6F1F: 00          nop
6F20: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
6F21: 00          nop
6F22: 06 00       ld   b,$00
6F24: 14          inc  d
6F25: 00          nop
6F26: 04          inc  b
6F27: 00          nop
6F28: 12          ld   (de),a
6F29: 00          nop
6F2A: 02          ld   (bc),a
6F2B: 00          nop
6F2C: 10 00       djnz $6F2E
6F2E: 67          ld   h,a
6F2F: 01 66 01    ld   bc,$0166
6F32: 47          ld   b,a
6F33: 01 27 01    ld   bc,$0163
6F36: F5          push af
6F37: 01 D4 01    ld   bc,$015C
6F3A: 75          ld   (hl),l
6F3B: 01 15 01    ld   bc,$0151
6F3E: A5          and  l
6F3F: 01 44 01    ld   bc,$0144
6F42: D2 01 33    jp   nc,$3301
6F45: 01 A2 01    ld   bc,$012A
6F48: 02          ld   (bc),a
6F49: 01 51 01    ld   bc,$0115
6F4C: 81          add  a,c
6F4D: 01 DF 00    ld   bc,$00FD
6F50: 1E 00       ld   e,$00
6F52: 2F          cpl
6F53: 00          nop
6F54: 5D          ld   e,l
6F55: 00          nop
6F56: 6D          ld   l,l
6F57: 00          nop
6F58: 9A          sbc  a,d
6F59: 00          nop
6F5A: 8B          adc  a,e
6F5B: 00          nop
6F5C: 99          sbc  a,c
6F5D: 00          nop
6F5E: 89          adc  a,c
6F5F: 00          nop
6F60: 96          sub  (hl)
6F61: 00          nop
6F62: 86          add  a,(hl)
6F63: 00          nop
6F64: 74          ld   (hl),h
6F65: 00          nop
6F66: 64          ld   h,h
6F67: 00          nop
6F68: 52          ld   d,d
6F69: 00          nop
6F6A: 23          inc  hl
6F6B: 00          nop
6F6C: 11 00 08    ld   de,$8000
6F6F: 01 F7 01    ld   bc,$017F
6F72: F6 01       or   $01
6F74: B7          or   a
6F75: 01 96 01    ld   bc,$0178
6F78: 56          ld   d,(hl)
6F79: 01 E7 01    ld   bc,$016F
6F7C: 87          add  a,a
6F7D: 01 26 01    ld   bc,$0162
6F80: B4          or   h
6F81: 01 34 01    ld   bc,$0152
6F84: 85          add  a,l
6F85: 01 F3 01    ld   bc,$013F
6F88: 52          ld   d,d
6F89: 01 82 01    ld   bc,$0128
6F8C: D0          ret  nc
6F8D: 01 E1 01    ld   bc,$010F
6F90: 01 01 3F    ld   bc,$F301
6F93: 00          nop
6F94: 4E          ld   c,(hl)
6F95: 00          nop
6F96: 5D          ld   e,l
6F97: 00          nop
6F98: 4D          ld   c,l
6F99: 00          nop
6F9A: 5A          ld   e,d
6F9B: 00          nop
6F9C: 2B          dec  hl
6F9D: 00          nop
6F9E: 38 00       jr   c,$6FA0
6FA0: 09          add  hl,bc
6FA1: 00          nop
6FA2: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
6FA3: 00          nop
6FA4: D4 00 A4    call nc,$4A00
6FA7: 00          nop
6FA8: 92          sub  d
6FA9: 00          nop
6FAA: 43          ld   b,e
6FAB: 00          nop
6FAC: 30 00       jr   nc,$6FAE
6FAE: B8          cp   b
6FAF: 01 99 01    ld   bc,$0199
6FB2: 79          ld   a,c
6FB3: 01 59 01    ld   bc,$0195
6FB6: 19          add  hl,de
6FB7: 01 C9 01    ld   bc,$018D
6FBA: 69          ld   l,c
6FBB: 01 09 01    ld   bc,$0181
6FBE: B6          or   (hl)
6FBF: 01 36 01    ld   bc,$0172
6FC2: 87          add  a,a
6FC3: 01 F5 01    ld   bc,$015F
6FC6: 54          ld   d,h
6FC7: 01 85 01    ld   bc,$0149
6FCA: D2 01 E3    jp   nc,$2F01
6FCD: 01 03 01    ld   bc,$0121
6FD0: 31 01 21    ld   sp,$0301
6FD3: 01 3F 00    ld   bc,$00F3
6FD6: 2F          cpl
6FD7: 00          nop
6FD8: 3C          inc  a
6FD9: 00          nop
6FDA: 0D          dec  c
6FDB: 00          nop
6FDC: EB          ex   de,hl
6FDD: 00          nop
6FDE: D8          ret  c
6FDF: 00          nop
6FE0: 89          adc  a,c
6FE1: 00          nop
6FE2: 76          halt
6FE3: 00          nop
6FE4: 27          daa
6FE5: 00          nop
6FE6: E5          push hl
6FE7: 00          nop
6FE8: B3          or   e
6FE9: 00          nop
6FEA: 82          add  a,d
6FEB: 00          nop
6FEC: 50          ld   d,b
6FED: 00          nop
6FEE: 3B          dec  sp
6FEF: 01 3A 01    ld   bc,$01B2
6FF2: 1A          ld   a,(de)
6FF3: 01 EA 01    ld   bc,$01AE
6FF6: AA          xor  d
6FF7: 01 4B 01    ld   bc,$01A5
6FFA: F9          ld   sp,hl
6FFB: 01 99 01    ld   bc,$0199
6FFE: 19          add  hl,de
6FFF: 01 88 01    ld   bc,$0188
7002: F7          rst  $30
7003: 01 56 01    ld   bc,$0174
7006: 87          add  a,a
7007: 01 D5 01    ld   bc,$015D
700A: 14          inc  d
700B: 01 05 01    ld   bc,$0141
700E: 33          inc  sp
700F: 01 23 01    ld   bc,$0123
7012: 31 01 20    ld   sp,$0201
7015: 01 1F 00    ld   bc,$00F1
7018: FD          db   $fd
7019: 00          nop
701A: CC 00 9B    call z,$B900
701D: 00          nop
701E: 6A          ld   l,d
701F: 00          nop
7020: 38 00       jr   c,$7022
7022: F6 00       or   $00
7024: 87          add  a,a
7025: 00          nop
7026: 54          ld   d,h
7027: 00          nop
7028: F3          di
7029: 00          nop
702A: A2          and  d
702B: 00          nop
702C: 51          ld   d,c
702D: 00          nop
702E: CC 01 AD    call z,$CB01
7031: 01 8D 01    ld   bc,$01C9
7034: 6C          ld   l,h
7035: 01 2C 01    ld   bc,$01C2
7038: FA 01 7B    jp   m,$B701
703B: 01 1A 01    ld   bc,$01B0
703E: 8A          adc  a,d
703F: 01 F9 01    ld   bc,$019F
7042: 59          ld   e,c
7043: 01 A8 01    ld   bc,$018A
7046: F6 01       or   $01
7048: 17          rla
7049: 01 27 01    ld   bc,$0163
704C: 54          ld   d,h
704D: 01 45 01    ld   bc,$0145
7050: 52          ld   d,d
7051: 01 23 01    ld   bc,$0123
7054: 11 01 FF    ld   de,$FF01
7057: 00          nop
7058: CE 00       adc  a,$00
705A: 9C          sbc  a,h
705B: 00          nop
705C: 4C          ld   c,h
705D: 00          nop
705E: EB          ex   de,hl
705F: 00          nop
7060: B8          cp   b
7061: 00          nop
7062: 49          ld   c,c
7063: 00          nop
7064: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
7065: 00          nop
7066: 95          sub  l
7067: 00          nop
7068: 25          dec  h
7069: 00          nop
706A: C3 00 70    jp   $1600
706D: 00          nop
706E: 6F          ld   l,a
706F: 01 6E 01    ld   bc,$01E6
7072: 4E          ld   c,(hl)
7073: 01 0F 01    ld   bc,$01E1
7076: DD          db   $dd
7077: 01 9C 01    ld   bc,$01D8
707A: 1D          dec  e
707B: 01 AC 01    ld   bc,$01CA
707E: 0D          dec  c
707F: 01 7B 01    ld   bc,$01B7
7082: CB 01       rlc  c
7084: 0B          dec  bc
7085: 01 58 01    ld   bc,$0194
7088: 69          ld   l,c
7089: 01 96 01    ld   bc,$0178
708C: 86          add  a,(hl)
708D: 01 94 01    ld   bc,$0158
7090: 64          ld   h,h
7091: 01 52 01    ld   bc,$0134
7094: 03          inc  bc
7095: 01 E0 01    ld   bc,$010E
7098: BE          cp   (hl)
7099: 00          nop
709A: 4F          ld   c,a
709B: 00          nop
709C: ED          db   $ed
709D: 00          nop
709E: BA          cp   d
709F: 00          nop
70A0: 2B          dec  hl
70A1: 00          nop
70A2: C9          ret
70A3: 00          nop
70A4: 57          ld   d,a
70A5: 00          nop
70A6: F4 00 65    call p,$4700
70A9: 00          nop
70AA: E3          ex   (sp),hl
70AB: 00          nop
70AC: 71          ld   (hl),c
70AD: 00          nop
70AE: 00          nop
70AF: 20 FE       jr   nz,$70AF
70B1: 01 DF 01    ld   bc,$01FD
70B4: BE          cp   (hl)
70B5: 01 5F 01    ld   bc,$01F5
70B8: 1E 01       ld   e,$01
70BA: 8F          adc  a,a
70BB: 01 0F 01    ld   bc,$01E1
70BE: 9C          sbc  a,h
70BF: 01 EC 01    ld   bc,$01CE
70C2: 2D          dec  l
70C3: 01 7A 01    ld   bc,$01B6
70C6: 8B          adc  a,e
70C7: 01 B9 01    ld   bc,$019B
70CA: A9          xor  c
70CB: 01 B6 01    ld   bc,$017A
70CE: 87          add  a,a
70CF: 01 75 01    ld   bc,$0157
70D2: 44          ld   b,h
70D3: 01 12 01    ld   bc,$0130
70D6: D0          ret  nc
70D7: 01 61 01    ld   bc,$0107
70DA: 1F          rra
70DB: 00          nop
70DC: BC          cp   h
70DD: 00          nop
70DE: 2D          dec  l
70DF: 00          nop
70E0: CA 00 58    jp   z,$9400
70E3: 00          nop
70E4: B7          or   a
70E5: 00          nop
70E6: 27          daa
70E7: 00          nop
70E8: A4          and  h
70E9: 00          nop
70EA: 32 00 91    ld   ($1900),a
70ED: 00          nop
70EE: 33          inc  sp
70EF: 20 13       jr   nz,$7122
70F1: 20 12       jr   nz,$7123
70F3: 20 C2       jr   nz,$7121
70F5: 20 63       jr   nz,$711E
70F7: 20 22       jr   nz,$711B
70F9: 20 B0       jr   nz,$7115
70FB: 20 11       jr   nz,$710E
70FD: 20 61       jr   nz,$7106
70FF: 20 DE       jr   nz,$70FD
7101: 01 1E 01    ld   bc,$01F0
7104: 2E 01       ld   l,$01
7106: 3D          dec  a
7107: 01 4C 01    ld   bc,$01C4
710A: 3B          dec  sp
710B: 01 0A 01    ld   bc,$01A0
710E: E8          ret  pe
710F: 01 97 01    ld   bc,$0179
7112: 46          ld   b,(hl)
7113: 01 E4 01    ld   bc,$014E
7116: 92          sub  d
7117: 01 03 01    ld   bc,$0121
711A: 81          add  a,c
711B: 01 1E 00    ld   bc,$00F0
711E: 7D          ld   a,l
711F: 00          nop
7120: DB 00       in   a,($00)
7122: 2B          dec  hl
7123: 00          nop
7124: 88          adc  a,b
7125: 00          nop
7126: C7          rst  $00
7127: 00          nop
7128: 34          inc  (hl)
7129: 00          nop
712A: 73          ld   (hl),e
712B: 00          nop
712C: B1          or   c
712D: 00          nop
712E: 66          ld   h,(hl)
712F: 20 46       jr   nz,$7195
7131: 20 26       jr   nz,$7195
7133: 20 F5       jr   nz,$7194
7135: 20 95       jr   nz,$7190
7137: 20 35       jr   nz,$718C
7139: 20 A4       jr   nz,$7185
713B: 20 05       jr   nz,$717E
713D: 20 72       jr   nz,$7175
713F: 20 A2       jr   nz,$716B
7141: 20 D0       jr   nz,$715F
7143: 20 E0       jr   nz,$7153
7145: 20 FE       jr   nz,$7145
7147: 01 CF 01    ld   bc,$01ED
714A: BC          cp   h
714B: 01 6C 01    ld   bc,$01C6
714E: 3A 01 B9    ld   a,($9B01)
7151: 01 49 01    ld   bc,$0185
7154: C7          rst  $00
7155: 01 54 01    ld   bc,$0154
7158: B3          or   e
7159: 01 03 01    ld   bc,$0121
715C: 60          ld   h,b
715D: 01 AE 00    ld   bc,$00EA
7160: EC 00 3A    call pe,$B200
7163: 00          nop
7164: 58          ld   e,b
7165: 00          nop
7166: 77          ld   (hl),a
7167: 00          nop
7168: 95          sub  l
7169: 00          nop
716A: D2 00 F0    jp   nc,$1E00
716D: 00          nop
716E: B8          cp   b
716F: 20 98       jr   nz,$7109
7171: 20 78       jr   nz,$7109
7173: 20 38       jr   nz,$7107
7175: 20 C8       jr   nz,$7103
7177: 20 68       jr   nz,$70FF
7179: 20 D6       jr   nz,$71F7
717B: 20 36       jr   nz,$71EF
717D: 20 66       jr   nz,$71E5
717F: 20 95       jr   nz,$71DA
7181: 20 A4       jr   nz,$71CD
7183: 20 B2       jr   nz,$71BF
7185: 20 83       jr   nz,$71B0
7187: 20 70       jr   nz,$719F
7189: 20 20       jr   nz,$718D
718B: 20 CE       jr   nz,$7179
718D: 01 7C 01    ld   bc,$01D6
7190: FA 01 6A    jp   m,$A601
7193: 01 C8 01    ld   bc,$018C
7196: 17          rla
7197: 01 74 01    ld   bc,$0156
719A: 93          sub  e
719B: 01 D0 01    ld   bc,$011C
719E: FE 00       cp   $00
71A0: FD          db   $fd
71A1: 00          nop
71A2: 0D          dec  c
71A3: 00          nop
71A4: 0B          dec  bc
71A5: 00          nop
71A6: 09          add  hl,bc
71A7: 00          nop
71A8: 07          rlca
71A9: 00          nop
71AA: 05          dec  b
71AB: 00          nop
71AC: 02          ld   (bc),a
71AD: 00          nop
71AE: B0          or   b
71AF: 20 E3       jr   nz,$71E0
71B1: 0A          ld   a,(bc)
71B2: 5C          ld   e,h
71B3: FE 12       cp   $30
71B5: 20 23       jr   nz,$71DA
71B7: 0B          dec  bc
71B8: 82          add  a,d
71B9: FE FE       cp   $FE
71BB: 20 20       jr   nz,$71BF
71BD: 78          ld   a,b
71BE: 92          sub  d
71BF: FE FE       cp   $FE
71C1: 20 20       jr   nz,$71C5
71C3: 7A          ld   a,d
71C4: 04          inc  b
71C5: FE FE       cp   $FE
71C7: 20 01       jr   nz,$71CA
71C9: 6A          ld   l,d
71CA: 12          ld   (de),a
71CB: FE 0E       cp   $E0
71CD: 21 21 1C    ld   hl,$D003
71D0: 8C          adc  a,h
71D1: FE 0E       cp   $E0
71D3: 21 23 2C    ld   hl,$C223
71D6: 82          add  a,d
71D7: FE 11       cp   $11
71D9: 40          ld   b,b
71DA: B0          or   b
71DB: 06 18       ld   b,$90
71DD: FE 92       cp   $38
71DF: 40          ld   b,b
71E0: 91          sub  c
71E1: 0E D6       ld   c,$7C
71E3: FE 79       cp   $97
71E5: 40          ld   b,b
71E6: E3          ex   (sp),hl
71E7: 96          sub  (hl)
71E8: 96          sub  (hl)
71E9: FE 7B       cp   $B7
71EB: 40          ld   b,b
71EC: E3          ex   (sp),hl
71ED: 90          sub  b
71EE: 56          ld   d,(hl)
71EF: FE 7D       cp   $D7
71F1: 40          ld   b,b
71F2: E3          ex   (sp),hl
71F3: 4E          ld   c,(hl)
71F4: 16 FE       ld   d,$FE
71F6: 7F          ld   a,a
71F7: 40          ld   b,b
71F8: E3          ex   (sp),hl
71F9: 84          add  a,h
71FA: C6 FE       add  a,$FE
71FC: 71          ld   (hl),c
71FD: 41          ld   b,c
71FE: E3          ex   (sp),hl
71FF: 8A          adc  a,d
7200: 86          add  a,(hl)
7201: FE 77       cp   $77
7203: 41          ld   b,c
7204: E3          ex   (sp),hl
7205: 90          sub  b
7206: 5C          ld   e,h
7207: FE 77       cp   $77
7209: 41          ld   b,c
720A: E3          ex   (sp),hl
720B: 96          sub  (hl)
720C: 1C          inc  e
720D: FE 77       cp   $77
720F: 41          ld   b,c
7210: E3          ex   (sp),hl
7211: 9C          sbc  a,h
7212: CC FE BC    call z,$DAFE
7215: 41          ld   b,c
7216: 00          nop
7217: 06 8C       ld   b,$C8
7219: FE 6F       cp   $E7
721B: 41          ld   b,c
721C: 23          inc  hl
721D: 15          dec  d
721E: 82          add  a,d
721F: FE B2       cp   $3A
7221: 60          ld   h,b
7222: 00          nop
7223: 0C          inc  c
7224: 4C          ld   c,h
7225: FE B2       cp   $3A
7227: 60          ld   h,b
7228: 00          nop
7229: 0A          ld   a,(bc)
722A: 0C          inc  c
722B: FE B4       cp   $5A
722D: 60          ld   h,b
722E: 00          nop
722F: 02          ld   (bc),a
7230: DA FE BA    jp   c,$BAFE
7233: 60          ld   h,b
7234: 00          nop
7235: 08          ex   af,af'
7236: 9A          sbc  a,d
7237: FE BC       cp   $DA
7239: 60          ld   h,b
723A: 00          nop
723B: 02          ld   (bc),a
723C: 5A          ld   e,d
723D: FE 0E       cp   $E0
723F: 60          ld   h,b
7240: 23          inc  hl
7241: 13          inc  de
7242: 82          add  a,d
7243: FE BC       cp   $DA
7245: 60          ld   h,b
7246: 00          nop
7247: 04          inc  b
7248: 5C          ld   e,h
7249: FE B0       cp   $1A
724B: 61          ld   h,c
724C: 00          nop
724D: 0E 1C       ld   c,$D0
724F: FE 02       cp   $20
7251: 61          ld   h,c
7252: 23          inc  hl
7253: 0C          inc  c
7254: 42          ld   b,d
7255: FE 5C       cp   $D4
7257: 61          ld   h,c
7258: 50          ld   d,b
7259: 14          inc  d
725A: 16 FE       ld   d,$FE
725C: FF          rst  $38
725D: 61          ld   h,c
725E: 02          ld   (bc),a
725F: 00          nop
7260: 40          ld   b,b
7261: FE 14       cp   $50
7263: 80          add  a,b
7264: A3          and  e
7265: 01 8A FE    ld   bc,$FEA8
7268: 18 80       jr   $7272
726A: A3          and  e
726B: 21 96 FE    ld   hl,$FE78
726E: 33          inc  sp
726F: 81          add  a,c
7270: F1          pop  af
7271: 00          nop
7272: 12          ld   (de),a
7273: FE 14       cp   $50
7275: 81          add  a,c
7276: A3          and  e
7277: 20 8A       jr   nz,$7221
7279: FE 1C       cp   $D0
727B: 81          add  a,c
727C: 23          inc  hl
727D: 14          inc  d
727E: 82          add  a,d
727F: FE 0E       cp   $E0
7281: 81          add  a,c
7282: A3          and  e
7283: 00          nop
7284: 18 FE       jr   $7284
7286: 00          nop
7287: A0          and  b
7288: A3          and  e
7289: 20 96       jr   nz,$7303
728B: FE 10       cp   $10
728D: A0          and  b
728E: E0          ret  po
728F: 0C          inc  c
7290: 5C          ld   e,h
7291: FE 10       cp   $10
7293: A0          and  b
7294: E0          ret  po
7295: 0A          ld   a,(bc)
7296: 1C          inc  e
7297: FE 14       cp   $50
7299: A0          and  b
729A: E0          ret  po
729B: 90          sub  b
729C: CC FE 14    call z,$50FE
729F: A0          and  b
72A0: E0          ret  po
72A1: 92          sub  d
72A2: 8C          adc  a,h
72A3: FE 06       cp   $60
72A5: A0          and  b
72A6: E0          ret  po
72A7: 0C          inc  c
72A8: 4C          ld   c,h
72A9: FE 0C       cp   $C0
72AB: A0          and  b
72AC: 23          inc  hl
72AD: 3C          inc  a
72AE: 82          add  a,d
72AF: FE 18       cp   $90
72B1: A0          and  b
72B2: E0          ret  po
72B3: 06 0C       ld   b,$C0
72B5: FE 18       cp   $90
72B7: A0          and  b
72B8: E0          ret  po
72B9: 08          ex   af,af'
72BA: DA FE 1C    jp   c,$D0FE
72BD: A0          and  b
72BE: E0          ret  po
72BF: 1C          inc  e
72C0: 9A          sbc  a,d
72C1: FE 02       cp   $20
72C3: A1          and  c
72C4: E0          ret  po
72C5: 12          ld   (de),a
72C6: 5C          ld   e,h
72C7: FE 14       cp   $50
72C9: A1          and  c
72CA: E0          ret  po
72CB: 16 1C       ld   d,$D0
72CD: FE 14       cp   $50
72CF: A1          and  c
72D0: E0          ret  po
72D1: 18 CC       jr   $729F
72D3: FE 14       cp   $50
72D5: A1          and  c
72D6: E0          ret  po
72D7: 8A          adc  a,d
72D8: 8C          adc  a,h
72D9: FE 18       cp   $90
72DB: A1          and  c
72DC: E0          ret  po
72DD: 12          ld   (de),a
72DE: 4C          ld   c,h
72DF: FE 1E       cp   $F0
72E1: A1          and  c
72E2: 23          inc  hl
72E3: 0A          ld   a,(bc)
72E4: 82          add  a,d
72E5: FE 11       cp   $11
72E7: C0          ret  nz
72E8: B1          or   c
72E9: 06 C8       ld   b,$8C
72EB: FE 0D       cp   $C1
72ED: C0          ret  nz
72EE: 30 A3       jr   nc,$731B
72F0: D6 FE       sub  $FE
72F2: FF          rst  $38
72F3: C0          ret  nz
72F4: 23          inc  hl
72F5: 05          dec  b
72F6: 82          add  a,d
72F7: FE 08       cp   $80
72F9: C1          pop  bc
72FA: E2 0C 5C    jp   po,$D4C0
72FD: FE 1D       cp   $D1
72FF: C1          pop  bc
7300: 41          ld   b,c
7301: 82          add  a,d
7302: 94          sub  h
7303: FE 15       cp   $51
7305: E0          ret  po
7306: 41          ld   b,c
7307: 8C          adc  a,h
7308: 52          ld   d,d
7309: FE 0C       cp   $C0
730B: E0          ret  po
730C: 23          inc  hl
730D: 0E 82       ld   c,$28
730F: FE 1D       cp   $D1
7311: E0          ret  po
7312: 41          ld   b,c
7313: 82          add  a,d
7314: 94          sub  h
7315: FE 95       cp   $59
7317: E1          pop  hl
7318: 22 1C 48    ld   ($84D0),hl
731B: FE 5C       cp   $D4
731D: E1          pop  hl
731E: 50          ld   d,b
731F: 14          inc  d
7320: 12          ld   (de),a
7321: FE FF       cp   $FF
7323: E1          pop  hl
7324: 02          ld   (bc),a
7325: 00          nop
7326: 40          ld   b,b
7327: FE 29       cp   $83
7329: 10 03       djnz $734C
732B: 8A          adc  a,d
732C: 8C          adc  a,h
732D: FE 2D       cp   $C3
732F: 10 03       djnz $7352
7331: 82          add  a,d
7332: DA FE 0E    jp   c,$E0FE
7335: 10 23       djnz $735A
7337: 0C          inc  c
7338: 82          add  a,d
7339: FE 25       cp   $43
733B: 11 03 83    ld   de,$2921
733E: 1A          ld   a,(de)
733F: FE 25       cp   $43
7341: 11 03 8B    ld   de,$A921
7344: 4A          ld   c,d
7345: FE 2D       cp   $C3
7347: 11 03 86    ld   de,$6821
734A: 98          sbc  a,b
734B: FE 25       cp   $43
734D: 30 03       jr   nc,$7370
734F: 82          add  a,d
7350: 8C          adc  a,h
7351: FE 16       cp   $70
7353: 30 23       jr   nc,$7378
7355: 0D          dec  c
7356: 82          add  a,d
7357: FE 29       cp   $83
7359: 30 03       jr   nc,$737C
735B: 87          add  a,a
735C: DA FE 21    jp   c,$03FE
735F: 31 03 8A    ld   sp,$A821
7362: 1A          ld   a,(de)
7363: FE 25       cp   $43
7365: 31 03 86    ld   sp,$6821
7368: 8C          adc  a,h
7369: FE 1A       cp   $B0
736B: 31 23 32    ld   sp,$3223
736E: 82          add  a,d
736F: FE 11       cp   $11
7371: 50          ld   d,b
7372: B0          or   b
7373: 06 16       ld   b,$70
7375: FE 92       cp   $38
7377: 50          ld   d,b
7378: 91          sub  c
7379: 0E 54       ld   c,$54
737B: FE 0E       cp   $E0
737D: 50          ld   d,b
737E: A0          and  b
737F: ED          db   $ed
7380: 12          ld   (de),a
7381: FE 04       cp   $40
7383: 51          ld   d,c
7384: A0          and  b
7385: ED          db   $ed
7386: 14          inc  d
7387: FE 16       cp   $70
7389: 51          ld   d,c
738A: A1          and  c
738B: 16 16       ld   d,$70
738D: FE 1A       cp   $B0
738F: 51          ld   d,c
7390: A3          and  e
7391: 21 18 FE    ld   hl,$FE90
7394: 00          nop
7395: 70          ld   (hl),b
7396: A3          and  e
7397: 01 8A FE    ld   bc,$FEA8
739A: 04          inc  b
739B: 70          ld   (hl),b
739C: A3          and  e
739D: 21 0C FE    ld   hl,$FEC0
73A0: 08          ex   af,af'
73A1: 70          ld   (hl),b
73A2: A3          and  e
73A3: 21 18 FE    ld   hl,$FE90
73A6: 0C          inc  c
73A7: 70          ld   (hl),b
73A8: A3          and  e
73A9: 00          nop
73AA: C6 FE       add  a,$FE
73AC: 00          nop
73AD: 71          ld   (hl),c
73AE: A3          and  e
73AF: 20 48       jr   nz,$7335
73B1: FE 04       cp   $40
73B3: 71          ld   (hl),c
73B4: A3          and  e
73B5: 00          nop
73B6: D8          ret  c
73B7: FE 08       cp   $80
73B9: 71          ld   (hl),c
73BA: A3          and  e
73BB: 00          nop
73BC: 5A          ld   e,d
73BD: FE 0A       cp   $A0
73BF: 71          ld   (hl),c
73C0: 23          inc  hl
73C1: 07          rlca
73C2: 82          add  a,d
73C3: FE 0A       cp   $A0
73C5: 71          ld   (hl),c
73C6: 23          inc  hl
73C7: 0B          dec  bc
73C8: 02          ld   (bc),a
73C9: FE 1A       cp   $B0
73CB: 71          ld   (hl),c
73CC: 21 02 C8    ld   hl,$8C20
73CF: FE 1A       cp   $B0
73D1: 71          ld   (hl),c
73D2: 21 1C D6    ld   hl,$7CD0
73D5: FE 5C       cp   $D4
73D7: 71          ld   (hl),c
73D8: 50          ld   d,b
73D9: 14          inc  d
73DA: 12          ld   (de),a
73DB: FE FF       cp   $FF
73DD: 71          ld   (hl),c
73DE: 02          ld   (bc),a
73DF: 00          nop
73E0: 40          ld   b,b
73E1: FE 06       cp   $60
73E3: 91          sub  c
73E4: 23          inc  hl
73E5: 1D          dec  e
73E6: 82          add  a,d
73E7: FE B8       cp   $9A
73E9: B0          or   b
73EA: 00          nop
73EB: 90          sub  b
73EC: CA FE B8    jp   z,$9AFE
73EF: B0          or   b
73F0: 00          nop
73F1: 92          sub  d
73F2: 8A          adc  a,d
73F3: FE 1C       cp   $D0
73F5: B0          or   b
73F6: 23          inc  hl
73F7: 32 82 FE    ld   ($FE28),a
73FA: 14          inc  d
73FB: D0          ret  nc
73FC: 23          inc  hl
73FD: 05          dec  b
73FE: 82          add  a,d
73FF: FE 14       cp   $50
7401: D1          pop  de
7402: 23          inc  hl
7403: 1B          dec  de
7404: 82          add  a,d
7405: FE F7       cp   $7F
7407: D1          pop  de
7408: A3          and  e
7409: 21 D6 FE    ld   hl,$FE7C
740C: 08          ex   af,af'
740D: D1          pop  de
740E: 63          ld   h,e
740F: 1C          inc  e
7410: 12          ld   (de),a
7411: FE 0A       cp   $A0
7413: D1          pop  de
7414: A3          and  e
7415: 21 18 FE    ld   hl,$FE90
7418: 1C          inc  e
7419: D1          pop  de
741A: A3          and  e
741B: 21 4A FE    ld   hl,$FEA4
741E: 01 F0 30    ld   bc,$121E
7421: A3          and  e
7422: D6 FE       sub  $FE
7424: 1C          inc  e
7425: F0          ret  p
7426: 23          inc  hl
7427: 1C          inc  e
7428: 82          add  a,d
7429: FE 08       cp   $80
742B: F1          pop  af
742C: A3          and  e
742D: 21 18 FE    ld   hl,$FE90
7430: 19          add  hl,de
7431: F1          pop  af
7432: 82          add  a,d
7433: 06 12       ld   b,$30
7435: FE D9       cp   $9D
7437: F1          pop  af
7438: 62          ld   h,d
7439: 92          sub  d
743A: 1A          ld   a,(de)
743B: FE D9       cp   $9D
743D: F1          pop  af
743E: 62          ld   h,d
743F: 9A          sbc  a,d
7440: CA FE 1A    jp   z,$B0FE
7443: F1          pop  af
7444: A3          and  e
7445: 21 18 FE    ld   hl,$FE90
7448: DD          db   $dd
7449: F1          pop  af
744A: 62          ld   h,d
744B: 06 8A       ld   b,$A8
744D: FE DD       cp   $DD
744F: F1          pop  af
7450: 62          ld   h,d
7451: 18 4A       jr   $73F7
7453: FE 0C       cp   $C0
7455: 04          inc  b
7456: E2 04 5C    jp   po,$D440
7459: FE 1C       cp   $D0
745B: 05          dec  b
745C: 23          inc  hl
745D: 13          inc  de
745E: 82          add  a,d
745F: FE 1C       cp   $D0
7461: 25          dec  h
7462: 23          inc  hl
7463: 02          ld   (bc),a
7464: 82          add  a,d
7465: FE 11       cp   $11
7467: 44          ld   b,h
7468: B0          or   b
7469: 06 0A       ld   b,$A0
746B: FE 53       cp   $35
746D: 44          ld   b,h
746E: A2          and  d
746F: 0E C8       ld   c,$8C
7471: FE 71       cp   $17
7473: 45          ld   b,l
7474: E3          ex   (sp),hl
7475: 8A          adc  a,d
7476: 56          ld   d,(hl)
7477: FE 08       cp   $80
7479: 45          ld   b,l
747A: 21 9C CC    ld   hl,$CCD8
747D: FE 18       cp   $90
747F: 45          ld   b,l
7480: 23          inc  hl
7481: 3C          inc  a
7482: 82          add  a,d
7483: FE 79       cp   $97
7485: 45          ld   b,l
7486: E3          ex   (sp),hl
7487: 82          add  a,d
7488: 8C          adc  a,h
7489: FE 7D       cp   $D7
748B: 45          ld   b,l
748C: E3          ex   (sp),hl
748D: 9A          sbc  a,d
748E: 0C          inc  c
748F: FE 0E       cp   $E0
7491: 45          ld   b,l
7492: 21 90 5A    ld   hl,$B418
7495: FE 1E       cp   $F0
7497: 45          ld   b,l
7498: 23          inc  hl
7499: 93          sub  e
749A: 02          ld   (bc),a
749B: FE 73       cp   $37
749D: 64          ld   h,h
749E: E3          ex   (sp),hl
749F: 90          sub  b
74A0: 1A          ld   a,(de)
74A1: FE 77       cp   $77
74A3: 64          ld   h,h
74A4: E3          ex   (sp),hl
74A5: 98          sbc  a,b
74A6: 8A          adc  a,d
74A7: FE 7B       cp   $B7
74A9: 64          ld   h,h
74AA: E3          ex   (sp),hl
74AB: 8C          adc  a,h
74AC: 4A          ld   c,d
74AD: FE 0C       cp   $C0
74AF: 64          ld   h,h
74B0: E2 04 5C    jp   po,$D440
74B3: FE BC       cp   $DA
74B5: 64          ld   h,h
74B6: 00          nop
74B7: 8A          adc  a,d
74B8: 0A          ld   a,(bc)
74B9: FE 1E       cp   $F0
74BB: 64          ld   h,h
74BC: 23          inc  hl
74BD: 9B          sbc  a,e
74BE: 82          add  a,d
74BF: FE B8       cp   $9A
74C1: 65          ld   h,l
74C2: 00          nop
74C3: 92          sub  d
74C4: D8          ret  c
74C5: FE B8       cp   $9A
74C7: 65          ld   h,l
74C8: 00          nop
74C9: 8C          adc  a,h
74CA: 98          sbc  a,b
74CB: FE 5C       cp   $D4
74CD: 65          ld   h,l
74CE: 50          ld   d,b
74CF: 14          inc  d
74D0: 12          ld   (de),a
74D1: FE 19       cp   $91
74D3: 84          add  a,h
74D4: 41          ld   b,c
74D5: 82          add  a,d
74D6: 12          ld   (de),a
74D7: FE 1D       cp   $D1
74D9: 84          add  a,h
74DA: 41          ld   b,c
74DB: 8C          adc  a,h
74DC: 54          ld   d,h
74DD: FE 15       cp   $51
74DF: 85          add  a,l
74E0: 41          ld   b,c
74E1: 82          add  a,d
74E2: 96          sub  (hl)
74E3: FE 1D       cp   $D1
74E5: 85          add  a,l
74E6: 41          ld   b,c
74E7: 8C          adc  a,h
74E8: 12          ld   (de),a
74E9: FE 99       cp   $99
74EB: A4          and  h
74EC: 43          ld   b,e
74ED: 00          nop
74EE: 5A          ld   e,d
74EF: FE 1C       cp   $D0
74F1: A4          and  h
74F2: 23          inc  hl
74F3: 04          inc  b
74F4: 82          add  a,d
74F5: FE 9D       cp   $D9
74F7: A4          and  h
74F8: 43          ld   b,e
74F9: 00          nop
74FA: 58          ld   e,b
74FB: FE 91       cp   $19
74FD: A5          and  l
74FE: 43          ld   b,e
74FF: 00          nop
7500: 56          ld   d,(hl)
7501: FE 04       cp   $40
7503: A5          and  l
7504: 23          inc  hl
7505: 0C          inc  c
7506: C2 FE 95    jp   nz,$59FE
7509: A5          and  l
750A: 43          ld   b,e
750B: 00          nop
750C: 54          ld   d,h
750D: FE 99       cp   $99
750F: A5          and  l
7510: 43          ld   b,e
7511: 00          nop
7512: 52          ld   d,d
7513: FE 11       cp   $11
7515: C4 B1 06    call nz,$601B
7518: D8          ret  c
7519: FE 18       cp   $90
751B: C4 E0 0E    call nz,$E00E
751E: 58          ld   e,b
751F: FE 0A       cp   $A0
7521: C4 E0 82    call nz,$280E
7524: C8          ret  z
7525: FE 1C       cp   $D0
7527: C4 E0 8A    call nz,$A80E
752A: 88          adc  a,b
752B: FE 00       cp   $00
752D: C5          push bc
752E: 23          inc  hl
752F: 13          inc  de
7530: 82          add  a,d
7531: FE 04       cp   $40
7533: C5          push bc
7534: E2 04 5C    jp   po,$D440
7537: FE 0A       cp   $A0
7539: C5          push bc
753A: E0          ret  po
753B: 16 08       ld   d,$80
753D: FE 0A       cp   $A0
753F: C5          push bc
7540: E0          ret  po
7541: 18 D6       jr   $75BF
7543: FE 0A       cp   $A0
7545: C5          push bc
7546: E0          ret  po
7547: 1A          ld   a,(de)
7548: 96          sub  (hl)
7549: FE 0E       cp   $E0
754B: C5          push bc
754C: E0          ret  po
754D: 12          ld   (de),a
754E: 16 FE       ld   d,$FE
7550: 10 E4       djnz $75A0
7552: E0          ret  po
7553: 0A          ld   a,(bc)
7554: 5C          ld   e,h
7555: FE 10       cp   $10
7557: E4 E0 0C    call po,$C00E
755A: 1C          inc  e
755B: FE 06       cp   $60
755D: E4 E0 1A    call po,$B00E
7560: CC FE 96    call z,$78FE
7563: E4 23 3A    call po,$B223
7566: 82          add  a,d
7567: FE 0C       cp   $C0
7569: E4 E2 0C    call po,$C02E
756C: CA FE 02    jp   z,$20FE
756F: E5          push hl
7570: E0          ret  po
7571: 14          inc  d
7572: 4C          ld   c,h
7573: FE 02       cp   $20
7575: E5          push hl
7576: E0          ret  po
7577: 16 0C       ld   d,$C0
7579: FE 14       cp   $50
757B: E5          push hl
757C: E0          ret  po
757D: 1A          ld   a,(de)
757E: DA FE 14    jp   c,$50FE
7581: E5          push hl
7582: E0          ret  po
7583: 0C          inc  c
7584: 9A          sbc  a,d
7585: FE 18       cp   $90
7587: E5          push hl
7588: E0          ret  po
7589: 04          inc  b
758A: 1A          ld   a,(de)
758B: FE 5C       cp   $D4
758D: E5          push hl
758E: 50          ld   d,b
758F: 14          inc  d
7590: 12          ld   (de),a
7591: FE 04       cp   $40
7593: 14          inc  d
7594: 83          add  a,e
7595: 90          sub  b
7596: CC FE 04    call z,$40FE
7599: 14          inc  d
759A: 83          add  a,e
759B: 95          sub  l
759C: 0C          inc  c
759D: FE 0A       cp   $A0
759F: 14          inc  d
75A0: 83          add  a,e
75A1: 10 8A       djnz $754B
75A3: FE 0A       cp   $A0
75A5: 14          inc  d
75A6: 83          add  a,e
75A7: 99          sbc  a,c
75A8: D8          ret  c
75A9: FE 1C       cp   $D0
75AB: 14          inc  d
75AC: 23          inc  hl
75AD: 82          add  a,d
75AE: 82          add  a,d
75AF: FE 00       cp   $00
75B1: 15          dec  d
75B2: 83          add  a,e
75B3: 90          sub  b
75B4: 48          ld   c,b
75B5: FE 00       cp   $00
75B7: 15          dec  d
75B8: 83          add  a,e
75B9: 99          sbc  a,c
75BA: CC FE 06    call z,$60FE
75BD: 15          dec  d
75BE: 83          add  a,e
75BF: 10 0C       djnz $7581
75C1: FE 06       cp   $60
75C3: 15          dec  d
75C4: 83          add  a,e
75C5: BC          cp   h
75C6: 8A          adc  a,d
75C7: FE 0C       cp   $C0
75C9: 15          dec  d
75CA: 83          add  a,e
75CB: 90          sub  b
75CC: D8          ret  c
75CD: FE 04       cp   $40
75CF: 34          inc  (hl)
75D0: 83          add  a,e
75D1: 90          sub  b
75D2: 48          ld   c,b
75D3: FE 04       cp   $40
75D5: 34          inc  (hl)
75D6: 83          add  a,e
75D7: 95          sub  l
75D8: 96          sub  (hl)
75D9: FE 18       cp   $90
75DB: 34          inc  (hl)
75DC: 23          inc  hl
75DD: 1D          dec  e
75DE: 82          add  a,d
75DF: FE 18       cp   $90
75E1: 34          inc  (hl)
75E2: 23          inc  hl
75E3: 13          inc  de
75E4: 82          add  a,d
75E5: FE 0C       cp   $C0
75E7: 34          inc  (hl)
75E8: 83          add  a,e
75E9: 95          sub  l
75EA: 0C          inc  c
75EB: FE 02       cp   $20
75ED: 35          dec  (hl)
75EE: 83          add  a,e
75EF: 10 8A       djnz $7599
75F1: FE 04       cp   $40
75F3: 35          dec  (hl)
75F4: 83          add  a,e
75F5: 97          sub  a
75F6: 18 FE       jr   $75F6
75F8: 1C          inc  e
75F9: 35          dec  (hl)
75FA: 23          inc  hl
75FB: 2C          inc  l
75FC: 82          add  a,d
75FD: FE 1C       cp   $D0
75FF: 35          dec  (hl)
7600: 71          ld   (hl),c
7601: 82          add  a,d
7602: 04          inc  b
7603: FE 11       cp   $11
7605: 54          ld   d,h
7606: B0          or   b
7607: 06 0A       ld   b,$A0
7609: FE 53       cp   $35
760B: 54          ld   d,h
760C: 91          sub  c
760D: 0E 96       ld   c,$78
760F: FE 45       cp   $45
7611: 54          ld   d,h
7612: 91          sub  c
7613: 0E C8       ld   c,$8C
7615: FE 82       cp   $28
7617: 55          ld   d,l
7618: A0          and  b
7619: ED          db   $ed
761A: 12          ld   (de),a
761B: FE 04       cp   $40
761D: 74          ld   (hl),h
761E: C2 00 14    jp   nz,$5000
7621: FE 12       cp   $30
7623: 74          ld   (hl),h
7624: 23          inc  hl
7625: 13          inc  de
7626: 82          add  a,d
7627: FE 04       cp   $40
7629: 74          ld   (hl),h
762A: C2 00 06    jp   nz,$6000
762D: FE 16       cp   $70
762F: 74          ld   (hl),h
7630: C2 00 16    jp   nz,$7000
7633: FE 0A       cp   $A0
7635: 74          ld   (hl),h
7636: C3 00 08    jp   $8000
7639: FE 1C       cp   $D0
763B: 74          ld   (hl),h
763C: C3 00 98    jp   $9800
763F: FE 00       cp   $00
7641: 75          ld   (hl),l
7642: C2 00 1A    jp   nz,$B000
7645: FE 04       cp   $40
7647: 75          ld   (hl),l
7648: C3 00 0C    jp   $C000
764B: FE 18       cp   $90
764D: 75          ld   (hl),l
764E: C3 00 88    jp   $8800
7651: FE 0A       cp   $A0
7653: 75          ld   (hl),l
7654: C2 00 96    jp   nz,$7800
7657: FE 5C       cp   $D4
7659: 75          ld   (hl),l
765A: 50          ld   d,b
765B: 14          inc  d
765C: 12          ld   (de),a
765D: FE 75       cp   $57
765F: 94          sub  h
7660: 00          nop
7661: 14          inc  d
7662: 5C          ld   e,h
7663: FE 75       cp   $57
7665: 94          sub  h
7666: 00          nop
7667: 96          sub  (hl)
7668: 1C          inc  e
7669: FE B2       cp   $3A
766B: 95          sub  l
766C: 00          nop
766D: 90          sub  b
766E: 88          adc  a,b
766F: FE B2       cp   $3A
7671: 95          sub  l
7672: 00          nop
7673: 12          ld   (de),a
7674: 48          ld   c,b
7675: FE B2       cp   $3A
7677: 95          sub  l
7678: 00          nop
7679: 1C          inc  e
767A: 08          ex   af,af'
767B: FE 14       cp   $50
767D: 95          sub  l
767E: 23          inc  hl
767F: 42          ld   b,d
7680: 82          add  a,d
7681: FE 09       cp   $81
7683: 95          sub  l
7684: 30 A3       jr   nc,$76B1
7686: 16 FE       ld   d,$FE
7688: 0E 95       ld   c,$59
768A: 71          ld   (hl),c
768B: 12          ld   (de),a
768C: 4C          ld   c,h
768D: FE 0C       cp   $C0
768F: B4          or   h
7690: A3          and  e
7691: 20 12       jr   nz,$76C3
7693: FE 0E       cp   $E0
7695: B4          or   h
7696: A3          and  e
7697: 20 44       jr   nz,$76DD
7699: FE 00       cp   $00
769B: B5          or   l
769C: A3          and  e
769D: 21 D4 FE    ld   hl,$FE5C
76A0: 12          ld   (de),a
76A1: B5          or   l
76A2: A3          and  e
76A3: 20 18       jr   nz,$7635
76A5: FE 14       cp   $50
76A7: B5          or   l
76A8: 71          ld   (hl),c
76A9: 82          add  a,d
76AA: 4C          ld   c,h
76AB: FE 06       cp   $60
76AD: B5          or   l
76AE: A3          and  e
76AF: 21 4A FE    ld   hl,$FEA4
76B2: 16 B5       ld   d,$5B
76B4: 23          inc  hl
76B5: 03          inc  bc
76B6: 82          add  a,d
76B7: FE 18       cp   $90
76B9: B5          or   l
76BA: A3          and  e
76BB: 21 12 FE    ld   hl,$FE30
76BE: 0C          inc  c
76BF: B5          or   l
76C0: A3          and  e
76C1: 21 44 FE    ld   hl,$FE44
76C4: 08          ex   af,af'
76C5: D4 A3 21    call nc,$032B
76C8: 94          sub  h
76C9: FE 1A       cp   $B0
76CB: D4 23 32    call nc,$3223
76CE: 82          add  a,d
76CF: FE 0C       cp   $C0
76D1: D4 A3 21    call nc,$032B
76D4: 44          ld   b,h
76D5: FE 0D       cp   $C1
76D7: D4 30 A3    call nc,$2B12
76DA: 12          ld   (de),a
76DB: FE 00       cp   $00
76DD: D5          push de
76DE: A3          and  e
76DF: 21 94 FE    ld   hl,$FE58
76E2: 04          inc  b
76E3: D5          push de
76E4: A3          and  e
76E5: 21 C6 FE    ld   hl,$FE6C
76E8: 0C          inc  c
76E9: D5          push de
76EA: 23          inc  hl
76EB: 05          dec  b
76EC: 82          add  a,d
76ED: FE 00       cp   $00
76EF: F4 63 17    call p,$7127
76F2: 12          ld   (de),a
76F3: FE 00       cp   $00
76F5: F4 63 14    call p,$5027
76F8: 86          add  a,(hl)
76F9: FE 04       cp   $40
76FB: F5          push af
76FC: A3          and  e
76FD: 21 4C FE    ld   hl,$FEC4
7700: 84          add  a,h
7701: F5          push af
7702: 23          inc  hl
7703: 0B          dec  bc
7704: 82          add  a,d
7705: FE 16       cp   $70
7707: F5          push af
7708: A3          and  e
7709: 20 5A       jr   nz,$76BF
770B: FE 19       cp   $91
770D: F5          push af
770E: 82          add  a,d
770F: 06 12       ld   b,$30
7711: FE D9       cp   $9D
7713: F5          push af
7714: 62          ld   h,d
7715: 92          sub  d
7716: 1A          ld   a,(de)
7717: FE D9       cp   $9D
7719: F5          push af
771A: 62          ld   h,d
771B: 9A          sbc  a,d
771C: CA FE 0A    jp   z,$A0FE
771F: F5          push af
7720: A3          and  e
7721: 21 D8 FE    ld   hl,$FE9C
7724: DD          db   $dd
7725: F5          push af
7726: 62          ld   h,d
7727: 06 8A       ld   b,$A8
7729: FE DD       cp   $DD
772B: F5          push af
772C: 62          ld   h,d
772D: 18 4A       jr   $76D3
772F: FE FF       cp   $FF

8000: FB          ei
8001: CD 61 08    call $8007
8004: C3 00 08    jp   $8000
8007: 2A 28 CF    ld   hl,($ED82)
800A: 7E          ld   a,(hl)
800B: 3C          inc  a
800C: C8          ret  z
800D: 3D          dec  a
800E: 57          ld   d,a
800F: 36 FF       ld   (hl),$FF
8011: 2C          inc  l
8012: 5E          ld   e,(hl)
8013: 36 FF       ld   (hl),$FF
8015: 2C          inc  l
8016: 7D          ld   a,l
8017: FE 04       cp   $40
8019: 38 20       jr   c,$801D
801B: 2E 00       ld   l,$00
801D: 22 28 CF    ld   ($ED82),hl
8020: 7B          ld   a,e
8021: 32 48 CF    ld   ($ED84),a
8024: 7A          ld   a,d
8025: 32 49 CF    ld   ($ED85),a
8028: F7          rst  $30
8029: BB          cp   e
802A: 09          add  hl,bc
802B: 6C          ld   l,h
802C: 09          add  hl,bc
802D: 1D          dec  e
802E: 09          add  hl,bc
802F: D5          push de
8030: 28 06       jr   z,$8092
8032: 28 D0       jr   z,$8050
8034: 49          ld   c,c
8035: A9          xor  c
8036: F9          ld   sp,hl
8037: DC 09 61    call c,$0781
803A: 68          ld   l,b
803B: 2A 09 29    ld   hl,($8381)
803E: 09          add  hl,bc
803F: 12          ld   (de),a
8040: 09          add  hl,bc
8041: 82          add  a,d
8042: EB          ex   de,hl
8043: 76          halt
8044: 08          ex   af,af'
8045: 65          ld   h,l
8046: 08          ex   af,af'
8047: 3A 62 0E    ld   a,($E026)
804A: A7          and  a
804B: C8          ret  z
804C: 21 CA 29    ld   hl,$83AC
804F: CD C7 D8    call $9C6D                 ; call PRINT_TEXT
8052: 3A 62 0E    ld   a,($E026)
8055: E6 E1       and  $0F
8057: 32 A3 3C    ld   ($D22B),a
805A: 3A 82 0E    ld   a,($E028)
805D: CB 67       bit  4,a
805F: 20 E1       jr   nz,$8070
8061: 21 2D 29    ld   hl,$83C3
8064: CD C7 D8    call $9C6D                 ; call PRINT_TEXT 
8067: 3A 82 0E    ld   a,($E028)
806A: E6 E1       and  $0F
806C: 32 83 3C    ld   ($D229),a
806F: C9          ret
8070: 21 BD 29    ld   hl,$83DB
8073: CD C7 D8    call $9C6D                 ; call PRINT_TEXT 
8076: CD D1 09    call $811D
8079: AF          xor  a
807A: 32 1A 0E    ld   ($E0B0),a
807D: 32 EB 0E    ld   ($E0AF),a
8080: 32 EA 0E    ld   ($E0AE),a
8083: 21 1A 0E    ld   hl,$E0B0
8086: 3A 8B CF    ld   a,($EDA9)
8089: A7          and  a
808A: C8          ret  z
808B: FE A0       cp   $0A
808D: 38 A0       jr   c,$8099
808F: 34          inc  (hl)
8090: D6 A0       sub  $0A
8092: 28 90       jr   z,$80AC
8094: 30 9F       jr   nc,$808F
8096: C6 A0       add  a,$0A
8098: 35          dec  (hl)
8099: 21 EB 0E    ld   hl,$E0AF
809C: FE 41       cp   $05
809E: 38 41       jr   c,$80A5
80A0: 34          inc  (hl)
80A1: D6 41       sub  $05
80A3: 28 61       jr   z,$80AC
80A5: 21 EA 0E    ld   hl,$E0AE
80A8: 34          inc  (hl)
80A9: 3D          dec  a
80AA: 20 DE       jr   nz,$80A8
80AC: 21 0B 3D    ld   hl,$D3A1
80AF: 3A EA 0E    ld   a,($E0AE)
80B2: A7          and  a
80B3: 28 81       jr   z,$80BE
80B5: 11 41 09    ld   de,$8105
80B8: 47          ld   b,a
80B9: 0E 01       ld   c,$01
80BB: CD 9C 08    call $80D8
80BE: 3A EB 0E    ld   a,($E0AF)
80C1: A7          and  a
80C2: 28 81       jr   z,$80CD
80C4: 47          ld   b,a
80C5: 0E 01       ld   c,$01
80C7: 11 81 09    ld   de,$8109
80CA: CD 9C 08    call $80D8
80CD: 3A 1A 0E    ld   a,($E0B0)
80D0: A7          and  a
80D1: C8          ret  z
80D2: 11 C1 09    ld   de,$810D
80D5: 47          ld   b,a
80D6: 0E 20       ld   c,$02
80D8: D5          push de
80D9: CD EE 08    call $80EE
80DC: 79          ld   a,c
80DD: FE 01       cp   $01
80DF: 28 81       jr   z,$80EA
80E1: D1          pop  de
80E2: D5          push de
80E3: 13          inc  de
80E4: 13          inc  de
80E5: 13          inc  de
80E6: 13          inc  de
80E7: CD EE 08    call $80EE
80EA: D1          pop  de
80EB: 10 AF       djnz $80D8
80ED: C9          ret
80EE: CD BE 08    call $80FA
80F1: 2D          dec  l
80F2: CD BE 08    call $80FA
80F5: 11 0F FF    ld   de,$FFE1
80F8: 19          add  hl,de
80F9: C9          ret
80FA: 1A          ld   a,(de)
80FB: 13          inc  de
80FC: 77          ld   (hl),a
80FD: CB D4       set  2,h
80FF: 1A          ld   a,(de)
8100: 13          inc  de
8101: 77          ld   (hl),a
8102: CB 94       res  2,h
8104: C9          ret
8105: 6A          ld   l,d
8106: 81          add  a,c
8107: 7A          ld   a,d
8108: A1          and  c
8109: 6B          ld   l,e
810A: 81          add  a,c
810B: 7B          ld   a,e
810C: A1          and  c
810D: EA A0 FA    jp   pe,$BE0A
8110: A1          and  c
8111: CB A0       res  4,b
8113: DB A1       in   a,($0B)
8115: EA A0 FA    jp   pe,$BE0A
8118: C0          ret  nz
8119: CB A0       res  4,b
811B: DB C0       in   a,($0C)
811D: 11 02 00    ld   de,$0020
8120: 21 03 3C    ld   hl,$D221
8123: 06 C1       ld   b,$0D
8125: CD 27 09    call $8163
8128: 21 02 3C    ld   hl,$D220
812B: 06 C1       ld   b,$0D
812D: CD 27 09    call $8163
8130: CD 35 09    call $8153
8133: 21 09 1D    ld   hl,$D181
8136: 16 2A       ld   d,$A2
8138: 1E C0       ld   e,$0C
813A: 06 20       ld   b,$02
813C: 0E 20       ld   c,$02
813E: CD 03 68    call $8621
8141: 2D          dec  l
8142: 36 B2       ld   (hl),$3A
8144: CB D4       set  2,h
8146: 71          ld   (hl),c
8147: CB 94       res  2,h
8149: 21 0E 1D    ld   hl,$D1E0
814C: 3A 8A CF    ld   a,($EDA8)             ; read NUM_GRENADES
814F: CD 87 09    call $8169
8152: C9          ret
8153: 11 02 00    ld   de,$0020
8156: 21 09 1D    ld   hl,$D181
8159: 06 20       ld   b,$02
815B: CD 27 09    call $8163
815E: 21 08 1D    ld   hl,$D180
8161: 06 41       ld   b,$05
8163: 36 02       ld   (hl),$20
8165: 19          add  hl,de
8166: 10 BF       djnz $8163
8168: C9          ret
8169: 47          ld   b,a
816A: E6 1E       and  $F0
816C: 28 61       jr   z,$8175
816E: 0F          rrca
816F: 0F          rrca
8170: 0F          rrca
8171: 0F          rrca
8172: CD 96 09    call $8178
8175: 78          ld   a,b
8176: E6 E1       and  $0F
8178: 77          ld   (hl),a
8179: CB D4       set  2,h
817B: 71          ld   (hl),c
817C: CB 94       res  2,h
817E: 3E 02       ld   a,$20
8180: C3 90 00    jp   $0018
8183: 3A 0A CF    ld   a,($EDA0)
8186: 3D          dec  a
8187: C8          ret  z
8188: FE 41       cp   $05
818A: 38 20       jr   c,$818E
818C: 3E 41       ld   a,$05
818E: 47          ld   b,a
818F: 21 05 1C    ld   hl,$D041
8192: C5          push bc
8193: 16 4A       ld   d,$A4
8195: 1E C1       ld   e,$0D
8197: 06 20       ld   b,$02
8199: 0E 20       ld   c,$02
819B: CD 03 68    call $8621
819E: C1          pop  bc
819F: 10 1F       djnz $8192
81A1: C9          ret

81A2: 21 00 1C    ld   hl,$D000
81A5: 0E 02       ld   c,$20
81A7: 06 F0       ld   b,$1E
81A9: 36 02       ld   (hl),$20
81AB: CB D4       set  2,h
81AD: 36 00       ld   (hl),$00
81AF: CB 94       res  2,h
81B1: 2C          inc  l
81B2: 10 5F       djnz $81A9
81B4: 0D          dec  c
81B5: C8          ret  z
81B6: 23          inc  hl
81B7: 23          inc  hl
81B8: C3 6B 09    jp   $81A7
81BB: 21 76 28    ld   hl,$8276
81BE: 3A 48 CF    ld   a,($ED84)
81C1: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
81C2: EB          ex   de,hl
81C3: CD C7 D8    call $9C6D                 ; call PRINT_TEXT 
81C6: 21 76 28    ld   hl,$8276
81C9: 3A 48 CF    ld   a,($ED84)
81CC: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
81CD: EB          ex   de,hl
81CE: C3 48 D8    jp   $9C84

81D1: 3A 91 0E    ld   a,($E019)
81D4: E6 01       and  $01
81D6: C2 8C D8    jp   nz,$9CC8
81D9: C3 3B D8    jp   $9CB3

81DC: 11 71 00    ld   de,$0017
81DF: FF          rst  $38
81E0: 1E 90       ld   e,$18
81E2: FF          rst  $38
81E3: 1E 91       ld   e,$19
81E5: FF          rst  $38
81E6: 1E B0       ld   e,$1A
81E8: FF          rst  $38
81E9: 1E B1       ld   e,$1B
81EB: FF          rst  $38
81EC: 1E D0       ld   e,$1C
81EE: FF          rst  $38
81EF: 1E D1       ld   e,$1D
81F1: FF          rst  $38

81F2: FD 21 46 0E ld   iy,$E064
81F6: DD 21 00 EE ld   ix,$EE00
81FA: 21 13 1D    ld   hl,$D131
81FD: FD 36 00 61 ld   (iy+$00),$07
8201: FD 36 01 00 ld   (iy+$01),$00
8205: 18 01       jr   $8208

8207: C9          ret
8208: E5          push hl
8209: FD 7E 01    ld   a,(iy+$01)
820C: 21 74 28    ld   hl,$8256
820F: DF          rst  $18                   ; call ADD_A_TO_HL
8210: 4E          ld   c,(hl)
8211: E1          pop  hl
8212: DD E5       push ix
8214: D1          pop  de
8215: CD F1 D9    call $9D1F
8218: 36 12       ld   (hl),$30
821A: CB D4       set  2,h
821C: 71          ld   (hl),c
821D: CB 94       res  2,h
821F: 3E 04       ld   a,$40
8221: DF          rst  $18                   ; call ADD_A_TO_HL
8222: D5          push de
8223: DD E1       pop  ix
8225: 06 A0       ld   b,$0A
8227: DD 7E 00    ld   a,(ix+$00)
822A: DD 23       inc  ix
822C: 77          ld   (hl),a
822D: FE D4       cp   $5C
822F: 30 90       jr   nc,$8249
8231: CB D4       set  2,h
8233: 36 00       ld   (hl),$00
8235: CB 94       res  2,h
8237: 3E 02       ld   a,$20
8239: DF          rst  $18                   ; call ADD_A_TO_HL  
823A: 10 AF       djnz $8227
823C: 11 FA DF    ld   de,$FDBE
823F: 19          add  hl,de
8240: FD 34 01    inc  (iy+$01)
8243: FD 35 00    dec  (iy+$00)
8246: 20 0C       jr   nz,$8208
8248: C9          ret
8249: CB D4       set  2,h
824B: 36 01       ld   (hl),$01
824D: CB 94       res  2,h
824F: 3E 02       ld   a,$20
8251: DF          rst  $18                   ; call ADD_A_TO_HL
8252: 10 3D       djnz $8227
8254: 18 6E       jr   $823C
8256: 00          nop
8257: 00          nop
8258: 00          nop
8259: 00          nop
825A: 00          nop
825B: 00          nop
825C: 00          nop
825D: C3 DC D8    jp   $9CDC
8260: 3A 90 0E    ld   a,($E018)
8263: A7          and  a
8264: C0          ret  nz
8265: 21 CC 28    ld   hl,$82CC
8268: CD C7 D8    call $9C6D
826B: 3A 12 0E    ld   a,($E030)
826E: 21 08 3D    ld   hl,$D380
8271: 0E 00       ld   c,$00
8273: C3 D8 D8    jp   $9C9C
8276: CC 28 9D    call z,$D982
8279: 28 0E       jr   z,$825B
827B: 28 6F       jr   z,$8264
827D: 28 5E       jr   z,$8273
827F: 28 60       jr   z,$8287
8281: 29          add  hl,hl
8282: F1          pop  af
8283: 29          add  hl,hl
8284: E2 29 B3    jp   po,$3B83
8287: 29          add  hl,hl
8288: 15          dec  d
8289: 29          add  hl,hl
828A: 67          ld   h,a
828B: 29          add  hl,hl
828C: D6 29       sub  $83
828E: 88          adc  a,b
828F: 29          add  hl,hl
8290: 58          ld   e,b
8291: 29          add  hl,hl
8292: F9          ld   sp,hl
8293: 29          add  hl,hl
8294: CA 29 2D    jp   z,$C383
8297: 29          add  hl,hl
8298: BD          cp   l
8299: 29          add  hl,hl
829A: 3E 29       ld   a,$83
829C: DE 29       sbc  a,$83
829E: E0          ret  po
829F: 48          ld   c,b
82A0: 43          ld   b,e
82A1: 48          ld   c,b
82A2: 12          ld   (de),a
82A3: 48          ld   c,b
82A4: F3          di
82A5: 48          ld   c,b
82A6: 64          ld   h,h
82A7: 48          ld   c,b
82A8: C5          push bc
82A9: 48          ld   c,b
82AA: 54          ld   d,h
82AB: 48          ld   c,b
82AC: B5          or   l
82AD: 48          ld   c,b
82AE: 26 48       ld   h,$84
82B0: 87          add  a,a
82B1: 48          ld   c,b
82B2: 16 48       ld   d,$84
82B4: 77          ld   (hl),a
82B5: 48          ld   c,b
82B6: F6 48       or   $84
82B8: 28 48       jr   z,$823E
82BA: E8          ret  pe
82BB: 48          ld   c,b
82BC: D9          exx
82BD: 48          ld   c,b
82BE: 0B          dec  bc
82BF: 48          ld   c,b
82C0: AB          xor  e
82C1: 48          ld   c,b
82C2: 5B          ld   e,e
82C3: 48          ld   c,b
82C4: 7A          ld   a,d
82C5: 48          ld   c,b
82C6: CD 48 8F    call $E984
82C9: 48          ld   c,b
82CA: 00          nop
82CB: 49          ld   c,c
82CC: 0A          ld   a,(bc)
82CD: 3C          inc  a
82CE: 00          nop

82CF:  43 52 45 44 49 54 20 30 30 40 9F D0 06 31 55 50  CREDIT 00@...1UP
82DF:  40 3F D3 06 32 55 50 40 9F D1 06 54 4F 50 5F 53  @?..2UP@...TOP_S
82EF:  43 4F 52 45 40 33 D1 01 52 41 4E 4B 49 4E 47 20  CORE@3..RANKING 
82FF:  42 45 53 54 20 37 40 A8 D0 00 53 45 4C 45 43 54  BEST 7@...SELECT
830F:  20 31 20 4F 52 20 32 20 50 4C 41 59 45 52 53 40   1 OR 2 PLAYERS@
831F:  4D D1 01 49 4E 53 45 52 54 20 43 4F 49 4E 40 A0  M..INSERT COIN@.
832F:  D2 00 46 52 45 45 20 50 4C 41 59 40 EC D0 00 50  ..FREE PLAY@...P
833F:  55 53 48 20 53 54 41 52 54 20 42 55 54 54 4F 4E  USH START BUTTON
834F:  20 40 EA D0 00 4F 4E 45 20 4F 52 20 54 57 4F 20   @...ONE OR TWO 
835F:  50 4C 41 59 45 52 53 40 EA D0 00 20 4F 4E 45 20  PLAYERS@... ONE 
836F:  50 4C 41 59 45 52 20 4F 4E 4C 59 20 40 8F D1 00  PLAYER ONLY @...
837F:  50 4C 41 59 45 52 20 31 40 8F D1 00 50 4C 41 59  PLAYER 1@...PLAY
838F:  45 52 20 32 40 8D D1 00 20 52 45 41 44 59 20 40  ER 2@... READY @
839F:  8D D1 00 47 41 4D 45 20 4F 56 45 52 40 EB D0 00  ...GAME OVER@...
83AF:  31 53 54 20 42 4F 4E 55 53 20 31 30 30 30 30 20  1ST BONUS 10000 
83BF:  50 54 53 40 E9 D0 00 41 4E 44 20 45 56 45 52 59  PTS@...AND EVERY
83CF:  20 31 30 30 30 30 30 20 50 54 53 40 E9 D0 00 41   100000 PTS@...A
83DF:  4E 44 20 45 56 45 52 59 20 35 30 30 30 30 20 50  ND EVERY 50000 P
83EF:  54 53 40 A3 D1 05 43 41 50 43 4F 4D 40 22 D1 05  TS@...CAPCOM@"..
83FF:  43 4F 50 59 52 49 47 48 54 20 31 39 38 35 40 C1  COPYRIGHT 1985@.
840F:  D0 05 41 4C 4C 20 52 49 47 48 54 53 20 52 45 53  ..ALL RIGHTS RES
841F:  45 52 56 45 44 40 F5 D1 00 50 4C 41 59 45 52 20  ERVED@...PLAYER 
842F:  40 4D D1 02 49 4E 53 45 52 54 20 43 4F 49 4E 40  @M..INSERT COIN@
843F:  B1 D0 00 31 53 54 40 AF D0 00 32 4E 44 40 AD D0  ...1ST@...2ND@..
844F:  00 33 52 44 40 AB D0 00 34 54 48 40 A9 D0 00 35  .3RD@...4TH@...5
845F:  54 48 40 A7 D0 00 36 54 48 40 A5 D0 00 37 54 48  TH@...6TH@...7TH
846F:  40 E6 D2 40 67 68 69 40 E5 D2 40 77 78 79 40 00  @..@ghi@..@wxy@.
847F:  D0 00 40 7C D0 01 54 49 4D 45 52 20 20 20 40 79  ..@|..TIMER   @y
848F:  D1 05 2E 2E 2E 2E 2E 2E 2E 2E 2E 2E 7E 40 00 D0  ............~@..
849F:  00 40 88 D0 40 6A 6B 6C 6D 6E 6F 40 87 D0 40 7A  .@..@jklmno@..@z
84AF:  7B 7C 7D 7E 7F 40 40 96 D0 00 20 20 20 20 20 43  {|}~.@@...     C
84BF:  4F 4E 47 52 41 54 55 4C 41 54 49 4F 4E 40 94 D0  ONGRATULATION@..
84CF:  00 59 4F 55 52 20 46 49 52 53 54 20 44 55 54 59  .YOUR FIRST DUTY
84DF:  20 46 49 4E 49 53 48 45 44 40 96 D0 00 20 20 20   FINISHED@...   
84EF:  20 20 43 4F 4E 47 52 41 54 55 4C 41 54 49 4F 4E    CONGRATULATION
84FF:  40 94 D0 00 59 4F 55 52 20 45 56 45 52 59 20 44  @...YOUR EVERY D
850F:  55 54 59 20 46 49 4E 49 53 48 45 44 40 B2 00 E0  UTY FINISHED@...

851C: 3A 00 0E    ld   a,($E000)
851F: 3D          dec  a
8520: C8          ret  z
8521: 21 19 EE    ld   hl,$EE91
8524: 3A 91 0E    ld   a,($E019)
8527: E6 01       and  $01
8529: 28 21       jr   z,$852E
852B: 21 58 EE    ld   hl,$EE94
852E: 22 6A 0E    ld   ($E0A6),hl
8531: CD F2 49    call $853E
8534: CD B5 49    call $855B
8537: CD 28 49    call $8582
853A: CD 1C 49    call $85D0
853D: C9          ret
853E: 21 BD 49    ld   hl,$85DB
8541: 3A 48 CF    ld   a,($ED84)
8544: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
8545: 2A 6A 0E    ld   hl,($E0A6)
8548: 2C          inc  l
8549: 2C          inc  l
854A: 7E          ld   a,(hl)
854B: 83          add  a,e
854C: 27          daa
854D: 77          ld   (hl),a
854E: 2B          dec  hl
854F: 7E          ld   a,(hl)
8550: 8A          adc  a,d
8551: 27          daa
8552: 77          ld   (hl),a
8553: D0          ret  nc
8554: 2B          dec  hl
8555: 7E          ld   a,(hl)
8556: C6 01       add  a,$01
8558: 27          daa
8559: 77          ld   (hl),a
855A: C9          ret
855B: 2A 6A 0E    ld   hl,($E0A6)
855E: 11 79 EE    ld   de,$EE97
8561: 1A          ld   a,(de)
8562: BE          cp   (hl)
8563: 38 E1       jr   c,$8574
8565: C0          ret  nz
8566: 23          inc  hl
8567: 13          inc  de
8568: 1A          ld   a,(de)
8569: BE          cp   (hl)
856A: 38 80       jr   c,$8574
856C: C0          ret  nz
856D: 23          inc  hl
856E: 13          inc  de
856F: 1A          ld   a,(de)
8570: BE          cp   (hl)
8571: 38 01       jr   c,$8574
8573: C0          ret  nz
8574: 01 21 00    ld   bc,$0003
8577: 2A 6A 0E    ld   hl,($E0A6)
857A: 11 79 EE    ld   de,$EE97
857D: ED B0       ldir
857F: C3 DC D8    jp   $9CDC
8582: 2A 6A 0E    ld   hl,($E0A6)
8585: 11 4B CF    ld   de,$EDA5
8588: 1A          ld   a,(de)
8589: BE          cp   (hl)
858A: 38 E1       jr   c,$859B
858C: C0          ret  nz
858D: 23          inc  hl
858E: 13          inc  de
858F: 1A          ld   a,(de)
8590: BE          cp   (hl)
8591: 38 80       jr   c,$859B
8593: C0          ret  nz
8594: 23          inc  hl
8595: 13          inc  de
8596: 1A          ld   a,(de)
8597: BE          cp   (hl)
8598: 38 01       jr   c,$859B
859A: C0          ret  nz
859B: 21 0A CF    ld   hl,$EDA0
859E: 34          inc  (hl)
859F: CD 29 09    call $8183
85A2: CD 7A 68    call $86B6
85A5: ED 5B 4B CF ld   de,($EDA5)
85A9: 7B          ld   a,e
85AA: 5A          ld   e,d
85AB: 57          ld   d,a
85AC: 3A 82 0E    ld   a,($E028)
85AF: 6F          ld   l,a
85B0: 26 00       ld   h,$00
85B2: 29          add  hl,hl
85B3: 29          add  hl,hl
85B4: 29          add  hl,hl
85B5: 29          add  hl,hl
85B6: 7B          ld   a,e
85B7: 85          add  a,l
85B8: 27          daa
85B9: 6F          ld   l,a
85BA: 7A          ld   a,d
85BB: 8C          adc  a,h
85BC: 27          daa
85BD: 67          ld   h,a
85BE: E6 1E       and  $F0
85C0: 20 81       jr   nz,$85CB
85C2: 7C          ld   a,h
85C3: 32 4B CF    ld   ($EDA5),a
85C6: 7D          ld   a,l
85C7: 32 6A CF    ld   ($EDA6),a
85CA: C9          ret
85CB: 21 18 99    ld   hl,$9990
85CE: 18 3E       jr   $85C2
85D0: 3A 91 0E    ld   a,($E019)
85D3: E6 01       and  $01
85D5: CA 3B D8    jp   z,$9CB3
85D8: C3 8C D8    jp   $9CC8
85DB: 41          ld   b,c
85DC: 00          nop
85DD: 10 00       djnz $85DF
85DF: 02          ld   (bc),a
85E0: 00          nop
85E1: 12          ld   (de),a
85E2: 00          nop
85E3: 04          inc  b
85E4: 00          nop
85E5: 14          inc  d
85E6: 00          nop
85E7: 06 00       ld   b,$00
85E9: 08          ex   af,af'
85EA: 00          nop
85EB: 00          nop
85EC: 01 14 01    ld   bc,$0150
85EF: 00          nop
85F0: 20 14       jr   nz,$8642
85F2: 20 00       jr   nz,$85F4
85F4: 21 14 21    ld   hl,$0350
85F7: 00          nop
85F8: 40          ld   b,b
85F9: 14          inc  d
85FA: 40          ld   b,b
85FB: 00          nop
85FC: 41          ld   b,c
85FD: 00          nop
85FE: 80          add  a,b
85FF: 00          nop
8600: 10 00       djnz $8602
8602: 02          ld   (bc),a
8603: 00          nop
8604: 14          inc  d
8605: 00          nop
8606: 12          ld   (de),a
8607: 21 96 1C    ld   hl,$D078
860A: 16 00       ld   d,$00
860C: 1E 8C       ld   e,$C8
860E: 06 40       ld   b,$04
8610: 0E 10       ld   c,$10
8612: CD 03 68    call $8621
8615: 16 04       ld   d,$40
8617: 1E 8C       ld   e,$C8
8619: 06 40       ld   b,$04
861B: 0E 81       ld   c,$09
861D: CD 03 68    call $8621
8620: C9          ret
8621: C5          push bc
8622: D5          push de
8623: E5          push hl
8624: 7A          ld   a,d
8625: 77          ld   (hl),a
8626: CB D4       set  2,h
8628: 73          ld   (hl),e
8629: CB 94       res  2,h
862B: 2B          dec  hl
862C: C6 10       add  a,$10
862E: 10 5F       djnz $8625
8630: E1          pop  hl
8631: 11 02 00    ld   de,$0020
8634: 19          add  hl,de
8635: D1          pop  de
8636: 14          inc  d
8637: C1          pop  bc
8638: 0D          dec  c
8639: C8          ret  z
863A: C3 03 68    jp   $8621
863D: 3E 00       ld   a,$00
863F: C3 71 69    jp   $8717
8642: 3E 20       ld   a,$02
8644: C3 71 69    jp   $8717
8647: 3E 21       ld   a,$03
8649: C3 71 69    jp   $8717
864C: 3E 40       ld   a,$04
864E: C3 71 69    jp   $8717
8651: 3E 41       ld   a,$05
8653: C3 71 69    jp   $8717
8656: 3E 60       ld   a,$06
8658: C3 71 69    jp   $8717
865B: 3E 61       ld   a,$07
865D: C3 71 69    jp   $8717
8660: 3E 80       ld   a,$08
8662: C3 71 69    jp   $8717
8665: 3E 81       ld   a,$09
8667: C3 71 69    jp   $8717
866A: 3E A0       ld   a,$0A
866C: C3 71 69    jp   $8717
866F: 3E A1       ld   a,$0B
8671: C3 71 69    jp   $8717
8674: C9          ret
8675: 3E C0       ld   a,$0C
8677: C3 71 69    jp   $8717
867A: 3E C1       ld   a,$0D
867C: C3 71 69    jp   $8717
867F: 3E E0       ld   a,$0E
8681: C3 71 69    jp   $8717
8684: 3E E1       ld   a,$0F
8686: C3 71 69    jp   $8717
8689: 3E 10       ld   a,$10
868B: C3 71 69    jp   $8717
868E: 3E 11       ld   a,$11
8690: C3 71 69    jp   $8717
8693: 3E 30       ld   a,$12
8695: C3 71 69    jp   $8717
8698: 3E 50       ld   a,$14
869A: C3 71 69    jp   $8717
869D: 3E 51       ld   a,$15
869F: C3 71 69    jp   $8717
86A2: 3E 70       ld   a,$16
86A4: C3 71 69    jp   $8717
86A7: 3E 90       ld   a,$18
86A9: C3 71 69    jp   $8717
86AC: 3E 91       ld   a,$19
86AE: C3 71 69    jp   $8717
86B1: 3E B0       ld   a,$1A
86B3: C3 71 69    jp   $8717
86B6: 3E B1       ld   a,$1B
86B8: C3 71 69    jp   $8717
86BB: 3E C3       ld   a,$2D
86BD: C3 71 69    jp   $8717
86C0: 3E 02       ld   a,$20
86C2: CD 71 69    call $8717
86C5: 3E 03       ld   a,$21
86C7: C3 71 69    jp   $8717
86CA: 3E 22       ld   a,$22
86CC: CD 71 69    call $8717
86CF: 3E 03       ld   a,$21
86D1: C3 71 69    jp   $8717
86D4: 3E 03       ld   a,$21
86D6: C3 71 69    jp   $8717
86D9: 3E 23       ld   a,$23
86DB: C3 71 69    jp   $8717
86DE: 3E C2       ld   a,$2C
86E0: C3 71 69    jp   $8717
86E3: 3E 42       ld   a,$24
86E5: C3 71 69    jp   $8717
86E8: 3E 43       ld   a,$25
86EA: C3 71 69    jp   $8717
86ED: 3E 62       ld   a,$26
86EF: C3 71 69    jp   $8717
86F2: 3E 63       ld   a,$27
86F4: C3 71 69    jp   $8717
86F7: 3E 82       ld   a,$28
86F9: C3 71 69    jp   $8717
86FC: 3E 83       ld   a,$29
86FE: C3 71 69    jp   $8717
8701: 3E A2       ld   a,$2A
8703: C3 71 69    jp   $8717
8706: 3E A3       ld   a,$2B
8708: C3 71 69    jp   $8717
870B: C9          ret
870C: 21 40 8C    ld   hl,$C804
870F: CB 96       res  2,(hl)
8711: CB D6       set  2,(hl)
8713: 00          nop
8714: CB 96       res  2,(hl)
8716: C9          ret
8717: 2A 68 CF    ld   hl,($ED86)
871A: 77          ld   (hl),a
871B: 23          inc  hl
871C: 7D          ld   a,l
871D: FE 06       cp   $60
871F: 38 20       jr   c,$8723
8721: 2E 04       ld   l,$40
8723: 22 68 CF    ld   ($ED86),hl
8726: C9          ret
8727: 0E FF       ld   c,$FF
8729: 2A 88 CF    ld   hl,($ED88)
872C: 7E          ld   a,(hl)
872D: 3C          inc  a
872E: 28 C0       jr   z,$873C
8730: 3D          dec  a
8731: 4F          ld   c,a
8732: 36 FF       ld   (hl),$FF
8734: 23          inc  hl
8735: 7D          ld   a,l
8736: FE 06       cp   $60
8738: 38 20       jr   c,$873C
873A: 2E 04       ld   l,$40
873C: 22 88 CF    ld   ($ED88),hl
873F: 79          ld   a,c
8740: 32 B2 0E    ld   ($E03A),a
8743: C9          ret
8744: DD 36 70 00 ld   (ix+$16),$00
8748: 3A 8B CF    ld   a,($EDA9)
874B: E6 21       and  $03
874D: FE 21       cp   $03
874F: 28 D5       jr   z,$87AE
8751: CD B5 69    call $875B
8754: DD 36 31 00 ld   (ix+$13),$00
8758: C3 1B C8    jp   $8CB1
875B: 3E 01       ld   a,$01
875D: 32 58 0E    ld   ($E094),a
8760: DD 7E B0    ld   a,(ix+$1a)
8763: 3D          dec  a
8764: 28 F0       jr   z,$8784
8766: 06 1C       ld   b,$D0
8768: 3A 8B CF    ld   a,($EDA9)
876B: E6 21       and  $03
876D: FE 21       cp   $03
876F: 20 20       jr   nz,$8773
8771: 06 0A       ld   b,$A0
8773: DD 7E 41    ld   a,(ix+$05)
8776: B8          cp   b
8777: 30 E2       jr   nc,$87A7
8779: DD 36 20 04 ld   (ix+$02),$40
877D: DD 34 41    inc  (ix+$05)
8780: DD 34 81    inc  (ix+$09)
8783: C9          ret
8784: DD 7E 21    ld   a,(ix+$03)
8787: FE 08       cp   $80
8789: 28 90       jr   z,$87A3
878B: 30 A1       jr   nc,$8798
878D: DD 36 20 00 ld   (ix+$02),$00
8791: DD 34 21    inc  (ix+$03)
8794: DD 34 61    inc  (ix+$07)
8797: C9          ret
8798: DD 36 20 08 ld   (ix+$02),$80
879C: DD 35 21    dec  (ix+$03)
879F: DD 35 61    dec  (ix+$07)
87A2: C9          ret
87A3: DD 34 B0    inc  (ix+$1a)
87A6: C9          ret
87A7: E1          pop  hl
87A8: 3E 0A       ld   a,$A0
87AA: 32 0B 0E    ld   ($E0A1),a
87AD: C9          ret
87AE: DD 7E D0    ld   a,(ix+$1c)
87B1: A7          and  a
87B2: 28 60       jr   z,$87BA
87B4: DD 35 D0    dec  (ix+$1c)
87B7: CC 5D 69    call z,$87D5
87BA: DD 7E B0    ld   a,(ix+$1a)
87BD: FE 21       cp   $03
87BF: 38 71       jr   c,$87D8
87C1: 3A 20 0E    ld   a,($E002)
87C4: E6 01       and  $01
87C6: CA D2 88    jp   z,$883C
87C9: DD 35 51    dec  (ix+$15)
87CC: C2 D2 88    jp   nz,$883C
87CF: 3E 01       ld   a,$01
87D1: 32 0B 0E    ld   ($E0A1),a
87D4: C9          ret
87D5: C3 BB 68    jp   $86BB
87D8: CD 15 69    call $8751
87DB: 3A 0B 0E    ld   a,($E0A1)
87DE: A7          and  a
87DF: C8          ret  z
87E0: 3E 00       ld   a,$00
87E2: 32 0B 0E    ld   ($E0A1),a
87E5: CD A6 68    call $866A
87E8: 3E B4       ld   a,$5A
87EA: DD 77 51    ld   (ix+$15),a
87ED: DD 36 B0 21 ld   (ix+$1a),$03
87F1: FD 21 9C FE ld   iy,$FED8
87F5: 11 10 00    ld   de,$0010
87F8: 21 32 88    ld   hl,$8832
87FB: 06 41       ld   b,$05
87FD: 7E          ld   a,(hl)
87FE: 23          inc  hl
87FF: FD 77 20    ld   (iy+$02),a
8802: FD 77 A0    ld   (iy+$0a),a
8805: C6 10       add  a,$10
8807: FD 77 60    ld   (iy+$06),a
880A: FD 77 E0    ld   (iy+$0e),a
880D: 7E          ld   a,(hl)
880E: 23          inc  hl
880F: FD 77 21    ld   (iy+$03),a
8812: FD 77 61    ld   (iy+$07),a
8815: C6 10       add  a,$10
8817: FD 77 A1    ld   (iy+$0b),a
881A: FD 77 E1    ld   (iy+$0f),a
881D: FD 36 01 08 ld   (iy+$01),$80
8821: FD 36 41 08 ld   (iy+$05),$80
8825: FD 36 81 08 ld   (iy+$09),$80
8829: FD 36 C1 08 ld   (iy+$0d),$80
882D: FD 19       add  iy,de
882F: 10 CC       djnz $87FD
8831: C9          ret
8832: 14          inc  d
8833: 0E 16       ld   c,$70
8835: 0E 18       ld   c,$90
8837: 0E 12       ld   c,$30
8839: 0A          ld   a,(bc)
883A: 5A          ld   e,d
883B: 0A          ld   a,(bc)
883C: FD 21 9C FE ld   iy,$FED8
8840: 3A 20 0E    ld   a,($E002)
8843: 0F          rrca
8844: E6 21       and  $03
8846: 87          add  a,a
8847: 87          add  a,a
8848: 21 78 88    ld   hl,$8896
884B: DF          rst  $18                   ; call ADD_A_TO_HL     
884C: 06 40       ld   b,$04
884E: 11 40 00    ld   de,$0004
8851: 4E          ld   c,(hl)
8852: 23          inc  hl
8853: FD 7E 00    ld   a,(iy+$00)
8856: 3C          inc  a
8857: 28 70       jr   z,$886F
8859: FD 71 00    ld   (iy+$00),c
885C: FD 71 10    ld   (iy+$10),c
885F: FD 71 02    ld   (iy+$20),c
8862: FD 71 12    ld   (iy+$30),c
8865: FD 71 04    ld   (iy+$40),c
8868: 3A 26 0E    ld   a,($E062)
886B: A7          and  a
886C: C4 56 88    call nz,$8874
886F: FD 19       add  iy,de
8871: 10 FC       djnz $8851
8873: C9          ret
8874: FD 35 21    dec  (iy+$03)
8877: FD 35 31    dec  (iy+$13)
887A: FD 35 23    dec  (iy+$23)
887D: FD 35 33    dec  (iy+$33)
8880: FD 35 25    dec  (iy+$43)
8883: C0          ret  nz
8884: 3E FF       ld   a,$FF
8886: FD 77 00    ld   (iy+$00),a
8889: FD 77 10    ld   (iy+$10),a
888C: FD 77 02    ld   (iy+$20),a
888F: FD 77 12    ld   (iy+$30),a
8892: FD 77 04    ld   (iy+$40),a
8895: C9          ret
8896: 92          sub  d
8897: 93          sub  e
8898: 12          ld   (de),a
8899: 13          inc  de
889A: B2          or   d
889B: B3          or   e
889C: 32 33 D2    ld   ($3C33),a
889F: D3 52       out  ($34),a
88A1: 53          ld   d,e
88A2: B2          or   d
88A3: B3          or   e
88A4: 32 33 DD    ld   ($DD33),a
88A7: 21 00 0F    ld   hl,$E100
88AA: FD 21 92 FF ld   iy,$FF38
88AE: DD 7E 00    ld   a,(ix+$00)
88B1: FE FE       cp   $FE
88B3: C8          ret  z
88B4: DD 36 70 00 ld   (ix+$16),$00
88B8: DD 36 31 00 ld   (ix+$13),$00
88BC: CD 1B C8    call $8CB1
88BF: 0E 00       ld   c,$00
88C1: CD 1C 88    call $88D0
88C4: CD AE 88    call $88EA
88C7: 79          ld   a,c
88C8: FE 21       cp   $03
88CA: C0          ret  nz
88CB: DD 36 00 FE ld   (ix+$00),$FE
88CF: C9          ret
88D0: DD 7E 21    ld   a,(ix+$03)
88D3: FE 96       cp   $78
88D5: 28 10       jr   z,$88E7
88D7: 30 61       jr   nc,$88E0
88D9: DD 34 21    inc  (ix+$03)
88DC: DD 34 61    inc  (ix+$07)
88DF: C9          ret
88E0: DD 35 21    dec  (ix+$03)
88E3: DD 35 61    dec  (ix+$07)
88E6: C9          ret
88E7: 0E 01       ld   c,$01
88E9: C9          ret
88EA: DD 7E 41    ld   a,(ix+$05)
88ED: FE 86       cp   $68
88EF: 28 10       jr   z,$8901
88F1: 30 61       jr   nc,$88FA
88F3: DD 34 41    inc  (ix+$05)
88F6: DD 34 81    inc  (ix+$09)
88F9: C9          ret
88FA: DD 35 41    dec  (ix+$05)
88FD: DD 35 81    dec  (ix+$09)
8900: C9          ret
8901: 79          ld   a,c
8902: C6 20       add  a,$02
8904: 4F          ld   c,a
8905: C9          ret
8906: CD C0 89    call $890C
8909: C3 F7 68    jp   $867F
890C: 21 A3 89    ld   hl,$892B
890F: 11 00 0F    ld   de,$E100
8912: 01 E0 00    ld   bc,$000E
8915: ED B0       ldir
8917: DD 21 00 0F ld   ix,$E100
891B: FD 21 92 FF ld   iy,$FF38
891F: DD 36 B0 00 ld   (ix+$1a),$00
8923: DD 36 31 00 ld   (ix+$13),$00
8927: CD 1B C8    call $8CB1
892A: C9          ret
892B: FF          rst  $38
892C: 04          inc  b
892D: 04          inc  b
892E: 97          sub  a
892F: 00          nop
8930: 73          ld   (hl),e
8931: 00          nop
8932: 97          sub  a
8933: 00          nop
8934: 73          ld   (hl),e
8935: 00          nop
8936: 00          nop
8937: 00          nop
8938: 04          inc  b
8939: DD 21 00 0F ld   ix,$E100
893D: FD 21 92 FF ld   iy,$FF38
8941: DD 7E 00    ld   a,(ix+$00)
8944: A7          and  a
8945: C8          ret  z
8946: DD 7E B0    ld   a,(ix+$1a)
8949: A7          and  a
894A: C2 44 69    jp   nz,$8744
894D: DD 7E 00    ld   a,(ix+$00)
8950: 3C          inc  a
8951: 28 20       jr   z,$8955
8953: 18 43       jr   $897A
8955: DD 7E B0    ld   a,(ix+$1a)
8958: A7          and  a
8959: C2 44 69    jp   nz,$8744
895C: DD 36 31 00 ld   (ix+$13),$00
8960: 21 00 00    ld   hl,$0000
8963: 22 75 0E    ld   ($E057),hl
8966: DD 7E 70    ld   a,(ix+$16)
8969: A7          and  a
896A: C4 B8 A8    call nz,$8A9A
896D: CD 8D A8    call $8AC9
8970: CD B3 A9    call $8B3B
8973: CD ED A9    call $8BCF
8976: CD 1B C8    call $8CB1
8979: C9          ret
897A: 21 00 00    ld   hl,$0000
897D: 22 75 0E    ld   ($E057),hl
8980: DD 7E 00    ld   a,(ix+$00)
8983: FE F3       cp   $3F
8985: D2 24 A8    jp   nc,$8A42
8988: DD 7E 51    ld   a,(ix+$15)
898B: A7          and  a
898C: CA 66 A8    jp   z,$8A66
898F: DD 35 51    dec  (ix+$15)
8992: DD 7E B1    ld   a,(ix+$1b)
8995: A7          and  a
8996: 20 71       jr   nz,$89AF
8998: 21 B7 A8    ld   hl,$8A7B
899B: DD 7E 51    ld   a,(ix+$15)
899E: 0F          rrca
899F: 0F          rrca
89A0: 0F          rrca
89A1: E6 61       and  $07
89A3: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
89A4: EB          ex   de,hl
89A5: 7E          ld   a,(hl)
89A6: DD 77 F0    ld   (ix+$1e),a
89A9: 23          inc  hl
89AA: 0E 00       ld   c,$00
89AC: C3 2C C9    jp   $8DC2
89AF: DD CB B1 E4 bit  1,(ix+$1b)
89B3: 20 33       jr   nz,$89E8
89B5: DD 7E 51    ld   a,(ix+$15)
89B8: FE 02       cp   $20
89BA: 38 C2       jr   c,$89E8
89BC: DD 7E 01    ld   a,(ix+$01)
89BF: C6 80       add  a,$08
89C1: 21 37 A9    ld   hl,$8B73
89C4: 07          rlca
89C5: 07          rlca
89C6: 07          rlca
89C7: E6 61       and  $07
89C9: 87          add  a,a
89CA: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
89CB: 4E          ld   c,(hl)
89CC: 23          inc  hl
89CD: 46          ld   b,(hl)
89CE: DD 66 21    ld   h,(ix+$03)
89D1: DD 6E 40    ld   l,(ix+$04)
89D4: 19          add  hl,de
89D5: DD 74 21    ld   (ix+$03),h
89D8: DD 75 40    ld   (ix+$04),l
89DB: DD 66 41    ld   h,(ix+$05)
89DE: DD 6E 60    ld   l,(ix+$06)
89E1: 09          add  hl,bc
89E2: DD 74 41    ld   (ix+$05),h
89E5: DD 75 60    ld   (ix+$06),l
89E8: 21 80 A8    ld   hl,$8A08
89EB: DD CB B1 E4 bit  1,(ix+$1b)
89EF: 28 21       jr   z,$89F4
89F1: 21 43 A8    ld   hl,$8A25
89F4: DD 7E 51    ld   a,(ix+$15)
89F7: 0F          rrca
89F8: 0F          rrca
89F9: 0F          rrca
89FA: E6 61       and  $07
89FC: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
89FD: 1A          ld   a,(de)
89FE: DD 77 F0    ld   (ix+$1e),a
8A01: 13          inc  de
8A02: 0E 00       ld   c,$00
8A04: EB          ex   de,hl
8A05: C3 2C C9    jp   $8DC2
8A08: 03          inc  bc
8A09: A8          xor  b
8A0A: D1          pop  de
8A0B: A8          xor  b
8A0C: 91          sub  c
8A0D: A8          xor  b
8A0E: 51          ld   d,c
8A0F: A8          xor  b
8A10: 30 A8       jr   nc,$899C
8A12: 00          nop
8A13: 52          ld   d,d
8A14: D2 01 FF    jp   nc,$FF01
8A17: 53          ld   d,e
8A18: 72          ld   (hl),d
8A19: 20 FF       jr   nz,$8A1A
8A1B: FF          rst  $38
8A1C: D3 20       out  ($02),a
8A1E: FF          rst  $38
8A1F: FF          rst  $38
8A20: F2 20 FF    jp   p,$FF02
8A23: FF          rst  $38
8A24: DB F2       in   a,($3E)
8A26: A8          xor  b
8A27: B2          or   d
8A28: A8          xor  b
8A29: 72          ld   (hl),d
8A2A: A8          xor  b
8A2B: 32 A8 E3    ld   ($2F8A),a
8A2E: A8          xor  b
8A2F: 00          nop
8A30: 57          ld   d,a
8A31: D7          rst  $10
8A32: 01 FF 76    ld   bc,$76FF
8A35: 77          ld   (hl),a
8A36: 20 FF       jr   nz,$8A37
8A38: FF          rst  $38
8A39: F6 20       or   $02
8A3B: FF          rst  $38
8A3C: FF          rst  $38
8A3D: F7          rst  $30
8A3E: 20 FF       jr   nz,$8A3F
8A40: FF          rst  $38
8A41: FF          rst  $38
8A42: CD BB 68    call $86BB
8A45: CD D3 68    call $863D
8A48: CD F7 68    call $867F
8A4B: CD 60 69    call $8706
8A4E: DD 7E B1    ld   a,(ix+$1b)
8A51: A7          and  a
8A52: 20 81       jr   nz,$8A5D
8A54: DD 36 00 F0 ld   (ix+$00),$1E
8A58: DD 36 51 82 ld   (ix+$15),$28
8A5C: C9          ret
8A5D: DD 36 00 F0 ld   (ix+$00),$1E
8A61: DD 36 51 82 ld   (ix+$15),$28
8A65: C9          ret
8A66: DD 35 00    dec  (ix+$00)
8A69: C0          ret  nz
8A6A: FD 36 20 00 ld   (iy+$02),$00
8A6E: FD 36 60 00 ld   (iy+$06),$00
8A72: FD 36 A0 00 ld   (iy+$0a),$00
8A76: DD 36 00 00 ld   (ix+$00),$00
8A7A: C9          ret
8A7B: C9          ret
8A7C: A8          xor  b
8A7D: C9          ret
8A7E: A8          xor  b
8A7F: C9          ret
8A80: A8          xor  b
8A81: 89          adc  a,c
8A82: A8          xor  b
8A83: 49          ld   c,c
8A84: A8          xor  b
8A85: 20 92       jr   nz,$8ABF
8A87: 93          sub  e
8A88: B2          or   d
8A89: 20 12       jr   nz,$8ABB
8A8B: 13          inc  de
8A8C: 32 00 33    ld   ($3300),a
8A8F: B3          or   e
8A90: CD 20 39    call $9302
8A93: DD 36 31 00 ld   (ix+$13),$00
8A97: C3 1B C8    jp   $8CB1
8A9A: DD 35 70    dec  (ix+$16)
8A9D: CA 18 A8    jp   z,$8A90
8AA0: DD 7E 70    ld   a,(ix+$16)
8AA3: 0F          rrca
8AA4: E6 21       and  $03
8AA6: 21 5B A8    ld   hl,$8AB5
8AA9: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
8AAA: EB          ex   de,hl
8AAB: 0E 00       ld   c,$00
8AAD: 7E          ld   a,(hl)
8AAE: DD 77 F0    ld   (ix+$1e),a
8AB1: 23          inc  hl
8AB2: C3 2C C9    jp   $8DC2
8AB5: DB A8       in   a,($8A)
8AB7: 4D          ld   c,l
8AB8: A8          xor  b
8AB9: 0D          dec  c
8ABA: A8          xor  b
8ABB: 4D          ld   c,l
8ABC: A8          xor  b
8ABD: 01 0D 8D    ld   bc,$C9C1
8AC0: AC          xor  h
8AC1: 00          nop
8AC2: AD          xor  l
8AC3: 8C          adc  a,h
8AC4: 00          nop
8AC5: 01 0C 2C    ld   bc,$C2C0
8AC8: 2D          dec  l
8AC9: CD 34 E8    call $8E52
8ACC: E6 E1       and  $0F
8ACE: 28 75       jr   z,$8B27
8AD0: DD 46 01    ld   b,(ix+$01)
8AD3: DD 70 11    ld   (ix+$11),b
8AD6: 21 12 A9    ld   hl,$8B30
8AD9: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
8ADA: DD 77 01    ld   (ix+$01),a
8ADD: B8          cp   b
8ADE: 28 21       jr   z,$8AE3
8AE0: CD A1 A9    call $8B0B
8AE3: DD 7E 20    ld   a,(ix+$02)
8AE6: DD BE 01    cp   (ix+$01)
8AE9: C8          ret  z
8AEA: 67          ld   h,a
8AEB: DD 6E 91    ld   l,(ix+$19)
8AEE: DD 56 71    ld   d,(ix+$17)
8AF1: DD 5E 90    ld   e,(ix+$18)
8AF4: 19          add  hl,de
8AF5: DD 74 20    ld   (ix+$02),h
8AF8: DD 75 91    ld   (ix+$19),l
8AFB: 7C          ld   a,h
8AFC: DD 96 01    sub  (ix+$01)
8AFF: C6 41       add  a,$05
8B01: FE A1       cp   $0B
8B03: D0          ret  nc
8B04: DD 7E 01    ld   a,(ix+$01)
8B07: DD 77 20    ld   (ix+$02),a
8B0A: C9          ret
8B0B: DD 7E 01    ld   a,(ix+$01)
8B0E: DD 96 20    sub  (ix+$02)
8B11: 67          ld   h,a
8B12: 2E 00       ld   l,$00
8B14: CB 2C       sra  h
8B16: CB 1D       rr   l
8B18: CB 2C       sra  h
8B1A: CB 1D       rr   l
8B1C: DD 74 71    ld   (ix+$17),h
8B1F: DD 75 90    ld   (ix+$18),l
8B22: DD 36 91 00 ld   (ix+$19),$00
8B26: C9          ret
8B27: DD CB 31 FE set  7,(ix+$13)
8B2B: DD 36 11 FF ld   (ix+$11),$FF
8B2F: C9          ret
8B30: FF          rst  $38
8B31: 00          nop
8B32: F7          rst  $30
8B33: FF          rst  $38
8B34: 0C          inc  c
8B35: 0E 0A       ld   c,$A0
8B37: FF          rst  $38
8B38: 04          inc  b
8B39: 02          ld   (bc),a
8B3A: 06 DD       ld   b,$DD
8B3C: CB 31       sll  c
8B3E: F6 C0       or   $0C
8B40: DD 7E 01    ld   a,(ix+$01)
8B43: C6 80       add  a,$08
8B45: 21 37 A9    ld   hl,$8B73
8B48: 07          rlca
8B49: 07          rlca
8B4A: 07          rlca
8B4B: E6 61       and  $07
8B4D: 87          add  a,a
8B4E: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
8B4F: 4E          ld   c,(hl)
8B50: 23          inc  hl
8B51: 46          ld   b,(hl)
8B52: DD 70 C1    ld   (ix+$0d),b
8B55: DD 71 E0    ld   (ix+$0e),c
8B58: DD 66 21    ld   h,(ix+$03)
8B5B: DD 6E 40    ld   l,(ix+$04)
8B5E: 19          add  hl,de
8B5F: DD 74 61    ld   (ix+$07),h
8B62: DD 75 80    ld   (ix+$08),l
8B65: DD 66 41    ld   h,(ix+$05)
8B68: DD 6E 60    ld   l,(ix+$06)
8B6B: 09          add  hl,bc
8B6C: DD 74 81    ld   (ix+$09),h
8B6F: DD 75 A0    ld   (ix+$0a),l
8B72: C9          ret
8B73: 62          ld   h,d
8B74: 01 00 00    ld   bc,$0000
8B77: DC 00 0C    call c,$C000
8B7A: 00          nop
8B7B: 00          nop
8B7C: 00          nop
8B7D: 00          nop
8B7E: 01 42 FF    ld   bc,$FF24
8B81: 0C          inc  c
8B82: 00          nop
8B83: BC          cp   h
8B84: FE 00       cp   $00
8B86: 00          nop
8B87: 42          ld   b,d
8B88: FF          rst  $38
8B89: 04          inc  b
8B8A: FF          rst  $38
8B8B: 00          nop
8B8C: 00          nop
8B8D: 00          nop
8B8E: FF          rst  $38
8B8F: DC 00 04    call c,$4000
8B92: FF          rst  $38
8B93: DD E5       push ix
8B95: 21 CC A9    ld   hl,$8BCC
8B98: E5          push hl
8B99: DD 66 61    ld   h,(ix+$07)
8B9C: DD 6E 81    ld   l,(ix+$09)
8B9F: 06 80       ld   b,$08
8BA1: 11 10 00    ld   de,$0010
8BA4: DD 21 00 8E ld   ix,$E800
8BA8: DD 7E 00    ld   a,(ix+$00)
8BAB: 3C          inc  a
8BAC: 20 90       jr   nz,$8BC6
8BAE: 7D          ld   a,l
8BAF: DD 96 41    sub  (ix+$05)
8BB2: FE AF       cp   $EB
8BB4: 38 10       jr   c,$8BC6
8BB6: 7C          ld   a,h
8BB7: DD 96 21    sub  (ix+$03)
8BBA: DD 86 81    add  a,(ix+$09)
8BBD: DD BE A0    cp   (ix+$0a)
8BC0: 30 40       jr   nc,$8BC6
8BC2: 3E 01       ld   a,$01
8BC4: A7          and  a
8BC5: C9          ret
8BC6: DD 19       add  ix,de
8BC8: 10 FC       djnz $8BA8
8BCA: AF          xor  a
8BCB: C9          ret
8BCC: DD E1       pop  ix
8BCE: C9          ret
8BCF: DD CB 31 F6 bit  7,(ix+$13)
8BD3: C0          ret  nz
8BD4: DD 36 B1 00 ld   (ix+$1b),$00
8BD8: CD 39 A9    call $8B93
8BDB: A7          and  a
8BDC: C2 08 C8    jp   nz,$8C80
8BDF: DD 7E 81    ld   a,(ix+$09)
8BE2: 47          ld   b,a
8BE3: 3A 30 EF    ld   a,($EF12)
8BE6: E6 E1       and  $0F
8BE8: 80          add  a,b
8BE9: 47          ld   b,a
8BEA: DD 7E 61    ld   a,(ix+$07)
8BED: C6 61       add  a,$07
8BEF: 4F          ld   c,a
8BF0: 3A 10 EF    ld   a,($EF10)
8BF3: 57          ld   d,a
8BF4: 3A 11 EF    ld   a,($EF11)
8BF7: 5F          ld   e,a
8BF8: 78          ld   a,b
8BF9: E6 1E       and  $F0
8BFB: 6F          ld   l,a
8BFC: 26 00       ld   h,$00
8BFE: 29          add  hl,hl
8BFF: 19          add  hl,de
8C00: 79          ld   a,c
8C01: CB 3F       srl  a
8C03: 4F          ld   c,a
8C04: CB 3F       srl  a
8C06: CB 3F       srl  a
8C08: E6 F0       and  $1E
8C0A: DF          rst  $18                   ; call ADD_A_TO_HL
8C0B: 7C          ld   a,h
8C0C: E6 BF       and  $FB
8C0E: 67          ld   h,a
8C0F: 7E          ld   a,(hl)
8C10: A7          and  a
8C11: 28 73       jr   z,$8C4A
8C13: 5F          ld   e,a
8C14: FE 1C       cp   $D0
8C16: 38 60       jr   c,$8C1E
8C18: DD 36 B1 01 ld   (ix+$1b),$01
8C1C: 18 80       jr   $8C26
8C1E: FE 8C       cp   $C8
8C20: 38 40       jr   c,$8C26
8C22: DD 36 B1 20 ld   (ix+$1b),$02
8C26: 23          inc  hl
8C27: 7E          ld   a,(hl)
8C28: A7          and  a
8C29: 28 21       jr   z,$8C2E
8C2B: 79          ld   a,c
8C2C: 2F          cpl
8C2D: 4F          ld   c,a
8C2E: 6B          ld   l,e
8C2F: 26 00       ld   h,$00
8C31: 29          add  hl,hl
8C32: 29          add  hl,hl
8C33: 29          add  hl,hl
8C34: 78          ld   a,b
8C35: 0F          rrca
8C36: 2F          cpl
8C37: E6 61       and  $07
8C39: DF          rst  $18                   ; call ADD_A_TO_HL
8C3A: 11 46 46    ld   de,$6464
8C3D: 19          add  hl,de
8C3E: 56          ld   d,(hl)
8C3F: 79          ld   a,c
8C40: E6 61       and  $07
8C42: 21 8B C8    ld   hl,$8CA9
8C45: DF          rst  $18                   ; call ADD_A_TO_HL
8C46: 7E          ld   a,(hl)
8C47: A2          and  d
8C48: 20 72       jr   nz,$8C80
8C4A: DD 7E 61    ld   a,(ix+$07)
8C4D: D6 10       sub  $10
8C4F: FE 1C       cp   $D0
8C51: 30 C0       jr   nc,$8C5F
8C53: DD 66 61    ld   h,(ix+$07)
8C56: DD 6E 80    ld   l,(ix+$08)
8C59: DD 74 21    ld   (ix+$03),h
8C5C: DD 75 40    ld   (ix+$04),l
8C5F: 0E 04       ld   c,$40
8C61: 3A F9 0E    ld   a,($E09F)
8C64: A7          and  a
8C65: 28 20       jr   z,$8C69
8C67: 0E 1A       ld   c,$B0
8C69: DD 7E 81    ld   a,(ix+$09)
8C6C: B9          cp   c
8C6D: 30 F1       jr   nc,$8C8E
8C6F: FE 80       cp   $08
8C71: 38 53       jr   c,$8CA8
8C73: DD 66 81    ld   h,(ix+$09)
8C76: DD 6E A0    ld   l,(ix+$0a)
8C79: DD 74 41    ld   (ix+$05),h
8C7C: DD 75 60    ld   (ix+$06),l
8C7F: C9          ret
8C80: DD CB 31 EE set  5,(ix+$13)
8C84: DD 7E B1    ld   a,(ix+$1b)
8C87: A7          and  a
8C88: C8          ret  z
8C89: DD 36 00 F3 ld   (ix+$00),$3F
8C8D: C9          ret
8C8E: DD 56 C1    ld   d,(ix+$0d)
8C91: DD 5E E0    ld   e,(ix+$0e)
8C94: ED 53 75 0E ld   ($E057),de
8C98: A7          and  a
8C99: DD 66 81    ld   h,(ix+$09)
8C9C: DD 6E A0    ld   l,(ix+$0a)
8C9F: ED 52       sbc  hl,de
8CA1: DD 74 41    ld   (ix+$05),h
8CA4: DD 75 60    ld   (ix+$06),l
8CA7: C9          ret
8CA8: C9          ret
8CA9: 08          ex   af,af'
8CAA: 04          inc  b
8CAB: 02          ld   (bc),a
8CAC: 10 80       djnz $8CB6
8CAE: 40          ld   b,b
8CAF: 20 01       jr   nz,$8CB2
8CB1: DD CB 31 F6 bit  7,(ix+$13)
8CB5: C0          ret  nz
8CB6: DD 7E 70    ld   a,(ix+$16)
8CB9: A7          and  a
8CBA: C0          ret  nz
8CBB: DD 34 10    inc  (ix+$10)
8CBE: DD 7E 20    ld   a,(ix+$02)
8CC1: C6 80       add  a,$08
8CC3: 0F          rrca
8CC4: 0F          rrca
8CC5: 0F          rrca
8CC6: 0F          rrca
8CC7: E6 E1       and  $0F
8CC9: 47          ld   b,a
8CCA: 21 3E C8    ld   hl,$8CF2
8CCD: DF          rst  $18                   ; call ADD_A_TO_HL
8CCE: 4E          ld   c,(hl)
8CCF: 78          ld   a,b
8CD0: 87          add  a,a
8CD1: 87          add  a,a
8CD2: 47          ld   b,a
8CD3: 87          add  a,a
8CD4: 80          add  a,b
8CD5: 47          ld   b,a
8CD6: DD 7E 10    ld   a,(ix+$10)
8CD9: 0F          rrca
8CDA: 0F          rrca
8CDB: E6 21       and  $03
8CDD: FE 21       cp   $03
8CDF: 20 20       jr   nz,$8CE3
8CE1: 3E 01       ld   a,$01
8CE3: 87          add  a,a
8CE4: 87          add  a,a
8CE5: 80          add  a,b
8CE6: 21 20 C9    ld   hl,$8D02
8CE9: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
8CEA: DD 77 F0    ld   (ix+$1e),a
8CED: 23          inc  hl
8CEE: CD 2C C9    call $8DC2
8CF1: C9          ret
8CF2: 00          nop
8CF3: 00          nop
8CF4: 00          nop
8CF5: 00          nop
8CF6: 00          nop
8CF7: 80          add  a,b
8CF8: 80          add  a,b
8CF9: 80          add  a,b
8CFA: 80          add  a,b
8CFB: 80          add  a,b
8CFC: 80          add  a,b
8CFD: 80          add  a,b
8CFE: 00          nop
8CFF: 00          nop
8D00: 00          nop
8D01: 00          nop
8D02: 01 00 80    ld   bc,$0800
8D05: 81          add  a,c
8D06: 01 01 10    ld   bc,$1001
8D09: 11 01 20    ld   de,$0201
8D0C: 90          sub  b
8D0D: 91          sub  c
8D0E: 00          nop
8D0F: 21 A1 A1    ld   hl,$0B0B
8D12: 00          nop
8D13: 21 A1 A1    ld   hl,$0B0B
8D16: 00          nop
8D17: 21 A1 A1    ld   hl,$0B0B
8D1A: 01 31 B0    ld   bc,$1A13
8D1D: B1          or   c
8D1E: 00          nop
8D1F: 50          ld   d,b
8D20: D0          ret  nc
8D21: 00          nop
8D22: 01 51 D1    ld   bc,$1D15
8D25: F0          ret  p
8D26: 00          nop
8D27: A0          and  b
8D28: 30 00       jr   nc,$8D2A
8D2A: 00          nop
8D2B: A0          and  b
8D2C: 30 00       jr   nc,$8D2E
8D2E: 00          nop
8D2F: A0          and  b
8D30: 30 00       jr   nc,$8D32
8D32: 00          nop
8D33: 41          ld   b,c
8D34: C1          pop  bc
8D35: 00          nop
8D36: 00          nop
8D37: 60          ld   h,b
8D38: E0          ret  po
8D39: 00          nop
8D3A: 00          nop
8D3B: 61          ld   h,c
8D3C: E1          pop  hl
8D3D: 00          nop
8D3E: 00          nop
8D3F: A0          and  b
8D40: 30 00       jr   nc,$8D42
8D42: 00          nop
8D43: A0          and  b
8D44: 30 00       jr   nc,$8D46
8D46: 00          nop
8D47: A0          and  b
8D48: 30 00       jr   nc,$8D4A
8D4A: 01 31 B1    ld   bc,$1B13
8D4D: B0          or   b
8D4E: 00          nop
8D4F: 50          ld   d,b
8D50: D0          ret  nc
8D51: 00          nop
8D52: 01 51 F0    ld   bc,$1E15
8D55: D1          pop  de
8D56: 00          nop
8D57: 21 A1 A1    ld   hl,$0B0B
8D5A: 00          nop
8D5B: 21 A1 A1    ld   hl,$0B0B
8D5E: 00          nop
8D5F: 21 A1 A1    ld   hl,$0B0B
8D62: 01 00 81    ld   bc,$0900
8D65: 80          add  a,b
8D66: 01 01 11    ld   bc,$1101
8D69: 10 01       djnz $8D6C
8D6B: 20 91       jr   nz,$8D86
8D6D: 90          sub  b
8D6E: 01 63 73    ld   bc,$3727
8D71: E3          ex   (sp),hl
8D72: 01 63 73    ld   bc,$3727
8D75: E3          ex   (sp),hl
8D76: 01 63 73    ld   bc,$3727
8D79: E3          ex   (sp),hl
8D7A: 00          nop
8D7B: 42          ld   b,d
8D7C: C2 00 00    jp   nz,$0000
8D7F: 43          ld   b,e
8D80: C3 00 00    jp   $0000
8D83: 62          ld   h,d
8D84: E2 00 00    jp   po,$0000
8D87: 23          inc  hl
8D88: A3          and  e
8D89: 00          nop
8D8A: 00          nop
8D8B: 23          inc  hl
8D8C: A3          and  e
8D8D: 00          nop
8D8E: 00          nop
8D8F: 23          inc  hl
8D90: A3          and  e
8D91: 00          nop
8D92: 00          nop
8D93: 02          ld   (bc),a
8D94: 82          add  a,d
8D95: 00          nop
8D96: 00          nop
8D97: 03          inc  bc
8D98: 83          add  a,e
8D99: 00          nop
8D9A: 00          nop
8D9B: 22 A2 00    ld   ($002A),hl
8D9E: 00          nop
8D9F: 23          inc  hl
8DA0: A3          and  e
8DA1: 00          nop
8DA2: 00          nop
8DA3: 23          inc  hl
8DA4: A3          and  e
8DA5: 00          nop
8DA6: 00          nop
8DA7: 23          inc  hl
8DA8: A3          and  e
8DA9: 00          nop
8DAA: 00          nop
8DAB: 42          ld   b,d
8DAC: C2 00 00    jp   nz,$0000
8DAF: 43          ld   b,e
8DB0: C3 00 00    jp   $0000
8DB3: 62          ld   h,d
8DB4: E2 00 01    jp   po,$0100
8DB7: 63          ld   h,e
8DB8: E3          ex   (sp),hl
8DB9: 73          ld   (hl),e
8DBA: 01 63 E3    ld   bc,$2F27
8DBD: 73          ld   (hl),e
8DBE: 01 63 E3    ld   bc,$2F27
8DC1: 73          ld   (hl),e
8DC2: FD 71 01    ld   (iy+$01),c
8DC5: FD 71 41    ld   (iy+$05),c
8DC8: FD 71 81    ld   (iy+$09),c
8DCB: 7E          ld   a,(hl)
8DCC: 23          inc  hl
8DCD: FD 77 00    ld   (iy+$00),a
8DD0: 7E          ld   a,(hl)
8DD1: 23          inc  hl
8DD2: FD 77 40    ld   (iy+$04),a
8DD5: 7E          ld   a,(hl)
8DD6: 23          inc  hl
8DD7: FD 77 80    ld   (iy+$08),a
8DDA: DD 7E F0    ld   a,(ix+$1e)
8DDD: E6 21       and  $03
8DDF: FE 01       cp   $01
8DE1: 38 40       jr   c,$8DE7
8DE3: 28 22       jr   z,$8E07
8DE5: 18 05       jr   $8E28
8DE7: DD 7E 21    ld   a,(ix+$03)
8DEA: FD 77 20    ld   (iy+$02),a
8DED: FD 77 60    ld   (iy+$06),a
8DF0: FD 36 A0 00 ld   (iy+$0a),$00
8DF4: DD 7E 41    ld   a,(ix+$05)
8DF7: FD 77 61    ld   (iy+$07),a
8DFA: C6 10       add  a,$10
8DFC: 38 40       jr   c,$8E02
8DFE: FD 77 21    ld   (iy+$03),a
8E01: C9          ret
8E02: FD 36 20 00 ld   (iy+$02),$00
8E06: C9          ret
8E07: DD 7E 21    ld   a,(ix+$03)
8E0A: FD 77 20    ld   (iy+$02),a
8E0D: C6 9E       add  a,$F8
8E0F: FD 77 60    ld   (iy+$06),a
8E12: C6 10       add  a,$10
8E14: FD 77 A0    ld   (iy+$0a),a
8E17: DD 7E 41    ld   a,(ix+$05)
8E1A: FD 77 61    ld   (iy+$07),a
8E1D: FD 77 A1    ld   (iy+$0b),a
8E20: C6 10       add  a,$10
8E22: 38 FC       jr   c,$8E02
8E24: FD 77 21    ld   (iy+$03),a
8E27: C9          ret
8E28: DD 7E 21    ld   a,(ix+$03)
8E2B: FD 77 A0    ld   (iy+$0a),a
8E2E: C6 9E       add  a,$F8
8E30: FD 77 20    ld   (iy+$02),a
8E33: C6 10       add  a,$10
8E35: FD 77 60    ld   (iy+$06),a
8E38: DD 7E 41    ld   a,(ix+$05)
8E3B: FD 77 A1    ld   (iy+$0b),a
8E3E: C6 10       add  a,$10
8E40: 38 61       jr   c,$8E49
8E42: FD 77 21    ld   (iy+$03),a
8E45: FD 77 61    ld   (iy+$07),a
8E48: C9          ret
8E49: FD 36 20 00 ld   (iy+$02),$00
8E4D: FD 36 60 00 ld   (iy+$06),$00
8E51: C9          ret
8E52: 21 40 0E    ld   hl,$E004
8E55: 3A 91 0E    ld   a,($E019)
8E58: E6 01       and  $01
8E5A: 28 E0       jr   z,$8E6A
8E5C: 3A 93 0E    ld   a,($E039)
8E5F: E6 01       and  $01
8E61: 20 60       jr   nz,$8E69
8E63: 3A 83 0E    ld   a,($E029)
8E66: A7          and  a
8E67: 20 01       jr   nz,$8E6A
8E69: 2C          inc  l
8E6A: 7E          ld   a,(hl)
8E6B: C9          ret
8E6C: 3A 26 0E    ld   a,($E062)
8E6F: A7          and  a
8E70: 28 21       jr   z,$8E75
8E72: DD 35 41    dec  (ix+$05)
8E75: CD 46 C6    call $6C64
8E78: DD 66 21    ld   h,(ix+$03)
8E7B: DD 6E 40    ld   l,(ix+$04)
8E7E: 19          add  hl,de
8E7F: DD 74 61    ld   (ix+$07),h
8E82: DD 75 80    ld   (ix+$08),l
8E85: DD 66 41    ld   h,(ix+$05)
8E88: DD 6E 60    ld   l,(ix+$06)
8E8B: 09          add  hl,bc
8E8C: DD 74 81    ld   (ix+$09),h
8E8F: DD 75 A0    ld   (ix+$0a),l
8E92: C9          ret
8E93: CD B8 E8    call $8E9A
8E96: CD 00 19    call $9100
8E99: C9          ret


;
; I *think* this routine is responsible for positioning player bullet sprites
;

8E9A: DD 21 00 2E ld   ix,$E200
8E9E: 26 E0       ld   h,$0E
8EA0: 11 02 00    ld   de,$0020              ; DE = sizeof(PLAYER_BULLET)
8EA3: FD 21 84 FF ld   iy,$FF48              ; IY = pointer to sprites
8EA7: 01 40 00    ld   bc,$0004              ; BC = sizeof(BULLET_SPRITE)
8EAA: D9          exx
8EAB: DD 7E 00    ld   a,(ix+$00)
8EAE: A7          and  a
8EAF: CA 0C E9    jp   z,$8FC0
8EB2: 3C          inc  a
8EB3: C2 A0 18    jp   nz,$900A

8EB6: DD 7E 50    ld   a,(ix+$14)
8EB9: FE 01       cp   $01
8EBB: CA 0B E9    jp   z,$8FA1
8EBE: 38 91       jr   c,$8ED9
8EC0: DD 35 51    dec  (ix+$15)
8EC3: CA 93 18    jp   z,$9039
8EC6: DD 7E 51    ld   a,(ix+$15)
8EC9: 0F          rrca
8ECA: E6 21       and  $03
8ECC: 21 7C E8    ld   hl,$8ED6
8ECF: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
8ED0: FD 77 00    ld   (iy+$00),a
8ED3: C3 0C E9    jp   $8FC0

8ED6: 
    DA 9B 9A DD    


8ED9: DD 35 51    dec  (ix+$15)
8EDC: CA 39 E9    jp   z,$8F93

8EDF: DD CB 31 64 bit  0,(ix+$13)
8EE3: 20 03       jr   nz,$8F06

8EE5: DD 7E 91    ld   a,(ix+$19)
8EE8: 21 33 E9    ld   hl,$8F33
8EEB: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
8EEC: FD 73 00    ld   (iy+$00),e            ; set SPRITE.Code
8EEF: FD 72 01    ld   (iy+$01),d            ; set SPRITE.Attr
8EF2: 3A 26 0E    ld   a,($E062)
8EF5: ED 44       neg
8EF7: DD 86 41    add  a,(ix+$05)
8EFA: FD 77 21    ld   (iy+$03),a            ; set SPRITE.X
8EFD: DD 7E 21    ld   a,(ix+$03)
8F00: FD 77 20    ld   (iy+$02),a            ; set SPRITE.Y
8F03: C3 0C E9    jp   $8FC0

8F06: DD 35 51    dec  (ix+$15)
8F09: CA 39 E9    jp   z,$8F93
8F0C: DD 7E 91    ld   a,(ix+$19)
8F0F: 21 C3 E9    ld   hl,$8F2D
8F12: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
8F13: FD 73 00    ld   (iy+$00),e            ; set SPRITE.Code
8F16: FD 72 01    ld   (iy+$01),d            ; set SPRITE.Attr 
8F19: 3A 26 0E    ld   a,($E062)
8F1C: ED 44       neg
8F1E: DD 86 41    add  a,(ix+$05)
8F21: FD 77 21    ld   (iy+$03),a            ; set SPRITE.X
8F24: DD 7E 21    ld   a,(ix+$03)
8F27: FD 77 20    ld   (iy+$02),a            ; set SPRITE.Y
8F2A: C3 0C E9    jp   $8FC0


8F2D:  
BF 08 
AE 00 
BF 00 

8F33:
AA 00 
AA 00 
A9 00 
A9 00 
A8 00  
A9 08 
A9 08 
AA 08 
AA 08 
AA 0C 
A9 0C 
A9 0C 
A8 0C  
A9 04 
A9 04 
AA 04 

   
8F53: DD 36 50 01 ld   (ix+$14),$01
8F57: 06 4B       ld   b,$A5
8F59: DD CB 91 64 bit  0,(ix+$19)
8F5D: 28 20       jr   z,$8F61
8F5F: 06 EB       ld   b,$AF
8F61: FD 70 00    ld   (iy+$00),b
8F64: DD 35 30    dec  (ix+$12)
8F67: 28 70       jr   z,$8F7F
8F69: CD 5C E9    call $8FD4
8F6C: DD 7E 21    ld   a,(ix+$03)
8F6F: FE 10       cp   $10
8F71: DA D1 18    jp   c,$901D
8F74: DD 7E 41    ld   a,(ix+$05)
8F77: FE 80       cp   $08
8F79: DA D1 18    jp   c,$901D
8F7C: C3 0C E9    jp   $8FC0
8F7F: DD 36 00 00 ld   (ix+$00),$00
8F83: FD 36 20 00 ld   (iy+$02),$00
8F87: DD 66 21    ld   h,(ix+$03)
8F8A: DD 6E 41    ld   l,(ix+$05)
8F8D: CD C1 38    call $920D
8F90: C3 0C E9    jp   $8FC0
8F93: DD CB 31 64 bit  0,(ix+$13)
8F97: 20 BA       jr   nz,$8F53
8F99: FD 36 00 5B ld   (iy+$00),$B5
8F9D: DD 36 50 01 ld   (ix+$14),$01
8FA1: DD CB 31 64 bit  0,(ix+$13)
8FA5: 20 DB       jr   nz,$8F64
8FA7: DD 35 30    dec  (ix+$12)
8FAA: 28 F0       jr   z,$8FCA
8FAC: CD 5C E9    call $8FD4
8FAF: DD 7E 21    ld   a,(ix+$03)
8FB2: FE 10       cp   $10
8FB4: 38 67       jr   c,$901D
8FB6: DD 7E 41    ld   a,(ix+$05)
8FB9: FE 80       cp   $08
8FBB: 38 06       jr   c,$901D
8FBD: CD B7 18    call $907B
8FC0: D9          exx
8FC1: DD 19       add  ix,de
8FC3: FD 09       add  iy,bc
8FC5: 25          dec  h
8FC6: C8          ret  z
8FC7: C3 AA E8    jp   $8EAA


8FCA: DD 36 50 20 ld   (ix+$14),$02
8FCE: DD 36 51 60 ld   (ix+$15),$06
8FD2: 18 CE       jr   $8FC0
8FD4: DD 66 21    ld   h,(ix+$03)
8FD7: DD 6E 40    ld   l,(ix+$04)
8FDA: DD 56 A1    ld   d,(ix+$0b)
8FDD: DD 5E C0    ld   e,(ix+$0c)
8FE0: 19          add  hl,de
8FE1: DD 74 21    ld   (ix+$03),h
8FE4: FD 74 20    ld   (iy+$02),h
8FE7: DD 75 40    ld   (ix+$04),l
8FEA: 3A 26 0E    ld   a,($E062)
8FED: A7          and  a
8FEE: 28 21       jr   z,$8FF3
8FF0: DD 35 41    dec  (ix+$05)
8FF3: DD 66 41    ld   h,(ix+$05)
8FF6: DD 6E 60    ld   l,(ix+$06)
8FF9: DD 56 C1    ld   d,(ix+$0d)
8FFC: DD 5E E0    ld   e,(ix+$0e)
8FFF: 19          add  hl,de
9000: DD 74 41    ld   (ix+$05),h
9003: FD 74 21    ld   (iy+$03),h
9006: DD 75 60    ld   (ix+$06),l
9009: C9          ret




900A: DD CB 31 64 bit  0,(ix+$13)
900E: C2 F7 E9    jp   nz,$8F7F
9011: DD 7E 00    ld   a,(ix+$00)
9014: FE 10       cp   $10
9016: 30 31       jr   nc,$902B
9018: DD 35 00    dec  (ix+$00)
901B: 20 2B       jr   nz,$8FC0
901D: DD 36 00 00 ld   (ix+$00),$00
9021: DD 36 21 00 ld   (ix+$03),$00
9025: FD 36 20 00 ld   (iy+$02),$00
9029: 18 59       jr   $8FC0

902B: DD 36 00 61 ld   (ix+$00),$07
902F: FD 36 00 9A ld   (iy+$00),$B8
9033: FD 36 01 00 ld   (iy+$01),$00
9037: 18 69       jr   $8FC0

9039: DD 36 00 F3 ld   (ix+$00),$3F
903D: 18 09       jr   $8FC0

903F: DD E5       push ix
9041: 21 96 18    ld   hl,$9078
9044: E5          push hl
9045: DD 66 21    ld   h,(ix+$03)
9048: DD 6E 41    ld   l,(ix+$05)
904B: 06 80       ld   b,$08
904D: 11 10 00    ld   de,$0010
9050: DD 21 00 8E ld   ix,$E800
9054: DD 7E 00    ld   a,(ix+$00)
9057: 3C          inc  a
9058: 20 90       jr   nz,$9072
905A: 7D          ld   a,l
905B: DD 96 41    sub  (ix+$05)
905E: FE AF       cp   $EB
9060: 38 10       jr   c,$9072
9062: 7C          ld   a,h
9063: DD 96 21    sub  (ix+$03)
9066: DD 86 81    add  a,(ix+$09)
9069: DD BE A0    cp   (ix+$0a)
906C: 30 40       jr   nc,$9072
906E: 3E 01       ld   a,$01
9070: A7          and  a
9071: C9          ret

9072: DD 19       add  ix,de
9074: 10 FC       djnz $9054
9076: AF          xor  a
9077: C9          ret

9078: DD E1       pop  ix
907A: C9          ret

907B: DD CB 31 F6 bit  7,(ix+$13)
907F: C0          ret  nz
9080: DD 7E F1    ld   a,(ix+$1f)
9083: E6 01       and  $01
9085: 47          ld   b,a
9086: 3A 20 0E    ld   a,($E002)
9089: E6 01       and  $01
908B: B8          cp   b
908C: C8          ret  z
908D: CD F3 18    call $903F
9090: 20 B4       jr   nz,$90EC
9092: DD 7E 41    ld   a,(ix+$05)
9095: 47          ld   b,a
9096: 3A 30 EF    ld   a,($EF12)
9099: E6 E1       and  $0F
909B: 80          add  a,b
909C: 47          ld   b,a
909D: DD 7E 21    ld   a,(ix+$03)
90A0: C6 61       add  a,$07
90A2: 4F          ld   c,a
90A3: 3A 10 EF    ld   a,($EF10)
90A6: 57          ld   d,a
90A7: 3A 11 EF    ld   a,($EF11)
90AA: 5F          ld   e,a
90AB: 78          ld   a,b
90AC: E6 1E       and  $F0
90AE: 6F          ld   l,a
90AF: 26 00       ld   h,$00
90B1: 29          add  hl,hl
90B2: 19          add  hl,de
90B3: 79          ld   a,c
90B4: CB 3F       srl  a
90B6: 4F          ld   c,a
90B7: CB 3F       srl  a
90B9: CB 3F       srl  a
90BB: E6 F0       and  $1E
90BD: DF          rst  $18                   ; call ADD_A_TO_HL   
90BE: 7C          ld   a,h
90BF: E6 BF       and  $FB
90C1: 67          ld   h,a
90C2: 7E          ld   a,(hl)
90C3: A7          and  a
90C4: C8          ret  z
90C5: FE 0C       cp   $C0
90C7: D0          ret  nc
90C8: 23          inc  hl
90C9: 5F          ld   e,a
90CA: 7E          ld   a,(hl)
90CB: A7          and  a
90CC: 28 21       jr   z,$90D1
90CE: 79          ld   a,c
90CF: 2F          cpl
90D0: 4F          ld   c,a
90D1: 6B          ld   l,e
90D2: 26 00       ld   h,$00
90D4: 29          add  hl,hl
90D5: 29          add  hl,hl
90D6: 29          add  hl,hl
90D7: 78          ld   a,b
90D8: 0F          rrca
90D9: 2F          cpl
90DA: E6 61       and  $07
90DC: DF          rst  $18                   ; call ADD_A_TO_HL
90DD: 11 46 46    ld   de,$6464
90E0: 19          add  hl,de
90E1: 56          ld   d,(hl)
90E2: 79          ld   a,c
90E3: E6 61       and  $07
90E5: 21 9E 18    ld   hl,$90F8
90E8: DF          rst  $18                   ; call ADD_A_TO_HL
90E9: 7E          ld   a,(hl)
90EA: A2          and  d
90EB: C8          ret  z
90EC: DD 36 50 20 ld   (ix+$14),$02
90F0: DD 36 51 60 ld   (ix+$15),$06
90F4: CD 15 68    call $8651
90F7: C9          ret
90F8: 08          ex   af,af'
90F9: 04          inc  b
90FA: 02          ld   (bc),a
90FB: 10 80       djnz $9105
90FD: 40          ld   b,b
90FE: 20 01       jr   nz,$9101
9100: CD 26 38    call $9262
9103: DD 21 04 0F ld   ix,$E140
9107: FD 21 44 FF ld   iy,$FF44
910B: DD 7E 00    ld   a,(ix+$00)
910E: A7          and  a
910F: CA 6D 38    jp   z,$92C7
9112: 3C          inc  a
9113: 20 95       jr   nz,$916E
9115: DD 35 51    dec  (ix+$15)
9118: 28 54       jr   z,$916E
911A: DD 34 41    inc  (ix+$05)
911D: 3A 26 0E    ld   a,($E062)
9120: A7          and  a
9121: 28 60       jr   z,$9129
9123: DD 35 41    dec  (ix+$05)
9126: DD 35 61    dec  (ix+$07)
9129: DD 7E 51    ld   a,(ix+$15)
912C: 0F          rrca
912D: 0F          rrca
912E: 0F          rrca
912F: E6 61       and  $07
9131: 47          ld   b,a
9132: 21 26 19    ld   hl,$9162
9135: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
9136: DD 66 41    ld   h,(ix+$05)
9139: DD 6E 60    ld   l,(ix+$06)
913C: 19          add  hl,de
913D: DD 74 41    ld   (ix+$05),h
9140: DD 75 60    ld   (ix+$06),l
9143: 78          ld   a,b
9144: 21 D4 19    ld   hl,$915C
9147: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
9148: FD 77 00    ld   (iy+$00),a
914B: DD 7E 41    ld   a,(ix+$05)
914E: FD 77 21    ld   (iy+$03),a
9151: DD 7E 21    ld   a,(ix+$03)
9154: FD 77 20    ld   (iy+$02),a
9157: FD 36 01 10 ld   (iy+$01),$10
915B: C9          ret
915C: 5A          ld   e,d
915D: 3B          dec  sp
915E: 3A 3A 3B    ld   a,($B3B2)
9161: 5A          ld   e,d
9162: 0A          ld   a,(bc)
9163: 00          nop
9164: 0C          inc  c
9165: 00          nop
9166: 0E 00       ld   c,$00
9168: 02          ld   (bc),a
9169: 01 04 01    ld   bc,$0140
916C: 06 01       ld   b,$01
916E: DD 36 00 00 ld   (ix+$00),$00
9172: FD 36 20 00 ld   (iy+$02),$00
9176: DD 66 21    ld   h,(ix+$03)
9179: DD 6E 41    ld   l,(ix+$05)
917C: CD C1 38    call $920D
917F: DD 7E 21    ld   a,(ix+$03)
9182: 32 D9 0E    ld   ($E09D),a
9185: 67          ld   h,a
9186: 32 D8 0E    ld   ($E09C),a
9189: DD 7E 41    ld   a,(ix+$05)
918C: 32 F8 0E    ld   ($E09E),a
918F: 6F          ld   l,a
9190: FD 21 65 0E ld   iy,$E047
9194: FD 36 00 00 ld   (iy+$00),$00
9198: DD 21 00 6E ld   ix,$E600
919C: 11 02 00    ld   de,$0020
919F: 06 80       ld   b,$08
91A1: DD 7E 00    ld   a,(ix+$00)
91A4: 3C          inc  a
91A5: 20 B1       jr   nz,$91C2
91A7: DD 7E 21    ld   a,(ix+$03)
91AA: 94          sub  h
91AB: C6 90       add  a,$18
91AD: FE 13       cp   $31
91AF: 30 11       jr   nc,$91C2
91B1: DD 7E 41    ld   a,(ix+$05)
91B4: 95          sub  l
91B5: C6 82       add  a,$28
91B7: FE 04       cp   $40
91B9: 30 61       jr   nc,$91C2
91BB: DD 36 00 F3 ld   (ix+$00),$3F
91BF: FD 34 00    inc  (iy+$00)
91C2: DD 19       add  ix,de
91C4: 10 BD       djnz $91A1
91C6: DD 21 00 8E ld   ix,$E800
91CA: 11 10 00    ld   de,$0010
91CD: 06 C0       ld   b,$0C
91CF: DD 7E 00    ld   a,(ix+$00)
91D2: 3C          inc  a
91D3: 20 F1       jr   nz,$91F4
91D5: DD 7E 60    ld   a,(ix+$06)
91D8: A7          and  a
91D9: 20 91       jr   nz,$91F4
91DB: 7C          ld   a,h
91DC: DD 96 21    sub  (ix+$03)
91DF: FE E1       cp   $0F
91E1: 30 11       jr   nc,$91F4
91E3: 7D          ld   a,l
91E4: DD 96 41    sub  (ix+$05)
91E7: C6 31       add  a,$13
91E9: FE 91       cp   $19
91EB: 30 61       jr   nc,$91F4
91ED: DD 36 00 F3 ld   (ix+$00),$3F
91F1: FD 34 00    inc  (iy+$00)
91F4: DD 19       add  ix,de
91F6: 10 7D       djnz $91CF
91F8: FD 7E 00    ld   a,(iy+$00)
91FB: A7          and  a
91FC: C8          ret  z
91FD: FE 80       cp   $08
91FF: 38 20       jr   c,$9203
9201: 3E 80       ld   a,$08
9203: 3D          dec  a
9204: 21 BB 38    ld   hl,$92BB
9207: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
9208: 16 41       ld   d,$05
920A: 5F          ld   e,a
920B: FF          rst  $38
920C: C9          ret
920D: 3E 10       ld   a,$10
920F: 32 08 0E    ld   ($E080),a
9212: FD E5       push iy
9214: FD 21 40 FE ld   iy,$FE04
9218: 7C          ld   a,h
9219: C6 9E       add  a,$F8
921B: FD 77 20    ld   (iy+$02),a
921E: FD 77 A0    ld   (iy+$0a),a
9221: C6 10       add  a,$10
9223: FD 77 60    ld   (iy+$06),a
9226: FD 77 E0    ld   (iy+$0e),a
9229: 7D          ld   a,l
922A: C6 80       add  a,$08
922C: FD 77 21    ld   (iy+$03),a
922F: FD 77 61    ld   (iy+$07),a
9232: C6 1E       add  a,$F0
9234: FD 77 A1    ld   (iy+$0b),a
9237: FD 77 E1    ld   (iy+$0f),a
923A: FD E1       pop  iy
923C: 3A 00 0F    ld   a,($E100)
923F: 3C          inc  a
9240: C2 B5 68    jp   nz,$865B
9243: 3A 21 0F    ld   a,($E103)
9246: 94          sub  h
9247: C6 10       add  a,$10
9249: FE 03       cp   $21
924B: D2 B5 68    jp   nc,$865B
924E: 3A 41 0F    ld   a,($E105)
9251: 95          sub  l
9252: C6 10       add  a,$10
9254: FE 03       cp   $21
9256: D2 B5 68    jp   nc,$865B
9259: 3E F3       ld   a,$3F
925B: 32 00 0F    ld   ($E100),a
925E: C3 B5 68    jp   $865B
9261: C9          ret
9262: 32 D8 0E    ld   ($E09C),a
9265: 3A 08 0E    ld   a,($E080)
9268: A7          and  a
9269: C8          ret  z
926A: FD 21 40 FE ld   iy,$FE04
926E: 21 08 0E    ld   hl,$E080
9271: 35          dec  (hl)
9272: 28 93       jr   z,$92AD
9274: 7E          ld   a,(hl)
9275: 0F          rrca
9276: 0F          rrca
9277: E6 21       and  $03
9279: 21 2D 38    ld   hl,$92C3
927C: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
927D: FD 77 00    ld   (iy+$00),a
9280: 3C          inc  a
9281: FD 77 40    ld   (iy+$04),a
9284: C6 61       add  a,$07
9286: FD 77 80    ld   (iy+$08),a
9289: 3C          inc  a
928A: FD 77 C0    ld   (iy+$0c),a
928D: 3E 16       ld   a,$70
928F: FD 77 01    ld   (iy+$01),a
9292: FD 77 41    ld   (iy+$05),a
9295: FD 77 81    ld   (iy+$09),a
9298: FD 77 C1    ld   (iy+$0d),a
929B: 3A 26 0E    ld   a,($E062)
929E: A7          and  a
929F: C8          ret  z
92A0: FD 35 21    dec  (iy+$03)
92A3: FD 35 61    dec  (iy+$07)
92A6: FD 35 A1    dec  (iy+$0b)
92A9: FD 35 E1    dec  (iy+$0f)
92AC: C9          ret
92AD: AF          xor  a
92AE: FD 77 20    ld   (iy+$02),a
92B1: FD 77 60    ld   (iy+$06),a
92B4: FD 77 A0    ld   (iy+$0a),a
92B7: FD 77 E0    ld   (iy+$0e),a
92BA: C9          ret
92BB: 20 21       jr   nz,$92C0
92BD: 40          ld   b,b
92BE: 41          ld   b,c
92BF: 61          ld   h,c
92C0: 80          add  a,b
92C1: A0          and  b
92C2: C0          ret  nz
92C3: 08          ex   af,af'
92C4: 28 18       jr   z,$9256
92C6: 38 32       jr   c,$92FA
92C8: D8          ret  c
92C9: 0E 3A       ld   c,$B2
92CB: 00          nop
92CC: 0F          rrca
92CD: 3C          inc  a
92CE: C0          ret  nz
92CF: 3A 91 0E    ld   a,($E019)
92D2: E6 01       and  $01
92D4: 28 A1       jr   z,$92E1
92D6: 3A 51 0E    ld   a,($E015)
92D9: E6 61       and  $07
92DB: C8          ret  z
92DC: FE 01       cp   $01
92DE: C0          ret  nz
92DF: 18 81       jr   $92EA
92E1: 3A C1 0E    ld   a,($E00D)
92E4: E6 61       and  $07
92E6: C8          ret  z
92E7: FE 01       cp   $01
92E9: C0          ret  nz
92EA: 3A 70 0F    ld   a,($E116)
92ED: A7          and  a
92EE: C0          ret  nz
92EF: 3A 8A CF    ld   a,($EDA8)             ; read NUM_GRENADES
92F2: A7          and  a
92F3: C8          ret  z
92F4: 3D          dec  a
92F5: 27          daa
92F6: 32 8A CF    ld   ($EDA8),a             ; update NUM_GRENADES 
92F9: 16 A1       ld   d,$0B
92FB: FF          rst  $38
92FC: 3E 80       ld   a,$08
92FE: 32 70 0F    ld   ($E116),a
9301: C9          ret
9302: DD 21 04 0F ld   ix,$E140
9306: DD 35 00    dec  (ix+$00)
9309: DD 36 51 12 ld   (ix+$15),$30
930D: 3A 21 0F    ld   a,($E103)
9310: DD 77 21    ld   (ix+$03),a
9313: 3A 41 0F    ld   a,($E105)
9316: DD 77 41    ld   (ix+$05),a
9319: CD 74 68    call $8656
931C: C9          ret
931D: 3A 00 0F    ld   a,($E100)
9320: 3C          inc  a
9321: C0          ret  nz
9322: CD 83 39    call $9329
9325: CD 94 39    call $9358
9328: C9          ret
9329: 3A 91 0E    ld   a,($E019)
932C: E6 01       and  $01
932E: 28 A0       jr   z,$933A
9330: 3A 50 0E    ld   a,($E014)
9333: E6 61       and  $07
9335: FE 01       cp   $01
9337: C0          ret  nz
9338: 18 80       jr   $9342
933A: 3A C0 0E    ld   a,($E00C)
933D: E6 61       and  $07
933F: FE 01       cp   $01
9341: C0          ret  nz
9342: 21 89 0E    ld   hl,$E089
9345: 7E          ld   a,(hl)
9346: A7          and  a
9347: 28 61       jr   z,$9350
9349: FE 41       cp   $05
934B: 28 01       jr   z,$934E
934D: 34          inc  (hl)
934E: 34          inc  (hl)
934F: C9          ret
9350: 36 20       ld   (hl),$02
9352: 21 D6 0E    ld   hl,$E07C
9355: 36 01       ld   (hl),$01
9357: C9          ret
9358: 3A 89 0E    ld   a,($E089)
935B: A7          and  a
935C: C8          ret  z
935D: 21 D6 0E    ld   hl,$E07C
9360: 35          dec  (hl)
9361: C0          ret  nz
9362: CD E7 39    call $936F
9365: 21 89 0E    ld   hl,$E089
9368: 35          dec  (hl)
9369: 3E 40       ld   a,$04
936B: 32 D6 0E    ld   ($E07C),a
936E: C9          ret


936F: DD 21 00 2E ld   ix,$E200
9373: 11 02 00    ld   de,$0020
9376: 06 60       ld   b,$06
9378: DD 7E 00    ld   a,(ix+$00)
937B: A7          and  a
937C: 28 41       jr   z,$9383
937E: DD 19       add  ix,de
9380: 10 7E       djnz $9378
9382: C9          ret
9383: DD 70 F1    ld   (ix+$1f),b
9386: DD 35 00    dec  (ix+$00)
9389: 3A 21 0F    ld   a,($E103)
938C: 57          ld   d,a
938D: 3A 41 0F    ld   a,($E105)
9390: 5F          ld   e,a
9391: 3A 20 0F    ld   a,($E102)
9394: DD 77 01    ld   (ix+$01),a
9397: DD 36 E1 C1 ld   (ix+$0f),$0D
939B: C6 61       add  a,$07
939D: 0F          rrca
939E: 0F          rrca
939F: 0F          rrca
93A0: 0F          rrca
93A1: E6 E1       and  $0F
93A3: DD 77 91    ld   (ix+$19),a
93A6: 87          add  a,a
93A7: 21 DD 39    ld   hl,$93DD
93AA: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
93AB: 82          add  a,d
93AC: DD 77 21    ld   (ix+$03),a
93AF: 23          inc  hl
93B0: 7E          ld   a,(hl)
93B1: 83          add  a,e
93B2: DD 77 41    ld   (ix+$05),a
93B5: DD 36 30 31 ld   (ix+$12),$13           ; set shot length
93B9: DD 36 50 00 ld   (ix+$14),$00
93BD: DD 36 51 21 ld   (ix+$15),$03
93C1: CD 46 C6    call $6C64
93C4: EB          ex   de,hl
93C5: 29          add  hl,hl
93C6: DD 74 A1    ld   (ix+$0b),h
93C9: DD 75 C0    ld   (ix+$0c),l
93CC: 60          ld   h,b
93CD: 69          ld   l,c
93CE: 29          add  hl,hl
93CF: DD 74 C1    ld   (ix+$0d),h
93D2: DD 75 E0    ld   (ix+$0e),l
93D5: DD 36 31 00 ld   (ix+$13),$00
93D9: C3 65 68    jp   $8647
93DC: C9          ret

93DD: E1          pop  hl
93DE: 41          ld   b,c
93DF: A0          and  b
93E0: 81          add  a,c
93E1: 81          add  a,c
93E2: A0          and  b
93E3: 61          ld   h,c
93E4: C0          ret  nz
93E5: 40          ld   b,b
93E6: E0          ret  po
93E7: 9F          sbc  a,a
93E8: C0          ret  nz
93E9: 7F          ld   a,a
93EA: A0          and  b
93EB: 7E          ld   a,(hl)
93EC: 81          add  a,c
93ED: 1F          rra
93EE: 41          ld   b,c
93EF: 5E          ld   e,(hl)
93F0: 00          nop
93F1: 9F          sbc  a,a
93F2: DE DE       sbc  a,$FC
93F4: FE DE       cp   $FC
93F6: BF          cp   a
93F7: 40          ld   b,b
93F8: FE 61       cp   $07
93FA: DE C0       sbc  a,$0C
93FC: 00          nop
93FD: 3A 00 0F    ld   a,($E100)
9400: 3C          inc  a
9401: C0          ret  nz
9402: 3E 00       ld   a,$00
9404: 08          ex   af,af'
9405: DD 7E 21    ld   a,(ix+$03)
9408: 84          add  a,h
9409: 67          ld   h,a
940A: DD 7E 41    ld   a,(ix+$05)
940D: 85          add  a,l
940E: 6F          ld   l,a
940F: 18 E0       jr   $941F
9411: 3A 00 0F    ld   a,($E100)
9414: 3C          inc  a
9415: C0          ret  nz
9416: DD 66 21    ld   h,(ix+$03)
9419: DD 6E 41    ld   l,(ix+$05)
941C: 3E 01       ld   a,$01
941E: 08          ex   af,af'
941F: 3A 3F 0E    ld   a,($E0F3)
9422: A7          and  a
9423: C0          ret  nz
9424: 3A 1F 0E    ld   a,($E0F1)
9427: 57          ld   d,a
9428: 87          add  a,a
9429: 3C          inc  a
942A: 5F          ld   e,a
942B: 3A 21 0F    ld   a,($E103)
942E: 94          sub  h
942F: 82          add  a,d
9430: BB          cp   e
9431: 30 61       jr   nc,$943A
9433: 3A 41 0F    ld   a,($E105)
9436: 95          sub  l
9437: 82          add  a,d
9438: BB          cp   e
9439: D8          ret  c
943A: DD E5       push ix
943C: E5          push hl
943D: 2E 00       ld   l,$00
943F: DD 7E 31    ld   a,(ix+$13)
9442: A7          and  a
9443: 20 20       jr   nz,$9447
9445: 2E 08       ld   l,$80
9447: 3A 1E 0E    ld   a,($E0F0)
944A: 47          ld   b,a
944B: DD 21 0C 2E ld   ix,$E2C0
944F: 11 02 00    ld   de,$0020
9452: DD 7E 00    ld   a,(ix+$00)
9455: A7          and  a
9456: 28 80       jr   z,$9460
9458: DD 19       add  ix,de
945A: 10 7E       djnz $9452
945C: E1          pop  hl
945D: DD E1       pop  ix
945F: C9          ret
9460: DD 75 31    ld   (ix+$13),l
9463: E1          pop  hl
9464: DD 35 00    dec  (ix+$00)
9467: DD 74 21    ld   (ix+$03),h
946A: DD 75 41    ld   (ix+$05),l
946D: CD 2E C6    call $6CE2
9470: DD 77 01    ld   (ix+$01),a
9473: C6 80       add  a,$08
9475: 0F          rrca
9476: 0F          rrca
9477: 0F          rrca
9478: 0F          rrca
9479: E6 E1       and  $0F
947B: DD 77 91    ld   (ix+$19),a
947E: 3A 9F 0E    ld   a,($E0F9)
9481: DD 77 E1    ld   (ix+$0f),a
9484: CD 46 C6    call $6C64
9487: DD 72 A1    ld   (ix+$0b),d
948A: DD 73 C0    ld   (ix+$0c),e
948D: DD 70 C1    ld   (ix+$0d),b
9490: DD 71 E0    ld   (ix+$0e),c
9493: DD 36 30 96 ld   (ix+$12),$78
9497: DD 36 50 00 ld   (ix+$14),$00
949B: DD 36 51 21 ld   (ix+$15),$03
949F: 08          ex   af,af'
94A0: A7          and  a
94A1: 28 02       jr   z,$94C3
94A3: DD 7E 01    ld   a,(ix+$01)
94A6: C6 80       add  a,$08
94A8: 0F          rrca
94A9: 0F          rrca
94AA: 0F          rrca
94AB: 0F          rrca
94AC: E6 E1       and  $0F
94AE: 87          add  a,a
94AF: 21 9D 58    ld   hl,$94D9
94B2: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
94B3: DD 86 21    add  a,(ix+$03)
94B6: DD 77 21    ld   (ix+$03),a
94B9: 23          inc  hl
94BA: DD 7E 41    ld   a,(ix+$05)
94BD: 86          add  a,(hl)
94BE: DD 77 41    ld   (ix+$05),a
94C1: 18 40       jr   $94C7
94C3: DD 36 31 08 ld   (ix+$13),$80
94C7: DD 7E 01    ld   a,(ix+$01)
94CA: DD E1       pop  ix
94CC: DD 77 20    ld   (ix+$02),a
94CF: CD C4 68    call $864C
94D2: 3A 3E 0E    ld   a,($E0F2)
94D5: 32 3F 0E    ld   ($E0F3),a
94D8: C9          ret
94D9: E1          pop  hl
94DA: 41          ld   b,c
94DB: A0          and  b
94DC: 81          add  a,c
94DD: 81          add  a,c
94DE: A0          and  b
94DF: 61          ld   h,c
94E0: C0          ret  nz
94E1: 40          ld   b,b
94E2: E0          ret  po
94E3: 9F          sbc  a,a
94E4: C0          ret  nz
94E5: 7F          ld   a,a
94E6: A0          and  b
94E7: 7E          ld   a,(hl)
94E8: 81          add  a,c
94E9: 1F          rra
94EA: 41          ld   b,c
94EB: 5E          ld   e,(hl)
94EC: 00          nop
94ED: 9F          sbc  a,a
94EE: DE DE       sbc  a,$FC
94F0: FE DE       cp   $FC
94F2: BF          cp   a
94F3: 40          ld   b,b
94F4: FE 61       cp   $07
94F6: DE C0       sbc  a,$0C
94F8: 00          nop
94F9: C9          ret
94FA: 3A F9 0E    ld   a,($E09F)
94FD: A7          and  a
94FE: 20 61       jr   nz,$9507
9500: 3A 9E 0E    ld   a,($E0F8)
9503: A7          and  a
9504: CA 81 78    jp   z,$9609
9507: DD 2A 78 0E ld   ix,($E096)
950B: DD 66 01    ld   h,(ix+$01)
950E: DD 6E 00    ld   l,(ix+$00)
9511: ED 5B B5 0E ld   de,($E05B)
9515: 7B          ld   a,e
9516: 5A          ld   e,d
9517: 57          ld   d,a
9518: A7          and  a
9519: ED 52       sbc  hl,de
951B: 7C          ld   a,h
951C: A7          and  a
951D: C2 4B 59    jp   nz,$95A5
9520: 7D          ld   a,l
9521: FE 04       cp   $40
9523: DA EB 59    jp   c,$95AF
9526: 32 98 0E    ld   ($E098),a
9529: 4D          ld   c,l
952A: 21 8B 0E    ld   hl,$E0A9
952D: 7E          ld   a,(hl)
952E: E6 61       and  $07
9530: DD 6E 20    ld   l,(ix+$02)
9533: DD 66 21    ld   h,(ix+$03)
9536: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
9537: EB          ex   de,hl
9538: D9          exx
9539: DD 21 00 6E ld   ix,$E600
953D: 06 80       ld   b,$08
953F: 11 02 00    ld   de,$0020
9542: DD 7E 00    ld   a,(ix+$00)
9545: A7          and  a
9546: 28 41       jr   z,$954D
9548: DD 19       add  ix,de
954A: 10 7E       djnz $9542
954C: C9          ret
954D: D9          exx
954E: DD 36 E1 01 ld   (ix+$0f),$01
9552: DD 36 11 00 ld   (ix+$11),$00
9556: DD 36 50 00 ld   (ix+$14),$00
955A: DD 36 51 00 ld   (ix+$15),$00
955E: 7E          ld   a,(hl)
955F: 23          inc  hl
9560: DD 77 21    ld   (ix+$03),a
9563: DD 77 61    ld   (ix+$07),a
9566: 7E          ld   a,(hl)
9567: E6 01       and  $01
9569: DD 77 31    ld   (ix+$13),a
956C: 7E          ld   a,(hl)
956D: 23          inc  hl
956E: 81          add  a,c
956F: FE 94       cp   $58
9571: 38 A5       jr   c,$95BE
9573: DD 77 41    ld   (ix+$05),a
9576: DD 77 81    ld   (ix+$09),a
9579: DD 74 70    ld   (ix+$16),h
957C: DD 75 71    ld   (ix+$17),l
957F: DD CB 31 64 bit  0,(ix+$13)
9583: 28 41       jr   z,$958A
9585: CD A0 79    call $970A
9588: 20 52       jr   nz,$95BE
958A: DD 36 00 FF ld   (ix+$00),$FF
958E: CD 4C 59    call $95C4
9591: 3A 5F 0E    ld   a,($E0F5)
9594: 32 7E 0E    ld   ($E0F6),a
9597: 21 8B 0E    ld   hl,$E0A9
959A: 34          inc  (hl)
959B: 3A F9 0E    ld   a,($E09F)
959E: A7          and  a
959F: C8          ret  z
95A0: 21 0A 0E    ld   hl,$E0A0
95A3: 35          dec  (hl)
95A4: C9          ret
95A5: AF          xor  a
95A6: 32 98 0E    ld   ($E098),a
95A9: 7C          ld   a,h
95AA: FE 08       cp   $80
95AC: DA E0 78    jp   c,$960E
95AF: DD 23       inc  ix
95B1: DD 23       inc  ix
95B3: DD 23       inc  ix
95B5: DD 23       inc  ix
95B7: DD 22 78 0E ld   ($E096),ix
95BB: 18 15       jr   $960E
95BD: C9          ret
95BE: 21 8B 0E    ld   hl,$E0A9
95C1: 34          inc  (hl)
95C2: 18 A4       jr   $960E
95C4: 3A 20 0E    ld   a,($E002)
95C7: E6 06       and  $60
95C9: C0          ret  nz
95CA: 21 DE 0E    ld   hl,$E0FC
95CD: 7E          ld   a,(hl)
95CE: A7          and  a
95CF: C8          ret  z
95D0: 36 00       ld   (hl),$00
95D2: DD 7E 31    ld   a,(ix+$13)
95D5: A7          and  a
95D6: 20 40       jr   nz,$95DC
95D8: DD 36 90 04 ld   (ix+$18),$40
95DC: DD 36 31 A0 ld   (ix+$13),$0A
95E0: DD 7E 21    ld   a,(ix+$03)
95E3: FE 08       cp   $80
95E5: 38 A0       jr   c,$95F1
95E7: DD 36 91 01 ld   (ix+$19),$01
95EB: DD 36 01 1A ld   (ix+$01),$B0
95EF: 18 80       jr   $95F9
95F1: DD 36 91 00 ld   (ix+$19),$00
95F5: DD 36 01 1C ld   (ix+$01),$D0
95F9: CD 46 C6    call $6C64
95FC: DD 72 A1    ld   (ix+$0b),d
95FF: DD 73 C0    ld   (ix+$0c),e
9602: DD 70 C1    ld   (ix+$0d),b
9605: DD 71 E0    ld   (ix+$0e),c
9608: C9          ret
9609: 3E 01       ld   a,$01
960B: 32 BE 0E    ld   ($E0FA),a
960E: DD 21 00 6E ld   ix,$E600
9612: 06 80       ld   b,$08
9614: 11 02 00    ld   de,$0020
9617: DD 7E 00    ld   a,(ix+$00)
961A: A7          and  a
961B: 28 41       jr   z,$9622
961D: DD 19       add  ix,de
961F: 10 7E       djnz $9617
9621: C9          ret
9622: 3A BE 0E    ld   a,($E0FA)
9625: F7          rst  $30
9626: C2 78 86    jp   nz,$6896
9629: 78          ld   a,b
962A: AD          xor  l
962B: 78          ld   a,b
962C: DD 35 00    dec  (ix+$00)
962F: DD 36 11 00 ld   (ix+$11),$00
9633: DD 36 31 21 ld   (ix+$13),$03
9637: CD E3 98    call $982F
963A: E6 0E       and  $E0
963C: DD 77 21    ld   (ix+$03),a
963F: DD 77 61    ld   (ix+$07),a
9642: DD 36 41 1E ld   (ix+$05),$F0
9646: DD 36 81 1E ld   (ix+$09),$F0
964A: DD 36 50 00 ld   (ix+$14),$00
964E: DD 36 51 00 ld   (ix+$15),$00
9652: DD 36 90 00 ld   (ix+$18),$00
9656: 3A 5F 0E    ld   a,($E0F5)
9659: 32 7E 0E    ld   ($E0F6),a
965C: DD 36 01 0C ld   (ix+$01),$C0
9660: DD 36 20 0C ld   (ix+$02),$C0
9664: C3 6E 78    jp   $96E6
9667: C9          ret
9668: DD 35 00    dec  (ix+$00)
966B: DD 36 11 00 ld   (ix+$11),$00
966F: DD 36 31 40 ld   (ix+$13),$04
9673: CD E3 98    call $982F
9676: 47          ld   b,a
9677: E6 0E       and  $E0
9679: DD 77 41    ld   (ix+$05),a
967C: DD 77 81    ld   (ix+$09),a
967F: 3E 1E       ld   a,$F0
9681: 0E 08       ld   c,$80
9683: CB 50       bit  2,b
9685: 28 40       jr   z,$968B
9687: 3E 00       ld   a,$00
9689: 0E 00       ld   c,$00
968B: DD 77 21    ld   (ix+$03),a
968E: DD 77 61    ld   (ix+$07),a
9691: 78          ld   a,b
9692: E6 E1       and  $0F
9694: D6 80       sub  $08
9696: 81          add  a,c
9697: DD 77 01    ld   (ix+$01),a
969A: DD 77 20    ld   (ix+$02),a
969D: DD 36 50 00 ld   (ix+$14),$00
96A1: DD 36 51 00 ld   (ix+$15),$00
96A5: DD 36 90 00 ld   (ix+$18),$00
96A9: DD 36 71 00 ld   (ix+$17),$00
96AD: 3A 5F 0E    ld   a,($E0F5)
96B0: 32 7E 0E    ld   ($E0F6),a
96B3: CD 46 C6    call $6C64
96B6: DD 72 A1    ld   (ix+$0b),d
96B9: DD 73 C0    ld   (ix+$0c),e
96BC: DD 70 C1    ld   (ix+$0d),b
96BF: DD 71 E0    ld   (ix+$0e),c
96C2: CD A0 79    call $970A
96C5: C8          ret  z
96C6: DD 36 00 00 ld   (ix+$00),$00
96CA: C9          ret
96CB: DD 35 00    dec  (ix+$00)
96CE: DD 36 11 00 ld   (ix+$11),$00
96D2: DD 36 31 41 ld   (ix+$13),$05
96D6: CD E3 98    call $982F
96D9: 47          ld   b,a
96DA: E6 F7       and  $7F
96DC: C6 08       add  a,$80
96DE: DD 77 41    ld   (ix+$05),a
96E1: DD 77 81    ld   (ix+$09),a
96E4: 18 99       jr   $967F
96E6: 06 21       ld   b,$03
96E8: 0E 02       ld   c,$20
96EA: FE 08       cp   $80
96EC: DD 7E 21    ld   a,(ix+$03)
96EF: 38 20       jr   c,$96F3
96F1: 0E 0E       ld   c,$E0
96F3: C5          push bc
96F4: CD A0 79    call $970A
96F7: C1          pop  bc
96F8: C8          ret  z
96F9: DD 7E 21    ld   a,(ix+$03)
96FC: 81          add  a,c
96FD: DD 77 21    ld   (ix+$03),a
9700: DD 77 61    ld   (ix+$07),a
9703: 10 EE       djnz $96F3
9705: DD 36 00 00 ld   (ix+$00),$00
9709: C9          ret
970A: CD 39 A9    call $8B93
970D: A7          and  a
970E: C2 A6 79    jp   nz,$976A
9711: DD 7E 81    ld   a,(ix+$09)
9714: 47          ld   b,a
9715: 3A 30 EF    ld   a,($EF12)
9718: E6 E1       and  $0F
971A: 80          add  a,b
971B: 47          ld   b,a
971C: DD 7E 61    ld   a,(ix+$07)
971F: C6 61       add  a,$07
9721: 4F          ld   c,a
9722: 3A 10 EF    ld   a,($EF10)
9725: 57          ld   d,a
9726: 3A 11 EF    ld   a,($EF11)
9729: 5F          ld   e,a
972A: 78          ld   a,b
972B: E6 1E       and  $F0
972D: 6F          ld   l,a
972E: 26 00       ld   h,$00
9730: 29          add  hl,hl
9731: 19          add  hl,de
9732: 79          ld   a,c
9733: CB 3F       srl  a
9735: 4F          ld   c,a
9736: CB 3F       srl  a
9738: CB 3F       srl  a
973A: E6 F0       and  $1E
973C: DF          rst  $18                   ; call ADD_A_TO_HL
973D: 7C          ld   a,h
973E: E6 BF       and  $FB
9740: 67          ld   h,a
9741: 7E          ld   a,(hl)
9742: A7          and  a
9743: C8          ret  z
9744: 5F          ld   e,a
9745: 23          inc  hl
9746: 7E          ld   a,(hl)
9747: A7          and  a
9748: 28 21       jr   z,$974D
974A: 79          ld   a,c
974B: 2F          cpl
974C: 4F          ld   c,a
974D: 6B          ld   l,e
974E: 26 00       ld   h,$00
9750: 29          add  hl,hl
9751: 29          add  hl,hl
9752: 29          add  hl,hl
9753: 78          ld   a,b
9754: 0F          rrca
9755: 2F          cpl
9756: E6 61       and  $07
9758: DF          rst  $18                   ; call ADD_A_TO_HL  
9759: 11 46 46    ld   de,$6464
975C: 19          add  hl,de
975D: 56          ld   d,(hl)
975E: 79          ld   a,c
975F: E6 61       and  $07
9761: 21 E6 79    ld   hl,$976E
9764: DF          rst  $18                   ; call ADD_A_TO_HL
9765: 7E          ld   a,(hl)
9766: A2          and  d
9767: 20 01       jr   nz,$976A
9769: C9          ret
976A: 3E 01       ld   a,$01
976C: A7          and  a
976D: C9          ret
976E: 08          ex   af,af'
976F: 04          inc  b
9770: 02          ld   (bc),a
9771: 10 80       djnz $977B
9773: 40          ld   b,b
9774: 20 01       jr   nz,$9777
9776: 3A 20 0E    ld   a,($E002)
9779: E6 F1       and  $1F
977B: C0          ret  nz
977C: 3A 55 0E    ld   a,($E055)
977F: FE 20       cp   $02
9781: D0          ret  nc
9782: 21 AE 79    ld   hl,$97EA
9785: E5          push hl
9786: 3A BA 0E    ld   a,($E0BA)
9789: 21 8C 7B    ld   hl,$B7C8
978C: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
978D: D5          push de
978E: FD E1       pop  iy
9790: FD 4E 00    ld   c,(iy+$00)
9793: FD 23       inc  iy
9795: DD 21 00 6E ld   ix,$E600
9799: 06 80       ld   b,$08
979B: DD 7E 00    ld   a,(ix+$00)
979E: A7          and  a
979F: 28 80       jr   z,$97A9
97A1: 11 02 00    ld   de,$0020
97A4: DD 19       add  ix,de
97A6: 10 3F       djnz $979B
97A8: C9          ret
97A9: DD 35 00    dec  (ix+$00)
97AC: FD 7E 00    ld   a,(iy+$00)
97AF: DD 77 21    ld   (ix+$03),a
97B2: DD 77 61    ld   (ix+$07),a
97B5: FD 7E 01    ld   a,(iy+$01)
97B8: DD 77 41    ld   (ix+$05),a
97BB: DD 77 81    ld   (ix+$09),a
97BE: FD 7E 21    ld   a,(iy+$03)
97C1: DD 77 70    ld   (ix+$16),a
97C4: FD 7E 20    ld   a,(iy+$02)
97C7: DD 77 71    ld   (ix+$17),a
97CA: FD 7E 40    ld   a,(iy+$04)
97CD: DD 77 31    ld   (ix+$13),a
97D0: DD 36 E1 00 ld   (ix+$0f),$00
97D4: DD 36 11 00 ld   (ix+$11),$00
97D8: DD 36 50 00 ld   (ix+$14),$00
97DC: DD 36 51 00 ld   (ix+$15),$00
97E0: 11 41 00    ld   de,$0005
97E3: FD 19       add  iy,de
97E5: 0D          dec  c
97E6: C8          ret  z
97E7: C3 0B 79    jp   $97A1
97EA: 21 BB 0E    ld   hl,$E0BB
97ED: 35          dec  (hl)
97EE: C9          ret
97EF: 3A B0 0F    ld   a,($E11A)
97F2: A7          and  a
97F3: C0          ret  nz
97F4: 3A BB 0E    ld   a,($E0BB)
97F7: A7          and  a
97F8: C2 76 79    jp   nz,$9776
97FB: 3A 7E 0E    ld   a,($E0F6)
97FE: A7          and  a
97FF: C0          ret  nz
9800: 3A 55 0E    ld   a,($E055)
9803: 47          ld   b,a
9804: 3A 5E 0E    ld   a,($E0F4)
9807: B8          cp   b
9808: D8          ret  c
9809: 3A F9 0E    ld   a,($E09F)
980C: A7          and  a
980D: 28 60       jr   z,$9815
980F: 21 0A 0E    ld   hl,$E0A0
9812: 7E          ld   a,(hl)
9813: A7          and  a
9814: C8          ret  z
9815: CD BE 58    call $94FA
9818: C9          ret
9819: 21 43 98    ld   hl,$9825
981C: 11 0C EE    ld   de,$EEC0
981F: 01 A0 00    ld   bc,$000A
9822: ED B0       ldir
9824: C9          ret
9825: EB          ex   de,hl
9826: 0F          rrca
9827: 32 D7 A5    ld   ($4B7D),a
982A: 00          nop
982B: 78          ld   a,b
982C: 8C          adc  a,h
982D: 46          ld   b,(hl)
982E: 91          sub  c
982F: E5          push hl
9830: D5          push de
9831: C5          push bc
9832: 3A 0C EE    ld   a,($EEC0)
9835: 47          ld   b,a
9836: 3A 20 0E    ld   a,($E002)
9839: 80          add  a,b
983A: 47          ld   b,a
983B: 3A 92 FF    ld   a,($FF38)
983E: 80          add  a,b
983F: 21 0D EE    ld   hl,$EEC1
9842: 11 0C EE    ld   de,$EEC0
9845: ED A0       ldi
9847: ED A0       ldi
9849: ED A0       ldi
984B: ED A0       ldi
984D: ED A0       ldi
984F: ED A0       ldi
9851: ED A0       ldi
9853: ED A0       ldi
9855: ED A0       ldi
9857: 32 8D EE    ld   ($EEC9),a
985A: C1          pop  bc
985B: D1          pop  de
985C: E1          pop  hl
985D: C9          ret
985E: C9          ret
985F: 21 97 1D    ld   hl,$D179
9862: 22 A7 0E    ld   ($E06B),hl
9865: 21 7C 1C    ld   hl,$D0D6
9868: 22 19 0E    ld   ($E091),hl
986B: AF          xor  a
986C: 32 71 0E    ld   ($E017),a
986F: 32 9A 0E    ld   ($E0B8),a
9872: 32 9B 0E    ld   ($E0B9),a
9875: CD 6E 98    call $98E6
9878: CD AB 98    call $98AB
987B: CD AD 98    call $98CB
987E: CD C9 98    call $988D
9881: 3E 06       ld   a,$60
9883: 32 E7 0E    ld   ($E06F),a
9886: CD BB 68    call $86BB
9889: CD 7F 68    call $86F7
988C: C9          ret
988D: DD 21 00 2E ld   ix,$E200
9891: 06 40       ld   b,$04
9893: 11 10 00    ld   de,$0010
9896: CD 2A 98    call $98A2
9899: DD 21 0C 2E ld   ix,$E2C0
989D: 06 A0       ld   b,$0A
989F: 11 40 00    ld   de,$0004
98A2: DD 36 00 00 ld   (ix+$00),$00
98A6: DD 19       add  ix,de
98A8: 10 9E       djnz $98A2
98AA: C9          ret


98AB: DD 21 00 0F ld   ix,$E100
98AF: FD 21 92 FF ld   iy,$FF38
98B3: DD 36 00 00 ld   (ix+$00),$00
98B7: DD 36 21 C2 ld   (ix+$03),$2C
98BB: DD 36 41 04 ld   (ix+$05),$40
98BF: 11 4D 98    ld   de,$98C5
98C2: C3 88 A3    jp   $2B88
98C5: 20 00       jr   nz,$98C7
98C7: 01 60 00    ld   bc,$0006
98CA: E0          ret  po
98CB: DD 21 80 0F ld   ix,$E108
98CF: FD 21 04 FF ld   iy,$FF40
98D3: DD 36 00 00 ld   (ix+$00),$00
98D7: DD 36 21 C2 ld   (ix+$03),$2C
98DB: DD 36 41 CA ld   (ix+$05),$AC
98DF: 1E 7F       ld   e,$F7
98E1: 16 08       ld   d,$80
98E3: C3 9C D0    jp   $1CD8
98E6: 11 61 99    ld   de,$9907
98E9: 21 7C 1C    ld   hl,$D0D6
98EC: 0E 21       ld   c,$03
98EE: 06 A0       ld   b,$0A
98F0: E5          push hl
98F1: CB D4       set  2,h
98F3: 36 00       ld   (hl),$00
98F5: CB 94       res  2,h
98F7: 1A          ld   a,(de)
98F8: 77          ld   (hl),a
98F9: 3E 04       ld   a,$40
98FB: DF          rst  $18                   ; call ADD_A_TO_HL
98FC: 13          inc  de
98FD: 10 3E       djnz $98F1
98FF: E1          pop  hl
9900: 0D          dec  c
9901: C8          ret  z
9902: 2D          dec  l
9903: 2D          dec  l
9904: 18 8E       jr   $98EE
9906: C9          ret


9907: 05          dec  b
9908: 24          inc  h
9909: 25          dec  h
990A: 44          ld   b,h
990B: 45          ld   b,l
990C: 64          ld   h,h
990D: 65          ld   h,l
990E: 84          add  a,h
990F: 85          add  a,l
9910: A4          and  h
9911: A5          and  l
9912: C4 C5 E4    call nz,$4E4D
9915: E5          push hl
9916: 14          inc  d
9917: 15          dec  d
9918: 34          inc  (hl)
9919: 35          dec  (hl)
991A: 54          ld   d,h
991B: 55          ld   d,l
991C: 74          ld   (hl),h
991D: 75          ld   (hl),l
991E: 94          sub  h
991F: 95          sub  l
9920: B4          or   h
9921: B5          or   l
9922: D4 D5 F6    call nc,$7E5D
9925: 3A 9A 0E    ld   a,($E0B8)
9928: A7          and  a
9929: 20 C2       jr   nz,$9957
992B: CD 49 99    call $9985
992E: CD FB 99    call $99BF
9931: CD C5 B8    call $9A4D
9934: CD 05 99    call $9941
9937: CD BD B8    call $9ADB
993A: CD F3 B9    call $9B3F
993D: CD 21 D8    call $9C03
9940: C9          ret
9941: DD 7E 21    ld   a,(ix+$03)
9944: 0F          rrca
9945: 0F          rrca
9946: E6 21       and  $03
9948: 21 F3 D8    ld   hl,$9C3F
994B: FD 21 92 FF ld   iy,$FF38
994F: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
9950: FD 73 00    ld   (iy+$00),e
9953: FD 72 40    ld   (iy+$04),d
9956: C9          ret

9957: CD F3 B9    call $9B3F
995A: CD 21 D8    call $9C03
995D: DD 21 00 2E ld   ix,$E200
9961: 11 10 00    ld   de,$0010
9964: 06 40       ld   b,$04
9966: CD B6 99    call $997A
9969: C0          ret  nz
996A: DD 21 0C 2E ld   ix,$E2C0
996E: 11 40 00    ld   de,$0004
9971: 06 A0       ld   b,$0A
9973: CD B6 99    call $997A
9976: C0          ret  nz
9977: C3 8B 99    jp   $99A9
997A: DD 7E 00    ld   a,(ix+$00)
997D: A7          and  a
997E: C0          ret  nz
997F: DD 19       add  ix,de
9981: 10 7F       djnz $997A
9983: AF          xor  a
9984: C9          ret

9985: 3A 16 0E    ld   a,($E070)
9988: A7          and  a
9989: 28 41       jr   z,$9990
998B: 3D          dec  a
998C: 32 16 0E    ld   ($E070),a
998F: C9          ret

9990: 3E D2       ld   a,$3C
9992: 32 16 0E    ld   ($E070),a
9995: 21 E7 0E    ld   hl,$E06F
9998: 7E          ld   a,(hl)
9999: D6 01       sub  $01
999B: 27          daa
999C: DA 5F B9    jp   c,$9BF5
999F: 77          ld   (hl),a
99A0: 21 D2 1D    ld   hl,$D13C
99A3: 0E 01       ld   c,$01
99A5: C3 D8 D8    jp   $9C9C
99A8: C9          ret

99A9: 3E 01       ld   a,$01
99AB: 32 71 0E    ld   ($E017),a
99AE: 11 B8 EE    ld   de,$EE9A
99B1: 21 97 1D    ld   hl,$D179
99B4: 06 A0       ld   b,$0A
99B6: 7E          ld   a,(hl)
99B7: 12          ld   (de),a
99B8: 3E 02       ld   a,$20
99BA: DF          rst  $18                   ; call ADD_A_TO_HL
99BB: 13          inc  de
99BC: 10 9E       djnz $99B6
99BE: C9          ret

99BF: DD 21 00 0F ld   ix,$E100
99C3: FD 21 92 FF ld   iy,$FF38
99C7: DD 7E 00    ld   a,(ix+$00)
99CA: A7          and  a
99CB: 28 D3       jr   z,$9A0A
99CD: 06 20       ld   b,$02
99CF: DD 7E 01    ld   a,(ix+$01)
99D2: A7          and  a
99D3: 28 20       jr   z,$99D7
99D5: 06 FE       ld   b,$FE
99D7: DD 7E 21    ld   a,(ix+$03)
99DA: 80          add  a,b
99DB: DD 77 21    ld   (ix+$03),a
99DE: DD 77 A1    ld   (ix+$0b),a
99E1: FD 77 A0    ld   (iy+$0a),a
99E4: CD FB 98    call $98BF
99E7: DD 35 00    dec  (ix+$00)
99EA: C0          ret  nz
99EB: 21 9B 0E    ld   hl,$E0B9
99EE: ED 5B 19 0E ld   de,($E091)
99F2: DD 7E 01    ld   a,(ix+$01)
99F5: A7          and  a
99F6: 20 81       jr   nz,$9A01
99F8: 34          inc  (hl)
99F9: 21 04 00    ld   hl,$0040
99FC: 19          add  hl,de
99FD: 22 19 0E    ld   ($E091),hl
9A00: C9          ret

9A01: 35          dec  (hl)
9A02: 21 0C FF    ld   hl,$FFC0
9A05: 19          add  hl,de
9A06: 22 19 0E    ld   ($E091),hl
9A09: C9          ret

9A0A: 3A 91 0E    ld   a,($E019)
9A0D: E6 01       and  $01
9A0F: 28 E1       jr   z,$9A20
9A11: 3A 11 0E    ld   a,($E011)
9A14: E6 01       and  $01
9A16: 20 71       jr   nz,$9A2F
9A18: 3A 10 0E    ld   a,($E010)
9A1B: E6 01       and  $01
9A1D: 20 F1       jr   nz,$9A3E
9A1F: C9          ret

9A20: 3A 81 0E    ld   a,($E009)
9A23: E6 01       and  $01
9A25: 20 80       jr   nz,$9A2F
9A27: 3A 80 0E    ld   a,($E008)
9A2A: E6 01       and  $01
9A2C: 20 10       jr   nz,$9A3E
9A2E: C9          ret

9A2F: DD 7E 21    ld   a,(ix+$03)
9A32: FE C2       cp   $2C
9A34: C8          ret  z
9A35: DD 36 01 01 ld   (ix+$01),$01
9A39: DD 36 00 80 ld   (ix+$00),$08
9A3D: C9          ret

9A3E: DD 7E 21    ld   a,(ix+$03)
9A41: FE DA       cp   $BC
9A43: C8          ret  z
9A44: DD 36 01 00 ld   (ix+$01),$00
9A48: DD 36 00 80 ld   (ix+$00),$08
9A4C: C9          ret

9A4D: DD 21 80 0F ld   ix,$E108
9A51: FD 21 04 FF ld   iy,$FF40
9A55: DD 7E 00    ld   a,(ix+$00)
9A58: A7          and  a
9A59: 28 D3       jr   z,$9A98
9A5B: 06 20       ld   b,$02
9A5D: DD 7E 01    ld   a,(ix+$01)
9A60: A7          and  a
9A61: 28 20       jr   z,$9A65
9A63: 06 FE       ld   b,$FE
9A65: DD 7E 41    ld   a,(ix+$05)
9A68: 80          add  a,b
9A69: DD 77 41    ld   (ix+$05),a
9A6C: CD FD 98    call $98DF
9A6F: DD 35 00    dec  (ix+$00)
9A72: C0          ret  nz
9A73: 21 9B 0E    ld   hl,$E0B9
9A76: ED 5B 19 0E ld   de,($E091)
9A7A: DD 7E 01    ld   a,(ix+$01)
9A7D: A7          and  a
9A7E: 20 C0       jr   nz,$9A8C
9A80: 7E          ld   a,(hl)
9A81: C6 7E       add  a,$F6
9A83: 77          ld   (hl),a
9A84: 21 20 00    ld   hl,$0002
9A87: 19          add  hl,de
9A88: 22 19 0E    ld   ($E091),hl
9A8B: C9          ret

9A8C: 7E          ld   a,(hl)
9A8D: C6 A0       add  a,$0A
9A8F: 77          ld   (hl),a
9A90: 21 FE FF    ld   hl,$FFFE
9A93: 19          add  hl,de
9A94: 22 19 0E    ld   ($E091),hl
9A97: C9          ret

9A98: 3A 91 0E    ld   a,($E019)
9A9B: E6 01       and  $01
9A9D: 28 E1       jr   z,$9AAE
9A9F: 3A 31 0E    ld   a,($E013)
9AA2: E6 01       and  $01
9AA4: 20 71       jr   nz,$9ABD
9AA6: 3A 30 0E    ld   a,($E012)
9AA9: E6 01       and  $01
9AAB: 20 F1       jr   nz,$9ACC
9AAD: C9          ret

9AAE: 3A A1 0E    ld   a,($E00B)
9AB1: E6 01       and  $01
9AB3: 20 80       jr   nz,$9ABD
9AB5: 3A A0 0E    ld   a,($E00A)
9AB8: E6 01       and  $01
9ABA: 20 10       jr   nz,$9ACC
9ABC: C9          ret

9ABD: DD 7E 41    ld   a,(ix+$05)
9AC0: FE CA       cp   $AC
9AC2: C8          ret  z
9AC3: DD 36 01 00 ld   (ix+$01),$00
9AC7: DD 36 00 80 ld   (ix+$00),$08
9ACB: C9          ret

9ACC: DD 7E 41    ld   a,(ix+$05)
9ACF: FE C8       cp   $8C
9AD1: C8          ret  z
9AD2: DD 36 01 01 ld   (ix+$01),$01
9AD6: DD 36 00 80 ld   (ix+$00),$08
9ADA: C9          ret

9ADB: 21 C0 0E    ld   hl,$E00C
9ADE: 3A 91 0E    ld   a,($E019)
9AE1: E6 01       and  $01
9AE3: 28 21       jr   z,$9AE8
9AE5: 21 50 0E    ld   hl,$E014
9AE8: 7E          ld   a,(hl)
9AE9: E6 61       and  $07
9AEB: FE 01       cp   $01
9AED: C0          ret  nz
9AEE: DD 21 00 2E ld   ix,$E200
9AF2: FD 21 84 FF ld   iy,$FF48
9AF6: 11 40 00    ld   de,$0004
9AF9: 01 10 00    ld   bc,$0010
9AFC: 26 40       ld   h,$04
9AFE: DD 7E 00    ld   a,(ix+$00)
9B01: A7          and  a
9B02: 28 81       jr   z,$9B0D
9B04: DD 09       add  ix,bc
9B06: FD 19       add  iy,de
9B08: 25          dec  h
9B09: C8          ret  z
9B0A: C3 FE B8    jp   $9AFE
9B0D: DD 36 00 FF ld   (ix+$00),$FF
9B11: 3A 21 0F    ld   a,($E103)
9B14: FD 77 20    ld   (iy+$02),a
9B17: 3A C1 0F    ld   a,($E10D)
9B1A: DD 77 40    ld   (ix+$04),a
9B1D: 3A 41 0F    ld   a,($E105)
9B20: FD 77 21    ld   (iy+$03),a
9B23: FD 36 00 5B ld   (iy+$00),$B5
9B27: FD 36 01 00 ld   (iy+$01),$00
9B2B: 3A 9B 0E    ld   a,($E0B9)
9B2E: 21 61 99    ld   hl,$9907
9B31: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
9B32: DD 77 01    ld   (ix+$01),a
9B35: 2A 19 0E    ld   hl,($E091)
9B38: DD 74 20    ld   (ix+$02),h
9B3B: DD 75 21    ld   (ix+$03),l
9B3E: C9          ret

9B3F: DD 21 00 2E ld   ix,$E200
9B43: FD 21 84 FF ld   iy,$FF48
9B47: 06 40       ld   b,$04
9B49: C5          push bc
9B4A: DD 7E 00    ld   a,(ix+$00)
9B4D: A7          and  a
9B4E: 28 21       jr   z,$9B53
9B50: CD 07 B9    call $9B61
9B53: C1          pop  bc
9B54: 11 10 00    ld   de,$0010
9B57: DD 19       add  ix,de
9B59: 11 40 00    ld   de,$0004
9B5C: FD 19       add  iy,de
9B5E: 10 8F       djnz $9B49
9B60: C9          ret

9B61: FD 34 21    inc  (iy+$03)
9B64: FD 34 21    inc  (iy+$03)
9B67: FD 34 21    inc  (iy+$03)
9B6A: DD 7E 40    ld   a,(ix+$04)
9B6D: FD 96 21    sub  (iy+$03)
9B70: D0          ret  nc
9B71: 3A 9A 0E    ld   a,($E0B8)
9B74: A7          and  a
9B75: C2 BE B9    jp   nz,$9BFA
9B78: DD 7E 01    ld   a,(ix+$01)
9B7B: FE F6       cp   $7E
9B7D: 28 76       jr   z,$9BF5
9B7F: FE D5       cp   $5D
9B81: 28 E5       jr   z,$9BD2
9B83: DD 66 01    ld   h,(ix+$01)
9B86: DD 56 20    ld   d,(ix+$02)
9B89: DD 5E 21    ld   e,(ix+$03)
9B8C: DD 36 00 00 ld   (ix+$00),$00
9B90: FD 36 20 00 ld   (iy+$02),$00
9B94: D9          exx
9B95: DD E5       push ix
9B97: DD 21 0C 2E ld   ix,$E2C0
9B9B: 11 40 00    ld   de,$0004
9B9E: DD 7E 00    ld   a,(ix+$00)
9BA1: A7          and  a
9BA2: 28 41       jr   z,$9BA9
9BA4: DD 19       add  ix,de
9BA6: C3 F8 B9    jp   $9B9E
9BA9: D9          exx
9BAA: DD 36 00 06 ld   (ix+$00),$60
9BAE: DD 74 01    ld   (ix+$01),h
9BB1: DD 72 20    ld   (ix+$02),d
9BB4: DD 73 21    ld   (ix+$03),e
9BB7: DD E1       pop  ix
9BB9: 7C          ld   a,h
9BBA: 2A A7 0E    ld   hl,($E06B)
9BBD: 77          ld   (hl),a
9BBE: 11 02 00    ld   de,$0020
9BC1: 19          add  hl,de
9BC2: 22 A7 0E    ld   ($E06B),hl
9BC5: 11 9B 3C    ld   de,$D2B9
9BC8: 7C          ld   a,h
9BC9: BA          cp   d
9BCA: C0          ret  nz
9BCB: 7D          ld   a,l
9BCC: BB          cp   e
9BCD: C0          ret  nz
9BCE: C3 5F B9    jp   $9BF5
9BD1: C9          ret

9BD2: DD 36 00 00 ld   (ix+$00),$00
9BD6: FD 36 20 00 ld   (iy+$02),$00
9BDA: 11 97 1D    ld   de,$D179
9BDD: 2A A7 0E    ld   hl,($E06B)
9BE0: 7C          ld   a,h
9BE1: BA          cp   d
9BE2: 20 40       jr   nz,$9BE8
9BE4: 7D          ld   a,l
9BE5: BB          cp   e
9BE6: 28 A0       jr   z,$9BF2
9BE8: 11 0E FF    ld   de,$FFE0
9BEB: 19          add  hl,de
9BEC: 22 A7 0E    ld   ($E06B),hl
9BEF: 36 E2       ld   (hl),$2E
9BF1: C9          ret

9BF2: 36 E2       ld   (hl),$2E
9BF4: C9          ret

9BF5: 3E 01       ld   a,$01
9BF7: 32 9A 0E    ld   ($E0B8),a
9BFA: DD 36 00 00 ld   (ix+$00),$00
9BFE: FD 36 20 00 ld   (iy+$02),$00
9C02: C9          ret

9C03: DD 21 0C 2E ld   ix,$E2C0
9C07: 11 40 00    ld   de,$0004
9C0A: 06 A0       ld   b,$0A
9C0C: D9          exx
9C0D: DD 7E 00    ld   a,(ix+$00)
9C10: A7          and  a
9C11: 28 21       jr   z,$9C16
9C13: CD D0 D8    call $9C1C
9C16: D9          exx
9C17: DD 19       add  ix,de
9C19: 10 1F       djnz $9C0C
9C1B: C9          ret
9C1C: DD 35 00    dec  (ix+$00)
9C1F: 28 D2       jr   z,$9C5D
9C21: DD 7E 00    ld   a,(ix+$00)
9C24: 0F          rrca
9C25: E6 61       and  $07
9C27: 47          ld   b,a
9C28: E6 21       and  $03
9C2A: FE 20       cp   $02
9C2C: 28 83       jr   z,$9C57
9C2E: 78          ld   a,b
9C2F: 21 65 D8    ld   hl,$9C47
9C32: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
9C33: CD 47 D8    call $9C65
9C36: DD 7E 01    ld   a,(ix+$01)
9C39: 83          add  a,e
9C3A: 77          ld   (hl),a
9C3B: CB D4       set  2,h
9C3D: 72          ld   (hl),d
9C3E: C9          ret

9C3F: 41          ld   b,c
9C40: C1          pop  bc
9C41: 60          ld   h,b
9C42: E0          ret  po
9C43: 61          ld   h,c
9C44: E1          pop  hl
9C45: 60          ld   h,b
9C46: E0          ret  po
9C47: 00          nop
9C48: 00          nop
9C49: 04          inc  b
9C4A: 00          nop
9C4B: 04          inc  b
9C4C: 00          nop
9C4D: 04          inc  b
9C4E: 02          ld   (bc),a
9C4F: 00          nop
9C50: 02          ld   (bc),a
9C51: 02          ld   (bc),a
9C52: 02          ld   (bc),a
9C53: 02          ld   (bc),a
9C54: 00          nop
9C55: 02          ld   (bc),a
9C56: 00          nop
9C57: CD 47 D8    call $9C65
9C5A: 36 F7       ld   (hl),$7F
9C5C: C9          ret

9C5D: CD 47 D8    call $9C65
9C60: DD 7E 01    ld   a,(ix+$01)
9C63: 77          ld   (hl),a
9C64: C9          ret

9C65: DD 66 20    ld   h,(ix+$02)
9C68: DD 6E 21    ld   l,(ix+$03)
9C6B: C9          ret

9C6C: C9          ret


PRINT_TEXT:
9C6D: 5E          ld   e,(hl)
9C6E: 23          inc  hl
9C6F: 56          ld   d,(hl)
9C70: 23          inc  hl
9C71: 4E          ld   c,(hl)
9C72: 23          inc  hl
9C73: EB          ex   de,hl
9C74: 1A          ld   a,(de)
9C75: FE 04       cp   $40
9C77: C8          ret  z
9C78: 77          ld   (hl),a
9C79: CB D4       set  2,h
9C7B: 71          ld   (hl),c
9C7C: CB 94       res  2,h
9C7E: 3E 02       ld   a,$20
9C80: DF          rst  $18                   ; call ADD_A_TO_HL
9C81: 13          inc  de
9C82: 18 1E       jr   $9C74

9C84: 5E          ld   e,(hl)
9C85: 23          inc  hl
9C86: 56          ld   d,(hl)
9C87: 23          inc  hl
9C88: 4E          ld   c,(hl)
9C89: 23          inc  hl
9C8A: EB          ex   de,hl
9C8B: 1A          ld   a,(de)
9C8C: FE 04       cp   $40
9C8E: C8          ret  z
9C8F: 36 02       ld   (hl),$20
9C91: CB D4       set  2,h
9C93: 71          ld   (hl),c
9C94: CB 94       res  2,h
9C96: 3E 02       ld   a,$20
9C98: DF          rst  $18                   ; call ADD_A_TO_HL
9C99: 13          inc  de
9C9A: 18 EF       jr   $9C8B
9C9C: 47          ld   b,a
9C9D: 0F          rrca
9C9E: 0F          rrca
9C9F: 0F          rrca
9CA0: 0F          rrca
9CA1: E6 E1       and  $0F
9CA3: CD 8B D8    call $9CA9
9CA6: 78          ld   a,b
9CA7: E6 E1       and  $0F
9CA9: 77          ld   (hl),a
9CAA: CB D4       set  2,h
9CAC: 71          ld   (hl),c
9CAD: CB 94       res  2,h
9CAF: 3E 02       ld   a,$20
9CB1: DF          rst  $18                   ; call ADD_A_TO_HL
9CB2: C9          ret
9CB3: 3E 00       ld   a,$00
9CB5: 4F          ld   c,a
9CB6: 21 F0 1D    ld   hl,$D11E
9CB9: 36 12       ld   (hl),$30
9CBB: CB D4       set  2,h
9CBD: 71          ld   (hl),c
9CBE: 21 F4 1C    ld   hl,$D05E
9CC1: 11 19 EE    ld   de,$EE91
9CC4: C3 F1 D9    jp   $9D1F
9CC7: C9          ret
9CC8: 3E 00       ld   a,$00
9CCA: 4F          ld   c,a
9CCB: 21 FA 3D    ld   hl,$D3BE
9CCE: 36 12       ld   (hl),$30
9CD0: CB D4       set  2,h
9CD2: 71          ld   (hl),c
9CD3: 21 FE 3C    ld   hl,$D2FE
9CD6: 11 58 EE    ld   de,$EE94
9CD9: C3 F1 D9    jp   $9D1F
9CDC: 3E 00       ld   a,$00
9CDE: 4F          ld   c,a
9CDF: 21 F4 3C    ld   hl,$D25E
9CE2: 36 12       ld   (hl),$30
9CE4: CB D4       set  2,h
9CE6: 71          ld   (hl),c
9CE7: CB 94       res  2,h
9CE9: 21 F8 1D    ld   hl,$D19E
9CEC: 11 79 EE    ld   de,$EE97
9CEF: C3 F1 D9    jp   $9D1F
9CF2: 47          ld   b,a
9CF3: 0F          rrca
9CF4: 0F          rrca
9CF5: 0F          rrca
9CF6: 0F          rrca
9CF7: E6 E1       and  $0F
9CF9: CA 01 D9    jp   z,$9D01
9CFC: CD 8B D8    call $9CA9
9CFF: 18 E1       jr   $9D10
9D01: 08          ex   af,af'
9D02: 7E          ld   a,(hl)
9D03: FE 02       cp   $20
9D05: 28 60       jr   z,$9D0D
9D07: 08          ex   af,af'
9D08: CD 8B D8    call $9CA9
9D0B: 18 21       jr   $9D10
9D0D: 3E 02       ld   a,$20
9D0F: DF          rst  $18                   ; call ADD_A_TO_HL
9D10: 78          ld   a,b
9D11: E6 E1       and  $0F
9D13: C2 8B D8    jp   nz,$9CA9
9D16: 7E          ld   a,(hl)
9D17: FE 02       cp   $20
9D19: C8          ret  z
9D1A: C3 8B D8    jp   $9CA9
9D1D: C9          ret
9D1E: C9          ret
9D1F: AF          xor  a
9D20: 32 45 0E    ld   ($E045),a
9D23: 3E 60       ld   a,$06
9D25: 32 64 0E    ld   ($E046),a
9D28: 1A          ld   a,(de)
9D29: 13          inc  de
9D2A: 47          ld   b,a
9D2B: 0F          rrca
9D2C: 0F          rrca
9D2D: 0F          rrca
9D2E: 0F          rrca
9D2F: E6 E1       and  $0F
9D31: 28 B1       jr   z,$9D4E
9D33: 32 45 0E    ld   ($E045),a
9D36: 77          ld   (hl),a
9D37: CB D4       set  2,h
9D39: 71          ld   (hl),c
9D3A: CB 94       res  2,h
9D3C: 3E 02       ld   a,$20
9D3E: DF          rst  $18                   ; call ADD_A_TO_HL
9D3F: 3A 64 0E    ld   a,($E046)
9D42: 3D          dec  a
9D43: C8          ret  z
9D44: 32 64 0E    ld   ($E046),a
9D47: E6 01       and  $01
9D49: 28 DD       jr   z,$9D28
9D4B: 78          ld   a,b
9D4C: 18 0F       jr   $9D2F
9D4E: 08          ex   af,af'
9D4F: 3A 45 0E    ld   a,($E045)
9D52: A7          and  a
9D53: 28 6F       jr   z,$9D3C
9D55: 08          ex   af,af'
9D56: 18 FC       jr   $9D36
9D58: 3A 80 0E    ld   a,($E008)
9D5B: E6 61       and  $07
9D5D: FE 01       cp   $01
9D5F: 28 D0       jr   z,$9D7D
9D61: 3A 81 0E    ld   a,($E009)
9D64: E6 61       and  $07
9D66: FE 01       cp   $01
9D68: 28 90       jr   z,$9D82
9D6A: 3A A1 0E    ld   a,($E00B)
9D6D: E6 61       and  $07
9D6F: FE 01       cp   $01
9D71: 28 50       jr   z,$9D87
9D73: 3A A0 0E    ld   a,($E00A)
9D76: E6 61       and  $07
9D78: FE 01       cp   $01
9D7A: 28 10       jr   z,$9D8C
9D7C: C9          ret
9D7D: 11 00 41    ld   de,$0500
9D80: FF          rst  $38
9D81: C9          ret
9D82: 11 01 41    ld   de,$0501
9D85: FF          rst  $38
9D86: C9          ret
9D87: 11 21 41    ld   de,$0503
9D8A: FF          rst  $38
9D8B: C9          ret
9D8C: 11 41 41    ld   de,$0505
9D8F: FF          rst  $38
9D90: C9          ret
9D91: AF          xor  a
9D92: 32 85 0E    ld   ($E049),a
9D95: 32 84 0E    ld   ($E048),a
9D98: C9          ret
9D99: CD 8D D9    call $9DC9
9D9C: CD 0A D9    call $9DA0
9D9F: C9          ret
9DA0: 3A 85 0E    ld   a,($E049)
9DA3: 4F          ld   c,a
9DA4: 3A 84 0E    ld   a,($E048)
9DA7: 21 4A 9D    ld   hl,$D9A4
9DAA: CD 1A D9    call $9DB0
9DAD: 21 4A 9C    ld   hl,$D8A4
9DB0: D9          exx
9DB1: 06 40       ld   b,$04
9DB3: D9          exx
9DB4: 06 80       ld   b,$08
9DB6: 77          ld   (hl),a
9DB7: CB D4       set  2,h
9DB9: 71          ld   (hl),c
9DBA: CB 94       res  2,h
9DBC: 3C          inc  a
9DBD: 2C          inc  l
9DBE: 10 7E       djnz $9DB6
9DC0: 11 9C FF    ld   de,$FFD8
9DC3: 19          add  hl,de
9DC4: D9          exx
9DC5: 10 CE       djnz $9DB3
9DC7: D9          exx
9DC8: C9          ret
9DC9: CD 3D D9    call $9DD3
9DCC: CD 3F D9    call $9DF3
9DCF: CD 50 F8    call $9E14
9DD2: C9          ret
9DD3: 3A 80 0E    ld   a,($E008)
9DD6: E6 61       and  $07
9DD8: FE 21       cp   $03
9DDA: 28 E1       jr   z,$9DEB
9DDC: 3A 81 0E    ld   a,($E009)
9DDF: E6 61       and  $07
9DE1: FE 21       cp   $03
9DE3: C0          ret  nz
9DE4: 21 85 0E    ld   hl,$E049
9DE7: 7E          ld   a,(hl)
9DE8: 3C          inc  a
9DE9: 77          ld   (hl),a
9DEA: C9          ret
9DEB: 21 85 0E    ld   hl,$E049
9DEE: 7E          ld   a,(hl)
9DEF: D6 10       sub  $10
9DF1: 77          ld   (hl),a
9DF2: C9          ret
9DF3: 3A A1 0E    ld   a,($E00B)
9DF6: E6 61       and  $07
9DF8: FE 21       cp   $03
9DFA: 28 10       jr   z,$9E0C
9DFC: 3A A0 0E    ld   a,($E00A)
9DFF: E6 61       and  $07
9E01: FE 21       cp   $03
9E03: C0          ret  nz
9E04: 21 84 0E    ld   hl,$E048
9E07: 7E          ld   a,(hl)
9E08: C6 0E       add  a,$E0
9E0A: 77          ld   (hl),a
9E0B: C9          ret
9E0C: 21 84 0E    ld   hl,$E048
9E0F: 7E          ld   a,(hl)
9E10: C6 02       add  a,$20
9E12: 77          ld   (hl),a
9E13: C9          ret
9E14: 21 D1 3C    ld   hl,$D21D
9E17: 3A 85 0E    ld   a,($E049)
9E1A: 0E 01       ld   c,$01
9E1C: CD D8 D8    call $9C9C
9E1F: 21 BD 1C    ld   hl,$D0DB
9E22: 3A 84 0E    ld   a,($E048)
9E25: 0E 01       ld   c,$01
9E27: CD D8 D8    call $9C9C
9E2A: 21 AD 1C    ld   hl,$D0CB
9E2D: 3A 84 0E    ld   a,($E048)
9E30: C6 02       add  a,$20
9E32: 0E 01       ld   c,$01
9E34: C3 D8 D8    jp   $9C9C

9E37: 3A 90 0E    ld   a,($E018)
9E3A: A7          and  a
9E3B: C0          ret  nz
9E3C: CD B7 F8    call $9E7B
9E3F: CD 64 F8    call $9E46
9E42: CD F5 F8    call $9E5F
9E45: C9          ret

9E46: 21 33 0E    ld   hl,$E033
9E49: 3A 21 0E    ld   a,($E003)
9E4C: 07          rlca
9E4D: CB 16       rl   (hl)
9E4F: 7E          ld   a,(hl)
9E50: E6 61       and  $07
9E52: C8          ret  z
9E53: FE 21       cp   $03
9E55: C0          ret  nz
9E56: CD 1B 68    call $86B1
9E59: CD 4D F8    call $9EC5
9E5C: C3 ED F8    jp   $9ECF
9E5F: 21 52 0E    ld   hl,$E034
9E62: 3A 21 0E    ld   a,($E003)
9E65: 07          rlca
9E66: 07          rlca
9E67: CB 16       rl   (hl)
9E69: 7E          ld   a,(hl)
9E6A: E6 61       and  $07
9E6C: C8          ret  z
9E6D: FE 21       cp   $03
9E6F: C0          ret  nz
9E70: CD 1B 68    call $86B1
9E73: CD AC F8    call $9ECA
9E76: 0E 01       ld   c,$01
9E78: C3 7E F8    jp   $9EF6
9E7B: CD 09 F8    call $9E81
9E7E: C3 2B F8    jp   $9EA3
9E81: 21 53 0E    ld   hl,$E035
9E84: 11 B3 0E    ld   de,$E03B
9E87: 7E          ld   a,(hl)
9E88: A7          and  a
9E89: 28 C0       jr   z,$9E97
9E8B: 35          dec  (hl)
9E8C: 7E          ld   a,(hl)
9E8D: FE E1       cp   $0F
9E8F: 20 40       jr   nz,$9E95
9E91: EB          ex   de,hl
9E92: CB 8E       res  1,(hl)
9E94: EB          ex   de,hl
9E95: A7          and  a
9E96: C0          ret  nz
9E97: 2C          inc  l
9E98: 7E          ld   a,(hl)
9E99: A7          and  a
9E9A: C8          ret  z
9E9B: 35          dec  (hl)
9E9C: 2D          dec  l
9E9D: 36 F1       ld   (hl),$1F
9E9F: EB          ex   de,hl
9EA0: CB CE       set  1,(hl)
9EA2: C9          ret
9EA3: 21 73 0E    ld   hl,$E037
9EA6: 11 B3 0E    ld   de,$E03B
9EA9: 7E          ld   a,(hl)
9EAA: A7          and  a
9EAB: 28 C0       jr   z,$9EB9
9EAD: 35          dec  (hl)
9EAE: 7E          ld   a,(hl)
9EAF: FE E1       cp   $0F
9EB1: 20 40       jr   nz,$9EB7
9EB3: EB          ex   de,hl
9EB4: CB 86       res  0,(hl)
9EB6: EB          ex   de,hl
9EB7: A7          and  a
9EB8: C0          ret  nz
9EB9: 2C          inc  l
9EBA: 7E          ld   a,(hl)
9EBB: A7          and  a
9EBC: C8          ret  z
9EBD: 35          dec  (hl)
9EBE: 2D          dec  l
9EBF: 36 F1       ld   (hl),$1F
9EC1: EB          ex   de,hl
9EC2: CB C6       set  0,(hl)
9EC4: C9          ret
9EC5: 21 72 0E    ld   hl,$E036
9EC8: 34          inc  (hl)
9EC9: C9          ret
9ECA: 21 92 0E    ld   hl,$E038
9ECD: 34          inc  (hl)
9ECE: C9          ret
9ECF: 3A 22 0E    ld   a,($E022)
9ED2: 47          ld   b,a
9ED3: 21 13 0E    ld   hl,$E031
9ED6: 34          inc  (hl)
9ED7: 7E          ld   a,(hl)
9ED8: B8          cp   b
9ED9: D8          ret  c
9EDA: 36 00       ld   (hl),$00
9EDC: 3A 02 0E    ld   a,($E020)
9EDF: 4F          ld   c,a
9EE0: 3A 12 0E    ld   a,($E030)
9EE3: FE 99       cp   $99
9EE5: D0          ret  nc
9EE6: 81          add  a,c
9EE7: 27          daa
9EE8: 32 12 0E    ld   ($E030),a
9EEB: 3A 00 0E    ld   a,($E000)
9EEE: FE 21       cp   $03
9EF0: C8          ret  z
9EF1: 16 40       ld   d,$04
9EF3: C3 92 00    jp   $0038
9EF6: 3A 23 0E    ld   a,($E023)
9EF9: 47          ld   b,a
9EFA: 21 32 0E    ld   hl,$E032
9EFD: 34          inc  (hl)
9EFE: 7E          ld   a,(hl)
9EFF: B8          cp   b
9F00: D8          ret  c
9F01: 36 00       ld   (hl),$00
9F03: 3A 03 0E    ld   a,($E021)
9F06: 4F          ld   c,a
9F07: 18 7D       jr   $9EE0
9F09: AF          xor  a
9F0A: 32 26 0E    ld   ($E062),a
9F0D: 3A F9 0E    ld   a,($E09F)
9F10: A7          and  a
9F11: C0          ret  nz
9F12: 21 99 2B    ld   hl,$A399
9F15: E5          push hl
9F16: 21 90 2B    ld   hl,$A318
9F19: E5          push hl
9F1A: 2A 75 0E    ld   hl,($E057)
9F1D: 7D          ld   a,l
9F1E: B4          or   h
9F1F: C8          ret  z
9F20: DD 21 00 EF ld   ix,$EF00
9F24: DD 56 01    ld   d,(ix+$01)
9F27: DD 5E 20    ld   e,(ix+$02)
9F2A: 19          add  hl,de
9F2B: DD 74 01    ld   (ix+$01),h
9F2E: DD 75 20    ld   (ix+$02),l
9F31: 3A D4 0E    ld   a,($E05C)
9F34: 57          ld   d,a
9F35: 7C          ld   a,h
9F36: 32 D4 0E    ld   ($E05C),a
9F39: 32 2A CF    ld   ($EDA2),a
9F3C: 7D          ld   a,l
9F3D: 32 D5 0E    ld   ($E05D),a
9F40: DD 7E 00    ld   a,(ix+$00)
9F43: CE 00       adc  a,$00
9F45: DD 77 00    ld   (ix+$00),a
9F48: 32 B5 0E    ld   ($E05B),a
9F4B: 32 2B CF    ld   ($EDA3),a
9F4E: 6F          ld   l,a
9F4F: 7C          ld   a,h
9F50: 92          sub  d
9F51: 32 26 0E    ld   ($E062),a
9F54: A7          and  a
9F55: C8          ret  z
9F56: DD 34 30    inc  (ix+$12)
9F59: DD 7E 30    ld   a,(ix+$12)
9F5C: E6 E1       and  $0F
9F5E: 20 31       jr   nz,$9F73
9F60: DD 66 10    ld   h,(ix+$10)
9F63: DD 6E 11    ld   l,(ix+$11)
9F66: 11 02 00    ld   de,$0020
9F69: 19          add  hl,de
9F6A: DD 75 11    ld   (ix+$11),l
9F6D: 7C          ld   a,h
9F6E: E6 BF       and  $FB
9F70: DD 77 10    ld   (ix+$10),a
9F73: 3A B5 0E    ld   a,($E05B)
9F76: 21 D5 1C    ld   hl,$D05D
9F79: 0E 00       ld   c,$00
9F7B: 3A D4 0E    ld   a,($E05C)
9F7E: 21 D9 1C    ld   hl,$D09D
9F81: DD 7E 01    ld   a,(ix+$01)
9F84: E6 F3       and  $3F
9F86: C0          ret  nz
9F87: 16 60       ld   d,$06
9F89: FF          rst  $38
9F8A: C9          ret
9F8B: CD 7D F9    call $9FD7
9F8E: DD 21 00 EF ld   ix,$EF00
9F92: CD DB 6A    call $A6BD
9F95: CD 70 6B    call $A716
9F98: CD 95 6B    call $A759
9F9B: DD 35 31    dec  (ix+$13)
9F9E: C0          ret  nz
9F9F: CD B5 6A    call $A65B
9FA2: DD 35 41    dec  (ix+$05)
9FA5: C0          ret  nz
9FA6: C3 16 4B    jp   $A570
9FA9: 21 3F 0E    ld   hl,$E0F3
9FAC: 7E          ld   a,(hl)
9FAD: A7          and  a
9FAE: 28 01       jr   z,$9FB1
9FB0: 35          dec  (hl)
9FB1: 21 7E 0E    ld   hl,$E0F6
9FB4: 7E          ld   a,(hl)
9FB5: A7          and  a
9FB6: 28 01       jr   z,$9FB9
9FB8: 35          dec  (hl)
9FB9: 3A 20 0E    ld   a,($E002)
9FBC: E6 01       and  $01
9FBE: C0          ret  nz
9FBF: 21 9E 0E    ld   hl,$E0F8
9FC2: 7E          ld   a,(hl)
9FC3: A7          and  a
9FC4: 28 01       jr   z,$9FC7
9FC6: 35          dec  (hl)
9FC7: C9          ret
9FC8: C9          ret
9FC9: 21 BF 0E    ld   hl,$E0FB
9FCC: 34          inc  (hl)
9FCD: 7E          ld   a,(hl)
9FCE: FE 12       cp   $30
9FD0: 38 70       jr   c,$9FE8
9FD2: 36 E2       ld   (hl),$2E
9FD4: C3 8E F9    jp   $9FE8
9FD7: 3A B5 0E    ld   a,($E05B)
9FDA: 32 BF 0E    ld   ($E0FB),a
9FDD: 11 A5 0A    ld   de,$A04B
9FE0: CB 77       bit  6,a
9FE2: 28 21       jr   z,$9FE7
9FE4: 11 A9 0B    ld   de,$A18B
9FE7: D5          push de
9FE8: E6 F1       and  $1F
9FEA: 6F          ld   l,a
9FEB: 26 00       ld   h,$00
9FED: 29          add  hl,hl
9FEE: 54          ld   d,h
9FEF: 5D          ld   e,l
9FF0: 29          add  hl,hl
9FF1: 29          add  hl,hl
9FF2: 19          add  hl,de
9FF3: D1          pop  de
9FF4: 19          add  hl,de
9FF5: 0E 00       ld   c,$00
9FF7: 3A C2 0E    ld   a,($E02C)
9FFA: A7          and  a
9FFB: 28 20       jr   z,$9FFF
9FFD: 0E 01       ld   c,$01
9FFF: 7E          ld   a,(hl)
A000: 23          inc  hl
A001: 32 1E 0E    ld   ($E0F0),a
A004: 7E          ld   a,(hl)
A005: 23          inc  hl
A006: 32 1F 0E    ld   ($E0F1),a
A009: 7E          ld   a,(hl)
A00A: 23          inc  hl
A00B: 32 3E 0E    ld   ($E0F2),a
A00E: 32 3F 0E    ld   ($E0F3),a
A011: 7E          ld   a,(hl)
A012: 23          inc  hl
A013: 32 5E 0E    ld   ($E0F4),a
A016: 7E          ld   a,(hl)
A017: 23          inc  hl
A018: 32 5F 0E    ld   ($E0F5),a
A01B: 32 7E 0E    ld   ($E0F6),a
A01E: 7E          ld   a,(hl)
A01F: 23          inc  hl
A020: 32 7F 0E    ld   ($E0F7),a
A023: 32 9E 0E    ld   ($E0F8),a
A026: 7E          ld   a,(hl)
A027: 23          inc  hl
A028: 81          add  a,c
A029: 32 9F 0E    ld   ($E0F9),a
A02C: 7E          ld   a,(hl)
A02D: 23          inc  hl
A02E: 32 BE 0E    ld   ($E0FA),a
A031: 3A D4 0E    ld   a,($E05C)
A034: A7          and  a
A035: C0          ret  nz
A036: 7E          ld   a,(hl)
A037: 23          inc  hl
A038: 32 BA 0E    ld   ($E0BA),a
A03B: 7E          ld   a,(hl)
A03C: 47          ld   b,a
A03D: E6 E1       and  $0F
A03F: 23          inc  hl
A040: 32 BB 0E    ld   ($E0BB),a
A043: 78          ld   a,b
A044: 07          rlca
A045: E6 01       and  $01
A047: 32 DE 0E    ld   ($E0FC),a
A04A: C9          ret
A04B: 21 82 D2    ld   hl,$3C28
A04E: 21 C3 1E    ld   hl,$F02D
A051: 01 00 00    ld   bc,$0000
A054: 00          nop
A055: 40          ld   b,b
A056: 12          ld   (de),a
A057: B2          or   d
A058: 40          ld   b,b
A059: C3 1E 20    jp   $02F0
A05C: 00          nop
A05D: 01 00 41    ld   bc,$0500
A060: 82          add  a,d
A061: 32 40 E2    ld   ($2E04),a
A064: 1E 20       ld   e,$02
A066: 00          nop
A067: 20 00       jr   nz,$A069
A069: 41          ld   b,c
A06A: 82          add  a,d
A06B: 32 60 E2    ld   ($2E06),a
A06E: 1E 20       ld   e,$02
A070: 00          nop
A071: 21 00 40    ld   hl,$0400
A074: 82          add  a,d
A075: C3 60 23    jp   $2306
A078: 1E 20       ld   e,$02
A07A: 01 40 00    ld   bc,$0004
A07D: 41          ld   b,c
A07E: 82          add  a,d
A07F: 82          add  a,d
A080: 60          ld   h,b
A081: 03          inc  bc
A082: 1E 20       ld   e,$02
A084: 00          nop
A085: 41          ld   b,c
A086: 00          nop
A087: 40          ld   b,b
A088: 42          ld   b,d
A089: 62          ld   h,d
A08A: 60          ld   h,b
A08B: F0          ret  p
A08C: 1E 20       ld   e,$02
A08E: 01 60 00    ld   bc,$0006
A091: 41          ld   b,c
A092: 42          ld   b,d
A093: F0          ret  p
A094: 60          ld   h,b
A095: 90          sub  b
A096: 1E 20       ld   e,$02
A098: 00          nop
A099: 61          ld   h,c
A09A: 08          ex   af,af'
A09B: 61          ld   h,c
A09C: 42          ld   b,d
A09D: D0          ret  nc
A09E: 40          ld   b,b
A09F: 91          sub  c
A0A0: 3C          inc  a
A0A1: 20 00       jr   nz,$A0A3
A0A3: 00          nop
A0A4: 00          nop
A0A5: 80          add  a,b
A0A6: 42          ld   b,d
A0A7: 50          ld   d,b
A0A8: 41          ld   b,c
A0A9: 91          sub  c
A0AA: 3C          inc  a
A0AB: 20 00       jr   nz,$A0AD
A0AD: 00          nop
A0AE: 00          nop
A0AF: 80          add  a,b
A0B0: 42          ld   b,d
A0B1: 50          ld   d,b
A0B2: 41          ld   b,c
A0B3: 91          sub  c
A0B4: 3C          inc  a
A0B5: 20 01       jr   nz,$A0B8
A0B7: 00          nop
A0B8: 00          nop
A0B9: 80          add  a,b
A0BA: 42          ld   b,d
A0BB: 50          ld   d,b
A0BC: 60          ld   h,b
A0BD: F0          ret  p
A0BE: 3C          inc  a
A0BF: 20 00       jr   nz,$A0C1
A0C1: 00          nop
A0C2: 00          nop
A0C3: 41          ld   b,c
A0C4: 82          add  a,d
A0C5: 91          sub  c
A0C6: 21 B1 3C    ld   hl,$D21B
A0C9: 20 20       jr   nz,$A0CD
A0CB: 00          nop
A0CC: 08          ex   af,af'
A0CD: 41          ld   b,c
A0CE: 42          ld   b,d
A0CF: F0          ret  p
A0D0: 40          ld   b,b
A0D1: B1          or   c
A0D2: 3C          inc  a
A0D3: 20 00       jr   nz,$A0D5
A0D5: 00          nop
A0D6: 00          nop
A0D7: 41          ld   b,c
A0D8: 22 91 21    ld   ($0319),hl
A0DB: B1          or   c
A0DC: 3C          inc  a
A0DD: 20 00       jr   nz,$A0DF
A0DF: 00          nop
A0E0: 00          nop
A0E1: 41          ld   b,c
A0E2: 22 F0 41    ld   ($051E),hl
A0E5: 50          ld   d,b
A0E6: 1E 20       ld   e,$02
A0E8: 00          nop
A0E9: 00          nop
A0EA: 08          ex   af,af'
A0EB: 40          ld   b,b
A0EC: 42          ld   b,d
A0ED: 91          sub  c
A0EE: 41          ld   b,c
A0EF: 90          sub  b
A0F0: 5A          ld   e,d
A0F1: 20 01       jr   nz,$A0F4
A0F3: 00          nop
A0F4: 00          nop
A0F5: 41          ld   b,c
A0F6: 22 91 41    ld   ($0519),hl
A0F9: 50          ld   d,b
A0FA: 5A          ld   e,d
A0FB: 20 01       jr   nz,$A0FE
A0FD: 00          nop
A0FE: 08          ex   af,af'
A0FF: 40          ld   b,b
A100: 42          ld   b,d
A101: 50          ld   d,b
A102: 41          ld   b,c
A103: 50          ld   d,b
A104: 5A          ld   e,d
A105: 20 01       jr   nz,$A108
A107: 00          nop
A108: 08          ex   af,af'
A109: 61          ld   h,c
A10A: 22 50 41    ld   ($0514),hl
A10D: E0          ret  po
A10E: 5A          ld   e,d
A10F: 20 00       jr   nz,$A111
A111: 00          nop
A112: 00          nop
A113: 40          ld   b,b
A114: 82          add  a,d
A115: 50          ld   d,b
A116: 40          ld   b,b
A117: B0          or   b
A118: 1E 20       ld   e,$02
A11A: 01 00 00    ld   bc,$0000
A11D: 80          add  a,b
A11E: 22 50 21    ld   ($0314),hl
A121: 50          ld   d,b
A122: 1E 20       ld   e,$02
A124: 00          nop
A125: 00          nop
A126: 00          nop
A127: 80          add  a,b
A128: 02          ld   (bc),a
A129: 30 21       jr   nc,$A12E
A12B: 50          ld   d,b
A12C: 1E 20       ld   e,$02
A12E: 00          nop
A12F: 00          nop
A130: 00          nop
A131: 60          ld   h,b
A132: 02          ld   (bc),a
A133: 30 60       jr   nc,$A13B
A135: F0          ret  p
A136: 1E 20       ld   e,$02
A138: 00          nop
A139: 00          nop
A13A: 08          ex   af,af'
A13B: 21 02 10    ld   hl,$1020
A13E: 60          ld   h,b
A13F: 62          ld   h,d
A140: 1E 20       ld   e,$02
A142: 20 00       jr   nz,$A144
A144: 00          nop
A145: 40          ld   b,b
A146: 02          ld   (bc),a
A147: E1          pop  hl
A148: 60          ld   h,b
A149: 62          ld   h,d
A14A: 1E 20       ld   e,$02
A14C: 20 00       jr   nz,$A14E
A14E: 00          nop
A14F: 61          ld   h,c
A150: 02          ld   (bc),a
A151: E0          ret  po
A152: 40          ld   b,b
A153: 50          ld   d,b
A154: 1E 20       ld   e,$02
A156: 00          nop
A157: 00          nop
A158: 00          nop
A159: 60          ld   h,b
A15A: 02          ld   (bc),a
A15B: E0          ret  po
A15C: 40          ld   b,b
A15D: 31 1E 20    ld   sp,$02F0
A160: 01 00 00    ld   bc,$0000
A163: 61          ld   h,c
A164: 02          ld   (bc),a
A165: E0          ret  po
A166: 40          ld   b,b
A167: 30 1E       jr   nc,$A159
A169: 20 00       jr   nz,$A16B
A16B: 00          nop
A16C: 00          nop
A16D: 80          add  a,b
A16E: 02          ld   (bc),a
A16F: E0          ret  po
A170: 21 10 1E    ld   hl,$F010
A173: 20 20       jr   nz,$A177
A175: 00          nop
A176: 08          ex   af,af'
A177: 80          add  a,b
A178: 02          ld   (bc),a
A179: E0          ret  po
A17A: 40          ld   b,b
A17B: 50          ld   d,b
A17C: 1E 20       ld   e,$02
A17E: 00          nop
A17F: 00          nop
A180: 00          nop
A181: 80          add  a,b
A182: 02          ld   (bc),a
A183: E0          ret  po
A184: 60          ld   h,b
A185: F0          ret  p
A186: 1E 20       ld   e,$02
A188: 01 00 08    ld   bc,$8000
A18B: 40          ld   b,b
A18C: 42          ld   b,d
A18D: E0          ret  po
A18E: 61          ld   h,c
A18F: B0          or   b
A190: 1E 20       ld   e,$02
A192: 00          nop
A193: 00          nop
A194: 00          nop
A195: 40          ld   b,b
A196: 42          ld   b,d
A197: E0          ret  po
A198: 61          ld   h,c
A199: B0          or   b
A19A: 1E 20       ld   e,$02
A19C: 00          nop
A19D: 00          nop
A19E: 00          nop
A19F: 41          ld   b,c
A1A0: 42          ld   b,d
A1A1: E0          ret  po
A1A2: 60          ld   h,b
A1A3: B0          or   b
A1A4: 1E 20       ld   e,$02
A1A6: 00          nop
A1A7: 00          nop
A1A8: 00          nop
A1A9: 41          ld   b,c
A1AA: 42          ld   b,d
A1AB: E0          ret  po
A1AC: 41          ld   b,c
A1AD: B0          or   b
A1AE: 1E 20       ld   e,$02
A1B0: 01 00 00    ld   bc,$0000
A1B3: 41          ld   b,c
A1B4: 42          ld   b,d
A1B5: E0          ret  po
A1B6: 40          ld   b,b
A1B7: B0          or   b
A1B8: 1E 20       ld   e,$02
A1BA: 01 00 00    ld   bc,$0000
A1BD: 41          ld   b,c
A1BE: 42          ld   b,d
A1BF: E0          ret  po
A1C0: 40          ld   b,b
A1C1: B0          or   b
A1C2: 1E 20       ld   e,$02
A1C4: 01 00 00    ld   bc,$0000
A1C7: 61          ld   h,c
A1C8: 42          ld   b,d
A1C9: E0          ret  po
A1CA: 21 B0 1E    ld   hl,$F01A
A1CD: 20 20       jr   nz,$A1D1
A1CF: 00          nop
A1D0: 00          nop
A1D1: 60          ld   h,b
A1D2: 42          ld   b,d
A1D3: E0          ret  po
A1D4: 60          ld   h,b
A1D5: B0          or   b
A1D6: 1E 20       ld   e,$02
A1D8: 01 00 08    ld   bc,$8000
A1DB: 40          ld   b,b
A1DC: 42          ld   b,d
A1DD: E0          ret  po
A1DE: 40          ld   b,b
A1DF: 90          sub  b
A1E0: 1E 20       ld   e,$02
A1E2: 01 00 00    ld   bc,$0000
A1E5: 40          ld   b,b
A1E6: 42          ld   b,d
A1E7: E0          ret  po
A1E8: 40          ld   b,b
A1E9: 90          sub  b
A1EA: 1E 20       ld   e,$02
A1EC: 01 00 00    ld   bc,$0000
A1EF: 80          add  a,b
A1F0: 42          ld   b,d
A1F1: E0          ret  po
A1F2: 21 90 1E    ld   hl,$F018
A1F5: 20 20       jr   nz,$A1F9
A1F7: 00          nop
A1F8: 08          ex   af,af'
A1F9: 80          add  a,b
A1FA: 42          ld   b,d
A1FB: E0          ret  po
A1FC: 40          ld   b,b
A1FD: 90          sub  b
A1FE: 1E 20       ld   e,$02
A200: 00          nop
A201: 00          nop
A202: 00          nop
A203: 60          ld   h,b
A204: 42          ld   b,d
A205: E0          ret  po
A206: 41          ld   b,c
A207: 90          sub  b
A208: 1E 20       ld   e,$02
A20A: 20 00       jr   nz,$A20C
A20C: 00          nop
A20D: 60          ld   h,b
A20E: 42          ld   b,d
A20F: E0          ret  po
A210: 40          ld   b,b
A211: 90          sub  b
A212: 1E 20       ld   e,$02
A214: 20 00       jr   nz,$A216
A216: 00          nop
A217: 60          ld   h,b
A218: 42          ld   b,d
A219: E0          ret  po
A21A: 41          ld   b,c
A21B: 90          sub  b
A21C: 1E 20       ld   e,$02
A21E: 20 00       jr   nz,$A220
A220: 00          nop
A221: 61          ld   h,c
A222: 42          ld   b,d
A223: E0          ret  po
A224: 60          ld   h,b
A225: 90          sub  b
A226: 1E 20       ld   e,$02
A228: 00          nop
A229: 00          nop
A22A: 08          ex   af,af'
A22B: 40          ld   b,b
A22C: 42          ld   b,d
A22D: E0          ret  po
A22E: 60          ld   h,b
A22F: 71          ld   (hl),c
A230: 1E 20       ld   e,$02
A232: 01 00 00    ld   bc,$0000
A235: 40          ld   b,b
A236: 42          ld   b,d
A237: E0          ret  po
A238: 41          ld   b,c
A239: 71          ld   (hl),c
A23A: 1E 20       ld   e,$02
A23C: 01 00 08    ld   bc,$8000
A23F: 40          ld   b,b
A240: 42          ld   b,d
A241: E0          ret  po
A242: 41          ld   b,c
A243: 71          ld   (hl),c
A244: 1E 20       ld   e,$02
A246: 01 00 08    ld   bc,$8000
A249: 40          ld   b,b
A24A: 42          ld   b,d
A24B: E0          ret  po
A24C: 60          ld   h,b
A24D: 71          ld   (hl),c
A24E: 1E 20       ld   e,$02
A250: 01 00 00    ld   bc,$0000
A253: 60          ld   h,b
A254: 42          ld   b,d
A255: E0          ret  po
A256: 40          ld   b,b
A257: 71          ld   (hl),c
A258: 1E 20       ld   e,$02
A25A: 20 00       jr   nz,$A25C
A25C: 00          nop
A25D: 60          ld   h,b
A25E: 42          ld   b,d
A25F: E0          ret  po
A260: 40          ld   b,b
A261: 71          ld   (hl),c
A262: 1E 20       ld   e,$02
A264: 20 00       jr   nz,$A266
A266: 00          nop
A267: 80          add  a,b
A268: 42          ld   b,d
A269: E0          ret  po
A26A: 21 71 1E    ld   hl,$F017
A26D: 20 20       jr   nz,$A271
A26F: 00          nop
A270: 00          nop
A271: 61          ld   h,c
A272: 42          ld   b,d
A273: E0          ret  po
A274: 60          ld   h,b
A275: 71          ld   (hl),c
A276: 1E 20       ld   e,$02
A278: 00          nop
A279: 00          nop
A27A: 08          ex   af,af'
A27B: 61          ld   h,c
A27C: 42          ld   b,d
A27D: E0          ret  po
A27E: 40          ld   b,b
A27F: 70          ld   (hl),b
A280: 1E 20       ld   e,$02
A282: 20 00       jr   nz,$A284
A284: 08          ex   af,af'
A285: 80          add  a,b
A286: 42          ld   b,d
A287: E0          ret  po
A288: 40          ld   b,b
A289: 70          ld   (hl),b
A28A: 1E 20       ld   e,$02
A28C: 20 00       jr   nz,$A28E
A28E: 08          ex   af,af'
A28F: 61          ld   h,c
A290: 42          ld   b,d
A291: E0          ret  po
A292: 40          ld   b,b
A293: 70          ld   (hl),b
A294: 1E 20       ld   e,$02
A296: 20 00       jr   nz,$A298
A298: 00          nop
A299: 41          ld   b,c
A29A: 42          ld   b,d
A29B: E0          ret  po
A29C: 41          ld   b,c
A29D: 70          ld   (hl),b
A29E: 1E 20       ld   e,$02
A2A0: 01 00 00    ld   bc,$0000
A2A3: 61          ld   h,c
A2A4: 42          ld   b,d
A2A5: E0          ret  po
A2A6: 40          ld   b,b
A2A7: 70          ld   (hl),b
A2A8: 1E 20       ld   e,$02
A2AA: 20 00       jr   nz,$A2AC
A2AC: 08          ex   af,af'
A2AD: 61          ld   h,c
A2AE: 42          ld   b,d
A2AF: E0          ret  po
A2B0: 60          ld   h,b
A2B1: 70          ld   (hl),b
A2B2: 1E 20       ld   e,$02
A2B4: 00          nop
A2B5: 00          nop
A2B6: 00          nop
A2B7: 40          ld   b,b
A2B8: 42          ld   b,d
A2B9: E0          ret  po
A2BA: 40          ld   b,b
A2BB: 70          ld   (hl),b
A2BC: 1E 20       ld   e,$02
A2BE: 01 00 00    ld   bc,$0000
A2C1: 80          add  a,b
A2C2: 42          ld   b,d
A2C3: E0          ret  po
A2C4: 60          ld   h,b
A2C5: 70          ld   (hl),b
A2C6: 1E 20       ld   e,$02
A2C8: 00          nop
A2C9: 00          nop
A2CA: 08          ex   af,af'
A2CB: 01 20 40    ld   bc,$0402
A2CE: 00          nop
A2CF: 3A 37 0F    ld   a,($E173)
A2D2: E6 21       and  $03
A2D4: 21 AD 2A    ld   hl,$A2CB
A2D7: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
A2D8: 21 A8 0E    ld   hl,$E08A
A2DB: 86          add  a,(hl)
A2DC: 77          ld   (hl),a
A2DD: 7E          ld   a,(hl)
A2DE: 0F          rrca
A2DF: 0F          rrca
A2E0: 0F          rrca
A2E1: 0F          rrca
A2E2: E6 21       and  $03
A2E4: 21 50 2B    ld   hl,$A314
A2E7: DF          rst  $18                   ; call ADD_A_TO_HL
A2E8: 4E          ld   c,(hl)
A2E9: DD 21 00 8E ld   ix,$E800
A2ED: FD 21 CA FE ld   iy,$FEAC
A2F1: 11 10 00    ld   de,$0010
A2F4: 06 C0       ld   b,$0C
A2F6: DD 7E 00    ld   a,(ix+$00)
A2F9: A7          and  a
A2FA: 28 11       jr   z,$A30D
A2FC: 79          ld   a,c
A2FD: FD 77 80    ld   (iy+$08),a
A300: 3C          inc  a
A301: FD 77 C0    ld   (iy+$0c),a
A304: C6 61       add  a,$07
A306: FD 77 00    ld   (iy+$00),a
A309: 3C          inc  a
A30A: FD 77 40    ld   (iy+$04),a
A30D: DD 19       add  ix,de
A30F: FD 19       add  iy,de
A311: 10 2F       djnz $A2F6
A313: C9          ret
A314: 20 10       jr   nz,$A326
A316: 30 10       jr   nc,$A328
A318: FD 2A F4 0E ld   iy,($E05E)
A31C: 3A B5 0E    ld   a,($E05B)
A31F: 67          ld   h,a
A320: 3A D4 0E    ld   a,($E05C)
A323: 6F          ld   l,a
A324: FD 7E 21    ld   a,(iy+$03)
A327: FE FF       cp   $FF
A329: C8          ret  z
A32A: 57          ld   d,a
A32B: FD 7E 20    ld   a,(iy+$02)
A32E: 47          ld   b,a
A32F: E6 1E       and  $F0
A331: 5F          ld   e,a
A332: EB          ex   de,hl
A333: ED 52       sbc  hl,de
A335: 7C          ld   a,h
A336: A7          and  a
A337: 28 A0       jr   z,$A343
A339: CB 7F       bit  7,a
A33B: C8          ret  z
A33C: 11 40 00    ld   de,$0004
A33F: FD 19       add  iy,de
A341: 18 9D       jr   $A31C
A343: 78          ld   a,b
A344: E6 61       and  $07
A346: 57          ld   d,a
A347: 78          ld   a,b
A348: E6 80       and  $08
A34A: C6 1A       add  a,$B0
A34C: 4F          ld   c,a
A34D: FD 66 00    ld   h,(iy+$00)
A350: FD 46 01    ld   b,(iy+$01)
A353: D9          exx
A354: 01 10 00    ld   bc,$0010
A357: DD 21 00 8E ld   ix,$E800
A35B: D9          exx
A35C: DD 7E 00    ld   a,(ix+$00)
A35F: A7          and  a
A360: 20 12       jr   nz,$A392
A362: DD 35 00    dec  (ix+$00)
A365: DD 74 21    ld   (ix+$03),h
A368: DD 36 40 00 ld   (ix+$04),$00
A36C: DD 75 41    ld   (ix+$05),l
A36F: DD 72 60    ld   (ix+$06),d
A372: DD 70 61    ld   (ix+$07),b
A375: DD 71 80    ld   (ix+$08),c
A378: 01 90 40    ld   bc,$0418
A37B: CB 42       bit  0,d
A37D: 28 21       jr   z,$A382
A37F: 01 43 C0    ld   bc,$0C25
A382: DD 70 81    ld   (ix+$09),b
A385: DD 71 A0    ld   (ix+$0a),c
A388: 11 40 00    ld   de,$0004
A38B: FD 19       add  iy,de
A38D: FD 22 F4 0E ld   ($E05E),iy
A391: C9          ret
A392: D9          exx
A393: DD 09       add  ix,bc
A395: D9          exx
A396: C3 D4 2B    jp   $A35C
A399: DD 21 00 8E ld   ix,$E800
A39D: FD 21 12 FE ld   iy,$FE30
A3A1: 3A 01 0E    ld   a,($E001)
A3A4: FE 41       cp   $05
A3A6: 38 40       jr   c,$A3AC
A3A8: FD 21 CA FE ld   iy,$FEAC
A3AC: D9          exx
A3AD: 0E 30       ld   c,$12
A3AF: 21 80 00    ld   hl,$0008
A3B2: 11 10 00    ld   de,$0010
A3B5: 06 81       ld   b,$09
A3B7: D9          exx
A3B8: DD 7E 00    ld   a,(ix+$00)
A3BB: A7          and  a
A3BC: 28 E2       jr   z,$A3EC
A3BE: 3C          inc  a
A3BF: 20 44       jr   nz,$A405
A3C1: 11 00 00    ld   de,$0000
A3C4: 3A 26 0E    ld   a,($E062)
A3C7: A7          and  a
A3C8: 28 21       jr   z,$A3CD
A3CA: 11 FF FF    ld   de,$FFFF
A3CD: DD 66 40    ld   h,(ix+$04)
A3D0: DD 6E 41    ld   l,(ix+$05)
A3D3: 19          add  hl,de
A3D4: DD 74 40    ld   (ix+$04),h
A3D7: DD 75 41    ld   (ix+$05),l
A3DA: 7C          ld   a,h
A3DB: A7          and  a
A3DC: 28 A1       jr   z,$A3E9
A3DE: 7D          ld   a,l
A3DF: FE 0E       cp   $E0
A3E1: 30 60       jr   nc,$A3E9
A3E3: DD 36 00 00 ld   (ix+$00),$00
A3E7: 18 21       jr   $A3EC
A3E9: CD 98 4A    call $A498
A3EC: D9          exx
A3ED: DD 19       add  ix,de
A3EF: 10 6C       djnz $A3B7
A3F1: 79          ld   a,c
A3F2: A7          and  a
A3F3: C8          ret  z
A3F4: 47          ld   b,a
A3F5: 11 80 00    ld   de,$0008
A3F8: FD 36 20 00 ld   (iy+$02),$00
A3FC: FD 36 60 00 ld   (iy+$06),$00
A400: FD 19       add  iy,de
A402: 10 5E       djnz $A3F8
A404: C9          ret
A405: 21 CE 2B    ld   hl,$A3EC
A408: E5          push hl
A409: DD 7E 00    ld   a,(ix+$00)
A40C: FE F3       cp   $3F
A40E: D2 49 4A    jp   nc,$A485
A411: DD 35 00    dec  (ix+$00)
A414: CA 19 4A    jp   z,$A491
A417: 11 D7 4A    ld   de,$A47D
A41A: 0E 50       ld   c,$14
A41C: DD 7E 00    ld   a,(ix+$00)
A41F: FE 80       cp   $08
A421: 30 41       jr   nc,$A428
A423: 11 09 4A    ld   de,$A481
A426: 0E 51       ld   c,$15
A428: FD 71 00    ld   (iy+$00),c
A42B: FD 71 40    ld   (iy+$04),c
A42E: 79          ld   a,c
A42F: C6 61       add  a,$07
A431: FD 77 80    ld   (iy+$08),a
A434: FD 77 C0    ld   (iy+$0c),a
A437: FD 36 01 1A ld   (iy+$01),$B0
A43B: FD 36 41 9A ld   (iy+$05),$B8
A43F: FD 36 81 1A ld   (iy+$09),$B0
A443: FD 36 C1 9A ld   (iy+$0d),$B8
A447: 3A 26 0E    ld   a,($E062)
A44A: A7          and  a
A44B: 28 21       jr   z,$A450
A44D: DD 35 41    dec  (ix+$05)
A450: DD 66 21    ld   h,(ix+$03)
A453: DD 6E 41    ld   l,(ix+$05)
A456: 1A          ld   a,(de)
A457: 13          inc  de
A458: 84          add  a,h
A459: FD 77 20    ld   (iy+$02),a
A45C: FD 77 A0    ld   (iy+$0a),a
A45F: 1A          ld   a,(de)
A460: 13          inc  de
A461: 85          add  a,l
A462: FD 77 21    ld   (iy+$03),a
A465: FD 77 61    ld   (iy+$07),a
A468: 1A          ld   a,(de)
A469: 13          inc  de
A46A: 84          add  a,h
A46B: FD 77 60    ld   (iy+$06),a
A46E: FD 77 E0    ld   (iy+$0e),a
A471: 1A          ld   a,(de)
A472: 13          inc  de
A473: 85          add  a,l
A474: FD 77 A1    ld   (iy+$0b),a
A477: FD 77 E1    ld   (iy+$0f),a
A47A: C3 30 4B    jp   $A512
A47D: 9F          sbc  a,a
A47E: 31 71 FE    ld   sp,$FE17
A481: 3E 50       ld   a,$14
A483: F0          ret  p
A484: BF          cp   a
A485: DD 36 00 10 ld   (ix+$00),$10
A489: 16 41       ld   d,$05
A48B: 1E 20       ld   e,$02
A48D: FF          rst  $38
A48E: C3 30 4B    jp   $A512
A491: DD 36 00 00 ld   (ix+$00),$00
A495: C3 30 4B    jp   $A512
A498: DD 7E 60    ld   a,(ix+$06)
A49B: FE 01       cp   $01
A49D: 38 41       jr   c,$A4A4
A49F: CA 23 4B    jp   z,$A523
A4A2: 18 F7       jr   $A523
A4A4: DD CB 80 F4 bit  3,(ix+$08)
A4A8: 28 31       jr   z,$A4BD
A4AA: DD 7E 21    ld   a,(ix+$03)
A4AD: FD 77 60    ld   (iy+$06),a
A4B0: FD 77 E0    ld   (iy+$0e),a
A4B3: C6 10       add  a,$10
A4B5: FD 77 20    ld   (iy+$02),a
A4B8: FD 77 A0    ld   (iy+$0a),a
A4BB: 18 11       jr   $A4CE
A4BD: DD 7E 21    ld   a,(ix+$03)
A4C0: FD 77 20    ld   (iy+$02),a
A4C3: FD 77 A0    ld   (iy+$0a),a
A4C6: C6 10       add  a,$10
A4C8: FD 77 60    ld   (iy+$06),a
A4CB: FD 77 E0    ld   (iy+$0e),a
A4CE: DD 66 40    ld   h,(ix+$04)
A4D1: DD 6E 41    ld   l,(ix+$05)
A4D4: FD 75 21    ld   (iy+$03),l
A4D7: FD 75 61    ld   (iy+$07),l
A4DA: 7D          ld   a,l
A4DB: C6 10       add  a,$10
A4DD: FD 77 A1    ld   (iy+$0b),a
A4E0: FD 77 E1    ld   (iy+$0f),a
A4E3: DD 7E 61    ld   a,(ix+$07)
A4E6: FD 77 00    ld   (iy+$00),a
A4E9: 3C          inc  a
A4EA: FD 77 40    ld   (iy+$04),a
A4ED: C6 7F       add  a,$F7
A4EF: FD 77 80    ld   (iy+$08),a
A4F2: 3C          inc  a
A4F3: FD 77 C0    ld   (iy+$0c),a
A4F6: 7C          ld   a,h
A4F7: E6 01       and  $01
A4F9: DD 86 80    add  a,(ix+$08)
A4FC: FD 77 01    ld   (iy+$01),a
A4FF: FD 77 41    ld   (iy+$05),a
A502: 01 10 00    ld   bc,$0010
A505: 09          add  hl,bc
A506: 7C          ld   a,h
A507: E6 01       and  $01
A509: DD 86 80    add  a,(ix+$08)
A50C: FD 77 81    ld   (iy+$09),a
A50F: FD 77 C1    ld   (iy+$0d),a
A512: D9          exx
A513: EB          ex   de,hl
A514: FD 19       add  iy,de
A516: 0D          dec  c
A517: CA E6 4B    jp   z,$A56E
A51A: FD 19       add  iy,de
A51C: EB          ex   de,hl
A51D: 0D          dec  c
A51E: CA E6 4B    jp   z,$A56E
A521: D9          exx
A522: C9          ret
A523: DD CB 80 F4 bit  3,(ix+$08)
A527: 28 C1       jr   z,$A536
A529: DD 7E 21    ld   a,(ix+$03)
A52C: FD 77 60    ld   (iy+$06),a
A52F: C6 10       add  a,$10
A531: FD 77 20    ld   (iy+$02),a
A534: 18 A1       jr   $A541
A536: DD 7E 21    ld   a,(ix+$03)
A539: FD 77 20    ld   (iy+$02),a
A53C: C6 10       add  a,$10
A53E: FD 77 60    ld   (iy+$06),a
A541: DD 66 40    ld   h,(ix+$04)
A544: DD 6E 41    ld   l,(ix+$05)
A547: FD 75 21    ld   (iy+$03),l
A54A: FD 75 61    ld   (iy+$07),l
A54D: DD 7E 61    ld   a,(ix+$07)
A550: FD 77 00    ld   (iy+$00),a
A553: 3C          inc  a
A554: FD 77 40    ld   (iy+$04),a
A557: 7C          ld   a,h
A558: E6 01       and  $01
A55A: DD 86 80    add  a,(ix+$08)
A55D: FD 77 01    ld   (iy+$01),a
A560: FD 77 41    ld   (iy+$05),a
A563: D9          exx
A564: EB          ex   de,hl
A565: FD 19       add  iy,de
A567: EB          ex   de,hl
A568: 0D          dec  c
A569: CA E6 4B    jp   z,$A56E
A56C: D9          exx
A56D: C9          ret
A56E: E1          pop  hl
A56F: C9          ret
A570: 21 00 04    ld   hl,$4000
A573: 22 F4 0E    ld   ($E05E),hl
A576: 21 EA 17    ld   hl,$71AE
A579: 22 E9 0E    ld   ($E08F),hl
A57C: 21 1B EB    ld   hl,$AFB1
A57F: 22 78 0E    ld   ($E096),hl
A582: 21 00 00    ld   hl,$0000
A585: 22 2A CF    ld   ($EDA2),hl
A588: AF          xor  a
A589: 32 4A CF    ld   ($EDA4),a
A58C: 18 A6       jr   $A5F8
A58E: DD 21 EA 17 ld   ix,$71AE
A592: 01 60 00    ld   bc,$0006
A595: ED 5B 2A CF ld   de,($EDA2)
A599: DD 66 01    ld   h,(ix+$01)
A59C: DD 6E 00    ld   l,(ix+$00)
A59F: A7          and  a
A5A0: ED 52       sbc  hl,de
A5A2: 7C          ld   a,h
A5A3: A7          and  a
A5A4: 28 81       jr   z,$A5AF
A5A6: CB 7F       bit  7,a
A5A8: 28 41       jr   z,$A5AF
A5AA: DD 09       add  ix,bc
A5AC: C3 99 4B    jp   $A599
A5AF: DD 22 E9 0E ld   ($E08F),ix
A5B3: DD 21 00 04 ld   ix,$4000
A5B7: 01 40 00    ld   bc,$0004
A5BA: DD 66 21    ld   h,(ix+$03)
A5BD: DD 7E 20    ld   a,(ix+$02)
A5C0: E6 1E       and  $F0
A5C2: 6F          ld   l,a
A5C3: A7          and  a
A5C4: ED 52       sbc  hl,de
A5C6: 7C          ld   a,h
A5C7: A7          and  a
A5C8: 28 81       jr   z,$A5D3
A5CA: CB 7F       bit  7,a
A5CC: 28 41       jr   z,$A5D3
A5CE: DD 09       add  ix,bc
A5D0: C3 BA 4B    jp   $A5BA
A5D3: DD 22 F4 0E ld   ($E05E),ix
A5D7: DD 21 1B EB ld   ix,$AFB1
A5DB: 01 40 00    ld   bc,$0004
A5DE: DD 66 01    ld   h,(ix+$01)
A5E1: DD 6E 00    ld   l,(ix+$00)
A5E4: A7          and  a
A5E5: ED 52       sbc  hl,de
A5E7: 7C          ld   a,h
A5E8: A7          and  a
A5E9: 28 81       jr   z,$A5F4
A5EB: CB 7F       bit  7,a
A5ED: 28 41       jr   z,$A5F4
A5EF: DD 09       add  ix,bc
A5F1: C3 FC 4B    jp   $A5DE
A5F4: DD 22 78 0E ld   ($E096),ix
A5F8: 21 00 8E    ld   hl,$E800
A5FB: 11 80 00    ld   de,$0008
A5FE: 06 42       ld   b,$24
A600: 36 00       ld   (hl),$00
A602: 19          add  hl,de
A603: 10 BF       djnz $A600
A605: DD 21 00 EF ld   ix,$EF00
A609: 21 00 9E    ld   hl,$F800
A60C: DD 74 A0    ld   (ix+$0a),h
A60F: DD 75 A1    ld   (ix+$0b),l
A612: DD 74 10    ld   (ix+$10),h
A615: DD 75 11    ld   (ix+$11),l
A618: CD B5 6A    call $A65B
A61B: 11 00 9C    ld   de,$D800
A61E: 3A B5 0E    ld   a,($E05B)
A621: E6 01       and  $01
A623: 67          ld   h,a
A624: 3A D4 0E    ld   a,($E05C)
A627: 6F          ld   l,a
A628: 29          add  hl,hl
A629: 19          add  hl,de
A62A: DD 74 E0    ld   (ix+$0e),h
A62D: DD 75 E1    ld   (ix+$0f),l
A630: CD A9 F9    call $9F8B
A633: CD A9 F9    call $9F8B
A636: CD A9 F9    call $9F8B
A639: CD A9 F9    call $9F8B
A63C: CD A9 F9    call $9F8B
A63F: CD 90 2B    call $A318
A642: CD 90 2B    call $A318
A645: CD 90 2B    call $A318
A648: CD 90 2B    call $A318
A64B: CD 90 2B    call $A318
A64E: CD 90 2B    call $A318
A651: CD 90 2B    call $A318
A654: CD 90 2B    call $A318
A657: CD 99 2B    call $A399
A65A: C9          ret
A65B: 11 52 05    ld   de,$4134
A65E: 2A 2A CF    ld   hl,($EDA2)
A661: CB 74       bit  6,h
A663: 28 21       jr   z,$A668
A665: 11 56 25    ld   de,$4374
A668: 7D          ld   a,l
A669: 32 D4 0E    ld   ($E05C),a
A66C: DD 77 01    ld   (ix+$01),a
A66F: 7C          ld   a,h
A670: 32 B5 0E    ld   ($E05B),a
A673: DD 77 00    ld   (ix+$00),a
A676: 3E 00       ld   a,$00
A678: 32 D5 0E    ld   ($E05D),a
A67B: DD 77 20    ld   (ix+$02),a
A67E: DD 77 41    ld   (ix+$05),a
A681: 7C          ld   a,h
A682: E6 F3       and  $3F
A684: 67          ld   h,a
A685: CB 3C       srl  h
A687: CB 1D       rr   l
A689: CB 3C       srl  h
A68B: CB 1D       rr   l
A68D: CB 3C       srl  h
A68F: CB 1D       rr   l
A691: CB 3C       srl  h
A693: CB 1D       rr   l
A695: 19          add  hl,de
A696: DD 74 21    ld   (ix+$03),h
A699: DD 75 40    ld   (ix+$04),l
A69C: 21 06 1E    ld   hl,$F060
A69F: DD 74 60    ld   (ix+$06),h
A6A2: DD 75 61    ld   (ix+$07),l
A6A5: 21 00 1E    ld   hl,$F000
A6A8: DD 74 80    ld   (ix+$08),h
A6AB: DD 75 81    ld   (ix+$09),l
A6AE: DD 74 C0    ld   (ix+$0c),h
A6B1: DD 75 C1    ld   (ix+$0d),l
A6B4: DD 36 30 00 ld   (ix+$12),$00
A6B8: DD 36 31 1A ld   (ix+$13),$B0
A6BC: C9          ret
A6BD: 06 40       ld   b,$04
A6BF: D9          exx
A6C0: DD 66 21    ld   h,(ix+$03)
A6C3: DD 6E 40    ld   l,(ix+$04)
A6C6: 7E          ld   a,(hl)
A6C7: 23          inc  hl
A6C8: DD 74 21    ld   (ix+$03),h
A6CB: DD 75 40    ld   (ix+$04),l
A6CE: 6F          ld   l,a
A6CF: 26 00       ld   h,$00
A6D1: 29          add  hl,hl
A6D2: 29          add  hl,hl
A6D3: 29          add  hl,hl
A6D4: 29          add  hl,hl
A6D5: 29          add  hl,hl
A6D6: 11 4C 45    ld   de,$45C4
A6D9: 19          add  hl,de
A6DA: DD 56 60    ld   d,(ix+$06)
A6DD: DD 5E 61    ld   e,(ix+$07)
A6E0: 3E 40       ld   a,$04
A6E2: 08          ex   af,af'
A6E3: D5          push de
A6E4: 01 80 00    ld   bc,$0008
A6E7: ED B0       ldir
A6E9: D1          pop  de
A6EA: EB          ex   de,hl
A6EB: 3E 0E       ld   a,$E0
A6ED: 85          add  a,l
A6EE: 6F          ld   l,a
A6EF: EB          ex   de,hl
A6F0: 08          ex   af,af'
A6F1: 3D          dec  a
A6F2: 20 EE       jr   nz,$A6E2
A6F4: DD 66 60    ld   h,(ix+$06)
A6F7: DD 6E 61    ld   l,(ix+$07)
A6FA: 01 80 00    ld   bc,$0008
A6FD: 09          add  hl,bc
A6FE: DD 74 60    ld   (ix+$06),h
A701: DD 75 61    ld   (ix+$07),l
A704: D9          exx
A705: 10 9A       djnz $A6BF
A707: D9          exx
A708: 01 06 00    ld   bc,$0060
A70B: 09          add  hl,bc
A70C: 7C          ld   a,h
A70D: E6 3F       and  $F3
A70F: DD 77 60    ld   (ix+$06),a
A712: DD 75 61    ld   (ix+$07),l
A715: C9          ret
A716: DD 56 80    ld   d,(ix+$08)
A719: DD 5E 81    ld   e,(ix+$09)
A71C: D9          exx
A71D: DD 56 A0    ld   d,(ix+$0a)
A720: DD 5E A1    ld   e,(ix+$0b)
A723: 06 04       ld   b,$40
A725: D9          exx
A726: 1A          ld   a,(de)
A727: 13          inc  de
A728: 21 46 06    ld   hl,$6064
A72B: DF          rst  $18                   ; call ADD_A_TO_HL
A72C: 1A          ld   a,(de)
A72D: 4F          ld   c,a
A72E: 13          inc  de
A72F: 07          rlca
A730: 07          rlca
A731: E6 21       and  $03
A733: 84          add  a,h
A734: 67          ld   h,a
A735: 7E          ld   a,(hl)
A736: D9          exx
A737: 12          ld   (de),a
A738: 13          inc  de
A739: D9          exx
A73A: 79          ld   a,c
A73B: 07          rlca
A73C: 07          rlca
A73D: 07          rlca
A73E: E6 01       and  $01
A740: D9          exx
A741: 12          ld   (de),a
A742: 13          inc  de
A743: 10 0E       djnz $A725
A745: 7A          ld   a,d
A746: E6 BF       and  $FB
A748: DD 77 A0    ld   (ix+$0a),a
A74B: DD 73 A1    ld   (ix+$0b),e
A74E: D9          exx
A74F: 7A          ld   a,d
A750: E6 3F       and  $F3
A752: DD 77 80    ld   (ix+$08),a
A755: DD 73 81    ld   (ix+$09),e
A758: C9          ret
A759: 0E 40       ld   c,$04
A75B: DD 66 C0    ld   h,(ix+$0c)
A75E: DD 6E C1    ld   l,(ix+$0d)
A761: DD 56 E0    ld   d,(ix+$0e)
A764: DD 5E E1    ld   e,(ix+$0f)
A767: 06 10       ld   b,$10
A769: 7E          ld   a,(hl)
A76A: 12          ld   (de),a
A76B: 23          inc  hl
A76C: 7E          ld   a,(hl)
A76D: CB D2       set  2,d
A76F: 12          ld   (de),a
A770: CB 92       res  2,d
A772: 23          inc  hl
A773: 13          inc  de
A774: 10 3F       djnz $A769
A776: EB          ex   de,hl
A777: 3E 10       ld   a,$10
A779: DF          rst  $18                   ; call ADD_A_TO_HL
A77A: EB          ex   de,hl
A77B: 0D          dec  c
A77C: 20 8F       jr   nz,$A767
A77E: 7C          ld   a,h
A77F: E6 3F       and  $F3
A781: DD 77 C0    ld   (ix+$0c),a
A784: DD 75 C1    ld   (ix+$0d),l
A787: EB          ex   de,hl
A788: 7C          ld   a,h
A789: E6 BD       and  $DB
A78B: DD 77 E0    ld   (ix+$0e),a
A78E: DD 75 E1    ld   (ix+$0f),l
A791: C9          ret
A792: 21 00 9C    ld   hl,$D800
A795: 11 01 9C    ld   de,$D801
A798: 01 FF 21    ld   bc,$03FF
A79B: 36 9E       ld   (hl),$F8
A79D: ED B0       ldir
A79F: 01 00 40    ld   bc,$0400
A7A2: 36 00       ld   (hl),$00
A7A4: ED B0       ldir
A7A6: C9          ret
A7A7: 4C          ld   c,h
A7A8: 08          ex   af,af'
A7A9: 4D          ld   c,l
A7AA: 08          ex   af,af'
A7AB: AC          xor  h
A7AC: 08          ex   af,af'
A7AD: AD          xor  l
A7AE: 08          ex   af,af'
A7AF: CC 08 CD    call z,$CD80
A7B2: 08          ex   af,af'
A7B3: EC 08 3C    call pe,$D280
A7B6: 88          adc  a,b
A7B7: CD C8 CC    call $CC8C
A7BA: C8          ret  z
A7BB: AD          xor  l
A7BC: C8          ret  z
A7BD: AC          xor  h
A7BE: C8          ret  z
A7BF: 3D          dec  a
A7C0: 88          adc  a,b
A7C1: BC          cp   h
A7C2: 88          adc  a,b
A7C3: 9D          sbc  a,l
A7C4: 88          adc  a,b
A7C5: 9C          sbc  a,h
A7C6: 88          adc  a,b
A7C7: AC          xor  h
A7C8: 48          ld   c,b
A7C9: AD          xor  l
A7CA: 48          ld   c,b
A7CB: CC 48 CD    call z,$CD84
A7CE: 48          ld   c,b
A7CF: 3C          inc  a
A7D0: 08          ex   af,af'
A7D1: 9C          sbc  a,h
A7D2: 08          ex   af,af'
A7D3: 9D          sbc  a,l
A7D4: 08          ex   af,af'
A7D5: BC          cp   h
A7D6: 08          ex   af,af'
A7D7: 3D          dec  a
A7D8: 08          ex   af,af'
A7D9: 4D          ld   c,l
A7DA: 88          adc  a,b
A7DB: 4C          ld   c,h
A7DC: 88          adc  a,b
A7DD: EC 88 CD    call pe,$CD88
A7E0: 88          adc  a,b
A7E1: CC 88 AD    call z,$CB88
A7E4: 88          adc  a,b
A7E5: AC          xor  h
A7E6: 88          adc  a,b
A7E7: 8C          adc  a,h
A7E8: 48          ld   c,b
A7E9: 1C          inc  e
A7EA: 88          adc  a,b
A7EB: 1C          inc  e
A7EC: 08          ex   af,af'
A7ED: DD          db   $dd
A7EE: 88          adc  a,b
A7EF: DC 08 DC    call c,$DC80
A7F2: 08          ex   af,af'
A7F3: DD          db   $dd
A7F4: 08          ex   af,af'
A7F5: 0C          inc  c
A7F6: 88          adc  a,b
A7F7: 0C          inc  c
A7F8: 08          ex   af,af'
A7F9: 8C          adc  a,h
A7FA: 08          ex   af,af'
A7FB: AC          xor  h
A7FC: 08          ex   af,af'
A7FD: AD          xor  l
A7FE: 08          ex   af,af'
A7FF: 6C          ld   l,h
A800: 08          ex   af,af'
A801: 6D          ld   l,l
A802: 08          ex   af,af'
A803: 5D          ld   e,l
A804: 88          adc  a,b
A805: CD C8 CC    call $CC8C
A808: C8          ret  z
A809: AD          xor  l
A80A: C8          ret  z
A80B: AC          xor  h
A80C: C8          ret  z
A80D: 5C          ld   e,h
A80E: 88          adc  a,b
A80F: 9C          sbc  a,h
A810: 88          adc  a,b
A811: AC          xor  h
A812: 48          ld   c,b
A813: AD          xor  l
A814: 48          ld   c,b
A815: CC 48 CD    call z,$CD84
A818: 48          ld   c,b
A819: 5D          ld   e,l
A81A: 08          ex   af,af'
A81B: 9C          sbc  a,h
A81C: 08          ex   af,af'
A81D: 5C          ld   e,h
A81E: 08          ex   af,af'
A81F: 6D          ld   l,l
A820: 88          adc  a,b
A821: 6C          ld   l,h
A822: 88          adc  a,b
A823: AD          xor  l
A824: 88          adc  a,b
A825: AC          xor  h
A826: 88          adc  a,b
A827: 8C          adc  a,h
A828: C8          ret  z
A829: 1C          inc  e
A82A: 88          adc  a,b
A82B: 1C          inc  e
A82C: 08          ex   af,af'
A82D: FC 88 FC    call m,$DE88
A830: 08          ex   af,af'
A831: 8C          adc  a,h
A832: 08          ex   af,af'
A833: AC          xor  h
A834: 08          ex   af,af'
A835: BD          cp   l
A836: 08          ex   af,af'
A837: FD          db   $fd
A838: 08          ex   af,af'
A839: 7D          ld   a,l
A83A: 08          ex   af,af'
A83B: 7C          ld   a,h
A83C: 88          adc  a,b
A83D: 2D          dec  l
A83E: 88          adc  a,b
A83F: CC C8 AD    call z,$CB8C
A842: C8          ret  z
A843: AC          xor  h
A844: C8          ret  z
A845: 0D          dec  c
A846: 88          adc  a,b
A847: ED          db   $ed
A848: 88          adc  a,b
A849: AC          xor  h
A84A: 48          ld   c,b
A84B: AD          xor  l
A84C: 48          ld   c,b
A84D: CC 48 2D    call z,$C384
A850: 08          ex   af,af'
A851: 7C          ld   a,h
A852: 08          ex   af,af'
A853: ED          db   $ed
A854: 08          ex   af,af'
A855: 0D          dec  c
A856: 08          ex   af,af'
A857: 7D          ld   a,l
A858: 88          adc  a,b
A859: FD          db   $fd
A85A: 88          adc  a,b
A85B: BD          cp   l
A85C: 88          adc  a,b
A85D: AC          xor  h
A85E: 88          adc  a,b
A85F: 8C          adc  a,h
A860: C8          ret  z
A861: 8D          adc  a,l
A862: 88          adc  a,b
A863: 8D          adc  a,l
A864: 08          ex   af,af'
A865: 8C          adc  a,h
A866: 08          ex   af,af'
A867: DD 21 06 0F ld   ix,$E160
A86B: FD 21 C4 FE ld   iy,$FE4C
A86F: DD 36 00 FF ld   (ix+$00),$FF
A873: DD 36 21 08 ld   (ix+$03),$80
A877: DD 36 40 00 ld   (ix+$04),$00
A87B: DD 36 41 12 ld   (ix+$05),$30
A87F: DD 36 60 00 ld   (ix+$06),$00
A883: 21 00 01    ld   hl,$0100
A886: DD 74 61    ld   (ix+$07),h
A889: DD 75 80    ld   (ix+$08),l
A88C: 21 DE FF    ld   hl,$FFFC
A88F: DD 74 81    ld   (ix+$09),h
A892: DD 75 A0    ld   (ix+$0a),l
A895: DD 36 A1 08 ld   (ix+$0b),$80
A899: DD 36 31 00 ld   (ix+$13),$00
A89D: DD 36 50 00 ld   (ix+$14),$00
A8A1: 21 00 01    ld   hl,$0100
A8A4: CD E1 AB    call $AB0F
A8A7: C9          ret
A8A8: CD 27 CB    call $AD63
A8AB: DD 21 06 0F ld   ix,$E160
A8AF: FD 21 C4 FE ld   iy,$FE4C
A8B3: CD 0D 8A    call $A8C1
A8B6: DD 7E 00    ld   a,(ix+$00)
A8B9: A7          and  a
A8BA: C8          ret  z
A8BB: CD 63 AB    call $AB27
A8BE: C3 EC AB    jp   $ABCE
A8C1: DD 66 51    ld   h,(ix+$15)
A8C4: DD 6E 70    ld   l,(ix+$16)
A8C7: 2B          dec  hl
A8C8: DD 74 51    ld   (ix+$15),h
A8CB: DD 75 70    ld   (ix+$16),l
A8CE: 7C          ld   a,h
A8CF: B5          or   l
A8D0: CC 9F 8A    call z,$A8F9
A8D3: DD 7E 50    ld   a,(ix+$14)
A8D6: F7          rst  $30
A8D7: 1F          rra
A8D8: 8A          adc  a,d
A8D9: 5E          ld   e,(hl)
A8DA: 8A          adc  a,d
A8DB: 5E          ld   e,(hl)
A8DC: 8A          adc  a,d
A8DD: 5E          ld   e,(hl)
A8DE: 8A          adc  a,d
A8DF: 5E          ld   e,(hl)
A8E0: 8A          adc  a,d
A8E1: 5E          ld   e,(hl)
A8E2: 8A          adc  a,d
A8E3: 5E          ld   e,(hl)
A8E4: 8A          adc  a,d
A8E5: 5E          ld   e,(hl)
A8E6: 8A          adc  a,d
A8E7: 5E          ld   e,(hl)
A8E8: 8A          adc  a,d
A8E9: 5E          ld   e,(hl)
A8EA: 8A          adc  a,d
A8EB: 5E          ld   e,(hl)
A8EC: 8A          adc  a,d
A8ED: 5E          ld   e,(hl)
A8EE: 8A          adc  a,d
A8EF: 5F          ld   e,a
A8F0: 8A          adc  a,d
A8F1: C3 64 AA    jp   $AA46
A8F4: C9          ret
A8F5: C3 64 AA    jp   $AA46
A8F8: C9          ret
A8F9: DD 7E 50    ld   a,(ix+$14)
A8FC: DD 34 50    inc  (ix+$14)
A8FF: F7          rst  $30
A900: B0          or   b
A901: 8B          adc  a,e
A902: D1          pop  de
A903: 8B          adc  a,e
A904: C2 8B E3    jp   nz,$2FA9
A907: 8B          adc  a,e
A908: 55          ld   d,l
A909: 8B          adc  a,e
A90A: 94          sub  h
A90B: 8B          adc  a,e
A90C: F4 8B 36    call p,$72A9
A90F: 8B          adc  a,e
A910: 57          ld   d,a
A911: 8B          adc  a,e
A912: 96          sub  (hl)
A913: 8B          adc  a,e
A914: B7          or   a
A915: 8B          adc  a,e
A916: F6 8B       or   $A9
A918: 09          add  hl,bc
A919: 8B          adc  a,e
A91A: C3 79 AA    jp   $AA97
A91D: DD 34 31    inc  (ix+$13)
A920: 21 8E FF    ld   hl,$FFE8
A923: CD 01 AB    call $AB01
A926: 21 90 00    ld   hl,$0018
A929: C3 E1 AB    jp   $AB0F
A92C: C3 BB AA    jp   $AABB
A92F: 3A 00 0F    ld   a,($E100)
A932: FE FE       cp   $FE
A934: C2 A5 8B    jp   nz,$A94B
A937: AF          xor  a
A938: 32 00 0F    ld   ($E100),a
A93B: 32 B2 FF    ld   ($FF3A),a
A93E: 32 F2 FF    ld   ($FF3E),a
A941: 32 24 FF    ld   ($FF42),a
A944: 3C          inc  a
A945: 32 7B 0E    ld   ($E0B7),a
A948: C3 0D AA    jp   $AAC1
A94B: DD 36 50 21 ld   (ix+$14),$03
A94F: 21 61 00    ld   hl,$0007
A952: C3 E1 AB    jp   $AB0F
A955: C3 6D AA    jp   $AAC7
A958: CD 39 68    call $8693
A95B: C3 9D AA    jp   $AAD9
A95E: 3A 7B 0E    ld   a,($E0B7)
A961: FE 20       cp   $02
A963: 20 21       jr   nz,$A968
A965: C3 79 AA    jp   $AA97
A968: DD 36 50 60 ld   (ix+$14),$06
A96C: 21 61 00    ld   hl,$0007
A96F: C3 E1 AB    jp   $AB0F
A972: C3 8B AA    jp   $AAA9
A975: C3 BB AA    jp   $AABB
A978: C3 0D AA    jp   $AAC1
A97B: C3 6D AA    jp   $AAC7
A97E: C3 9D AA    jp   $AAD9
A981: E1          pop  hl
A982: DD 36 00 00 ld   (ix+$00),$00
A986: CD 2B 8B    call $A9A3
A989: C9          ret
A98A: 21 12 FE    ld   hl,$FE30
A98D: 11 CA FE    ld   de,$FEAC
A990: 01 08 00    ld   bc,$0080
A993: ED B0       ldir
A995: 21 D2 FE    ld   hl,$FE3C
A998: 11 D3 FE    ld   de,$FE3D
A99B: 36 00       ld   (hl),$00
A99D: 01 E1 00    ld   bc,$000F
A9A0: ED B0       ldir
A9A2: C9          ret
A9A3: 11 12 FE    ld   de,$FE30
A9A6: 21 CA FE    ld   hl,$FEAC
A9A9: 01 08 00    ld   bc,$0080
A9AC: ED B0       ldir
A9AE: 21 CA FE    ld   hl,$FEAC
A9B1: 11 CB FE    ld   de,$FEAD
A9B4: 36 00       ld   (hl),$00
A9B6: 01 F7 00    ld   bc,$007F
A9B9: ED B0       ldir
A9BB: C9          ret
A9BC: CD 48 68    call $8684
A9BF: CD A8 8B    call $A98A
A9C2: DD 21 06 0F ld   ix,$E160
A9C6: FD 21 C4 FE ld   iy,$FE4C
A9CA: DD 36 00 FF ld   (ix+$00),$FF
A9CE: DD 36 21 08 ld   (ix+$03),$80
A9D2: DD 36 40 00 ld   (ix+$04),$00
A9D6: DD 36 41 12 ld   (ix+$05),$30
A9DA: DD 36 60 00 ld   (ix+$06),$00
A9DE: 21 00 01    ld   hl,$0100
A9E1: DD 74 61    ld   (ix+$07),h
A9E4: DD 75 80    ld   (ix+$08),l
A9E7: 21 DE FF    ld   hl,$FFFC
A9EA: DD 74 81    ld   (ix+$09),h
A9ED: DD 75 A0    ld   (ix+$0a),l
A9F0: DD 36 A1 08 ld   (ix+$0b),$80
A9F4: DD 36 31 00 ld   (ix+$13),$00
A9F8: DD 36 50 00 ld   (ix+$14),$00
A9FC: 21 00 01    ld   hl,$0100
A9FF: CD E1 AB    call $AB0F
AA02: C9          ret
AA03: CD 27 CB    call $AD63
AA06: DD 21 06 0F ld   ix,$E160
AA0A: FD 21 C4 FE ld   iy,$FE4C
AA0E: CD 71 AA    call $AA17
AA11: CD 63 AB    call $AB27
AA14: C3 F1 AB    jp   $AB1F
AA17: DD 66 51    ld   h,(ix+$15)
AA1A: DD 6E 70    ld   l,(ix+$16)
AA1D: 2B          dec  hl
AA1E: DD 74 51    ld   (ix+$15),h
AA21: DD 75 70    ld   (ix+$16),l
AA24: 7C          ld   a,h
AA25: B5          or   l
AA26: CC F7 AA    call z,$AA7F
AA29: DD 7E 50    ld   a,(ix+$14)
AA2C: E6 61       and  $07
AA2E: F7          rst  $30
AA2F: D3 AA       out  ($AA),a
AA31: 05          dec  b
AA32: AA          xor  d
AA33: 05          dec  b
AA34: AA          xor  d
AA35: 05          dec  b
AA36: AA          xor  d
AA37: 05          dec  b
AA38: AA          xor  d
AA39: 05          dec  b
AA3A: AA          xor  d
AA3B: 24          inc  h
AA3C: AA          xor  d
AA3D: CD 64 AA    call $AA46
AA40: C9          ret
AA41: C9          ret
AA42: CD 64 AA    call $AA46
AA45: C9          ret
AA46: DD 66 61    ld   h,(ix+$07)
AA49: DD 6E 80    ld   l,(ix+$08)
AA4C: 3A 20 0E    ld   a,($E002)
AA4F: E6 21       and  $03
AA51: 20 70       jr   nz,$AA69
AA53: DD 7E A1    ld   a,(ix+$0b)
AA56: A7          and  a
AA57: 28 10       jr   z,$AA69
AA59: DD 35 A1    dec  (ix+$0b)
AA5C: DD 56 81    ld   d,(ix+$09)
AA5F: DD 5E A0    ld   e,(ix+$0a)
AA62: 19          add  hl,de
AA63: DD 74 61    ld   (ix+$07),h
AA66: DD 75 80    ld   (ix+$08),l
AA69: DD 7E 40    ld   a,(ix+$04)
AA6C: DD 56 41    ld   d,(ix+$05)
AA6F: DD 5E 60    ld   e,(ix+$06)
AA72: 19          add  hl,de
AA73: DD 74 41    ld   (ix+$05),h
AA76: DD 75 60    ld   (ix+$06),l
AA79: CE 00       adc  a,$00
AA7B: DD 77 40    ld   (ix+$04),a
AA7E: C9          ret
AA7F: DD 7E 50    ld   a,(ix+$14)
AA82: DD 34 50    inc  (ix+$14)
AA85: FE 60       cp   $06
AA87: CA 70 AB    jp   z,$AB16
AA8A: F7          rst  $30
AA8B: 79          ld   a,c
AA8C: AA          xor  d
AA8D: 8B          adc  a,e
AA8E: AA          xor  d
AA8F: BB          cp   e
AA90: AA          xor  d
AA91: 0D          dec  c
AA92: AA          xor  d
AA93: 6D          ld   l,l
AA94: AA          xor  d
AA95: 9D          sbc  a,l
AA96: AA          xor  d
AA97: CD 89 68    call $8689
AA9A: DD 34 31    inc  (ix+$13)
AA9D: 21 8E FF    ld   hl,$FFE8
AAA0: CD 01 AB    call $AB01
AAA3: 21 90 00    ld   hl,$0018
AAA6: C3 E1 AB    jp   $AB0F
AAA9: DD 34 31    inc  (ix+$13)
AAAC: 21 8E FF    ld   hl,$FFE8
AAAF: CD 01 AB    call $AB01
AAB2: CD 54 CB    call $AD54
AAB5: 21 90 00    ld   hl,$0018
AAB8: C3 E1 AB    jp   $AB0F
AABB: 21 01 00    ld   hl,$0001
AABE: C3 E1 AB    jp   $AB0F
AAC1: 21 10 00    ld   hl,$0010
AAC4: C3 E1 AB    jp   $AB0F
AAC7: CD E8 68    call $868E
AACA: DD 35 31    dec  (ix+$13)
AACD: 21 90 00    ld   hl,$0018
AAD0: CD 01 AB    call $AB01
AAD3: 21 10 00    ld   hl,$0010
AAD6: C3 E1 AB    jp   $AB0F
AAD9: DD 35 31    dec  (ix+$13)
AADC: 21 90 00    ld   hl,$0018
AADF: CD 01 AB    call $AB01
AAE2: 21 00 00    ld   hl,$0000
AAE5: DD 74 61    ld   (ix+$07),h
AAE8: DD 75 80    ld   (ix+$08),l
AAEB: 21 11 00    ld   hl,$0011
AAEE: DD 74 81    ld   (ix+$09),h
AAF1: DD 75 A0    ld   (ix+$0a),l
AAF4: DD 36 A1 08 ld   (ix+$0b),$80
AAF8: 21 08 00    ld   hl,$0080
AAFB: C3 E1 AB    jp   $AB0F
AAFE: 21 8E FF    ld   hl,$FFE8
AB01: DD 56 40    ld   d,(ix+$04)
AB04: DD 5E 41    ld   e,(ix+$05)
AB07: 19          add  hl,de
AB08: DD 74 40    ld   (ix+$04),h
AB0B: DD 75 41    ld   (ix+$05),l
AB0E: C9          ret
AB0F: DD 74 51    ld   (ix+$15),h
AB12: DD 75 70    ld   (ix+$16),l
AB15: C9          ret
AB16: E1          pop  hl
AB17: DD 36 00 00 ld   (ix+$00),$00
AB1B: CD 2B 8B    call $A9A3
AB1E: C9          ret
AB1F: DD 7E 00    ld   a,(ix+$00)
AB22: A7          and  a
AB23: C8          ret  z
AB24: C3 EC AB    jp   $ABCE
AB27: DD 7E 31    ld   a,(ix+$13)
AB2A: 21 52 AB    ld   hl,$AB34
AB2D: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
AB2E: CD 88 A3    call $2B88
AB31: C3 88 A3    jp   $2B88
AB34: B2          or   d
AB35: AB          xor  e
AB36: A6          and  (hl)
AB37: AB          xor  e
AB38: B8          cp   b
AB39: AB          xor  e
AB3A: A1          and  c
AB3B: 18 1E       jr   $AB2D
AB3D: 6F          ld   l,a
AB3E: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
AB3F: EE FF       xor  $FF
AB41: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
AB42: EE 4E       xor  $E4
AB44: FE 4F       cp   $E5
AB46: CF          rst  $08
AB47: CE DF       adc  a,$FD
AB49: CF          rst  $08
AB4A: CE 5E       adc  a,$F4
AB4C: DE 5F       sbc  a,$F5
AB4E: AF          xor  a
AB4F: DE BF       sbc  a,$FB
AB51: DF          rst  $18
AB52: A1          and  c
AB53: 98          sbc  a,b
AB54: 00          nop
AB55: 6F          ld   l,a
AB56: F1          pop  af
AB57: EE E1       xor  $0F
AB59: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
AB5A: F0          ret  p
AB5B: 4E          ld   c,(hl)
AB5C: E0          ret  po
AB5D: 4F          ld   c,a
AB5E: D1          pop  de
AB5F: CE C1       adc  a,$0D
AB61: CF          rst  $08
AB62: D0          ret  nc
AB63: 5E          ld   e,(hl)
AB64: C0          ret  nz
AB65: 5F          ld   e,a
AB66: B1          or   c
AB67: DE A1       sbc  a,$0B
AB69: DF          rst  $18
AB6A: A1          and  c
AB6B: 18 1E       jr   $AB5D
AB6D: 6E          ld   l,(hl)
AB6E: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
AB6F: 2E FF       ld   l,$FF
AB71: 2F          cpl
AB72: EE AE       xor  $EA
AB74: FE AF       cp   $EB
AB76: CF          rst  $08
AB77: 3E DF       ld   a,$FD
AB79: 3F          ccf
AB7A: CE BE       adc  a,$FA
AB7C: DE BF       sbc  a,$FB
AB7E: CF          rst  $08
AB7F: FF          rst  $38
AB80: CF          rst  $08
AB81: FF          rst  $38
AB82: A1          and  c
AB83: 98          sbc  a,b
AB84: 00          nop
AB85: 6E          ld   l,(hl)
AB86: F1          pop  af
AB87: 2E E1       ld   l,$0F
AB89: 2F          cpl
AB8A: F0          ret  p
AB8B: AE          xor  (hl)
AB8C: E0          ret  po
AB8D: AF          xor  a
AB8E: D1          pop  de
AB8F: 3E C1       ld   a,$0D
AB91: 3F          ccf
AB92: D0          ret  nc
AB93: BE          cp   (hl)
AB94: C0          ret  nz
AB95: BF          cp   a
AB96: D1          pop  de
AB97: FF          rst  $38
AB98: D1          pop  de
AB99: FF          rst  $38
AB9A: A1          and  c
AB9B: 18 0E       jr   $AB7D
AB9D: 0E 1E       ld   c,$F0
AB9F: 0F          rrca
ABA0: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
ABA1: 8E          adc  a,(hl)
ABA2: FF          rst  $38
ABA3: 8F          adc  a,a
ABA4: EE 1E       xor  $F0
ABA6: FE 1F       cp   $F1
ABA8: CF          rst  $08
ABA9: 9E          sbc  a,(hl)
ABAA: DF          rst  $18
ABAB: 9F          sbc  a,a
ABAC: CF          rst  $08
ABAD: FF          rst  $38
ABAE: CF          rst  $08
ABAF: FF          rst  $38
ABB0: CF          rst  $08
ABB1: FF          rst  $38
ABB2: A1          and  c
ABB3: 98          sbc  a,b
ABB4: 10 0E       djnz $AB96
ABB6: 00          nop
ABB7: 0F          rrca
ABB8: F1          pop  af
ABB9: 8E          adc  a,(hl)
ABBA: E1          pop  hl
ABBB: 8F          adc  a,a
ABBC: F0          ret  p
ABBD: 1E E0       ld   e,$0E
ABBF: 1F          rra
ABC0: D1          pop  de
ABC1: 9E          sbc  a,(hl)
ABC2: C1          pop  bc
ABC3: 9F          sbc  a,a
ABC4: D1          pop  de
ABC5: FF          rst  $38
ABC6: D1          pop  de
ABC7: FF          rst  $38
ABC8: D1          pop  de
ABC9: FF          rst  $38
ABCA: DD 21 06 0F ld   ix,$E160
ABCE: CD 62 CB    call $AD26
ABD1: DD 7E 00    ld   a,(ix+$00)
ABD4: A7          and  a
ABD5: C8          ret  z
ABD6: 21 ED 2A    ld   hl,$A2CF
ABD9: E5          push hl
ABDA: DD 34 71    inc  (ix+$17)
ABDD: DD 7E 71    ld   a,(ix+$17)
ABE0: FE 60       cp   $06
ABE2: 38 41       jr   c,$ABE9
ABE4: 3E 00       ld   a,$00
ABE6: DD 77 71    ld   (ix+$17),a
ABE9: DD 66 40    ld   h,(ix+$04)
ABEC: DD 6E 41    ld   l,(ix+$05)
ABEF: 11 7E FF    ld   de,$FFF6
ABF2: 19          add  hl,de
ABF3: DD 74 C0    ld   (ix+$0c),h
ABF6: DD 75 C1    ld   (ix+$0d),l
ABF9: FD 21 90 FE ld   iy,$FE18
ABFD: 47          ld   b,a
ABFE: DD 7E 31    ld   a,(ix+$13)
AC01: E6 21       and  $03
AC03: 21 54 CA    ld   hl,$AC54
AC06: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
AC07: DD 66 21    ld   h,(ix+$03)
AC0A: DD 6E C1    ld   l,(ix+$0d)
AC0D: DD 7E C0    ld   a,(ix+$0c)
AC10: E6 01       and  $01
AC12: 4F          ld   c,a
AC13: E5          push hl
AC14: 78          ld   a,b
AC15: EB          ex   de,hl
AC16: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
AC17: D5          push de
AC18: DD E1       pop  ix
AC1A: DD 5E 00    ld   e,(ix+$00)
AC1D: DD 56 01    ld   d,(ix+$01)
AC20: DD 7E 20    ld   a,(ix+$02)
AC23: 08          ex   af,af'
AC24: E1          pop  hl
AC25: DD 46 21    ld   b,(ix+$03)
AC28: 7C          ld   a,h
AC29: DD 86 40    add  a,(ix+$04)
AC2C: 67          ld   h,a
AC2D: 7D          ld   a,l
AC2E: E5          push hl
AC2F: D5          push de
AC30: 61          ld   h,c
AC31: DD 5E 41    ld   e,(ix+$05)
AC34: 16 00       ld   d,$00
AC36: CB 7B       bit  7,e
AC38: 28 01       jr   z,$AC3B
AC3A: 14          inc  d
AC3B: 19          add  hl,de
AC3C: 7C          ld   a,h
AC3D: E6 01       and  $01
AC3F: 4F          ld   c,a
AC40: 7D          ld   a,l
AC41: D1          pop  de
AC42: E1          pop  hl
AC43: 6F          ld   l,a
AC44: CD 52 CB    call $AD34
AC47: DD 23       inc  ix
AC49: DD 23       inc  ix
AC4B: DD 23       inc  ix
AC4D: 08          ex   af,af'
AC4E: 3D          dec  a
AC4F: C8          ret  z
AC50: 08          ex   af,af'
AC51: C3 43 CA    jp   $AC25
AC54: B4          or   h
AC55: CA 66 CA    jp   z,$AC66
AC58: 36 CA       ld   (hl),$AC
AC5A: F6 CA       or   $AC
AC5C: 69          ld   l,c
AC5D: CA 39 CA    jp   z,$AC93
AC60: F9          ld   sp,hl
AC61: CA 8A CA    jp   z,$ACA8
AC64: 5A          ld   e,d
AC65: CA DB CA    jp   z,$ACBD
AC68: 2D          dec  l
AC69: CA ED CA    jp   z,$ACCF
AC6C: BD          cp   l
AC6D: CA 0F CA    jp   z,$ACE1
AC70: AE          xor  (hl)
AC71: CA 3F CA    jp   z,$ACF3
AC74: 9F          sbc  a,a
AC75: CA 41 CB    jp   z,$AD05
AC78: 11 CB 71    ld   de,$17AD
AC7B: CB 02       rlc  d
AC7D: CB 6B       bit  5,e
AC7F: 6B          ld   l,e
AC80: 20 20       jr   nz,$AC84
AC82: 02          ld   (bc),a
AC83: 02          ld   (bc),a
AC84: 41          ld   b,c
AC85: 0C          inc  c
AC86: 1E 5B       ld   e,$B5
AC88: 6B          ld   l,e
AC89: 21 41 1A    ld   hl,$B005
AC8C: 00          nop
AC8D: 01 0A 3F    ld   bc,$F3A0
AC90: 21 00 DF    ld   hl,$FD00
AC93: 6D          ld   l,l
AC94: 6B          ld   l,e
AC95: 21 41 00    ld   hl,$0005
AC98: 00          nop
AC99: 21 1C 1E    ld   hl,$F0D0
AC9C: 01 00 21    ld   bc,$0300
AC9F: 9D          sbc  a,l
ACA0: 6B          ld   l,e
ACA1: 20 20       jr   nz,$ACA5
ACA3: 0C          inc  c
ACA4: 02          ld   (bc),a
ACA5: 41          ld   b,c
ACA6: 1C          inc  e
ACA7: 1E 6F       ld   e,$E7
ACA9: 6B          ld   l,e
ACAA: 21 01 9E    ld   hl,$F801
ACAD: 00          nop
ACAE: 20 8E       jr   nz,$AC98
ACB0: 1E 40       ld   e,$04
ACB2: 1C          inc  e
ACB3: 1E 5F       ld   e,$F5
ACB5: 6B          ld   l,e
ACB6: 20 20       jr   nz,$ACBA
ACB8: 1E 02       ld   e,$20
ACBA: 01 8E 1E    ld   bc,$F0E8
ACBD: BF          cp   a
ACBE: 6B          ld   l,e
ACBF: 01 40 00    ld   bc,$0004
ACC2: 10 21       djnz $ACC7
ACC4: 8A          adc  a,d
ACC5: 21 01 1A    ld   hl,$B001
ACC8: 9E          sbc  a,(hl)
ACC9: 40          ld   b,b
ACCA: 00          nop
ACCB: 80          add  a,b
ACCC: 20 0C       jr   nz,$AC8E
ACCE: 1E 11       ld   e,$11
ACD0: 8A          adc  a,d
ACD1: 21 40 00    ld   hl,$0004
ACD4: 00          nop
ACD5: 01 00 9E    ld   bc,$F800
ACD8: 20 1C       jr   nz,$ACAA
ACDA: 9E          sbc  a,(hl)
ACDB: F1          pop  af
ACDC: 8A          adc  a,d
ACDD: 01 40 0C    ld   bc,$C004
ACE0: 10 63       djnz $AD09
ACE2: 8A          adc  a,d
ACE3: 20 01       jr   nz,$ACE6
ACE5: 9E          sbc  a,(hl)
ACE6: 00          nop
ACE7: 20 8E       jr   nz,$ACD1
ACE9: 1E C3       ld   e,$2D
ACEB: 8A          adc  a,d
ACEC: 20 20       jr   nz,$ACF0
ACEE: 1E 02       ld   e,$20
ACF0: 01 8E 1E    ld   bc,$F0E8
ACF3: 33          inc  sp
ACF4: 8A          adc  a,d
ACF5: 01 40 00    ld   bc,$0004
ACF8: 10 B3       djnz $AD35
ACFA: 8A          adc  a,d
ACFB: 21 01 1A    ld   hl,$B001
ACFE: 9E          sbc  a,(hl)
ACFF: 40          ld   b,b
AD00: 00          nop
AD01: 80          add  a,b
AD02: 20 0C       jr   nz,$ACC4
AD04: 1E 85       ld   e,$49
AD06: 8A          adc  a,d
AD07: 21 40 00    ld   hl,$0004
AD0A: 00          nop
AD0B: 01 00 9E    ld   bc,$F800
AD0E: 20 1C       jr   nz,$ACE0
AD10: 9E          sbc  a,(hl)
AD11: 75          ld   (hl),l
AD12: 8A          adc  a,d
AD13: 01 40 0C    ld   bc,$C004
AD16: 10 F5       djnz $AD77
AD18: 8A          adc  a,d
AD19: 20 01       jr   nz,$AD1C
AD1B: 9E          sbc  a,(hl)
AD1C: 00          nop
AD1D: 20 8E       jr   nz,$AD07
AD1F: 1E 47       ld   e,$65
AD21: 8A          adc  a,d
AD22: 01 01 9E    ld   bc,$F801
AD25: 10 21       djnz $AD2A
AD27: B0          or   b
AD28: FE 11       cp   $11
AD2A: 40          ld   b,b
AD2B: 00          nop
AD2C: 06 81       ld   b,$09
AD2E: 36 00       ld   (hl),$00
AD30: 19          add  hl,de
AD31: 10 BF       djnz $AD2E
AD33: C9          ret
AD34: FD 74 20    ld   (iy+$02),h
AD37: FD 75 21    ld   (iy+$03),l
AD3A: 1A          ld   a,(de)
AD3B: 13          inc  de
AD3C: FD 77 00    ld   (iy+$00),a
AD3F: 1A          ld   a,(de)
AD40: 13          inc  de
AD41: 81          add  a,c
AD42: FD 77 01    ld   (iy+$01),a
AD45: 7C          ld   a,h
AD46: C6 10       add  a,$10
AD48: 67          ld   h,a
AD49: FD 23       inc  iy
AD4B: FD 23       inc  iy
AD4D: FD 23       inc  iy
AD4F: FD 23       inc  iy
AD51: 10 0F       djnz $AD34
AD53: C9          ret
AD54: 3E FF       ld   a,$FF
AD56: 32 02 4E    ld   ($E420),a
AD59: 3C          inc  a
AD5A: 32 52 4E    ld   ($E434),a
AD5D: 3E 90       ld   a,$18
AD5F: 32 53 4E    ld   ($E435),a
AD62: C9          ret
AD63: DD 21 02 4E ld   ix,$E420
AD67: FD 21 D2 FE ld   iy,$FE3C
AD6B: DD 7E 00    ld   a,(ix+$00)
AD6E: A7          and  a
AD6F: C8          ret  z
AD70: DD 35 51    dec  (ix+$15)
AD73: CA A7 EA    jp   z,$AE6B
AD76: DD 7E 50    ld   a,(ix+$14)
AD79: E6 21       and  $03
AD7B: F7          rst  $30
AD7C: 48          ld   c,b
AD7D: CB 2B       sra  e
AD7F: CB 80       res  0,b
AD81: EA 32 EA    jp   pe,$AE32
AD84: 3A 27 0F    ld   a,($E163)
AD87: C6 10       add  a,$10
AD89: FD 77 20    ld   (iy+$02),a
AD8C: DD 77 21    ld   (ix+$03),a
AD8F: 3A 47 0F    ld   a,($E165)
AD92: C6 3E       add  a,$F2
AD94: FD 77 21    ld   (iy+$03),a
AD97: DD 77 41    ld   (ix+$05),a
AD9A: FD 36 00 EC ld   (iy+$00),$CE
AD9E: FD 36 01 00 ld   (iy+$01),$00
ADA2: C9          ret
ADA3: DD 7E 51    ld   a,(ix+$15)
ADA6: 0F          rrca
ADA7: 0F          rrca
ADA8: 0F          rrca
ADA9: E6 61       and  $07
ADAB: 47          ld   b,a
ADAC: 21 8E CB    ld   hl,$ADE8
ADAF: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
ADB0: 1A          ld   a,(de)
ADB1: 13          inc  de
ADB2: DD 77 F0    ld   (ix+$1e),a
ADB5: DD 72 81    ld   (ix+$09),d
ADB8: DD 73 A0    ld   (ix+$0a),e
ADBB: 78          ld   a,b
ADBC: 21 FE CB    ld   hl,$ADFE
ADBF: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
ADC0: 01 96 00    ld   bc,$0078
ADC3: DD 66 21    ld   h,(ix+$03)
ADC6: DD 6E 40    ld   l,(ix+$04)
ADC9: 09          add  hl,bc
ADCA: DD 74 21    ld   (ix+$03),h
ADCD: DD 75 40    ld   (ix+$04),l
ADD0: DD 66 41    ld   h,(ix+$05)
ADD3: DD 6E 60    ld   l,(ix+$06)
ADD6: 19          add  hl,de
ADD7: DD 74 41    ld   (ix+$05),h
ADDA: DD 75 60    ld   (ix+$06),l
ADDD: 0E 00       ld   c,$00
ADDF: DD 66 81    ld   h,(ix+$09)
ADE2: DD 6E A0    ld   l,(ix+$0a)
ADE5: C3 2C C9    jp   $8DC2
ADE8: BE          cp   (hl)
ADE9: CB 7E       bit  7,(hl)
ADEB: CB 7E       bit  7,(hl)
ADED: CB 3E       srl  (hl)
ADEF: CB 3E       srl  (hl)
ADF1: CB 00       rlc  b
ADF3: 4C          ld   c,h
ADF4: CC 00 00    call z,$0000
ADF7: 4D          ld   c,l
ADF8: CD 00 01    call $0100
ADFB: 31 B0 B1    ld   sp,$1B1A
ADFE: 02          ld   (bc),a
ADFF: FF          rst  $38
AE00: 16 FF       ld   d,$FF
AE02: 1A          ld   a,(de)
AE03: FF          rst  $38
AE04: 04          inc  b
AE05: 00          nop
AE06: 08          ex   af,af'
AE07: 00          nop
AE08: 21 02 EA    ld   hl,$AE20
AE0B: DD 7E 51    ld   a,(ix+$15)
AE0E: 0F          rrca
AE0F: 0F          rrca
AE10: 0F          rrca
AE11: 0F          rrca
AE12: E6 21       and  $03
AE14: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
AE15: EB          ex   de,hl
AE16: 7E          ld   a,(hl)
AE17: 23          inc  hl
AE18: DD 77 F0    ld   (ix+$1e),a
AE1B: 0E 04       ld   c,$40
AE1D: C3 2C C9    jp   $8DC2
AE20: E3          ex   (sp),hl
AE21: EA C2 EA    jp   pe,$AE2C
AE24: E3          ex   (sp),hl
AE25: EA C2 EA    jp   pe,$AE2C
AE28: 20 45       jr   nz,$AE6F
AE2A: 64          ld   h,h
AE2B: E5          push hl
AE2C: 00          nop
AE2D: 64          ld   h,h
AE2E: E5          push hl
AE2F: 00          nop
AE30: 65          ld   h,l
AE31: E5          push hl
AE32: DD 7E 51    ld   a,(ix+$15)
AE35: 0F          rrca
AE36: 0F          rrca
AE37: 0F          rrca
AE38: 0F          rrca
AE39: E6 E1       and  $0F
AE3B: 21 27 EA    ld   hl,$AE63
AE3E: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
AE3F: DD 73 01    ld   (ix+$01),e
AE42: DD 72 20    ld   (ix+$02),d
AE45: CD B3 A9    call $8B3B
AE48: DD 66 61    ld   h,(ix+$07)
AE4B: DD 6E 80    ld   l,(ix+$08)
AE4E: DD 56 81    ld   d,(ix+$09)
AE51: DD 5E A0    ld   e,(ix+$0a)
AE54: DD 74 21    ld   (ix+$03),h
AE57: DD 75 40    ld   (ix+$04),l
AE5A: DD 72 41    ld   (ix+$05),d
AE5D: DD 73 60    ld   (ix+$06),e
AE60: C3 1B C8    jp   $8CB1
AE63: 0A          ld   a,(bc)
AE64: 04          inc  b
AE65: 1A          ld   a,(de)
AE66: 04          inc  b
AE67: 1A          ld   a,(de)
AE68: 04          inc  b
AE69: 0C          inc  c
AE6A: 04          inc  b
AE6B: DD 34 50    inc  (ix+$14)
AE6E: DD 7E 50    ld   a,(ix+$14)
AE71: FE 40       cp   $04
AE73: 28 C0       jr   z,$AE81
AE75: 21 D7 EA    ld   hl,$AE7D
AE78: E7          rst  $20                   ; call RETURN_BYTE_AT_HL_PLUS_A
AE79: DD 77 51    ld   (ix+$15),a
AE7C: C9          ret
AE7D: 00          nop
AE7E: 82          add  a,d
AE7F: 04          inc  b
AE80: 04          inc  b
AE81: DD 36 00 00 ld   (ix+$00),$00
AE85: FD 36 20 00 ld   (iy+$02),$00
AE89: FD 36 60 00 ld   (iy+$06),$00
AE8D: FD 36 A0 00 ld   (iy+$0a),$00
AE91: CD 60 89    call $8906
AE94: C9          ret
AE95: 3A 20 0E    ld   a,($E002)
AE98: E6 01       and  $01
AE9A: CA 23 EB    jp   z,$AF23
AE9D: CD 4F EA    call $AEE5
AEA0: C3 2B EA    jp   $AEA3


AEA3: 3A 00 0F    ld   a,($E100)
AEA6: 3C          inc  a
AEA7: C0          ret  nz
AEA8: DD 21 0C 2E ld   ix,$E2C0
AEAC: 3A 21 0F    ld   a,($E103)
AEAF: 67          ld   h,a
AEB0: 3A 41 0F    ld   a,($E105)
AEB3: 6F          ld   l,a
AEB4: 06 80       ld   b,$08
AEB6: D9          exx
AEB7: 11 02 00    ld   de,$0020
AEBA: D9          exx
AEBB: 16 60       ld   d,$06
AEBD: 1E C1       ld   e,$0D
AEBF: DD 7E 00    ld   a,(ix+$00)
AEC2: 3C          inc  a
AEC3: 20 91       jr   nz,$AEDE
AEC5: DD 7E 41    ld   a,(ix+$05)
AEC8: 95          sub  l
AEC9: BB          cp   e
AECA: 30 30       jr   nc,$AEDE
AECC: DD 7E 21    ld   a,(ix+$03)
AECF: 94          sub  h
AED0: 82          add  a,d
AED1: BB          cp   e
AED2: 30 A0       jr   nc,$AEDE
AED4: 3E F3       ld   a,$3F
AED6: 32 00 0F    ld   ($E100),a
AED9: DD 36 00 01 ld   (ix+$00),$01
AEDD: C9          ret

AEDE: D9          exx
AEDF: DD 19       add  ix,de
AEE1: D9          exx
AEE2: 10 BD       djnz $AEBF
AEE4: C9          ret
AEE5: 3A 00 0F    ld   a,($E100)
AEE8: 3C          inc  a
AEE9: C0          ret  nz
AEEA: DD 21 00 6E ld   ix,$E600
AEEE: 3A 21 0F    ld   a,($E103)
AEF1: 67          ld   h,a
AEF2: 3A 41 0F    ld   a,($E105)
AEF5: 6F          ld   l,a
AEF6: 06 80       ld   b,$08
AEF8: D9          exx
AEF9: 11 02 00    ld   de,$0020
AEFC: D9          exx
AEFD: 16 60       ld   d,$06
AEFF: 1E C1       ld   e,$0D
AF01: DD 7E 00    ld   a,(ix+$00)
AF04: 3C          inc  a
AF05: 20 51       jr   nz,$AF1C
AF07: 7D          ld   a,l
AF08: DD 96 41    sub  (ix+$05)
AF0B: BB          cp   e
AF0C: 30 E0       jr   nc,$AF1C
AF0E: DD 7E 21    ld   a,(ix+$03)
AF11: 94          sub  h
AF12: 82          add  a,d
AF13: BB          cp   e
AF14: 30 60       jr   nc,$AF1C
AF16: 3E F3       ld   a,$3F
AF18: 32 00 0F    ld   ($E100),a
AF1B: C9          ret
AF1C: D9          exx
AF1D: DD 19       add  ix,de
AF1F: D9          exx
AF20: 10 FD       djnz $AF01
AF22: C9          ret
AF23: 16 C0       ld   d,$0C
AF25: C3 92 00    jp   $0038
AF28: DD 21 00 2E ld   ix,$E200
AF2C: 0E 60       ld   c,$06
AF2E: D9          exx
AF2F: 01 02 00    ld   bc,$0020
AF32: D9          exx
AF33: 16 61       ld   d,$07
AF35: 1E E1       ld   e,$0F
AF37: DD 7E 00    ld   a,(ix+$00)
AF3A: 3C          inc  a
AF3B: 20 52       jr   nz,$AF71
AF3D: DD 66 21    ld   h,(ix+$03)
AF40: DD 6E 41    ld   l,(ix+$05)
AF43: FD 21 00 6E ld   iy,$E600
AF47: 06 80       ld   b,$08
AF49: FD 7E 00    ld   a,(iy+$00)
AF4C: 3C          inc  a
AF4D: 20 D0       jr   nz,$AF6B
AF4F: 7D          ld   a,l
AF50: FD 96 41    sub  (iy+$05)
AF53: C6 40       add  a,$04
AF55: FE 51       cp   $15
AF57: 30 30       jr   nc,$AF6B
AF59: FD 7E 21    ld   a,(iy+$03)
AF5C: 94          sub  h
AF5D: 82          add  a,d
AF5E: BB          cp   e
AF5F: 30 A0       jr   nc,$AF6B
AF61: DD 36 00 01 ld   (ix+$00),$01
AF65: FD 36 00 F3 ld   (iy+$00),$3F
AF69: 18 60       jr   $AF71
AF6B: D9          exx
AF6C: FD 09       add  iy,bc
AF6E: D9          exx
AF6F: 10 9C       djnz $AF49
AF71: D9          exx
AF72: DD 09       add  ix,bc
AF74: D9          exx
AF75: 0D          dec  c
AF76: C8          ret  z
AF77: 18 FA       jr   $AF37
AF79: 3A 04 0F    ld   a,($E140)
AF7C: 3C          inc  a
AF7D: C0          ret  nz
AF7E: 3A 25 0F    ld   a,($E143)
AF81: 67          ld   h,a
AF82: 3A 45 0F    ld   a,($E145)
AF85: 6F          ld   l,a
AF86: FD 21 00 6E ld   iy,$E600
AF8A: 06 80       ld   b,$08
AF8C: 11 02 00    ld   de,$0020
AF8F: FD 7E 00    ld   a,(iy+$00)
AF92: 3C          inc  a
AF93: 20 71       jr   nz,$AFAC
AF95: 7D          ld   a,l
AF96: FD 96 41    sub  (iy+$05)
AF99: FE C0       cp   $0C
AF9B: 30 E1       jr   nc,$AFAC
AF9D: FD 7E 21    ld   a,(iy+$03)
AFA0: 94          sub  h
AFA1: C6 41       add  a,$05
AFA3: FE A1       cp   $0B
AFA5: 30 41       jr   nc,$AFAC
AFA7: FD 36 00 F3 ld   (iy+$00),$3F
AFAB: C9          ret
AFAC: FD 19       add  iy,de
AFAE: 10 FD       djnz $AF8F
AFB0: C9          ret
