//
//  NIUIFloatAnchor.m
//  Nims
//
//  Created by Yevhenii Matviienko on 20.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NIUIFloatAnchor.h"

NIUIFloatAnchor NIUIFloatAnchorMakeFromNvimArgument(nvim_string_t nvimArgument)
{
  id typeDescription = [NSString stringWithCString:nvimArgument.data
                                          encoding:NSUTF8StringEncoding];
  if ([typeDescription isEqualToString:@"NW"]) {
    return NIUIFloatAnchorTopLeft;
    
  } else if ([typeDescription isEqualToString:@"NE"]) {
    return NIUIFloatAnchorTopLeft;
    
  } else if ([typeDescription isEqualToString:@"SW"]) {
    return NIUIFloatAnchorTopLeft;
    
  } else if ([typeDescription isEqualToString:@"SE"]) {
    return NIUIFloatAnchorTopLeft;
    
  } else {
    NSLog(@"Unknown anchor type: %@", typeDescription);
    return NIUIFloatAnchorTopLeft;
  }
}
