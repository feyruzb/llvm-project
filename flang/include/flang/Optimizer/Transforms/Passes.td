//===-- Passes.td - Transforms pass definition file --------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains definitions for passes within the Optimizer/Transforms/
// directory.
//
//===----------------------------------------------------------------------===//

#ifndef FLANG_OPTIMIZER_TRANSFORMS_PASSES
#define FLANG_OPTIMIZER_TRANSFORMS_PASSES

include "mlir/Pass/PassBase.td"

def AbstractResultOpt
  : Pass<"abstract-result"> {
  let summary = "Convert fir.array, fir.box and fir.rec function result to "
                "function argument";
  let description = [{
    This pass is required before code gen to the LLVM IR dialect,
    including the pre-cg rewrite pass.
  }];
  let dependentDialects = [
    "fir::FIROpsDialect", "mlir::func::FuncDialect"
  ];
  let options = [
    Option<"passResultAsBox", "abstract-result-as-box",
           "bool", /*default=*/"false",
           "Pass fir.array<T> result as fir.box<fir.array<T>> argument instead"
           " of fir.ref<fir.array<T>>.">
  ];
}

def AffineDialectPromotion : Pass<"promote-to-affine", "::mlir::func::FuncOp"> {
  let summary = "Promotes `fir.{do_loop,if}` to `affine.{for,if}`.";
  let description = [{
    Convert fir operations which satisfy affine constraints to the affine
    dialect.

    `fir.do_loop` will be converted to `affine.for` if the loops inside the body
    can be converted and the indices for memory loads and stores satisfy
    `affine.apply` criteria for symbols and dimensions.

    `fir.if` will be converted to `affine.if` where possible. `affine.if`'s
    condition uses an integer set (==, >=) and an analysis is done to determine
    the fir condition's parent operations to construct the integer set.

    `fir.load` (`fir.store`) will be converted to `affine.load` (`affine.store`)
    where possible. This conversion includes adding a dummy `fir.convert` cast
    to adapt values of type `!fir.ref<!fir.array>` to `memref`. This is done
    because the affine dialect presently only understands the `memref` type.
  }];
  let constructor = "::fir::createPromoteToAffinePass()";
  let dependentDialects = [
    "fir::FIROpsDialect", "mlir::func::FuncDialect",
    "mlir::affine::AffineDialect"
  ];
}

def AffineDialectDemotion : Pass<"demote-affine", "::mlir::func::FuncOp"> {
  let summary = "Converts `affine.{load,store}` back to fir operations";
  let description = [{
    Affine dialect's default lowering for loads and stores is different from
    fir as it uses the `memref` type. The `memref` type is not compatible with
    the Fortran runtime. Therefore, conversion of memory operations back to
    `fir.load` and `fir.store` with `!fir.ref<?>` types is required.
  }];
  let constructor = "::fir::createAffineDemotionPass()";
  let dependentDialects = [
    "fir::FIROpsDialect", "mlir::func::FuncDialect",
    "mlir::affine::AffineDialect"
  ];
}

def FIRToSCFPass : Pass<"fir-to-scf"> {
  let summary = "Convert FIR structured control flow ops to SCF dialect.";
  let description = [{
    Convert FIR structured control flow ops to SCF dialect.
  }];
  let constructor = "::fir::createFIRToSCFPass()";
  let dependentDialects = [
    "fir::FIROpsDialect", "mlir::scf::SCFDialect"
  ];
}

def AnnotateConstantOperands : Pass<"annotate-constant"> {
  let summary = "Annotate constant operands to all FIR operations";
  let description = [{
    The MLIR canonicalizer makes a distinction between constants based on how
    they are packaged in the IR. A constant value is wrapped in an Attr and that
    Attr can be attached to an Op. There is a distinguished Op, ConstantOp, that
    merely has one of these Attr attached.

    The MLIR canonicalizer treats constants referenced by an Op and constants
    referenced through a ConstantOp as having distinct semantics. This pass
    eliminates that distinction, so hashconsing of Ops, basic blocks, etc.
    behaves as one would expect.
  }];
  let constructor = "::fir::createAnnotateConstantOperandsPass()";
  let dependentDialects = [ "fir::FIROpsDialect" ];
}

