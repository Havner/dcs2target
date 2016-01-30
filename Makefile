CC=g++
CPPFLAGS=-std=c++98 -Wall -pedantic -Werror -g -O0
OBJS=dcs2target_phase2.o

%.o: %.c
	$(CC) -c -o $@ $(CPPFLAGS)

dcs2target_phase2.exe: $(OBJS)
	$(CC) -o $@ $(OBJS)
