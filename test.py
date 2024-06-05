import os
os.system("cls")

def make_tree(path):
	tree = {}
	path.reverse()
	for node in path:
		tree = {node: tree}
	path.reverse()
	return tree

def dict_to_array(dict):
	array = []
	for key in dict:
		array.append(key)
		array.append(dict_to_array(dict[key]))
	return array

tree = {}

path = ["body", "div", "a"]
dict1 = dict_to_array(make_tree(path))
path = ["body", "div", "p"]
dict2 = dict_to_array(make_tree(path))

# print(dict1)
# print(dict2)