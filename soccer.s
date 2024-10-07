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
ExecBase               EQU $4
Disable                EQU -$78
Enable                 EQU -$7e
OpenLibrary            EQU -$198
CloseLibrary           EQU -$19e

                           ;5432109876543210
DMASET                 EQU %1000001111000000                                                ; copper,bitplane,blitter DMA
N_PLANES               EQU 4                                                                ; numero di bitplanes
PITCH_WIDTH            EQU 640
PITCH_HEIGHT           EQU 817
PLAYFIELD_WIDTH        EQU 352
PLAYFIELD_VIS_W        EQU 320
PLAYFIELD_HEIGHT       EQU 256+2*PLAYER_HEIGHT
PLAYFIELD_ROW_SIZE     EQU (PLAYFIELD_WIDTH/8)
PITCH_PLANE_SIZE       EQU (PITCH_WIDTH/8)*PITCH_HEIGHT
PITCH_ROW_SIZE         EQU (PITCH_WIDTH/8)
PITCH_ORIGIN_X         EQU 309
PITCH_ORIGIN_Y         EQU 417
PLF_PLANE_SIZE         EQU (PLAYFIELD_WIDTH/8)*PLAYFIELD_HEIGHT
VIEWPORT_WIDTH         EQU 320
VIEWPORT_HEIGHT        EQU 256
CAMERA_YMIN            EQU -PITCH_ORIGIN_Y+(VIEWPORT_HEIGHT/2)
CAMERA_YMAX            EQU PITCH_HEIGHT-PITCH_ORIGIN_Y-(VIEWPORT_HEIGHT/2)
CAMERA_XMIN            EQU -PITCH_ORIGIN_X+(VIEWPORT_WIDTH/2)
CAMERA_XMAX            EQU PITCH_WIDTH-PITCH_ORIGIN_X-(VIEWPORT_WIDTH/2)
CAMERA_SPEED           EQU 4
SPRITESHEET_PLAYER_W   EQU 128
SPRITESHEET_PLAYER_H   EQU 80
PLAYER_WIDTH           EQU 16
PLAYER_HEIGHT          EQU 20
PLAYER_H               EQU 12
PLAYER_STATE_STANDRUN  EQU 0
PLAYER_STATE_KICK      EQU 1
PLAYER_STATE_LOPASS    EQU 2
PLAYER_STATE_HIPASS    EQU 3
INPUT_TYPE_JOY         EQU 0
INPUT_TYPE_AI          EQU 1
BALL_WIDTH             EQU 16
BALL_HEIGHT            EQU 4
SPRITESHEET_BALL_W     EQU 80
SPRITESHEET_BALL_H     EQU 4
GRAVITY                EQU 96                                                               ; 1.5 
BOUNCE                 EQU 45                                                               ; 0.7
GRASS_FRICTION         EQU 10                                                               ; 0.16
SPIN_FACTOR            EQU 15                                                               ; 0.24
SPIN_DAMPENING         EQU 9                                                                ; 0.14
BALL_XMIN              EQU -281<<6
BALL_XMAX              EQU 287<<6
BALL_YMIN              EQU -335<<6
BALL_YMAX              EQU 335<<6
KICKMODE_UNKNOWN       EQU 0
KICKMODE_LOWPASS       EQU 1
KICKMODE_SHOT          EQU 2
KICKMODE_HIGHPASS      EQU 3
GOAL_LINE              EQU 196
PENALY_AREA_HALF_WIDTH EQU 144
POTGOR                 EQU $016
NUM_PLAYERS_PER_TEAM   EQU 11

;**************************************************************************************************************************************************************************
; STRUTTURE DATI
;**************************************************************************************************************************************************************************

; giocatore
                       rsreset
player.x               rs.w       1                                                         ; posizione (in formato fixed 10.6)
player.y               rs.w       1
player.v               rs.w       1                                                         ; velocità (in formato fixed 10.6)
player.a               rs.w       1                                                         ; angolo di orientamento (gradi) (in formato fixed 10.6)
player.animx           rs.w       1                                                         ; colonna del frame di animazione
player.animy           rs.w       1                                                         ; riga del frame di animazione
player.state           rs.w       1                                                         ; stato del calciatore
player.inputdevice     rs.b       inputdevice.length
player.speed           rs.w       1                                                         ; attributo velocità (in formato fixed 10.6)
player.inputtype       rs.w       1                                                         ; tipo di input
player.anim_time       rs.w       1                                                         ; tempo di animazione (in 1/50 di sec)
player.anim_counter    rs.w       1
player.id              rs.w       1                                                         ; id univoco
player.has_ball        rs.w       1                                                         ; 1 se è in possesso della palla, 0 altrimenti
player.timer1          rs.w       1
player.side            rs.w       1                                                         ; indica qual'è la metà campo della propria squadra: -1 sopra, 1 sotto
player.selected        rs.w       1                                                         ; 1 indica che è selezionato per essere controllato, 0 altrimenti
player.kick_angle      rs.w       1                                                         ; angolo di tiro (0-359, in formato fixed 10.6)
player.shoot_bar_anim  rs.w       1                                                         ; frame di animazione della shoot bar
player.length          rs.b       0


; dispositivo di input
                       rsreset
inputdevice.value      rs.w       1                                                         ; un valore <> 0 indica che è stato mosso in una direzione
inputdevice.angle      rs.w       1                                                         ; angolo in cui la leva è stata spostata (0-359)
inputdevice.fire1      rs.w       1                                                         ; se fire1 è premuto vale 1, 0 altrimenti
inputdevice.fire2      rs.w       1                                                         ; se fire2 è premuto vale 1, 0 altrimenti
inputdevice.fire3      rs.w       1                                                         ; se fire3 è premuto vale 1, 0 altrimenti
inputdevice.length     rs.b       0 


; palla
                       rsreset
ball.x                 rs.w       1                                                         ; posizione (in formato fixed 10.6)
ball.y                 rs.w       1
ball.z                 rs.w       1
ball.v                 rs.w       1                                                         ; velocità su x e y (in formato fixed 10.6)
ball.vz                rs.w       1                                                         ; velocità verticale (in formato fixed 10.6)
ball.a                 rs.w       1                                                         ; angolo di orientamento (gradi) (in formato fixed 10.6)
ball.s                 rs.w       1                                                         ; spin (in formato fixed 10.6)
ball.animx             rs.w       1                                                         ; colonna dello spritesheet
ball.animy             rs.w       1                                                         ; riga dello spritesheet
ball.f                 rs.w       1                                                         ; frame di animazione (in formato fixed 10.6)
ball.anim_timer        rs.w       1
ball.anim_duration     rs.w       1                                                         ; durata frame di animazione (in 1/50 di sec)
ball.owner             rs.w       1                                                         ; id del calciatore in possesso della palla
ball.x_side            rs.w       1                                                         ; indica in quale parte di campo orizzontale si trova: -1 alla sinistra, 1 alla destra
ball.length            rs.b       0

; squadra
                       rsreset
team.name              rs.b       16
team.short_name        rs.b       4
team.side              rs.w       1                                                         ; indica la propria area: -1 sopra, 1 sotto
team.players           rs.b       player.length * NUM_PLAYERS_PER_TEAM
team.length            rs.b       0

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
                       bsr        init_bplpointers                                          ; inizializzamo i bplpointer per puntare alla nostra immagine del campo
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
                       bsr        ball_update
                       bsr        player_update
                       bsr        update_camera
                       bsr        draw_pitch
                      ;  lea        player0,a0
                      ;  bsr        player_draw
                       bsr        team_draw
                       bsr        ball_draw
                       ;bsr        test_font
                       

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
; Subroutine
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
                       movem.l    d0-d7/a0-a6,-(sp)
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
                       add.l      #PLAYER_HEIGHT*PLAYFIELD_ROW_SIZE,a1                      ; salto la parte non visibile
.planeloop:
                       btst.b     #6,DMACONR(a5)                                            ; lettura dummy
.bltbusy               btst.b     #6,DMACONR(a5)                                            ; blitter pronto?
                       bne        .bltbusy                                                  ; no. Aspetta.
                       move.l     a0,BLTAPT(a5)
                       move.l     a1,BLTDPT(a5)
                       move.w     #$ffff,BLTAFWM(a5)                                        ; nessuna maschera
                       move.w     #$0000,BLTALWM(a5)                                        ; nessuna maschera
                       move.w     d3,BLTCON0(a5)                                            
                       move.w     #0,BLTCON1(a5)
                       move.w     #(PITCH_WIDTH-22*16)/8,BLTAMOD(a5)
                       move.w     #(PLAYFIELD_WIDTH-22*16)/8,BLTDMOD(a5)
                       move.w     #VIEWPORT_HEIGHT<<6+22,BLTSIZE(a5)
                       move.l     a0,d0
                       add.l      #PITCH_PLANE_SIZE,d0
                       move.l     d0,a0
                       move.l     a1,d0
                       add.l      #PLF_PLANE_SIZE,d0
                       move.l     d0,a1
                       dbra       d7,.planeloop
                       movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; aggiorna la posizione della telecamera
