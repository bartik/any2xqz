from xml.dom import minidom
import re

def remove_last_newline_for_siblings(dom, parent_tag, sibling_tag):
    """
    Removes the last newline character from all sibling tags of a given tag name.

    Parameters:
        dom (xml.dom.minidom.Document): The parsed XML DOM object.
        parent_tag (str): The name of the parent tag containing the siblings.
        sibling_tag (str): The name of the sibling tags to process.
    """
    # Iterate through all parent tags
    for parent in dom.getElementsByTagName(parent_tag):
        # Iterate through all sibling tags within the parent
        for sibling in parent.getElementsByTagName(sibling_tag):
            if sibling.firstChild:
                # Remove the last newline character and strip whitespace
                sibling_value = sibling.firstChild.nodeValue.rstrip("\n").strip()
                sibling.firstChild.nodeValue = sibling_value

def parse_and_add_tag(input_file, output_file):
    # Parse the XML file using minidom
    dom = minidom.parse(input_file)
    root = dom.documentElement

    # Remove the last newline character from <text>, <remark>, and <choice> tags for all <question> tags
    remove_last_newline_for_siblings(dom, "question", "text")
    remove_last_newline_for_siblings(dom, "question", "remark")
    remove_last_newline_for_siblings(dom, "question", "choice")

    # Iterate through all <question> tags
    for question in root.getElementsByTagName('question'):
        # Check if the question type is "1"
        if question.getAttribute('type') == '1':
            # Collect values of <choice> tags where correct="True"
            correct_choices = []
            for choice in question.getElementsByTagName('choice'):
                if choice.getAttribute('correct') == 'True' and choice.firstChild:
                    correct_choices.append(choice.firstChild.nodeValue.strip())

            # Count the number of correct choices
            correct_count_choices = len(correct_choices)

            # Check if the <remark> tag exists
            remark_tags = question.getElementsByTagName('remark')
            if not remark_tags:  # Add <remark> only if it does not exist
                # Concatenate the collected values
                concatenated_choices = "; ".join(correct_choices)

                # Add a new <remark> tag
                remark_tag = dom.createElement('remark')
                remark_text = dom.createTextNode(f"Correct answer(s) ({correct_count_choices}): {concatenated_choices}")
                remark_tag.appendChild(remark_text)
                question.appendChild(remark_tag)

            # Check and update the <text> tag
            text_tags = question.getElementsByTagName('text')
            if text_tags:
                text_tag = text_tags[0]
                if text_tag.firstChild:
                    text_value = text_tag.firstChild.nodeValue.strip()

                    # Remove "Choose the correct answers." if it exists
                    text_value = text_value.replace("Choose the correct answers.", "").strip()

                    # Check if the pattern "There are [1-9][0-9]* correct answers" exists
                    if not re.search(r"There are [1-9][0-9]* correct answers", text_value):
                        # Use "is" for one correct answer and "are" for multiple correct answers
                        note_verb = "is" if correct_count_choices == 1 else "are"
                        updated_text = f"{text_value} Note: There {note_verb} {correct_count_choices} correct answer{'s' if correct_count_choices > 1 else ''} to this question."
                        text_tag.firstChild.nodeValue = updated_text

    # Pretty-print the XML and remove empty lines
    pretty_xml = dom.toprettyxml(indent="  ")
    pretty_xml_no_empty_lines = "\n".join([line for line in pretty_xml.splitlines() if line.strip()])

    # Write the pretty-printed XML without empty lines to the output file
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(pretty_xml_no_empty_lines)

    print(f"Modified XML written to {output_file}")

# Example usage
if __name__ == "__main__":
    input_file = r"c:\Users\pbt01\Documents\Auto\C_SEC_XXXX.xqz"
    output_file = r"c:\Users\pbt01\Documents\Auto\C_SEC_XXXX_modified.xqz"
    parse_and_add_tag(input_file, output_file)
