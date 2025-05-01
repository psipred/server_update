# Makefile for metsite
CC=gcc
CPP=g++
JAVAC=javac
LD=gcc
CFLAGS=-O3
LIBS=-lm
INC=/usr/include/

all: pdbaa pdbclust chkparse tdb2fasta

clean:
	rm -f pdbaa
	rm -f pdbclust
	rm -f chkparse
	rm -f tdb2fasta

pdbaa:
		$(CC) $(CFLAGS) makepdbaa.c $(LIBS) -o makepdbaa

pdbclust:
		$(CC) $(CFLAGS) pdbclust.c $(LIBS) -o pdbclust

chkparse:
		$(CC) $(CFLAGS) chkparse.c $(LIBS) -o chkparse

tdb2fasta:
		$(CC) $(CFLAGS) tdb2fasta.c $(LIBS) -o tdb2fasta
