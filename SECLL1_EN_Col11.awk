#!/usr/bin/awk -f

# Initialize variables
BEGIN {
	question = ""
	explanation = ""
	inQuestion = 0
	inAnswer = 0
	inExplanation = 0
	answerIndex = 0
	processLines = 0
	categoriesItemTemplate = "<Item Name=\"%s\" Description=\"\" MaxQuestForQuiz=\"9999\" IsRandom=\"False\" />\n"
	categoriesItem = ""
	questionPrefixTemplate = "<question type=\"%d\" category=\"%s\" include=\"True\" weight=\"1\" timetoanswer=\"0\" textFormat=\"1\" sortAns=\"False\" putSeparator=\"True\">"
	questionPrefix = ""
	questionSuffix = "</question>"
	textPrefix = "<text>"
	textSuffix = "</text>"
	explanationPrefix = "<remark>"
	explanationSuffix = "</remark>"
	choicePrefix = "<choice correct=\"True\" TextFormat=\"1\" pointsIn=\"1\" pointsOut=\"0\">"
	choiceSuffix = "</choice>"
	answersPrefix = "<answers type=\"1\"><singleAns>False</singleAns>"
	answersSuffix = "</answers>"
	score = "<score correct=\"1\" wrong=\"0\" blank=\"0\" />"
	phrasePrefix = "<answers type=\"1\"><phrase TextFormat=\"1\">"
	phraseSuffix = "</phrase></answers>"
	freetextPrefix = "<answers>"
	freetextSuffix = "</answers>"
	truefalsePrefix = "<answers><sentence is=\"True\" TextFormat=\"1\">"
	truefalseSuffix = "</sentence></answers>"
	inFalse = 0
}

# Set the question prefix based on the file name
FNR == 1 {
	# Print the last question of the previous file
	if (NR > FNR) {
		printQuestion()
	}
	categoriesItem = categoriesItem sprintf(categoriesItemTemplate, generateCategory())
	question = ""
	explanation = ""
	inQuestion = 0
	inAnswer = 0
	inExplanation = 0
	answerIndex = 0
	firstQuestion = 1
	inFalse = 0
}

# Process only these sections of the file
/Learning Assessment - Answers[[:space:]]*$/ {
	processLines = 1
	next
}

/Lesson 1/ {
	processLines = 0
	next
}

processLines == 0 {
	next
}

# Skip lines that contain garbage and could interfere with question processing
/^[[:space:]]*Learning Assessment/ {
	next
}

# End question creation if the line contains UNIT or Glossary or Copyright
/^[[:space:]]*UNIT[[:space:]]+[[:digit:]]+/ || /^[[:space:]]*Glossary/ || /Copyright. All rights reserved./ {
	inQuestion = 0
	inAnswer = 0
	inExplanation = 0
	next
}

# Match lines that start with a number followed by a dot and space (question start)
/^[[:space:]]*[1-9][0-9]*\. / || /^[[:space:]]*\.[[:space:]]+/ {
	if (firstQuestion == 0) {
		printQuestion()
		question = ""
		explanation = ""
	}
	question = $0
	inQuestion = 1
	inAnswer = 0
	inExplanation = 0
	answerIndex = 0
	firstQuestion = 0
	inFalse = 0
	next
}

# Match lines that start with garbage followed by a letter (answer start)
/^[[:space:]]*[\342\200\230aX]+[[:space:]]+[A-Z][[:space:]]+/ {
	answerIndex++
	answers[answerIndex] = $0
	gsub(/^[[:space:]]*[\342\200\230aX]+[[:space:]]*/, "", answers[answerIndex])
	gsub(/[[:space:]]+/, " ", answers[answerIndex])
	inQuestion = 0
	inAnswer = 0
	inExplanation = 1
	next
}

