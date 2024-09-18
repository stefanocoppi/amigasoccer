;**************************************************************************************************************************************************************************
; AmigaSoccer
; 
; clone di Sensible Soccer per Amiga.
;
; (c) 2024 Stefano Coppi
;**************************************************************************************************************************************************************************

                    incdir     "include"
                    include    "hw.i"


;**************************************************************************************************************************************************************************
; costanti
;**************************************************************************************************************************************************************************
ExecBase              EQU $4
Disable               EQU -$78
Enable                EQU -$7e
OpenLibrary           EQU -$198
CloseLibrary          EQU -$19e

                     ;5432109876543210
DMASET                EQU %1000001111000000                                              ; copper,bitplane,blitter DMA
N_PLANES              EQU 4                                                              ; numero di bitplanes
PITCH_WIDTH           EQU 640
PITCH_HEIGHT          EQU 817
PLAYFIELD_WIDTH       EQU 352
PLAYFIELD_VIS_W       EQU 320
PLAYFIELD_HEIGHT      EQU 256
PLAYFIELD_ROW_SIZE    EQU (PLAYFIELD_WIDTH/8)
PITCH_PLANE_SIZE      EQU (PITCH_WIDTH/8)*PITCH_HEIGHT
PITCH_ROW_SIZE        EQU (PITCH_WIDTH/8)
PITCH_ORIGIN_X        EQU 309
PITCH_ORIGIN_Y        EQU 417
PLF_PLANE_SIZE        EQU (PLAYFIELD_WIDTH/8)*PLAYFIELD_HEIGHT
VIEWPORT_WIDTH        EQU 320
VIEWPORT_HEIGHT       EQU 256
CAMERA_YMIN           EQU -PITCH_ORIGIN_Y+(VIEWPORT_HEIGHT/2)
CAMERA_YMAX           EQU PITCH_HEIGHT-PITCH_ORIGIN_Y-(VIEWPORT_HEIGHT/2)
CAMERA_XMIN           EQU -PITCH_ORIGIN_X+(VIEWPORT_WIDTH/2)
CAMERA_XMAX           EQU PITCH_WIDTH-PITCH_ORIGIN_X-(VIEWPORT_WIDTH/2)
CAMERA_SPEED          EQU 4
SPRITESHEET_W         EQU 320
SPRITESHEET_H         EQU 100
SPRITESHEET_ROW_SIZE  EQU (320/8)
PLAYER_WIDTH          EQU 16
PLAYER_HEIGHT         EQU 20
SPR_PLANE_SIZE        EQU (SPRITESHEET_W/8)*SPRITESHEET_H 
PLAYER_STATE_STANDRUN EQU 0
INPUT_TYPE_JOY        EQU 0
INPUT_TYPE_AI         EQU 1


;**************************************************************************************************************************************************************************
; STRUTTURE DATI
;**************************************************************************************************************************************************************************

; giocatore
                    rsreset
player.x            rs.w       1                                                         ; posizione (in formato fixed 10.6)
player.y            rs.w       1
player.v            rs.w       1                                                         ; velocità 
player.a            rs.w       1                                                         ; angolo di orientamento (gradi)
player.animx        rs.w       1                                                         ; colonna del frame di animazione
player.animy        rs.w       1                                                         ; riga del frame di animazione
player.state        rs.w       1                                                         ; stato del calciatore
player.inputdevice  rs.b       inputdevice.length
player.speed        rs.w       1                                                         ; attributo velocità 
player.inputtype    rs.w       1                                                         ; tipo di input
player.length       rs.b       0


; dispositivo di input
                    rsreset
inputdevice.value   rs.w       1                                                         ; un valore <> 0 indica che è stato mosso in una direzione
inputdevice.angle   rs.w       1                                                         ; angolo in cui la leva è stata spostata (0-359)
inputdevice.length  rs.b       0 


                    SECTION    codice,CODE 

