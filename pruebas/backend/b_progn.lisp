// Test de Secuencias (progn) para Backend
(setq a 0)

(defun main ()
  (progn
    (setf a 1)
    (setf a (+ a 1))
    (setf a (* a 10))
    (princ "Resultado acumulado: ")
    (princ a)
  )
)

(main)
