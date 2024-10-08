;**************************************************************************************************************************************************************************
; Dati delle squadre
;**************************************************************************************************************************************************************************

; team.name              rs.b       16
; team.short_name        rs.b       4
; team.side              rs.w       1                                                         ; indica la propria area: -1 sopra, 1 sotto
; team.players           rs.b       player.length * NUM_PLAYERS_PER_TEAM

;**************************************************************************************************************************************************************************
; INTER
;**************************************************************************************************************************************************************************
team_inter:
           dc.b     'Inter',0                ; team.name
           dcb.b    10
           dc.b     'INT',0                  ; short_name
           dc.w     -1                       ; team.side
           dc.l     0                        ; team.near_ball
.player1   dc.w     -20<<6                   ; posizione x
           dc.w     0<<6                     ; posizione y
           dc.w     0<<6                     ; player.v
           dc.w     0<<6                     ; player.a
           dc.w     0                        ; player.animx
           dc.w     1                        ; player.animy
           dc.w     PLAYER_STATE_STANDRUN    ; stato
           dc.w     0                        ; inputdevice.value
           dc.w     0                        ; inputdevice.angle
           dc.w     0                        ; inputdevice.fire1
           dc.w     0                        ; inputdevice.fire2
           dc.w     0                        ; inputdevice.fire3
           dc.w     2<<6                     ; player.speed
           dc.w     INPUT_TYPE_JOY           ; player.inputtype
           dc.w     4                        ; player.anim_time
           dc.w     4                        ; player.anim_counter
           dc.w     1                        ; player.id 
           dc.w     0                        ; player.has_ball
           dc.w     0                        ; player.timer1
           dc.w     -1                       ; player.side
           dc.w     1                        ; player.selected
           dc.w     0                        ; player.kick_angle
           dc.w     1                        ; player.shoot_bar_anim
           dc.w     0                        ; player.ball_distance
.player2   dc.w     -20<<6                   ; posizione x
           dc.w     -14<<6                   ; posizione y
           dc.w     0<<6                     ; player.v
           dc.w     0<<6                     ; player.a
           dc.w     0                        ; player.animx
           dc.w     1                        ; player.animy
           dc.w     PLAYER_STATE_STANDRUN    ; stato
           dc.w     0                        ; inputdevice.value
           dc.w     0                        ; inputdevice.angle
           dc.w     0                        ; inputdevice.fire1
           dc.w     0                        ; inputdevice.fire2
           dc.w     0                        ; inputdevice.fire3
           dc.w     2<<6                     ; player.speed
           dc.w     INPUT_TYPE_AI            ; player.inputtype
           dc.w     4                        ; player.anim_time
           dc.w     4                        ; player.anim_counter
           dc.w     1                        ; player.id 
           dc.w     0                        ; player.has_ball
           dc.w     0                        ; player.timer1
           dc.w     -1                       ; player.side
           dc.w     0                        ; player.selected
           dc.w     0                        ; player.kick_angle
           dc.w     1                        ; player.shoot_bar_anim
           dc.w     0                        ; player.ball_distance
.player3   dc.w     -20<<6                   ; posizione x
           dc.w     -28<<6                   ; posizione y
           dc.w     0<<6                     ; player.v
           dc.w     0<<6                     ; player.a
           dc.w     0                        ; player.animx
           dc.w     1                        ; player.animy
           dc.w     PLAYER_STATE_STANDRUN    ; stato
           dc.w     0                        ; inputdevice.value
           dc.w     0                        ; inputdevice.angle
           dc.w     0                        ; inputdevice.fire1
           dc.w     0                        ; inputdevice.fire2
           dc.w     0                        ; inputdevice.fire3
           dc.w     2<<6                     ; player.speed
           dc.w     INPUT_TYPE_AI            ; player.inputtype
           dc.w     4                        ; player.anim_time
           dc.w     4                        ; player.anim_counter
           dc.w     1                        ; player.id 
           dc.w     0                        ; player.has_ball
           dc.w     0                        ; player.timer1
           dc.w     -1                       ; player.side
           dc.w     0                        ; player.selected
           dc.w     0                        ; player.kick_angle
           dc.w     1                        ; player.shoot_bar_anim
           dc.w     0                        ; player.ball_distance
