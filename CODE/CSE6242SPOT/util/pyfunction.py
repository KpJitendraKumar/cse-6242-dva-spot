import osmnx as ox
import networkx as nx
import os
from sklearn.neighbors import KernelDensity
import numpy as np
import pandas as pd

print(os.getcwd())

# load your graphml file here
f_path = os.getcwd() + "/data/Atlanta_accidents_updt.graphml"

G=ox.save_load.load_graphml(filename=f_path, folder=None)

# kernel density estimation:
acc = pd.read_csv(os.getcwd()+'/data/atlanta_accidents_KDE.csv')
kde_model = KernelDensity(bandwidth=0.001, metric='haversine', kernel='gaussian', algorithm='ball_tree')

kde_model.fit((np.asarray(acc[['Start_Lat','Start_Lng']])))

def get_accident_risk(location, kde = kde_model):
    
    start = [location[0]-0.00001, location[1]-0.00001]  # Start of the range
    end = [location[0]+0.00001, location[1]+0.00001]    # End of the range
    N = 10   # Number of evaluation points 

    step = (end[0] - start[0]) / (N - 1)  # Step size
    step = step*step
    x = np.linspace(start[0], end[0], N)
    y = np.linspace(start[1], end[1], N)

    arr = []
    for i in range(len(x)):
        for j in range(len(y)):
            arr.append([x[i],y[j]])
        
    kd_vals = np.exp(kde.score_samples(arr))  # Get PDF values for each x
    probability = np.sum(kd_vals * step)  # Approximate the integral of the PDF
    return(probability)
    

def node_list_to_path(G, node_list, use_geom=True):
    """
    Given a list of nodes, return a list of lines that together follow the path
    defined by the list of nodes.
    Parameters
    ----------
    G : networkx multidigraph
    route : list
        the route as a list of nodes
    use_geom : bool
        if True, use the spatial geometry attribute of the edges to draw
        geographically accurate edges, rather than just lines straight from node
        to node
    Returns
    -------
    lines : list of lines given as pairs ( (x_start, y_start), (x_stop, y_stop) )
    """
    edge_nodes = list(zip(node_list[:-1], node_list[1:]))
    lines = []
    for u, v in edge_nodes:
        # if there are parallel edges, select the shortest in length
        data = min(G.get_edge_data(u, v).values(), key=lambda x: x['length'])

        # if it has a geometry attribute (ie, a list of line segments)
        if 'geometry' in data and use_geom:
            # add them to the list of lines to plot
            xs, ys = data['geometry'].xy
            lines.append(list(zip(xs, ys)))
        else:
            # if it doesn't have a geometry attribute, the edge is a straight
            # line from node to node
            x1 = G.nodes[u]['x']
            y1 = G.nodes[u]['y']
            x2 = G.nodes[v]['x']
            y2 = G.nodes[v]['y']
            line = [(x1, y1), (x2, y2)]
            lines.append(line)
    return lines

def path_finder(origin_point, destination_point, path_type):
	
	# get the nearest nodes to the locations
	origin_node = ox.get_nearest_node(G, origin_point)
	destination_node = ox.get_nearest_node(G, destination_point)
	
	route = nx.shortest_path(G, origin_node, destination_node, weight = path_type)
	# getting the list of coordinates from the path (which is a list of nodes)
	lines = node_list_to_path(G, route)

	long = []
	lat = []

	for i in range(len(lines)):
	    z = list(lines[i])
	    l1 = list(list(zip(*z))[0])
	    l2 = list(list(zip(*z))[1])
	    for j in range(len(l1)):
	        long.append(l1[j])
	        lat.append(l2[j])
	        
	# return the nodes
	return(list(zip(lat, long)))
