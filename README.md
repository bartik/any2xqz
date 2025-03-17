How to use.

1) Get the pdf guides from SAP for the desired certification (if there are any).
2) Get the QuizFaber software. Extract and save an empty quiz in xqz format.
3) Get a tool to convert pdf to txt (here pdftotext is used from poppler package)
5) Convert pdfs to txt (e.g. C_TADM_23.bat)
6) Extract the questions (awk -f ADM100_EN_Col24.awk *.txt  1>test.out)
7) Add the lines with the tag Item to the saved xqz file categories/items section
8) Remove the lines with the tag Item from the test.out file
9) Add the tag <body> as a first line of the test.out file
10) Add the tag </body> as the last line of the test.out file
11a) Upload the test.out file to your favorit chatAI together with the prompt: "For the file test.out in xml format use the text in the tag remark to determine the correct answer. Set the attribute correct of the tag choice to true for the correct answers and set it to false for incorrect answers. Do this for each tag question in the file test.out where the type attribute has the value 1"
11b) Alternatively Upload the test.out file to your favorit chatAI together with the prompt: "For the appended xml use the question in the tag text to determine the correct answer. Set the attribute correct of the tag choice to true for the correct answers and set it to false for incorrect answers. Ignore the text in the tag remark. Do this for each tag question in the file test.out where the type attribute has the value 1." to see the answers your chatAI came up with.
11c) Alternatively go through the pdf's and set the correct answers based on the Assessment - Answers chapters (after you have done 12, 13)
12) Download the updated file and insert all questions into the test.xqz file (withoud the <body> tag)
13) Open the file in QuizFaber. Generate the quiz. If errors occur correct the question.
