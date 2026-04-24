// Test de Variables y Asignaciones para Backend
(setq x 10)
(setq y 20)

(defun main ()
  (setf x 50)
  (setf y (+ x 10))
  (princ "X: ")
  (princ x)
  (princ " Y: ")
  (princ y)
)

(main)