;**************************************************************************************************************************************************************************
update_camera:
                       movem.l    d0-d7/a0-a6,-(sp)
                       lea        ball,a0
                       move.w     ball.x(a0),d0                                             ; coordinata x in formato fixed 10.6
                       asr.w      #6,d0                                                     ; converte in int
                       move.w     d0,camera_x
                       move.w     ball.y(a0),d0                                             ; coordinata y in formato fixed 10.6
                       asr.w      #6,d0                                                     ; converte in int
                       move.w     d0,camera_y
                       ; limita il movimento della cam entro il campo di gioco
                       cmp.w      #CAMERA_XMIN,camera_x
                       ble        .minx
                       cmp.w      #CAMERA_XMAX,camera_x
                       bge        .maxx
.checky:
                       cmp.w      #CAMERA_YMIN,camera_y
                       ble        .miny
                       cmp.w      #CAMERA_YMAX,camera_y
                       bge        .maxy
                       bra        .return
.minx:
                       move.w     #CAMERA_XMIN,camera_x
                       bra        .checky
.maxx:
                       move.w     #CAMERA_XMAX,camera_x
                       bra        .checky
.miny:
                       move.w     #CAMERA_YMIN,camera_y
                       bra        .return
.maxy:
                       move.w     #CAMERA_YMAX,camera_y
.return:
                       movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; aggiorna la posizione della telecamera. Camera centrata sul calciatore.
;**************************************************************************************************************************************************************************
update_camera2:
                       lea        player0,a0
                       move.w     player.x(a0),d0                                           ; coordinata x in formato fixed 10.6
                       asr.w      #6,d0                                                     ; converte in int
                       move.w     d0,camera_x
                       move.w     player.y(a0),d0                                           ; coordinata y in formato fixed 10.6
                       asr.w      #6,d0                                                     ; converte in int
                       move.w     d0,camera_y
                    ; limita il movimento della cam entro il campo di gioco
                       cmp.w      #CAMERA_XMIN,camera_x
                       ble        .minx
                       cmp.w      #CAMERA_XMAX,camera_x
                       bge        .maxx
.checky:
                       cmp.w      #CAMERA_YMIN,camera_y
                       ble        .miny
                       cmp.w      #CAMERA_YMAX,camera_y
                       bge        .maxy
                       bra        .return
.minx:
                       move.w     #CAMERA_XMIN,camera_x
                       bra        .checky
.maxx:
                       move.w     #CAMERA_XMAX,camera_x
                       bra        .checky
.miny:
                       move.w     #CAMERA_YMIN,camera_y
                       bra        .return
.maxy:
                       move.w     #CAMERA_YMAX,camera_y
.return:
                       rts


;**************************************************************************************************************************************************************************
; legge il joystick e muove la camera: non serve più
;**************************************************************************************************************************************************************************
read_joy2:
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
; legge il joystick e aggiorna la variabile joy_state: versione che legge joystick a 3 pulsanti.
; 
; NB: il joystick deve essere connesso in porta 2
; in WinUAE, come tipologia di joystick, selezionare Gamepad.
;**************************************************************************************************************************************************************************
read_joy:
                       movem.l    d0-d7/a0-a6,-(sp)
                       clr.w      joy_state                                                 ; azzero lo stato del joy
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
                       bra.s      .check_fire1
.check_down:
                       btst.l     #0,d3                                                     ; joy in basso?
                       beq.s      .check_fire1                                                      
                       add.w      #%1000,joy_state
.check_fire1:
                       btst       #7,$bfe001                                                ; fire1 premuto?
                       bne        .check_fire2
                       add.w      #%10000,joy_state
                       bra        .end
.check_fire2:
                       move.w     POTGOR(a5),d0
                       btst.l     #14,d0                                                    ; fire2 premuto?
                       beq        .set_fire2_state
                       bra        .check_fire3
.set_fire2_state:
                       add.w      #%100000,joy_state
.check_fire3:
                       btst.l     #12,d0                                                    ; fire3 premuto?
                       beq        .set_fire3_state
                       bra        .end
.set_fire3_state:
                       add.w      #%1000000,joy_state
.end 
                       move.w     #$ff00,POTGO(a5)                                          ; abilita i pin 12,14 per la lettura
                       movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; Scambia i buffer video, provocando la visualizzazione del draw_buffer.
;**************************************************************************************************************************************************************************
swap_buffers:
                       move.l     draw_buffer,d0                                            ; scambia i valori di draw_buffer e view_buffer
                       move.l     view_buffer,draw_buffer
                       move.l     d0,view_buffer
                       add.l      #PLAYER_HEIGHT*PLAYFIELD_ROW_SIZE,d0                      ; la parte visibile del playfield inizia PLAYER_HEIGHT pixel dopo per consentire il clipping verticale degli sprite
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
; d5.w larghezza sprite
; d6.w altezza sprite
; a1 indirizzo dello spritesheet
; a2 indirizzo delle maschere
; a3.w larghezza spritesheet
; a4.w altezza spritesheet
;**************************************************************************************************************************************************************************
draw_sprite:
                       movem.l    d0-d7/a0-a6,-(sp)
                       move.l     draw_buffer,a0
                       move.w     d5,d2
                       asr.w      #1,d2                                                     ; width/2
                       sub.w      d2,d0                                                     ; x = x - width/2  porto l'origine al centro 
                       sub.w      viewport_x,d0                                             ; converto da coordinate globali in coordinate locali alla viewport
                       cmp.w      #-16,d0
                       blt        .return                                                   ; se x < viewport_x - 16 , allora sprite fuori dalla viewport, non lo disegno
                       cmp.w      #VIEWPORT_WIDTH+16,d0                                     ; se x >= viewport_x + VIEWPORT_WIDTH+16 allora
                       bge        .return                                                   ; sprite fuori dalla viewport, non lo disegno
                       add.w      #16,d0                                                    ; tiene conto dei 16 px non visibili per lo scroll
                       sub.w      d6,d1                                                     ; y = y - height   porto l'origine in basso
                       add.w      #20,d1                                                    ; tiene conto della fascia alta 20px fuori schermo per il clipping 
                       sub.w      viewport_y,d1
                       blt        .return                                                   ; se y < viewport_y non disegno lo sprite perchè non è visibile
                       move.w     #VIEWPORT_HEIGHT,d2
                       add.w      d6,d2                                                     ; VIEWPORT_HEIGHT + sprite_height
                       cmp.w      d2,d1
                       bge        .return                                                   ; se y >= viewport_y + PLAYFIELD_HEIGHT allora non è visibile e non lo disegno
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
                       move.w     d5,d1                                                     ; SPRITE_WIDTH
                       asr.w      #3,d1                                                     ; SPRITE_WIDTH/8
                       mulu       d1,d3                                                     ; offset_x = colonna * (SPRITE_WIDTH/8)
                       add.w      d3,a1
                       add.w      d3,a2
                       mulu       d6,d4                                                     ; SPRITE_HEIGHT * riga
                       move.w     a3,d1                                                     ; SPRITESHEET_PLAYER_W
                       asr.w      #3,d1                                                     ; SPRITESHEET_ROW_SIZE = SPRITESHEET_PLAYER_W / 8
                       mulu       d1,d4                                                     ; offset_y = riga * SPRITE_HEIGHT * SPRITESHEET_ROW_SIZE
                       add.w      d4,a1
                       add.w      d4,a2
                       moveq      #N_PLANES-1,d7
                     ; calcolo il modulo dei canali A,B (in d1)
                       move.w     a3,d3                                                     ; SPRITESHEET_PLAYER_W
                       sub.w      d5,d3                                                     ; SPRITESHEET_PLAYER_W-SPRITE_WIDTH
                       sub.w      #16,d3                                                    ; SPRITESHEET_PLAYER_W-SPRITE_WIDTH-16
                       asr.w      #3,d3                                                     ; (SPRITESHEET_PLAYER_W-SPRITE_WIDTH-16)/8
                     ; calcolo il modulo dei canali C,D
                       move.w     #PLAYFIELD_WIDTH,d4
                       sub.w      d5,d4                                                     ; PLAYFIELD_WIDTH-SPRITE_WIDTH
                       sub.w      #16,d4
                       asr.w      #3,d4                                                     ; (PLAYFIELD_WIDTH-SPRITE_WIDTH-16)/8
                     ; calcolo la dimensione della blittata
                       move.w     d6,d1
                       lsl.w      #6,d1                                                     ; SPRITE_HEIGHT<<6
                       add.w      #16,d5                                                    ; SPRITE_WIDTH+16
                       asr.w      #4,d5                                                     ; (SPRITE_WIDTH+16)/16
                       add.w      d1,d5                                                     ; SPRITE_HEIGHT<<6+(SPRITE_WIDTH+16)/16

.planeloop:
                       btst.b     #6,DMACONR(a5)                                            ; lettura dummy