.player4   dc.w     -20<<6                   ; posizione x
           dc.w     -42<<6                   ; posizione y
           dc.w     0<<6                     ; player.v
           dc.w     0<<6                     ; player.a
           dc.w     0                        ; player.animx
           dc.w     1                        ; player.animy
           dc.w     PLAYER_STATE_STANDRUN    ; stato
           dc.w     0                        ; inputdevice.value
           dc.w     0                        ; inputdevice.angle
           dc.w     0                        ; inputdevice.fire1
           dc.w     0                        ; inputdevice.fire2
           dc.w     0                        ; inputdevice.fire3
           dc.w     2<<6                     ; player.speed
           dc.w     INPUT_TYPE_AI            ; player.inputtype
           dc.w     4                        ; player.anim_time
           dc.w     4                        ; player.anim_counter
           dc.w     1                        ; player.id 
           dc.w     0                        ; player.has_ball
           dc.w     0                        ; player.timer1
           dc.w     -1                       ; player.side
           dc.w     0                        ; player.selected
           dc.w     0                        ; player.kick_angle
           dc.w     1                        ; player.shoot_bar_anim
           dc.w     0                        ; player.ball_distance
.player5   dc.w     -20<<6                   ; posizione x
           dc.w     -56<<6                   ; posizione y
           dc.w     0<<6                     ; player.v
           dc.w     0<<6                     ; player.a
           dc.w     0                        ; player.animx
           dc.w     1                        ; player.animy
           dc.w     PLAYER_STATE_STANDRUN    ; stato
           dc.w     0                        ; inputdevice.value
           dc.w     0                        ; inputdevice.angle
           dc.w     0                        ; inputdevice.fire1
           dc.w     0                        ; inputdevice.fire2
           dc.w     0                        ; inputdevice.fire3
           dc.w     2<<6                     ; player.speed
           dc.w     INPUT_TYPE_AI            ; player.inputtype
           dc.w     4                        ; player.anim_time
           dc.w     4                        ; player.anim_counter
           dc.w     1                        ; player.id 
           dc.w     0                        ; player.has_ball
           dc.w     0                        ; player.timer1
           dc.w     -1                       ; player.side
           dc.w     0                        ; player.selected
           dc.w     0                        ; player.kick_angle
           dc.w     1                        ; player.shoot_bar_anim
           dc.w     0                        ; player.ball_distance
.player6   dc.w     -20<<6                   ; posizione x
           dc.w     -70<<6                   ; posizione y
           dc.w     0<<6                     ; player.v
           dc.w     0<<6                     ; player.a
           dc.w     0                        ; player.animx
           dc.w     1                        ; player.animy
           dc.w     PLAYER_STATE_STANDRUN    ; stato
           dc.w     0                        ; inputdevice.value
           dc.w     0                        ; inputdevice.angle
           dc.w     0                        ; inputdevice.fire1
           dc.w     0                        ; inputdevice.fire2
           dc.w     0                        ; inputdevice.fire3
           dc.w     2<<6                     ; player.speed
           dc.w     INPUT_TYPE_AI            ; player.inputtype
           dc.w     4                        ; player.anim_time
           dc.w     4                        ; player.anim_counter
           dc.w     1                        ; player.id 
           dc.w     0                        ; player.has_ball
           dc.w     0                        ; player.timer1
           dc.w     -1                       ; player.side
           dc.w     0                        ; player.selected
           dc.w     0                        ; player.kick_angle
           dc.w     1                        ; player.shoot_bar_anim
           dc.w     0                        ; player.ball_distance
.player7   dc.w     -20<<6                   ; posizione x
           dc.w     -84<<6                   ; posizione y
           dc.w     0<<6                     ; player.v
           dc.w     0<<6                     ; player.a
           dc.w     0                        ; player.animx
           dc.w     1                        ; player.animy
           dc.w     PLAYER_STATE_STANDRUN    ; stato
           dc.w     0                        ; inputdevice.value
           dc.w     0                        ; inputdevice.angle
           dc.w     0                        ; inputdevice.fire1
           dc.w     0                        ; inputdevice.fire2
           dc.w     0                        ; inputdevice.fire3
           dc.w     2<<6                     ; player.speed
           dc.w     INPUT_TYPE_AI            ; player.inputtype
           dc.w     4                        ; player.anim_time
           dc.w     4                        ; player.anim_counter
           dc.w     1                        ; player.id 
           dc.w     0                        ; player.has_ball
           dc.w     0                        ; player.timer1
           dc.w     -1                       ; player.side
           dc.w     0                        ; player.selected
           dc.w     0                        ; player.kick_angle
           dc.w     1                        ; player.shoot_bar_anim
           dc.w     0                        ; player.ball_distance
