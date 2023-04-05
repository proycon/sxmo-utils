#include <unicode/ustdio.h>
#include <unicode/ubidi.h>

int main() {
	UFILE *in = u_finit(stdin, NULL, NULL);
	int line = 1;
	int err = 0;
	bool comment = false;

	while (true) {
		UChar chr = u_fgetc(in);
		if (chr == U_EOF) {
			break;
		} if (chr == '\n') {
			line++;
			comment = false;
			continue;
		} if (chr == '#') {
			comment = true;
		}

		if (comment)
			continue;

		if (chr >= 0xF900 && chr <= 0xFDFF) {
			u_printf("ERROR: detected legacy nerd font icon in wrong characer range: \"%C\" 0x%x on line %d\n", chr, chr, line);
			err = 1;
		}
	}

	return err;
}