.bltbusy               btst.b     #6,DMACONR(a5)                                            ; blitter pronto?
                       bne        .bltbusy
                       move.w     #$ffff,BLTAFWM(a5)                                        ; nessuna maschera
                       move.w     #$0000,BLTALWM(a5)                                        ; maschera sull'ultima word
                       move.w     d0,BLTCON0(a5)                                            
                       move.w     d2,BLTCON1(a5)
                       move.w     d3,BLTAMOD(a5)
                       move.w     d3,BLTBMOD(a5)
                       move.w     d4,BLTCMOD(a5)
                       move.w     d4,BLTDMOD(a5)
                       move.l     a2,BLTAPT(a5)
                       move.l     a1,BLTBPT(a5) 
                       move.l     a0,BLTCPT(a5)
                       move.l     a0,BLTDPT(a5)
                       move.w     d5,BLTSIZE(a5)
                       move.l     a0,d1
                       add.l      #PLF_PLANE_SIZE,d1                                        ; punto al bitplane successivo
                       move.l     d1,a0
                       move.w     a3,d6
                       asr.w      #3,d6                                                     ; SPRITESHEET_PLAYER_W/8
                       move.w     a4,d1                                                     ; SPRITESHEET_PLAYER_H
                       mulu       d1,d6                                                     ; SPR_PLANE_SIZE = (SPRITESHEET_PLAYER_W/8)*SPRITESHEET_PLAYER_H
                       move.l     a1,d1
                       add.l      d6,d1
                       move.l     d1,a1
                       dbra       d7,.planeloop
.return:
                       movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; Disegna uno sprite sul draw_buffer.
; L'immagine dello sprite viene copiata da uno spritesheet.
;
; d0.w coordinata x 
; d1.w coordinata y
; d3.w colonna dello spritesheet
; d4.w riga dello spritesheet
; d5.w larghezza sprite
; d6.w altezza sprite
; a1 indirizzo dello spritesheet
; a2 indirizzo delle maschere
; a3.w larghezza spritesheet
; a4.w altezza spritesheet
;**************************************************************************************************************************************************************************
draw_sprite2:
                       movem.l    d0-d7/a0-a4,-(sp)
                       move.l     draw_buffer,a0
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
                       move.w     d5,d1                                                     ; SPRITE_WIDTH
                       asr.w      #3,d1                                                     ; SPRITE_WIDTH/8
                       mulu       d1,d3                                                     ; offset_x = colonna * (SPRITE_WIDTH/8)
                       add.w      d3,a1
                       add.w      d3,a2
                       mulu       d6,d4                                                     ; SPRITE_HEIGHT * riga
                       move.w     a3,d1                                                     ; SPRITESHEET_PLAYER_W
                       asr.w      #3,d1                                                     ; SPRITESHEET_ROW_SIZE = SPRITESHEET_PLAYER_W / 8
                       mulu       d1,d4                                                     ; offset_y = riga * SPRITE_HEIGHT * SPRITESHEET_ROW_SIZE
                       add.w      d4,a1
                       add.w      d4,a2
                       moveq      #N_PLANES-1,d7
                     ; calcolo il modulo dei canali A,B (in d1)
                       move.w     a3,d3                                                     ; SPRITESHEET_PLAYER_W
                       sub.w      d5,d3                                                     ; SPRITESHEET_PLAYER_W-SPRITE_WIDTH
                       sub.w      #16,d3                                                    ; SPRITESHEET_PLAYER_W-SPRITE_WIDTH-16
                       asr.w      #3,d3                                                     ; (SPRITESHEET_PLAYER_W-SPRITE_WIDTH-16)/8
                     ; calcolo il modulo dei canali C,D
                       move.w     #PLAYFIELD_WIDTH,d4
                       sub.w      d5,d4                                                     ; PLAYFIELD_WIDTH-SPRITE_WIDTH
                       sub.w      #16,d4
                       asr.w      #3,d4                                                     ; (PLAYFIELD_WIDTH-SPRITE_WIDTH-16)/8
                     ; calcolo la dimensione della blittata
                       move.w     d6,d1
                       lsl.w      #6,d1                                                     ; SPRITE_HEIGHT<<6
                       add.w      #16,d5                                                    ; SPRITE_WIDTH+16
                       asr.w      #4,d5                                                     ; (SPRITE_WIDTH+16)/16
                       add.w      d1,d5                                                     ; SPRITE_HEIGHT<<6+(SPRITE_WIDTH+16)/16

.planeloop:
                       btst.b     #6,DMACONR(a5)                                            ; lettura dummy
.bltbusy               btst.b     #6,DMACONR(a5)                                            ; blitter pronto?
                       bne        .bltbusy
                       move.w     #$ffff,BLTAFWM(a5)                                        ; nessuna maschera
                       move.w     #$0000,BLTALWM(a5)                                        ; maschera sull'ultima word
                       move.w     d0,BLTCON0(a5)                                            
                       move.w     d2,BLTCON1(a5)
                       move.w     d3,BLTAMOD(a5)
                       move.w     d3,BLTBMOD(a5)
                       move.w     d4,BLTCMOD(a5)
                       move.w     d4,BLTDMOD(a5)
                       move.l     a2,BLTAPT(a5)
                       move.l     a1,BLTBPT(a5) 
                       move.l     a0,BLTCPT(a5)
                       move.l     a0,BLTDPT(a5)
                       move.w     d5,BLTSIZE(a5)
                       move.l     a0,d1
                       add.l      #PLF_PLANE_SIZE,d1                                        ; punto al bitplane successivo
                       move.l     d1,a0
                       move.w     a3,d6
                       asr.w      #3,d6                                                     ; SPRITESHEET_PLAYER_W/8
                       move.w     a4,d1                                                     ; SPRITESHEET_PLAYER_H
                       mulu       d1,d6                                                     ; SPR_PLANE_SIZE = (SPRITESHEET_PLAYER_W/8)*SPRITESHEET_PLAYER_H
                       move.l     a1,d1
                       add.l      d6,d1
                       move.l     d1,a1
                       dbra       d7,.planeloop
.return:
                       movem.l    (sp)+,d0-d7/a0-a4
                       rts


;**************************************************************************************************************************************************************************
; Disegna un calciatore.
;
; parametri:
; a0 - indirizzo della struttura dati del calciatore
;**************************************************************************************************************************************************************************
player_draw:
                       movem.l    d0-d7/a0-a6,-(sp)
                       move.w     player.x(a0),d0                                           ; coordinata x in formato fixed 10.6
                       asr.w      #6,d0                                                     ; converte x in int
                       move.w     player.y(a0),d1                                           ; coordinata y
                       asr.w      #6,d1
                       move.w     player.animx(a0),d3                                       ; colonna dello spritesheet
                       move.w     player.animy(a0),d4                                       ; riga dello spritesheet
                       move.w     #PLAYER_WIDTH,d5
                       move.w     #PLAYER_HEIGHT,d6
                       lea        player_vertical,a1                                        ; indirizzo spritesheet
                       lea        player_vertical_mask,a2                                   ; indirizzo maschere
                       move.w     #SPRITESHEET_PLAYER_W,a3
                       move.w     #SPRITESHEET_PLAYER_H,a4
                       bsr        draw_sprite
                       ; se il calciatore è selezionato, mostra l'indicatore e la shoot bar
                       tst.w      player.selected(a0)                                       ; player.selected = 0?
                       beq        .return
                       bsr        shoot_bar_draw

.return                movem.l    (sp)+,d0-d7/a0-a6
                       rts  


;**************************************************************************************************************************************************************************
; Aggiorna lo stato di un calciatore.
;**************************************************************************************************************************************************************************
player_update:
                       movem.l    d0-d7/a0-a6,-(sp)
                       lea        player0,a0                                                ; calcola la posizione x = x + v * cos(a)
                       lea        costable,a1
                       move.w     player.v(a0),d0
                       move.w     player.a(a0),d1
                       asr.w      #6,d1                                                     ; converte da fixed 10.6 ad int
                       lsl.w      #1,d1                                                     ; perchè la costable è formata da word
                       move.w     0(a1,d1.w),d3                                             ; cos(a)
                       muls       d3,d0                                                     ; v * cos(a)
                       asr.l      #6,d0 
                       add.w      d0,player.x(a0)
                       lea        sintable,a1
                       move.w     player.v(a0),d0
                       move.w     0(a1,d1.w),d3                                             ; sin(a)
                       muls       d3,d0                                                     ; v * sin(a)
                       asr.l      #6,d0
                       add.w      d0,player.y(a0)                                           ; y = y + v * sin(a) 
                       bsr        player_update_input
                       bsr        player_process_state
                       movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; Chiama la routine di gestione dello stato corrente del calciatore, usando la jumptable
;**************************************************************************************************************************************************************************
player_process_state:
                       movem.l    d0-d7/a0-a6,-(sp)
                       lea        player_state_jumptable,a1
                       lea        player0,a0
                       move.w     player.state(a0),d0
                       lsl.w      #2,d0                                                     ; moltiplica lo stato per 4 per puntare all'elemento corrispondente della tabella
                       move.l     0(a1,d0.w),a1                                             ; indirizzo della routine
                       jsr        (a1)
                       movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; Aggiorna l'input del calciatore
;**************************************************************************************************************************************************************************
player_update_input:
                       movem.l    d0-d7/a0-a6,-(sp)
                       lea        player0,a0
                       lea        player.inputdevice(a0),a1
                       move.w     player.inputtype(a0),d0
                       cmp.w      #INPUT_TYPE_JOY,d0                                        ; l'input_type è joystick?
                       beq        .joy
