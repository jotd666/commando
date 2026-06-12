;
; Commando (C) 1985 CAPCOM.
;
; Reverse engineering work by Scott Tunstall, Paisley, Scotland. 
; Tools used: MAME debugger & Visual Studio Code text editor.
; Date: 23 Feb 2020. Keep checking for updates. 
; 
; Fake instructions cleanup, jump table discovery, entrypoints restorations by JOTD
;
; Please send any questions, corrections and updates to scott.tunstall@ntlworld.com
;
; Be sure to check out my reverse engineering work for Robotron 2084, Galaxian and Scramble too, 
; at http://seanriddle.com/robomame.asm, http://seanriddle.com/galaxian.asm and http://seanriddle.com/scramble.asm respectively.
;


; /*
; Conventions: 
; 
; NUMBERS
; =======
; 
; The term "@ $" means "at memory address in hexadecimal". 
; e.g. @ $1234 means "refer to memory address 1234" or "program code @ memory location 1234" 
; 
; The term "#$" means "immediate value in hexadecimal". It's a habit I have kept from 6502 days.
; e.g. #$60 means "immediate value of 60 hex" (96 decimal)
; 
; If I don't prefix a number with $ or #$ in my comments, treat the value as a decimal number.
; 
; 
; LABELS
; ======
; I have a labelling convention in place to help you identify the important parts of the code quicker.
; Any subroutine labelled with the SCRIPT_ , DISPLAY_ or HANDLE_ prefix are critical "top-level" functions responsible 
; for calling a series of "lower-level" functions to achieve a given result.   
; 
; If this helps you any, think of the "top level" as the main entry point to code that achieves a specific purpose.  
; 
; Routines prefixed HANDLE_ manage a particular aspect of the game.
;     For example, HANDLE_PLAYER_MOVE is the core routine for reading the player joystick and moving the player ship. 
;     HANDLE_PLAYER_SHOOT is the core routine for reading the player fire button and spawning a bullet.
; 
; I expect the purpose of DISPLAY_ is obvious.
; 
; SCRIPTS are documented below - see docs for SCRIPT_NUMBER ($4005)
; 
; 
; ARRAYS, LISTS, TABLES
; =====================
; 
; The terms "entry", "slot", "item", "record" when used in an array, list or table context all mean the same thing.
; I try to be consistent with my terminology but obviously with a task this size that might not be the case.
; 
; Unless I specify otherwise, I all indexes into arrays/lists/tables are zero-based, 
; meaning element [0] is the first element, [1] the second, [2] the third and so on.
; 
; FLAGS
; =====
; The terms "Clear", "Reset", "Unset" in a flag context all mean the flag is set to zero.
;                                                                                
; 
; COORDINATES
; ===========
; 
; X,Y refer to the X and Y axis in a 2D coordinate system, where X is horizontal and Y is vertical.
; 
; */
; 
; 
; Memory map taken from https://github.com/mamedev/mame/blob/master/src/mame/drivers/commando.cpp
; 
; MAIN CPU
; 0000-bfff ROM
; d000-d3ff Video RAM
; d400-d7ff Color RAM
; d800-dbff background video RAM
; dc00-dfff background color RAM
; e000-ffff RAM
; fe00-ff7f Sprites
; read:
; c000      IN0
; c001      IN1
; c002      IN2
; c003      DSW1
; c004      DSW2
; write:
; c808-c809 background scroll x position
; c80a-c80b background scroll y position
; SOUND CPU
; 0000-3fff ROM
; 4000-47ff RAM
; write:
; 8000      YM2203 #1 control
; 8001      YM2203 #1 write
; 8002      YM2203 #2 control
; 8003      YM2203 #2 write
; 
; 
;	map(0x0000, 0xbfff).rom();
;	map(0xc000, 0xc000).portr("SYSTEM");
;	map(0xc001, 0xc001).portr("P1");
;	map(0xc002, 0xc002).portr("P2");
;	map(0xc003, 0xc003).portr("DSW1");
;	map(0xc004, 0xc004).portr("DSW2");
;	map(0xc800, 0xc800).w("soundlatch", FUNC(generic_latch_8_device::write));
;	map(0xc804, 0xc804).w(FUNC(commando_state::c804_w));
;	// 0xc806 triggers the DMA (not emulated)
;	map(0xc808, 0xc809).w(FUNC(commando_state::scrollx_w));
;	map(0xc80a, 0xc80b).w(FUNC(commando_state::scrolly_w));
;	map(0xd000, 0xd3ff).ram().w(FUNC(commando_state::videoram_w<1>)).share(m_videoram[1]);
;	map(0xd400, 0xd7ff).ram().w(FUNC(commando_state::colorram_w<1>)).share(m_colorram[1]);
;	map(0xd800, 0xdbff).ram().w(FUNC(commando_state::videoram_w<0>)).share(m_videoram[0]);
;	map(0xdc00, 0xdfff).ram().w(FUNC(commando_state::colorram_w<0>)).share(m_colorram[0]);
;	map(0xe000, 0xfdff).ram();
;	map(0xfe00, 0xff7f).ram().share("spriteram");
;	map(0xff80, 0xffff).ram();
;}
;
;
;void commando_state::sound_map(address_map &map)
;{
;	map(0x0000, 0x3fff).rom();
;	map(0x4000, 0x47ff).ram();
;	map(0x6000, 0x6000).r("soundlatch", FUNC(generic_latch_8_device::read));
;	map(0x8000, 0x8001).w("ym1", FUNC(ym2203_device::write));
;	map(0x8002, 0x8003).w("ym2", FUNC(ym2203_device::write));
;}

; ; Port bits taken from https://github.com/RetroPie/mame4all-pi/blob/master/src/drivers/commando.cpp
; 
; PORT_START	/* IN0 */
; PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_START1 )
; PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_START2 )
; PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_UNUSED )
; PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_UNUSED )
; PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_UNKNOWN )
; PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_UNKNOWN )
; PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_COIN1 )
; PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_COIN2 )
; 
; PORT_START	/* IN1 */
; PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_JOYSTICK_RIGHT | IPF_8WAY )
; PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_JOYSTICK_LEFT | IPF_8WAY )
; PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_JOYSTICK_DOWN | IPF_8WAY )
; PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_JOYSTICK_UP | IPF_8WAY )
; PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_BUTTON1 )
; PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_BUTTON2 )
; PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_UNUSED )
; PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_UNUSED )
; 
; PORT_START	/* IN2 */
; PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_JOYSTICK_RIGHT | IPF_8WAY | IPF_COCKTAIL )
; PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_JOYSTICK_LEFT | IPF_8WAY | IPF_COCKTAIL )
; PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_JOYSTICK_DOWN | IPF_8WAY | IPF_COCKTAIL )
; PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_JOYSTICK_UP | IPF_8WAY | IPF_COCKTAIL )
; PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_BUTTON1 | IPF_COCKTAIL )
; PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_BUTTON2 | IPF_COCKTAIL )
; PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_UNUSED )
; PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_UNUSED )
; 
; 
; ; And these mappings are taken from https://github.com/mamedev/mame/blob/master/src/mame/drivers/commando.cpp
; 
; PORT_START("DSW1")
; PORT_DIPNAME( 0x03, 0x03, "Starting Area" ) PORT_DIPLOCATION("SW1:8,7")
; PORT_DIPSETTING(    0x03, "0 (Forest 1)" )
; PORT_DIPSETTING(    0x01, "2 (Desert 1)" )
; PORT_DIPSETTING(    0x02, "4 (Forest 2)" )
; PORT_DIPSETTING(    0x00, "6 (Desert 2)" )
; PORT_DIPNAME( 0x0c, 0x0c, DEF_STR( Lives ) ) PORT_DIPLOCATION("SW1:6,5")
; PORT_DIPSETTING(    0x04, "2" )
; PORT_DIPSETTING(    0x0c, "3" )
; PORT_DIPSETTING(    0x08, "4" )
; PORT_DIPSETTING(    0x00, "5" )
; PORT_DIPNAME( 0x30, 0x30, DEF_STR( Coin_B ) ) PORT_DIPLOCATION("SW1:4,3")
; PORT_DIPSETTING(    0x00, DEF_STR( 4C_1C ) )
; PORT_DIPSETTING(    0x20, DEF_STR( 3C_1C ) )
; PORT_DIPSETTING(    0x10, DEF_STR( 2C_1C ) )
; PORT_DIPSETTING(    0x30, DEF_STR( 1C_1C ) )
; PORT_DIPNAME( 0xc0, 0xc0, DEF_STR( Coin_A ) ) PORT_DIPLOCATION("SW1:1,2")
; PORT_DIPSETTING(    0x00, DEF_STR( 2C_1C ) )
; PORT_DIPSETTING(    0xc0, DEF_STR( 1C_1C ) )
; PORT_DIPSETTING(    0x40, DEF_STR( 1C_2C ) )
; PORT_DIPSETTING(    0x80, DEF_STR( 1C_3C ) )
; 
; PORT_START("DSW2")
; PORT_DIPNAME( 0x07, 0x07, DEF_STR( Bonus_Life ) ) PORT_DIPLOCATION("SW2:8,7,6")
; PORT_DIPSETTING(    0x07, "10K 50K+" )
; PORT_DIPSETTING(    0x03, "10K 60K+" )
; PORT_DIPSETTING(    0x05, "20K 60K+" )
; PORT_DIPSETTING(    0x01, "20K 70K+" )
; PORT_DIPSETTING(    0x06, "30K 70K+" )
; PORT_DIPSETTING(    0x02, "30K 80K+" )
; PORT_DIPSETTING(    0x04, "40K 100K+" )
; PORT_DIPSETTING(    0x00, DEF_STR( None ) )
; PORT_DIPNAME( 0x08, 0x08, DEF_STR( Demo_Sounds ) ) PORT_DIPLOCATION("SW2:5")
; PORT_DIPSETTING(    0x00, DEF_STR( Off ) )
; PORT_DIPSETTING(    0x08, DEF_STR( On ) )
; PORT_DIPNAME( 0x10, 0x10, DEF_STR( Difficulty ) ) PORT_DIPLOCATION("SW2:4")
; PORT_DIPSETTING(    0x10, DEF_STR( Normal ) )
; PORT_DIPSETTING(    0x00, DEF_STR( Difficult ) )
; PORT_DIPNAME( 0x20, 0x00, DEF_STR( Flip_Screen ) ) PORT_DIPLOCATION("SW2:3")
; PORT_DIPSETTING(    0x00, DEF_STR( Off ) )
; PORT_DIPSETTING(    0x20, DEF_STR( On ) )
; PORT_DIPNAME( 0xc0, 0x00, DEF_STR( Cabinet ) ) PORT_DIPLOCATION("SW2:2,1")
; PORT_DIPSETTING(    0x00, DEF_STR( Upright ) )
; PORT_DIPSETTING(    0x40, "Upright Two Players" )
; PORT_DIPSETTING(    0xc0, DEF_STR( Cocktail ) )




