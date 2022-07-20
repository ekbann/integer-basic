.PHONY: clean
.SUFFIXES:

TARGET=c64

CC=$(CC65_BIN)/cc65
CFLAGS=-O -t $(TARGET)
AS=$(CC65_BIN)/ca65
AFLAGS=-t $(TARGET) -g
LD=$(CC65_BIN)/ld65
LDFLAGS=-t $(TARGET)
AR=$(CC65_BIN)/ar65

colortest.prg: colortest.o 
	$(LD) -o $@ $(LDFLAGS) $^ $(TARGET).lib

%.o: %.s
	$(AS) -o $@ $(AFLAGS) $<

%.s: %.c
	$(CC) -I $(CC65_INC) -o $@ $(CFLAGS) $<

clean:
	rm -f colortest.prg colortest.o colortest.s