.joy:
                      ; in base allo stato del joystick, imposta angolo e value dell'input_device del calciatore
                       move.w     joy_state,d0
                       and.w      #$000f,d0                                                 ; preleva solo i primi 4 bit che indicano la direzione
                       cmp.w      #1,d0                                                     ; joy a dx?
                       beq        .dx
                       cmp.w      #2,d0                                                     ; joy a sx?
                       beq        .sx
                       cmp.w      #%100,d0                                                  ; joy in alto?
                       beq        .up
                       cmp.w      #%1000,d0                                                 ; joy in basso?
                       beq        .down
                       cmp.w      #%101,d0                                                  ; joy in alto a dx?
                       beq        .updx
                       cmp.w      #%110,d0                                                  ; joy in alto a sx?
                       beq        .upsx
                       cmp.w      #%1001,d0                                                 ; joy in basso a dx?
                       beq        .downdx
                       cmp.w      #%1010,d0                                                 ; joy in basso a sx?
                       beq        .downsx
                       move.w     #0,inputdevice.value(a1)
                       bra        .check_fire1
.dx:
                       move.w     #1,inputdevice.value(a1)
                       move.w     #0,inputdevice.angle(a1)
                       bra        .check_fire1
.sx:
                       move.w     #1,inputdevice.value(a1)
                       move.w     #180,inputdevice.angle(a1)
                       bra        .check_fire1
.up:
                       move.w     #1,inputdevice.value(a1)
                       move.w     #270,inputdevice.angle(a1)
                       bra        .check_fire1
.down:
                       move.w     #1,inputdevice.value(a1)
                       move.w     #90,inputdevice.angle(a1)
                       bra        .check_fire1
.updx:
                       move.w     #1,inputdevice.value(a1)
                       move.w     #315,inputdevice.angle(a1)
                       bra        .check_fire1
.upsx:
                       move.w     #1,inputdevice.value(a1)
                       move.w     #225,inputdevice.angle(a1)
                       bra        .check_fire1
.downdx:
                       move.w     #1,inputdevice.value(a1)
                       move.w     #45,inputdevice.angle(a1)
                       bra        .check_fire1
.downsx:
                       move.w     #1,inputdevice.value(a1)
                       move.w     #135,inputdevice.angle(a1)
                       bra        .check_fire1
.check_fire1:
                       move.w     joy_state,d0
                       btst.l     #4,d0                                                     ; fire1 premuto?
                       bne        .set_fire1
                       move.w     #0,inputdevice.fire1(a1)
                       bra        .check_fire2
.set_fire1:
                       move.w     #1,inputdevice.fire1(a1)
.check_fire2:
                       btst.l     #5,d0                                                     ; fire2 premuto?
                       bne        .set_fire2
                       move.w     #0,inputdevice.fire2(a1)
                       bra        .check_fire3
.set_fire2:
                       move.w     #1,inputdevice.fire2(a1)
.check_fire3:
                       btst.l     #6,d0                                                     ; fire3 premuto?
                       bne        .set_fire3
                       move.w     #0,inputdevice.fire3(a1)
                       bra        .return
.set_fire3:
                       move.w     #1,inputdevice.fire3(a1)
.return:
                       movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; Stato in cui il calciatore può correre o fermarsi
;**************************************************************************************************************************************************************************
player_state_standrun:
                       movem.l    d0-d7/a0-a6,-(sp)
                       bsr        player_get_possession
                       lea        player0,a0
                       lea        player.inputdevice(a0),a1
                       lea        ball,a2
                       ; controllo della palla
                       move.w     player.has_ball(a0),d0
                       tst.w      d0                                                        ; player.has_ball = 0?
                       beq        .check_input
                       move.w     ball.z(a2),d0
                       cmp.w      #PLAYER_H,d0                                              ; ball.z < PLAYER_H?
                       blt        .ball_control
                       bra        .check_input
.ball_control:
                       move.w     player.a(a0),d0
                       tst.w      d0                                                        ; player.a = 0?
                       beq        .azero
                       cmp.w      #45<<6,d0                                                 ; player.a = 45?
                       beq        .a45
                       cmp.w      #90<<6,d0                                                 ; player.a = 90?
                       beq        .a90
                       cmp.w      #135<<6,d0                                                ; player.a = 135?
                       beq        .a135
                       cmp.w      #180<<6,d0                                                ; player.a = 180?
                       beq        .a180
                       cmp.w      #225<<6,d0                                                ; player.a = 225?
                       beq        .a225
                       cmp.w      #270<<6,d0                                                ; player.a = 270?
                       beq        .a270
                       cmp.w      #315<<6,d0                                                ; player.a = 315?
                       beq        .a315
                       bra        .check_input
.azero:
                       move.w     player.x(a0),d0
                       add.w      #4<<6,d0
                       move.w     d0,ball.x(a2)
                       move.w     player.y(a0),d0
                       add.w      #-1<<6,d0
                       move.w     d0,ball.y(a2)
                       bra        .check_input
.a45:
                       move.w     player.x(a0),d0
                       add.w      #4<<6,d0
                       move.w     d0,ball.x(a2)
                       move.w     player.y(a0),d0
                       add.w      #2<<6,d0
                       move.w     d0,ball.y(a2)
                       bra        .check_input
.a90:
                       move.w     player.x(a0),d0
                       add.w      #1<<6,d0
                       move.w     d0,ball.x(a2)
                       move.w     player.y(a0),d0
                       add.w      #2<<6,d0
                       move.w     d0,ball.y(a2)
                       bra        .check_input
.a135:
                       move.w     player.x(a0),d0
                       add.w      #-4<<6,d0
                       move.w     d0,ball.x(a2)
                       move.w     player.y(a0),d0
                       add.w      #2<<6,d0
                       move.w     d0,ball.y(a2)
                       bra        .check_input
.a180:
                       move.w     player.x(a0),d0
                       add.w      #-4<<6,d0
                       move.w     d0,ball.x(a2)
                       move.w     player.y(a0),d0
                       add.w      #-1<<6,d0
                       move.w     d0,ball.y(a2)
                       bra        .check_input
.a225:
                       move.w     player.x(a0),d0
                       add.w      #-4<<6,d0
                       move.w     d0,ball.x(a2)
                       move.w     player.y(a0),d0
                       add.w      #-2<<6,d0
                       move.w     d0,ball.y(a2)
                       bra        .check_input
.a270:
                       move.w     player.x(a0),d0
                       add.w      #3<<6,d0
                       move.w     d0,ball.x(a2)
                       move.w     player.y(a0),d0
                       add.w      #-2<<6,d0
                       move.w     d0,ball.y(a2)
                       bra        .check_input
.a315:
                       move.w     player.x(a0),d0
                       add.w      #4<<6,d0
                       move.w     d0,ball.x(a2)
                       move.w     player.y(a0),d0
                       add.w      #-2<<6,d0
                       move.w     d0,ball.y(a2)
                       bra        .check_input
.check_input:
                       
                       move.w     inputdevice.value(a1),d0
                       tst.w      d0
                       bne        .moveplayer
                       move.w     #0,player.v(a0)
                       bra        .anim
.moveplayer:
                       move.w     player.speed(a0),player.v(a0)
                       move.w     inputdevice.angle(a1),d0
                       asl.w      #6,d0                                                     ; converte in fixed 10.6
                       move.w     d0,player.a(a0)                                           ; player.a = inputdevice.angle
.anim:
                    ; animazione
                       move.w     player.a(a0),d0
                       beq        .dx
                       cmp.w      #45<<6,d0
                       beq        .downdx
                       cmp.w      #90<<6,d0
                       beq        .down
                       cmp.w      #135<<6,d0
                       beq        .downsx
                       cmp.w      #180<<6,d0
                       beq        .sx
                       cmp.w      #225<<6,d0
                       beq        .upsx
                       cmp.w      #270<<6,d0
                       beq        .up
                       cmp.w      #315<<6,d0
                       beq        .updx
                       bra        .vert_frame
.dx:
                       move.w     #0,player.animx(a0)
                       bra        .vert_frame
.downdx:
                       move.w     #1,player.animx(a0)
                       bra        .vert_frame
.down:
                       move.w     #2,player.animx(a0)
                       bra        .vert_frame
.downsx:
                       move.w     #3,player.animx(a0)
                       bra        .vert_frame
.sx:
                       move.w     #4,player.animx(a0)
                       bra        .vert_frame
.upsx:
                       move.w     #5,player.animx(a0)
                       bra        .vert_frame
.up:
                       move.w     #6,player.animx(a0)
                       bra        .vert_frame
.updx:
                       move.w     #7,player.animx(a0)
.vert_frame:
                     ; frame verticali
                       move.w     player.v(a0),d0                                           ; se player.v <= 0 allora player.animy = 1
                       tst.w      d0
                       bgt        .run_anim                                                 ; se player.v > 0, allora cambia animy ciclicamente
                       move.w     #1,player.animy(a0)
                       bra        .check_state_change
