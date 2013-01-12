;;; es-shift-text.el --- Move the region in 4 directions, in a way similar to Eclipse's
;;; Version: 0.1
;;; Author: sabof
;;; URL: https://github.com/sabof/es-shift-text
;;; Package-Requires: ((es-lib "0.1"))

;;; Commentary:

;; The project is hosted at https://github.com/sabof/es-shift-text
;; The latest version, and all the relevant information can be found there.

;;; License:

;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program ; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Code:

(require 'es-lib)

(defun es--current-mode-indent-step ()
  (case major-mode
    (haskell-mode 1)
    (python-mode 4)
    (php-mode 4)
    (otherwise 2)))

(defun es--section-marking-end-of-line (&optional pos)
  (save-excursion
    (when pos
      (goto-char pos))
    (if (and (region-active-p) (equal (current-column) 0))
        (point)
        (min (point-max) (1+ (es-total-line-end-position))))))

(defun* es--move-text-internal (arg)
  (let* (( was-active (region-active-p))
         ( first-line-was-folded
           (save-excursion
             (when was-active
               (goto-char (region-beginning)))
             (es-line-folded-p)))
         ( initial-column (current-column))
         ( start (es-total-line-beginning-position
                  (if was-active
                      (region-beginning)
                      (point))))
         ( end (es--section-marking-end-of-line
                (if was-active
                    (region-end)
                    (point))))
         ( text (delete-and-extract-region start end))
         new-start)
    (es-total-forward-line arg)
    (setq new-start (point))
    (insert text)
    (unless (equal (aref text (1- (length text)))
                   (aref "\n" 0))
      (insert "\n"))
    (set-mark new-start)
    (exchange-point-and-mark)
    (if (or was-active first-line-was-folded)
        (setq deactivate-mark nil
              cua--explicit-region-start nil)
        (progn (move-to-column initial-column t)
               (deactivate-mark)))
    (and first-line-was-folded
         (fboundp 'fold-dwim-hide)
         (save-excursion
           (cond ( (memq major-mode
                         '(lisp-mode
                           emacs-lisp-mode
                           lisp-interaction-mode
                           common-lisp-mode))
                   (fold-dwim-hide))
                 ( (progn (goto-char (line-end-position))
                          (equal (char-before) ?\{))
                   (fold-dwim-hide)
                   ))))))

(defun* es--indent-rigidly-internal (arg)
  (cond ( (region-active-p)
          (let (( start
                  (es-total-line-beginning-position
                   (region-beginning)))
                ( end
                  (es--section-marking-end-of-line
                   (region-end))))
            (set-mark end)
            (goto-char start)
            (indent-rigidly start end arg)
            (setq deactivate-mark nil)))
        ( (es-line-empty-p)
          (let* (( cur-column (current-column))
                 ( step (abs arg))
                 ( rest (mod cur-column step))
                 ( new-indent
                   (max 0 (if (zerop rest)
                              (+ cur-column arg)
                              (if (plusp arg)
                                  (+ cur-column rest)
                                  (- cur-column (- step rest)))))))
            (if (> new-indent cur-column)
                (indent-to new-indent)
                (goto-char (+ new-indent (line-beginning-position)))
                (delete-region (point) (line-end-position))
                )))
        ( t (indent-rigidly
             (es-total-line-beginning-position (point))
             (es--section-marking-end-of-line (point))
             arg))))

;;;###autoload
(defun es-move-text-down ()
  "Move region or the current line down."
  (interactive)
  (es--move-text-internal 1))

;;;###autoload
(defun es-move-text-up ()
  "Move region or the current line up."
  (interactive)
  (es--move-text-internal -1))

;;;###autoload
(defun es-move-text-left ()
  "Move region or the current line left."
  (interactive)
  (es--indent-rigidly-internal
   (* -1 (es--current-mode-indent-step))))

;;;###autoload
(defun es-move-text-right ()
  "Move region or the current line right."
  (interactive)
  (es--indent-rigidly-internal
   (es--current-mode-indent-step)))

(provide 'es-shift-text)

;;; es-shift-text.el ends here