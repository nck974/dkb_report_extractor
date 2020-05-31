# dkb_report_extractor

This scripts allows you to extract the credit card and bank transactions from the movements of the dkb bank pdf report.

The script is a mix between python to extract the data and perl to process it.

The tabula library is requiered in python:
https://tabula-py.readthedocs.io/en/latest/tabula.html#tabula.io.build_options

The following folder structure is needed:
`.
├── _archive

├── csv # Intermediate step

├── json # This is your output

├── movements # Store here your pdfs

├── pdf_to_csv_with_tabula.py

├── extract.pl

└── README.md
`