.run_anim:
                       sub.w      #1,player.anim_counter(a0)                                ; decrementa il timer di animazione
                       ble        .adv_frame
                       bra        .check_state_change
.adv_frame:
                       move.w     player.anim_time(a0),player.anim_counter(a0)              ; ripristina il timer
                       add.w      #1,player.animy(a0)                                       ; incrementa il frame di animazione y
                       cmp.w      #3,player.animy(a0)
                       bgt        .reset_frame                                              ; player.animy > 3, allora resetta l'animazione 
                       bra        .check_state_change
.reset_frame:
                       move.w     #0,player.animy(a0)
.check_state_change:
                       move.w     player.has_ball(a0),d0
                       tst.w      d0                                                        ; player.has_ball = 0?
                       beq        .return
                       move.w     ball.z(a2),d0
                       cmp.w      #8<<6,d0                                                  ; ball.z >= 8?
                       bge        .return
                       move.w     inputdevice.fire1(a1),d0
                       tst.w      d0                                                        ; fire1 premuto?
                       beq        .check_fire2 
                     ;move.w     #3<<6,ball.v(a2)                                          ; ball.v = 2
                     ;move.w     #0,player.v(a0)
                       move.w     #0,player.timer1(a0)
                       move.w     #1,player.shoot_bar_anim(a0)
                       move.w     ball.a(a2),player.kick_angle(a0)
                       move.w     #0,ball.s(a2)
                       move.w     #PLAYER_STATE_KICK,player.state(a0)
                       bra        .return
.check_fire2           move.w     inputdevice.fire2(a1),d0                                  ; fire2 premuto?
                       bne        .lopass
                       move.w     inputdevice.fire3(a1),d0                                  ; fire3 premuto?
                       bne        .hipass
                       bra        .return
.lopass                move.w     #0,player.timer1(a0)                                      ; inizializza lo stato lopass
                       move.w     #1,player.shoot_bar_anim(a0)
                       move.w     ball.a(a2),player.kick_angle(a0)
                       move.w     #0,ball.s(a2)                
                       move.w     #PLAYER_STATE_LOPASS,player.state(a0)                     ; passa allo stato lopass
                       bra        .return
.hipass                move.w     #0,player.timer1(a0)                                      ; inizializza lo stato hipass
                       move.w     #1,player.shoot_bar_anim(a0)
                       move.w     ball.a(a2),player.kick_angle(a0)
                       move.w     #0,ball.s(a2)                
                       move.w     #PLAYER_STATE_HIPASS,player.state(a0)                     ; passa allo stato hipass
.return:
                       movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; Stato in cui il calciatore effettua un tiro.
;**************************************************************************************************************************************************************************
player_state_kick:
                       movem.l    d0-d7/a0-a6,-(sp)
                       lea        player0,a0
                       lea        ball,a1
                       lea        player.inputdevice(a0),a2
                       add.w      #1,player.timer1(a0)
                       move.w     player.timer1(a0),d0
                       cmp.w      #15,d0                                                    ; player.timer1 <= 15?
                       ble        .check_fire
                       bra        .change_state
.check_fire            move.w     inputdevice.fire1(a2),d0                                  ; fire1 premuto?
                       tst.w      d0
                       bne        .calc_v
                       bra        .change_state
.calc_v                add.w      #96,ball.v(a1)                                            ; ball.v += 1.5
                       ; velocità verticale
                       move.w     ball.v(a1),d0
                       mulu       #7,d0                                                     ; 0.1 * ball.v
                       lsr.l      #6,d0
                       move.w     d0,ball.vz(a1)                                            ; ball.vz = 0.1 * ball.v
                       ; effetto
                       move.w     inputdevice.value(a2),d0                                  ; joystick in una direzione?
                       tst.w      d0
                       beq        .update_shoot_bar
                       move.w     inputdevice.angle(a2),d0
                       beq        .add360
                       bra        .convert
.add360:
                       add.w      #360,d0
.convert               lsl.w      #6,d0                                                     ; converte in fixed 10.6
                       move.w     player.kick_angle(a0),d1
                       sub.w      d1,d0                                                     ; angle_diff = inputdevice.angle - kick_angle
                       cmp.w      #157<<6,d0                                                ; angle_diff < 157?
                       blt        .check_sign
                       bra        .update_shoot_bar
.check_sign:
                       tst.w      d0                                                        ; angle_diff < 0?
                       beq        .update_shoot_bar
                       blt        .sub_spin
                       bra        .add_spin
.sub_spin:
                       sub.w      #8<<6,ball.s(a1)
                       bra        .update_shoot_bar           
.add_spin:
                       add.w      #8<<6,ball.s(a1)
                       ; aggiorna la shoot bar
.update_shoot_bar      move.w     player.timer1(a0),d0
                       mulu       #100,d0                                                   ; converte in centesimi
                       divu       #15,d0                                                    ; player.timer1/15
                       mulu       #6,d0
                       divu       #100,d0                                                   ; converte in int
                       add.w      #1,d0                                                     ; aggiunge 1 perchè il frame 0 è lo sfondo
                       move.w     d0,player.shoot_bar_anim(a0)                              ; anima la shoot bar 
                       bra        .return
.change_state          move.w     player.timer1(a0),d0
                       cmp.w      #25,d0                                                    ; player.timer1 > 25?
                       bgt        .change_state2
                       bra        .return
.change_state2         move.w     #PLAYER_STATE_STANDRUN,player.state(a0)
                       move.w     #1,player.shoot_bar_anim(a0)
.return                movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; Stato in cui il calciatore effettua un passaggio basso.
;**************************************************************************************************************************************************************************
player_state_lopass:
                       movem.l    d0-d7/a0-a6,-(sp)
                       lea        player0,a0
                       lea        ball,a1
                       lea        player.inputdevice(a0),a2
                       add.w      #1,player.timer1(a0)
                       move.w     player.timer1(a0),d0
                       cmp.w      #15,d0                                                    ; player.timer1 <= 15?
                       ble        .check_fire
                       bra        .change_state
.check_fire            move.w     inputdevice.fire2(a2),d0                                  ; fire2 premuto?
                       tst.w      d0
                       bne        .calc_v
                       bra        .change_state
.calc_v                add.w      #128,ball.v(a1)                                           ; ball.v += 2.0
                       ; aggiorna la shoot bar
.update_shoot_bar      move.w     player.timer1(a0),d0
                       mulu       #100,d0                                                   ; converte in centesimi
                       divu       #15,d0                                                    ; player.timer1/15
                       mulu       #6,d0
                       divu       #100,d0                                                   ; converte in int
                       add.w      #1,d0                                                     ; aggiunge 1 perchè il frame 0 è lo sfondo
                       move.w     d0,player.shoot_bar_anim(a0)                              ; anima la shoot bar 
                       bra        .return
.change_state          move.w     player.timer1(a0),d0
                       cmp.w      #25,d0                                                    ; player.timer1 > 25?
                       bgt        .change_state2
                       bra        .return
.change_state2         move.w     #PLAYER_STATE_STANDRUN,player.state(a0)
                       move.w     #1,player.shoot_bar_anim(a0)
.return                movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; Stato in cui il calciatore effettua passaggio alto.
;**************************************************************************************************************************************************************************
player_state_hipass:
                       movem.l    d0-d7/a0-a6,-(sp)
                       lea        player0,a0
                       lea        ball,a1
                       lea        player.inputdevice(a0),a2
                       add.w      #1,player.timer1(a0)
                       move.w     player.timer1(a0),d0
                       cmp.w      #15,d0                                                    ; player.timer1 <= 15?
                       ble        .check_fire
                       bra        .change_state
.check_fire            move.w     inputdevice.fire3(a2),d0                                  ; fire3 premuto?
                       tst.w      d0
                       bne        .calc_v
                       bra        .change_state
.calc_v                add.w      #64,ball.v(a1)                                            ; ball.v += 1.0
                       ; velocità verticale
                       move.w     ball.v(a1),d0
                       add.w      #2<<6,d0                                                  ; 2 + ball.v
                       mulu       #19,d0                                                    ; 0.3 * (2+ball.v)
                       lsr.l      #6,d0
                       move.w     d0,ball.vz(a1)                                            ; ball.vz = 0.3 * (2+ball.v)
                       ; aggiorna la shoot bar
.update_shoot_bar      move.w     player.timer1(a0),d0
                       mulu       #100,d0                                                   ; converte in centesimi
                       divu       #15,d0                                                    ; player.timer1/15
                       mulu       #6,d0
                       divu       #100,d0                                                   ; converte in int
                       add.w      #1,d0                                                     ; aggiunge 1 perchè il frame 0 è lo sfondo
                       move.w     d0,player.shoot_bar_anim(a0)                              ; anima la shoot bar 
                       bra        .return
.change_state          move.w     player.timer1(a0),d0
                       cmp.w      #25,d0                                                    ; player.timer1 > 25?
                       bgt        .change_state2
                       bra        .return
.change_state2         move.w     #PLAYER_STATE_STANDRUN,player.state(a0)
                       move.w     #1,player.shoot_bar_anim(a0)
.return                movem.l    (sp)+,d0-d7/a0-a6 
                       rts