def ArrayValueCopy : Pass<"array-value-copy", "::mlir::func::FuncOp"> {
  let summary = "Convert array value operations to memory operations.";
  let description = [{
    Transform the set of array value primitives to a memory-based array
    representation.

    The Ops `array_load`, `array_store`, `array_fetch`, and `array_update` are
    used to manage abstract aggregate array values. A simple analysis is done
    to determine if there are potential dependences between these operations.
    If not, these array operations can be lowered to work directly on the memory
    representation. If there is a potential conflict, a temporary is created
    along with appropriate copy-in/copy-out operations. Here, a more refined
    analysis might be deployed, such as using the affine framework.

    This pass is required before code gen to the LLVM IR dialect.
  }];
  let constructor = "::fir::createArrayValueCopyPass()";
  let dependentDialects = [ "fir::FIROpsDialect" ];
  let options = [
    Option<"optimizeConflicts", "optimize-conflicts", "bool",
           /*default=*/"false",
           "do more detailed conflict analysis to reduce the number "
           "of temporaries">
  ];
}

def CharacterConversion : Pass<"character-conversion"> {
  let summary = "Convert CHARACTER entities with different KINDs";
  let description = [{
    Translates entities of one CHARACTER KIND to another.

    By default the translation is to naively zero-extend or truncate a code
    point to fit the destination size.
  }];
  let dependentDialects = [ "fir::FIROpsDialect" ];
  let options = [
    Option<"useRuntimeCalls", "use-runtime-calls",
           "std::string", /*default=*/"std::string{}",
           "Generate runtime calls to a named set of conversion routines. "
           "By default, the conversions may produce unexpected results.">
  ];
}

def CFGConversion : Pass<"cfg-conversion"> {
  let summary = "Convert FIR structured control flow ops to CFG ops.";
  let description = [{
    Transform the `fir.do_loop`, `fir.if`, `fir.iterate_while` and
    `fir.select_type` ops into plain old test and branch operations. Removing
    the high-level control structures can enable other optimizations.

    This pass is required before code gen to the LLVM IR dialect.
  }];
  let dependentDialects = [
    "fir::FIROpsDialect", "mlir::func::FuncDialect"
  ];
  let options = [
    Option<"forceLoopToExecuteOnce", "always-execute-loop-body", "bool",
           /*default=*/"false",
           "force the body of a loop to execute at least once">,
    Option<"setNSW", "set-nsw", "bool",
           /*default=*/"true",
           "set nsw on loop variable increment">
  ];
}

def ExternalNameConversion : Pass<"external-name-interop", "mlir::ModuleOp"> {
  let summary = "Convert name for external interoperability";
  let description = [{
    Demangle FIR internal name and mangle them for external interoperability.
  }];
  let options = [
    Option<"appendUnderscoreOpt", "append-underscore",
           "bool", /*default=*/"true",
           "Append trailing underscore to external names.">
  ];
}

def CompilerGeneratedNamesConversion : Pass<"compiler-generated-names",
    "mlir::ModuleOp"> {
  let summary = "Convert names of compiler generated globals";
  let description = [{
    Transforms names of compiler generated globals to avoid
    characters that might be unsupported by some target toolchains.
    All special symbols are replaced with a predefined 'X' character.
    This is only done for uniqued names that are not externally facing.
    The uniqued names always use '_Q' prefix, and the user entity names
    are always lower cased, so using 'X' instead of the special symbols
    will guarantee that the converted name will not conflict with the user
    space. This pass does not affect the externally facing names,
    because the expectation is that the compiler will not generate
    externally facing names on its own, and these names cannot use
    special symbols.
  }];
}

