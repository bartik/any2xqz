#!/usr/bin/awk -f

# Initialize variables
BEGIN {
    question = ""
    explanation = ""
    in_question = 0
    in_answer = 0
    in_explanation = 0
    answer_index = 0
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
    gsub(/\042/, "\\&quot;", str)
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
    gsub(/^[[:space:]]*[0-9]+\./, "", question)
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
    print "\t" explanation_prefix explanation explanation_suffix
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
}

# Skip lines that contain garbage
/Copyright/ { next }
/Unit [[:digit:]]+: Learning Assessment/ { next }
/^[[:space:]]*UNIT[[:space:]]+[[:digit:]]+/ || /^[[:space:]]*Glossary/{
    in_question = 0
    in_answer = 0
    in_explanation = 0
    next
}

# Match lines that start with a number followed by a dot (question start)
/^[[:space:]]*[0-9]+\./ {
    if (trim(explanation) != "") {
        printQuestion()
        question = ""
        explanation = ""
    }
    question = $0
    in_question = 1
    in_answer = 0
    in_explanation = 0
    answer_index = 0
    next
}

# Match lines that start with an X followed by a letter (answer start)
/^[[:space:]]*[X0-9]+[[:space:]]+[A-Z]/ {
    answer_index++
    answers[answer_index] = $0
    gsub(/^[[:space:]]*X[[:space:]]*/, "", answers[answer_index])
    gsub(/[[:space:]]+/, " ", answers[answer_index])
    in_question = 0
    in_answer = 1
    in_explanation = 0
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
