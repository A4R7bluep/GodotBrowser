import os
os.system("cls")


class Element:
	value = {"element_type": "", "attributes": [], "text_value": None}
	children = []
	
	def __init__(self, type, attributes, innertext):
		self.value["element_type"] = type #Example: p
		self.value["attributes"] = attributes #Example: id="h"
		self.value["text_value"] = innertext #Example: This is text
	
	def __repr__(self):
		return str(self.value)


def make_tree(path, tree):
	if len(tree) == 0:
		tree.append(Element("body", [], None))
	else:
		pass

	return tree


tree = []

path = ["body", "div", "a"]
tree = make_tree(path, tree)
print(tree)