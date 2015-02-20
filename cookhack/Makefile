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

ifeq ($(strip $(COUNTRY)),ES)
ID:=S
endif

ifeq ($(strip $(COUNTRY)),FR)
ID:=F
endif

ifeq ($(strip $(COUNTRY)),ITA)
ID:=I
endif

ifeq ($(strip $(COUNTRY)),GER)
ID:=D
endif

.PHONY:	cookhack.elf

TARGET	:=	VCK$(ID).SAV

$(TARGET): cookhack.elf cooksum$(EXEEXT)
	$(OBJCOPY) -O binary cookhack.elf $@
	./cooksum $@

cooksum$(EXEEXT):	cooksum.c
	gcc -Wall -O2 $< -o $@

cookhack.elf:	cookhack.s overflow.bin Makefile
	$(CC) -Ttext=0 -x assembler-with-cpp -D$(COUNTRY) -nostartfiles -nostdlib $< -o $@

clean:
	rm -f *.SAV cookhack.elf cooksum$(EXEEXT)