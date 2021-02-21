//  HKU Games & Interactie heidag 19-02-2021 C64 code dump
//
//  N.B. This is the first program I've written for C64 in assembler language, for your reading pleasure 
//  I've documented the code and considerations I've made along the way of learning to program the Commodore 64. 
//
//       Compile using KickAssembler v5.19 by Mads Nielsen

.const SCREEN_RAM = $0400         // SCREEN RAM is stored at $C000 - $07FF if we used VIC-II bank #3
.const COLOR_RAM = $D800          // COLOR RAM is stored at $D800 - $DBFF

.const KLA_CHARS = $3f40          // Address where characters are stored in the HKU logo PRG (Koala img)
.const KLA_COLORS = $4328         // Address where colors are stored in the HKU logo PRG (Koala img)

.var music = LoadSid("Housy.sid") // Please load yout own SID file here

// The first 256 bytes ($0000 - $00FF) is known as the zero-page, all addresses except $0001 and $0002 can 
// safely be used in an application and afford increased execution time because memory locations fit in one byte.


BasicUpstart2(main)               // Kick Assembler macro that inserts the sys-line into the program

main:
// Since twp effects of this demo utilize character-mode graphics the obvious VIC-II bank choices are 
// bank #0 and bank #3 because those feature character-generator ROM aat $1000 and $9000. Personally I'm not 
// familiar enough with C64 programming to have a preference for one bank over another. I'm just going with 
// the default VIC-II bank 0 which affords 16K ranging from $0000 - $3FFF.

  lda #$00                        // #$00 is the color black
  sta $D020                       // $D020 is the border color VIC-II address
  sta $D021                       // $D021 is the background color VIC-11 address

  ldx #$00
  ldy #$00
  lda #music.startSong - 1        // Set the default (stating) song
  jsr music.init                  // Kick Assembler script

  sei                             // Disable interrupt so we can bank out ROM and setup IEQ handler

  lda #<IRQ                       // Get low-byte of IRQ handler address
  sta $0314                       // Set interrupt vector
  lda #>IRQ                       // Get high-byte of IEQ handler address
  sta $0315                       // Set interrupt vector
  asl $D019                       // Clear interrupt flag
  lda #%01111011                  // Enable all interrupt controls except TOD alarm
  sta $DC0D                       // Store in the interrupt control register
  lda #%10000001                  // Toggle raster interrupt
  sta $D01A                       // Store in the other intterupt control register
  lda #$80
  sta $d012                       // Set scanline to 128 on which to trigger the interrupt

  cli                             // Enable interrupt

// The splash screen is a multicolor bitmap effect that basically renders a full-screen Koala exported image.
// It requires the VIC-II to read the bitmap data at $2000 and screen memory at $0400. The part below copies 
// character and color data from the exported HKU image to the appropriate locations in memory so that the 
// VIC-II can access them.

prepare_HKU:
  ldx #$00
!:
  lda KLA_CHARS,  x
  sta SCREEN_RAM, x
  lda KLA_CHARS   + $100, x
  sta SCREEN_RAM  + $100, x
  lda KLA_CHARS   + $200, x
  sta SCREEN_RAM  + $200, x
  lda KLA_CHARS   + $300, x
  sta SCREEN_RAM  + $300, x       // Copy 1000 HKU PRG characters to SCREEN_RAM
  lda KLA_COLORS, x
  sta COLOR_RAM,  x
  lda KLA_COLORS  + $100, x
  sta COLOR_RAM   + $100, x
  lda KLA_COLORS  + $200, x
  sta COLOR_RAM   + $200, x
  lda KLA_COLORS  + $300, x
  sta COLOR_RAM   + $300, x       // Copy 1000 HKU PRG colors to COLOR_RAM
  inx
  bne !-                          // When ldx overflows the zero flag is set (so after 256 iterations)

// Now that the bitmap and color data has been copied the VIC-II can be pointed to the appropriate memory
// locations by configuring the memory setup register and sceen control registers.

start_HKU:
  lda #%00011000                  // Toggle SCREEN_RAM at $0400, bitmap at $2000
  sta $D018                       // Memory setup register points to where graphics data are located  
 
  lda #%00111000                  // Toggle 25 rows, screen on, bitmap mode
  sta $D011                       // Screen control register #1, e.g. for toggling bitmap or character-mode

  lda #%10111011                  // Toggle 40 columns, multicolor mode, default bits
  sta $D016                       // Screen control register #2, e.g. for toggling multicolor mode


main_loop:

  lda #$A0                        // Kind of arbitrary value, really
!waitvblank: 
  cmp $D012                       // Compare with the current raster line position in $D012 
  bne !waitvblank-                // Note: this is a temporary solution, should be handled by IRQ

  jmp main_loop  
  rts                             // enf-of-program

IRQ:
  asl $D019                       // Acknowledge interrupt by clearing the interrupt flag
  jsr music.play                  // Tick SID player
  pla                             
  tay
  pla
  tax
  pla                             // Pull registers and accumulator from stack
  rti

* = $1FFE "Bitmap"                // -2 bytes offset to clip off the header
.import binary "hku.kla"

* = $F000 "Characters"

* = music.location "Music"        
.fill music.size, music.getData(i)// Kick Assembler function to store SID module data in memory

// References:
// - https://codebase64.org/doku.php?id=base:vicii_memory_organizing
// - https://sta.c64.org/cbm64mem.html
// - http://www.antimon.org/code/Linus/
// - http://www.theweb.dk/KickAssembler/webhelp/content/ch12s03.html
