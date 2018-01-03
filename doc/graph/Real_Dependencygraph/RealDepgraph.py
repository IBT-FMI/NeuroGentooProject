#!/us6/bin/python

import graph_tool.all as gt
import math


g_green = (0x73/255.0, 0xD2/255.0, 0x16/255.0, 1)
g_purple = (0x54/255.0, 0x48/255.0, 0x7A/255.0, 1)
g_purple = (0x6E/255.0, 0x56/255.0, 0xAF/255.0, 1)

#g = gt.collection.data["polblogs"] #  http://www2.scedu.unibo.it/roversi/SocioNet/AdamicGlanceBlogWWW.pdf
g = gt.load_graph("RealDepgraph.dot")
print(g.num_vertices(), g.num_edges())

#reduce to only connected nodes
g = gt.GraphView(g,vfilt=lambda v: (v.out_degree() > 0) and (v.in_degree() > 0) )
g.purge_vertices()

print(g.num_vertices(), g.num_edges())

#use 1->Republican, 2->Democrat
red_blue_map = {1:(1,0,0,1),0:(0,0,1,1)}
plot_color = g.new_vertex_property('vector<double>')
g.vertex_properties['plot_color'] = plot_color
for v in g.vertices():
	if g.vertex_properties['vertex_name'][v] == "sci-biology/samri":
		plot_color[v] = g_green #red_blue_map[g.vertex_properties['value'][v]]
	else:
		plot_color[v] = (0,0,0,1)
#edge colors
alpha=0.15
edge_color = g.new_edge_property('vector<double>')
g.edge_properties['edge_color']=edge_color
for e in g.edges():
	if g.vertex_properties['vertex_name'][e.source()] == "sci-biology/samri":
		edge_color[e]=g_green;
	else:
		edge_color[e]=g_purple

state = gt.minimize_nested_blockmodel_dl(g, deg_corr=True)
bstack = state.get_bstack()
t = gt.get_hierarchy_tree(state)[0]
tpos = pos = gt.radial_tree_layout(t, t.vertex(t.num_vertices() - 1), weighted=True)
cts = gt.get_hierarchy_control_points(g, t, tpos)
pos = g.own_property(tpos)
b = bstack[0].vp["b"]

#labels
text_rot = g.new_vertex_property('double')
g.vertex_properties['text_rot'] = text_rot
for v in g.vertices():
	if pos[v][0] >0:
		text_rot[v] = math.atan(pos[v][1]/pos[v][0])
	else:
		text_rot[v] = math.pi + math.atan(pos[v][1]/pos[v][0])

size=8048
gt.graph_draw(g, pos=pos, vertex_fill_color=g.vertex_properties['plot_color'], 
			vertex_color=g.vertex_properties['plot_color'],
			edge_control_points=cts,
			vertex_size=10,
			vertex_text=g.vertex_properties['vertex_name'],
			vertex_text_rotation=g.vertex_properties['text_rot'],
			vertex_text_position="centered",
			vertex_text_color=g.vertex_properties['plot_color'],
			vertex_font_size=18*2,
			edge_color=g.edge_properties['edge_color'],
			vertex_anchor=0,
			bg_color=[1,1,1,0],
			output_size=[size,size],
			output='RealDepgraph.png')