rom_hi_score_table_018f    = $018f   
vulgus_hi_score_018f       = $018f
son_son_hi_score_019c      = $019c
higemaru_hi_score_01a9     = $01a9
capcom_hi_score_01b6       = $01b6
exed_exes_hi_score_01c3    = $01c3
comando_hi_score_01d0      = $01d0
empty_hi_score_01dd        = $01dd

hi_score_table_ee00  = $ee00
hi_score_1st_ee00    = $ee00
hi_score_2nd_ee0d    = $ee0d
hi_score_3rd_ee1a    = $ee1a
hi_score_4th_ee27    = $ee27
hi_score_5th_ee34    = $ee34
hi_score_6th_ee41    = $ee41
hi_score_7th_ee4e    = $ee4e

timing_variable_e002 = $e002
port_state_c000_in0_e003 = $e003
sound_and_screen_orientation_c804 = $c804
background_scroll_x_c808 = $c808
background_scroll_x_c809 = $c809
background_scroll_y_c80a = $c80a
background_scroll_y_c80b = $c80b
background_scroll_x_shadow_e05b = $e05b

; PORT_STATE_C001_IN1_e004 holds the state of IN1 after a bit flip (2's complement) - see $0328
; Bit 0: player moving RIGHT
; Bit 1: player moving LEFT
; Bit 2: player moving DOWN
; Bit 3: player moving UP
; Bit 4: player SHOOT
; Bit 5: player GRENADE
port_state_c001_in1_e004 = $e004
port_state_c002_in2_e005 = $e005
port_state_dsw1_e006     = $e006
port_state_dsw2_e007     = $e007

; These names are temporary until I work out what they are for.
port_state_c001_bit0_bits_e008 = $e008
port_state_c001_bit1_bits_e009 = $e009
port_state_c001_bit2_bits_e00a = $e00a
port_state_c001_bit3_bits_e00b = $e00b
port_state_c001_bit4_bits_e00c = $e00c
port_state_c001_bit5_bits_e00d = $e00d
sound_c800 = $c800

; set to 1 if dip switches report an upright cabinet 
is_cabinet_upright_e025 = $e025
 ; set to 2 if dip switches report upright cabinet with one stick (see $012D)                  
is_single_stick_setup_e029   = $e029
    ; set to 16 if dip switches report demo sounds should be OFF (see $0133)
is_demo_sounds_on_e02a = $e02a
 ; set to 8 if Difficult difficulty in dip switches, 0 = Normal (see $0139)      
is_difficult_e02c   = $e02c
 ; number of credits inserted 
num_credits_e030    = $e030 
; temp name: set to 1 if screen is flipped on vertical axis    
is_screen_yflipped_e039 = $e039         


player_bullets_e200 = $e200

num_grenades_eda8 = $eda8
  ; the hi score seen on screen
hi_score_ee97     = $ee97
port_1_c001 = $c001
port_2_c002 = $c002
system_c000 = $c000
;
;struct PLAYER_BULLET
;{
; 0    
; 1    
; 2    
; 3 
; 4    
; 5    
; 6    
; 7    
; 8    
; 9    
; A    
; B    
; C    
; D    
; E    
; F    
; 10   
; 11   
; 12 BYTE ShotLength  
; 13   
; 14   
; 15   
; 16   
; 17   
; 18   
; 19   
; 1A   
; 1B   
; 1C   
; 1D   
; 1E   
; 1F   
;}  - sizeof(INFLIGHT_ALIEN) is 32 bytes



;
; Hardware sprite structure
;
; 

;struct SPRITE
;{
;    BYTE Code;                       ; code (animation frame) of sprite to display. 
;
;    ; NOTES ABOUT ATTR FLAGS:
;    ; Bit 0: unused
;    ; Bit 1: if set, negate X coord
;    ; Bit 2: if set, flip sprite horizontally
;    ; Bit 3: if set, flip sprite vertically
;    ; Bits 4 & 5: sprite colour select (shift right 4 times to get real value)
;    ; Bits 6 & 7: sprite bank select
;    BYTE Attr;                       ; bit flags used to determine how to display sprite
;
;    BYTE Y;                          ; Y coordinate of sprite
;    BYTE X;                          ; LSB of sprite X coordinate
;}

boot_0000:   ; [global]
0000: 3E 40       ld   a,$04
0002: 32 00 0E    ld   ($E000),a
0005: C3 A4 00    jp   startup_004a
0008: C9          ret

0010: F3          di
0011: C3 7B 20    jp   $02B7



;
; Add an 8-bit value to HL
; A = 8 bit value to add to HL
;

add_a_to_hl_0018:
0018: 85          add  a,l
0019: 6F          ld   l,a
001A: 30 01       jr   nc,$001D
001C: 24          inc  h
001D: C9          ret


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

return_byte_at_hl_plus_a_0020:
0020: 85          add  a,l
0021: 6F          ld   l,a
0022: 30 01       jr   nc,$0025
0024: 24          inc  h
0025: 7E          ld   a,(hl)
0026: C9          ret


multiply_a_by_2_add_to_hl_load_de_from_hl_0028:
0028: 87          add  a,a                   ; multiply a by 2
0029: DF          rst  $18                   ; call ADD_A_TO_HL
002A: 5E          ld   e,(hl)
002B: 23          inc  hl
002C: 56          ld   d,(hl)
002D: 23          inc  hl
002E: C9          ret


jump_0030:
0030: E1          pop  hl
0031: EF          rst  $28                   ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0032: EB          ex   de,hl
0033: E9          jp   (hl)




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

startup_004a:
004A: 31 00 1E    ld   sp,$F000			; set stack at top
004D: F3          di					; no interrupts
004E: 3E 10       ld   a,$10
0050: 32 40 8C    ld   (sound_and_screen_orientation_c804),a		; reset sound cpu & screen orientation
0053: AF          xor  a
0054: 32 80 8C    ld   (background_scroll_x_c808),a             ; set background scroll X
0057: 32 A1 8C    ld   (background_scroll_y_c80b),a             ; set background scroll Y
005A: 32 81 8C    ld   (background_scroll_x_c809),a             ; set background scroll X
005D: 32 A0 8C    ld   (background_scroll_y_c80a),a             ; set background scroll Y

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
0085: ED B0       ldir			; [video_address]

; clear background video RAM
0087: 21 00 9C    ld   hl,$D800
008A: 11 01 9C    ld   de,$D801
008D: 01 FF 21    ld   bc,$03FF
0090: 36 9E       ld   (hl),$F8
0092: ED B0       ldir			; [video_address]

; clear background colour RAM
0094: 21 00 DC    ld   hl,$DC00
0097: 11 01 DC    ld   de,$DC01
009A: 01 FF 21    ld   bc,$03FF
009D: 36 00       ld   (hl),$00
009F: ED B0       ldir			; [video_address]

; Copy hi score to RAM
00A1: 21 E9 01    ld   hl,vulgus_hi_score_018f              ; load HL with address of ROM_HI_SCORE_TABLE
00A4: E5          push hl
00A5: 11 79 EE    ld   de,hi_score_ee97              ; load DE with address of HI_SCORE 
00A8: ED A0       ldi                        ; copy top score from ROM...
00AA: ED A0       ldi
00AC: ED A0       ldi                        ; ..to current high score in RAM. 
00AE: E1          pop  hl

; Copy high score table from ROM to RAM
00AF: 11 00 EE    ld   de,hi_score_1st_ee00
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
00E2: 32 93 0E    ld   (is_screen_yflipped_e039),a
00E5: CD 76 20    call $0276

00E8: 3A 60 0E    ld   a,(port_state_dsw1_e006)
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
0123: 3A 61 0E    ld   a,(port_state_dsw2_e007)             ; read PORT_STATE_DSW2
0126: 47          ld   b,a
0127: E6 01       and  $01
0129: 32 43 0E    ld   (is_cabinet_upright_e025),a             ; set IS_CABINET_UPRIGHT
012C: 78          ld   a,b
012D: E6 20       and  $02
012F: 32 83 0E    ld   (is_single_stick_setup_e029),a             ; set IS_SINGLE_STICK_SETUP
0132: 78          ld   a,b
0133: E6 10       and  $10
0135: 32 A2 0E    ld   (is_demo_sounds_on_e02a),a             ; set DEMO_SOUNDS_ON
0138: 78          ld   a,b
0139: E6 80       and  $08
013B: 32 C2 0E    ld   (is_difficult_e02c),a             ; set IS_NORMAL_DIFFICULTY
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
0293: 32 60 0E    ld   (port_state_dsw1_e006),a             ; write to PORT_STATE_DSW1
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
02B3: 32 61 0E    ld   (port_state_dsw2_e007),a             ; write to PORT_STATE_DSW2 
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

02FA: 21 20 0E    ld   hl,timing_variable_e002              ; load HL with address of TIMING_VARIABLE
02FD: 34          inc  (hl)                  ; increment TIMING_VARIABLE
02FE: 21 B3 0E    ld   hl,$E03B
0301: 3A 40 0C    ld   a,($C004)             ; read DSW2 
0304: 07          rlca
0305: 07          rlca
0306: E6 08       and  $80
0308: 4F          ld   c,a
0309: 3A 93 0E    ld   a,(is_screen_yflipped_e039)
030C: E6 01       and  $01
030E: 28 40       jr   z,$0314
0310: 79          ld   a,c
0311: C6 08       add  a,$80
0313: 4F          ld   c,a
0314: 3A B3 0E    ld   a,($E03B)
0317: E6 F7       and  $7F
0319: 81          add  a,c
031A: 32 B3 0E    ld   ($E03B),a
031D: 3A 00 0C    ld   a,(system_c000)             ; read IN0
0320: 2F          cpl
0321: 32 21 0E    ld   (port_state_c000_in0_e003),a             ; save in PORT_STATE_C000_IN0  
0324: 3A 01 0C    ld   a,(port_1_c001)             ; read IN1
0327: 2F          cpl
0328: 32 40 0E    ld   (port_state_c001_in1_e004),a             ; save in PORT_STATE_C001_IN1_e004
032B: 3A 20 0C    ld   a,(port_2_c002)             ; read IN2
032E: 2F          cpl
032F: 32 41 0E    ld   (port_state_c002_in2_e005),a             ; save in PORT_STATE_C005

; Expand PORT_STATE_C001_IN1_e004 bits to flags
0332: 11 40 0E    ld   de,port_state_c001_in1_e004              ; load DE with address of PORT_STATE_C001_IN1_e004
0335: 21 80 0E    ld   hl,port_state_c001_bit0_bits_e008
0338: 1A          ld   a,(de)                ; read PORT_STATE_C001_IN1_e004
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


0350: 11 40 0E    ld   de,port_state_c001_in1_e004              ; load DE with address of PORT_STATE_C001_IN1_e004 
0353: 3A 93 0E    ld   a,(is_screen_yflipped_e039)             ; read IS_SCREEN_YFLIPPED flag 
0356: E6 01       and  $01                   ; test if flag is set
0358: 20 60       jr   nz,$0360              ; if flag is set, goto $03600

035A: 3A 83 0E    ld   a,(is_single_stick_setup_e029)
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


037C: 3A 21 0E    ld   a,(port_state_c000_in0_e003)             ; read PORT_STATE_C000_IN0 bits
037F: 21 96 0E    ld   hl,$E078
0382: 0F          rrca
0383: CB 16       rl   (hl)
0385: CD 73 F8    call $9E37

0388: 3A 00 0E    ld   a,($E000)
038B: E6 21       and  $03
038D: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=4]
; jump_table_038e:
	dc.w	$03c9	; $038e
	dc.w	$0400	; $0390
	dc.w	$0562	; $0392
	dc.w	$0621	; $0394

