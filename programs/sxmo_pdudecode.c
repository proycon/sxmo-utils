#include <gammu.h>
#include <gammu-message.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
	GSM_SMSMessage m;
	GSM_Error err;
	int i;
	char timestamp[50];
	char * hexstring;

	hexstring = malloc(strlen(argv[1]) / 2);
	for (i = 0; i < strlen(argv[1]) / 2; i++) {
		sscanf(argv[1] + i*2, "%2hhx", &hexstring[i]);
	}
	err = GSM_DecodePDUFrame(NULL, &m, hexstring, strlen(argv[1]) / 2, NULL, 1);
	if (err != ERR_NONE) {
		fprintf(stderr, "Failure to parse string: %s\n",  GSM_ErrorString(err));
	}
	GSM_DateTimeToTimestamp(&m.DateTime, timestamp);

	printf("Date: %s\n", timestamp);
	printf("Number: %s\n", DecodeUnicodeConsole(m.Number));
	printf("Message:\n%s\n", DecodeUnicodeConsole(m.Text));
}
