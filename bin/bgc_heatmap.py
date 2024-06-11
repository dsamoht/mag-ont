import sys
import re

import pandas as pd
import dash_bio


BGC_TO_TOXIN = {
        'BGC0000017': 'anatoxin-a',
        'BGC0000188': 'saxitoxin',
        'BGC0000384': 'lyngbyatoxin',
        'BGC0000396': 'nodularin',
        'BGC0000887': 'saxitoxin',
        'BGC0000978': 'cylindrospermopsin',
        'BGC0000979': 'cylindrospermopsin',
        'BGC0000980': 'cylindrospermopsin',
        'BGC0000981': 'cylindrospermopsin',
        'BGC0001015': 'microcystin',
        'BGC0001016': 'microcystin',
        'BGC0001017': 'microcystin',
        'BGC0001667': 'microcystin-LR',
        'BGC0001705': 'nodularin',
        'BGC0002148': 'guanitoxin'
    }



if __name__ == "__main__":

    clstr_info_mibig = pd.read_csv("/Users/thomas/ClusterGraph/Data/prodigal/mibig_roshab_env_clstr_exp/cluster_to_mibig_id.tsv", sep="\t", index_col=0, header=None)
    clstr_info_mibig = clstr_info_mibig[clstr_info_mibig[1].isin(BGC_TO_TOXIN)]
    df = pd.read_csv(sys.argv[1], index_col=0)
    df = df.loc[list(set(df.index).intersection(set(clstr_info_mibig.index)))]
    df = df[[i for i in df.columns if re.search("ROXTON", i)]]
    bgc_labels = []
    row_colors = []

    for i, index in enumerate(df.index.values):
        bgc_labels.append(BGC_TO_TOXIN[clstr_info_mibig.iloc[i,0]])

    fig = dash_bio.Clustergram(
            data=df,
            column_labels=list(df.columns.values),
            row_labels=bgc_labels,
            height=1000,
            width=1200,
            cluster='col',
            color_map= [[0.0, 'white'],
            [1.0, 'green']],
        )
    fig.update_xaxes(tickangle=315)
    fig.show()
