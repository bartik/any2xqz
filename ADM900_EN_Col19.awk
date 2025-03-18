#!/usr/bin/awk -f

# Initialize variables
BEGIN {
    question = ""
    explanation = ""
    in_question = 0
    in_answer = 0
    in_explanation = 0
    answer_index = 0
    process_lines = 0
    categories_item_template = "<Item Name=\"%s\" Description=\"\" MaxQuestForQuiz=\"9999\" IsRandom=\"False\" />\n"
    categories_item = ""
    question_prefix_template = "<question type=\"%d\" category=\"%s\" include=\"True\" weight=\"1\" timetoanswer=\"0\" textFormat=\"1\" sortAns=\"False\" putSeparator=\"True\">"
    question_prefix = ""
    question_suffix = "</question>"
    text_prefix = "<text>"
    text_suffix = "</text>"
    explanation_prefix = "<remark>"
    explanation_suffix = "</remark>"
    choice_prefix = "<choice correct=\"True\" TextFormat=\"1\" pointsIn=\"1\" pointsOut=\"0\">"
    choice_suffix = "</choice>"
    answers_prefix = "<answers type=\"1\"><singleAns>False</singleAns>"
    answers_suffix = "</answers>"
    score = "<score correct=\"1\" wrong=\"0\" blank=\"0\" />"
    phrase_prefix = "<answers type=\"1\"><phrase TextFormat=\"1\">"
    phrase_suffix = "</phrase></answers>"
    in_false = 0
}

# Function to trim leading and trailing whitespace
function trim(str) {
    sub(/^[[:space:]]+/, "", str)
    sub(/[[:space:]]+$/, "", str)
    return str
}

