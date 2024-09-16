; la prima copperlist

             incdir     "include"
             include    "hw.i"

; costanti
ExecBase         EQU $4
Disable          EQU -$78
Enable           EQU -$7e
OpenLibrary      EQU -$198
CloseLibrary     EQU -$19e

                     ;5432109876543210
DMASET           EQU %1000001111000000                                            ; copper,bitplane,blitter DMA
N_PLANES         EQU 4                                                            ; numero di bitplanes
PITCH_WIDTH      EQU 640
PITCH_HEIGHT     EQU 817
PLAYFIELD_WIDTH  EQU 352
PLAYFIELD_HEIGHT EQU 256
PITCH_PLANE_SIZE EQU (PITCH_WIDTH/8)*PITCH_HEIGHT
PITCH_ROW_SIZE   EQU (PITCH_WIDTH/8)
PLF_PLANE_SIZE   EQU (PLAYFIELD_WIDTH/8)*PLAYFIELD_HEIGHT
CAMERA_YMAX      EQU PITCH_HEIGHT-PLAYFIELD_HEIGHT
CAMERA_XMAX      EQU PITCH_WIDTH-PLAYFIELD_WIDTH
CAMERA_SPEED     EQU 1

             SECTION    codice,CODE 

start:
             move.l     ExecBase,a6
             jsr        Disable(a6)                                               ; fermiamo il multitasking
             lea        gfx_name,a1                                               ; nome della libreria da aprire in a1
             jsr        OpenLibrary(a6)                                           ; apriamo la graphics.library
             move.l     d0,gfx_base                                               ; salviamo l'indirizzo base della graphics.library
             move.l     d0,a6
             move.l     $26(a6),old_cop                                           ; salviamo l'indirizzo della copperlist di sistema
             ;bsr        init_bplpointers                                          ; inizializzamo i bplpointer per puntare alla nostra immagine del campo
             lea        CUSTOM,a5
          
             move.w     #DMASET,DMACON(a5)

             move.l     #copperlist,COP1LC(a5)                                    ; puntiamo la nostra copperlist
             move.w     d0,COPJMP1(a5)                                            ; facciamo partire la copperlist
             move.w     #0,$dff1fc                                                ; FMODE - Disattiva l’AGA
             move.w     #$c00,$dff106                                             ; BPLCON3 - Disattiva l’AGA
             move.w     #$11,$10c(a5)

mainloop:
             move.l     #$1ff00,d1
             move.l     #$13000,d2                                                ; linea da aspettare: $130 = 304
wait:
             move.l     VPOSR(a5),d0
             and.l      d1,d0
             cmp.l      d2,d0
             bne.s      wait

             bsr        swap_buffers
             bsr        read_joy
             bsr        draw_pitch

             btst       #6,$bfe001                                                ; tasto sinistro del mouse premuto?
             bne        mainloop                                                  ; se no, torna a waitline

             move.l     old_cop,COP1LC(a5)                                        ; puntiamo la copperlist di sistema
             move.w     d0,COPJMP1(a5)                                            ; facciamo partire la copperlist di sistema

             move.l     ExecBase,a6
             jsr        Enable(a6)                                                ; riabilitiamo il multitasking
             move.l     gfx_base,a1                                               ; indirizzo base della graphics.library in a1
             jsr        CloseLibrary(a6)                                          ; chiudiamo la graphics.library

             rts


init_bplpointers:
             move.l     #playfield1,d0                                            ; indirizzo dell'immagine da visualizzare in d0
             lea        bplpointers,a1                                            ; puntatori ai bitplane in a1
             moveq      #N_PLANES-1,d1                                            ; numero di piani - 1
.loop:
             move.w     d0,6(a1)                                                  ; copia la parte bassa dell'indirizzo dell'immagine nella parte bassa del bplpointer
             swap       d0                                                        ; scambia word alta e bassa dell'indirizzo dell'immagine
             move.w     d0,2(a1)                                                  ; copia la parte alta dell'indirizzo dell'immagine nel bplpointer
             swap       d0                                                        ; riporta d0 alla condizione iniziale
             add.l      #PLF_PLANE_SIZE,d0                                        ; punta al bitplane successivo
             add.l      #8,a1                                                     ; punta al bplpointer successivo
             dbra       d1,.loop                                                  ; ripete il loop per tutti i piani
             rts 


; disegna il campo di gioco usando il blitter.
draw_pitch:
             moveq      #N_PLANES-1,d7
             move.l     #pitch,d0
             move.w     camera_y,d1
             mulu       #PITCH_ROW_SIZE,d1                                        ; offset verticale
             add.l      d1,d0
             move.w     camera_x,d1                                               ; offset orizzontale = camera_x / 8
             move.w     d1,d2
             asr.w      #3,d1
             and.w      #$fffe,d1                                                 ; arrotonda ad indirizzi pari
             add.l      d1,d0
             move.l     d0,a0
             and.w      #$000f,d2                                                 ; seleziono i primi 4 bit, che corrispondono allo shift
             move.w     #$f,d3
             sub.w      d2,d3
             lsl.w      #8,d3                                                     ; sposto i 4 bit di shift nella posizione che occupano in BLTCON0
             lsl.w      #4,d3
             or.w       #$09f0,d3                                                 ; inserisco i 4 bit nel valore da assegnare ad BLTCON0
             move.l     draw_buffer,a1
.planeloop:
             btst.b     #6,DMACONR(a5)                                            ; lettura dummy
