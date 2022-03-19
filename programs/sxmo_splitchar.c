// SPDX-License-Identifier: AGPL-3.0-only
// Copyright 2022 Sxmo Contributors
#include <stdio.h>

int main()
{
	char key;

	while (fread(&key, 1, sizeof(char), stdin) == 1) {
		putchar(key);
		putchar(' ');
		fflush(stdout);
	}
}
