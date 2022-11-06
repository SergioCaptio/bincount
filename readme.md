# Bincount

a light alternative to leadger, inspired by Beancount and the Ledger Go port.

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

### Ledger Go Port
 - no `import` use an external tool.
 - no `balance`, `equity` cli command for quick reporting,  
   use `bincount -accounts Asset:* Equity:* Liabilities:* Income:* Expenses:*` instead.
 - support multiple commodities, and all commodities are automatically to the base currency.
 - [ ] `register` that also act as a tsv exporter
 - [ ] `stats` partial support.

### Beancount:
 - ignore transaction flagged with **!** or **P**.
 - only two commodity position + the default currency position.
   [^](beancount.github.io/docs/beancount_language_syntax.html#reducing-positions)
 - no *metatag* support. it's a text file, use a search utility.
 - force strict mode for default currency (transaction must balance).
 - require **open** directive for accounts, and **price** directive in default currency.
 - support **pad** directive (but it does not insert a new transaction) for account in default currency.

Known bug:
 - the minus sign must be near the number `-199.44` is ok, `- 199.44` is not.