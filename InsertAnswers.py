from lxml import etree
import re

def remove_last_newline_for_siblings(tree, tags):
    """
    Removes the last newline character from all specified tags in the XML tree.

    Parameters:
        tree (lxml.etree.ElementTree): The parsed XML tree.
        tags (list): A list of tag names to process.
    """
    # Combine the tags into a single XPath query
    xpath_query = " | ".join([f".//{tag}" for tag in tags])
    
    # Find all matching elements in the tree
    for element in tree.xpath(xpath_query):
        if element.text:
            # Remove the last newline character and strip whitespace
            element.text = element.text.rstrip("\n").strip()

def parse_and_add_tag(input_file, output_file):
    # Parse the XML file using lxml.etree
    tree = etree.parse(input_file)

    # Remove the last newline character from <text>, <remark>, and <choice> tags
    remove_last_newline_for_siblings(tree, ["question/text", "question/remark", "answers/choice"])

    # Use XPath to find all <question> tags with @type="1"
    for question in tree.xpath(".//question[@type='1']"):
        # Collect values of <choice> tags where correct="True"
        correct_choices = []
        for choice in question.xpath(".//answers/choice"):
            if choice.text:
                # Remove strings matching the pattern "^[A-Za-z][.)]" from the choice text
                choice.text = re.sub(r"^[A-Za-z][.)]\s*", "", choice.text.strip())
                if choice.get("correct") == "True":
                    correct_choices.append(choice.text)

        # Count the number of correct choices
        correct_count_choices = len(correct_choices)

        # Check if the <remark> tag exists
        remark = question.find("remark")
        if remark is None:  # Add <remark> only if it does not exist
            # Concatenate the collected values
            concatenated_choices = "; ".join(correct_choices)

            # Add a new <remark> tag
            remark = etree.SubElement(question, "remark")
            remark.text = f"Correct answer(s) ({correct_count_choices}): {concatenated_choices}"

        # Check and update the <text> tag
        text = question.find("text")
        if text is not None and text.text:
            text_value = text.text.strip()

            # Check if the space is missing in "[0-9A-Za-z]+correct answers"
            if re.search(r" [0-9A-Za-z]+correct answers", text_value):
                text_value = text_value.replace("correct answers", " correct answers").strip()

            # Remove "Choose the correct answers." if it exists
            text_value = text_value.replace("Please choose the correct answer.", "").strip()
            text_value = text_value.replace("Choose the correct answers.", "").strip()

            # Set the <singleAns> tag value to "True" if correct_count_choices is 1
            single_ans = question.find(".//answers/singleAns")
            if single_ans is not None:
                if correct_count_choices == 1:
                    single_ans.text = "True"
                    # Add "Choose the correct answer" to the text
                    text_value = f"{text_value} Choose the correct answer."
                else:
                    single_ans.text = "False"
                    # Add "There are {correct_count_choices} correct answers" if the pattern is missing
                    if not re.search(r"There are [0-9A-Za-z]+ correct answers", text_value) and correct_count_choices > 1:
                        text_value = f"{text_value} There are {correct_count_choices} correct answers to this question."

                # Update the text tag with the modified text_value
                text.text = text_value

    # Write the modified XML to the output file with pretty printing
    tree.write(output_file, encoding="utf-8", pretty_print=True, xml_declaration=True)
    print(f"Modified XML written to {output_file}")

# Example usage
if __name__ == "__main__":
    input_file = r"c:\Test_XXXX.xqz"
    output_file = r"c:\Test_XXXX_modified.xqz"
    parse_and_add_tag(input_file, output_file)
