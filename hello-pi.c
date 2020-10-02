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