;**************************************************************************************************************************************************************************
; Programma principale
;**************************************************************************************************************************************************************************
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
                    bsr        read_joy2
                    bsr        draw_pitch

                    bsr        update_player
                    bsr        draw_player

                    btst       #6,$bfe001                                                ; tasto sinistro del mouse premuto?
                    bne        mainloop                                                  ; se no, torna a waitline

                    move.l     old_cop,COP1LC(a5)                                        ; puntiamo la copperlist di sistema
                    move.w     d0,COPJMP1(a5)                                            ; facciamo partire la copperlist di sistema

                    move.l     ExecBase,a6
                    jsr        Enable(a6)                                                ; riabilitiamo il multitasking
                    move.l     gfx_base,a1                                               ; indirizzo base della graphics.library in a1
                    jsr        CloseLibrary(a6)                                          ; chiudiamo la graphics.library

                    rts


;**************************************************************************************************************************************************************************
; Subruotine
;**************************************************************************************************************************************************************************

;**************************************************************************************************************************************************************************
; Inizializza i puntatori ai bitplane
;**************************************************************************************************************************************************************************
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


;**************************************************************************************************************************************************************************
; disegna il campo di gioco usando il blitter.
;**************************************************************************************************************************************************************************
draw_pitch:
                    move.w     camera_x,d0                                               ; trasforma da coordinate camera a viewport
                    sub.w      #VIEWPORT_WIDTH/2,d0
                    move.w     d0,viewport_x
                    move.w     camera_y,d0
                    sub.w      #VIEWPORT_HEIGHT/2,d0
                    move.w     d0,viewport_y
                    moveq      #N_PLANES-1,d7
                    move.l     #pitch,d0
                    move.w     viewport_y,d1
                    add.w      #PITCH_ORIGIN_Y,d1
                    mulu       #PITCH_ROW_SIZE,d1                                        ; offset verticale
                    add.l      d1,d0
                    move.w     viewport_x,d1                                             ; offset orizzontale = viewport_x / 8
                    add.w      #PITCH_ORIGIN_X,d1
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
.bltbusy            btst.b     #6,DMACONR(a5)                                            ; blitter pronto?
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
                    cmp.w      #CAMERA_XMIN,camera_x
                    bge.s      .checkup
                    move.w     #CAMERA_XMIN,camera_x
.checkup:
                    move.w     d3,d2
                    lsr.w      #1,d2                                                     ; il bit 9 di JOY1DAT è in posizione 8 in d2
                    eor.w      d2,d3                                                     ; eor tra il bit 8 e il 9 di JOY1DAT
                    btst.l     #8,d3  
                    beq.s      .check_down                                               ; se il risultato dell'eor è 0, allora salta al check se il joy è premuto in basso
                    sub.w      #CAMERA_SPEED,camera_y                                    ; joy in alto: decrementa la y
                    cmp.w      #CAMERA_YMIN,camera_y
                    blt.s      .clamp_ymin                                               ; se camera_y < 0 allora salta a clamp_ymin 
                    bra.s      .end
.clamp_ymin:
                    move.w     #CAMERA_YMIN,camera_y                                     ; clamp a 0 di camera_y
                    bra.s      .end
.check_down:
                    btst.l     #0,d3                                                     ; joy in basso?
                    beq.s      .end                                                      ; se no, termina
                    add.w      #CAMERA_SPEED,camera_y                                    ; se si, incrementa camera_y
                    cmp.w      #CAMERA_YMAX,camera_y
                    ble.s      .end
                    move.w     #CAMERA_YMAX,camera_y                                     ; limita camera_y al suo valore massimo
.end 
                    move.w     camera_x,d0                                               ; trasforma da coordinate camera a viewport
                    sub.w      #VIEWPORT_WIDTH/2,d0
                    move.w     d0,viewport_x
                    move.w     camera_y,d0
                    sub.w      #VIEWPORT_HEIGHT/2,d0
                    move.w     d0,viewport_y
                    rts


