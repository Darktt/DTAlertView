//
//  DTProgressStatus.m
//  DTAlertViewDemo
//
//  Created by Darktt on 13/9/26.
//  Copyright (c) 2013 Darktt. All rights reserved.
//

#import "DTProgressStatus.h"

const DTProgressStatus DTProgressStatusZero = {0, 0};

bool DTProgressStatusIsZero(DTProgressStatus status)
{
    return status.current == 0 && status.total == 0;
}

NSString *NSStringFromDTProgressStatus(DTProgressStatus status)
{
    return [NSString stringWithFormat:@"%d/%d", status.current, status.total];
}