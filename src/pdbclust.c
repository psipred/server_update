#define PEPSIZE 10
#define PEPSTEP 1
#define MAXNRES 100000
#define SIMCUT 90

/* Non-redundant data bank generator - DTJ 1993 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>
#include <string.h>

#define FALSE 0
#define TRUE 1
#define BIG 1000000000

#define MIN(x,y) ((x)<(y)?(x):(y))
#define MAX(x,y) ((x)>(y)?(x):(y))

/* Hashtable size is 2**HASHSIZE */
#define HASHSIZE 25

#define HASHTLEN (1 << HASHSIZE)

struct sequence
{
    unsigned short length;
    unsigned int sernum, hits;
    char *seq;
};

struct seqlist
{
    struct seqlist *next;
    struct sequence *seq;
    char           *tuple;
} *hashtab[HASHTLEN];

char            nseqs;

/* Calculate hash value */
unsigned
                hash(char *s)
{
    unsigned        hashval, l;

    for (l = hashval = 0; *s && l < PEPSIZE; s++, l++)
        hashval = ((hashval << 5) + hashval) + *s; /* hash * 33 + c */

    return hashval & ((HASHTLEN)-1);
}

int
nwscore(char *seq1, char *seq2, int len1, int len2, int gap_pen)
{
    int             diag, col, row, maxcol, maxrows[MAXNRES], toprows[MAXNRES], i, j, maxscore = -BIG;
    int             maxcgap, maxrgap[MAXNRES], maxid, now = 0, last = 1;
    int             mat[2][MAXNRES], gap[2][MAXNRES];

    for (i = 0; i < len1; i++)
	maxrows[i] = -BIG;

    for (j = len2 - 1; j >= 0; j--)
    {
	maxcol = -BIG;

	for (i = len1 - 1; i >= 0; i--)
	{
	    gap[now][i] = mat[now][i] = (seq1[i] == seq2[j]) ? 1 : 0;
	    if (j != len2 - 1 && i != len1 - 1)
	    {
		diag = mat[last][i + 1];
		col = maxcol - gap_pen;
		row = maxrows[i] - gap_pen;

		if (diag >= col && diag >= row)
		{
		    mat[now][i] += diag;
		    gap[now][i] += gap[last][i + 1];
		}
		else
		{
		    if (row > col)
		    {
			mat[now][i] += row;
			gap[now][i] += maxrgap[i+1];
		    }
		    else
		    {
			mat[now][i] += col;
			gap[now][i] += maxcgap;
		    }
		}

		if (mat[now][i] > maxscore)
		{
		    maxscore = mat[now][i];
		    maxid = gap[now][i];
		}

		if (diag > maxrows[i])
		{
		    maxrows[i] = diag;
		    maxrgap[i] = gap[last][i+1];
		    toprows[i] = j + 1;
		}
		if (diag > maxcol)
		{
		    maxcol = diag;
		    maxcgap = gap[last][i+1];
		}
	    }
	}
	now = !now;
	last = !last;
    }

    return maxid;
}

/* Lookup a seq in a hash table */
int
                lookup(char *s, struct seqlist **hashtab)
{
    int i, len, score, scoremax;
    struct seqlist *np, *bestp = NULL;
    static unsigned int sernum;

    len = strlen(s);
    sernum++;

    for (scoremax=i=0; i<=len-PEPSIZE; i++)
	for (np = hashtab[hash(s+i)]; np; np = np->next)
	    if (!memcmp(np->tuple, s+i, PEPSIZE))
	    {
		if (np->seq->sernum == sernum)
		    continue;

		np->seq->sernum = sernum;
		score = nwscore(np->seq->seq, s, np->seq->length, len, 4);
		if (score > scoremax)
		    scoremax = score;

		if (100*score >= len*SIMCUT)
		    break;
	    }

/*    printf("Score = %d\n", score); */

    return (scoremax);
}