0396: 3A B2 0E    ld   a,($E03A)
0399: 32 00 8C    ld   (sound_c800),a
039C: 3A B5 0E    ld   a,(background_scroll_x_shadow_e05b)
039F: E6 01       and  $01
03A1: 32 81 8C    ld   (background_scroll_x_c809),a
03A4: 3A D4 0E    ld   a,($E05C)
03A7: 32 80 8C    ld   (background_scroll_x_c808),a
03AA: 3A B3 0E    ld   a,($E03B)
03AD: 32 40 8C    ld   (sound_and_screen_orientation_c804),a
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
03CC: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=2]
; jump_table_03cd:
	dc.w	$03d1	; $03cd
	dc.w	$03fd	; $03cf

03D1: 3A C0 0E    ld   a,(port_state_c001_bit4_bits_e00c)
03D4: A7          and  a
03D5: C2 DE 41    jp   nz,$05FC
03D8: CD 06 E0    call $0E60
03DB: 3A 20 0E    ld   a,(timing_variable_e002)
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
0407: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=6]
; jump_table_0408:
	dc.w	$0426	; $0408
	dc.w	$045e	; $040a
	dc.w	$048e	; $040c
	dc.w	$04bb	; $040e
	dc.w	$04d4	; $0410
	dc.w	$04eb	; $0412

0414: 3A 90 0E    ld   a,($E018)
0417: A7          and  a
0418: C2 16 41    jp   nz,$0570
041B: 3A 12 0E    ld   a,(num_credits_e030)
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
04FF: 3A 20 0E    ld   a,(timing_variable_e002)
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

051D: 3A 20 0E    ld   a,($E002)
0520: 47          ld   b,a
0521: E6 E1       and  $0F
0523: C0          ret  nz
0524: 11 60 00    ld   de,$0006
0527: 3A C2 0E    ld   a,(is_difficult_e02c)
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
0546: 3A 20 0E    ld   a,(timing_variable_e002)
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

0561: C9          ret
0562: 21 29 41    ld   hl,$0583
0565: E5          push hl
0566: 3A 01 0E    ld   a,($E001)
0569: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=3]
; jump_table_056a:
	dc.w	$05da	; $056a
	dc.w	$05f0	; $056c
	dc.w	$0600	; $056e

