import sys
import json
from xml.dom import minidom

def _metadata_entry(file: str) -> dict:
	entry = {
		'keywords': [],
	}

	dom: minidom.Document = minidom.parse(file)
	elems: minidom.Element = dom.getElementsByTagName('metadata')

	if len(elems) == 0:
		return entry

	# keywords
	keywords = entry['keywords']
	elems = elems[0].getElementsByTagName('keywords')
	if len(elems) != 0:
		for keyword in elems[0].getElementsByTagName('keyword'):
			keywords.append(keyword.firstChild.nodeValue)

	return entry

def generate(files: [str]) -> str:
	metadata = dict()

	for file in files:
		metadata[file] = _metadata_entry(file)
	
	return json.dumps(metadata, ensure_ascii=False).encode('utf8').decode()

if __name__ == '__main__':
	files = sys.argv[1:]
	
	metadata = generate(files)
	print(metadata)