# Function to replace reserved HTML characters with their appropriate entities
function escape_html(str) {
    gsub(/&/, "\\&amp;", str)
    gsub(/</, "\\&lt;", str)
    gsub(/>/, "\\&gt;", str)
    gsub(/'/, "\\&apos;", str)
    #  \042 is the ASCII code for double quotation mark because syntax highligtning is not working with " properly
    # 201C and 201D are the Unicode code points for left and right double quotation marks + dashes/quotes
    gsub(/\042/, "\\&quot;/", str)
    gsub(/\342\200\234/, "\\&quot;", str) # 201C
    gsub(/\342\200\235/, "\\&quot;", str) # 201D
    gsub(/\342\200\223/, "-", str) # 2013
    gsub(/\342\200\224/, "-", str) # 2014
    gsub(/\342\200\231/, "\\&apos;", str) # 2019
    gsub(/\342\200\230/, "\\&apos;", str) # 2018
    #gsub(/\342\200\176/, "\\&deg;", str) # 00B0
    #gsub(/\342\200\246/, "\\&hellip;", str) # 2026
    return str
}

# Function to print the current question
function printQuestion() {
    # Normalize the question and explanation
    gsub(/[[:space:]]+/, " ", question)
    gsub(/[[:space:]]+/, " ", explanation)
    gsub(/^[[:space:]]*[0-9]*\.[[:space:]]+/, "", question)
    gsub(/^[[:space:]]*You are correct[!]/, "", explanation)
    gsub(/^[[:space:]]*Correct[.:]/, "", explanation)
    question = trim(question)
    explanation = trim(explanation)
    question = escape_html(question)
    explanation = escape_html(explanation)
    # Check if the question has already been seen
    if (questions_seen[question] != 1) {
        # Print the question in quizfaber format
        # Check if the first answer starts with a digit
        if (match(answers[1], /^[[:digit:]]/)) {
            printQuestionPrefix(4, FILENAME)
            printPhrase()
        } else {
            printQuestionPrefix(1, FILENAME)
            printAnswers()
        }
        print question_suffix
    }
    questions_seen[question] = 1
}

# Function to print the question prefix
function printQuestionPrefix( questionType, filename) {
    setQuestionPrefix(questionType, filename)
    print question_prefix
    print "\t" text_prefix question text_suffix
    if (explanation != "") {
        print "\t" explanation_prefix explanation explanation_suffix
    }
    print "\t" score
}

# Function to print the answers
function printAnswers() {
    print "\t" answers_prefix
    for (i = 1; i <= answer_index; i++) {
        gsub(/[[:space:]]+/, " ", answers[i])
        gsub(/^[[:space:]]*[[:alpha:]][[:space:]]+/, "", answers[i])
        answers[i] = trim(answers[i])
        answers[i] = escape_html(answers[i])
        print "\t\t" choice_prefix answers[i] choice_suffix
    }
    print "\t" answers_suffix
}

# Function to print the phrase
function printPhrase() {
    printf "\t%s", phrase_prefix
    for (i = 1; i <= answer_index; i++) {
        match(answers[i], /^[[:digit:]]+/, arr)
        gsub(/^[[:digit:]]+/, "", answers[i])
        first_number = arr[0]
        csv = generate_csv(first_number, answer_index)
        print "[" csv "] " answers[i]
    }
    print phrase_suffix
}

# Function to set the question prefix based on the file name
function setQuestionPrefix(questionType, filename) {
    # Remove the directory path
    n = split(filename, parts, "/")
    filename = parts[n]
    # Remove the file extension if it exists
    sub(/\.[^.]*$/, "", filename)
    # Replace "Standard" with the file name in the question prefix template
    question_prefix = sprintf(question_prefix_template, questionType, filename)
}

# Function to generate a comma-separated string
function generate_csv(first, maximum) {
    result = first
    for (j = 1; j <= maximum; j++) {
        if (j != first) {
            result = result "," j
        }
    }
    return result
}

# Set the question prefix based on the file name
FNR==1 {
    categories_item = categories_item sprintf(categories_item_template, FILENAME)
    question = ""
    explanation = ""
    in_question = 0
    in_answer = 0
    in_explanation = 0
    answer_index = 0
    first_question = 1
    in_false = 0
}

# Process only these sections of the file
/Learning Assessment - Answers[[:space:]]*$/ {
    process_lines = 1
    next
}

/Lesson 1/ {
    process_lines = 0
    next
}

process_lines == 0 {
    next
}

# Skip lines that contain garbage and could interfere with question processing
/^[[:space:]]*Learning Assessment/ { next }

# End question creation if the line contains UNIT or Glossary or Copyright
/^[[:space:]]*UNIT[[:space:]]+[[:digit:]]+/ || /^[[:space:]]*Glossary/ || /Copyright. All rights reserved./{
    in_question = 0
    in_answer = 0
    in_explanation = 0
    in_false = 0
    next
}

# Match lines that start with a number followed by a dot and space (question start)
# Sometimes the number is not recognized by OCR but the dot is
# . For which of the following tasks is it appropriate to use transaction SU24?
/^[[:space:]]*[1-9]+\. / || /^[[:space:]]*\.[[:space:]]+/ {
    # print "Question >>>>>>>>>>>>>>" $0
    if (first_question == 0) {
        printQuestion()
        question = ""
        explanation = ""
    }
    question = $0
    in_question = 1
    in_answer = 0
    in_explanation = 0
    answer_index = 0
    first_question = 0
    in_false = 0
    next
}

# Match lines that start with garbage followed by a letter (answer start)
# X D Usage reporting capabilities
# ‘a B SAP* is not subject to authorization checks.
/^[[:space:]]*[‘aX]+[[:space:]]+[A-Z][[:space:]]+/ {
    # print "Answer X [A-Z] >>>>>>>>>>>>>>" $0
    answer_index++
    answers[answer_index] = $0
    # remove the X prefix it has no significance and keep the letter
    gsub(/^[[:space:]]*[‘aX]+[[:space:]]*/, "", answers[answer_index])
    gsub(/[[:space:]]+/, " ", answers[answer_index])
    in_question = 0
    in_answer = 0
    in_explanation = 1
    next
}

# Match lines starting with a digit and followed by a space
# 2 Kernel
# 3 Default profile
# 4 Instance profile
# 1 Environment Variables
# [| A Non-repudiation
# [_] B Confidentiality
# [| C Resource availability
# [4] Assign the roles that you created to the audit user.
# [2] Update the roles.
/^[[:space:]]*[1-9\]\[|_]+[[:space:]]+/ {
    # print "Answer [|_][1-9][|_] >>>>>>>>>>>>>>" $0
    answer_index++
    answers[answer_index] = $0
    # Keep the number in prefix it is the order in answer
    gsub(/^[[:space:]]*[\]\[|_]+[[:space:]]*/, "", answers[answer_index])
    gsub(/[\]\[|_]+[[:space:]]*/, " ", answers[answer_index])
    gsub(/[[:space:]]+/, " ", answers[answer_index])
    in_question = 0
    in_answer = 0
    in_explanation = 1
    next
}

# Match lines that start with an X followed by a letter (answer start)
# D Allof the above
/^[[:space:]]*[A-Z][[:space:]]+/ && in_false == 0 {
    # print "Answer [A-Z] >>>>>>>>>>>>>>" $0
    answer_index++
    answers[answer_index] = $0
    # Keep the letter
    # gsub(/^[[:space:]]*[A-Z][[:space:]]*/, "", answers[answer_index])
    gsub(/[[:space:]]+/, " ", answers[answer_index])
    in_question = 0
    in_answer = 0
    in_explanation = 1
    next
}

# [| True
# ‘a False
/[[:space:]]+True[[:space:]]*$/ || /^[[:space:]]*True[[:space:]]*$/ {
    # print "True >>>>>>>>>>>>>>" $0
    answer_index++
    answers[answer_index] = $0
    gsub(/[[:space:]]+/, " ", answers[answer_index])
    gsub(/^[[:space:]]*[\]\[|_]+[[:space:]]*/, "", answers[answer_index])
    gsub(/^[[:space:]]*‘a[[:space:]]*/, "", answers[answer_index])
    in_question = 0
    in_answer = 0
    in_explanation = 1
    next
}

# ‘a False
/[[:space:]]+False[[:space:]]*$/ || /^[[:space:]]*False[[:space:]]*$/ {
    # print "False >>>>>>>>>>>>>>" $0
    answer_index++
    answers[answer_index] = $0
    gsub(/[[:space:]]+/, " ", answers[answer_index])
    gsub(/^[[:space:]]*[\]\[|_]+[[:space:]]*/, "", answers[answer_index])
    gsub(/^[[:space:]]*‘a[[:space:]]*/, "", answers[answer_index])
    in_question = 0
    in_answer = 0
    in_explanation = 1
    in_false = 1
    next
}

# Match lines that start with "You are correct" (explanation start)
/^[[:space:]]*You are correct/ || /^[[:space:]]*Correct[.:]/ {
    explanation = $0
    in_question = 0
    in_answer = 0
    in_explanation = 1
    next
}

# Match empty lines (end of question, answer, or explanation)
/^[[:space:]]*$/ {
    if (in_question) {
        gsub(/[[:space:]]+/, " ", question)
        in_question = 0
    } else if (in_answer) {
        gsub(/[[:space:]]+/, " ", answers[answer_index])
        in_answer = 0
        in_explanation = 1
    } else if (in_explanation) {
        gsub(/[[:space:]]+/, " ", explanation)
        in_explanation = 0
    }
    next
}

# Append lines to the current question, answer, or explanation
{
    if (in_question) {
        question = question " " $0
    } else if (in_answer) {
        answers[answer_index] = answers[answer_index] " " $0
    } else if (in_explanation) {
        explanation = explanation " " $0
    }
}

END {
    if (trim(explanation) != "") {
        printQuestion()
    }
    print categories_item
}
