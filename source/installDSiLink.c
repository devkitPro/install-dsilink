#include <nds.h>

#include <string.h>
#include <stdio.h>

#include "dslink_nds.h"
#include "bootstub_bin.h"
#include "fwboot_bin.h"


struct fwheader {
	int	arm7FWaddress, arm7load, arm7execute, arm7size;
	int	arm9FWaddress, arm9load, arm9execute, arm9size;
};

char booter[2048];
int fwbase = 0x10000;


char readbuf[256];

bool fwWriteBinary(int address, void *buffer, int size) {

	int blocks = (size + 255) /256;

	int i;

	for ( i = 0; i < blocks; i++ ) {

		iprintf("writing block %d of %d\r", i+1, blocks);

		readFirmware(address, readbuf, 256);

		if (memcmp(readbuf,buffer,256)) {
			writeFirmware(address,buffer,256);
			readFirmware(address, readbuf, 256);
			if (memcmp(readbuf,buffer,256)) break;
		}

		address += 256;
		buffer += 256;
	}
	iprintf("\n");
	return (i == blocks);
}


void installDSiLink() {

	tNDSHeader *ndsfile = (tNDSHeader *)dslink_nds;

	memcpy(booter,bootstub_bin,bootstub_bin_size);
	memcpy(&booter[bootstub_bin_size],fwboot_bin,fwboot_bin_size);

	struct fwheader *fwhdr = (struct fwheader*)(&booter[bootstub_bin_size + 4]);

	*(u32*)(&booter[4])=fwboot_bin_size;

	fwhdr->arm7load = ndsfile->arm7destination;
	fwhdr->arm7execute = ndsfile->arm7executeAddress;
	fwhdr->arm7size = ndsfile->arm7binarySize;

	fwhdr->arm9load = ndsfile->arm9destination;
	fwhdr->arm9execute = ndsfile->arm9executeAddress;
	fwhdr->arm9size = ndsfile->arm9binarySize;

	fwhdr->arm7FWaddress = fwbase + 2048;
	fwhdr->arm9FWaddress = fwbase + 2048 + ((fwhdr->arm7size + 255) & ~255);

	u8 *arm7bin = (u8 *)(ndsfile->arm7romOffset + (u32)ndsfile);

	u8 *arm9bin = (u8 *)(ndsfile->arm9romOffset + (u32)ndsfile);

	if (!fwWriteBinary(fwhdr->arm7FWaddress,arm7bin,fwhdr->arm7size)) {
		iprintf ("failed writing arm7 code\n");
		return;
	}

	if (!fwWriteBinary(fwhdr->arm9FWaddress,arm9bin,fwhdr->arm9size)) {
		iprintf ("failed writing arm9 code\n");
		return;
	}

	if (!fwWriteBinary(fwbase,booter,2048)) {
		iprintf ("failed writing boot code\n");
		return;
	}



}

int main(int argc, char ** argv) {


	consoleDemoInit();
	iprintf("DSi dslink installer.\n\n");
	iprintf("Press A,B,X,Y to install.\n\n");

	int buttonseq[] = { KEY_A, KEY_B, KEY_X, KEY_Y, -1};

	int seq = 0;

	while(1) {

		if(buttonseq[seq] == -1) {
			seq = 0;
			installDSiLink();
		}

		swiWaitForVBlank();
		scanKeys();

		int press = keysDown();

		if ( press & KEY_START) break;

		if (press) {
			if (press&buttonseq[seq]) {
				seq++;
			} else {
				seq = 0;
			}
		}

	}
	return 0;
}