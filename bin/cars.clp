;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Cars Expert System
;; "CS Department"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Import some commonly-used classes
(import javax.swing.*)
(import java.awt.*)
(import java.awt.event.*)

;; Don't clear defglobals on (reset)
(set-reset-globals FALSE)

(defglobal ?*crlf* = "
")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Question and answer templates

(deftemplate question
  (slot text)
  (slot type)
  (multislot valid)
  (slot ident))

(deftemplate answer
  (slot ident)
  (slot text))

(do-backward-chaining answer)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Module app-rules

(defmodule app-rules)

(defrule app-rules::supply-answers
  (declare (auto-focus TRUE))
  (MAIN::need-answer (ident ?id))
  (not (MAIN::answer (ident ?id)))
  (not (MAIN::ask ?))
  =>
  (assert (MAIN::ask ?id))
  (return))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Engine rules

(defrule MAIN::engine-off
  (declare (auto-focus TRUE))
  (answer (ident sound) (text no))
  (answer (ident engine-on) (text no))
  =>
  (recommend-action "have to turn on your car Engine ")
  (halt))

(defrule MAIN::engine-broken
  (declare (auto-focus TRUE))
  (answer (ident sound) (text no))
  (answer (ident engine-on) (text yes))
  =>
  (recommend-action "have to go to mechanic shop")
  (halt))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Heat rules

(defrule MAIN::check-heat
  (declare (auto-focus TRUE))
  (answer (ident sound) (text yes))
  (answer (ident seek) (text no))
  (answer (ident does-beep) (text yes))
  (answer (ident how-many-beeps) (text ?t))
  (test (< (integer ?t) 3))
  =>
  (assert (check battery-charge))
  (recommend-action "have to fill the water tank"))

(defrule MAIN::unknown-heat
  (declare (auto-focus TRUE))
  (answer (ident sound) (text yes))
  (answer (ident seek) (text no))
  (answer (ident does-beep) (text no))
  =>
  (recommend-action "have to turn off the Engine")
  (halt))

(defrule MAIN::Engine
  (declare (auto-focus TRUE))
  (answer (ident sound) (text yes))
  (answer (ident seek) (text no))
  (answer (ident does-beep) (text yes))
  (answer (ident how-many-beeps) (text ?t))
  (test (>= (integer ?t) 3))
  =>
  (recommend-action "have to go to the mechanic!")
  (halt))

(defrule MAIN::no-fuel
  (declare (auto-focus TRUE))
  (answer (ident sound) (text yes))
  (answer (ident seek) (text yes))
  (answer (ident boot-begins) (text no))
  =>
  (recommend-action "have to fill the fuel tank")
  (halt))

(defrule MAIN::car-works
  (declare (auto-focus TRUE))
  (answer (ident sound) (text yes))
  (answer (ident seek) (text yes))
  (answer (ident boot-begins) (text yes))
  =>
  (recommend-action "consult a car mechanic expert")
  (halt))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Battery rules

(defrule MAIN::battery-charge
  (declare (auto-focus TRUE))
  (check battery-charge)
  (answer (ident battery-charge) (text yes))
  =>
  (recommend-action "have to charage the battery")
  (halt))

(defrule MAIN::battery-broken
  (declare (auto-focus TRUE))
  (check battery-charge)
  (answer (ident battery-charge) (text no))
  =>
  (recommend-action "have to replace your battery")
  (halt))
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; cars mode rules

(defrule MAIN::car-mode
  (declare (auto-focus TRUE))
  (explicit (answer (ident hardware) (text Other)))
  =>
  (recommend-action "consult a car mechanic expert")
  (halt))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Results output

(deffunction recommend-action (?action)
  "Give final instructions to the user"
  (call JOptionPane showMessageDialog ?*frame*
        (str-cat "I recommend that you " ?action)
        "Recommendation"
        (get-member JOptionPane INFORMATION_MESSAGE)))
  
(defadvice before halt (?*qfield* setText "Close window to exit"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Module ask

(defmodule ask)

(deffunction ask-user (?question ?type ?valid)
  "Set up the GUI to ask a question"
  (?*qfield* setText ?question)
  (?*apanel* removeAll)
  (if (eq ?type multi) then
    (?*apanel* add ?*acombo*)
    (?*apanel* add ?*acombo-ok*)
    (?*acombo* removeAllItems)
    (foreach ?item ?valid
             (?*acombo* addItem ?item))
    else
    (?*apanel* add ?*afield*)
    (?*apanel* add ?*afield-ok*)
    (?*afield* setText ""))
  (?*apanel* validate)
  (?*apanel* repaint))

(deffunction is-of-type (?answer ?type ?valid)
  "Check that the answer has the right form"
  (if (eq ?type multi) then
    (foreach ?item ?valid
             (if (eq (sym-cat ?answer) (sym-cat ?item)) then
               (return TRUE)))
    (return FALSE))
    
  (if (eq ?type number) then
    (return (is-a-number ?answer)))
    
  ;; plain text
  (return (> (str-length ?answer) 0)))

(deffunction is-a-number (?value)
  (try
   (integer ?value)
   (return TRUE)
   catch 
   (return FALSE)))

(defrule ask::ask-question-by-id
  "Given the identifier of a question, ask it"
  (declare (auto-focus TRUE))
  (MAIN::question (ident ?id) (text ?text) (valid $?valid) (type ?type))
  (not (MAIN::answer (ident ?id)))
  (MAIN::ask ?id)
  =>
  (ask-user ?text ?type ?valid)
  ((engine) waitForActivations))

(defrule ask::collect-user-input
  "Check an answer returned from the GUI, and optionally return it"
  (declare (auto-focus TRUE))
  (MAIN::question (ident ?id) (text ?text) (type ?type) (valid $?valid))
  (not (MAIN::answer (ident ?id)))
  ?user <- (user-input ?input)
  ?ask <- (MAIN::ask ?id)
  =>
  (if (is-of-type ?input ?type ?valid) then
    (retract ?ask ?user)
    (assert (MAIN::answer (ident ?id) (text ?input)))
    (return)
    else
    (retract ?ask ?user)
    (assert (MAIN::ask ?id))))

;; Main window
(defglobal ?*frame* = (new JFrame "Cars Expert System"))
(?*frame* setDefaultCloseOperation (get-member JFrame EXIT_ON_CLOSE))
(?*frame* setSize 500 250)
(?*frame* setVisible TRUE)


;; Question field
(defglobal ?*qfield* = (new JTextArea 5 40))
(bind ?scroll (new JScrollPane ?*qfield*))
((?*frame* getContentPane) add ?scroll)
(?*qfield* setText "Please wait...")

;; Answer area
(defglobal ?*apanel* = (new JPanel))
(defglobal ?*afield* = (new JTextField 40))
(defglobal ?*afield-ok* = (new JButton OK))

(defglobal ?*acombo* = (new JComboBox (create$ "yes" "no")))
(defglobal ?*acombo-ok* = (new JButton OK))

(?*apanel* add ?*afield*)
(?*apanel* add ?*afield-ok*)
((?*frame* getContentPane) add ?*apanel* (get-member BorderLayout SOUTH))
(?*frame* validate)
(?*frame* repaint)

(deffunction read-input (?EVENT)
  "An event handler for the user input field"
  (assert (ask::user-input (sym-cat (?*afield* getText)))))

(bind ?handler (new jess.awt.ActionListener read-input (engine)))
(?*afield* addActionListener ?handler)
(?*afield-ok* addActionListener ?handler)

(deffunction combo-input (?EVENT)
  "An event handler for the combo box"
  (assert (ask::user-input (sym-cat (?*acombo* getSelectedItem)))))

(bind ?handler (new jess.awt.ActionListener combo-input (engine)))
(?*acombo-ok* addActionListener ?handler)

(deffacts MAIN::question-data
  (question (ident hardware) (type multi) (valid Manual Automatic Other)
            (text "What kind of system car?"))
  (question (ident sound) (type multi) (valid yes no)
            (text "Does engine work lodudly?"))
  (question (ident engine-on) (type multi) (valid yes no)
            (text "dose the engine power on ?"))
  (question (ident seek) (type multi) (valid yes no)
            (text "is the battery fully charged?"))
  (question (ident does-beep) (type multi) (valid yes no)
            (text "Does the heat alarm makes beep?"))
  (question (ident how-many-beeps) (type number) (valid)
            (text "How many times does it beep?"))
  (question (ident battery-charge) (type multi) (valid yes no)
            (text "Does the fuel tank is full ?"))
  (question (ident boot-begins) (type multi) (valid yes no)
            (text "Does the car working now?"))
  (ask hardware))

  
(reset)
(run-until-halt)