056F: 60          ld   h,b
0570: 3A 20 0E    ld   a,(timing_variable_e002)
0573: 47          ld   b,a
0574: E6 F3       and  $3F
0576: 20 50       jr   nz,$058C
0578: 11 E0 00    ld   de,$000E
057B: CB 70       bit  6,b
057D: 28 01       jr   z,$0580
057F: 14          inc  d
0580: FF          rst  $38
0581: 18 81       jr   $058C
0583: 3A 20 0E    ld   a,(timing_variable_e002)
0586: 47          ld   b,a
0587: E6 F1       and  $1F
0589: CC D8 41    call z,$059C
058C: 3A 21 0E    ld   a,(port_state_c000_in0_e003)
058F: CB 4F       bit  1,a
0591: 20 43       jr   nz,$05B8
0593: 3A 21 0E    ld   a,(port_state_c000_in0_e003)
0596: CB 47       bit  0,a
0598: C8          ret  z
0599: C3 8A 41    jp   $05A8
059C: 11 80 00    ld   de,$0008
059F: CB 68       bit  5,b
05A1: CA 92 00    jp   z,$0038
05A4: 14          inc  d
05A5: C3 92 00    jp   $0038
05A8: 3A 12 0E    ld   a,(num_credits_e030)
05AB: D6 01       sub  $01
05AD: 27          daa
05AE: 32 12 0E    ld   (num_credits_e030),a
05B1: AF          xor  a
05B2: 32 B0 0E    ld   ($E01A),a
05B5: C3 8D 41    jp   $05C9
05B8: 3A 12 0E    ld   a,(num_credits_e030)
05BB: FE 01       cp   $01
05BD: C8          ret  z
05BE: D6 20       sub  $02
05C0: 27          daa
05C1: 32 12 0E    ld   (num_credits_e030),a
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

05F0: 3A 12 0E    ld   a,(num_credits_e030)
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
0624: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=11]
; jump_table_0625:
	dc.w	$0646	; $0625
	dc.w	$06dd	; $0627
	dc.w	$0769	; $0629
	dc.w	$07cd	; $062b
	dc.w	$07fc	; $062d
	dc.w	$094c	; $062f
	dc.w	$0a6d	; $0631
	dc.w	$0ceb	; $0633
	dc.w	$0d1c	; $0635
	dc.w	$0d73	; $0637
	dc.w	$0df7	; $0639

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
06FE: 3A 8A CF    ld   a,(num_grenades_eda8)             ; read NUM_GRENADES
0701: FE 60       cp   $06
0703: 30 41       jr   nc,$070A
0705: 3E 60       ld   a,$06
0707: 32 8A CF    ld   (num_grenades_eda8),a             ; update NUM_GRENADES
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

079B: 3A 43 0E    ld   a,(is_cabinet_upright_e025)
079E: A7          and  a
079F: C0          ret  nz
07A0: 3A 91 0E    ld   a,($E019)
07A3: E6 01       and  $01
07A5: 32 93 0E    ld   (is_screen_yflipped_e039),a
07A8: C9          ret

07A9: 11 C1 00    ld   de,$000D
07AC: FF          rst  $38
07AD: 3A 20 0E    ld   a,(timing_variable_e002)
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
082F: 3A B5 0E    ld   a,(background_scroll_x_shadow_e05b)
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
097C: 32 A1 8C    ld   (background_scroll_y_c80b),a
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
0AAA: 3A 20 0E    ld   a,(timing_variable_e002)
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
0AD6: 3A B5 0E    ld   a,(background_scroll_x_shadow_e05b)
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
0B2B: 3A 20 0E    ld   a,(timing_variable_e002)
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
0B40: 3A 20 0E    ld   a,(timing_variable_e002)
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
0B69: 3A 20 0E    ld   a,(timing_variable_e002)
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


0CEB: 16 41       ld   d,$05
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
0D05: 32 A1 8C    ld   (background_scroll_y_c80b),a
0D08: C9          ret
0D09: 3A 8B CF    ld   a,($EDA9)
0D0C: E6 21       and  $03
0D0E: FE 21       cp   $03
0D10: C2 70 C1    jp   nz,$0D16
0D13: C3 2F 68    jp   $86E3
0D16: CD BB 68    call $86BB
0D19: C3 5C 68    jp   $86D4
0D1C: 3A 20 0E    ld   a,(timing_variable_e002)
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
0D69: 32 93 0E    ld   (is_screen_yflipped_e039),a
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

0DF7: 3A 20 0E    ld   a,(timing_variable_e002)
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
0E17: 21 E4 EE    ld   hl,hi_score_7th_ee4e
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

0E60: 3A 20 0E    ld   a,(timing_variable_e002)
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


0E88: 23          inc  hl
0E89: 5E          ld   e,(hl)
0E8A: 23          inc  hl
0E8B: 56          ld   d,(hl)
0E8C: ED 53 1B 0E ld   ($E0B1),de
0E90: 23          inc  hl
0E91: 22 3B 0E    ld   ($E0B3),hl
0E94: C9          ret

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

1025: DD 7E 11    ld   a,(ix+$11)
1028: E6 01       and  $01
102A: 20 4C       jr   nz,$0FF0
102C: DD 7E 31    ld   a,(ix+$13)
102F: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=11]
; jump_table_1030:
	dc.w	$142e	; $1030
	dc.w	$142e	; $1032
	dc.w	$1260	; $1034
	dc.w	$108c	; $1036
	dc.w	$10e3	; $1038
	dc.w	$1123	; $103a
	dc.w	$12a7	; $103c
	dc.w	$1260	; $103e
	dc.w	$142e	; $1040
	dc.w	$126e	; $1042
	dc.w	$1046	; $1044


1046: CD 94 31    call $1358
1049: DD CB 30 6E set  4,(ix+$12)
104D: 3A 20 0E    ld   a,(timing_variable_e002)
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
10D1: 3A 20 0E    ld   a,(timing_variable_e002)
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
1144: 3A 20 0E    ld   a,(timing_variable_e002)
1147: 21 B4 11    ld   hl,$115A
114A: CB 5F       bit  3,a
114C: 28 21       jr   z,$1151
114E: 21 D4 11    ld   hl,$115C
1151: 0E 04       ld   c,$40
1153: DD 36 F0 00 ld   (ix+$1e),$00
1157: C3 2C C9    jp   $8DC2

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
132A: 3A 20 0E    ld   a,(timing_variable_e002)
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

142E: DD 7E 51    ld   a,(ix+$15)
1431: A7          and  a
1432: CC D9 51    call z,$159D
1435: DD 35 51    dec  (ix+$15)
1438: DD 7E 50    ld   a,(ix+$14)
143B: A7          and  a
143C: 20 60       jr   nz,$1444
143E: CD 94 31    call $1358
1441: C3 95 90    jp   $1859
1444: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=8]
; jump_table_1445:
	dc.w	$143e	; $1445
	dc.w	$143e	; $1447
	dc.w	$143e	; $1449
	dc.w	$143e	; $144b
	dc.w	$1455	; $144d
	dc.w	$14c3	; $144f
	dc.w	$1556	; $1451
	dc.w	$143e	; $1453

1455: DD 7E 51    ld   a,(ix+$15)
1458: FE 80       cp   $08
145A: CC 96 50    call z,$1478
145D: CD 19 51    call $1591
1460: 0E 00       ld   c,$00
1462: 21 86 50    ld   hl,$1468
1465: C3 D4 51    jp   $155C

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
15DE: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=8]
; jump_table_15df:
	dc.w	$15ef	; $15df
	dc.w	$15f9	; $15e1
	dc.w	$1600	; $15e3
	dc.w	$160a	; $15e5
	dc.w	$1621	; $15e7
	dc.w	$162a	; $15e9
	dc.w	$1633	; $15eb
	dc.w	$163e	; $15ed

15EF: 3E 01       ld   a,$01
15F1: 32 58 0E    ld   ($E094),a
15F4: DD 36 51 01 ld   (ix+$15),$01
15F8: C9          ret
15F9: CD 8D 51    call $15C9
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
1660: 3A 20 0E    ld   a,(timing_variable_e002)
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

; not reached??
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
185F: 3A 20 0E    ld   a,(timing_variable_e002)
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

191F: CD C9 B2    call $3A8D
1922: 3A 20 0E    ld   a,(timing_variable_e002)
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
1951: 3A 20 0E    ld   a,(timing_variable_e002)
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
1969: 3A 20 0E    ld   a,(timing_variable_e002)
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

19D1: CD F6 91    call $197E
19D4: CD 8A 91    call $19A8
19D7: 11 0E 91    ld   de,$19E0
19DA: CD 88 A3    call $2B88
19DD: C3 88 A3    jp   $2B88

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
1A22: 3A 20 0E    ld   a,(timing_variable_e002)
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