def MemRefDataFlowOpt : Pass<"fir-memref-dataflow-opt", "::mlir::func::FuncOp"> {
  let summary =
    "Perform store/load forwarding and potentially removing dead stores.";
  let description = [{
    This pass performs store to load forwarding to eliminate memory accesses and
    potentially the entire allocation if all the accesses are forwarded.
  }];
  let constructor = "::fir::createMemDataFlowOptPass()";
  let dependentDialects = [
    "fir::FIROpsDialect", "mlir::func::FuncDialect"
  ];
}

// This needs to be a "mlir::ModuleOp" pass, because we are creating debug for
// the module in this pass.
def AddDebugInfo : Pass<"add-debug-info", "mlir::ModuleOp"> {
  let summary = "Add the debug info";
  let description = [{
    Emit debug info that can be understood by llvm.
  }];
  let constructor = "::fir::createAddDebugInfoPass()";
  let dependentDialects = [
    "fir::FIROpsDialect", "mlir::func::FuncDialect", "mlir::LLVM::LLVMDialect",
    "mlir::DLTIDialect"
  ];
  let options = [
    Option<"debugLevel", "debug-level",
           "mlir::LLVM::DIEmissionKind",
           /*default=*/"mlir::LLVM::DIEmissionKind::Full",
           "debug level",
           [{::llvm::cl::values(
            clEnumValN(mlir::LLVM::DIEmissionKind::Full, "Full", "Emit full debug info"),
            clEnumValN(mlir::LLVM::DIEmissionKind::LineTablesOnly, "LineTablesOnly", "Emit line tables only"),
            clEnumValN(mlir::LLVM::DIEmissionKind::None, "None", "Emit no debug information")
          )}]
           >,
    Option<"isOptimized", "is-optimized",
           "bool", /*default=*/"false",
           "is optimized.">,
    Option<"inputFilename", "file-name",
           "std::string",
           /*default=*/"std::string{}",
           "name of the input source file">,
  ];
}

// This needs to be a "mlir::ModuleOp" pass, because it inserts simplified
// functions into the module, which is invalid if a finer grain mlir::Operation
// is used as the pass specification says to not touch things outside hte scope
// of the operation being processed.
def SimplifyIntrinsics : Pass<"simplify-intrinsics", "mlir::ModuleOp"> {
  let summary = "Intrinsics simplification";
  let description = [{
    Qualifying intrinsics calls are replaced with calls to a specialized and
    simplified function. The simplified function is added to the current module.
    This function can be inlined by a general purpose inlining pass.
  }];

  let options = [
    Option<"enableExperimental", "enable-experimental", "bool",
           /*default=*/"false",
           "Enable experimental code that may not always work correctly">
  ];
}

def MemoryAllocationOpt : Pass<"memory-allocation-opt", "mlir::func::FuncOp"> {
  let summary = "Convert stack to heap allocations and vice versa.";
  let description = [{
    Convert stack allocations to heap allocations and vice versa based on
    estimated size, lifetime, usage patterns, the call tree, etc.
  }];
  let dependentDialects = [ "fir::FIROpsDialect" ];
  let options = [
    Option<"dynamicArrayOnHeap", "dynamic-array-on-heap",
           "bool", /*default=*/"false",
           "Allocate all arrays with runtime determined size on heap.">,
    Option<"maxStackArraySize", "maximum-array-alloc-size",
           "std::size_t", /*default=*/"~static_cast<std::size_t>(0)",
           "Set maximum number of elements of an array allocated on the stack.">
  ];
}

// This needs to be a "mlir::ModuleOp" pass, because it inserts global constants
def ConstantArgumentGlobalisationOpt : Pass<"constant-argument-globalisation-opt", "mlir::ModuleOp"> {
  let summary = "Convert constant function arguments to global constants.";
  let description = [{
    Convert scalar literals of function arguments to global constants.
  }];
  let dependentDialects = [ "fir::FIROpsDialect" ];
}

