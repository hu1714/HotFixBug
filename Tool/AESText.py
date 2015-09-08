#!/usr/bin/python

key="0123456789abcdef"

from Crypto.Cipher import AES

import sys

if(len(sys.argv)==1):
	print __file__+" -e|-d inPath outPath"
	exit(1)

t = sys.argv[1]
ipath = sys.argv[2]
opath = sys.argv[3]

def AESto(mode,key,ipath,opath):
	f = file(ipath,"r")
	text = f.read()
	f.close
	if(mode=="-e"):
		en = AES.new(key,AES.MODE_ECB)
		plen = 16
		tlen = len(text)
		padlen = plen-tlen%plen
		text = text + ('\0' * padlen)
		out = en.encrypt(text)
	elif(mode=="-d"):
		de = AES.new(key,AES.MODE_ECB)
		out = de.decrypt(text)
	else:
		print "error."
		exit(1)
	of = file(opath,"w")
	of.write(out)
	of.close()

if __name__ == '__main__':
	AESto(t,key,ipath,opath)
