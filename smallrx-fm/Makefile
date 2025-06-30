CC=gcc
CFLAGS=-Wall -Ofast -march=native 
LDFLAGS=-lm -lasound

OBJS=sta.o
TARGET=sta

all: $(OBJS)
	$(CC) $(OBJS) $(LDFLAGS) -o $(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)
