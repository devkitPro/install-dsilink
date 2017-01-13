#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------
ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

include $(DEVKITARM)/base_tools

export TOPDIR		:=	$(CURDIR)

SAVEFILES	:=	VCKV.SAV VCKE.SAV VCKS.SAV VCKF.SAV VCKI.SAV VCKD.SAV \
	 		VCWV.SAV VCWE.SAV VCWF.SAV VBLE.SAV VBLV.SAV

.PHONY: dslink/dslink.nds

#---------------------------------------------------------------------------------
# canned command sequence for binary data
#---------------------------------------------------------------------------------
define bin2o
	bin2s $< | $(AS) -o $(@)
	echo "extern const u8" `(echo $(<F) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"_end[];" > `(echo $(@D)/$(<F) | tr . _)`.h
	echo "extern const u8" `(echo $(<F) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"[];" >> `(echo $(@D)/$(<F) | tr . _)`.h
	echo "extern const u32" `(echo $(<F) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`_size";" >> `(echo $(@D)/$(<F) | tr . _)`.h
endef

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
all: \
	data build savefiles \
	savefiles/VCKD.SAV \
	savefiles/VCKE.SAV \
	savefiles/VCKS.SAV \
	savefiles/VCKF.SAV \
	savefiles/VCKV.SAV \
	savefiles/VCKI.SAV \
	savefiles/VCWE.SAV \
	savefiles/VCWV.SAV \
	savefiles/VCWF.SAV \
	savefiles/VBLE.SAV \
	savefiles/VBLV.SAV \
	installDSiLink.nds


data:
	mkdir -p data

build:
	mkdir -p build

savefiles:
	mkdir -p savefiles

installDSiLink.nds: installDSiLink.elf
	ndstool	-c $@ -b installDSiLink.bmp "installDSiLink;;" -9 $<


data/bootstub.bin: bootstub/bootstub.elf
	$(OBJCOPY) -O binary $< $@

bootstub/bootstub.elf: bootstub/bootstub.s
	$(CC) -Ttext=0 -x assembler-with-cpp -nostartfiles -nostdlib $< -o $@

installDSiLink.elf: CFLAGS=-Wall -mthumb-interwork -march=armv5te -mtune=arm946e-s -Os -fno-strict-aliasing -DARM9 -I$(DEVKITPRO)/libnds/include -Ibuild

installDSiLink.elf: \
	build/bootstub.bin.o \
	build/dslink.nds.o \
	build/installDSiLink.o 

installDSiLink.elf:
	$(CC) -specs=ds_arm9.specs $^ -L$(DEVKITPRO)/libnds/lib -lnds9 -o $@

dslink/dslink.nds:
	$(MAKE) -C dslink dslink.nds

dslink.nds: dslink/dslink.nds
	cp	$< $@

build/bootstub_bin.h build/bootstub.bin.o: data/bootstub.bin

build/installDSiLink.o: source/installDSiLink.c build/bootstub_bin.h build/dslink_nds.h

build/dslink_nds.h build/dslink.nds.o : dslink.nds

build/dslink.nds.o: dslink.nds
	@$(bin2o)

build/%.bin.o: data/%.bin
	@$(bin2o)

build/%.o: source/%.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.s
	$(CC) -x assembler-with-cpp  -mthumb-interwork -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@


savefiles/%.SAV: cookhack/%.SAV
	cp $< $@

savefiles/%.SAV: classichack/%.SAV
	cp $< $@

savefiles/%.SAV: tblhack/%.SAV
	cp $< $@


cookhack/VCKD.SAV:
	$(MAKE)	COUNTRY=GER -C cookhack

cookhack/VCKE.SAV:
	$(MAKE)	COUNTRY=USA -C cookhack

cookhack/VCKV.SAV:
	$(MAKE)	COUNTRY=UK -C cookhack

cookhack/VCKS.SAV:
	$(MAKE)	COUNTRY=ES -C cookhack

cookhack/VCKF.SAV:
	$(MAKE)	COUNTRY=FR -C cookhack

cookhack/VCKI.SAV:
	$(MAKE)	COUNTRY=ITA -C cookhack

classichack/VCWE.SAV:
	$(MAKE)	COUNTRY=USA -C classichack

classichack/VCWV.SAV:
	$(MAKE)	COUNTRY=UK -C classichack

classichack/VCWF.SAV:
	$(MAKE)	COUNTRY=FR -C classichack

tblhack/VBLV.SAV:
	$(MAKE)	COUNTRY=EU -C tblhack

tblhack/VBLE.SAV:
	$(MAKE)	COUNTRY=USA -C tblhack

.PHONY: $(BUILD) clean

#---------------------------------------------------------------------------------
clean:
	rm -fr savefiles data build
	rm -f bootstub/*.elf
	rm -f installDSiLink.nds installDSiLink.elf
	$(MAKE) -C cookhack clean
	$(MAKE) -C classichack clean
	$(MAKE) -C tblhack clean
	$(MAKE) -C dslink clean


#---------------------------------------------------------------------------------
dist:
	rm -f dslink.tar.bz2
	tar -cvjf dslink.tar.bz2 README.html savefiles dslink.nds installDSiLink.nds host
