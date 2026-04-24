// Test de Control de Flujo para Backend
(setq limite 5)

(defun main ()
  (setq i 0)
  (loop while (< i limite) do
    (if (= (mod i 2) 0)
        (progn
          (princ i)
          (princ " es par")
        )
        (progn
          (princ i)
          (princ " es impar")
        )
    )
    (setf i (+ i 1))
  )
)

(main)
