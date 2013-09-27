//
//  DTProgressStatus.h
//  DTAlertViewDemo
//
//  Created by Darktt on 13/9/26.
//  Copyright (c) 2013 Darktt. All rights reserved.
//

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
DT_EXTERN bool DTProgressStatusIsNull(DTProgressStatus status);

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
