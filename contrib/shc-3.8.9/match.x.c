#if 0
	shc Version 3.8.9, Generic Script Compiler
	Copyright (c) 1994-2012 Francisco Rosales <frosal@fi.upm.es>

	./shc -v -f match 
#endif

static  char data [] = 
#define      msg1_z	42
#define      msg1	((&data[0]))
	"\212\011\245\131\234\115\231\032\012\201\215\273\250\045\317\260"
	"\301\176\266\060\254\302\031\145\223\037\310\021\224\113\152\167"
	"\002\324\254\254\352\364\350\263\145\250"
#define      chk2_z	19
#define      chk2	((&data[44]))
	"\115\056\322\327\210\042\264\135\016\136\117\363\362\156\042\204"
	"\044\363\305\032\213\026\010\002"
#define      chk1_z	22
#define      chk1	((&data[68]))
	"\236\240\114\301\156\001\335\145\217\063\034\270\346\227\035\331"
	"\237\261\002\000\020\075\127\044\027\270\102\074"
#define      shll_z	8
#define      shll	((&data[95]))
	"\077\301\340\110\304\244\305\042\102\363"
#define      lsto_z	1
#define      lsto	((&data[104]))
	"\352"
#define      pswd_z	256
#define      pswd	((&data[140]))
	"\016\222\245\010\371\132\126\050\161\136\053\001\301\337\240\142"
	"\366\130\245\063\221\027\260\321\012\047\354\116\034\167\363\053"
	"\012\231\063\160\105\153\335\172\241\104\353\347\233\315\246\363"
	"\170\254\072\334\210\225\074\240\360\076\227\236\137\245\010\071"
	"\164\213\251\271\366\207\064\230\314\037\200\147\354\047\133\145"
	"\323\225\101\133\053\176\374\034\275\223\272\034\070\302\126\255"
	"\115\377\146\104\207\233\335\123\273\135\273\247\204\026\015\127"
	"\254\116\263\330\315\257\364\212\103\256\247\173\160\375\050\276"
	"\375\217\002\204\052\337\330\345\075\224\215\301\253\233\031\127"
	"\352\314\060\267\174\044\102\277\322\351\073\103\346\144\001\343"
	"\364\004\150\037\343\101\005\041\325\223\342\200\056\374\330\030"
	"\311\010\320\105\054\022\005\377\373\101\102\342\246\103\306\233"
	"\107\056\272\053\157\277\114\105\123\057\305\201\053\235\232\364"
	"\245\152\072\322\174\100\321\167\202\023\132\051\127\040\304\236"
	"\116\176\312\276\076\027\003\221\106\311\023\161\146\255\146\014"
	"\027\241\336\224\341\257\014\144\303\146\215\032\206\121\271\325"
	"\320\203\223\016\233\227\240\341\140\264\123\307\141\272\323\171"
	"\133\262\015\075\142\032\241\045\200\057\100\006\200\371\333\121"
	"\175\157\140\003\363\211\054\145\350\127\147\252\067\007\014\056"
	"\140\262\142\361\311\023\303\324\073\257\043\130\047\027\203\061"
	"\260\266\065\244\100\142\011\051\272\160\323\361"
#define      tst1_z	22
#define      tst1	((&data[442]))
	"\330\222\203\312\134\341\077\324\006\012\202\034\221\201\112\264"
	"\266\355\263\370\044\332\136\103\307\376\004"
#define      msg2_z	19
#define      msg2	((&data[466]))
	"\322\075\202\343\054\372\221\102\057\352\013\264\202\237\143\277"
	"\300\300\253\157\106"
#define      inlo_z	3
#define      inlo	((&data[485]))
	"\033\112\021"
#define      rlax_z	1
#define      rlax	((&data[488]))
	"\217"
#define      date_z	1
#define      date	((&data[489]))
	"\065"
#define      opts_z	1
#define      opts	((&data[490]))
	"\374"