# Match lines starting with a digit and followed by a space
/^[[:space:]]*[1-9\]\[|_]+[[:space:]]+/ {
	answerIndex++
	answers[answerIndex] = $0
	gsub(/^[[:space:]]*[\]\[|_]+[[:space:]]*/, "", answers[answerIndex])
	gsub(/[\]\[|_]+[[:space:]]*/, " ", answers[answerIndex])
	gsub(/[[:space:]]+/, " ", answers[answerIndex])
	inQuestion = 0
	inAnswer = 0
	inExplanation = 1
	next
}

/[[:space:]]+True[[:space:]]*$/ || /^[[:space:]]*True[[:space:]]*$/ {
	answerIndex++
	answers[answerIndex] = $0
	gsub(/[[:space:]]+/, " ", answers[answerIndex])
	gsub(/^[[:space:]]*[\]\[|_]+[[:space:]]*/, "", answers[answerIndex])
	gsub(/^[[:space:]]*\342\200\230a[[:space:]]*/, "", answers[answerIndex])
	inQuestion = 0
	inAnswer = 0
	inExplanation = 1
	next
}

/[[:space:]]+False[[:space:]]*$/ || /^[[:space:]]*False[[:space:]]*$/ {
	answerIndex++
	answers[answerIndex] = $0
	gsub(/[[:space:]]+/, " ", answers[answerIndex])
	gsub(/^[[:space:]]*[\]\[|_]+[[:space:]]*/, "", answers[answerIndex])
	gsub(/^[[:space:]]*\342\200\230a[[:space:]]*/, "", answers[answerIndex])
	inQuestion = 0
	inAnswer = 0
	inExplanation = 1
	inFalse = 1
	next
}

/^[[:space:]]*You are correct/ || /^[[:space:]]*Correct[.:]/ {
	explanation = $0
	inQuestion = 0
	inAnswer = 0
	inExplanation = 1
	next
}

# The position of this block matters. It must be always behind the False block
/^[[:space:]]*[A-Z][[:space:]]+/ && inFalse == 0 {
	answerIndex++
	answers[answerIndex] = $0
	gsub(/[[:space:]]+/, " ", answers[answerIndex])
	inQuestion = 0
	inAnswer = 0
	inExplanation = 1
	next
}

/^[[:space:]]*$/ {
	if (inQuestion) {
		gsub(/[[:space:]]+/, " ", question)
		inQuestion = 0
	} else if (inAnswer) {
		gsub(/[[:space:]]+/, " ", answers[answerIndex])
		inAnswer = 0
		inExplanation = 1
	} else if (inExplanation) {
		gsub(/[[:space:]]+/, " ", explanation)
		inExplanation = 0
	}
	next
}

{
	if (inQuestion) {
		question = question " " $0
	} else if (inAnswer) {
		answers[answerIndex] = answers[answerIndex] " " $0
	} else if (inExplanation) {
		explanation = explanation " " $0
	}
}

END {
	printQuestion()
	print categoriesItem
}