1A55: DD 7E 50    ld   a,(ix+$14)
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

1B48: 3A 58 0E    ld   a,($E094)
1B4B: A7          and  a
1B4C: 28 81       jr   z,$1B57
1B4E: DD 36 50 01 ld   (ix+$14),$01
1B52: 3E 00       ld   a,$00
1B54: 32 58 0E    ld   ($E094),a
1B57: DD 7E 50    ld   a,(ix+$14)
1B5A: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=4]
; jump_table_1b5b:
	dc.w	$1b63	; $1b5b
	dc.w	$1b64	; $1b5d
	dc.w	$1b78	; $1b5f
	dc.w	$1b87	; $1b61

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


1BB3: 21 55 0E    ld   hl,$E055
1BB6: 34          inc  (hl)
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

1C50: DD E5       push ix
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
1D04: 3A 20 0E    ld   a,(timing_variable_e002)
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
1D6C: 3A 20 0E    ld   a,(timing_variable_e002)
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
1D80: DD 21 00 2E ld   ix,player_bullets_e200
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
1E96: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=5]
; jump_table_1e97:
	dc.w	$1eee	; $1e97
	dc.w	$1f0b	; $1e99
	dc.w	$1f17	; $1e9b
	dc.w	$1f17	; $1e9d
	dc.w	$1ed5	; $1e9f



1ED5: DD 36 50 00 ld   (ix+$14),$00
1ED9: DD 36 51 10 ld   (ix+$15),$10
1EDD: C9          ret
1EDE: 3A 20 0E    ld   a,(timing_variable_e002)
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

1F48: DD 4E 80    ld   c,(ix+$08)
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

203B: DD 7E 50    ld   a,(ix+$14)
203E: DD 34 50    inc  (ix+$14)
2041: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=3]
; jump_table_2042:
	dc.w	$205b	; $2042
	dc.w	$2060	; $2044
	dc.w	$2048	; $2046

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


218A: DD 7E 40    ld   a,(ix+$04)
218D: A7          and  a
218E: C0          ret  nz
218F: 3A 20 0E    ld   a,(timing_variable_e002)
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
21CF: 3A 20 0E    ld   a,(timing_variable_e002)
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
2353: 3A 20 0E    ld   a,(timing_variable_e002)
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
24AE: 3A 20 0E    ld   a,(timing_variable_e002)
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
2656: 3A 20 0E    ld   a,(timing_variable_e002)
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
26E2: 3A 20 0E    ld   a,(timing_variable_e002)
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
2755: ED 5B B5 0E ld   de,(background_scroll_x_shadow_e05b)
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
27C2: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=48]
; jump_table_27c3:
	dc.w	$298b	; $27c3
	dc.w	$29a0	; $27c5
	dc.w	$299c	; $27c7
	dc.w	$29bf	; $27c9
	dc.w	$1f48	; $27cb
	dc.w	$29cc	; $27cd
	dc.w	$2225	; $27cf
	dc.w	$289d	; $27d1
	dc.w	$29dd	; $27d3
	dc.w	$29e2	; $27d5
	dc.w	$29ea	; $27d7
	dc.w	$29fa	; $27d9
	dc.w	$289d	; $27db
	dc.w	$289d	; $27dd
	dc.w	$297e	; $27df
	dc.w	$295c	; $27e1
	dc.w	$289d	; $27e3
	dc.w	$289d	; $27e5
	dc.w	$2953	; $27e7
	dc.w	$289d	; $27e9
	dc.w	$294e	; $27eb
	dc.w	$2944	; $27ed
	dc.w	$294d	; $27ef
	dc.w	$293f	; $27f1
	dc.w	$293f	; $27f3
	dc.w	$2918	; $27f5
	dc.w	$289d	; $27f7
	dc.w	$289d	; $27f9
	dc.w	$289d	; $27fb
	dc.w	$289d	; $27fd
	dc.w	$3627	; $27ff
	dc.w	$28dc	; $2801
	dc.w	$289d	; $2803
	dc.w	$28a7	; $2805
	dc.w	$289d	; $2807
	dc.w	$2879	; $2809
	dc.w	$289e	; $280b
	dc.w	$289d	; $280d
	dc.w	$298b	; $280f
	dc.w	$2889	; $2811
	dc.w	$286c	; $2813
	dc.w	$28c0	; $2815
	dc.w	$2918	; $2817
	dc.w	$2842	; $2819
	dc.w	$2823	; $281b
	dc.w	$2823	; $281d
	dc.w	$2971	; $281f
	dc.w	$298b	; $2821

2823: CD E7 68    call $866F
2826: DD 7E 41    ld   a,(ix+$05)
2829: FE 1E       cp   $F0
282B: D2 33 82    jp   nc,$2833
282E: DD 36 00 00 ld   (ix+$00),$00
2832: C9          ret
2833: 3A 21 0F    ld   a,($E103)
2836: 47          ld   b,a
2837: 3A 20 0E    ld   a,(timing_variable_e002)
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
28DC: 3A 20 0E    ld   a,(timing_variable_e002)
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

2A3E: DD 21 00 4F ld   ix,$E500
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
2A72: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=48]
; jump_table_2a73:
	dc.w	$1bb3	; $2a73
	dc.w	$1cf4	; $2a75
	dc.w	$1d63	; $2a77
	dc.w	$1db7	; $2a79
	dc.w	$1fc5	; $2a7b
	dc.w	$20d7	; $2a7d
	dc.w	$22a9	; $2a7f
	dc.w	$2313	; $2a81
	dc.w	$2313	; $2a83
	dc.w	$2312	; $2a85
	dc.w	$2314	; $2a87
	dc.w	$25be	; $2a89
	dc.w	$2598	; $2a8b
	dc.w	$252b	; $2a8d
	dc.w	$2428	; $2a8f
	dc.w	$3a8c	; $2a91
	dc.w	$3a8c	; $2a93
	dc.w	$3a8c	; $2a95
	dc.w	$19f0	; $2a97
	dc.w	$39ac	; $2a99
	dc.w	$39ad	; $2a9b
	dc.w	$3898	; $2a9d
	dc.w	$3899	; $2a9f
	dc.w	$3823	; $2aa1
	dc.w	$37c0	; $2aa3
	dc.w	$36a7	; $2aa5
	dc.w	$3672	; $2aa7
	dc.w	$3646	; $2aa9
	dc.w	$3643	; $2aab
	dc.w	$3625	; $2aad
	dc.w	$3627	; $2aaf
	dc.w	$34ca	; $2ab1
	dc.w	$34c9	; $2ab3
	dc.w	$3178	; $2ab5
	dc.w	$313b	; $2ab7
	dc.w	$3092	; $2ab9
	dc.w	$3091	; $2abb
	dc.w	$3004	; $2abd
	dc.w	$3024	; $2abf
	dc.w	$2ea7	; $2ac1
	dc.w	$1af8	; $2ac3
	dc.w	$32c3	; $2ac5
	dc.w	$2d28	; $2ac7
	dc.w	$1898	; $2ac9
	dc.w	$199c	; $2acb
	dc.w	$19d1	; $2acd
	dc.w	$2428	; $2acf
	dc.w	$1869	; $2ad1

2AD3: CD C9 B2    call $3A8D
2AD6: DD 7E 31    ld   a,(ix+$13)
2AD9: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=48]
; jump_table_2ada
	.word	$2B3A 
	.word	$2BC9 
	.word	$2BF0 
	.word	$2C13 
	.word	$2C64 
	.word	$2C64 
	.word	$2C8C 
	.word	$2313
	.word	$2313 
	.word	$2C8D 
	.word	$2C94 
	.word	$2CB9 
	.word	$2CDE 
	.word	$2CDE 
	.word	$2CDE 
	.word	$2D1D
	.word	$2D1D 
	.word	$2D1D 
	.word	$2D1D 
	.word	$2D1D 
	.word	$2D1D 
	.word	$2D1D 
	.word	$2D1D 
	.word	$2D1D
	.word	$2D1D 
	.word	$2D1E 
	.word	$2D25 
	.word	$2D25 
	.word	$2D25 
	.word	$2D25
	.word	$2C64 
	.word	$2B3A
	.word	$2B3A 
	.word	$2B3A 
	.word	$2B3A 
	.word	$2B3A 
	.word	$2B3A
	.word	$2B3A
	.word	$2B3A
	.word	$2B3A
	.word	$2B3A
	.word	$2B3A
	.word	$2D1E
	.word	$2B3A 
	.word	$2B3A 
	.word	$2B3A 
	.word	$2CDE 
	.word	$2B3A

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

