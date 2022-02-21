# Betting on a buzz, mispricing and inefficiency in online sportsbooks
Philip Ramirez, J. James Reade, Carl Singleton

Code repository for ["Betting on a buzz, mispricing and inefficiency in online sportsbooks."](https://www.carlsingletoneconomics.com/uploads/4/2/3/0/42306545/tennis_rrs.pdf) Here you will find the code, data, and documentation necessary to reproduce the findings in our paper. Please forward all questions/concerns to p.ramirez@pgr.reading.ac.uk.

## Data
The data sources used in this project include **odds** data collected from [tennis-data.co.uk](http://www.tennis-data.co.uk), **Wikipedia** article views acquired using The Wikimedia Foundation's [pageview API](https://github.com/mediawiki-utilities/python-mwviews), and geolocations found with the [GeoPy](https://geopy.readthedocs.io/en/stable/) python package to ascertain corresponding **time zones** with the [timezonefinder](https://pypi.org/project/timezonefinder/) python package. The final dataset, detailed below, is used for estimation.
<br />
<br />
[Google Drive: Betting On A Buzz](https://drive.google.com/drive/folders/1GiRMkek1MnUAYzIhutt_Oie_XIq2vDO7?usp=sharing)

### IN
1. **Odds** - match-by-match dataset with odds, outcomes, and details of WTA matches from 2015 to 2020


2. **Wikipedia** - Wikipedia article views per day for each available WTA player from 2015 - 2020

3. **Players** - manually compiled list of player abbreviations and their corresponding full names. This will be used to merge the odds data with the Wikipedia data. Manual matching is used to account for edge cases such as maiden names.

4. **Timezones** - date, time zone, and utc offset for every unique WTA match location

### OUT
1. **Final** - data set compiled using the acquired odds, wikipedia, and time zone data

## Code
All python scripts were only used to compile and process data. Merging and regressions are contained within the do files. All data input files
for the scripts can be found in the google drive link listed in the data section. TO SKIP TO ANALYSIS AND MODELING, all you need is the final.dta file and the final.do file.

**merge_odds.do**
<br />
stata do file that compiles together every year's odds data found in the google drive. The output file (odds.dta) will be used to form the final dataset.
```
# To run
do merge_odds.do
```

**timezones.py**
<br />
python script to find timezones and corresponding utc offsets for each date/location pair found in the odds dataset
```
# To run
python timezones.py -i '/path/to/odds.dta' -o 'path/to/timezones.dta'
```

**wiki_views.py**
<br />
python script to get Wikipedia article views for every player in the manually compiled list of tennis players
```
# To run
python wiki_views.py -i '/path/to/players.csv' -o 'path/to/wikipedia.csv'
```

**elo.R**
<br />
R script to provide elo and welo rankings for every player in the dataset with ranking information. Ouput is elo.dta and welo.dta
```
# To run
Rscript elo.R
```

**merge_all.do**
<br />
merges the wikipedia article views data into the odds.dta file for winners and losers. Additionally, timezones and elo/welo are merged in. The output file (final.dta) will be used for estimation.
```
# To run
do merge_all.do
```

**final.do**
<br />
stata do file to reproduce estimations/figures found in our paper. File also includes light data manipulation/feature engineering
```
# To run
do final.do
```