;**************************************************************************************************************************************************************************
; legge il joystick e aggiorna la variabile joy_state
;**************************************************************************************************************************************************************************
read_joy2:
                    move.w     JOY1DAT(a5),d3
                    btst.l     #1,d3                                                     ; joy a destra?
                    beq.s      .checksx
                    add.w      #1,joy_state  
                    bra        .checkup
.checksx:
                    btst.l     #9,d3                                                     ; joy a sinistra?
                    beq.s      .checkup
                    add.w      #2,joy_state
.checkup:
                    move.w     d3,d2
                    lsr.w      #1,d2                                                     ; il bit 9 di JOY1DAT è in posizione 8 in d2
                    eor.w      d2,d3                                                     ; eor tra il bit 8 e il 9 di JOY1DAT
                    btst.l     #8,d3                                                     ; joy in alto?
                    beq.s      .check_down                                               
                    add.w      #%100,joy_state 
                    bra.s      .end
.check_down:
                    btst.l     #0,d3                                                     ; joy in basso?
                    beq.s      .end                                                      
                    add.w      #%1000,joy_state
.end 
                    lea        player0,a0                                                ; imposta l'angolo del calciatore in base al movimento del joystick
                    cmp        #1,joy_state                                              ; joy a dx?
                    beq        .setdx
                    cmp        #2,joy_state                                              ; joy a sx?
                    beq        .setsx
                    bra        .return
.setdx:
                    move.w     #0,player.a(a0)
                    bra        .return
.setsx:
                    move.w     #180,player.a(a0)
                    bra        .return
              ;      move.w     camera_x,d0                                               ; trasforma da coordinate camera a viewport
              ;  sub.w      #VIEWPORT_WIDTH/2,d0
              ;  move.w     d0,viewport_x
              ;  move.w     camera_y,d0
              ;  sub.w      #VIEWPORT_HEIGHT/2,d0
              ;  move.w     d0,viewport_y
.return:
                    rts


;**************************************************************************************************************************************************************************
; Scambia i buffer video, provocando la visualizzazione del draw_buffer.
;**************************************************************************************************************************************************************************
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


;**************************************************************************************************************************************************************************
; Disegna uno sprite sul draw_buffer.
; L'immagine dello sprite viene copiata da uno spritesheet.
;
; d0.w coordinata x 
; d1.w coordinata y
; d3.w colonna dello spritesheet
; d4.w riga dello spritesheet
; a1 indirizzo dello spritesheet
; a2 indirizzo delle maschere
;**************************************************************************************************************************************************************************
draw_sprite:
            
                    move.l     draw_buffer,a0
                    sub.w      viewport_x,d0                                             ; converto da coordinate globali in coordinate locali alla viewport
                    cmp.w      #-16,d0
                    blt        .return                                                   ; se x < viewport_x - 16 , allora sprite fuori dalla viewport, non lo disegno
                    cmp.w      #PLAYFIELD_VIS_W+16,d0                                    ; se x >= viewport_x + PLAYFIELD_VIS_W+16 allora
                    bge        .return                                                   ; sprite fuori dalla viewport, non lo disegno
                    add.w      #16,d0                                                    ; tiene conto dei 16 px non visibili per lo scroll
                    sub.w      #PLAYER_WIDTH/2,d0                                        ; porto l'origine deal centro
                    sub.w      viewport_y,d1
                    blt        .return                                                   ; se y < viewport_y non disegno lo sprite perchè non è visibile
                    cmp.w      #PLAYFIELD_HEIGHT-16,d1
                    bge        .return                                                   ; se y >= viewport_y + PLAYFIELD_HEIGHT allora non è visibile e non lo disegno
                    sub.w      #PLAYER_HEIGHT,d1                                         ; porto l'origine del giocatore in alto
                    mulu.w     #PLAYFIELD_ROW_SIZE,d1                                    ; calcolo offset_y = PLAYFIELD_ROW_SIZE * y
                    add.w      d1,a0                                                     ; sommo offset_y ad a0
                    move       d0,d1
                    and.w      #$000f,d0                                                 ; seleziono i primi 4 bit che rappresentano lo shift
                    lsl.w      #8,d0                                                     ; sposto i bit di shift nel nibble più significativo
                    lsl.w      #4,d0
                    move.w     d0,d2
                    or.w       #$0fca,d0                                                 ; inserisco i bit dello shift nel valore da assegnare a BPLCON0
                    lsr.w      #3,d1                                                     ; calcolo offset_x = x/8
                    and.w      #$fffe,d1                                                 ; rendo pari l'indirizzo
                    add.w      d1,a0
                    mulu       #(PLAYER_WIDTH/8),d3                                      ; offset_x = colonna * (PLAYER_WIDTH/8)
                    add.w      d3,a1
                    add.w      d3,a2
                    mulu       #PLAYER_HEIGHT,d4
                    mulu       #SPRITESHEET_ROW_SIZE,d4                                  ; offset_y = riga * PLAYER_HEIGHT * SPRITESHEET_ROW_SIZE
                    add.w      d4,a1
                    add.w      d4,a2
                    moveq      #N_PLANES-1,d7
