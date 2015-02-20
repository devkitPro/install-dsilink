include $(DEVKITARM)/base_tools

ifeq ($(strip $(COUNTRY)),USA)
ID:=E
endif

ifeq ($(strip $(COUNTRY)),EU)
ID:=V
endif


BASENAME := VBL$(ID)

TARGET	:=	$(BASENAME).SAV

$(TARGET): $(BASENAME).elf
	$(OBJCOPY) -O binary $< $@

$(BASENAME).elf: TBLdslink.s
	$(CC) -Ttext=0 -x assembler-with-cpp -D$(COUNTRY) -nostartfiles -nostdlib $< -o $@

clean:
	rm -f *.SAV *.elf