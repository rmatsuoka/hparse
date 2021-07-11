#!/usr/bin/awk -f
# parsing.awk - parse for hpath

# categorize strings into types
# types
# - startTag
# - attrName
# - attrVal
# - endTag
# - voidElement
# - text

BEGIN{
	# enum states
	inQuote  = 0 # -- inside a quote inside a tag.
	             #    Its type is attrVal.
	attrVal  = 1 # -- after "=" inside a tag.
	attrName = 2 # -- befor "=" inside a tag.
	text     = 3 # -- outside a tag.

	# initial state
	state = text

	quote=""
	initText = 1

	# If the last attrNames of a tag is slash(/), then
	# the tag provides a void element. This value knows
	# that its latest attrName is slash, if it is 1.
	maybeVoidElement=0
}
function printType(type){
	printf("%s%s", type, fieldSep)
}
###########################################
# text -- outside a tag or inside a quote #
###########################################
text == state{
	if($0 ~ /^<\/[0-9a-zA-Z]+/){
		# print newline when texts exist
		printf("%s", initText ? "" :"\n")
		initText = 1

		printType("endTag")
		sub(/^<\//,"",$0);printf("%s\n", $0)
		state = attrName
		next
	}else if($0 ~ /^<[0-9a-zA-Z]+/){
		printf("%s", initText ? "" : "\n")
		initText = 1

		printType("startTag")
		sub(/^</,"",$0);printf("%s\n", $0)
		state = attrName
		next
	}

	if(initText){
		printType("text")
		initText = 0
	}
	printf("%s", $0)
	next
}
inQuote == state{
	if($0 == quote){
		printf("\n")
		state = attrName
		next
	}
	printf("%s", $0)
	next
}
#######################################
# inside a tag -- attrVal or attrName #
#######################################
{	
	# remove the marker of newlines.
	# because a newline inside tag is just separator.
	gsub(newline,"")
}
/^[ 	]*$/{
	# This is just separator.
	next
}
attrVal == state{
	printType("attrVal")
	if($0 == "'" || $0 == "\""){
		# single- or double-quoted attribute value
		quote = $0
		state = inQuote
		next
	}
	# unquoted attribute value
	printf("%s\n", $1)

	# Rest fields are attrName.
	# list ups those.
	state = attrName
	for(i=2; i<=NF; i++){
		if($i == "/"){
			maybeVoidElement=1
			continue
		}
		maybeVoidElement=0
		printType("attrName")
		printf("%s\n", $i)
	}
	next
}
attrName == state{
	if($0 == ">"){
		if(maybeVoidElement){
			printType("voidElement")
			printf("\n")
		}
		maybeVoidElement=0
		state = text
		next
	}else if($0 == "="){
		state = attrVal
		next
	}

	for(i=1; i<=NF; i++){
		if($i == "/"){
			maybeVoidElement=1
			continue
		}
		maybeVoidElement=0
		printType("attrName")
		printf("%s\n", $i)
	}
	next
}
END{
	if((text == state && initText == 0)|| inQuote == state){
		printf("\n")
	}
}
