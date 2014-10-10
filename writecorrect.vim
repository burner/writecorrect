function! WriteCorrect()
python << EOF
import vim
import glob
import re
from os import getcwd

curWin = vim.current.window
curBuf = vim.current.buffer
curPos = curWin.cursor

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
	curLine = curBuf[curIdx[0]-1]
	while curLine.strip().endswith('.') != -1:
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


	#\\newacronym{rowa}{ROWA}{Read-One/Write-All}
	p = re.compile("{(?P<src>[^}]*)}{(?P<short>[^}]*)}{?P<long>[^}]*}")
	dic = dict()
	f = open(gls[0], 'r')
	for l in f:
		m = p.search(l)
		if m != None:
			print("FOO",m.group())
			dict[m.group("src")] = (m.group("short"), m.group("long"))
		else:
			print(l)

	return dic


print(getCurrentSentance())
print(getGlossary())

EOF
endfunction
