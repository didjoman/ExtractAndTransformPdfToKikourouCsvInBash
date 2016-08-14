# ExtractAndTransformPdfToKikourouCsvInBash
This project downloads the pdf result of the course "Ascension du col de Braus" and transforms it as a csv respecting the format asked by the site Kikourou.
The pdf downloaded contains a table of results. 
The output format is a csv containing 5 columns: class;temps;nom;cat;sexe;club

## Dependencies 
The project requires you to have installed the following dependencies :
- bash
- curl
- pdftotext


## Executing the program 
```
chmod u+x pdfToKikourouCsv.sh
./pdfToKikourouCsv.sh
```