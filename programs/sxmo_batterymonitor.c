#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <syslog.h>

static void help(){
	printf("Usage: sxmo_batterymonitor [POSIX style options]\nPOSIX options:\n-h\t\tprint help\n-i\tinterval\t set an interval in seconds");
	exit(EXIT_SUCCESS);
}

void term(){
	syslog (LOG_NOTICE, "sxmo_batterymonitor daemon terminated.");
	closelog();
}

int main(int argc, char* argv[], char* envp[]){
	int interval=10;
	if (argc < 3){
		help();
	}
	if ( strcmp(argv[1], "-i") == 0 ){
		interval = atoi(argv[2]);
	}
	else{
		help();
	}
	if (system("pidof -o $PPID sxmo_batterymonitor > /dev/null") == 0){
		printf("Another daemon is already running -- exiting");
		exit(EXIT_FAILURE);
	}
	if( daemon(0,0) != 0){
		exit(EXIT_FAILURE);
	}
	openlog ("sxmo_batterymonitor", LOG_PID, LOG_DAEMON);
	syslog (LOG_NOTICE, "sxmo_batterymonitor daemon started.");
	setenv("BATTERY_DEVICE","/sys/class/power_supply/axp20x-battery",0);
	setenv("DISPLAY",":0",0);
	setenv("BM_LOOP","0",0);
	setenv("BM_WARN","1",0);
	setenv("BM_WARN_THRESHOLD","15",0);
	setenv("BM_WARN_CRIT_THRESHOLD","5",0);
	char* device = getenv("BATTERY_DEVICE");
	char* cap = "/capacity",data=0;
	char* path= strcat(device,cap);
	int c=0,wrn=0,bm_disable_warn=0,bm_warn_threshold=15,bm_warn_crit_threshold=5,loop=0;
	loop = atoi(getenv("BM_LOOP"));
	bm_disable_warn = atoi(getenv("BM_WARN"));
	bm_warn_threshold = atoi(getenv("BM_WARN_THRESHOLD"));
	bm_warn_crit_threshold = atoi(getenv("BM_WARN_CRIT_THRESHOLD"));
	while (1){
		FILE *ptr = fopen(path,"r");
		fgets(&data,5,ptr);
		c = atoi(&data);
		switch( loop ){
			case 1:
				if( (bm_disable_warn == 1) && (c < bm_warn_threshold) ){
					system("$XDG_CONFIG_HOME/sxmo/hooks/battery &");
				}
				if( c < bm_warn_crit_threshold ){
					system("$XDG_CONFIG_HOME/sxmo/hooks/battery_crit &");
				}
			default:
				if( (bm_disable_warn == 1) && (c < bm_warn_threshold) && (wrn == 0)){
					wrn = 1;
					system("$XDG_CONFIG_HOME/sxmo/hooks/battery &");
				}
				if( (c < bm_warn_crit_threshold) && (wrn != 2) ){
					wrn=2;
					system("$XDG_CONFIG_HOME/sxmo/hooks/battery_crit &");
				}
				if( c >= bm_warn_crit_threshold ){
					wrn = 1;
				}
				if( c >= bm_warn_threshold ){
					wrn = 0;
				}
		}
		fclose(ptr);
		sleep(interval);
	}
	term();
	exit(EXIT_FAILURE);
}
