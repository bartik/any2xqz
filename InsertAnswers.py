import xml.etree.ElementTree as ET
import re

def remove_last_newline_for_siblings(tree, xpath_query):
    """
    Removes the last newline character from all specified tags in the XML tree.

    Parameters:
        tree (xml.etree.ElementTree.ElementTree): The parsed XML tree.
        tags (list): A list of tag names to process.
    """
    # Find all matching elements in the tree
    for element in tree.findall(xpath_query):
        if element.text:
            # Remove the last newline character and strip whitespace
            element.text = element.text.rstrip("\n").strip()

def parse_and_add_tag(input_file, output_file):
    # Parse the XML file using ElementTree
    tree = ET.parse(input_file)

    # Remove the last newline character from <text>, <remark>, and <choice> tags
    remove_last_newline_for_siblings(tree, './/question/text')
    remove_last_newline_for_siblings(tree, './/question/remark')
    remove_last_newline_for_siblings(tree, './/question/answers/choice')

    # Use XPath-like syntax to find all <question> tags with @type="1"
    for question in tree.findall('.//question[@type="1"]'):
        # Collect values of <choice> tags where correct="True"
        correct_choices = [
            choice.text.strip()
            for choice in question.findall('.//answers/choice[@correct="True"]')
            if choice.text
        ]

        # Count the number of correct choices
        correct_count_choices = len(correct_choices)

        # Check if the <remark> tag exists
        remark = question.find('remark')
        if remark is None:  # Add <remark> only if it does not exist
            # Concatenate the collected values
            concatenated_choices = "; ".join(correct_choices)

            # Add a new <remark> tag
            remark = ET.SubElement(question, 'remark')
            remark.text = f"Correct answer(s) ({correct_count_choices}): {concatenated_choices}"

        # Check and update the <text> tag
        text = question.find("text")
        if text is not None and text.text:
            text_value = text.text.strip()

            # Remove "Choose the correct answers." if it exists
            text_value = text_value.replace("Choose the correct answers.", "").strip()

            # Check if the pattern "There are [1-9][0-9]* correct answers" exists
            if not re.search(r"There are [1-9][0-9]* correct answers", text_value):
                # Use "is" for one correct answer and "are" for multiple correct answers
                note_verb = "is" if correct_count_choices == 1 else "are"
                updated_text = f"{text_value} Note: There {note_verb} {correct_count_choices} correct answer{'s' if correct_count_choices > 1 else ''} to this question."
                text.text = updated_text

    # Write the modified XML to the output file
    tree.write(output_file, encoding="utf-8", xml_declaration=True)
    print(f"Modified XML written to {output_file}")

# Example usage
if __name__ == "__main__":
    input_file = r"c:\Test_XXXX.xqz"
    output_file = r"c:\Test_XXXX_modified.xqz"
    parse_and_add_tag(input_file, output_file)