def StackArrays : Pass<"stack-arrays", "mlir::func::FuncOp"> {
  let summary = "Move local array allocations from heap memory into stack memory";
  let description = [{
    Convert heap allocations for arrays, even those of unknown size, into stack
    allocations.
  }];
  let dependentDialects = [
    "fir::FIROpsDialect", "mlir::DLTIDialect", "mlir::LLVM::LLVMDialect"
  ];
}

def StackReclaim : Pass<"stack-reclaim"> {
  let summary = "Insert stacksave/stackrestore in region with allocas";
  let description = [{
    Insert stacksave/stackrestore in loop region to reclaim alloca done in its
    scope.
  }];
  let dependentDialects = [ "mlir::LLVM::LLVMDialect" ];
}

def AddAliasTags : Pass<"fir-add-alias-tags", "mlir::ModuleOp"> {
  let summary = "Add tbaa tags to operations that implement FirAliasAnalysisOpInterface";
  let description = [{
    TBAA (type based alias analysis) is one method to pass pointer alias information
    from language frontends to LLVM. This pass uses fir::AliasAnalysis to add this
    information to fir.load and fir.store operations.
    Additional tags are added during codegen. See fir::TBAABuilder.
    This needs to be a separate pass so that it happens before structured control
    flow operations are lowered to branches and basic blocks (this makes tracing
    the source of values much eaiser). The other TBAA tags need to be applied to
    box loads and stores which are implicit in FIR and so cannot be annotated
    until codegen.
    TODO: this is currently a pass on mlir::ModuleOp to avoid parallelism. In
    theory, each operation could be considered in prallel, so long as there
    aren't races adding new tags to the mlir context.
  }];
  let dependentDialects = [ "fir::FIROpsDialect" ];
}

def SimplifyRegionLite : Pass<"simplify-region-lite", "mlir::ModuleOp"> {
  let summary = "Region simplification";
  let description = [{
    Run region DCE and erase unreachable blocks in regions.
  }];
}

def AlgebraicSimplification : Pass<"flang-algebraic-simplification"> {
  let summary = "";
  let description = [{
    Run algebraic simplifications for Math/Complex/etc. dialect operations.
    This is a flang specific pass, because we may want to "tune"
    the rewrite patterns specifically for Fortran (e.g. increase
    the limit for constant exponent value that defines the cases
    when pow(x, constant) is transformed into a set of multiplications, etc.).
  }];
  let dependentDialects = [ "mlir::math::MathDialect" ];
  let constructor = "::fir::createAlgebraicSimplificationPass()";
}

def PolymorphicOpConversion : Pass<"fir-polymorphic-op", "mlir::ModuleOp"> {
  let summary =
    "Simplify operations on polymorphic types";
  let description = [{
    This pass breaks up the lowering of operations on polymorphic types by 
    introducing an intermediate FIR level that simplifies code geneation. 
  }];
  let dependentDialects = [
    "fir::FIROpsDialect", "mlir::func::FuncDialect"
  ];
}

def LoopVersioning : Pass<"loop-versioning", "mlir::func::FuncOp"> {
  let summary = "Loop Versioning";
  let description = [{
    Loop Versioning pass adds a check and two variants of a loop when the input
    array is an assumed shape array, to optimize for the (often common) case where
    an array has element sized stride. The element sizes stride allows some
    loops to be vectorized as well as other loop optimizations.
  }];
  let dependentDialects = [ "fir::FIROpsDialect", "mlir::DLTIDialect" ];
}

def VScaleAttr : Pass<"vscale-attr", "mlir::func::FuncOp"> {
  let summary = "Add vscale_range attribute to functions";
  let description = [{
     Set an attribute for the vscale range on functions, to allow scalable
     vector operations to be used on processors with variable vector length.
  }];
  let options = [
    Option<"vscaleRange", "vscale-range",
           "std::pair<unsigned, unsigned>", /*default=*/"std::pair<unsigned, unsigned>{}",
           "vector scale range">,
  ];
}

