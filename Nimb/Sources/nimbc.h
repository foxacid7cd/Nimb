//
//  shims.h
//  Nimb
//
//  Created by Yevhenii Matviienko on 17.08.2024.
//

#ifndef _NIMBC_H_
#define _NIMBC_H_

#include <mach/mach.h>

void* nimb_allocate_shared_memory(size_t size);
kern_return_t nimb_deallocate_shared_memory(void* data, size_t size);

#endif