/* Install a new sequence in a hash table */
struct seqlist *
                install(char *seq, struct seqlist **hashtab)
{
    int             i, len;
    char *pseq;
    struct sequence *sp;
    struct seqlist *np;
    unsigned        hashval;

    if (!(sp = malloc(sizeof(struct sequence))))
	return (NULL);

    if (!(pseq = strdup(seq)))
	return (NULL);

    len = strlen(seq);

    sp->seq = pseq;
    sp->length = len;
    sp->sernum = 0;

    for (i=0; i<=len-PEPSIZE; i+=PEPSTEP)
    {
	np = (struct seqlist *) malloc(sizeof(struct seqlist));
	if (!np)
	    return (NULL);
	np->seq = sp;
	np->tuple = pseq+i;
	np->seq->length = len;
	hashval = hash(seq+i);
	np->next = hashtab[hashval];
	hashtab[hashval] = np;
    }

    return (np);
}

/* Convert AA letter to numeric code (0-22) */
int
                aanum(int ch)
{
    static int      aacvs[] =
    {
	999, 0, 20, 4, 3, 6, 13, 7, 8, 9, 22, 11, 10, 12, 2,
	22, 14, 5, 1, 15, 16, 22, 19, 17, 22, 18, 21
    };

    return (isalpha(ch) ? aacvs[ch & 31] : 22);
}

/* Read FASTA formatted sequence data */
void
                getfasta(char *id, char *desc, char *seq, FILE *ifp)
{
    char            ch = '\0';

    if (fscanf(ifp, "%s", id) != 1)
      return;
    while (!feof(ifp) && (ch = getc(ifp)) != '>')
	if (isalpha(ch))
	    *seq++ = ch;
    if (ch == '>')
      fseek(ifp, -1, SEEK_CUR);
    *seq++ = '\0';
}


/* Check if sequence is similar to existing sequence and update hash if required */
int addseq(char *desc, char *seq, int seqlen)
{
    int perid;
    struct seqlist *np;

    if (seqlen >= PEPSIZE && seqlen < MAXNRES)
    {
	perid = 100 * lookup(seq, hashtab) / seqlen;

/*	printf("%ID = %d\n", perid); */

	if (perid < SIMCUT)
	{
	    if (!install(seq, hashtab))
	    {
		fprintf(stderr, "Out of memory\n");
		exit(1);
	    }
//	    printf(">%s%s\n", desc, seq);
	    printf("%s", desc);
	    fflush(stdout);
	    return 1;
	}
//	else
//	    fprintf(stderr, "## %d %s\n", perid, desc);
    }

    return 0;
}


main(int argc, char **argv)
{
    int             i, j, ns = 0, addflg, totns = 0, seqlen;
    char            buf[100000], seq[100000], desc[4096], *p;
    FILE           *ifp;

    if (argc < 1)
    {
	fprintf(stderr, "Usage: pdbclust fastafile ... fastafile");
	exit(1);
    }

    for (i = 1; i < argc; i++)
    {
	fprintf(stderr, "%s\n", argv[i]);
	ifp = fopen(argv[i], "r");
	if (!ifp)
	    exit(1);

	seqlen = 0;

	while (!feof(ifp))
	{
	    if (!fgets(buf, 65536, ifp))
		break;
	    if (buf[0] == '>')
	    {
		totns++;
		if (seqlen)
		{
		    seq[seqlen] = '\0';
		    addflg = addseq(desc, seq, seqlen);
		    ns += addflg;
		    if (addflg && ns % 1000 == 0)
			fprintf(stderr, "%d/%d\n", ns, totns);
		}
		seqlen = 0;
		strcpy(desc, buf + 1);
	    }
	    else
	    {
		p = buf - 1;
		while (*++p)
		    if (isalpha(*p))
			seq[seqlen++] = *p;
	    }
	}

	if (seqlen)
	{
	    seq[seqlen] = '\0';
	    addflg = addseq(desc, seq, seqlen);
	    ns += addflg;
	    if (addflg && ns % 1000 == 0)
		fprintf(stderr, "%d/%d\n", ns, totns);
	}

	fclose(ifp);
    }

    fprintf(stderr, "%d sequences\n", ns);
}
