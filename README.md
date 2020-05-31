# dkb_report_extractor

This scripts allows you to extract the credit card and bank transactions from the movements of the dkb bank pdf report.

The script is a mix between python to extract the data and perl to process it.

The tabula library is requiered in python:
https://tabula-py.readthedocs.io/en/latest/tabula.html#tabula.io.build_options

The following folder structure is needed:
```
├── _archive
├── bank_transactions # PDF exports of the DKB bank transactions
├── credit_card_movements # PDF exports of the DKB credit card abrrechnungen
├── csv # intermediate folder
├── csv_transactions # intermediate folder
├── extract_bank_transactions.pl
├── extract_credit_card_movements.pl
├── json # Both results will be stored here
├── pdf_to_csv_with_tabula_credit.py
├── pdf_to_csv_with_tabula_movements.py
└── README.md
```

Just execute with the following once the pdfs and folders are set up:
```
perl extract_bank_transactions.pl
perl extract_credit_card_movements.pl
```
