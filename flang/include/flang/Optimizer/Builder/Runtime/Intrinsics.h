// Builder/Runtime/Intrinsics.h  Fortran runtime codegen interface -*- C++ -*-//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Builder routines for constructing the FIR dialect of MLIR. As FIR is a
// dialect of MLIR, it makes extensive use of MLIR interfaces and MLIR's coding
// style (https://mlir.llvm.org/getting_started/DeveloperGuide/) is used in this
// module.
//
//===----------------------------------------------------------------------===//

#ifndef FORTRAN_LOWER_RUNTIME_H
#define FORTRAN_LOWER_RUNTIME_H

#include <optional>

namespace mlir {
class Location;
class Type;
class Value;
} // namespace mlir

namespace fir {
class CharBoxValue;
class FirOpBuilder;

namespace runtime {

mlir::Value genAssociated(fir::FirOpBuilder &, mlir::Location,
                          mlir::Value pointer, mlir::Value target);

void genPointerAssociate(fir::FirOpBuilder &, mlir::Location,
                         mlir::Value pointer, mlir::Value target);
void genPointerAssociateRemapping(fir::FirOpBuilder &, mlir::Location,
                                  mlir::Value pointer, mlir::Value target,
                                  mlir::Value bounds, bool isMonomorphic);

mlir::Value genCpuTime(fir::FirOpBuilder &, mlir::Location);
void genDateAndTime(fir::FirOpBuilder &, mlir::Location,
                    std::optional<fir::CharBoxValue> date,
                    std::optional<fir::CharBoxValue> time,
                    std::optional<fir::CharBoxValue> zone, mlir::Value values);
void genEtime(fir::FirOpBuilder &builder, mlir::Location loc,
              mlir::Value values, mlir::Value time);

void genFree(fir::FirOpBuilder &builder, mlir::Location loc, mlir::Value ptr);

mlir::Value genFseek(fir::FirOpBuilder &builder, mlir::Location loc,
                     mlir::Value unit, mlir::Value offset, mlir::Value whence);
mlir::Value genFtell(fir::FirOpBuilder &builder, mlir::Location loc,
                     mlir::Value unit);

mlir::Value genGetUID(fir::FirOpBuilder &, mlir::Location);
mlir::Value genGetGID(fir::FirOpBuilder &, mlir::Location);

mlir::Value genMalloc(fir::FirOpBuilder &builder, mlir::Location loc,
                      mlir::Value size);

void genRandomInit(fir::FirOpBuilder &, mlir::Location, mlir::Value repeatable,
                   mlir::Value imageDistinct);
void genRandomNumber(fir::FirOpBuilder &, mlir::Location, mlir::Value harvest);
void genRandomSeed(fir::FirOpBuilder &, mlir::Location, mlir::Value size,
                   mlir::Value put, mlir::Value get);

/// generate rename runtime call
void genRename(fir::FirOpBuilder &builder, mlir::Location loc,
               mlir::Value path1, mlir::Value path2, mlir::Value status);

/// generate time runtime call
mlir::Value genTime(fir::FirOpBuilder &builder, mlir::Location loc);

/// generate runtime call to transfer intrinsic with no size argument
void genTransfer(fir::FirOpBuilder &builder, mlir::Location loc,
                 mlir::Value resultBox, mlir::Value sourceBox,
                 mlir::Value moldBox);

/// generate runtime call to transfer intrinsic with size argument
void genTransferSize(fir::FirOpBuilder &builder, mlir::Location loc,
                     mlir::Value resultBox, mlir::Value sourceBox,
                     mlir::Value moldBox, mlir::Value size);

/// generate system_clock runtime call/s
/// all intrinsic arguments are optional and may appear here as mlir::Value{}
void genSystemClock(fir::FirOpBuilder &, mlir::Location, mlir::Value count,
                    mlir::Value rate, mlir::Value max);

// generate signal runtime call
// CALL SIGNAL(NUMBER, HANDLER [, STATUS])
// status can be {} or a value. It may also be dynamically absent
void genSignal(fir::FirOpBuilder &builder, mlir::Location loc,
               mlir::Value number, mlir::Value handler, mlir::Value status);

/// generate sleep runtime call
void genSleep(fir::FirOpBuilder &builder, mlir::Location loc,
              mlir::Value seconds);

/// generate chdir runtime call
mlir::Value genChdir(fir::FirOpBuilder &builder, mlir::Location loc,
                     mlir::Value name);

} // namespace runtime
} // namespace fir

#endif // FORTRAN_LOWER_RUNTIME_H