;**************************************************************************************************************************************************************************
; Verifica se il calciatore può entrare in possesso di palla.
;**************************************************************************************************************************************************************************
player_get_possession:
                       movem.l    d0-d7/a0-a6,-(sp)
                       lea        player0,a0
                       lea        ball,a1
                       move.w     player.x(a0),d0
                       move.w     player.y(a0),d1
                       move.w     ball.x(a1),d2
                       move.w     ball.y(a1),d3
                       bsr        calc_dist
                       cmp.l      #49,d2                                                    ; distanza palla-calciatore <7?
                       blo        .checkz
                       bra        .no_possession
.checkz:
                       cmp.w      #PLAYER_H<<6,ball.z(a1)                                   ; ball.z < PLAYER_H ?
                       blt        .ball_possession
                       bra        .no_possession
.ball_possession:
                    ;  move.w     player.v(a0),d0
                    ;  mulu       #58,d0
                    ;  asr.l      #6,d0                                                    
                    ;  move.w     d0,ball.v(a1)                                             ; ball.v = 0.9 * player.v
                       move.w     player.v(a0),ball.v(a1)                                   ; ball.v = player.v
                       move.w     player.a(a0),ball.a(a1)                                   ; ball.a = player.a
                       move.w     #0,ball.z(a1)                                             ; ball.z = 0
                       move.w     #0,ball.vz(a1)                                            ; ball.vz = 0
                       move.w     player.id(a0),ball.owner(a1)
                       move.w     #1,player.has_ball(a0)
                       bra        .return
.no_possession:
                       move.w     #0,ball.owner(a1)
                       move.w     #0,player.has_ball(a0)
.return:
                       movem.l    (sp)+,d0-d7/a0-a6
                       rts




;**************************************************************************************************************************************************************************
; calcola la distanza tra due punti.
;
; input:
; d0.w - x1
; d1.w - y1
; d2.w - x2
; d3.w - y2
;
; ritorna:
; d2.l - distanza al quadrato
;**************************************************************************************************************************************************************************
calc_dist:
                       asr.w      #6,d0                                                     ; converto da fixed 10.6 a int tutte le coordinate
                       asr.w      #6,d1
                       asr.w      #6,d2
                       asr.w      #6,d3
                       sub.w      d0,d2                                                     ;  x2 - x1
                       ext.l      d2
                       muls       d2,d2                                                     ; (x2 - x1)^2
                       sub.w      d1,d3                                                     ; y2 - y1
                       muls       d3,d3                                                     ; (y2 - y1)^2
                       add.l      d3,d2                                                     ; dist^2
                       rts


;**************************************************************************************************************************************************************************
; disegna la palla
;**************************************************************************************************************************************************************************
ball_draw:
                       movem.l    d0-d7/a0-a6,-(sp)
                       lea        ball,a0
                       move.w     ball.x(a0),d0
                       asr        #6,d0                                                     ; converte da fixed 10.6 a int
                       move.w     ball.y(a0),d1
                       asr.w      #6,d1                                                     ; converte da fixed 10.6 a int
                       movem.l    d0,-(sp)
                       move.w     #4,d3                                                     ; animx
                       move.w     ball.animy(a0),d4
                       move.w     #BALL_WIDTH,d5
                       move.w     #BALL_HEIGHT,d6 
                       lea        ball_sprite,a1
                       lea        ball_mask,a2
                       move.w     #SPRITESHEET_BALL_W,a3
                       move.w     #SPRITESHEET_BALL_H,a4
                     ; disegna prima l'ombra
                       add.w      #1,d0                                                     ; x = x + 1
                       add.w      #3,d1                                                     ; y = y + 3
                       bsr        draw_sprite
                     ; disegna la palla
                       movem.l    (sp)+,d0
                       move.w     ball.y(a0),d1
                       sub.w      ball.z(a0),d1                                             ; y = y -z
                       asr.w      #6,d1                                                     ; converte da fixed 10.6 a int
                       move.w     ball.animx(a0),d3 
                       bsr        draw_sprite
                       movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; aggiorna lo stato della palla
;**************************************************************************************************************************************************************************
ball_update:
                       movem.l    d0-d7/a0-a6,-(sp)
                       ; calcola lo spin (effetto)
                       lea        ball,a0
                       move.w     ball.s(a0),d0
                       muls       #SPIN_FACTOR,d0                                           ; SPIN_FACTOR * s
                       asr.l      #6,d0
                       add.w      d0,ball.a(a0)                                             ; a = SPIN_FACTOR * s
                       move.w     #1<<6,d0
                       sub.w      #SPIN_DAMPENING,d0                                        ; 1 - SPIN_DAMPENING
                       move.w     ball.s(a0),d1
                       muls       d1,d0                                                     ; s *= 1 - SPIN_DAMPENING
                       asr.l      #6,d0
                       move.w     d0,ball.s(a0)
                       ; aggiorna la posizione                    
                       lea        costable,a1                                               ; calcola la posizione x = x + v * cos(a)
                       move.w     ball.v(a0),d0
                       move.w     ball.a(a0),d1
                       lsr.w      #6,d1                                                     ; converte in int
                       cmp.w      #360,d1                                                   ; a > 360 ?
                       bgt        .gt360
                       bra        .continue
.gt360:
                       sub.w      #360,d1                                                   ; se a>360 allora a = a - 360
.continue:
                       lsl.w      #1,d1                                                     ; perchè la costable è formata da word
                       move.w     0(a1,d1.w),d3                                             ; cos(a)
                       muls       d3,d0                                                     ; v * cos(a)
                       asr.l      #6,d0
                       add.w      d0,ball.x(a0)
                       lea        sintable,a1
                       move.w     ball.v(a0),d0
                       move.w     0(a1,d1.w),d3                                             ; sin(a)
                       muls       d3,d0                                                     ; v * sin(a)
                       asr.l      #6,d0
                       add.w      d0,ball.y(a0)                                             ; y = y + v * sin(a)
                       move.w     ball.vz(a0),d0
                       add.w      d0,ball.z(a0)
                       ; applica l'attrito dell'erba
                       cmp.w      #1<<6,ball.z(a0)                                          ; Z < 1?
                       blt        .grass_friction
                       bra        .test_gravity
.grass_friction:
                       move.w     ball.v(a0),d0
                       tst.w      d0                                                        ; v < 0?
                       blt        .change_sign
                       bra        .apply_friction
.change_sign:
                       muls       #-1<<6,d0
                       asr.l      #6,d0
.apply_friction:
                       muls.w     #GRASS_FRICTION,d0                                        ; GRASS_FRICTION * abs(v)
                       asr.l      #6,d0
                       sub.w      d0,ball.v(a0)                                             ; v = v - GRASS_FRICTION * abs(v)
                       tst.w      ball.v(a0)                                                ; v <= 0?
                       ble        .v_le_zero
                       cmp.w      #10,ball.v(a0)
                       ble        .v_le_zero
                       bra        .test_gravity
.v_le_zero:
                       move.w     #0,ball.v(a0)                                             ; v = 0
.test_gravity:
                       ; applica la gravità
                       tst.w      ball.z(a0)
                       bgt        .gravity                                                  ; se z > 0 applica la gravità
                       bra        .rimbalzo
.gravity:
                       sub.w      #GRAVITY,ball.vz(a0)                                      ; vz = vz - GRAVITY
                       move.w     ball.vz(a0),d0
.rimbalzo:
                       tst.w      ball.z(a0)
                       blt        .rimbalzo2                                                ; se z < 0
                       bra        .anim
.rimbalzo2:
                       tst.w      ball.vz(a0)
                       blt        .rimbalzo3                                                ; se vz < 0
                       bra        .anim
.rimbalzo3:
                       move.w     #0,ball.z(a0)
                       cmp.w      #-326,ball.vz(a0)                                         ; vz > -5.1?
                       bgt        .zero
                       move.w     ball.vz(a0),d0                                            ; vz = vz * - BOUNCE 
                       muls       #-BOUNCE,d0
                       asr.l      #6,d0
                       move.w     d0,ball.vz(a0)
                       bra        .anim
.zero:
                       move.w     #0,ball.vz(a0)
.anim:
                       ; animazione
                       move.w     ball.v(a0),d0                                             ; se v = 0 allora non cambio frame
                       tst.w      d0
                       beq        .return
                       sub.w      #1,ball.anim_timer(a0)
                       ble        .adv_frame
                       bra        .return
.adv_frame:
                       move.w     ball.anim_duration(a0),ball.anim_timer(a0)                ; ripristina il timer
                       add.w      #1,ball.animx(a0)
                       cmp.w      #3,ball.animx(a0)
                       bgt        .reset_frame
                       bra        .return
.reset_frame:
                       move.w     #0,ball.animx(A0)

                    ;  move.w     ball.v(a0),d0
                    ;  divu       #20,d0                                                    ; ball.v / 20                                                    
                    ;  add.w      d0,ball.f(a0)                                             ; ball.f = ball.f + ball.v / 20
                    ;  move.w     ball.f(a0),d0
                    ;  ext.l      d0
                    ;  divu       #4,d0                                                     ; ball.f = ball.f / 4
                    ;  swap       d0                                                        ; resto (compreso 0-3)
                    ;  move.w     d0,ball.animx(a0)                                               