.bltbusy     btst.b     #6,DMACONR(a5)                                            ; blitter pronto?
             bne        .bltbusy                                                  ; no. Aspetta.
             move.l     a0,BLTAPT(a5)
             move.l     a1,BLTDPT(a5)
             move.w     #$ffff,BLTAFWM(a5)                                        ; nessuna maschera
             move.w     #$0000,BLTALWM(a5)                                        ; nessuna maschera
             move.w     d3,BLTCON0(a5)                                            
             move.w     #0,BLTCON1(a5)
             move.w     #(PITCH_WIDTH-22*16)/8,BLTAMOD(a5)
             move.w     #(PLAYFIELD_WIDTH-22*16)/8,BLTDMOD(a5)
             move.w     #PLAYFIELD_HEIGHT<<6+22,BLTSIZE(a5)
             move.l     a0,d0
             add.l      #PITCH_PLANE_SIZE,d0
             move.l     d0,a0
             move.l     a1,d0
             add.l      #PLF_PLANE_SIZE,d0
             move.l     d0,a1
             dbra       d7,.planeloop
             rts


read_joy:
             move.w     JOY1DAT(a5),d3
             btst.l     #1,d3                                                     ; joy a destra?
             beq.s      .checksx
             add.w      #CAMERA_SPEED,camera_x
             cmp.w      #CAMERA_XMAX,camera_x
             ble.s      .checksx
             move.w     #CAMERA_XMAX,camera_x
.checksx:
             btst.l     #9,d3                                                     ; joy a sinistra?
             beq.s      .checkup
             sub.w      #CAMERA_SPEED,camera_x
             bge.s      .checkup
             move.w     #0,camera_x
.checkup:
             move.w     d3,d2
             lsr.w      #1,d2                                                     ; il bit 9 di JOY1DAT è in posizione 8 in d2
             eor.w      d2,d3                                                     ; eor tra il bit 8 e il 9 di JOY1DAT
             btst.l     #8,d3  
             beq.s      .check_down                                               ; se il risultato dell'eor è 0, allora salta al check se il joy è premuto in basso
             sub.w      #CAMERA_SPEED,camera_y                                    ; joy in alto: decrementa la y
             blt.s      .clamp_ymin                                               ; se camera_y < 0 allora salta a clamp_ymin 
             bra.s      .end
.clamp_ymin:
             move.w     #0,camera_y                                               ; clamp a 0 di camera_y
             bra.s      .end
.check_down:
             btst.l     #0,d3                                                     ; joy in basso?
             beq.s      .end                                                      ; se no, termina
             add.w      #CAMERA_SPEED,camera_y                                    ; se si, incrementa camera_y
             cmp.w      #CAMERA_YMAX,camera_y
             ble.s      .end
             move.w     #CAMERA_YMAX,camera_y                                     ; limita camera_y al suo valore massimo
.end 
             rts


swap_buffers:
             move.l     draw_buffer,d0                                            ; scambia i valori di draw_buffer e view_buffer
             move.l     view_buffer,draw_buffer
             move.l     d0,view_buffer
             lea        bplpointers,a1                                            
             moveq      #N_PLANES-1,d1                                            
.loop:
             move.w     d0,6(a1)                                                  ; copia la parte bassa dell'indirizzo dell'immagine nella parte bassa del bplpointer
             swap       d0                                                        ; scambia word alta e bassa dell'indirizzo dell'immagine
             move.w     d0,2(a1)                                                  ; copia la parte alta dell'indirizzo dell'immagine nel bplpointer
             swap       d0                                                        ; riporta d0 alla condizione iniziale
             add.l      #PLF_PLANE_SIZE,d0                                        ; punta al bitplane successivo
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

camera_x     dc.w       5
camera_y     dc.w       320

view_buffer  dc.l       playfield1                                                ; buffer visualizzato sullo schermo
draw_buffer  dc.l       playfield2                                                ; buffer di disegno (non visibile)


; dati grafici

             SECTION    grafica,DATA_C                                            ; segmento caricato in CHIP RAM

copperlist:  
             dc.w       $8e,$2c81                                                 ; DIWSTART: 16 pixel dopo per mascherare il disturbo dovuto allo shift
             dc.w       $90,$2cc1                                                 ; DIWSTOP
             dc.w       $92,$0030                                                 ; DDFSTART
             dc.w       $94,$00d0                                                 ; DDFSTOP
             dc.w       $102,0                                                    ; BPLCON1
             dc.w       $104,0                                                    ; BPLCON2
             dc.w       $108,2                                                    ; BPL1MOD
             dc.w       $10a,2                                                    ; BPL2MOD

             dc.w       $100,$4200                                                ; BPLCON0 4 bitplane
 

  ; palette
             dc.w       $0180,$0790,$0182,$0999,$0184,$0FFF,$0186,$0000
             dc.w       $0188,$0721,$018A,$0A40,$018C,$0F71,$018E,$0690
             dc.w       $0190,$0030,$0192,$0990,$0194,$0F00,$0196,$000F
             dc.w       $0198,$088F,$019A,$0380,$019C,$0FF0,$019E,$0000

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
             incbin     "gfx/pitch_complete.raw"                                  ; immagine del campo 640 x 817, 4 bpp

player_vertical:
             incbin     "gfx/player_vertical_final.raw"                           ; spritesheet del giocatore con maglia verticale 320 x 100
player_vertical_mask:
             incbin     "gfx/player_vertical_final.mask"


             SECTION    dati_azzerati,BSS_C                                       ; sezione contenente i dati azzerati
  
playfield1:
             ds.b       (PLAYFIELD_WIDTH/8)*PLAYFIELD_HEIGHT*N_PLANES 
playfield2:
             ds.b       (PLAYFIELD_WIDTH/8)*PLAYFIELD_HEIGHT*N_PLANES 

             END 