.planeloop:
                    btst.b     #6,DMACONR(a5)                                            ; lettura dummy
.bltbusy            btst.b     #6,DMACONR(a5)                                            ; blitter pronto?
                    bne        .bltbusy
                    move.w     #$ffff,BLTAFWM(a5)                                        ; nessuna maschera
                    move.w     #$0000,BLTALWM(a5)                                        ; maschera sull'ultima word
                    move.w     d0,BLTCON0(a5)                                            
                    move.w     d2,BLTCON1(a5)
                    move.w     #(SPRITESHEET_W-PLAYER_WIDTH-16)/8,BLTAMOD(a5)
                    move.w     #(SPRITESHEET_W-PLAYER_WIDTH-16)/8,BLTBMOD(a5)
                    move.w     #(PLAYFIELD_WIDTH-PLAYER_WIDTH-16)/8,BLTCMOD(a5)
                    move.w     #(PLAYFIELD_WIDTH-PLAYER_WIDTH-16)/8,BLTDMOD(a5)
                    move.l     a2,BLTAPT(a5)
                    move.l     a1,BLTBPT(a5)
                    move.l     a0,BLTCPT(a5)
                    move.l     a0,BLTDPT(a5)
                    move.w     #PLAYER_HEIGHT<<6+(PLAYER_WIDTH+16)/16,BLTSIZE(a5)
                    move.l     a0,d1
                    add.l      #PLF_PLANE_SIZE,d1                                        ; punto al bitplane successivo
                    move.l     d1,a0
                    move.l     a1,d1
                    add.l      #SPR_PLANE_SIZE,d1
                    move.l     d1,a1
                    dbra       d7,.planeloop
.return:
                    rts


;**************************************************************************************************************************************************************************
; Disegna un calciatore.
;**************************************************************************************************************************************************************************
draw_player:
                    lea        player0,a0
                    move.w     player.x(a0),d0                                           ; coordinata x in formato fixed 10.6
                    asr.w      #6,d0                                                     ; converte x in int
                    move.w     player.y(a0),d1                                           ; coordinata y
                    asr.w      #6,d1
                    move.w     player.animx(a0),d3                                       ; colonna dello spritesheet
                    move.w     player.animy(a0),d4                                       ; riga dello spritesheet
                    lea        player_vertical,a1                                        ; indirizzo spritesheet
                    lea        player_vertical_mask,a2                                   ; indirizzo maschere
                    bsr        draw_sprite
                    rts  


