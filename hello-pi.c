/*
Copyright (c) 2012, Broadcom Europe Ltd
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the copyright holder nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "interface/vmcs_host/vc_vchi_gencmd.h"
#include "interface/vmcs_host/vc_gencmd_defs.h"
#include <wiringPi.h>

#define TEMP_KEY_SIZE 5

void chop(char *str, size_t n);

int main()
{
  // Get board model
  int m, rev, mem, maker, ov;
  piBoardId(&m, &rev, &mem, &maker, &ov);

  printf("Raspberry Pi: %s\n", piModelNames[m]);
  printf("Revision: %s\n", piRevisionNames[rev]);

  // Get SoC temperature
  // https://github.com/raspberrypi/userland/blob/master/host_applications/linux/apps/gencmd/gencmd.c
  // vcgencmd measure_temp
  VCHI_INSTANCE_T vchi_instance;
  VCHI_CONNECTION_T *vchi_connection = NULL;

  vcos_init();

  if (vchi_initialise(&vchi_instance) != 0)
  {
    fprintf(stderr, "VCHI init failed\n");
    return 1;
  }

  // Create a vchi connection
  if (vchi_connect(NULL, 0, vchi_instance) != 0)
  {
    fprintf(stderr, "VCHI connect failed\n");
    return 1;
  }

  vc_vchi_gencmd_init(vchi_instance, &vchi_connection, 1);

  char buffer[GENCMDSERVICE_MSGFIFO_SIZE];
  size_t buffer_offset = 0;
  int ret;

  // Reset the buffer
  buffer[0] = '\0';

  // Set the cmd
  buffer_offset = vcos_safe_strcpy(buffer, "measure_temp", sizeof(buffer), buffer_offset);

  // Send the gencmd for the argument
  if ((ret = vc_gencmd_send("%s", buffer)) != 0)
  {
    printf("vc_gencmd_send returned non-zero code: %d\n", ret);
    return 1;
  }

  // Get + print out the response
  if ((ret = vc_gencmd_read_response(buffer, sizeof(buffer))) != 0)
  {
    printf("vc_gencmd_read_response returned a non-zero code: %d\n", ret);
    return 1;
  }
  buffer[sizeof(buffer) - 1] = 0;

  if (buffer[0] != '\0')
  {
    if (strncmp(buffer, "temp=", TEMP_KEY_SIZE) == 0)
    {
      chop(buffer, TEMP_KEY_SIZE);
      printf("Temperature: %s\n", buffer);
    }
    else
      puts(buffer);
  }

  vc_gencmd_stop();

  // Close the vchi connection
  if (vchi_disconnect(vchi_instance) != 0)
  {
    fprintf(stderr, "VCHI disconnect failed\n");
    return 1;
  }

  return 0;
}

void chop(char *str, size_t n)
{
  size_t len = strlen(str);
  if (n > len)
    return;
  memmove(str, str + n, len - n + 1);
}