#define      text_z	337
#define      text	((&data[559]))
	"\072\241\332\263\202\373\213\024\176\125\160\025\343\241\347\040"
	"\366\022\205\142\277\033\176\044\350\076\312\026\010\230\377\103"
	"\072\332\366\274\326\201\321\124\327\102\152\272\344\122\333\332"
	"\144\140\074\044\174\272\110\144\371\023\173\001\254\173\104\346"
	"\125\072\243\053\044\153\234\007\147\332\330\051\215\061\366\300"
	"\313\303\214\012\015\245\054\033\340\102\372\263\110\226\246\334"
	"\322\313\251\036\347\124\313\113\031\002\103\106\100\077\132\121"
	"\131\210\044\211\241\104\105\245\345\360\303\347\303\236\152\171"
	"\221\014\037\340\303\076\227\261\240\375\042\337\237\212\253\106"
	"\137\144\323\077\062\244\221\333\203\262\106\176\270\367\045\253"
	"\365\175\000\260\223\033\215\100\362\224\150\264\020\047\221\003"
	"\315\266\073\352\311\350\155\061\134\077\064\373\271\376\276\104"
	"\133\337\365\261\366\150\011\100\063\351\021\257\160\164\056\074"
	"\207\067\005\334\360\313\211\106\013\257\150\057\150\011\147\100"
	"\376\362\203\204\105\021\213\375\063\127\266\024\120\064\365\255"
	"\013\205\267\331\114\106\062\350\301\305\076\047\161\353\301\207"
	"\206\152\016\100\155\215\126\114\036\147\350\115\151\052\327\160"
	"\146\304\234\331\244\356\004\336\203\363\354\156\020\050\135\210"
	"\154\034\056\023\131\102\161\201\134\172\172\333\204\047\175\275"
	"\170\253\020\142\101\337\367\176\123\363\246\370\061\117\306\223"
	"\270\050\152\041\103\327\076\240\122\146\170\152\371\112\074\345"
	"\243\021\004\341\154\356\302\344\177\260\207\376\176\360\201\376"
	"\042\070\134\364\165\255\270\110\111\326\115\154\363\223\352\256"
	"\254\133\357\307\001\120\047\350\265\277\170\140\217\005\035\231"
	"\377\377\104\163\304\200\264\053\367\215\023\266\017\372\236\371"
	"\015\301\375\001\226\274\165\200\223\267\353\116\233\075\051\166"
	"\241\212\263\305\006\156\016\153\147\041\346\151\316\142\256\264"
	"\270\351\130\343\245\315\144\071\205\117\207\040\215\261\227\056"
	"\073\112\364\102\270\003\255\040\045\224\211\363\366\067\250\256"
	"\041\001\222\306\316\367\377\124\107\207\165\324\070\014\003\164"
	"\127\367"
#define      tst2_z	19
#define      tst2	((&data[973]))
	"\352\344\255\141\115\135\000\241\326\120\110\366\250\274\126\033"
	"\236\214\370\143\060\040\370"
#define      xecc_z	15
#define      xecc	((&data[996]))
	"\053\312\230\041\065\361\157\025\375\357\060\261\353\151\307\362"
	"\274\236"/* End of data[] */;
#define      hide_z	4096
#define DEBUGEXEC	0	/* Define as 1 to debug execvp calls */
#define TRACEABLE	0	/* Define as 1 to enable ptrace the executable */

/* rtc.c */

#include <sys/stat.h>
#include <sys/types.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

/* 'Alleged RC4' */

static unsigned char stte[256], indx, jndx, kndx;

/*
 * Reset arc4 stte. 
 */
void stte_0(void)
{
	indx = jndx = kndx = 0;
	do {
		stte[indx] = indx;
	} while (++indx);
}

/*
 * Set key. Can be used more than once. 
 */
void key(void * str, int len)
{
	unsigned char tmp, * ptr = (unsigned char *)str;
	while (len > 0) {
		do {
			tmp = stte[indx];
			kndx += tmp;
			kndx += ptr[(int)indx % len];
			stte[indx] = stte[kndx];
			stte[kndx] = tmp;
		} while (++indx);
		ptr += 256;
		len -= 256;
	}
}

/*
 * Crypt data. 
 */
void arc4(void * str, int len)
{
	unsigned char tmp, * ptr = (unsigned char *)str;
	while (len > 0) {
		indx++;
		tmp = stte[indx];
		jndx += tmp;
		stte[indx] = stte[jndx];
		stte[jndx] = tmp;
		tmp += stte[indx];
		*ptr ^= stte[tmp];
		ptr++;
		len--;
	}
}

/* End of ARC4 */

/*
 * Key with file invariants. 
 */
int key_with_file(char * file)
{
	struct stat statf[1];
	struct stat control[1];

	if (stat(file, statf) < 0)
		return -1;

	/* Turn on stable fields */
	memset(control, 0, sizeof(control));
	control->st_ino = statf->st_ino;
	control->st_dev = statf->st_dev;
	control->st_rdev = statf->st_rdev;
	control->st_uid = statf->st_uid;
	control->st_gid = statf->st_gid;
	control->st_size = statf->st_size;
	control->st_mtime = statf->st_mtime;
	control->st_ctime = statf->st_ctime;
	key(control, sizeof(control));
	return 0;
}

#if DEBUGEXEC
void debugexec(char * sh11, int argc, char ** argv)
{
	int i;
	fprintf(stderr, "shll=%s\n", sh11 ? sh11 : "<null>");
	fprintf(stderr, "argc=%d\n", argc);
	if (!argv) {
		fprintf(stderr, "argv=<null>\n");
	} else { 
		for (i = 0; i <= argc ; i++)
			fprintf(stderr, "argv[%d]=%.60s\n", i, argv[i] ? argv[i] : "<null>");
	}
}
#endif /* DEBUGEXEC */

void rmarg(char ** argv, char * arg)
{
	for (; argv && *argv && *argv != arg; argv++);
	for (; argv && *argv; argv++)
		*argv = argv[1];
}

