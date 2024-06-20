extends Control

var TESTING = true

@onready var http = $HTTPRequest
@onready var label = $RichTextLabel
@onready var search = $HBoxContainer/LineEdit
@onready var go = $HBoxContainer/Button


class Element:
	var value = {"element_type": "", "attributes": [], "text_value": null}
	var children = []
	
	func _init(type, attributes, innertext):
		value["element_type"] = type #Example: p
		value["attributes"] = attributes #Exapmle: id="h"
		value["text_value"] = innertext #Example: This is text


func _ready():
	var url = "https://godotengine.org"
	http.request(url)
	search.text = url

func _on_http_request_request_completed(result, response_code, headers, body):
	var html = body.get_string_from_utf8()
	label.text = html
	parser(tokenizer(html))
	if TESTING:
		get_tree().quit()

func _on_button_pressed():
	http.request(search.text)

func _on_line_edit_text_submitted(new_text):
	http.request(new_text)


func make_tree(path):
	var tree = {}
	path.reverse()
	for node in path:
		tree = {node: tree}
	path.reverse()
	return tree

func dict_to_array(dict):
	var array = []
	for key in dict:
		array.append(key)
		array.append(dict_to_array(dict[key]))
	return array

func merge_dict(dict1, dict2):
	for key in dict1.keys():
		var val = dict1[key]
		if type_string(typeof(val)) == "Dictionary":
			if key in dict2 and type_string(typeof(dict2[key])) == "Dictionary":
				merge_dict(dict1[key], dict2[key])
		else:
			if key in dict2 and key in dict1 and not type_string(typeof(dict1[key])) == "Array":
				dict1[key].append(dict2[key])
				print("WACK")
			elif key in dict2:
				dict1[key] = dict2[key]

	for key in dict2.keys():
		var val = dict2[key]
		if not key in dict1:
			dict1[key] = val

	return dict1


func tokenizer(html):
	var tokenList = []
	var inNameToken = false
	var inPropToken = false
	var body = html
	var bodypart1
	var bodypart2
	
	body = body.split("</head>")[1]
	body = body.split("</html>")[0]
	body = body.strip_edges()
	
	# Remove Style Tag
	bodypart1 = body.split("<style>")[0]
	bodypart2 = body.split("<style>")[1].split("</style>")[1]
	var css = body.split("<style>")[1].split("</style>")[0]
	bodypart1.strip_edges()
	bodypart2.strip_edges()
	body = bodypart1 + bodypart2
	
	# Remove Script Tag
	bodypart1 = body.split("<script>")[0]
	bodypart2 = body.split("<script>")[1].split("</script>")[1]
	var js = body.split("<script>")[1].split("</script>")[0]
	bodypart1.strip_edges()
	bodypart2.strip_edges()
	body = bodypart1 + bodypart2
	body += ("</script>\n</body>")
	
	#var file = FileAccess.open("res://old/body.html", FileAccess.WRITE)
	#file.store_string(str(body))
	#file.close()
	
	label.text = body
	
	for i in range(len(body)):
		var char = body[i]
		
		if char + body[min(i + 1, len(body) - 1)] == "</": 
			tokenList.append("</")
			inNameToken = false
		elif char + body[min(i + 1, len(body) - 1)] == "/>":
			tokenList.append("/>")
			inNameToken = false
		elif char == "<":
			tokenList.append("<")
			inNameToken = false
		elif char == ">":
			tokenList.append(">")
			inNameToken = false
		elif char == " " and inNameToken:
			inNameToken = false
			inPropToken = true
		else:
			if !inNameToken and char != "/":
				inNameToken = true
				tokenList.append(char)
			elif inNameToken:
				tokenList[-1] += char
	
	#var file = FileAccess.open("res://old/tokenizer.json", FileAccess.WRITE)
	#file.store_string(JSON.stringify(tokenList))
	#file.close()
	
	return tokenList


func parser(tokens):
	var tokenDict = {}
	var pathList = []
	var jumpNext = false
	
	for i in range(len(tokens)):
		if jumpNext:
			jumpNext = false
			continue
		var token = tokens[i]
		match token:
			"<":
				pathList.append(tokens[i + 1])
				tokenDict = merge_dict(tokenDict, make_tree(pathList))
			">":
				if pathList.back() in ["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"]:
					pathList.pop_back()
			"</":
				pathList.pop_back()
			"/>":
				pathList.pop_back()
	#print(tokenDict)
	
	var file = FileAccess.open("res://old/parser.json", FileAccess.WRITE)
	file.store_string(str(tokenDict))
	file.close()