.return:
                       bsr        ball_keep_in_field
                       lea        ball,a0
                       tst.w      ball.x(a0)                                                ; ball.x < 0?
                       blt        .neg
                       move.w     #1,ball.x_side(a0)
                       bra        .return2
.neg:
                       move.w     #-1,ball.x_side(a0)
.return2:
                       movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
; Mantiene la palla nel campo di gioco.
;**************************************************************************************************************************************************************************
ball_keep_in_field:
                       lea        ball,a0
                       move.w     ball.x(a0),d0
                       cmp.w      #BALL_XMIN,d0                                             ; ball.x <= BALL_XMIN?
                       ble        .xmin
                       cmp.w      #BALL_XMAX,d0                                             ; ball.x >= BALL_XMAX?
                       bge        .xmax
                       move.w     ball.y(a0),d0
                       cmp.w      #BALL_YMIN,d0                                             ; ball.y <= BALL_YMIN?
                       ble        .ymin
                       cmp.w      #BALL_YMAX,d0                                             ; ball.y >= BALL_YMAX?
                       bge        .ymax
                       bra        .return
.xmin:
                       move.w     #BALL_XMIN,ball.x(a0)                                     ; ball.x = BALL_XMIN
                       move.w     ball.v(a0),d0
                       muls       #32,d0
                       asr.l      #6,d0
                       move.w     d0,ball.v(a0)                                             ; ball.v = ball.v * 0.5
                       move.w     ball.a(a0),d0
                       move.w     #180<<6,d1
                       sub.w      d0,d1                                                     ; ball.a = 180 - ball.a
                       blt        .convert                                                  ; ball.a < 0?
                       bra        .continue
.convert:
                       add.w      #360<<6,d1                                                ; ball.a = 360 - ball.a
.continue:
                       move.w     d1,ball.a(a0)
                       bra        .return
.xmax:
                       move.w     #BALL_XMAX,ball.x(a0)                                     ; ball.x = BALL_XMAX
                       move.w     ball.v(a0),d0
                       muls       #32,d0
                       asr.l      #6,d0
                       move.w     d0,ball.v(a0)                                             ; ball.v = ball.v * 0.5
                       move.w     ball.a(a0),d0
                       move.w     #180<<6,d1
                       sub.w      d0,d1                                                     ; ball.a = 180 - ball.a
                       blt        .makepos
                       bra        .continue2
.makepos:
                       add.w      #360<<6,d1
.continue2:
                       move.w     d1,ball.a(a0)
                       bra        .return
.ymin:
                       move.w     #BALL_YMIN,ball.y(a0)                                     ; ball.y = BALL_YMIN
                       move.w     ball.v(a0),d0
                       muls       #32,d0
                       asr.l      #6,d0
                       move.w     d0,ball.v(a0)                                             ; ball.v = ball.v * 0.5
                       move.w     ball.a(a0),d0
                       move.w     #360<<6,d1
                       sub.w      d0,d1                                                     ; ball.a = 360 - ball.a
                       move.w     d1,ball.a(a0)
                       bra        .return
.ymax:
                       move.w     #BALL_YMAX,ball.y(a0)                                     ; ball.y = BALL_YMAX
                       move.w     ball.v(a0),d0
                       muls       #32,d0
                       asr.l      #6,d0
                       move.w     d0,ball.v(a0)                                             ; ball.v = ball.v * 0.5
                       move.w     ball.a(a0),d0
                       move.w     #360<<6,d1
                       sub.w      d0,d1                                                     ; ball.a = 360 - ball.a
                       move.w     d1,ball.a(a0)
.return:
                       move.w     ball.s(a0),d0
                       muls       #-1<<6,d0 
                       asr.l      #6,d0
                       move.w     d0,ball.s(a0)                                             ; ball.s = - ball.s
                       rts


;**************************************************************************************************************************************************************************
; Indica se la palla si trova nell'area di tiro
;
; ritorna:
; d0.w - se la palla si trova nell'area di tiro 1, 0 altrimenti 
;**************************************************************************************************************************************************************************
ball_is_inside_shot_area:
                       movem.l    a0-a1,-(sp) 
                       lea        ball,a0
                       lea        player0,a1
                       move.w     player.side(a1),d1
                       muls       #-1,d1                                                    ; -player.side
                       move.w     ball.y(a0),d0
                       muls       d1,d0                                                     ; -player.side * ball.y
                       cmp.w      #GOAL_LINE<<6,d0                                          ; (player.side * ball.y) > GOAL_LINE?
                       bgt        .checkx
                       move.w     #0,d0
                       bra        .return
.checkx:
                       move.w     ball.x(a0),d0
                       muls       ball.x_side(a0),d0
                       cmp.w      #PENALY_AREA_HALF_WIDTH<<6,d0                             ; ball.x * ball.x_side < PENALY_AREA_HALF_WIDTH?
                       blt        .ret1
                       move.w     #0,d0
                       bra        .return
.ret1:
                       move.w     #1,d0
.return:
                       movem.l    (sp)+,a0-a1
                       rts


;**************************************************************************************************************************************************************************
; Disegna la shootbar.
;**************************************************************************************************************************************************************************
shoot_bar_draw:
                       movem.l    d0-d7/a0-a6,-(sp)

                       lea        player0,a0

                       ; disegna lo sfondo della shoot bar
                       move.w     player.x(a0),d0                                           
                       asr.w      #6,d0                                                     ; converte x da fixed 10.6 ad int
                       move.w     player.y(a0),d1                                           
                       asr.w      #6,d1                                                     ; converte y da fixed 10.6 ad int
                       sub.w      #PLAYER_HEIGHT-5,d1                                       ; sposta la shoot bar sopra al giocatore
                       move.w     #0,d3                                                     ; colonna dello spritesheet
                       move.w     #0,d4                                                     ; riga dello spritesheet
                       move.w     #PLAYER_WIDTH,d5                                          ; larghezza sprite
                       move.w     #5,d6                                                     ; altezza sprite
                       lea        shoot_bar,a1                                              ; indirizzo spritesheet
                       lea        shoot_bar_mask,a2                                         ; indirizzo maschere
                       move.w     #16,a3                                                    ; larghezza spritesheet
                       move.w     #40,a4                                                    ; altezza spritesheet
                       bsr        draw_sprite
                      
                       ; disegna la shoot bar
                       move.w     player.shoot_bar_anim(a0),d4
                       bsr        draw_sprite
                      
.return                movem.l    (sp)+,d0-d7/a0-a6
                       rts


;**************************************************************************************************************************************************************************
draw_char:
                       ; parametri: 
                       ; d0.w coordinata x 
                       ; d1.w coordinata y
                       ; d3.b codice ascii del carattere
                       
                       movem.l    d0-d7/a0-a6,-(sp)

                       ext.w      d3
                       sub.w      #44,d3                                                    ; sottrae codice ascii di ',' in modo da avere un indica che parte da zero
                       divu       #13,d3                                                    ; divido per il numero di caratteri in una riga
                       move.w     d3,d4                                                     ; riga dello spritesheet
                       swap       d3                                                        ; colonna: è il resto della divisione, che viene spostato nella parte meno signif.
                       move.w     #16,d5                                                    ; larghezza sprite
                       move.w     #7,d6                                                     ; altezza sprite
                       lea        font,a1                                                   ; indirizzo dello spritesheet
                       lea        font_mask,a2                                              ; indirizzo delle maschere
                       move.w     #208,a3                                                   ; larghezza spritesheet
                       move.w     #28,a4                                                    ; altezza spritesheet
                       bsr        draw_sprite2

                       movem.l    (sp)+,d0-d7/a0-a6
                       rts

;**************************************************************************************************************************************************************************
draw_string:
                       ; parametri:
                       ; d0.w coordinata x 
                       ; d1.w coordinata y
                       ; a0   indirizzo della stringa, terminata da uno 0

                       movem.l    d0-d7/a0-a6,-(sp)

.loop                  move.b     (a0)+,d3                                                  ; preleva un carattere della stringa
                       tst.b      d3                                                        ; il codice carattere è 0?
                       beq        .return
                       bsr        draw_char
                       add.w      #7,d0                                                     ; sposta la coordinata x sul carattere successivo
                       bra        .loop

.return                movem.l    (sp)+,d0-d7/a0-a6
                       rts

;**************************************************************************************************************************************************************************
dec_2_string:
                       ; converte un numero decimale in una stringa
                       ;
                       ; parametri:
                       ; d0.w - numero da convertire (-32767,32767)
                       ; a0   - indirizzo della stringa
                       movem.l    d0-d7/a0-a6,-(sp)

                       btst.l     #15,d0                                                    ; numero negativo?
                       bne        .compl2
                       bra        .convert
.compl2                move.w     #$ffff,d1
                       sub.w      d0,d1
                       add.w      #1,d1
                       move.w     d1,d0
                       move.b     #'-',(a0)+                                                ; segno meno
.convert
                       ext.l      d0
                       divu       #10000,d0
                       bne        .write
                       bra        .continue