int chkenv(int argc)
{
	char buff[512];
	unsigned long mask, m;
	int l, a, c;
	char * string;
	extern char ** environ;

	mask  = (unsigned long)&chkenv;
	mask ^= (unsigned long)getpid() * ~mask;
	sprintf(buff, "x%lx", mask);
	string = getenv(buff);
#if DEBUGEXEC
	fprintf(stderr, "getenv(%s)=%s\n", buff, string ? string : "<null>");
#endif
	l = strlen(buff);
	if (!string) {
		/* 1st */
		sprintf(&buff[l], "=%lu %d", mask, argc);
		putenv(strdup(buff));
		return 0;
	}
	c = sscanf(string, "%lu %d%c", &m, &a, buff);
	if (c == 2 && m == mask) {
		/* 3rd */
		rmarg(environ, &string[-l - 1]);
		return 1 + (argc - a);
	}
	return -1;
}

#if !TRACEABLE

#define _LINUX_SOURCE_COMPAT
#include <sys/ptrace.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <unistd.h>

#if !defined(PTRACE_ATTACH) && defined(PT_ATTACH)
#	define PTRACE_ATTACH	PT_ATTACH
#endif
void untraceable(char * argv0)
{
	char proc[80];
	int pid, mine;

	switch(pid = fork()) {
	case  0:
		pid = getppid();
		/* For problematic SunOS ptrace */
#if defined(__FreeBSD__)
		sprintf(proc, "/proc/%d/mem", (int)pid);
#else
		sprintf(proc, "/proc/%d/as",  (int)pid);
#endif
		close(0);
		mine = !open(proc, O_RDWR|O_EXCL);
		if (!mine && errno != EBUSY)
			mine = !ptrace(PTRACE_ATTACH, pid, 0, 0);
		if (mine) {
			kill(pid, SIGCONT);
		} else {
			perror(argv0);
			kill(pid, SIGKILL);
		}
		_exit(mine);
	case -1:
		break;
	default:
		if (pid == waitpid(pid, 0, 0))
			return;
	}
	perror(argv0);
	_exit(1);
}
#endif /* !TRACEABLE */

char * xsh(int argc, char ** argv)
{
	char * scrpt;
	int ret, i, j;
	char ** varg;
	char * me = getenv("_");
	if (me == NULL) { me = argv[0]; }

	stte_0();
	 key(pswd, pswd_z);
	arc4(msg1, msg1_z);
	arc4(date, date_z);
	if (date[0] && (atoll(date)<time(NULL)))
		return msg1;
	arc4(shll, shll_z);
	arc4(inlo, inlo_z);
	arc4(xecc, xecc_z);
	arc4(lsto, lsto_z);
	arc4(tst1, tst1_z);
	 key(tst1, tst1_z);
	arc4(chk1, chk1_z);
	if ((chk1_z != tst1_z) || memcmp(tst1, chk1, tst1_z))
		return tst1;
	ret = chkenv(argc);
	arc4(msg2, msg2_z);
	if (ret < 0)
		return msg2;
	varg = (char **)calloc(argc + 10, sizeof(char *));
	if (!varg)
		return 0;
	if (ret) {
		arc4(rlax, rlax_z);
		if (!rlax[0] && key_with_file(shll))
			return shll;
		arc4(opts, opts_z);
		arc4(text, text_z);
		arc4(tst2, tst2_z);
		 key(tst2, tst2_z);
		arc4(chk2, chk2_z);
		if ((chk2_z != tst2_z) || memcmp(tst2, chk2, tst2_z))
			return tst2;
		/* Prepend hide_z spaces to script text to hide it. */
		scrpt = malloc(hide_z + text_z);
		if (!scrpt)
			return 0;
		memset(scrpt, (int) ' ', hide_z);
		memcpy(&scrpt[hide_z], text, text_z);
	} else {			/* Reexecute */
		if (*xecc) {
			scrpt = malloc(512);
			if (!scrpt)
				return 0;
			sprintf(scrpt, xecc, me);
		} else {
			scrpt = me;
		}
	}
	j = 0;
	varg[j++] = argv[0];		/* My own name at execution */
	if (ret && *opts)
		varg[j++] = opts;	/* Options on 1st line of code */
	if (*inlo)
		varg[j++] = inlo;	/* Option introducing inline code */
	varg[j++] = scrpt;		/* The script itself */
	if (*lsto)
		varg[j++] = lsto;	/* Option meaning last option */
	i = (ret > 1) ? ret : 0;	/* Args numbering correction */
	while (i < argc)
		varg[j++] = argv[i++];	/* Main run-time arguments */
	varg[j] = 0;			/* NULL terminated array */
#if DEBUGEXEC
	debugexec(shll, j, varg);
#endif
	execvp(shll, varg);
	return shll;
}

int main(int argc, char ** argv)
{
#if DEBUGEXEC
	debugexec("main", argc, argv);
#endif
#if !TRACEABLE
	untraceable(argv[0]);
#endif
	argv[1] = xsh(argc, argv);
	fprintf(stderr, "%s%s%s: %s\n", argv[0],
		errno ? ": " : "",
		errno ? strerror(errno) : "",
		argv[1] ? argv[1] : "<null>"
	);
	return 1;
}
