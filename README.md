lipid_classifier
================

Lipid classification tool


#Usage#

##Installation
`bundle install` should do most of the work for you, however, it currently references unreleased code in Rubabel.  I use that as a local git repository.  Due to the large file size of the DB, it will take some additional preparatory work to prepare this.  I'll have instructions posted on Rubabel after I figure that step out.  I expect to make that file available via Dropbox for local caching.

## Generating analysis WEKA files
from your root directory run `./bin/write_arffs` to see the options

Typical usage might include these options: 
- `-m N` where N is the number of threads
- `-d FOLDER` where folder is the directory (it will make it for you) where you want to generate the files
- `-r` if you want to clean out that folder, ie you are iterating in place.
- `-f input.yml` where you provide the input file in YAML format containing the classifications  

So, if I have `all_lmids.yml' in the root, and have 6 cores, I might run:
`./bin/write_arffs -f all_lmids.yml -d all -m 6`

Or, I might want to rerun that analysis on one core
`./bin/write_arffs -f all_lmids.yml -d all2`

Corrected LMIDS won't change the LMID in the output, but does change the classification used by WEKA.  These are loaded from the hash contained in `corrections.yml`.

## Analyzing files with WEKA
Again, from the root directory `./bin/classify_lipids` will show you the options.

Typical usage examples:
- `-d FOLDER` which is the FOLDER or directory where `write_arffs` placed its output files
- `-l list.txt` where list.txt is a file containing one LMID per line, for batch analysis of LMIDS in the classifier
- `--lmids LMFA01010001,LMST02040023,LMSL05010014` where you can provide a list of LMIDS for classification
- `-t` will add timing outputs to the analysis.
- `--run_weka` is required to generate a new WEKA analysis.  Otherwise, the analysis will just pull existing classifcation information from the directory.  You must do this the first time you run `classify_lipids` on a new directory.

So, to analyze a list of lmids in `lmids.txt`, working off the generated analyses (all, all2) from the previous section run: 
`./bin/classify_lipids -d all -l lmids.txt -t --run_weka`

Repeat that for the other analysis with: 
`./bin/classify_lipids -d all2 -l lmids.txt -t --run_weka`

Now, if you want to run a new list of LMIDS instead of the other one, you can skip the `run_weka` option:
`./bin/classify_lipids -d all -l lmids.txt -t `