.write                 add.w      #'0',d0                                                   ; converte in ascii
                       move.b     d0,(a0)+                                                  ; scrive la cifra numerica nella stringa
.continue              swap       d0                                                        ; considera il resto
                       ext.l      d0
                       divu       #1000,d0
                       bne        .write2
                       bra        .continue2
.write2                add.w      #'0',d0                                                   ; converte in ascii
                       move.b     d0,(a0)+                                                  ; scrive la cifra numerica nella stringa
.continue2             swap       d0
                       ext.l      d0 
                       divu       #100,d0
                       bne        .write3
                       bra        .continue3
.write3                add.w      #'0',d0                                                   ; converte in ascii
                       move.b     d0,(a0)+                                                  ; scrive la cifra numerica nella stringa
.continue3             swap       d0
                       ext.l      d0
                       divu       #10,d0
                       bne        .write4
                       bra        .continue4
.write4                add.w      #'0',d0                                                   ; converte in ascii
                       move.b     d0,(a0)+                                                  ; scrive la cifra numerica nella stringa
.continue4             swap       d0
                       ext.l      d0
                       divu       #1,d0
                       bne        .write5
                       bra        .continue5
.write5                add.w      #'0',d0                                                   ; converte in ascii
                       move.b     d0,(a0)+                                                  ; scrive la cifra numerica nella stringa
.continue5             move.b     #0,(a0)                                                   ; terminatore
.return                movem.l    (sp)+,d0-d7/a0-a6   
                       rts


;**************************************************************************************************************************************************************************
hex_2_string:
                       ; converte un numero esadecimale in una stringa
                       ;
                       ; parametri:
                       ; d0.w - numero esadecimale da convertire ($0000,$FFFF)
                       ; a0   - indirizzo della stringa
                       movem.l    d0-d7/a0-a6,-(sp)

                       and.l      #$ffff,d0
                       divu       #$1000,d0
                       cmp.w      #10,d0
                       bge        .conv
                       add.w      #'0',d0                                                   ; converte in ascii
                       bra        .write
.conv                  sub.w      #10,d0
                       add.w      #'A',d0                       
.write                 move.b     d0,(a0)+                                                  ; scrive la cifra numerica nella stringa
                       swap       d0                                                        ; considera il resto
                       and.l      #$ffff,d0
                       divu       #$100,d0
                       cmp.w      #10,d0
                       bge        .conv2
                       add.w      #'0',d0                                                   ; converte in ascii
                       bra        .write2
.conv2                 sub.w      #10,d0
                       add.w      #'A',d0                       
.write2                move.b     d0,(a0)+                                                  ; scrive la cifra numerica nella stringa
                       swap       d0                                                        ; considera il resto
                       and.l      #$ffff,d0
                       divu       #$10,d0
                       cmp.w      #10,d0
                       bge        .conv3
                       add.w      #'0',d0                                                   ; converte in ascii
                       bra        .write3
.conv3                 sub.w      #10,d0
                       add.w      #'A',d0                       
.write3                move.b     d0,(a0)+                                                  ; scrive la cifra numerica nella stringa
                       swap       d0                                                        ; considera il resto
                       and.l      #$ffff,d0
                       divu       #$1,d0
                       cmp.w      #10,d0
                       bge        .conv4
                       add.w      #'0',d0                                                   ; converte in ascii
                       bra        .write4
.conv4                 sub.w      #10,d0
                       add.w      #'A',d0                       
.write4                move.b     d0,(a0)+                                                  ; scrive la cifra numerica nella stringa
                       move.b     #0,(a0)                                                   ; terminatore
.return                movem.l    (sp)+,d0-d7/a0-a6   
                       rts


;**************************************************************************************************************************************************************************
test_font:
                       ;movem.l    d0-d3/a0,-(sp)
                       
                      ;  move.b     #'8',d3                                                   ; codice ascii del carattere
                      ;  bsr        draw_char
                       ;lea        test_string,a0
                       lea        dec_string,a0
                       ;move.w     #$fa10,d0
                       move.w     #-12569,d0
                       ;bsr        hex_2_string
                       bsr        dec_2_string
                       move.w     #16,d0                                                    ; coordinata x
                       move.w     #27,d1                                                    ; coordinata y
                       bsr        draw_string
                       
                       ;movem.l    (sp)+,d0-d3/a0
                       rts


;**************************************************************************************************************************************************************************
; Disegna tutti i calciatori di una squadra
;**************************************************************************************************************************************************************************
team_draw:
                       movem.l    d0-d7/a0-a6,-(sp)

                       move.l     home_team,a1
                       lea        team.players(a1),a0 
                       moveq      #11-1,d7
.loop:
                       bsr        player_draw
                       add.l      #player.length,a0
                       dbra       d7,.loop

.return                movem.l    (sp)+,d0-d7/a0-a6
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

viewport_x             dc.w       0
viewport_y             dc.w       0

camera_x               dc.w       0
camera_y               dc.w       0

view_buffer            dc.l       playfield1                                                ; buffer visualizzato sullo schermo
draw_buffer            dc.l       playfield2                                                ; buffer di disegno (non visibile)

joy_state              dc.w       0                                                         ; stato dello joystick

player0                dc.w       -20<<6                                                    ; posizione x
                       dc.w       -10<<6                                                    ; posizione y
                       dc.w       0<<6                                                      ; player.v
                       dc.w       90<<6                                                     ; player.a
                       dc.w       0                                                         ; player.animx
                       dc.w       1                                                         ; player.animy
                       dc.w       PLAYER_STATE_STANDRUN                                     ; stato
                       dc.w       0                                                         ; inputdevice.value
                       dc.w       0                                                         ; inputdevice.angle
                       dc.w       0                                                         ; inputdevice.fire1
                       dc.w       0                                                         ; inputdevice.fire2
                       dc.w       0                                                         ; inputdevice.fire3
                       dc.w       2<<6                                                      ; player.speed
                       dc.w       INPUT_TYPE_JOY                                            ; player.inputtype
                       dc.w       4                                                         ; player.anim_time
                       dc.w       4                                                         ; player.anim_counter
                       dc.w       1                                                         ; player.id 
                       dc.w       0                                                         ; player.has_ball
                       dc.w       0                                                         ; player.timer1
                       dc.w       -1                                                        ; player.side
                       dc.w       1                                                         ; player.selected
                       dc.w       0                                                         ; player.kick_angle
                       dc.w       1                                                         ; player.shoot_bar_anim

ball                   dc.w       10<<6                                                     ; ball.x
                       dc.w       0<<6                                                      ; ball.y
                       dc.w       0<<6                                                      ; ball.z
                       dc.w       0<<6                                                      ; ball.v
                       dc.w       0<<6                                                      ; ball.vz 19
                       dc.w       0<<6                                                      ; ball.a
                       dc.w       0<<6                                                      ; ball.s
                       dc.w       0                                                         ; ball.animx
                       dc.w       0                                                         ; ball.animy
                       dc.w       0                                                         ; ball.f    
                       dc.w       2                          F                              ; ball.anim_timer
                       dc.w       2                                                         ; ball.anim_duration
                       dc.w       0                                                         ; ball.owner
                       dc.w       0                                                         ; ball.x_side                    

; tabella con le routine da eseguire per ciascun stato del calciatore
player_state_jumptable:  
                       dc.l       player_state_standrun
                       dc.l       player_state_kick
                       dc.l       player_state_lopass
                       dc.l       player_state_hipass


test_string            dc.b       "TEST DRAW STRING",0,0
                       even

dec_string             dcb.b      8

                       include    "teams.i"

home_team              dc.l       team_inter
away_team              dc.l       0

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



;**************************************************************************************************************************************************************************
; dati grafici
;**************************************************************************************************************************************************************************

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


;**************************************************************************************************************************************************************************
; Incorporamento grafica
;**************************************************************************************************************************************************************************
pitch                  incbin     "gfx/pitch_complete.raw"                                  ; immagine del campo 640 x 817, 4 bpp

player_vertical        incbin     "gfx/player_vertical_final2.raw"                          ; spritesheet del giocatore con maglia verticale 128 x 80
player_vertical_mask   incbin     "gfx/player_vertical_final2.mask"

ball_sprite            incbin     "gfx/ball.raw"                                            ; 80x4, 5 frames
ball_mask              incbin     "gfx/ball.mask"

shoot_bar              incbin     "gfx/shoot_bar.raw"                                       ; barra potenza tiro 16x40, 4bpp, 1 colonna, 8 righe, frame_size: 16x5
shoot_bar_mask         incbin     "gfx/shoot_bar.mask"

font                   incbin     "gfx/font.raw"                                            ; font 4bpp, 13 x 4, frame_size: 16x7
font_mask              incbin     "gfx/font.mask"


;**************************************************************************************************************************************************************************
                       SECTION    dati_azzerati,BSS_C                                       ; sezione contenente i dati azzerati
;**************************************************************************************************************************************************************************  
playfield1             ds.b       (PLAYFIELD_WIDTH/8)*PLAYFIELD_HEIGHT*N_PLANES 
playfield2             ds.b       (PLAYFIELD_WIDTH/8)*PLAYFIELD_HEIGHT*N_PLANES 

                       END 