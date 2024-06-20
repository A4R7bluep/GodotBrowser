extends Control

const TESTING = true

@onready var http = $HTTPRequest
@onready var label = $RichTextLabel
@onready var search = $HBoxContainer/LineEdit
@onready var go = $HBoxContainer/Button

class TagToken:
	var tagName = ""
	var type = "OpenTag"
	var attributes = {}
	var tempAttrName = ""
	var selfClosing = false
	
	func _to_string():
		return str({"name": tagName, "type": type})


# ==============================================================================
# Tokenizer States
# ==============================================================================

enum {
	DATA,
	TAG_OPEN, 
	CHAR_REF,
	MARKUP_DECLARATION_OPEN,
	END_TAG_OPEN,
	TAG_NAME, 
	BOGUS_COMMENT,
	BEFORE_ATTRIBUTE_NAME,
	SELF_CLOSING_START_TAG,
	AFTER_ATTRIBUTE_NAME,
	ATTRIBUTE_NAME,
	ATTRIBUTE_VALUE,
}


# ==============================================================================
# Tree Builder States
# ==============================================================================

enum {
	INITIAL,
	BEFORE_HTML,
}


# ==============================================================================
# Ready Functions
# ==============================================================================

func _ready():
	#var url = "https://godotengine.org"
	#http.request(url)
	#search.text = url
	var tokenizer = Tokenizer.new()
	var markup = "<div>Divitis is a serious condition.</div>"
	var tokens = tokenizer.tokenizer_states(markup)
	print(tokens)

#func _on_http_request_request_completed(result, response_code, headers, body):
	#var html = body.get_string_from_utf8()
	#label.text = html
	#parser(tokenizer(html))
	#if TESTING:
		#get_tree().quit()

#func _on_button_pressed():
	#http.request(search.text)

#func _on_line_edit_text_submitted(new_text):
	#http.request(new_text)


# ==============================================================================
# Parser Classes
# ==============================================================================
class Tokenizer:
	var tokenizerState = DATA

	var tokens = ["doctype", "\n"]
	var token

	var alpha = [
		'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
		'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
	]

	func tokenizer_states(html):
		for character in html:
			match tokenizerState:
				DATA:
					data_eat(character)
				TAG_OPEN:
					tag_open_eat(character)
				CHAR_REF:
					char_ref_eat(character)
				#MARKUP_DECLARATION_OPEN:
					#markup_decl_eat(character)
				END_TAG_OPEN:
					end_tag_open_eat(character)
				TAG_NAME:
					tag_name_eat(character)
				BOGUS_COMMENT:
					bogus_comment_eat(character)
				BEFORE_ATTRIBUTE_NAME:
					before_attribute_name_eat(character)
				SELF_CLOSING_START_TAG:
					self_closing_start_tag_eat(character)
				AFTER_ATTRIBUTE_NAME:
					after_attribute_name_eat(character)
				ATTRIBUTE_NAME:
					attribute_name_eat(character)
				ATTRIBUTE_VALUE:
					attribute_value_eat(character)
		
		return tokens


	# ==============================================================================
	# Consuming Functions
	# ==============================================================================

	func data_eat(character):
		match character:
			"&":
				tokenizerState = CHAR_REF
			"<":
				tokenizerState = TAG_OPEN
			null:
				parse_error("unexpected-null-character")
				tokens.append(character)
			_:
				tokens.append(character)

	func tag_open_eat(character):
		if character == "!":
			tokenizerState = MARKUP_DECLARATION_OPEN
		elif character == "/":
			tokenizerState = END_TAG_OPEN
		elif character.to_upper() in alpha:
				token = TagToken.new()
				tokenizerState = TAG_NAME
				tag_name_eat(character)
		elif character == "?":
			parse_error("unexpected-question-mark-instead-of-tag-name")
			tokenizerState = BOGUS_COMMENT
			bogus_comment_eat(character)
		else:
			parse_error("invalid-first-character-of-tag-name")
			tokens.append("<")
			tokenizerState = DATA
			data_eat(character)

	func char_ref_eat(character):
		pass # Come back to at https://htmlparser.info/parser/#character-references

	func end_tag_open_eat(character):
		if character.to_upper() in alpha:
			token = TagToken.new()
			token.type = "CloseTag"
			tokenizerState = TAG_NAME
			tag_name_eat(character)
		elif character == ">":
			parse_error("missing-end-tag-name")
			tokenizerState = DATA
		else:
			parse_error("invalid-first-character-of-tag-name")
			bogus_comment_eat(character)

	func tag_name_eat(character):
		if character == "\t" or character == "\n" or character == " ":
			tokenizerState = BEFORE_ATTRIBUTE_NAME
		elif character == "/":
			tokenizerState = SELF_CLOSING_START_TAG
		elif character == ">":
			tokenizerState = DATA
			tokens.append(token)
		elif character in alpha:
				token.tagName += character.to_lower()
		elif character == null:
			parse_error('unexpected-null-character')
		else:
			token.tagName += character

	func bogus_comment_eat(character):
		pass

	func before_attribute_name_eat(character):
		token.tempAttrName = ""
		match character:
			"/", ">":
				tokenizerState = AFTER_ATTRIBUTE_NAME
				after_attribute_name_eat(character)
			_:
				tokenizerState = ATTRIBUTE_NAME
				attribute_name_eat(character)

	func after_attribute_name_eat(character):
		match character:
			"/":
				tokenizerState = SELF_CLOSING_START_TAG

	func self_closing_start_tag_eat(character):
		match character:
			">":
				token.selfClosing = true
				tokenizerState = DATA
				tokens.append(token)
			_:
				parse_error("unexpected-solidus-in-tag")
				tokenizerState = BEFORE_ATTRIBUTE_NAME
				before_attribute_name_eat(character)

	func attribute_name_eat(character):
		match character:
			"\t", " ", "/", ">":
				tokenizerState = AFTER_ATTRIBUTE_NAME
				token.attributes[token.tempAttrName] = ""
				after_attribute_name_eat(character)
			"=":
				token.attributes[token.tempAttrName] = ""
				tokenizerState = ATTRIBUTE_VALUE
			_:
				token.tempAttrName += character

	func attribute_value_eat(character):
		match character:
			"\"", "\'":
				pass
			" ":
				tokenizerState = AFTER_ATTRIBUTE_NAME
				after_attribute_name_eat(character)
			_:
				token.attributes[token.tempAttrName] += character

	#func markup_decl_eat(character):
		#match character:
			#"-":
				#pass
	
	# ==============================================================================
	# HTML Parser Error Function
	# ==============================================================================
	
	func parse_error(errorType):
		push_error("HTML PARSER ERROR OF TYPE {type}".format({"type": errorType}))
		#print_rich("[color=red][b]HTML PARSER ERROR OF TYPE {type}[/b][/color]
		#".format({"type": errorType}))

class TreeBuilder:
	var treeBuilderState = INITIAL
	
	func tree_builder_states(tokens):
		for token in tokens:
			match treeBuilderState:
				INITIAL:
					initial_eat(token)
				BEFORE_HTML:
					before_html_eat(token)
	
	# ==========================================================================
	# Consuming Functions
	# ==========================================================================
	
	func initial_eat(token):
		treeBuilderState = BEFORE_HTML
	
	func before_html_eat(token):
		if token in ["\t", "\n", " "]:
			pass
		else:
			pass

