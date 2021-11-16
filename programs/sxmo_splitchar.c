#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[])
{
	char key[1];

	while (fread(&key, 1, sizeof(char), stdin) == 1) {
		printf("%s ", key);
		fflush(stdout);
	}
}