2D0D: CD 98 68    call $8698
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
2D83: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=4]
; jump_table_2d84:
	dc.w	$2d8c	; $2d84
	dc.w	$2d8c	; $2d86
	dc.w	$2dad	; $2d88
	dc.w	$2d8c	; $2d8a

2D8C: DD 56 E1    ld   d,(ix+$0f)
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
2DE9: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=7]
; jump_table_2dea:
	dc.w	$2e34	; $2dea
	dc.w	$2e14	; $2dec
	dc.w	$2e22	; $2dee
	dc.w	$2df8	; $2df0
	dc.w	$2e39	; $2df2
	dc.w	$2e14	; $2df4
	dc.w	$2e3b	; $2df6

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

2F85: DD 7E 40    ld   a,(ix+$04)
2F88: A7          and  a
2F89: 20 98       jr   nz,$2F23
2F8B: 3A 20 0E    ld   a,(timing_variable_e002)
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

3004: CD C9 B2    call $3A8D
3007: 11 10 12    ld   de,$3010
300A: CD 88 A3    call $2B88
300D: C3 88 A3    jp   $2B88

3024: 3A B0 0F    ld   a,($E11A)
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

305A: 3A 20 0E    ld   a,(timing_variable_e002)
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
3095: 3A 20 0E    ld   a,(timing_variable_e002)
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
3108: 3A 8A CF    ld   a,(num_grenades_eda8)             ; read NUM_GRENADES
310B: BA          cp   d
310C: 30 70       jr   nc,$3124
310E: 83          add  a,e
310F: 27          daa
3110: 32 8A CF    ld   (num_grenades_eda8),a             ; update NUM_GRENADES 
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
312E: 32 8A CF    ld   (num_grenades_eda8),a             ; set NUM_GRENADES
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

3178: 21 55 0E    ld   hl,$E055
317B: 34          inc  (hl)
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
3200: 3A 20 0E    ld   a,(timing_variable_e002)
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

32C3: 21 55 0E    ld   hl,$E055
32C6: 34          inc  (hl)
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

33F5: DD 70 21    ld   (ix+$03),b
33F8: DD 71 41    ld   (ix+$05),c
33FB: C9          ret

3408: DD 7E 40    ld   a,(ix+$04)
340B: A7          and  a
340C: C0          ret  nz
340D: DD 7E 50    ld   a,(ix+$14)
3410: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=4]
; jump_table_3411:
	dc.w	$3419	; $3411
	dc.w	$34a8	; $3413
	dc.w	$34b9	; $3415
	dc.w	$34c1	; $3417

3419: 3A 20 0E    ld   a,(timing_variable_e002)
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
351A: 3A 20 0E    ld   a,(timing_variable_e002)
351D: E6 01       and  $01
351F: C8          ret  z
3520: FD E5       push iy
3522: FD 21 00 2E ld   iy,player_bullets_e200
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

35A7: DD 7E 41    ld   a,(ix+$05)
35AA: FE 12       cp   $30
35AC: D8          ret  c
35AD: FE 1E       cp   $F0
35AF: D0          ret  nc
35B0: 3A 20 0E    ld   a,(timing_variable_e002)
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


3672: CD C9 B2    call $3A8D
3675: 11 F6 72    ld   de,$367E
3678: CD 88 A3    call $2B88
367B: C3 88 A3    jp   $2B88

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
36B5: 3A 20 0E    ld   a,(timing_variable_e002)
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

3768: E1          pop  hl		; [stack_pop]
3769: C3 6B B2    jp   $3AA7


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
3AD0: 3A 21 0E    ld   a,(port_state_c000_in0_e003)
3AD3: 32 B3 0E    ld   ($E03B),a
3AD6: 3A 60 0E    ld   a,(port_state_dsw1_e006)
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
3B15: 3A 61 0E    ld   a,(port_state_dsw2_e007)
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


3D8A: 21 D2 F2    ld   hl,$3E3C
3D8D: 06 30       ld   b,$12
3D8F: CD 6C B3    call $3BC6
3D92: 10 BF       djnz $3D8F
3D94: 3A 60 0E    ld   a,(port_state_dsw1_e006)
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
3DA9: 3A 61 0E    ld   a,(port_state_dsw2_e007)
3DAC: 4F          ld   c,a
3DAD: 21 13 3C    ld   hl,$D231
3DB0: 06 80       ld   b,$08
3DB2: E6 01       and  $01
3DB4: 77          ld   (hl),a
3DB5: 19          add  hl,de
3DB6: CB 09       rrc  c
3DB8: 79          ld   a,c
3DB9: 10 7F       djnz $3DB2
3DBB: 3A 40 0E    ld   a,(port_state_c001_in1_e004)
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
3DDA: 3A 41 0E    ld   a,(port_state_c002_in2_e005)
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
3DF9: 3A 21 0E    ld   a,(port_state_c000_in0_e003)
3DFC: 47          ld   b,a
3DFD: E6 01       and  $01
3DFF: 21 89 3D    ld   hl,$D389
3E02: 77          ld   (hl),a
3E03: 2B          dec  hl
3E04: CB 08       rrc  b
3E06: 78          ld   a,b
3E07: E6 01       and  $01
3E09: 77          ld   (hl),a
3E0A: 3A 21 0E    ld   a,(port_state_c000_in0_e003)
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
3F23: 3A C0 0E    ld   a,(port_state_c001_bit4_bits_e00c)
3F26: E6 61       and  $07
3F28: FE 01       cp   $01
3F2A: C0          ret  nz
3F2B: 7E          ld   a,(hl)
3F2C: 32 B2 0E    ld   ($E03A),a
3F2F: C9          ret
3F30: 3A 80 0E    ld   a,(port_state_c001_bit0_bits_e008)
3F33: E6 61       and  $07
3F35: FE 01       cp   $01
3F37: 28 E0       jr   z,$3F47
3F39: 3A 81 0E    ld   a,(port_state_c001_bit1_bits_e009)
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
6CB7: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=4]
; jump_table_6cb8:
	dc.w	$6cc0	; $6cb8
	dc.w	$6cc6	; $6cba
	dc.w	$6cca	; $6cbc
	dc.w	$6cd6	; $6cbe

6CC0: 50          ld   d,b
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

6D63: 7E          ld   a,(hl)
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
6D81: 3A A1 0E    ld   a,(port_state_c001_bit3_bits_e00b)
6D84: E6 01       and  $01
6D86: 28 21       jr   z,$6D8B
6D88: FD 34 21    inc  (iy+$03)
6D8B: 3A A0 0E    ld   a,(port_state_c001_bit2_bits_e00a)
6D8E: E6 01       and  $01
6D90: 28 21       jr   z,$6D95
6D92: FD 35 21    dec  (iy+$03)
6D95: 3A 81 0E    ld   a,(port_state_c001_bit1_bits_e009)
6D98: E6 01       and  $01
6D9A: 28 21       jr   z,$6D9F
6D9C: FD 35 20    dec  (iy+$02)
6D9F: 3A 80 0E    ld   a,(port_state_c001_bit0_bits_e008)
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
8028: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=15]
; jump_table_8029:
	dc.w	$81bb	; $8029
	dc.w	$81c6	; $802b
	dc.w	$81d1	; $802d
	dc.w	$825d	; $802f
	dc.w	$8260	; $8031
	dc.w	$851c	; $8033
	dc.w	$9f8b	; $8035
	dc.w	$81dc	; $8037
	dc.w	$8607	; $8039
	dc.w	$81a2	; $803b
	dc.w	$8183	; $803d
	dc.w	$8130	; $803f
	dc.w	$af28	; $8041
	dc.w	$8076	; $8043
	dc.w	$8047	; $8045

