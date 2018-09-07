# Makefile for metsite
CC=gcc
CPP=g++
JAVAC=javac
LD=gcc
CFLAGS=-O3
LIBS=-lm
INC=/usr/include/

all: pdbaa pdbclust chkparse

clean:
	rm -f pdbaa
	rm -f pdbclust
	rm -f chkparse

pdbaa:
		$(CC) $(CFLAGS) makepdbaa.c $(LIBS) -o makepdbaa

pdbclust:
		$(CC) $(CFLAGS) pdbclust.c $(LIBS) -o pdbclust

chkparse:
		$(CC) $(CFLAGS) chkparse.c $(LIBS) -o chkparse
