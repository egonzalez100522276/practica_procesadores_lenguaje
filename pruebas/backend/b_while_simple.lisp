(setq contador 0)
(defun main ()
  (loop while (< contador 3) do
    (print contador)
    (setf contador (+ contador 1))
  )
)
(main)
