//
//  shims.c
//  Nimb
//
//  Created by Yevhenii Matviienko on 17.08.2024.
//

#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach/vm_types.h>

#include "nimbc.h"

void* nimb_allocate_shared_memory(size_t size) {
  char* data;
  kern_return_t err = vm_allocate(mach_task_self(),
                                  (vm_address_t*) &data,
                                  size,
                                  VM_FLAGS_ANYWHERE);
  if (err != KERN_SUCCESS) {
    data = NULL;
  }
  return data;
}

kern_return_t nimb_deallocate_shared_memory(void* data, size_t size) {
  return vm_deallocate(mach_task_self(), (vm_address_t) data, size);
}
