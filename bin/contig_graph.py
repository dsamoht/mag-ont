import sys

from dash import Dash, html
import dash_cytoscape as cyto
import networkx as nx
import pickle
import polars as pl

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


app = Dash(__name__)

df = pickle.load(open(sys.argv[1], "rb"))
df = df.filter(pl.col("source") != "MIBiG")
graph = nx.MultiGraph()

gene_to_cluster = {}

def add_clstr_as_nodes(row):
    gene = row[0].split()[0].split(">")[1]
    gene_to_cluster[gene] = row[3]
    return 0

df.map_rows(add_clstr_as_nodes)

sorted_genes = sorted(gene_to_cluster.keys())
for i, gene in enumerate(sorted_genes):
    if i < len(sorted_genes) - 1:
        next_gene = sorted_genes[i+1]
        name_1, pos_1 = gene.split("_")[:-1], gene.split("_")[-1]
        name_2, pos_2 = next_gene.split("_")[:-1], next_gene.split("_")[-1]
        if name_1 == name_2 and (int(pos_2) - int(pos_1) == 1):
            graph.add_node(gene_to_cluster[gene], label=gene_to_cluster[gene])
            graph.add_node(gene_to_cluster[next_gene], label=gene_to_cluster[next_gene])
            graph.add_edge(gene_to_cluster[gene], gene_to_cluster[next_gene], label=str(name_1), value="_".join(gene.split("_")[:-1]))

data = nx.cytoscape_data(graph)

app.layout = html.Div([
    html.P("Contiguity Graph"),
    cyto.Cytoscape(
        id='Gene Contiguity Graph',
        elements=data['elements']['nodes'] + data['elements']['edges'],
        style={'width': '100%', 'height': '600px'},
        layout={"name": "cose"},
        stylesheet=[
            {
                'selector': 'edge',
                'style': {
                    'label': 'data(label)',
                    'curve-style': 'bezier',
                }
            },
            {
                'selector': 'node',
                'style': {
                    'label': 'data(label)'
                }
            },
        ]
    )
])

app.run_server(debug=True)
