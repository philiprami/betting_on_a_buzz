'''
find wikipedia article views for every player in the manually compiled list
of WTA players

input:
    players.csv
output:
    wikipedia.csv
'''

import argparse
import pandas as pd
from mwviews.api import PageviewsClient

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', '-i',
                        required=True, type=str,
                        help='path to players.csv file with locations')
    parser.add_argument('--end_date',
                        type=str, default='20200216',
                        help='end date to fetch views. default to last date' +
                             'found in the odds data set')
    parser.add_argument('--output', '-o',
                        type=str, default='wikipedia.csv',
                        help='data file with wikipedia article views')

    return parser.parse_args()

def get_player_data(players):
    '''
    iterate through every player and query the pageview api to get
    daily wikipedia article views

    input:
        players: list[str]
    output:
        results: pd.DataFrame
    '''
    results = pd.DataFrame(columns=['Date', 'wiki', 'Player'])
    for player in players:
        try:
            data = client.article_views('en.wikipedia', player,
                                        granularity='daily',
                                        start='20110101',
                                        end=args.end_date)
        except:
            continue

        # turn raw record data into dataframe, process
        data_df = pd.DataFrame.from_dict(data, orient='index')
        column = data_df.columns[0]
        data_df = data_df.reset_index()
        data_df.rename(columns={'index' : 'Date',
                                 column : 'wiki'}, inplace=True)
        data_df['Player'] = player

        # make sure not to add duplicated data
        date_mask = data_df['Date'].isin(results['Date'])
        player_mask = data_df['Player'].isin(results['Player'])
        dup_mask = date_mask & player_mask
        new_data = data_df[~dup_mask]
        if new_data.shape[0] == 0:
            continue

        # fill nulls and add month, day, year cols for merging later
        new_data.fillna(0, inplace=True)
        new_data['year'] = new_data['Date'].dt.year
        new_data['month'] = new_data['Date'].dt.month
        new_data['day'] = new_data['Date'].dt.day
        results = results.append(new_data)

    return results

    def combine_same_players(frame, players):
        '''
        some of the players in the data set have nicknames, maiden names or
        alike. for such players sum the results for each name. result should
        replace the old numbers with the new

        input:
            frame: pd.DataFrame, players: pd.Series
        output:
            frame: pd.DataFrame
        '''
        for odds_p, players_list in players.iteritems():
            if len(players_list) != 1:
                mask = frame.odds_player == odds_p
                combined_sum = frame[mask].groupby('Date')['wiki'].sum()
                combined_sum = combined_sum.reset_index()
                combined = frame[mask].merge(combined_sum,
                                             on='Date',
                                             how='left',
                                             suffixes=('_x', ''))
                combined.drop(columns=['wiki_x'], inplace=True)
                combined = combined[combined.player == players_list[0]]
                frame = frame[~mask]
                frame = frame.append(combined_frame)

        return frame

if __name__ == "__main__":
    args = parse_args()

    players_df = pd.read_csv(args.input)
    players = list(players_df['player'].dropna().unique())

    # initialize client
    client = PageviewsClient(user_agent="<p.ramirez@pgr.reading.ac.uk> Research")

    # fetch wiki data
    results = get_player_data(players)

    # merge in odds players
    merged = players_df[['odds_player', 'player']].merge\
      (results, left_on='player', right_on='Player',  how='left')
    merged.drop(columns=['Player'], inplace=True)

    # process... drop dates where all values are null
    merged = merged[merged.wiki.notnull()]
    nulls = merged.groupby('Date')['wiki'].sum() == 0
    null_dates = nulls[nulls == True].index.tolist()
    merged = merged[~merged.Date.isin(null_dates)]

    # combine values for players with multiple valid names
    grouped_players = merged.groupby('odds_player')['player'].unique()
    merged = combine_same_players(merged, grouped_players)

    # write to file
    merged.sort_values(['player', 'Date'], inplace=True)
    merged.to_csv(args.output, encoding='utf8', index=False)
