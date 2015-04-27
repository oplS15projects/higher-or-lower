#lang racket/base
(require racket/gui/base games/cards racket/class racket/unit racket/format)

;; Initial card count
(define DEAL-COUNT 5)
;; Messages
(define YOUR-TURN-MESSAGE "Your turn.  (Draw a card or pickup a discard.)")
(define DISCARD-MESSAGE "Drag a card from your hand to discard.")
(define GAME-OVER-MESSAGE "GAME OVER")
;; Area labels
(define YOUR-NAME "You")
(define MACHINE-NAME "Machine")
;; Region layout constants
(define MARGIN 5)
(define LABEL-H 15)
;; Size of buttons
(define BUTTON-HEIGHT 16)
(define BUTTON-WIDTH 100)
;; Randomize
(random-seed (modulo (current-milliseconds) 10000))
;; Set up the table
(define t (make-table "Simplified War" 8 4.5))
(define status-pane (send t create-status-pane))
(send t add-scribble-button status-pane
      '(lib "games/scribblings/games.scrbl") "ginrummy")
(send t set-status "Machine has 0; you have 0")
(send t show #t)
(send t set-double-click-action #f)
(send t set-button-action 'left 'drag-raise/one)
(send t set-button-action 'middle 'drag/one)
(send t set-button-action 'right 'drag/above)
;; Get table width & height
(define w (send t table-width))
(define h (send t table-height))
;; Set up the cards
(define deck (shuffle-list (make-deck) 7))
(for-each (lambda (card)
            (send card user-can-move #f)
            (send card user-can-flip #f))
          deck)
;; Function for dealing or drawing cards
(define (deal n)
  (let loop ([n n][d deck])
    (if (zero? n)
      (begin (set! deck d) null)
      (cons (car d) (loop (sub1 n) (cdr d))))))
;; Card width & height
(define cw (send (car deck) card-width))
(define ch (send (car deck) card-height))
;; Draw and discard pile locations
(define draw-x (/ (- w (* 3 cw)) 2))
(define draw-y (/ (- h ch) 2))
(define discard-1-x (+ draw-x (* 2 cw)))
(define discard-1-y draw-y)
(define discard-2-x (* (+ draw-x (* 2 cw)) 2))
(define discard-2-y draw-y)
;; Put the cards on the table
(send t add-cards deck draw-x draw-y)
;; Player region size
(define pw (- w (* 2 MARGIN)))
(define ph (- (* 1.75 ch) (* 4 MARGIN)))
;; Define the regions
(define machine-region
  (make-region MARGIN MARGIN pw ph MACHINE-NAME #f))
(define machine-score-region
  (make-region MARGIN (+ MARGIN ph) 100 50 "machine: 0" #f))
(define your-region
  (make-region MARGIN (- h ph MARGIN) pw ph YOUR-NAME void))
(define your-score-region
  (make-region MARGIN (+ MARGIN ph 55) 100 50 "you: 0" #f))
(define discard-region_1
  (make-region (- discard-1-x MARGIN) (- discard-1-y MARGIN)
               (+ cw (* 2 MARGIN)) (+ ch (* 2 MARGIN))
               "disacrd-1" #f))
(define discard-region_2
  (make-region (+  (+ cw (* 2 MARGIN))(- discard-1-x MARGIN))  (- discard-1-y MARGIN)
               (+ cw (* 4 MARGIN)) (+ ch (* 4 MARGIN))
               "discard-2" #f))

;; Install the visible regions
(send t add-region machine-region)
(send t add-region machine-score-region)
(send t add-region your-region)
(send t add-region your-score-region)
(send t add-region discard-region_1)
(send t add-region discard-region_2)
;; Deal the initial hands
(define machine-hand (deal DEAL-COUNT))
(define your-hand (deal DEAL-COUNT))
      ;; Function to inset a region
(define (region->display-region r)
  (define m MARGIN)
  (make-region (+ m (region-x r)) (+ m (region-y r))
               (- (region-w r) (* 2 m)) (- (region-h r) (* 2 m))
               #f #f))
;; Place cards nicely
(define machine-display-region (region->display-region machine-region))
  
(send t move-cards-to-region machine-hand machine-display-region)
(send t move-cards-to-region your-hand (region->display-region your-region))
;(let loop()
;; All cards in your hand are movable, but must stay in your region
(for-each (lambda (card) 
            (send card home-region your-region)
            (send card user-can-move #t))
          your-hand)
;; More card setup: Show your cards
;(send t cards-face-up you-hand)
(send t flip-cards your-hand)

;; Start the discard pile
(define discards (deal 1))
(define machine-region-score 0)
(define your-region-score 0)
(let loop()
  
;(send t card-face-up (car your-hand))
(send t move-card (car your-hand) discard-1-x discard-1-y)
(send t card-face-up (car machine-hand))
(send t move-card (car machine-hand) (+  (+ cw (* 2 MARGIN))(- discard-1-x MARGIN)) (- discard-1-y MARGIN))
  (send t pause 4.00)
(send t remove-card (car your-hand))
(send t remove-card (car machine-hand))
(send (car machine-hand) get-value)
;(send (car machine-hand) get-suit)
(send (car your-hand) get-value)
;(send (car your-hand) get-suit)
(define machine-score 0)
(define your-score 0)

(set! machine-score (send (car machine-hand) get-value))
(set! your-score (send (car your-hand) get-value))
      
(cond((> (send (car machine-hand) get-value) (send (car your-hand) get-value))
    (set! machine-region-score (+ machine-region-score 2)))
    ((< (send (car machine-hand) get-value) (send (car your-hand) get-value))
     (set! your-region-score (+ your-region-score 2)))
((set! machine-region-score machine-region-score)
 (set! your-region-score your-region-score)))

  (send t set-status (string-append (format "Machine has ~a." machine-score) (format " you have ~a." your-score)))

(send t remove-region machine-score-region)
(define (update-machine-score-region! d)
 (send t add-region (make-region MARGIN (+ MARGIN ph) 100 50 (string-append "Machine: " (~a d)) #f))
  )
;
(update-machine-score-region! machine-region-score)
(send t remove-region your-score-region)
(define (update-your-score-region! d)
 (send t add-region (make-region MARGIN (+ MARGIN ph 55) 100 50 (string-append "you: " (~a d)) #f))
  )
;
(update-your-score-region! your-region-score)
;
(set! machine-hand (cdr machine-hand))
     (set! your-hand (cdr your-hand))
  
 
(loop))