8047: 3A 62 0E    ld   a,($E026)
804A: A7          and  a
804B: C8          ret  z
804C: 21 CA 29    ld   hl,$83AC
804F: CD C7 D8    call print_text_9c6d
8052: 3A 62 0E    ld   a,($E026)
8055: E6 E1       and  $0F
8057: 32 A3 3C    ld   ($D22B),a
805A: 3A 82 0E    ld   a,($E028)
805D: CB 67       bit  4,a
805F: 20 E1       jr   nz,$8070
8061: 21 2D 29    ld   hl,$83C3
8064: CD C7 D8    call print_text_9c6d
8067: 3A 82 0E    ld   a,($E028)
806A: E6 E1       and  $0F
806C: 32 83 3C    ld   ($D229),a
806F: C9          ret
8070: 21 BD 29    ld   hl,$83DB
8073: CD C7 D8    call print_text_9c6d
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
814C: 3A 8A CF    ld   a,(num_grenades_eda8)             ; read NUM_GRENADES
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
81C3: CD C7 D8    call print_text_9c6d
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
81F6: DD 21 00 EE ld   ix,hi_score_1st_ee00
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


825D: C3 DC D8    jp   $9CDC
8260: 3A 90 0E    ld   a,($E018)
8263: A7          and  a
8264: C0          ret  nz
8265: 21 CC 28    ld   hl,$82CC
8268: CD C7 D8    call $9C6D
826B: 3A 12 0E    ld   a,(num_credits_e030)
826E: 21 08 3D    ld   hl,$D380
8271: 0E 00       ld   c,$00
8273: C3 D8 D8    jp   $9C9C


82CF:  43 52 45 44 49 54 20 30 30 40 9F D0 06 31 55 50  ;CREDIT 00@...1UP
82DF:  40 3F D3 06 32 55 50 40 9F D1 06 54 4F 50 5F 53  ;@?..2UP@...TOP_S
82EF:  43 4F 52 45 40 33 D1 01 52 41 4E 4B 49 4E 47 20  ;CORE@3..RANKING 
82FF:  42 45 53 54 20 37 40 A8 D0 00 53 45 4C 45 43 54  ;BEST 7@...SELECT
830F:  20 31 20 4F 52 20 32 20 50 4C 41 59 45 52 53 40  ; 1 OR 2 PLAYERS@
831F:  4D D1 01 49 4E 53 45 52 54 20 43 4F 49 4E 40 A0  ;M..INSERT COIN@.
832F:  D2 00 46 52 45 45 20 50 4C 41 59 40 EC D0 00 50  ;..FREE PLAY@...P
833F:  55 53 48 20 53 54 41 52 54 20 42 55 54 54 4F 4E  ;USH START BUTTON
834F:  20 40 EA D0 00 4F 4E 45 20 4F 52 20 54 57 4F 20  ; @...ONE OR TWO 
835F:  50 4C 41 59 45 52 53 40 EA D0 00 20 4F 4E 45 20  ;PLAYERS@... ONE 
836F:  50 4C 41 59 45 52 20 4F 4E 4C 59 20 40 8F D1 00  ;PLAYER ONLY @...
837F:  50 4C 41 59 45 52 20 31 40 8F D1 00 50 4C 41 59  ;PLAYER 1@...PLAY
838F:  45 52 20 32 40 8D D1 00 20 52 45 41 44 59 20 40  ;ER 2@... READY @
839F:  8D D1 00 47 41 4D 45 20 4F 56 45 52 40 EB D0 00  ;...GAME OVER@...
83AF:  31 53 54 20 42 4F 4E 55 53 20 31 30 30 30 30 20  ;1ST BONUS 10000 
83BF:  50 54 53 40 E9 D0 00 41 4E 44 20 45 56 45 52 59  ;PTS@...AND EVERY
83CF:  20 31 30 30 30 30 30 20 50 54 53 40 E9 D0 00 41  ; 100000 PTS@...A
83DF:  4E 44 20 45 56 45 52 59 20 35 30 30 30 30 20 50  ;ND EVERY 50000 P
83EF:  54 53 40 A3 D1 05 43 41 50 43 4F 4D 40 22 D1 05  ;TS@...CAPCOM@"..
83FF:  43 4F 50 59 52 49 47 48 54 20 31 39 38 35 40 C1  ;COPYRIGHT 1985@.
840F:  D0 05 41 4C 4C 20 52 49 47 48 54 53 20 52 45 53  ;..ALL RIGHTS RES
841F:  45 52 56 45 44 40 F5 D1 00 50 4C 41 59 45 52 20  ;ERVED@...PLAYER 
842F:  40 4D D1 02 49 4E 53 45 52 54 20 43 4F 49 4E 40  ;@M..INSERT COIN@
843F:  B1 D0 00 31 53 54 40 AF D0 00 32 4E 44 40 AD D0  ;...1ST@...2ND@..
844F:  00 33 52 44 40 AB D0 00 34 54 48 40 A9 D0 00 35  ;.3RD@...4TH@...5
845F:  54 48 40 A7 D0 00 36 54 48 40 A5 D0 00 37 54 48  ;TH@...6TH@...7TH
846F:  40 E6 D2 40 67 68 69 40 E5 D2 40 77 78 79 40 00  ;@..@ghi@..@wxy@.
847F:  D0 00 40 7C D0 01 54 49 4D 45 52 20 20 20 40 79  ;..@|..TIMER   @y
848F:  D1 05 2E 2E 2E 2E 2E 2E 2E 2E 2E 2E 7E 40 00 D0  ;............~@..
849F:  00 40 88 D0 40 6A 6B 6C 6D 6E 6F 40 87 D0 40 7A  ;.@..@jklmno@..@z
84AF:  7B 7C 7D 7E 7F 40 40 96 D0 00 20 20 20 20 20 43  ;{|}~.@@...     C
84BF:  4F 4E 47 52 41 54 55 4C 41 54 49 4F 4E 40 94 D0  ;ONGRATULATION@..
84CF:  00 59 4F 55 52 20 46 49 52 53 54 20 44 55 54 59  ;.YOUR FIRST DUTY
84DF:  20 46 49 4E 49 53 48 45 44 40 96 D0 00 20 20 20  ; FINISHED@...   
84EF:  20 20 43 4F 4E 47 52 41 54 55 4C 41 54 49 4F 4E  ;  CONGRATULATION
84FF:  40 94 D0 00 59 4F 55 52 20 45 56 45 52 59 20 44  ;@...YOUR EVERY D
850F:  55 54 59 20 46 49 4E 49 53 48 45 44 40 B2 00 E0  ;UTY FINISHED@...

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
855E: 11 79 EE    ld   de,hi_score_ee97
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
857A: 11 79 EE    ld   de,hi_score_ee97
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

; not reached??
870C: 21 40 8C    ld   hl,sound_and_screen_orientation_c804
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
87C1: 3A 20 0E    ld   a,(timing_variable_e002)
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

883C: FD 21 9C FE ld   iy,$FED8
8840: 3A 20 0E    ld   a,(timing_variable_e002)
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


88A6: DD 21 00 0F ld   ix,$E100
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


8B3B: DD CB 31 F6 bit  7,(ix+$13)
8B3F: C0          ret  nz
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
8E52: 21 40 0E    ld   hl,port_state_c001_in1_e004
8E55: 3A 91 0E    ld   a,($E019)
8E58: E6 01       and  $01
8E5A: 28 E0       jr   z,$8E6A
8E5C: 3A 93 0E    ld   a,(is_screen_yflipped_e039)
8E5F: E6 01       and  $01
8E61: 20 60       jr   nz,$8E69
8E63: 3A 83 0E    ld   a,(is_single_stick_setup_e029)
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

8E9A: DD 21 00 2E ld   ix,player_bullets_e200
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
9086: 3A 20 0E    ld   a,(timing_variable_e002)
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

92C7: 32 D8 0E    ld   ($E09C),a
92CA: 3A 00 0F    ld   a,($E100)
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
92E1: 3A C1 0E    ld   a,(port_state_c001_bit5_bits_e00d)
92E4: E6 61       and  $07
92E6: C8          ret  z
92E7: FE 01       cp   $01
92E9: C0          ret  nz
92EA: 3A 70 0F    ld   a,($E116)
92ED: A7          and  a
92EE: C0          ret  nz
92EF: 3A 8A CF    ld   a,(num_grenades_eda8)             ; read NUM_GRENADES
92F2: A7          and  a
92F3: C8          ret  z
92F4: 3D          dec  a
92F5: 27          daa
92F6: 32 8A CF    ld   (num_grenades_eda8),a             ; update NUM_GRENADES 
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
933A: 3A C0 0E    ld   a,(port_state_c001_bit4_bits_e00c)
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


936F: DD 21 00 2E ld   ix,player_bullets_e200
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

