#include <nds.h>

u8 writeread(u8 data) {
	REG_SPIDATA = data;
	SerialWaitBusy();
	return REG_SPIDATA;
}

void readFW(int address, char *dest, int size) {
	REG_SPICNT = SPI_ENABLE | SPI_BAUD_4MHz | SPI_DEVICE_NVRAM | SPI_CONTINUOUS;
	writeread(0x03);
	writeread((address>>16)&0xff);
	writeread((address>>8)&0xff);
	writeread(address&0xff);
	int i;
	for (i=0; i < size; i++) {
		dest[i] = writeread(0);
	}
	REG_SPICNT = 0;
}

struct fwheader {
	u32	arm7FWaddress, arm7load, arm7execute, arm7size;
	u32	arm9FWaddress, arm9load, arm9execute, arm9size;

};


void boot(struct fwheader *header) {
	REG_IME = 0;
	readFW(header->arm7FWaddress,(char*)header->arm7load,header->arm7size);
	readFW(header->arm9FWaddress,(char*)header->arm9load,header->arm9size);

	__NDSHeader->arm9executeAddress = header->arm9execute;

}