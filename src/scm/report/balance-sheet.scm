;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; balance-sheet.scm: balance sheet 
;; 
;; By Robert Merkel <rgmerk@mira.net>
;;
;; Largely borrowed from pnl.scm by:
;; Christian Stimming <stimming@tu-harburg.de>
;;
;; This program is free software; you can redistribute it and/or    
;; modify it under the terms of the GNU General Public License as   
;; published by the Free Software Foundation; either version 2 of   
;; the License, or (at your option) any later version.              
;;                                                                  
;; This program is distributed in the hope that it will be useful,  
;; but WITHOUT ANY WARRANTY; without even the implied warranty of   
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the    
;; GNU General Public License for more details.                     
;;                                                                  
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, contact:
;;
;; Free Software Foundation           Voice:  +1-617-542-5942
;; 59 Temple Place - Suite 330        Fax:    +1-617-542-2652
;; Boston, MA  02111-1307,  USA       gnu@gnu.org
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(gnc:support "report/balance-sheet.scm")
(gnc:depend  "report-html.scm")

;; first define all option's names so that they are properly defined
;; in *one* place.

(let* ((pagename-general (N_ "General"))
       (optname-from-date (N_ "From"))
       (optname-to-date (N_ "To"))
       
       (pagename-accounts (N_ "Accounts"))
       (optname-display-depth (N_ "Account Display Depth"))
       (optname-show-subaccounts (N_ "Always show sub-accounts"))
       (optname-accounts (N_ "Account"))

       (pagename-display (N_ "Display"))
       (optname-show-parent-balance (N_ "Show balances for parent accounts"))
       (optname-show-parent-total (N_ "Show subtotals"))
       
       (pagename-currencies pagename-general)
       (optname-show-foreign (N_ "Show Foreign Currencies"))
       (optname-report-currency (N_ "Report's currency")))

  ;; Moderatly ugly hack here, i.e. this depends on the internal
  ;; structure of html-table -- if that is changed, this might break.
  (define (html-table-merge t1 t2)
    (begin 
      (gnc:html-table-set-data! t1
			      (append
			       (gnc:html-table-data t2)
			       (gnc:html-table-data t1)))
      (gnc:html-table-set-num-rows-internal!
       t1 (+ (gnc:html-table-num-rows t1)
	     (gnc:html-table-num-rows t2)))))

  (define (accountlist-get-comm-balance-at-date accountlist date)
    (let ((collector (gnc:make-commodity-collector)))
      (for-each (lambda (account)
		  (let ((balance 
			(gnc:account-get-comm-balance-at-date 
			 account date #f)))
		    (collector 'merge balance #f)))
		accountlist)
      collector))
		  
  ;; options generator
  (define (balance-sheet-options-generator)
    (let ((options (gnc:new-options)))
      
      ;; date at which to report balance
      (gnc:options-add-report-date!
       options pagename-general 
       optname-to-date "a")

      ;; all about currencies
      (gnc:options-add-currency-selection!
       options pagename-currencies
       optname-show-foreign optname-report-currency
       "b")

      ;; accounts to work on
      (gnc:options-add-account-selection! 
       options pagename-accounts
       optname-display-depth optname-show-subaccounts
       optname-accounts "a" 2
       (lambda ()
	 (gnc:filter-accountlist-type 
	  '(bank cash credit asset liability stock mutual-fund currency
            equity income expense)
	  (gnc:group-get-subaccounts (gnc:get-current-group)))))
      
      ;; what to show about non-leaf accounts
      (gnc:register-option 
       options
       (gnc:make-simple-boolean-option
	pagename-display optname-show-parent-balance 
	"c" (N_ "Show balances for parent accounts") #t))

      ;; have a subtotal for each parent account?
      (gnc:register-option 
       options
       (gnc:make-simple-boolean-option
	pagename-display optname-show-parent-total
	"d" (N_ "Show subtotals for parent accounts") #f))

      ;; Set the general page as default option tab
      (gnc:options-set-default-section options pagename-general)      

      options))
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; balance-sheet-renderer
  ;; set up the document and add the table
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (balance-sheet-renderer report-obj)
    (define (get-option pagename optname)
      (gnc:option-value
       (gnc:lookup-option 
        (gnc:report-options report-obj) pagename optname)))

    ;; get all option's values
    (let* ((display-depth (get-option pagename-accounts 
				      optname-display-depth))
	   (show-subaccts? (get-option pagename-accounts
				      optname-show-subaccounts))
	   (accounts (get-option pagename-accounts
				 optname-accounts))	 
	   (show-parent-balance? (get-option pagename-display
					     optname-show-parent-balance))
	   (show-parent-total? (get-option pagename-display
					   optname-show-parent-total))
	   (show-fcur? (get-option pagename-currencies
				   optname-show-foreign))
	   (report-currency (get-option pagename-currencies
					optname-report-currency))
	   (to-date-tp (gnc:timepair-end-day-time 
		       (vector-ref (get-option pagename-general
					       optname-to-date) 1)))

	   ;; decompose the account list
	   (split-up-accounts (gnc:decompose-accountlist accounts))
	   (asset-accounts
	    (assoc-ref split-up-accounts 'asset))
	   (liability-accounts
	    (assoc-ref split-up-accounts 'liability))
	   (equity-accounts
	    (assoc-ref split-up-accounts 'equity))
	   (income-expense-accounts
	    (append (assoc-ref split-up-accounts 'income)
		    (assoc-ref split-up-accounts 'expense)))


	   (doc (gnc:make-html-document))
	   (txt (gnc:make-html-text))
	   (tree-depth (if (equal? display-depth 'all)
			   (gnc:get-current-group-depth) 
			   display-depth))
	   ;; calculate the exchange rates  
	   (exchange-alist (gnc:make-exchange-alist 
			    report-currency to-date-tp))
	   (exchange-fn (gnc:make-exchange-function exchange-alist))
	   (totals-get-balance (lambda (account)
				 (gnc:account-get-comm-balance-at-date 
				  account to-date-tp #f))))

      ;; Wrapper to call the right html-utility function.
      (define (add-subtotal-line table label balance)
	(if show-fcur?
	  (gnc:html-acct-table-comm-row-helper! 
	   table tree-depth 1 label 
	   report-currency (gnc:sum-collector-stocks 
			    balance report-currency exchange-fn)
	   #f #f #t #f)
	  (gnc:html-acct-table-row-helper! 
	   table tree-depth 1 label 	   
	   (gnc:sum-collector-commodity
	    balance report-currency exchange-fn)
	   #f #t #f)))
      
      ;;(gnc:warn "account names" liability-account-names)
      (gnc:html-document-set-title! 
       ;; FIXME: Use magic sprintf code (goonie: which one?).
       doc (sprintf #f (_ "Balance sheet at %s")
		    (gnc:timepair-to-datestring to-date-tp)))

      (if (not (null? accounts))
	  ;; Get all the balances for each account group.
	  (let* ((asset-balance 
		  (gnc:accounts-get-comm-total-assets 
		   asset-accounts totals-get-balance))
		 (liability-balance
		  (gnc:accounts-get-comm-total-assets 
		   liability-accounts totals-get-balance))
		 (equity-balance
		  (gnc:accounts-get-comm-total-assets 
		   equity-accounts totals-get-balance))
		 (sign-reversed-liability-balance
		  (gnc:make-commodity-collector))
		 (neg-retained-profit-balance 
		  (accountlist-get-comm-balance-at-date
		   income-expense-accounts
		   to-date-tp))
		 (retained-profit-balance (gnc:make-commodity-collector))
		 (total-equity-balance (gnc:make-commodity-collector))
		 (equity-plus-liability (gnc:make-commodity-collector))

		 ;; Create the account tables here.
		 (asset-table 
		  (gnc:html-build-acct-table 
		   #f to-date-tp 
		   tree-depth show-subaccts? 
		   asset-accounts
		   #f #f #f #f #f
		   show-parent-balance? show-parent-total?
		   show-fcur? report-currency exchange-fn))
		 (liability-table 
		  (gnc:html-build-acct-table
		   #f to-date-tp
		   tree-depth show-subaccts?
		   liability-accounts
		   #f #f #f #f #f
		   show-parent-balance? show-parent-total?
		   show-fcur? report-currency exchange-fn))
		 (equity-table
		  (gnc:html-build-acct-table
		   #f to-date-tp
		   tree-depth show-subaccts?
		   equity-accounts
		   #f #f #f #f #f 
		   show-parent-balance? show-parent-total?
		   show-fcur? report-currency exchange-fn)))

	    (retained-profit-balance 'minusmerge
				     neg-retained-profit-balance
				     #f)
	    (total-equity-balance 'minusmerge equity-balance #f)
	    (total-equity-balance 'merge
				  retained-profit-balance
				  #f)	    
	    (sign-reversed-liability-balance 'minusmerge
					     liability-balance
					     #f)
	    (equity-plus-liability 'merge
				   sign-reversed-liability-balance
				   #f)
	    (equity-plus-liability 'merge
				   total-equity-balance
				   #f)

	    
	    ;; Now concatenate the tables. This first prepend-row has
	    ;; to be written out by hand -- we can't use the function
	    ;; append-something because we have to prepend.
	    (gnc:html-table-prepend-row! 
	     asset-table 
	     (list (gnc:html-acct-table-cell (* (if show-fcur? 3 2) 
						tree-depth) 
					     (_ "Assets") #t)))
	    
	    (add-subtotal-line 
	     asset-table (_ "Assets") asset-balance)	    
	    
	    ;; add a horizontal ruler
	    (gnc:html-table-append-ruler! 
	     asset-table (* (if show-fcur? 3 2) tree-depth))
	    
	    (add-subtotal-line 
	     asset-table (_ "Liabilities") #f)
	    (html-table-merge asset-table liability-table)
	    (add-subtotal-line
	     asset-table (_ "Liabilities") sign-reversed-liability-balance)

	    (gnc:html-table-append-ruler! 
	     asset-table (* (if show-fcur? 3 2) tree-depth))
	    (add-subtotal-line
	     asset-table (_ "Equity") #f)
	    (html-table-merge asset-table equity-table)
	    (add-subtotal-line
             asset-table (_ "Net Profit") retained-profit-balance)
	    (add-subtotal-line
             asset-table (_ "Total Equity") total-equity-balance)

	    (gnc:html-table-append-ruler! 
	     asset-table (* (if show-fcur? 3 2) tree-depth))
	    (add-subtotal-line
	     asset-table (_ "Liabilities & Equity") equity-plus-liability)
	    (gnc:html-document-add-object! doc asset-table)

	    ;; add currency information
;	    (gnc:html-document-add-object! 
;	     doc ;;(gnc:html-markup-p
;	     (gnc:html-make-exchangerates 
;	      report-currency exchange-alist accounts #f)))
	    )
	  
	  ;; error condition: no accounts specified
          (let ((p (gnc:make-html-text)))
            (gnc:html-text-append! 
             p 
             (gnc:html-markup-h2 (_ "No accounts selected"))
             (gnc:html-markup-p
              (_ "This report requires accounts to be selected.")))
            (gnc:html-document-add-object! doc p)))      
      doc))

  (gnc:define-report 
   'version 1
   'name (N_ "Balance Sheet")
   'menu-path (list "_Assets & Liabilities")
   'options-generator balance-sheet-options-generator
   'renderer balance-sheet-renderer))