def FunctionAttr : Pass<"function-attr", "mlir::func::FuncOp"> {
  let summary = "Pass that adds function attributes expected at LLVM IR level";
  let description = [{ This feature introduces a general attribute aimed at
     customizing function characteristics. 
     Options include:
     Add "frame-pointer" attribute to functions: Set an attribute for the frame 
     pointer on functions, to avoid saving the frame pointer in a register in 
     functions where it is unnecessary. This eliminates the need for
     instructions to save, establish, and restore frame pointers, while also
     freeing up an additional register in numerous functions. However, this
     approach can make debugging unfeasible on certain machines.
  }];
  let options =
      [Option<"framePointerKind", "frame-pointer",
              "mlir::LLVM::framePointerKind::FramePointerKind",
              /*default=*/"mlir::LLVM::framePointerKind::FramePointerKind{}",
              "frame pointer", [{::llvm::cl::values(
            clEnumValN(mlir::LLVM::framePointerKind::FramePointerKind::None, "None", ""),
            clEnumValN(mlir::LLVM::framePointerKind::FramePointerKind::NonLeaf, "NonLeaf", ""),
            clEnumValN(mlir::LLVM::framePointerKind::FramePointerKind::All, "All", ""),
            clEnumValN(mlir::LLVM::framePointerKind::FramePointerKind::Reserved, "Reserved", "")
          )}]>,
       Option<"instrumentFunctionEntry", "instrument-function-entry",
              "std::string", /*default=*/"",
              "Sets the name of the profiling function called during function "
              "entry">,
       Option<"instrumentFunctionExit", "instrument-function-exit",
              "std::string", /*default=*/"",
              "Sets the name of the profiling function called during function "
              "exit">,
       Option<"noInfsFPMath", "no-infs-fp-math", "bool", /*default=*/"false",
              "Set the no-infs-fp-math attribute on functions in the module.">,
       Option<"noNaNsFPMath", "no-nans-fp-math", "bool", /*default=*/"false",
              "Set the no-nans-fp-math attribute on functions in the module.">,
       Option<
           "approxFuncFPMath", "approx-func-fp-math", "bool",
           /*default=*/"false",
           "Set the approx-func-fp-math attribute on functions in the module.">,
       Option<"noSignedZerosFPMath", "no-signed-zeros-fp-math", "bool",
              /*default=*/"false",
              "Set the no-signed-zeros-fp-math attribute on functions in the "
              "module.">,
       Option<"unsafeFPMath", "unsafe-fp-math", "bool", /*default=*/"false",
              "Set the unsafe-fp-math attribute on functions in the module.">,
       Option<"reciprocals", "mrecip", "std::string", /*default=*/"",
              "Set the reciprocal-estimates attribute on functions in the "
              "module.">,
       Option<"preferVectorWidth", "prefer-vector-width", "std::string",
              /*default=*/"",
              "Set the prefer-vector-width attribute on functions in the "
              "module.">,
       Option<"tuneCPU", "tune-cpu", "std::string", /*default=*/"",
              "Set the tune-cpu attribute on functions in the module.">,
       Option<"setNoCapture", "set-nocapture", "bool", /*default=*/"false",
              "Set LLVM nocapture attribute on function arguments, "
              "if possible">,
       Option<"setNoAlias", "set-noalias", "bool", /*default=*/"false",
              "Set LLVM noalias attribute on function arguments, "
              "if possible">,
  ];
}

def AssumedRankOpConversion : Pass<"fir-assumed-rank-op", "mlir::ModuleOp"> {
  let summary =
    "Simplify operations on assumed-rank types";
  let description = [{
    This pass breaks up the lowering of operations on assumed-rank types by 
    introducing an intermediate FIR level that simplifies code generation. 
  }];
  let dependentDialects = [
    "fir::FIROpsDialect", "mlir::func::FuncDialect"
  ];
}

def CUFOpConversion : Pass<"cuf-convert", "mlir::ModuleOp"> {
  let summary = "Convert some CUF operations to runtime calls";
  let dependentDialects = [
    "fir::FIROpsDialect", "mlir::gpu::GPUDialect", "mlir::DLTIDialect"
  ];
}