# Function to replace reserved HTML characters with their appropriate entities
function escapeHtml(str)
{
	gsub(/&/, "\\&amp;", str)
	gsub(/</, "\\&lt;", str)
	gsub(/>/, "\\&gt;", str)
	gsub(/'/, "\\&apos;", str)
	#  \042 is the ASCII code for double quotation mark because syntax highligtning is not working with " properly
	# 201C and 201D are the Unicode code points for left and right double quotation marks + dashes/quotes
	gsub(/\042/, "\\&quot;/", str)
	gsub(/\342\200\234/, "\\&quot;", str)	# 201C
	gsub(/\342\200\235/, "\\&quot;", str)	# 201D
	gsub(/\342\200\223/, "-", str)	# 2013
	gsub(/\342\200\224/, "-", str)	# 2014
	gsub(/\342\200\231/, "\\&apos;", str)	# 2019
	gsub(/\342\200\230/, "\\&apos;", str)	# 2018
	#gsub(/\342\200\176/, "\\&deg;", str) # 00B0
	#gsub(/\342\200\246/, "\\&hellip;", str) # 2026
	return str
}

# Function to create category name
function generateCategory()
{
	n = split(FILENAME, parts, "/")
	filename = parts[n]
	sub(/\.[^.]*$/, "", filename)
	return filename
}

# Function to generate a comma-separated string
function generateCsv(first, maximum)
{
	result = first
	for (j = 1; j <= maximum; j++) {
		if (j != first) {
			result = result "," j
		}
	}
	return result
}

# Function to print the answers
function printAnswers()
{
	print "\t" answersPrefix
	for (i = 1; i <= answerIndex; i++) {
		gsub(/[[:space:]]+/, " ", answers[i])
		gsub(/^[[:space:]]*[[:alpha:]][[:space:]]+/, "", answers[i])
		answers[i] = trim(answers[i])
		answers[i] = escapeHtml(answers[i])
		print "\t\t" choicePrefix answers[i] choiceSuffix
	}
	print "\t" answersSuffix
}

# Function to print the phrase
function printFreeText()
{
	printf "\t%s", freetextPrefix
	print freetextSuffix
}

# Function to print the phrase
function printPhrase()
{
	printf "\t%s", phrasePrefix
	for (i = 1; i <= answerIndex; i++) {
		match(answers[i], /^[[:digit:]]+/, arr)
		gsub(/^[[:digit:]]+/, "", answers[i])
		firstNumber = arr[0]
		csv = generateCsv(firstNumber, answerIndex)
		print "[" csv "] " answers[i]
	}
	print phraseSuffix
}

# Function to print the current question
function printQuestion()
{
	# Normalize the question and explanation
	gsub(/[[:space:]]+/, " ", question)
	gsub(/[[:space:]]+/, " ", explanation)
	gsub(/^[[:space:]]*[0-9]*\.[[:space:]]+/, "", question)
	gsub(/^[[:space:]]*You are correct[!]/, "", explanation)
	gsub(/^[[:space:]]*Correct[.:!]/, "", explanation)
	question = trim(question)
	explanation = trim(explanation)
	question = escapeHtml(question)
	explanation = escapeHtml(explanation)
	# Check if the question has already been seen
	if (questionsSeen[question] != 1) {
		# Print the question in quizfaber format
		if (match(answers[1], /^[[:digit:]]/)) {
			questionPrefix = sprintf(questionPrefixTemplate, 4, generateCategory())
			print questionPrefix
			printQuestionPostfix()
			printPhrase()
		} else if ((match(answers[1], /True/) && match(answers[2], /False/) && answerIndex == 2)||(match(question, /Determine whether this statement is true or false./))) {
			questionPrefix = sprintf(questionPrefixTemplate, 2, generateCategory())
			print questionPrefix
			# Use a regular expression to match the last sentence starting with '. ' or '? ' for a True/False question
			n = split(question, parts, /[;.?][[:space:]]+/)
			lastSentence = parts[n]
			sub(lastSentence, "", question)
			question = trim(question)
			lastSentence = trim(lastSentence)
			printQuestionPostfix()
			print "\t" truefalsePrefix lastSentence truefalseSuffix
		} else if (answerIndex > 0) {
			questionPrefix = sprintf(questionPrefixTemplate, 1, generateCategory())
			print questionPrefix
			printQuestionPostfix()
			printAnswers()
		} else {
			questionPrefix = sprintf(questionPrefixTemplate, 3, generateCategory())
			print questionPrefix
			# Freetext questions have the explanation as part of the question parsed.
			match(question, /[.?][[:space:]]+/)
			if (RSTART > 0) {
				explanation = substr(question, RSTART + 2)
				question = substr(question, 1, RSTART + 1)
			}
			question = trim(question)
			explanation = trim(explanation)
			printQuestionPostfix()
			printFreeText()
		}
		print questionSuffix
	}
	questionsSeen[question] = 1
}

# Function to print the question postfix
function printQuestionPostfix()
{
	print "\t" textPrefix question textSuffix
	if (explanation != "") {
		print "\t" explanationPrefix explanation explanationSuffix
	}
	print "\t" score
}

# Function to trim leading and trailing whitespace
function trim(str)
{
	sub(/^[[:space:]]+/, "", str)
	sub(/[[:space:]]+$/, "", str)
	return str
}
