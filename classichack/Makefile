include $(DEVKITARM)/base_tools

UNAME	:=	$(shell uname -s)

ifneq (,$(findstring MINGW,$(UNAME)))
	EXEEXT		:=	.exe
endif

ifeq ($(strip $(COUNTRY)),USA)
ID:=E
endif

ifeq ($(strip $(COUNTRY)),UK)
ID:=V
endif

ifeq ($(strip $(COUNTRY)),FR)
ID:=F
endif

TARGET	:=	VCW$(ID).SAV

.PHONY:	cwghack.elf

$(TARGET):	cwghack.elf cwgsum$(EXEEXT)
	$(OBJCOPY) -O binary $< $@
	./cwgsum $@

cwgsum$(EXEEXT):	cwgsum.c
	gcc -Wall -O2 $< -o $@

cwghack.elf:	cwghack.s
	$(CC) -Ttext=0 -x assembler-with-cpp -nostartfiles -nostdlib -D$(COUNTRY) $< -o $@

clean:
	rm -f cwgsum$(EXEEXT) cwghack.elf cwghack.o *.SAV