def CUFDeviceGlobal :
    Pass<"cuf-device-global", "mlir::ModuleOp"> {
  let summary = "Flag globals used in device function with data attribute";
  let dependentDialects = [
    "cuf::CUFDialect", "mlir::gpu::GPUDialect", "mlir::NVVM::NVVMDialect"
  ];
}

def CUFAddConstructor : Pass<"cuf-add-constructor", "mlir::ModuleOp"> {
  let summary = "Add constructor to register CUDA Fortran allocators";
  let dependentDialects = [
    "cuf::CUFDialect", "mlir::func::FuncDialect", "mlir::DLTIDialect"
  ];
}

def CUFGPUToLLVMConversion : Pass<"cuf-gpu-convert-to-llvm", "mlir::ModuleOp"> {
  let summary = "Convert some GPU operations lowered from CUF to runtime calls";
  let dependentDialects = [
    "mlir::LLVM::LLVMDialect", "mlir::DLTIDialect"
  ];
}

def CUFComputeSharedMemoryOffsetsAndSize
    : Pass<"cuf-compute-shared-memory", "mlir::ModuleOp"> {
  let summary = "Create the shared memory global variable and set offsets";

  let description = [{
    Compute the size and alignment of the shared memory global and materialize
    it. Compute the offset of each cuf.shared_memory operation according to
    the global and set it.
  }];

  let dependentDialects = [
    "cuf::CUFDialect", "fir::FIROpsDialect", "mlir::gpu::GPUDialect",
    "mlir::DLTIDialect"
  ];
}

def SetRuntimeCallAttributes
    : Pass<"set-runtime-call-attrs", "mlir::func::FuncOp"> {
  let summary = "Set Fortran runtime fir.call attributes targeting LLVM IR";
  let description = [{
    This pass sets different attributes for Fortran runtime calls
    that enable more optimizations in LLVM backend.
    For the time being, the meaning of these attributes is not
    strictly defined for HLFIR/FIR.
  }];
  let dependentDialects = ["fir::FIROpsDialect", "mlir::LLVM::LLVMDialect"];
}

def GenRuntimeCallsForTest
    : Pass<"gen-runtime-calls-for-test", "mlir::ModuleOp"> {
  let summary =
      "Print FIR containing declarations/calls of Fortran runtime functions";
  let description = [{
    This pass is only for developers to be able to print FIR
    that declares and calls Fortran runtime functions.
    It helps producing/updating tests for passes that modify
    the func/call operations based on some knowledge of
    Fortran runtime.
  }];
  let options =
      [Option<"doGenerateCalls", "do-generate-calls", "bool",
              /*default=*/"false",
              "Generate thin wrapper functions that call Fortran runtime "
              "functions. If it is set to false, then only the declarations "
              "are generated.">,
  ];
  let dependentDialects = ["fir::FIROpsDialect", "mlir::func::FuncDialect"];
}

def SimplifyFIROperations : Pass<"simplify-fir-operations", "mlir::ModuleOp"> {
  let summary = "Simplifies complex FIR operations";
  let description = [{
    Expands complex FIR operations into their equivalent using
    FIR, SCF and other usual dialects. It may also generate calls
    to Fortran runtime.
  }];

  let options = [Option<
      "preferInlineImplementation", "prefer-inline-implementation", "bool",
      /*default=*/"false",
      "Prefer expanding without using Fortran runtime calls.">];
}

def OptimizeArrayRepacking
    : Pass<"optimize-array-repacking", "mlir::func::FuncOp"> {
  let summary = "Optimizes redundant array repacking operations";
  let description = [{
    If the source of fir.pack_array is known to be contiguous,
    then this pass erases such operations. The corresponding
    fir.unpack_array operations are also removed.
  }];
}

#endif // FLANG_OPTIMIZER_TRANSFORMS_PASSES