;**************************************************************************************************************************************************************************
; Aggiorna lo stato di un calciatore.
;**************************************************************************************************************************************************************************
update_player:
                    lea        player0,a0                                                ; calcola la posizione x = x + v * cos(a)
                    lea        costable,a1
                    move.w     player.v(a0),d0
                    move.w     player.a(a0),d1
                    lsl.w      #1,d1                                                     ; perchè la costable è formata da word
                    move.w     0(a1,d1.w),d3                                             ; cos(a)
                    muls       d3,d0                                                     ; v * cos(a)
                    add.w      d0,player.x(a0)
                    lea        sintable,a1
                    move.w     player.v(a0),d0
                    move.w     0(a1,d1.w),d3                                             ; sin(a)
                    muls       d3,d0                                                     ; v * sin(a)
                    add.w      d0,player.y(a0)                                           ; y = y + v * sin(a) 
                    bsr        update_player_input
                    bsr        process_player_state
                    rts


;**************************************************************************************************************************************************************************
; Chiama la routine di gestione dello stato corrente del calciatore, usando la jumptable
;**************************************************************************************************************************************************************************
process_player_state:
                    lea        player_state_jumptable,a1
                    lea        player0,a0
                    move.w     player.state(a0),d0
                    lsl.w      #2,d0                                                     ; moltiplica lo stato per 4 per puntare all'elemento corrispondente della tabella
                    move.l     0(a1,d0.w),a1                                             ; indirizzo della routine
                    jsr        (a1)
                    rts


;**************************************************************************************************************************************************************************
; Aggiorna l'input del giocatore
;**************************************************************************************************************************************************************************
update_player_input:
                    lea        player0,a0
                    lea        player.inputdevice(a0),a1
                    move.w     player.inputtype(a0),d0
                    cmp.w      #INPUT_TYPE_JOY,d0
                    beq        .joy
.joy:
                    move.w     joy_state,d0
                    cmp.w      #1,d0                                                     ; joy a dx?
                    beq        .dx
                    cmp.w      #2,d0                                                     ; joy a sx?
                    beq        .sx
                    move.w     #0,inputdevice.value(a1)
                    bra        .return
.dx:
                    move.w     #1,inputdevice.value(a1)
                    move.w     #0,inputdevice.angle(a1)
                    bra        .return
.sx:
                    move.w     #1,inputdevice.value(a1)
                    move.w     #180,inputdevice.angle(a1)
                    bra        .return
.return:
                    rts


;**************************************************************************************************************************************************************************
; Stato in cui il calciatore può correre o fermarsi
;**************************************************************************************************************************************************************************
process_plstate_standrun:
                    lea        player0,a0
                    lea        player.inputdevice(a0),a1
                    move.w     inputdevice.value(a1),d0
                    tst.w      d0
                    bne        .moveplayer
                    move.w     #0,player.v(a0)
                    bra        .return
.moveplayer:
                    move.w     player.speed(a0),player.v(a0)
                    move.w     inputdevice.angle(a1),player.a(a0)
.return:
                    rts


;**************************************************************************************************************************************************************************
; variabili
;**************************************************************************************************************************************************************************
gfx_name:
                    dc.b       "graphics.library",0,0
gfx_base:
                    dc.l       0                                                         ; indirizzo base della graphics.library
old_cop:
                    dc.l       0                                                         ; indirizzo della copperlist di sistema

viewport_x          dc.w       0
viewport_y          dc.w       0

camera_x            dc.w       0
camera_y            dc.w       0

view_buffer         dc.l       playfield1                                                ; buffer visualizzato sullo schermo
draw_buffer         dc.l       playfield2                                                ; buffer di disegno (non visibile)

joy_state           dc.w       0                                                         ; stato dello joystick

player0             dc.w       0<<6                                                      ; posizione x
                    dc.w       0<<6                                                      ; posizione y
                    dc.w       0                                                         ; player.v
                    dc.w       0                                                         ; player.a
                    dc.w       3                                                         ; player.animx
                    dc.w       0                                                         ; player.animy
                    dc.w       PLAYER_STATE_STANDRUN                                     ; stato
                    dc.w       0                                                         ; inputdevice.value
                    dc.w       0                                                         ; inputdevice.angle
                    dc.w       2                                                         ; player.speed
                    dc.w       INPUT_TYPE_JOY                                            ; player.inputtype

