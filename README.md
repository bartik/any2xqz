How to use.

1) Get the pdf guides from SAP for the desired certification (if there are any, see "How to prepare" for course)
2) Get the QuizFaber software. Extract and save an empty quiz in xqz format
3) Get a tool to convert pdf to txt (here pdftotext is used from poppler package)
5) Convert pdfs to txt (e.g. C_TADM_23.bat)
6) Extract the questions (awk -f ADM100_EN_Col24.awk *.txt  1>test.out)
7) Add the lines with the tag Item to the saved xqz file categories/items section
8) Remove the lines with the tag Item from the test.out file
9) Add the tag &lt;body> as a first line of the test.out file
10) Add the tag &lt;/body> as the last line of the test.out file
11) Upload the test.out file to your favorit chatAI together with the prompt: "For the file test.out in xml format use the text in the tag remark to determine the correct answer. Set the attribute correct of the tag choice to true for the correct answers and set it to false for incorrect answers. Do this for each tag question in the file test.out where the type attribute has the value 1"
12) Alternatively Upload the test.out file to your favorit chatAI together with the prompt: "For the file test.out use the question in the tag text to determine the correct answer. Set the attribute correct of the tag choice to true for the correct answers and set it to false for incorrect answers. Ignore the text in the tag remark. Do this for each tag question in the file test.out where the type attribute has the value 1." to see the answers your chatAI came up with
13) Alternatively go through the pdf's and set the correct answers based on the Assessment - Answers chapters (after you have done 15, 16)
14) Alternatively use the pdftotext so that exports also the correct answers and modify the awk script to use that to generate the correct answers
15) Download the updated file and insert all questions into the test.xqz file (withoud the <body> tag)
16) Open the file in QuizFaber. Generate the quiz. If errors occur correct the question
17) The script does create question type 4,3,2 and 1 (correct order, freetext,true/false and multiple choice) where appropriate.
18) You can use the InsertAnswers.py script to clean-up the questions and add the text with expected number of answers and a remark (if it does not exist) with a list of correct answers for questions of type=1

Helpful tools:
1) https://convertio.co/pdf-txt/
2) https://tools.pdf24.org/en/ocr-pdf
3) https://github.com/oschwartz10612/poppler-windows
4) https://www.quizfaber.com/index.php/en/
