#lang racket
(define atom?
  (lambda (x)
    (and (not(pair? x)) (not(null? x)))))

; This chapter focusses on returing functions are values which means currying the argument to produce generic procedures.
;------------------------------------------------------------------------------------------------------------------------------------------------------------
; (multi-rmember-f test? ) --> (fun sym lst) return a fucntion which takes sym and removes all the elements of lst on which test is sucessfull 
;------------------------------------------------------------------------------------------------------------------------------------------------------------
(define multi-rmember-test
  (lambda (test?)
    (lambda (sym lst)
      (cond((null? lst) '())
           ((test? sym (car lst)) ((multi-rmember-test test?) sym (cdr lst)))
           (else(cons(car lst)
                     ((multi-rmember-test test?) sym (cdr lst))))))))

(define multi-rmember=(multi-rmember-test =))
;(multi-rmember= 2 '(1 2 3 5 4 2 2 2))
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
; (insertL-f test?) --> returns a fucntion which takes new ,old and lst as argument and insert new symbol the left of old symbol if test? is successfull.
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
(define multi-insertL-f
  (lambda (test?)
    (lambda (new old lst)
      (cond((null? lst) '())
           ((test? (car lst) old) (cons new (cons (car lst)
                                                  ((multi-insertL-f test?) new old (cdr lst)))))
           (else (cons (car lst)
                       ((multi-insertL-f test?) new old (cdr lst))))))))
(define insertL> (multi-insertL-f >))
;(insertL> 2 3 '( 2 3 4))

;-----------------------------------------------------------------------------------------------------------------------------------------------------------
; (insertR-f test?) --> returns a fucntion which takes new ,old and lst as argument and insert new symbol to the rught of old symbol if test? is successfull.
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
(define multi-insertR-f
  (lambda (test?)
    (lambda (new old lst)
      (cond((null? lst) '())
           ((test? (car lst) old) (cons (car lst) (cons new
                                                        ((multi-insertR-f test?) new old (cdr lst)))))
           (else (cons (car lst)
                       ((multi-insertR-f test?) new old (cdr lst))))))))
(define multi-insertR> (multi-insertR-f >))
;(multi-insertR> 2 3 '( 2 3 4))
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
; (insertG-f test? seq) --> function takes test? predicate and seq which is a function to arrange new item to the left(seqL new old lst) 
;or right(seqR new old lst) of old item if test? is successfull.
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
(define seqL
  (lambda (new old lst)
    (cons new(cons old lst))))

(define seqR
  (lambda (new old lst)
    (cons old(cons new lst))))

(define multi-insertG-f
  (lambda (seq)
    (lambda (test?)
      (lambda (new old lst)
        (cond((null? lst) '())
             ((test? (car lst) old) (seq new (car lst) ( ((multi-insertG-f seq) test?) new old (cdr lst))))
             (else(cons (car lst)
                        (((multi-insertG-f seq) test?) new old (cdr lst))))))))) 

;(define multi-insertL-g ((multi-insertG-f seqL) >))
;(define multi-insertR-g (multi-insertG-f > seqR))
;(multi-insertL-g   2 3 '(1 4 3 4 3))
;(multi-insertR-g 2 3 '(1 4 3 4 3))
;----------------------------------------------------------------------------------------------------------------------------------------------------------
; (multi-substG-f test? seq) --> accepts test? predicate and a fuction for sequencing elements and returns another function which takes 2 symbols new, old , and lst which is list of symbols to return another list in which all instances of old are replaced by new.
;----------------------------------------------------------------------------------------------------------------------------------------------------------
(define  seq-S
  (lambda (new old lst)
    (cons new lst)))
;(define multi-substG-f ((multi-insertG-f seq-S) =))
;(multi-substG-f 2 3 '(1 3 4 3 5 3 6 3))
;-----------------------------------------------------------------------------------------------------------------------------------
; (value aexp) --> n returns a number which is value of aexp
; we have define value in most abstract way
;-----------------------------------------------------------------------------------------------------------------------------------
(define ^
  (lambda(a b)
    (cond((zero? b) '1)
         (else(* a (^ a (sub1 b)))))))

(define oper-fun
  (lambda (aexpr)
    (cond((eq? (car(cdr aexpr)) (quote +)) +)
         ((eq? (car(cdr aexpr)) (quote *)) *)
         ((eq? (car(cdr aexpr)) (quote ^)) ^))))

(define value
  (lambda (aexp)
    (cond((and(atom? aexp) (number? aexp)) aexp)
         (else((oper-fun aexp) (value (car aexp))
                               (value (car (cdr(cdr aexp)))))))))

;(oper-fun '(1 + 2))
;(value '( 10 * (3 ^ 3)))
;----------------------------------------------------------------------------------------------------------------------------------------------------------
; (multi-rmember-co sym lat col) -->  removes sym symbol with new and retunrns the result using a collector function col
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
(define multi-rmember-co
  (lambda (sym lat col)
    (cond((null? lat) (col '() '()))
         ((eq? (car lat) sym)
          (multi-rmember-co 
           sym
           (cdr lat)
           (lambda (newlat oldlat)
             (col newlat
                  (cons (car lat) oldlat)))))
         (else
          (multi-rmember-co
           sym
           (cdr lat)
           (lambda (newlat oldlat)
             (col (cons (car lat) newlat)
                  oldlat)))))))
(define rcol
  (lambda (newlat oldlat)
    oldlat))
(multi-rmember-co 'tuna '(straw tuna gold tuna) rcol)

;-----------------------------------------------------------------------------------------------------------------------------------------------------------
; (multi-insert-LR new oldL oldR lat) --> insert new to the left and right of lat
;-----------------------------------------------------------------------------------------------------------------------------------------------------------

(define multi-insert-LR
  (lambda (new oldL oldR lat)
    (cond((null? lat) '())
         ((equal? (car lat) oldL)
          (cons new
                (cons (car lat)(multi-insert-LR new oldL oldR (cdr lat)))))
         ((equal? (car lat) oldR)
          (cons (car lat)
                (cons new (multi-insert-LR new oldL oldR (cdr lat)))))
         (else(cons(car lat)
                   (multi-insert-LR new oldL oldR (cdr lat)))))))
(multi-insert-LR 3 4 6 '(1 4 5 6 4 5 6 7 6 4))
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
; (multi-insert-LR-co new oldL oldR lat col) --> Returns new list of atoms lat , number of left inserts, and number of right inserts.
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
(define multiInsertLR&co
  (lambda (new oldL oldR lat col)
    (cond((null? lat) (col '() 0 0))
         ((equal? (car lat) oldL)
          (multiInsertLR&co new oldL oldR (cdr lat)
                            (lambda (newlat L R)
                              (col (cons new (cons oldL newlat)) (add1 L) R))))
         ((equal? (car lat) oldR)
          (multiInsertLR&co new oldL oldR (cdr lat)
                            (lambda (newlat L R)
                              (col (cons oldR (cons new newlat)) L (add1 R)))))
         (else(multiInsertLR&co new oldL oldR (cdr lat)
                                (lambda (newlat L R)
                                  (col (cons (car lat) newlat) L R)))))))

(define insertRcol
  (lambda (new L R)
    (cons new (cons L R))))
(multiInsertLR&co 3 4 6 '(1 4 5 6 4 5 6 7 6 4) insertRcol)

;-----------------------------------------------------------------------------------------------------------------------------------------------------------
; (evens-only* l) --> return only even numbers from the nested list
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
(define even?
  (lambda (n)
    (cond((= n 0) #t)
         ((= n 1) #f)
         (else(even?(- n 2))))))

(define evens-only?
  (lambda (lat)
    (cond((null? lat) '())
         ((atom? (car lat)) 
          (cond((even? (car lat))
                (cons (car lat) (evens-only? (cdr lat))))
               (else(evens-only? (cdr lat)))))
         (else(cons(evens-only? (car lat))
                                (evens-only? (cdr lat)))))))

;(evens-only? '(1 2 3 4 5 6 5 3 7 9 11))
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
; (even-only&co l col) --> return list of even number in the collector function
;-----------------------------------------------------------------------------------------------------------------------------------------------------------
(define even-only&co 
  (lambda (lat col)
    (cond((null? lat) (col '() 1 0))
         ((atom? (car lat))
          (cond((even? (car lat))
                (even-only&co (cdr lat)
                              (lambda (newlat m s)
                                (col (cons (car lat) newlat) (* (car lat) m) s))))
               (else(even-only&co (cdr lat)
                                  (lambda (newlat m s)
                                    (col newlat m (+ (car lat) s)))))))
         (else(cons 
               (even-only&co (car lat) col)
               (even-only&co (cdr lat) col))))))

  (define even-col
(lambda (lat m s)
  (cons lat (cons m s))))
  
  (even-only&co '(1 2 3 4 5) even-col)
                 