.player8   dc.w     -20<<6                   ; posizione x
           dc.w     -98<<6                   ; posizione y
           dc.w     0<<6                     ; player.v
           dc.w     0<<6                     ; player.a
           dc.w     0                        ; player.animx
           dc.w     1                        ; player.animy
           dc.w     PLAYER_STATE_STANDRUN    ; stato
           dc.w     0                        ; inputdevice.value
           dc.w     0                        ; inputdevice.angle
           dc.w     0                        ; inputdevice.fire1
           dc.w     0                        ; inputdevice.fire2
           dc.w     0                        ; inputdevice.fire3
           dc.w     2<<6                     ; player.speed
           dc.w     INPUT_TYPE_AI            ; player.inputtype
           dc.w     4                        ; player.anim_time
           dc.w     4                        ; player.anim_counter
           dc.w     1                        ; player.id 
           dc.w     0                        ; player.has_ball
           dc.w     0                        ; player.timer1
           dc.w     -1                       ; player.side
           dc.w     0                        ; player.selected
           dc.w     0                        ; player.kick_angle
           dc.w     1                        ; player.shoot_bar_anim
           dc.w     0                        ; player.ball_distance
.player9   dc.w     -20<<6                   ; posizione x
           dc.w     -112<<6                  ; posizione y
           dc.w     0<<6                     ; player.v
           dc.w     0<<6                     ; player.a
           dc.w     0                        ; player.animx
           dc.w     1                        ; player.animy
           dc.w     PLAYER_STATE_STANDRUN    ; stato
           dc.w     0                        ; inputdevice.value
           dc.w     0                        ; inputdevice.angle
           dc.w     0                        ; inputdevice.fire1
           dc.w     0                        ; inputdevice.fire2
           dc.w     0                        ; inputdevice.fire3
           dc.w     2<<6                     ; player.speed
           dc.w     INPUT_TYPE_AI            ; player.inputtype
           dc.w     4                        ; player.anim_time
           dc.w     4                        ; player.anim_counter
           dc.w     1                        ; player.id 
           dc.w     0                        ; player.has_ball
           dc.w     0                        ; player.timer1
           dc.w     -1                       ; player.side
           dc.w     0                        ; player.selected
           dc.w     0                        ; player.kick_angle
           dc.w     1                        ; player.shoot_bar_anim
           dc.w     0                        ; player.ball_distance
.player10  dc.w     -20<<6                   ; posizione x
           dc.w     -126<<6                  ; posizione y
           dc.w     0<<6                     ; player.v
           dc.w     0<<6                     ; player.a
           dc.w     0                        ; player.animx
           dc.w     1                        ; player.animy
           dc.w     PLAYER_STATE_STANDRUN    ; stato
           dc.w     0                        ; inputdevice.value
           dc.w     0                        ; inputdevice.angle
           dc.w     0                        ; inputdevice.fire1
           dc.w     0                        ; inputdevice.fire2
           dc.w     0                        ; inputdevice.fire3
           dc.w     2<<6                     ; player.speed
           dc.w     INPUT_TYPE_AI            ; player.inputtype
           dc.w     4                        ; player.anim_time
           dc.w     4                        ; player.anim_counter
           dc.w     1                        ; player.id 
           dc.w     0                        ; player.has_ball
           dc.w     0                        ; player.timer1
           dc.w     -1                       ; player.side
           dc.w     0                        ; player.selected
           dc.w     0                        ; player.kick_angle
           dc.w     1                        ; player.shoot_bar_anim
           dc.w     0                        ; player.ball_distance
.player11  dc.w     -20<<6                   ; posizione x
           dc.w     -140<<6                  ; posizione y
           dc.w     0<<6                     ; player.v
           dc.w     0<<6                     ; player.a
           dc.w     0                        ; player.animx
           dc.w     1                        ; player.animy
           dc.w     PLAYER_STATE_STANDRUN    ; stato
           dc.w     0                        ; inputdevice.value
           dc.w     0                        ; inputdevice.angle
           dc.w     0                        ; inputdevice.fire1
           dc.w     0                        ; inputdevice.fire2
           dc.w     0                        ; inputdevice.fire3
           dc.w     2<<6                     ; player.speed
           dc.w     INPUT_TYPE_AI            ; player.inputtype
           dc.w     4                        ; player.anim_time
           dc.w     4                        ; player.anim_counter
           dc.w     1                        ; player.id 
           dc.w     0                        ; player.has_ball
           dc.w     0                        ; player.timer1
           dc.w     -1                       ; player.side
           dc.w     0                        ; player.selected
           dc.w     0                        ; player.kick_angle
           dc.w     1                        ; player.shoot_bar_anim
           dc.w     0                        ; player.ball_distance