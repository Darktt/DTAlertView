//
//  DTProgressStatus.h
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

#if !defined(DT_EXTERN)
#  if defined(__cplusplus)
#   define DT_EXTERN extern "C"
#  else
#   define DT_EXTERN extern
#  endif
#endif

#if !defined(DT_INLINE)
# if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#  define DT_INLINE static inline
# elif defined(__cplusplus)
#  define DT_INLINE static inline
# elif defined(__GNUC__)
#  define DT_INLINE static __inline__
# else
#  define DT_INLINE static
# endif
#endif

#ifndef DTProgressStatus_h_
#define DTProgressStatus_h_

struct DTProgressStatus {
    NSUInteger current;
    NSUInteger total;
};
typedef struct DTProgressStatus DTProgressStatus;

DT_EXTERN const DTProgressStatus DTProgressStatusZero;
DT_EXTERN bool DTProgressStatusIsZero(DTProgressStatus status);

UIKIT_EXTERN NSString *NSStringFromDTProgressStatus(DTProgressStatus status);

DT_INLINE DTProgressStatus DTProgressStatusMake(NSUInteger current, NSUInteger total);

/*** Definitions of inline functions. ***/

DT_INLINE DTProgressStatus DTProgressStatusMake(NSUInteger current, NSUInteger total)
{
    DTProgressStatus progressStatus;
    progressStatus.current = current;
    progressStatus.total = total;
    
    return progressStatus;
}

#endif