; tabella con le routine da eseguire per ciascun stato del calciatore
player_state_jumptable:  
                    dc.l       process_plstate_standrun


sintable:
;@generated-datagen-start----------------
; This code was generated by Amiga Assembly extension
;
;----- parameters : modify ------
;expression(x as variable): round(sin(x*(PI/180))*pow(2,6))
;variable:
;   name:x
;   startValue:0
;   endValue:360
;   step:1
;outputType(B,W,L): W
;outputInHex: true
;valuesPerLine: 8
;--------------------------------
;- DO NOT MODIFY following lines -
 ; -> SIGNED values <-
                    dc.w       $0000, $0001, $0002, $0003, $0004, $0006, $0007, $0008
                    dc.w       $0009, $000a, $000b, $000c, $000d, $000e, $000f, $0011
                    dc.w       $0012, $0013, $0014, $0015, $0016, $0017, $0018, $0019
                    dc.w       $001a, $001b, $001c, $001d, $001e, $001f, $0020, $0021
                    dc.w       $0022, $0023, $0024, $0025, $0026, $0027, $0027, $0028
                    dc.w       $0029, $002a, $002b, $002c, $002c, $002d, $002e, $002f
                    dc.w       $0030, $0030, $0031, $0032, $0032, $0033, $0034, $0034
                    dc.w       $0035, $0036, $0036, $0037, $0037, $0038, $0039, $0039
                    dc.w       $003a, $003a, $003a, $003b, $003b, $003c, $003c, $003d
                    dc.w       $003d, $003d, $003e, $003e, $003e, $003e, $003f, $003f
                    dc.w       $003f, $003f, $003f, $0040, $0040, $0040, $0040, $0040
                    dc.w       $0040, $0040, $0040, $0040, $0040, $0040, $0040, $0040
                    dc.w       $0040, $0040, $003f, $003f, $003f, $003f, $003f, $003e
                    dc.w       $003e, $003e, $003e, $003d, $003d, $003d, $003c, $003c
                    dc.w       $003b, $003b, $003a, $003a, $003a, $0039, $0039, $0038
                    dc.w       $0037, $0037, $0036, $0036, $0035, $0034, $0034, $0033
                    dc.w       $0032, $0032, $0031, $0030, $0030, $002f, $002e, $002d
                    dc.w       $002c, $002c, $002b, $002a, $0029, $0028, $0027, $0027
                    dc.w       $0026, $0025, $0024, $0023, $0022, $0021, $0020, $001f
                    dc.w       $001e, $001d, $001c, $001b, $001a, $0019, $0018, $0017
                    dc.w       $0016, $0015, $0014, $0013, $0012, $0011, $000f, $000e
                    dc.w       $000d, $000c, $000b, $000a, $0009, $0008, $0007, $0006
                    dc.w       $0004, $0003, $0002, $0001, $0000, $ffff, $fffe, $fffd
                    dc.w       $fffc, $fffa, $fff9, $fff8, $fff7, $fff6, $fff5, $fff4
                    dc.w       $fff3, $fff2, $fff1, $ffef, $ffee, $ffed, $ffec, $ffeb
                    dc.w       $ffea, $ffe9, $ffe8, $ffe7, $ffe6, $ffe5, $ffe4, $ffe3
                    dc.w       $ffe2, $ffe1, $ffe0, $ffdf, $ffde, $ffdd, $ffdc, $ffdb
                    dc.w       $ffda, $ffd9, $ffd9, $ffd8, $ffd7, $ffd6, $ffd5, $ffd4
                    dc.w       $ffd4, $ffd3, $ffd2, $ffd1, $ffd0, $ffd0, $ffcf, $ffce
                    dc.w       $ffce, $ffcd, $ffcc, $ffcc, $ffcb, $ffca, $ffca, $ffc9
                    dc.w       $ffc9, $ffc8, $ffc7, $ffc7, $ffc6, $ffc6, $ffc6, $ffc5
                    dc.w       $ffc5, $ffc4, $ffc4, $ffc3, $ffc3, $ffc3, $ffc2, $ffc2
                    dc.w       $ffc2, $ffc2, $ffc1, $ffc1, $ffc1, $ffc1, $ffc1, $ffc0
                    dc.w       $ffc0, $ffc0, $ffc0, $ffc0, $ffc0, $ffc0, $ffc0, $ffc0
                    dc.w       $ffc0, $ffc0, $ffc0, $ffc0, $ffc0, $ffc0, $ffc1, $ffc1
                    dc.w       $ffc1, $ffc1, $ffc1, $ffc2, $ffc2, $ffc2, $ffc2, $ffc3
                    dc.w       $ffc3, $ffc3, $ffc4, $ffc4, $ffc5, $ffc5, $ffc6, $ffc6
                    dc.w       $ffc6, $ffc7, $ffc7, $ffc8, $ffc9, $ffc9, $ffca, $ffca
                    dc.w       $ffcb, $ffcc, $ffcc, $ffcd, $ffce, $ffce, $ffcf, $ffd0
                    dc.w       $ffd0, $ffd1, $ffd2, $ffd3, $ffd4, $ffd4, $ffd5, $ffd6
                    dc.w       $ffd7, $ffd8, $ffd9, $ffd9, $ffda, $ffdb, $ffdc, $ffdd
                    dc.w       $ffde, $ffdf, $ffe0, $ffe1, $ffe2, $ffe3, $ffe4, $ffe5
                    dc.w       $ffe6, $ffe7, $ffe8, $ffe9, $ffea, $ffeb, $ffec, $ffed
                    dc.w       $ffee, $ffef, $fff1, $fff2, $fff3, $fff4, $fff5, $fff6
                    dc.w       $fff7, $fff8, $fff9, $fffa, $fffc, $fffd, $fffe, $ffff
                    dc.w       $0000
