'''
find timezones and utc offsets for each location found in the dataset

input:
    odds.dta
output:
    timezones.dta
'''

import argparse
import pandas as pd
from pytz import timezone
from datetime import datetime
import matplotlib.pyplot as plt
from geopy.geocoders import Nominatim
from timezonefinder import TimezoneFinder

plt.style.use(['science','no-latex'])
plt.rcParams.update({
    "font.family": "serif",   # specify font family here
    "font.serif": ["Times"],  # specify font here
    "font.size":11})

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', '-i',
                        required=True, type=str,
                        help='path to odds.dta file with locations')
    parser.add_argument('--output', '-o',
                        type=str, default='timezones.dta',
                        help='data file with locations and timezones')

    return parser.parse_args()

def get_timezones(locations):
    '''
    given a list of locations, produce a map of locations and their
    corresponding timezones. First use geopy to find the latitude and
    longitude of the locations. Then use timezonefinder to find the time zone.
    Finally, hard code the time zone for Bali, an edge case.

    input:
        locations: list[str]
    output:
        timezones: dict{str : str}
    '''
    timezones = {}
    for loc in locations:
        if loc == '' or loc in timezones:
            continue

        loc_ob = geolocator.geocode(loc)
        tz = tz_finder.timezone_at(lng=loc_ob.longitude, lat=loc_ob.latitude)
        timezones[loc] = tz

    timezones['Bali'] = 'Asia/Shanghai'
    return timezones

def calculate_offset(frame, timezones):
    '''
    for each unique date/location pair in the data,
    find the utc offset - the time difference between the utc time zone and the
    location/time zone for the given day.

    input:
        frame: pd.DataFrame
        timezones: dict{str : str}
    output:
        results: pd.DataFrame
    '''
    results = pd.DataFrame()
    loc_date_df = frame[['date', 'location']].drop_duplicates()
    for i, row in loc_date_df.iterrows():
        if pd.isnull(row.date):
            continue

        tz = timezones[row.location]
        if tz:
            dtime = datetime.strptime(row.date, '%d/%m/%Y')
            dtime = dtime.astimezone(timezone(tz))
            utf_offset = dtime.utcoffset().total_seconds()/60/60
            row['timezone'] = str(tz)
            row['utc_offset'] = int(utf_offset)
        else:
            row['timezone'] = None
            row['utc_offset'] = None

        results = results.append(row)

    # add month, day, year cols for merging later
    dates = results.date.apply(lambda x: datetime.strptime(x, '%d/%m/%Y'))
    results[['month', 'day', 'year']] = \
      dates.apply(lambda x: pd.Series([x.month, x.day, x.year]))
    return results

if __name__ == "__main__":
    args = parse_args()

    # initialize clients
    tz_finder = TimezoneFinder()
    geolocator = Nominatim(user_agent="tennis")

    # read in data file
    df = pd.read_stata(args.input)

    # get locations then timezones
    locations = df.location.unique()
    timezones = get_timezones(locations)

    # calulate utc offset
    results = calculate_offset(df, timezones)

    # write to output
    results.to_stata(args.output)

    # gantt chart
    total = df.merge(results, on=['date', 'location'])
    gantt = total[['timezone', 'utc_offset']].drop_duplicates()
    gantt.sort_values('utc_offset', inplace=True)
    gantt['start'] = gantt['utc_offset'] - 12
    fig, ax = plt.subplots(1, figsize=(14, 10))
    ax.barh(gantt.timezone, 24, left=gantt.start, color='w', edgecolor='k')
    plt.axvline(-24, linestyle='--', label='UTC 12pm', color='k')
    plt.axvline(0, linestyle='--', label='UTC 12pm', color='k')
    plt.axvline(24, linestyle='--', label='UTC 12pm', color='k')
    ax.set_xticks([-24,-12,0,12,24])
    plt.xlim(-30,30)
    plt.show()
