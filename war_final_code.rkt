#lang racket
(require racket/gui/base games/cards )


;; Initial card count for each player to get
; update this count to get more cards but not more than 15 because of display region size limitation
;******************************************
(define DEAL-COUNT 7)

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
(define t (make-table "Simplified War Game" 8 4.5))
(define status-pane (send t create-status-pane)
  )

(send t set-status "Machine has 0; you have 0")
(send t show #t)
(send t set-double-click-action #f)

;; Get table width & height
(define w (send t table-width)
  )
(define h (send t table-height)
  )

;; Set up the cards
(define deck (shuffle-list (make-deck) 7)
  ) ; optimal shuffle with 7
(for-each (lambda (card)
            (send card user-can-move #f)
            (send card user-can-flip #f))
          deck)

;; Function for dealing or drawing cards
(define (deal n)
  (let loop ([n n][d deck])
    (if (zero? n)
        (begin (set! deck d) null)
        (cons (car d) (loop (sub1 n) (cdr d)))))
  )

;; Card width & height
(define cw (send (car deck) card-width)
  )
(define ch (send (car deck) card-height)
  )

;; Draw and discard pile locations
(define draw-x (/ (- w (* 3 cw)) 2)
  )
(define draw-y (/ (- h ch) 2)
  )
(define discard-1-x (+ draw-x (* 2 cw))
  )
(define discard-1-y draw-y)
(define discard-2-x (* (+ draw-x (* 2 cw)) 2)
  )
(define discard-2-y draw-y)

;; Put the cards on the table
(send t add-cards deck draw-x draw-y)

;; Player region size
(define pw (- w (* 2 MARGIN))
  )
(define ph (- (* 1.75 ch) (* 4 MARGIN))
  )

;; Define the regions
(define machine-region
  (make-region MARGIN MARGIN pw ph MACHINE-NAME #f)
  )

(define machine-score-region
  (make-region MARGIN (+ MARGIN ph) 100 50 "Machine: 0" #f)
  )

(define your-region
  (make-region MARGIN (- h ph MARGIN) pw ph YOUR-NAME void)
  )

(define your-score-region
  (make-region MARGIN (+ MARGIN ph 55) 100 50 "You: 0" #f
               ))
  
  (define discard-region_1
    (make-region (- discard-1-x MARGIN) (- discard-1-y MARGIN)
                 (+ cw (* 4 MARGIN)) (+ ch (* 4 MARGIN))
                 "Your card" #f)
    )
  
  (define discard-region_2
    (make-region (+  (+ cw (* 2 MARGIN))(- discard-1-x MARGIN))  (- discard-1-y MARGIN)
                 (+ cw (* 4 MARGIN)) (+ ch (* 4 MARGIN))
                 "Mac card" #f)
    )
  
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
                 #f #f)
    )
  
  ;; Place cards nicely
  (define machine-display-region (region->display-region machine-region)
    )  
  (send t move-cards-to-region machine-hand machine-display-region)
  (send t move-cards-to-region your-hand (region->display-region your-region))
  
  ;; All cards in your hand are movable, but must stay in your region
  (for-each (lambda (card) 
              (send card home-region your-region)
              (send card user-can-move #t))
            your-hand)
  
  ;; Start the discard pile
  (define discards (deal 1))
  
  ;; Initialize scores
  (define machine-region-score 0)
  (define your-region-score 0)
  
  ;; for loop control testing
  (define x 0)
  
  ;; For end game message
  (define win-message "Game on")
  
  ;; Player buttons
  (define (make-button title pos)
    (make-button-region (+ (/ (- w (* 4 BUTTON-WIDTH) (* 3 MARGIN)) 2)
                           (* pos (+ BUTTON-WIDTH MARGIN)))
                        (- h MARGIN BUTTON-HEIGHT)
                        BUTTON-WIDTH BUTTON-HEIGHT
                        title void)
    )
  (define hit-button (make-button "Move" 1)
    )
  (define over-button (make-button "Game over" 1)
    )
  
  ;; end of game procedure
  (define (game-over win-message) (lambda () (set! x 2)
                                    (send t set-status win-message)
                                    (send t add-region over-button)
                                    (set-region-callback! over-button #f)
                                    ))
  
  ;; loop with the move button
  (set-region-callback!
   hit-button
   (lambda ()
     (send t move-card (car your-hand) discard-1-x discard-1-y)
     (send t card-face-up (car machine-hand))
     (send t move-card (car machine-hand) (+  (+ cw (* 2 MARGIN))(- discard-1-x MARGIN)) (- discard-1-y MARGIN))
     (send t card-face-up (car your-hand))
     (send t pause 1.00) 
     (send (car machine-hand) get-value)
     (send (car your-hand) get-value)
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
     (update-machine-score-region! machine-region-score)
     (send t remove-region your-score-region)
     (update-your-score-region! your-region-score)
     (send t remove-card (car your-hand))                  
     (send t remove-card (car machine-hand))
     
     (cond ((> your-region-score machine-region-score)
            (set! win-message "You win!!"))
           ((< your-region-score machine-region-score)
            (set! win-message "Machine wins!!"))
           ((= your-region-score machine-region-score)
            (set! win-message "You are even!!")))
     (set! machine-hand (cdr machine-hand))
     (set! your-hand (cdr your-hand))
     (display x)
     (if (equal? '()  your-hand)
         ((game-over win-message))
         (set! x 0))
     )
   )
  ; end of loop
  (send t add-region hit-button)
  (display x)
  (define machine-score 0)
  (define your-score 0)
  (define (update-machine-score-region! d)
    (send t add-region (make-region MARGIN (+ MARGIN ph) 100 50 (string-append "Machine: " (~a d)) #f))
    )
  (define (update-your-score-region! d)
    (send t add-region (make-region MARGIN (+ MARGIN ph 55) 100 50 (string-append "you: " (~a d)) #f)
          )
    )
  (region-callback hit-button)
  