#include "globals.h"
#include "banksetup.h"
#include "song_player.h"

#define DURATION (4*PATTERN_TIME_ZIK2) // 13 seconds

void robotgfx_init(void);
void eyes_kernal();

static const unsigned char eyescos[] = {
152, 151, 151, 151, 151, 150, 150, 149, 149, 148, 147, 146, 145, 144, 143, 141, 140, 139, 137, 136, 134, 132, 130, 129, 127, 125, 123, 120, 118, 116, 114, 112, 109, 107, 104, 102, 99, 97, 94, 92, 89, 87, 84, 81, 79, 76, 74, 71, 68, 66, 63, 60, 58, 55, 53, 50, 48, 45, 43, 41, 38, 36, 34, 32, 29, 27, 25, 23, 22, 20, 18, 16, 15, 13, 12, 10, 9, 8, 7, 5, 4, 4, 3, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 3, 4, 4, 5, 7, 8, 9, 10, 12, 13, 15, 16, 18, 20, 22, 23, 25, 27, 29, 32, 34, 36, 38, 41, 43, 45, 48, 50, 53, 55, 58, 60, 63, 66, 68, 71, 74, 76, 79, 81, 84, 87, 89, 92, 94, 97, 99, 102, 104, 107, 109, 112, 114, 116, 118, 120, 123, 125, 127, 129, 130, 132, 134, 136, 137, 139, 140, 141, 143, 144, 145, 146, 147, 148, 149, 149, 150, 150, 151, 151, 151, 151
};

static const unsigned char eyessin[] = {
120, 123, 126, 130, 133, 137, 140, 143, 147, 150, 153, 157, 160, 163, 166, 169, 172, 176, 179, 181, 184, 187, 190, 193, 195, 198, 201, 203, 206, 208, 210, 212, 215, 217, 219, 220, 222, 224, 226, 227, 229, 230, 231, 233, 234, 235, 236, 236, 237, 238, 238, 239, 239, 239, 239, 239, 239, 239, 239, 239, 238, 238, 237, 236, 236, 235, 234, 233, 231, 230, 229, 227, 226, 224, 222, 220, 219, 217, 215, 212, 210, 208, 206, 203, 201, 198, 195, 193, 190, 187, 184, 181, 179, 176, 172, 169, 166, 163, 160, 157, 153, 150, 147, 143, 140, 137, 133, 130, 126, 123, 120, 116, 113, 109, 106, 102, 99, 96, 92, 89, 86, 82, 79, 76, 73, 70, 67, 63, 60, 58, 55, 52, 49, 46, 44, 41, 38, 36, 33, 31, 29, 27, 24, 22, 20, 19, 17, 15, 13, 12, 10, 9, 8, 6, 5, 4, 3, 3, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 3, 3, 4, 5, 6, 8, 9, 10, 12, 13, 15, 17, 19, 20, 22, 24, 27, 29, 31, 33, 36, 38, 41, 44, 46, 49, 52, 55, 58, 60, 63, 67, 70, 73, 76, 79, 82, 86, 89, 92, 96, 99, 102, 106, 109, 113, 116
};

static const unsigned char eyescol[] = {
  0x60, 0x62, 0x64, 0x66, 0x68, 0x6a, 0x6c, 0x6e,
  0x6e, 0x6c, 0x6a, 0x68, 0x66, 0x64, 0x62, 0x60,
  0x20, 0x22, 0x24, 0x26, 0x28, 0x2a, 0x2c, 0x2e,
  0x2e, 0x2c, 0x2a, 0x28, 0x26, 0x24, 0x22, 0x20,
};

void eyes_fx(void) {
  unsigned char i, i2, j, j2;
  unsigned char prevx, prevx2;
  unsigned int k;

  TIA.colup0 = TIA.colup1 = 0x66;
  i = 53;
  i2 = 37;
  j = 115;
  j2 = 115; // eyessin[115] = 102
  prevx = eyescos[i];
  prevx2 = eyescos[i2];

  // Half a second delay between eyes
  TIA.hmp1 = 0;
  for(k=0; k<25; k++) {
    TIA.hmp0 = (prevx - eyescos[i]) << 4;
    TIA.wsync = 0;
    TIA.hmove = 0;
    wait_overscan();
    bankCall(eyessin[j], eyessin[j2], eyes_kernal);
    prevx = eyescos[i];
    i = i+1 >= sizeof(eyescos) ? 0 : i+1;
    j = j+1 >= sizeof(eyessin) ? 0 : j+1;
  }

  for(k=0; k<DURATION-25; k++) {
    TIA.colup0 = eyescol[(k>>2) & 0x1f];
    TIA.colup1 = eyescol[((k>>2)+8) & 0x1f];
    TIA.hmp0 = (prevx - eyescos[i]) << 4;
    TIA.hmp1 = (prevx2 - eyescos[i2]) << 4;
    TIA.wsync = 0;
    TIA.hmove = 0;
    wait_overscan();
    bankCall(eyessin[j], eyessin[j2], eyes_kernal);
    prevx = eyescos[i];
    prevx2 = eyescos[i2];
    i = i+1 >= sizeof(eyescos) ? 0 : i+1;
    i2 = i2+1 >= sizeof(eyescos) ? 0 : i2+1;
    j = j+1 >= sizeof(eyessin) ? 0 : j+1;
    j2 = j2+1 >= sizeof(eyessin) ? 0 : j2+1;
  }
}