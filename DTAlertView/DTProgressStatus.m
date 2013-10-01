//
//  DTProgressStatus.m
//
// Copyright (c) 2013 Darktt
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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