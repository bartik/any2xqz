#!/usr/bin/awk -f

# Initialize variables
BEGIN {
    question = ""
    explanation = ""
    in_question = 0
    in_answer = 0
    in_explanation = 0
    answer_index = 0
    question_prefix = "<question type=\"1\" category=\"Standard\" include=\"True\" weight=\"1\" timetoanswer=\"0\" textFormat=\"1\" sortAns=\"False\" putSeparator=\"True\">"
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
    # 201C and 201D are the Unicode code points for left and right double quotation marks
    gsub(/\042/, "\\&quot;", str)
    gsub(/\342\200\234/, "\\&quot;", str) # 201C
    gsub(/\342\200\235/, "\\&quot;", str) # 201D
    return str
}

# Function to print the current question
function printQuestion() {
    # Normalize the question and explanation
    gsub(/[[:space:]]+/, " ", question)
    gsub(/[[:space:]]+/, " ", explanation)
    gsub(/^[[:space:]]*[0-9]+\./, "", question)
    gsub(/^[[:space:]]*You are correct[!]/, "", explanation)
    question = trim(question)
    explanation = trim(explanation)
    question = escape_html(question)
    explanation = escape_html(explanation)
    # Print the question in quizfaber format
    print question_prefix
    print "\t" text_prefix question text_suffix
    print "\t" explanation_prefix explanation explanation_suffix
    print "\t" score
    print "\t" answers_prefix
    for (i = 1; i <= answer_index; i++) {
        gsub(/[[:space:]]+/, " ", answers[i])
        gsub(/^[[:space:]]*[[:alpha:]][[:space:]]+/, "", answers[i])
        answers[i] = trim(answers[i])
        answers[i] = escape_html(answers[i])
        print "\t\t" choice_prefix answers[i] choice_suffix
    }
    print "\t" answers_suffix
    print question_suffix
}

# Skip lines that contain garbage
/Copyright/ { next }
/Unit [[:digit:]]+: Learning Assessment/ { next }

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
/^[[:space:]]*X[[:space:]]*[A-Z]/ {
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
/^[[:space:]]*You are correct/ {
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
}