94FA: 3A F9 0E    ld   a,($E09F)
94FD: A7          and  a
94FE: 20 61       jr   nz,$9507
9500: 3A 9E 0E    ld   a,($E0F8)
9503: A7          and  a
9504: CA 81 78    jp   z,$9609
9507: DD 2A 78 0E ld   ix,($E096)
950B: DD 66 01    ld   h,(ix+$01)
950E: DD 6E 00    ld   l,(ix+$00)
9511: ED 5B B5 0E ld   de,(background_scroll_x_shadow_e05b)
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
95C4: 3A 20 0E    ld   a,(timing_variable_e002)
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
9625: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=3]
; jump_table_9626:
	dc.w	$962c	; $9626
	dc.w	$9668	; $9628
	dc.w	$96cb	; $962a

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

9776: 3A 20 0E    ld   a,(timing_variable_e002)
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

982F: E5          push hl
9830: D5          push de
9831: C5          push bc
9832: 3A 0C EE    ld   a,($EEC0)
9835: 47          ld   b,a
9836: 3A 20 0E    ld   a,(timing_variable_e002)
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
988D: DD 21 00 2E ld   ix,player_bullets_e200
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
995D: DD 21 00 2E ld   ix,player_bullets_e200
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

9A20: 3A 81 0E    ld   a,(port_state_c001_bit1_bits_e009)
9A23: E6 01       and  $01
9A25: 20 80       jr   nz,$9A2F
9A27: 3A 80 0E    ld   a,(port_state_c001_bit0_bits_e008)
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

9AAE: 3A A1 0E    ld   a,(port_state_c001_bit3_bits_e00b)
9AB1: E6 01       and  $01
9AB3: 20 80       jr   nz,$9ABD
9AB5: 3A A0 0E    ld   a,(port_state_c001_bit2_bits_e00a)
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

9ADB: 21 C0 0E    ld   hl,port_state_c001_bit4_bits_e00c
9ADE: 3A 91 0E    ld   a,($E019)
9AE1: E6 01       and  $01
9AE3: 28 21       jr   z,$9AE8
9AE5: 21 50 0E    ld   hl,$E014
9AE8: 7E          ld   a,(hl)
9AE9: E6 61       and  $07
9AEB: FE 01       cp   $01
9AED: C0          ret  nz
9AEE: DD 21 00 2E ld   ix,player_bullets_e200
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

9B3F: DD 21 00 2E ld   ix,player_bullets_e200
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


print_text_9c6d:
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
9CEC: 11 79 EE    ld   de,hi_score_ee97
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
9D58: 3A 80 0E    ld   a,(port_state_c001_bit0_bits_e008)
9D5B: E6 61       and  $07
9D5D: FE 01       cp   $01
9D5F: 28 D0       jr   z,$9D7D
9D61: 3A 81 0E    ld   a,(port_state_c001_bit1_bits_e009)
9D64: E6 61       and  $07
9D66: FE 01       cp   $01
9D68: 28 90       jr   z,$9D82
9D6A: 3A A1 0E    ld   a,(port_state_c001_bit3_bits_e00b)
9D6D: E6 61       and  $07
9D6F: FE 01       cp   $01
9D71: 28 50       jr   z,$9D87
9D73: 3A A0 0E    ld   a,(port_state_c001_bit2_bits_e00a)
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
9DD3: 3A 80 0E    ld   a,(port_state_c001_bit0_bits_e008)
9DD6: E6 61       and  $07
9DD8: FE 21       cp   $03
9DDA: 28 E1       jr   z,$9DEB
9DDC: 3A 81 0E    ld   a,(port_state_c001_bit1_bits_e009)
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
9DF3: 3A A1 0E    ld   a,(port_state_c001_bit3_bits_e00b)
9DF6: E6 61       and  $07
9DF8: FE 21       cp   $03
9DFA: 28 10       jr   z,$9E0C
9DFC: 3A A0 0E    ld   a,(port_state_c001_bit2_bits_e00a)
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
9E49: 3A 21 0E    ld   a,(port_state_c000_in0_e003)
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
9E62: 3A 21 0E    ld   a,(port_state_c000_in0_e003)
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
9EE0: 3A 12 0E    ld   a,(num_credits_e030)
9EE3: FE 99       cp   $99
9EE5: D0          ret  nc
9EE6: 81          add  a,c
9EE7: 27          daa
9EE8: 32 12 0E    ld   (num_credits_e030),a
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
9F48: 32 B5 0E    ld   (background_scroll_x_shadow_e05b),a
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
9F73: 3A B5 0E    ld   a,(background_scroll_x_shadow_e05b)
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
9FB9: 3A 20 0E    ld   a,(timing_variable_e002)
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
9FD7: 3A B5 0E    ld   a,(background_scroll_x_shadow_e05b)
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
9FF7: 3A C2 0E    ld   a,(is_difficult_e02c)
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

A318: FD 2A F4 0E ld   iy,($E05E)
A31C: 3A B5 0E    ld   a,(background_scroll_x_shadow_e05b)
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
A61E: 3A B5 0E    ld   a,(background_scroll_x_shadow_e05b)
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
A670: 32 B5 0E    ld   (background_scroll_x_shadow_e05b),a
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
A8D6: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=13]
; jump_table_a8d7:
	dc.w	$a8f1	; $a8d7
	dc.w	$a8f4	; $a8d9
	dc.w	$a8f4	; $a8db
	dc.w	$a8f4	; $a8dd
	dc.w	$a8f4	; $a8df
	dc.w	$a8f4	; $a8e1
	dc.w	$a8f4	; $a8e3
	dc.w	$a8f4	; $a8e5
	dc.w	$a8f4	; $a8e7
	dc.w	$a8f4	; $a8e9
	dc.w	$a8f4	; $a8eb
	dc.w	$a8f4	; $a8ed
	dc.w	$a8f5	; $a8ef

A8F1: C3 64 AA    jp   $AA46
A8F4: C9          ret
A8F5: C3 64 AA    jp   $AA46
A8F8: C9          ret
A8F9: DD 7E 50    ld   a,(ix+$14)
A8FC: DD 34 50    inc  (ix+$14)
A8FF: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=13]
; jump_table_a900:
	dc.w	$a91a	; $a900
	dc.w	$a91d	; $a902
	dc.w	$a92c	; $a904
	dc.w	$a92f	; $a906
	dc.w	$a955	; $a908
	dc.w	$a958	; $a90a
	dc.w	$a95e	; $a90c
	dc.w	$a972	; $a90e
	dc.w	$a975	; $a910
	dc.w	$a978	; $a912
	dc.w	$a97b	; $a914
	dc.w	$a97e	; $a916
	dc.w	$a981	; $a918

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
AA2E: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=7]
; jump_table_aa2f:
	dc.w	$aa3d	; $aa2f
	dc.w	$aa41	; $aa31
	dc.w	$aa41	; $aa33
	dc.w	$aa41	; $aa35
	dc.w	$aa41	; $aa37
	dc.w	$aa41	; $aa39
	dc.w	$aa42	; $aa3b

AA3D: CD 64 AA    call $AA46
AA40: C9          ret
AA41: C9          ret
AA42: CD 64 AA    call $AA46
AA45: C9          ret
AA46: DD 66 61    ld   h,(ix+$07)
AA49: DD 6E 80    ld   l,(ix+$08)
AA4C: 3A 20 0E    ld   a,(timing_variable_e002)
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
AA8A: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=6]
; jump_table_aa8b:
	dc.w	$aa97	; $aa8b
	dc.w	$aaa9	; $aa8d
	dc.w	$aabb	; $aa8f
	dc.w	$aac1	; $aa91
	dc.w	$aac7	; $aa93
	dc.w	$aad9	; $aa95

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

AD26: 21 B0 FE    ld   hl,$FE1A
AD29: 11 40 00    ld   de,$0004
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
AD7B: F7          rst  $30    ; [jump_to_jump_table] [nb_entries=4]
; jump_table_ad7c:
	dc.w	$ad84	; $ad7c
	dc.w	$ada3	; $ad7e
	dc.w	$ae08	; $ad80
	dc.w	$ae32	; $ad82

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

AE81: DD 36 00 00 ld   (ix+$00),$00
AE85: FD 36 20 00 ld   (iy+$02),$00
AE89: FD 36 60 00 ld   (iy+$06),$00
AE8D: FD 36 A0 00 ld   (iy+$0a),$00
AE91: CD 60 89    call $8906
AE94: C9          ret
AE95: 3A 20 0E    ld   a,(timing_variable_e002)
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
AF28: DD 21 00 2E ld   ix,player_bullets_e200
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
