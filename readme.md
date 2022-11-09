# Bincount

a light leadger-cli alternative inspired by 
[Beancount](https://github.com/beancount/beancount)
and the 
[Go Leadger](https://github.com/howeyc/ledger) port.

```
 bincount file [options] [arguments]
Arguments:
 file
 arguments          account names (allow incomplete naming eg. Asset:*)
Options:
 -c                  set the main currency
 -print              print and fix the input file while reading
 -accounts           print the final list of open accounts
 -wrong-assuption    makes wrong assumption about data
 -max-date           YYYY-MM-DD ignore transaction after the given date
```
**Why should you uses bincount?** you shouldn't  
but if you found (h)ledger unsafe, beancount bloat and Ledger Go 
too lacking, you can try it and be disappointed.

features set:
 - _~xx%_ of Ledger Go (by design)
 - _~xx%_ of Beancount (by design)

main goals:
 - elegant code
 - easy to hack and customize
 - ✔ small binary and small codebase

(these are the goals, not the result i got)

Known bug:
 - the minus sign must be near the number: `-199.44` is ok, `- 199.
44` is not.

----------------------------------------------------------------

### How does it compare to Ledger Go Port?
 - no `import` command, use an external tool.
 - no `balance`, `equity` cli command for quick reporting,  
   use `bincount -accounts Asset:* Equity:* Liabilities:* Income:* Expenses:*` instead.
 - it support multiple commodities, and all commodities are somehoe convert to the base currency.
 - ✖ `register` command is going to act as a tsv exporter
 - `stats` partial support.

### How does it compare to Beancount?
 - ignores transactions flagged with **!** or **P**.
 - no *metatag* support. it's a text file, use a search utility.
 - force strict mode for default currency (transaction must balance).
 - only two commodity positions (instead of 3) + the default currency position.
   [^](beancount.github.io/docs/beancount_language_syntax.html#reducing-positions)
 - supports **pad** directive (but it does not insert a new transaction) for account in default currency.
 - requires **open** directive for accounts, and **price** directive in default currency.

### Why my accounts and currency name are no longer capitalized?
I don't care, Nim-lang doesn't care, and Bincount doesn't care 
either. 
if you care: [see]()

*Why?*  
Style Consistency is a worthy and noble goal, but 
it should not be a Forced Requirements, expecially
if I am using my phone to write the last 20 transactions
before calculate the net value.

So Bincount normalize all the string of text it care about.
For example `asset:mybank` can also be written as:

```
asset:my_bank
Asset:MyBank
ASSET:My_Bank
```
### Why you dont support FIFO, LIFO, etc ?
the `AIS 2` (and the `OIC 13`) requires inventories 
to be measured at the lower of Cost (fifo, lifo) 
and Net Realisable Value.

Until we found a clean solution for inputing the NRV
(and store costs) inside the journal, we cannot support Fifo.

### why do you find ledger unsafe?
  I agree with the developer of beancount.

  Ledger is too powerful for your own good and
  too tolerant when facing normal typing error.

  Forcing the user to open an account before usage
  and being picky about zero-sum transaction
  is good accounting.

### what is missing that should be here?
 - input from standard input

### what's -wrong-assumption?:
the wrong_assumption flag ignore some checks and makes unreasonabl
assumptions about user datas.
 - the balance directive overwrite the account amount.
 - options are not only in the first 10 lines of the file
 - if a price is missing for a commodity, assume a 1:1 with 
base_currency


----------------------------------------------------------------

## Bincount Syntax Cheat Sheet
obliviously copy-pasted from beancount

**Directives**
General syntax:
```
YYYY-MM-DD <directive> <arguments...>
YYYY-MM-DD <DIRECTIVE> <arguments...>
```
**Opening & Closing Accounts**
```
2001-05-29 open Expenses:Restaurant
2001-05-29 open Assets:Checking USD~,EUR~ ; Only one commodity 
allowed,
2001-05-29 open Assets:Checking EUR       ; use multiple line for 
extra commodity / currency
2015-04-23 close Assets:Checking
```
**Prices**
```
2015-05-30 price eur 1 ; all commodities has to be declared with a
base_currency value
2015-04-30 price USD . ; use . or 0.0 for an account base_currency
independant
2015-05-30 price AAPL 130.28 ~USD~ ; prices can only be declare in
base_currency 
```
**Notes**
```
2013-03-20 note Assets:Checking "Called to ask about rebate"
```
**Documents**
```
2013-03-20 document Assets:Checking "path/to/statement.pdf"
```

**Transactions**
```
2015-05-30 * "Some narration about this transaction"
Liabilities:CreditCard -101.23 USD
Expenses:Restaurant 101.23 USD

2015-05-30 ! "Cable Co" "Phone Bill" #tag ˆlink
    Expenses:Home:Phone 87.45 USD
    ~Assets:Checking ; You may leave one amount out~
    Assets:Checking . USD //        ; leaving the amount out is 
more verbose. 
```
**Postings**
(no cost, only prices)
```
... 123.45  ; Very Simple, assume base_currency    
... 123.45 USD ; Simple
... 10 GOOG @ 502.12 USD ; With per-unit price
... 10 GOOG @@ 5021.20 USD ; With total price
```

**Balance Assertions and Padding**
Asserts the amount for only the given currency:
```
2015-06-01 balance Liabilities:CreditCard -634.30 USD
```
Automatic insertion of transaction to fulfill the following 
assertion:
```
YYYY-MM-DD pad Assets:Checking Equity:Opening-Balances
```
**Events**
```
YYYY-MM-DD event "location" "New York, USA"
YYYY-MM-DD event "address" "123 May Street"
```
**Options**
    limited to the first 10 line of the file
option "title" "My Personal Ledger"

; Comments begin with a semi-colon