function! WriteCorrect(args)
python3 << EOF
import vim
import glob
import re
import subprocess
from os import getcwd
from gtts import gTTS

from xml.dom.minidom import parse, parseString

curWin = vim.current.window
curBuf = vim.current.buffer
curPos = curWin.cursor

def langtooltofile(ret,f):
	ignore = ["COMMA_PARENTHESIS_WHITESPACE"]
	p = parseString(ret)
	for node in p.getElementsByTagName("error"):
		if node.attributes["ruleId"].value in ignore:
			continue
		f.write("Error: {} Id: {}\nContext: {}\n\n".format(
			node.attributes["msg"].value, node.attributes["ruleId"].value, 
			node.attributes["context"].value))

def beginsWithUpper(string):
	if len(string) > 0:
		return string[0:1].isupper()
	else:
		return False

# This functions gets the current sentence the cursor is in.
# The end of the sentence must be equal to the end of the line plus whitespace.
# The sentence must start with a capital letter at the beginning of the line.
def getCurrentSentance():
	curIdx = curPos
	buf = curBuf[curIdx[0]-1].strip()
	#curLine = curBuf[curIdx[0]-1]
	while not buf.strip().endswith('.'):
		curIdx = (curIdx[0]+1, curIdx[1])
		if curIdx[0]-1 >= len(curBuf):
			break
		else:
			buf += ' ' + curBuf[curIdx[0]-1]

	curIdx = (curPos[0]-1, curPos[1])
	while not beginsWithUpper(buf) and curIdx[0] != 0:
		buf = curBuf[curIdx[0]-1] + ' ' + buf
		curIdx = (curIdx[0]-1, curIdx[1])

	return buf

def getGlossary():
	print(os.getcwd())
	gls = glob.glob("*.gls")
	if len(gls) == 0 or len(gls) > 1:
		return []

	p = re.compile("{(?P<src>[^}]*)}{(?P<short>[^}]*)}{(?P<long>[^}]*)}")
	dic = dict()
	f = open(gls[0], 'r')
	for l in f:
		m = p.search(l)
		if m != None:
			dic[m.group("src")] = (m.group("short"), m.group("long"))

	return dic

def wordSearchRest(line,match):
	low = line.find(match)
	if low == 0 and len(line) == len(match):
		print(58)
		return ("","")
	elif low > 0 and len(line) == len(match)+low:
		print(61)
		return (line[:low], "")
	elif low > 0 and len(line) != len(match)+low:
		print(64)
		return (line[:low], line[len(match)+low:])
	elif low == 0 and len(line) != len(match)+low:
		print(67)
		return ("", line[len(match)+low:])

def begin(line,bi):
	if bi == 0:
		return ""
	else:
		return line[:bi]

def end(line,r,ei):
	if r == "\\glspl{" or r == "\\Glspl{":
		return "s " + line[ei+1:]
	else:
		return line[ei+1:]

def newGlossaryReplace(line,dic):
	ret = []
	glsStart = ["\\gls{", "\\glspl{", "\\Gls{", "\\Glspl{"]
	for w in line.split():
		if w.startswith("\\cite{"):
			ret.append(w[w.find("}")+1:])
			break
		for r in glsStart:
			idx = w.find(r)
			if idx != -1:
				closing = w[idx+len(r):].find("}") + idx + len(r)
				key = w[idx+len(r):closing]
				ret.append(begin(w,idx) + dic[key][1] + end(w,r,closing).strip())
				break
		else:
			ret.append(w)

	return " ".join(ret)

if __name__ == "__main__":
	sen = getCurrentSentance()
	glos = getGlossary()
	anArg = vim.eval("a:args")
	if anArg == "sentence":
		print(newGlossaryReplace(sen, glos))
	elif anArg == "speech":
		tts = gTTS(text=newGlossaryReplace(sen,glos), lang='en')
		name = ".speechdump.mp3"
		tts.save(name)
		import subprocess
		player = subprocess.Popen(["mplayer", name], stdin=subprocess.PIPE, 
			stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	elif anArg == "check":
		processSentence = newGlossaryReplace(sen,glos)
		senFile = ".__sentenceFile.txt"
		f = open(senFile, "w")
		f.write(processSentence)
		f.close()

		langtool = subprocess.check_output(["languagetool", "--api", "-l", "en-US", senFile])
		qqtool = subprocess.check_output(["qq", "-q", "-v", senFile])

		outputFile = ".__outputFile.txt"
		f = open(outputFile, "w")
		langtooltofile(langtool, f)
		if str(qqtool) != "b'-- .__sentenceFile.txt\\n'":
			for i in qqtool[46:].decode("utf-8"):
				f.write(i);
		f.close()

		vim.command(":set splitright")	
		vim.command(":vsplit " + outputFile)	
		vim.command(":AnsiEsc")

EOF
endfunction
