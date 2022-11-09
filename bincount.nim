import tables, hashes, strscans
import strutils except normalize
from times import getDateStr
from math import round

func normalize(s: string): string  =
  result = newString(s.len)
  var j = 0
  for i in 0..len(s) - 1:
    if s[i] in 'A'..'Z':
      result[j] = chr(ord(s[i]) + (ord('a') - ord('A')))
      inc j
    elif s[i] == '_': continue
    elif i == 0 and s[i] == ' ': continue
    elif i != 0 and s[i] == ' ' and s[i - 1] == ' ': continue
    else:
      result[j] = s[i]
      inc j
  if j != s.len: setLen(result, j)

import simple_parseopt
let arg = get_options:
    file:string {.bare, required.}
    c:string = ""           {.description("set the main currency").}
    print:bool              {.description("print and fix the input file while reading").}
    print_title:bool        {.description("🧪 - print only the directive").}
    accounts:bool           {.description("print the final list of open accounts").}
    wrong_assuption:bool    {.description("makes wrong assumption about data").}
    max_date = "9999-12-31" {.description("YYYY-MM-DD ignore transaction after the given date").}
    arguments:seq[string]   {.description("account names (allow incomplete naming eg. Asset:*)").}

var 
    line_count:int
    errorcount:int
    binbool: bool # throwaway boolean for scantuple
    readingpost = false
    default_com = arg.c
    priceTable = {default_com: 1.0,"": 1.0}.toTable
    balance = {default_com: 0.0}.toTable
    accountTable = {(account: "", commodity : ""): 0.0}.toOrderedTable

proc error( s: varargs[string, `$`]) = 
  inc error_count
  stderr.writeLine "\e[0;31m", line_count, s.join " " , "\e[0m"

proc query(arg: seq[string]) =
  # TODO: find a better name for the variable
  if arg.len > 0:
    echo: center "FILTER", 40, '-'
    var printable_accountTable = {(account: "*", commodity : default_com): 0.0}.toOrderedTable
    for key in arg:
      printable_accountTable[(account: key.normalize, commodity : default_com)] = 0.0
    for k in printable_accountTable.keys:
      for (key, value) in accountTable.pairs:
        if key.account == k.account and key.commodity == k.commodity:
          printable_accountTable[k] += value 
        elif k.account[^1] == '*' and
        key.account.startswith(k.account[0..^2]) and
        key.commodity == k.commodity:
            printable_accountTable[k] += value 
    for (key, value) in printable_accountTable.pairs:
              echo "  ", key.account.alignLeft 23, value.round(2).`$`.align 10, " ", key.commodity

for line in arg.file.lines:
  line_count += 1
  ## DOUBLE ENTRY
  ##`   account:pollo:x     10_000 EUR @ 200 USD ; Comment
  var account, commodity: string
  block post:
    var amount1: float
    var restofstring:string
    if scanf( line.normalize, "$+ $f$s$*$.", account, amount1, restofstring ) and readingpost == true:
      var (a, commodity1, m, amount2, commodity2) = restofstring.scanTuple "$s$+ $+ $f $w"
      var (amount, commodity) = case m:
          of "@@": (amount2, commodity2)
          of "@": (amount1 * amount2, commodity2)
          of "", ";", "\r": 
            if amount1 == 0 and commodity1 == "//":
              (0.0 - balance[default_com], default_com)
            else:
              (amount1, commodity1)
          of "//":
              ( 0.0 - balance[commodity1], commodity1) # for . USD //
          else: 
            error "WTF"
            (0.0, default_com)
      # get base value from price directive
      balance[default_com] +=  amount * pricetable[commodity]
      accountTable[(account, default_com)] += amount * pricetable[commodity]
      if not(commodity in ["", default_com]):
        balance[commodity] += amount
        accountTable[(account, commodity)] += amount
      ## print data
      if arg.print: echo "  ", account.alignLeft 23, amount.round(2).`$`.align 10," ", commodity
  
  ## DIRECTIVE
  ##` 2015-01-02 balance Assets:US:BofA:Checking        4841.12 USD
  ## you can start a new transaction parsing only if balance is 0.0
  block directive:
      var (c, date, dir, w) = line.normalize.scantuple "$+ $+ $+"
      if not( dir in ["*", "!", "D", "open", "close", "commodity", "document", "option", "event", "price", "pad", "query","custom"] ):
          continue
      var  y, m, d : int
      if not scanf( date, "$i-$i-$i", y, m, d ):
          assert m > 13 and d > 31
          continue
      ## now you are "sure" you are on a directive line 
      if balance[default_com] != 0:
          error " previous transaction is not balanced"
          balance[default_com] = 0

      readingpost = false
      if date > arg.max_date: 
          error "max date reached"
          continue

      (binbool, account, commodity) = w.scantuple "$+ $+"
      case dir:
        of "open": 
            if not accountTable.hasKey (account, default_com):
              accountTable[(account, default_com)] = 0.0
            if not accountTable.hasKey (account, commodity):
              if commodity != "": 
                accountTable[(account, commodity)] = 0.0
        of "close":
            if accountTable[(account, commodity)] == 0.0:
              del accountTable, (account, commodity)
        of "balance":
            var (binbool, account, amount, commodity) = w.scantuple "$+ $f $+"
            if arg.wrong_assuption: accountTable[(account, commodity)] = amount
            elif accountTable[(account, commodity)] != amount:
              error "no balance for ", account, " ", commodity
        of "pad":
            accountTable[(commodity, default_com)] += accountTable[(account, default_com)]
            accountTable[(account, default_com)] = 0.0
        of "*", "P":
            readingpost = true
            # inline transaction
            var (binbool, account1, account2, amount, commodity) = w.normalize.scantuple "$+ $+ $f $+"
            if binbool and accountTable.hasKey((account1, commodity)) and accountTable.hasKey((account2, commodity)):
                accountTable[(account1, commodity)] -= amount
                accountTable[(account2, commodity)] += amount
        of "price":
            # only for commodities with default_currency value
            var (binbool, currency, amount) = w.scantuple "$+ $f"
            price_table[currency] = amount
        of "query":
          query w.splitWhitespace
  ## print data
  if arg.print or arg.print_title: echo line

block stats:
  # Time period               : 2021-12-01 to 2022-01-15 (6 weeks 3 days)
  # Unique accounts           : 10
  # Number of transactions    : 12 (0.3 per day)
  # Number of postings        : 25 (0.6 per day)
  # Time since last post      : 18 weeks
  echo : center "RUN", 40, '-'
  echo "Time Period           : ", getDateStr()
  if error_count != 0: error "has been ecounter ",  error_count, "errors"
  echo "Unique Accounts       : ", -1 + accountTable.len

block accounts:
  # after reaching the end, print accounts data
  if arg.accounts == true:
    echo: center "ACCOUNTS", 40, '-'
    for (key, value) in accountTable.pairs:
        echo "  ", key.account.alignLeft 23, value.`$`.align 10, " ", key.commodity
    echo: center "PRICES", 40, '-'
    for (key, value) in price_table.pairs:
        echo "  ", key.alignLeft 23, value.`$`.align 10, " ", default_com

query(arg.arguments)