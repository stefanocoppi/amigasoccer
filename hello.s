; la prima copperlist

; costanti
ExecBase     EQU $4
Disable      EQU -$78
Enable       EQU -$7e
OpenLibrary  EQU -$198
CloseLibrary EQU -$19e
COP1LC       EQU $dff080
COPJMP1      EQU $dff088

  SECTION    codice,CODE 

inizio:
  move.l     ExecBase,a6
  jsr        Disable(a6)                                               ; fermiamo il multitasking
  lea        gfx_name,a1                                               ; nome della libreria da aprire in a1
  jsr        OpenLibrary(a6)                                           ; apriamo la graphics.library
  move.l     d0,gfx_base                                               ; salviamo l'indirizzo base della graphics.library
  move.l     d0,a6
  move.l     $26(a6),old_cop                                           ; salviamo l'indirizzo della copperlist di sistema
  bsr        init_bplpointers                                          ; inizializzamo i bplpointer per puntare alla nostra immagine del campo
  move.l     #copperlist,COP1LC                                        ; puntiamo la nostra copperlist
  move.w     d0,COPJMP1                                                ; facciamo partire la copperlist
  move.w     #0,$dff1fc                                                ; FMODE - Disattiva l’AGA
  move.w     #$c00,$dff106                                             ; BPLCON3 - Disattiva l’AGA
waitmouse:
  btst       #6,$bfe001                                                ; tasto sinistro del mouse premuto?
  bne        waitmouse                                                 ; se no, torna a waitmouse

  move.l     old_cop,COP1LC                                            ; puntiamo la copperlist di sistema
  move.w     d0,COPJMP1                                                ; facciamo partire la copperlist di sistema

  move.l     ExecBase,a6
  jsr        Enable(a6)                                                ; riabilitiamo il multitasking
  move.l     gfx_base,a1                                               ; indirizzo base della graphics.library in a1
  jsr        CloseLibrary(a6)                                          ; chiudiamo la graphics.library

  rts


init_bplpointers:
  move.l     #pitch,d0                                                 ; indirizzo dell'immagine da visualizzare in d0
  lea        bplpointers,a1                                            ; puntatori ai bitplane in a1
  moveq      #3,d1                                                     ; numero di piani - 1
.loop:
  move.w     d0,6(a1)                                                  ; copia la parte bassa dell'indirizzo dell'immagine nella parte bassa del bplpointer
  swap       d0                                                        ; scambia word alta e bassa dell'indirizzo dell'immagine
  move.w     d0,2(a1)                                                  ; copia la parte alta dell'indirizzo dell'immagine nel bplpointer
  swap       d0                                                        ; riporta d0 alla condizione iniziale
  add.l      #84*880,d0                                                ; punta al bitplane successivo
  add.l      #8,a1                                                     ; punta al bplpointer successivo
  dbra       d1,.loop                                                  ; ripete il loop per tutti i piani
  rts 


; variabili

gfx_name:
  dc.b       "graphics.library",0,0
gfx_base:
  dc.l       0                                                         ; indirizzo base della graphics.library
old_cop:
  dc.l       0                                                         ; indirizzo della copperlist di sistema

; dati grafici

  SECTION    grafica,DATA_C                                            ; segmento caricato in CHIP RAM

copperlist:  
  dc.w       $8e,$2c81                                                 ; DIWSTART
  dc.w       $90,$2cc1                                                 ; DIWSTOP
  dc.w       $92,$0038                                                 ; DDFSTART
  dc.w       $94,$00d0                                                 ; DDFSTOP
  dc.w       $102,0                                                    ; BPLCON1
  dc.w       $104,0                                                    ; BPLCON2
  dc.w       $108,44                                                   ; BPL1MOD  modulo = (672-320) / 8 = 44
  dc.w       $10a,44                                                   ; BPL2MOD

  dc.w       $100,$4200                                                ; BPLCON0 3 bitplane
 

  ; palette
  dc.w       $0180,$0111,$0182,$0350,$0184,$0620,$0186,$0554
  dc.w       $0188,$000F,$018A,$046B,$018C,$00E0,$018E,$0690
  dc.w       $0190,$009F,$0192,$0B40,$0194,$0E00,$0196,$0F60
  dc.w       $0198,$0990,$019A,$0FF0,$019C,$0999,$019E,$0EEE

bplpointers:
  dc.w       $e0,$0000,$e2,$0000                                       ; BPL0PT
  dc.w       $e4,$0000,$e6,$0000                                       ; BPL1PT
  dc.w       $e8,$0000,$ea,$0000                                       ; BPL2PT
  dc.w       $ec,$0000,$ee,$0000                                       ; BPL3PT

  ; azzera i puntatori agli sprite
  dc.w       $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000
  dc.w       $12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
  dc.w       $134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
  dc.w       $13e,$0000

  dc.w       $ffff,$fffe                                               ; fine copperlist


pitch:
  incbin     "pitch1.raw"                                              ; immagine del campo 672 x 880, 4 bpp

  END 