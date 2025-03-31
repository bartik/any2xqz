import xml.etree.ElementTree as ET
from xml.dom import minidom

def parse_and_add_tag(input_file, output_file):
    # Parse the XML file
    tree = ET.parse(input_file)
    root = tree.getroot()

    # Iterate through all <question> tags under <body>
    for question in root.findall('.//body/question'):
        # Check if the question type is "1"
        if question.get('type') == '1':
            # Check if the <remark> tag exists and is not empty
            remark_tag = question.find('remark')
            if remark_tag is None or not remark_tag.text or not remark_tag.text.strip():
                # Collect values of <choice> tags where correct="True"
                correct_choices = []
                for choice in question.findall(".//choice[@correct='True']"):
                    if choice.text:
                        correct_choices.append(choice.text.strip())

                # Concatenate the collected values
                concatenated_choices = "; ".join(correct_choices)

                # Add a new <remark> tag if it doesn't exist
                if remark_tag is None:
                    remark_tag = ET.Element('remark')
                    remark_tag.text = "Correct answer(s): " + concatenated_choices

                    # Find the <text> node and insert the <remark> node after it
                    text_node = question.find('text')
                    if text_node is not None:
                        question.insert(list(question).index(text_node) + 1, remark_tag)

    # Convert the modified XML tree to a string
    xml_string = ET.tostring(root, encoding='utf-8')

    # Pretty-print the XML string
    pretty_xml = minidom.parseString(xml_string).toprettyxml(indent="  ", newl="")

    # Write the pretty-printed XML to the output file
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(pretty_xml)

    print(f"Modified XML written to {output_file}")

# Example usage
if __name__ == "__main__":
    input_file = r"c:\Users\pbt01\Documents\Auto\C_SEC_XXXX.xqz"
    output_file = r"c:\Users\pbt01\Documents\Auto\C_SEC_XXXX_modified.xqz"
    parse_and_add_tag(input_file, output_file)