;@generated-datagen-end----------------






costable:
;@generated-datagen-start----------------
; This code was generated by Amiga Assembly extension
;
;----- parameters : modify ------
;expression(x as variable): round(cos(x*(PI/180))*pow(2,6))
;variable:
;   name:x
;   startValue:0
;   endValue:360
;   step:1
;outputType(B,W,L): W
;outputInHex: true
;valuesPerLine: 8
;--------------------------------
;- DO NOT MODIFY following lines -
 ; -> SIGNED values <-
                    dc.w       $0040, $0040, $0040, $0040, $0040, $0040, $0040, $0040
                    dc.w       $003f, $003f, $003f, $003f, $003f, $003e, $003e, $003e
                    dc.w       $003e, $003d, $003d, $003d, $003c, $003c, $003b, $003b
                    dc.w       $003a, $003a, $003a, $0039, $0039, $0038, $0037, $0037
                    dc.w       $0036, $0036, $0035, $0034, $0034, $0033, $0032, $0032
                    dc.w       $0031, $0030, $0030, $002f, $002e, $002d, $002c, $002c
                    dc.w       $002b, $002a, $0029, $0028, $0027, $0027, $0026, $0025
                    dc.w       $0024, $0023, $0022, $0021, $0020, $001f, $001e, $001d
                    dc.w       $001c, $001b, $001a, $0019, $0018, $0017, $0016, $0015
                    dc.w       $0014, $0013, $0012, $0011, $000f, $000e, $000d, $000c
                    dc.w       $000b, $000a, $0009, $0008, $0007, $0006, $0004, $0003
                    dc.w       $0002, $0001, $0000, $ffff, $fffe, $fffd, $fffc, $fffa
                    dc.w       $fff9, $fff8, $fff7, $fff6, $fff5, $fff4, $fff3, $fff2
                    dc.w       $fff1, $ffef, $ffee, $ffed, $ffec, $ffeb, $ffea, $ffe9
                    dc.w       $ffe8, $ffe7, $ffe6, $ffe5, $ffe4, $ffe3, $ffe2, $ffe1
                    dc.w       $ffe0, $ffdf, $ffde, $ffdd, $ffdc, $ffdb, $ffda, $ffd9
                    dc.w       $ffd9, $ffd8, $ffd7, $ffd6, $ffd5, $ffd4, $ffd4, $ffd3
                    dc.w       $ffd2, $ffd1, $ffd0, $ffd0, $ffcf, $ffce, $ffce, $ffcd
                    dc.w       $ffcc, $ffcc, $ffcb, $ffca, $ffca, $ffc9, $ffc9, $ffc8
                    dc.w       $ffc7, $ffc7, $ffc6, $ffc6, $ffc6, $ffc5, $ffc5, $ffc4
                    dc.w       $ffc4, $ffc3, $ffc3, $ffc3, $ffc2, $ffc2, $ffc2, $ffc2
                    dc.w       $ffc1, $ffc1, $ffc1, $ffc1, $ffc1, $ffc0, $ffc0, $ffc0
                    dc.w       $ffc0, $ffc0, $ffc0, $ffc0, $ffc0, $ffc0, $ffc0, $ffc0
                    dc.w       $ffc0, $ffc0, $ffc0, $ffc0, $ffc1, $ffc1, $ffc1, $ffc1
                    dc.w       $ffc1, $ffc2, $ffc2, $ffc2, $ffc2, $ffc3, $ffc3, $ffc3
                    dc.w       $ffc4, $ffc4, $ffc5, $ffc5, $ffc6, $ffc6, $ffc6, $ffc7
                    dc.w       $ffc7, $ffc8, $ffc9, $ffc9, $ffca, $ffca, $ffcb, $ffcc
                    dc.w       $ffcc, $ffcd, $ffce, $ffce, $ffcf, $ffd0, $ffd0, $ffd1
                    dc.w       $ffd2, $ffd3, $ffd4, $ffd4, $ffd5, $ffd6, $ffd7, $ffd8
                    dc.w       $ffd9, $ffd9, $ffda, $ffdb, $ffdc, $ffdd, $ffde, $ffdf
                    dc.w       $ffe0, $ffe1, $ffe2, $ffe3, $ffe4, $ffe5, $ffe6, $ffe7
                    dc.w       $ffe8, $ffe9, $ffea, $ffeb, $ffec, $ffed, $ffee, $ffef
                    dc.w       $fff1, $fff2, $fff3, $fff4, $fff5, $fff6, $fff7, $fff8
                    dc.w       $fff9, $fffa, $fffc, $fffd, $fffe, $ffff, $0000, $0001
                    dc.w       $0002, $0003, $0004, $0006, $0007, $0008, $0009, $000a
                    dc.w       $000b, $000c, $000d, $000e, $000f, $0011, $0012, $0013
                    dc.w       $0014, $0015, $0016, $0017, $0018, $0019, $001a, $001b
                    dc.w       $001c, $001d, $001e, $001f, $0020, $0021, $0022, $0023
                    dc.w       $0024, $0025, $0026, $0027, $0027, $0028, $0029, $002a
                    dc.w       $002b, $002c, $002c, $002d, $002e, $002f, $0030, $0030
                    dc.w       $0031, $0032, $0032, $0033, $0034, $0034, $0035, $0036
                    dc.w       $0036, $0037, $0037, $0038, $0039, $0039, $003a, $003a
                    dc.w       $003a, $003b, $003b, $003c, $003c, $003d, $003d, $003d
                    dc.w       $003e, $003e, $003e, $003e, $003f, $003f, $003f, $003f
                    dc.w       $003f, $0040, $0040, $0040, $0040, $0040, $0040, $0040
                    dc.w       $0040
;@generated-datagen-end----------------




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