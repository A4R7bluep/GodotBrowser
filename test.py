import os

# def setValueInTree(path, tree, value):
#     if len(path) == 1:
#         tree[path[0]] = value
#     else:
#         key = path.pop(0)
#         if key in tree:
#             setValueInTree(path, tree, value)
#         else:
#             tree[key] = {}
#             path.insert(0, key)
#             setValueInTree(path, tree, value)
#     return tree

# path = ["body", "div", "a"]
# tree = {}

# os.system("cls")
# print(setValueInTree(path, tree, 1))
def create_tree(path):
    tree = {}
    for node in reversed(path):
        tree = {node: tree}
    return tree

path = ["body", "div", "a"]
tree = {}

os.system("cls")
dict1 = create_tree(path)
path = ["body", "div", "p"]
dict2 = create_tree(path)

def merge_dict(dict1, dict2):
    for key, val in dict1.items():
        if type(val) == dict:
            if key in dict2 and type(dict2[key] == dict):
                merge_dict(dict1[key], dict2[key])
        else:
            if key in dict2:
                dict1[key] = dict2[key]

    for key, val in dict2.items():
        if not key in dict1:
            dict1[key] = val

    return dict1

print(merge_dict(dict1, dict2))


# Godot backup
# var tokenDict = {}
# var pathList = []
# var jumpNext = false

# for i in range(len(tokens)):
#     if jumpNext:
#         jumpNext = false
#         continue
#     var token = tokens[i]
#     match token:
#         "<":
#             for p in range(len(pathList)):
#                 tokenDict = setValueInTree(pathList, tokenDict, {})
#             pathList.append(tokens[i + 1])
#             jumpNext = true
#         ">":
#             pass
#         "</":
#             pathList.pop_back()
#         "/>":
#             pathList.pop_back()
# print(tokenDict)

# var file = FileAccess.open("res://parser.json", FileAccess.WRITE)
# file.store_string(str(tokenDict))
# file.close()
