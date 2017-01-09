import cllvm

/// Species the behavior that should occur on overflow during mathematical
/// operations.
public enum OverflowBehavior {
  /// The result value of the operator is the mathematical result modulo `2^n`,
  /// where `n` is the bit width of the result.
  case `default`
  /// The result value of the operator is a poison value if signed overflow 
  /// occurs.
  case noSignedWrap
  /// The result value of the operator is a poison value if unsigned overflow
  /// occurs.
  case noUnsignedWrap
}

/// The condition codes available for integer comparison instructions.
public enum IntPredicate {
  /// Yields `true` if the operands are equal, false otherwise without sign
  /// interpretation.
  case eq
  /// Yields `true` if the operands are unequal, false otherwise without sign
  /// interpretation.
  case ne

  /// Interprets the operands as unsigned values and yields true if the first is
  /// greater than the second.
  case ugt
  /// Interprets the operands as unsigned values and yields true if the first is
  /// greater than or equal to the second.
  case uge
  /// Interprets the operands as unsigned values and yields true if the first is
  /// less than the second.
  case ult
  /// Interprets the operands as unsigned values and yields true if the first is
  /// less than or equal to the second.
  case ule

  /// Interprets the operands as signed values and yields true if the first is 
  /// greater than the second.
  case sgt
  /// Interprets the operands as signed values and yields true if the first is
  /// greater than or equal to the second.
  case sge
  /// Interprets the operands as signed values and yields true if the first is
  /// less than the second.
  case slt
  /// Interprets the operands as signed values and yields true if the first is
  /// less than or equal to the second.
  case sle

  static let predicateMapping: [IntPredicate: LLVMIntPredicate] = [
    .eq: LLVMIntEQ, .ne: LLVMIntNE, .ugt: LLVMIntUGT, .uge: LLVMIntUGE,
    .ult: LLVMIntULT, .ule: LLVMIntULE, .sgt: LLVMIntSGT, .sge: LLVMIntSGE,
    .slt: LLVMIntSLT, .sle: LLVMIntSLE
  ]
  public var llvm: LLVMIntPredicate {
    return IntPredicate.predicateMapping[self]!
  }
}

/// The condition codes available for floating comparison instructions.
public enum RealPredicate {
  /// No comparison, always returns `false`.
  case `false`
  /// Ordered and equal.
  case oeq
  /// Ordered greater than.
  case ogt
  /// Ordered greater than or equal.
  case oge
  /// Ordered less than.
  case olt
  /// Ordered less than or equal.
  case ole
  /// Ordered and not equal.
  case one
  /// Oredered (no nans).
  case ord
  /// Unordered (either nans).
  case uno
  /// Unordered or equal.
  case ueq
  /// Unordered or greater than.
  case ugt
  /// Unordered or greater than or equal.
  case uge
  /// Unordered or less than.
  case ult
  /// Unordered or less than or equal.
  case ule
  /// Unordered or not equal.
  case une
  /// No comparison, always returns `true`.
  case `true`

  static let predicateMapping: [RealPredicate: LLVMRealPredicate] = [
    .false: LLVMRealPredicateFalse, .oeq: LLVMRealOEQ, .ogt: LLVMRealOGT,
    .oge: LLVMRealOGE, .olt: LLVMRealOLT, .ole: LLVMRealOLE,
    .one: LLVMRealONE, .ord: LLVMRealORD, .uno: LLVMRealUNO,
    .ueq: LLVMRealUEQ, .ugt: LLVMRealUGT, .uge: LLVMRealUGE,
    .ult: LLVMRealULT, .ule: LLVMRealULE, .une: LLVMRealUNE,
    .true: LLVMRealPredicateTrue,
  ]

  public var llvm: LLVMRealPredicate {
    return RealPredicate.predicateMapping[self]!
  }
}

/// An `IRBuilder` is a helper object that generates LLVM instructions.  IR 
/// Builders keep track of a position within a function or basic block and has
/// methods to insert instructions at that position.
public class IRBuilder {
  internal let llvm: LLVMBuilderRef

  /// The module this `IRBuilder` is associated with.
  public let module: Module

  /// Creates an `IRBuilder` object with the given module.
  ///
  /// - parameter module: The module into which instructions will be inserted.
  public init(module: Module) {
    self.module = module
    self.llvm = LLVMCreateBuilderInContext(module.context.llvm)
  }

  // MARK: IR Navigation

  /// Repositions the IR Builder at the end of the given basic block.
  ///
  /// - parameter block: The basic block to reposition the IR Builder after.
  public func positionAtEnd(of block: BasicBlock) {
    LLVMPositionBuilderAtEnd(llvm, block.llvm)
  }

  /// Repositions the IR Builder before the start of the given instruction.
  ///
  /// - parameter inst: The instruction to reposition the IR Builder before.
  public func positionBefore(_ inst: IRValue) {
    LLVMPositionBuilderBefore(llvm, inst.asLLVM())
  }

  /// Repositions the IR Builder at the point specified by the given instruction
  /// in the given basic block.
  ///
  /// This is equivalent to calling `positionAtEnd(of:)` with the given basic
  /// block then calling `positionBefore(_:)` with the given instruction.
  ///
  /// - parameter inst: The instruction to reposition the IR Builder before.
  /// - parameter block: The basic block to reposition the IR builder in.
  public func position(_ inst: IRValue, block: BasicBlock) {
    LLVMPositionBuilder(llvm, block.llvm, inst.asLLVM())
  }

  /// Clears the insertion point.
  ///
  /// Subsequent instructions will not be inserted into a block.
  public func clearInsertionPosition() {
    LLVMClearInsertionPosition(llvm)
  }

  // MARK: Instruction Insertion

  /// Gets the basic block built instructions will be inserted into.
  public var insertBlock: BasicBlock? {
    guard let blockRef = LLVMGetInsertBlock(llvm) else { return nil }
    return BasicBlock(llvm: blockRef)
  }

  /// Inserts the given instruction into the IR Builder.
  ///
  /// - parameter inst: The instruction to insert.
  /// - parameter name: The name for the newly inserted instruction.
  public func insert(_ inst: IRValue, name: String? = nil) {
    if let name = name {
      LLVMInsertIntoBuilderWithName(llvm, inst.asLLVM(), name)
    } else {
      LLVMInsertIntoBuilder(llvm, inst.asLLVM())
    }
  }

  // MARK: Arithmetic Instructions

  /// Builds a negation instruction with the given value as an operand.
  ///
  /// Whether an integer or floating point negate instruction is built is
  /// determined by the type of the given value.  Providing an operand that is
  /// neither an integer nor a floating value is a fatal condition.
  ///
  /// - parameter value: The value to negate.
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the program.
  /// - name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the negation of the given value.
  public func buildNeg(_ value: IRValue,
                       overflowBehavior: OverflowBehavior = .default,
                       name: String = "") -> IRValue {
    let val = value.asLLVM()
    if value.type is IntType {
      switch overflowBehavior {
      case .noSignedWrap:
        return LLVMBuildNSWNeg(llvm, val, name)
      case .noUnsignedWrap:
        return LLVMBuildNUWNeg(llvm, val, name)
      case .default:
        return LLVMBuildNeg(llvm, val, name)
      }
    } else if value.type is FloatType {
      return LLVMBuildFNeg(llvm, val, name)
    }
    fatalError("Can only negate value of int or float types")
  }

  /// Builds an add instruction with the given values as operands.
  ///
  /// Whether an integer or floating point add instruction is built is 
  /// determined by the type of the first given value.  Providing operands that
  /// are neither integers nor floating values is a fatal condition.
  ///
  /// - parameter lhs: The first summand value (the augend).
  /// - parameter rhs: The second summand value (the addend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the 
  ///   behavior of the program.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the sum of the two operands.
  public func buildAdd(_ lhs: IRValue, _ rhs: IRValue,
                overflowBehavior: OverflowBehavior = .default,
                name: String = "") -> IRValue {
    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    if lhs.type is IntType {
      switch overflowBehavior {
      case .noSignedWrap:
        return LLVMBuildNSWAdd(llvm, lhsVal, rhsVal, name)
      case .noUnsignedWrap:
        return LLVMBuildNUWAdd(llvm, lhsVal, rhsVal, name)
      case .default:
        return LLVMBuildAdd(llvm, lhsVal, rhsVal, name)
      }
    } else if lhs.type is FloatType {
      return LLVMBuildFAdd(llvm, lhsVal, rhsVal, name)
    }
    fatalError("Can only add value of int, float, or vector types")
  }

  /// Builds a subtract instruction with the given values as operands.
  ///
  /// Whether an integer or floating point subtract instruction is built is
  /// determined by the type of the first given value.  Providing operands that
  /// are neither integers nor floating values is a fatal condition.
  ///
  /// - parameter lhs: The first value (the minuend).
  /// - parameter rhs: The second value (the subtrahend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the program.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the difference of the two operands.
  public func buildSub(_ lhs: IRValue, _ rhs: IRValue,
                overflowBehavior: OverflowBehavior = .default,
                name: String = "") -> IRValue {
    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    if lhs.type is IntType {
      switch overflowBehavior {
      case .noSignedWrap:
        return LLVMBuildNSWSub(llvm, lhsVal, rhsVal, name)
      case .noUnsignedWrap:
        return LLVMBuildNSWSub(llvm, lhsVal, rhsVal, name)
      case .default:
        return LLVMBuildSub(llvm, lhsVal, rhsVal, name)
      }
    } else if lhs.type is FloatType {
      return LLVMBuildFSub(llvm, lhsVal, rhsVal, name)
    }
    fatalError("Can only subtract value of int or float types")
  }

  /// Builds a multiply instruction with the given values as operands.
  ///
  /// Whether an integer or floating point multiply instruction is built is
  /// determined by the type of the first given value.  Providing operands that
  /// are neither integers nor floating values is a fatal condition.
  ///
  /// - parameter lhs: The first factor value (the multiplier).
  /// - parameter rhs: The second factor value (the multiplicand).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the program.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the product of the two operands.
  public func buildMul(_ lhs: IRValue, _ rhs: IRValue,
                overflowBehavior: OverflowBehavior = .default,
                name: String = "") -> IRValue {
    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    if lhs.type is IntType {
      switch overflowBehavior {
      case .noSignedWrap:
        return LLVMBuildNSWMul(llvm, lhsVal, rhsVal, name)
      case .noUnsignedWrap:
        return LLVMBuildNUWMul(llvm, lhsVal, rhsVal, name)
      case .default:
        return LLVMBuildMul(llvm, lhsVal, rhsVal, name)
      }
    } else if lhs.type is FloatType {
      return LLVMBuildFMul(llvm, lhsVal, rhsVal, name)
    }
    fatalError("Can only multiply value of int or float types")
  }

  /// Build a remainder instruction that provides the remainder after divison of
  /// the first value by the second value.
  ///
  /// Whether an integer or floating point remainder instruction is built is
  /// determined by the type of the first given value.  Providing operands that
  /// are neither integers nor floating values is a fatal condition.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  /// - parameter signed: Whether to emit a signed or unsigned remainder
  ///   instruction.  Defaults to emission of a signed remainder instruction.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the remainder of division of the first
  ///   operand by the second operand.
  public func buildRem(_ lhs: IRValue, _ rhs: IRValue,
                signed: Bool = true,
                name: String = "") -> IRValue {
    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    if lhs.type is IntType {
      if signed {
        return LLVMBuildSRem(llvm, lhsVal, rhsVal, name)
      } else {
        return LLVMBuildURem(llvm, lhsVal, rhsVal, name)
      }
    } else if lhs.type is FloatType {
      return LLVMBuildFRem(llvm, lhsVal, rhsVal, name)
    }
    fatalError("Can only take remainder of int or float types")
  }

  /// Build a division instruction that divides the first value by the second
  /// value.
  ///
  /// Whether an integer or floating point divide instruction is built is
  /// determined by the type of the first given value.  Providing operands that
  /// are neither integers nor floating values is a fatal condition.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  /// - parameter signed: Whether to emit a signed or unsigned remainder
  ///   instruction.  Defaults to emission of a signed divide instruction.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the quotient of the first and second 
  ///   operands.
  public func buildDiv(_ lhs: IRValue, _ rhs: IRValue,
                signed: Bool = true, name: String = "") -> IRValue {
    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    if lhs.type is IntType {
      if signed {
        return LLVMBuildSDiv(llvm, lhsVal, rhsVal, name)
      } else {
        return LLVMBuildUDiv(llvm, lhsVal, rhsVal, name)
      }
    } else if lhs.type is FloatType {
      return LLVMBuildFDiv(llvm, lhsVal, rhsVal, name)
    }
    fatalError("Can only divide values of int or float types")
  }

  /// Build an integer comparison between the two provided values using the
  /// given predicate.
  ///
  /// Attempting to compare operands that are not integers is a fatal condition.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter lhs: The second value to compare.
  /// - parameter predicate: The method of comparison to use.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of the comparision of the given
  ///   operands.
  public func buildICmp(_ lhs: IRValue, _ rhs: IRValue,
                 _ predicate: IntPredicate,
                 name: String = "") -> IRValue {
    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    guard lhs.type is IntType else {
      fatalError("Can only build ICMP instruction with int types")
    }
    return LLVMBuildICmp(llvm, predicate.llvm, lhsVal, rhsVal, name)
  }

  /// Build a floating comparison between the two provided values using the
  /// given predicate.
  ///
  /// Attempting to compare operands that are not floating is a fatal condition.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter lhs: The second value to compare.
  /// - parameter predicate: The method of comparison to use.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of the comparision of the given
  ///   operands.
  public func buildFCmp(_ lhs: IRValue, _ rhs: IRValue,
                 _ predicate: RealPredicate,
                 name: String = "") -> IRValue {
    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    guard lhs.type is FloatType else {
      fatalError("Can only build FCMP instruction with float types")
    }
    return LLVMBuildFCmp(llvm, predicate.llvm, lhsVal, rhsVal, name)
  }

  // MARK: Logical Instructions

  /// Builds a bitwise logical not with the given value as an operand.
  ///
  /// - parameter val: The value to negate.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the logical negation of the given operand.
  public func buildNot(_ val: IRValue, name: String = "") -> IRValue {
    return LLVMBuildNot(llvm, val.asLLVM(), name)
  }

  /// Builds a bitwise logical exclusive OR with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the exclusive OR of the values of the
  ///   two given operands.
  public func buildXor(_ lhs: IRValue, _ rhs: IRValue, name: String = "") -> IRValue {
    return LLVMBuildXor(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
  }

  /// Builds a bitwise logical OR with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the logical OR of the values of the
  ///   two given operands.
  public func buildOr(_ lhs: IRValue, _ rhs: IRValue, name: String = "") -> IRValue {
    return LLVMBuildOr(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
  }

  /// Builds a bitwise logical AND with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the logical AND of the values of the
  ///   two given operands.
  public func buildAnd(_ lhs: IRValue, _ rhs: IRValue, name: String = "") -> IRValue {
    return LLVMBuildAnd(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
  }

  /// Builds a left-shift instruction of the first value by an amount in the
  /// second value.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The number of bits to shift the first operand left by.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the value of the first operand shifted
  ///   left by the number of bits specified in the second operand.
  public func buildShl(_ lhs: IRValue, _ rhs: IRValue,
                       name: String = "") -> IRValue {
    return LLVMBuildShl(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
  }

  /// Builds a right-shift instruction of the first value by an amount in the
  /// second value.  If `isArithmetic` is true the value of the first operand is
  /// bitshifted with sign extension.  Else the value is bitshifted with 
  /// zero-fill.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The number of bits to shift the first operand right by.
  /// - parameter isArithmetic: Whether this instruction performs an arithmetic
  ///   or logical right-shift.  The default is a logical right-shift.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the value of the first operand shifted
  ///   right by the numeber of bits specified in the second operand.
  public func buildShr(_ lhs: IRValue, _ rhs: IRValue,
                       isArithmetic: Bool = false,
                       name: String = "") -> IRValue {
    if isArithmetic {
      return LLVMBuildAShr(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
    } else {
      return LLVMBuildLShr(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
    }
  }

  // MARK: Declaration Instructions

  /// Build a phi node with the given type acting as the result of any incoming
  /// basic blocks.
  ///
  /// - parameter type: The type of incoming values.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the newly inserted phi node.
  public func buildPhi(_ type: IRType, name: String = "") -> PhiNode {
    let value = LLVMBuildPhi(llvm, type.asLLVM(), name)!
    return PhiNode(llvm: value)
  }

  /// Build a named function body with the given type.
  ///
  /// - parameter name: The name of the newly defined function.
  /// - parameter type: The type of the newly defined function.
  /// 
  /// - returns: A value representing the newly inserted function definition.
  public func addFunction(_ name: String, type: FunctionType) -> Function {
    return Function(llvm: LLVMAddFunction(module.llvm, name, type.asLLVM()))
  }

  /// Build a branch table that branches on the given value with the given
  /// default basic block.
  ///
  /// The ‘switch‘ instruction is used to transfer control flow to one of 
  /// several different places. It is a generalization of the ‘br‘ instruction, 
  /// allowing a branch to occur to one of many possible destinations.
  ///
  /// - parameter value: The value to compare.
  /// - parameter else: The default destination for control flow should the 
  ///   value not match a case in the branch table.
  /// - parameter caseCount: The number of cases in the branch table.
  ///
  /// - returns: A value representing the newly inserted `switch` instruction.
  public func buildSwitch(_ value: IRValue, else: BasicBlock, caseCount: Int) -> Switch {
    return Switch(llvm: LLVMBuildSwitch(llvm,
                                        value.asLLVM(),
                                        `else`.asLLVM(),
                                        UInt32(caseCount))!)
  }

  /// Build a named structure definition.
  ///
  /// - parameter name: The name of the structure.
  /// - parameter types: The type of fields that make up the structure's body.
  /// - parameter isPacked: Whether this structure should be 1-byte aligned with
  ///   no padding between elements.
  ///
  /// - returns: A value representing the newly declared named structure.
  public func createStruct(name: String, types: [IRType]? = nil, isPacked: Bool = false) -> StructType {
    let named = LLVMStructCreateNamed(module.context.llvm, name)!
    let type = StructType(llvm: named)
    if let types = types {
      type.setBody(types)
    }
    return type
  }

  // MARK: Terminator Instructions

  /// Build an unconditional branch to the given basic block.
  ///
  /// - parameter block: The target block to transfer control flow to.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildBr(_ block: BasicBlock) -> IRValue {
    return LLVMBuildBr(llvm, block.llvm)
  }

  /// Build a condition branch that branches to the first basic block if the 
  /// provided condition is `true`, otherwise to the second basic block.
  ///
  /// - parameter condition: A value of type `i1` that determines which basic
  ///   block to transfer control flow to.
  /// - parameter then: The basic block to transfer control flow to if the 
  ///   condition evaluates to `true`.
  /// - parameter else: The basic block to transfer control flow to if the
  ///   condition evaluates to `false`.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildCondBr(condition: IRValue, then: BasicBlock, `else`: BasicBlock) -> IRValue {
    return LLVMBuildCondBr(llvm, condition.asLLVM(), then.asLLVM(), `else`.asLLVM())
  }

  /// Builds a return from the current function back to the calling function
  /// with the given value.
  ///
  /// - parameter val: The value to return from the current function.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildRet(_ val: IRValue) -> IRValue {
    return LLVMBuildRet(llvm, val.asLLVM())
  }

  /// Builds a void return from the current function.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildRetVoid() -> IRValue {
    return LLVMBuildRetVoid(llvm)
  }

  /// Builds an unreachable instruction in the current function.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildUnreachable() -> IRValue {
    return LLVMBuildUnreachable(llvm)
  }

  /// Build a call to the given function with the given arguments to transfer
  /// control to that function.
  ///
  /// - parameter fn: The function to invoke.
  /// - parameter args: A list of arguments.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildCall(_ fn: IRValue, args: [IRValue], name: String = "") -> IRValue {
    var args = args.map { $0.asLLVM() as Optional }
    return args.withUnsafeMutableBufferPointer { buf in
      return LLVMBuildCall(llvm, fn.asLLVM(), buf.baseAddress!, UInt32(buf.count), name)
    }
  }

  // MARK: Memory Access Instructions

  /// Build an `alloca` to allocate stack memory to hold a value of the given
  /// type.
  ///
  /// - parameter type: The sized type used to determine the amount of stack
  ///   memory to allocate.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing `void`.
  public func buildAlloca(type: IRType, name: String = "") -> IRValue {
    return LLVMBuildAlloca(llvm, type.asLLVM(), name)
  }

  /// Build a store instruction that stores the first value into the location
  /// given in the second value.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildStore(_ val: IRValue, to ptr: IRValue) -> IRValue {
    return LLVMBuildStore(llvm, val.asLLVM(), ptr.asLLVM())
  }

  /// Builds a load instruction that loads a value from the location in the
  /// given value.
  ///
  /// - parameter ptr: The pointer value to load from.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of a load from the given
  ///   pointer value.
  public func buildLoad(_ ptr: IRValue, name: String = "") -> IRValue {
    return LLVMBuildLoad(llvm, ptr.asLLVM(), name)
  }

  /// Builds a `GEP` (Get Element Pointer) instruction with a resultant value 
  /// that is undefined if the address is outside the actual underlying 
  /// allocated object and not the address one-past-the-end.
  ///
  /// The `GEP` instruction is often the source of confusion.  LLVM [provides a
  /// document](http://llvm.org/docs/GetElementPtr.html) to answer questions
  /// around its semantics and correct usage.
  ///
  /// - parameter ptr: The base address for the index calculation.
  /// - parameter indices: A list of indices that indicate which of the elements
  ///   of the aggregate object are indexed.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   aggregate data structure value.
  public func buildInBoundsGEP(_ ptr: IRValue, indices: [IRValue], name: String = "") -> IRValue {
    var vals = indices.map { $0.asLLVM() as Optional }
    return vals.withUnsafeMutableBufferPointer { buf in
      return LLVMBuildInBoundsGEP(llvm, ptr.asLLVM(), buf.baseAddress, UInt32(buf.count), name)
    }
  }

  /// Builds a GEP (Get Element Pointer) instruction.
  ///
  /// The `GEP` instruction is often the source of confusion.  LLVM [provides a
  /// document](http://llvm.org/docs/GetElementPtr.html) to answer questions
  /// around its semantics and correct usage.
  ///
  /// - parameter ptr: The base address for the index calculation.
  /// - parameter indices: A list of indices that indicate which of the elements
  ///   of the aggregate object are indexed.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   aggregate data structure value.
  public func buildGEP(_ ptr: IRValue, indices: [IRValue], name: String = "") -> IRValue {
    var vals = indices.map { $0.asLLVM() as Optional }
    return vals.withUnsafeMutableBufferPointer { buf in
      return LLVMBuildGEP(llvm, ptr.asLLVM(), buf.baseAddress, UInt32(buf.count), name)
    }
  }

  /// Builds a GEP (Get Element Pointer) instruction suitable for indexing into
  /// a struct.
  ///
  /// - parameter ptr: The base address for the index calculation.
  /// - parameter index: The offset from the base for the index calculation.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   struct value.
  public func buildStructGEP(_ ptr: IRValue, index: Int, name: String = "") -> IRValue {
      return LLVMBuildStructGEP(llvm, ptr.asLLVM(), UInt32(index), name)
  }

  // MARK: Null Test Instructions

  /// Builds a comparision instruction that returns whether the given operand is
  /// `null`.
  ///
  /// - parameter val: The value to test.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: An `i1`` value representing the result of a test to see if the
  ///   value is `null`.
  public func buildIsNull(_ val: IRValue, name: String = "") -> IRValue {
    return LLVMBuildIsNull(llvm, val.asLLVM(), name)
  }

  /// Builds a comparision instruction that returns whether the given operand is
  /// not `null`.
  ///
  /// - parameter val: The value to test.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: An `i1`` value representing the result of a test to see if the
  ///   value is not `null`.
  public func buildIsNotNull(_ val: IRValue, name: String = "") -> IRValue {
    return LLVMBuildIsNotNull(llvm, val.asLLVM(), name)
  }

  // MARK: Conversion Instructions

  /// Builds an instruction that either performs a truncation or a bitcast of
  /// the given value to a value of the given type.
  ///
  /// - parameter val: The value to cast or truncate.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of truncating or bitcasting the
  ///   given value to fit the given type.
  public func buildTruncOrBitCast(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildTruncOrBitCast(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Builds a bitcast instruction to convert the given value to a value of the 
  /// given type by just copying the bit pattern.
  ///
  /// - parameter val: The value to bitcast.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of bitcasting the given value 
  ///   to fit the given type.
  public func buildBitCast(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildBitCast(llvm, val.asLLVM(), type.asLLVM(), name)
  }
  /// Builds a truncate instruction to truncate the given value to the given
  /// type with a shorter width.
  ///
  /// - parameter val: The value to truncate.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of truncating the given value
  ///   to fit the given type.
  public func buildTrunc(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildTrunc(llvm, val.asLLVM(), type.asLLVM(), name)
  }


  /// Builds a sign extension instruction to sign extend the given value to
  /// the given type with a wider width.
  ///
  /// - parameter val: The value to sign extend.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of sign extending the given 
  ///   value to fit the given type.
  public func buildSExt(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildSExt(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Builds a zero extension instruction to zero extend the given value to the
  /// given type with a wider width.
  ///
  /// - parameter val: The value to zero extend.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of zero extending the given
  ///   value to fit the given type.
  public func buildZExt(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildZExt(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Builds an integer-to-pointer instruction to convert the given value to the
  /// given pointer type.
  ///
  /// - parameter val: The integer value.
  /// - parameter type: The destination pointer type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A pointer value representing the value of the given integer
  ///   converted to the given pointer type.
  public func buildIntToPtr(_ val: IRValue, type: PointerType, name: String = "") -> IRValue {
    return LLVMBuildIntToPtr(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Builds a pointer-to-integer instruction to convert the given pointer value
  /// to the given integer type.
  ///
  /// - parameter val: The pointer value.
  /// - parameter type: The destination integer type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: An integer value representing the value of the given pointer
  ///   converted to the given integer type.
  public func buildPtrToInt(_ val: IRValue, type: IntType, name: String = "") -> IRValue {
    return LLVMBuildIntToPtr(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Builds an integer-to-floating instruction to convert the given integer 
  /// value to the given floating type.
  ///
  /// - parameter val: The integer value.
  /// - parameter type: The destination integer type.
  /// - parameter signed: Whether the destination is a signed or unsigned integer.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A floating value representing the value of the given integer
  ///   converted to the given floating type.
  public func buildIntToFP(_ val: IRValue, type: FloatType, signed: Bool, name: String = "") -> IRValue {
    if signed {
      return LLVMBuildSIToFP(llvm, val.asLLVM(), type.asLLVM(), name)
    } else {
      return LLVMBuildUIToFP(llvm, val.asLLVM(), type.asLLVM(), name)
    }
  }

  /// Builds a floating-to-integer instruction to convert the given floating
  /// value to the given integer type.
  ///
  /// - parameter val: The floating value.
  /// - parameter type: The destination integer type.
  /// - parameter signed: Whether the destination is a signed or unsigned integer.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: An integer value representing the value of the given float
  ///   converted to the given integer type.
  public func buildFPToInt(_ val: IRValue, type: IntType, signed: Bool, name: String = "") -> IRValue {
    if signed {
      return LLVMBuildFPToSI(llvm, val.asLLVM(), type.asLLVM(), name)
    } else {
      return LLVMBuildFPToUI(llvm, val.asLLVM(), type.asLLVM(), name)
    }
  }

  /// Builds a constant expression that returns the alignment of the given type 
  /// in bytes.
  ///
  /// - parameter val: The type to evaluate the alignment of.
  ///
  /// - returns: An integer value representing the alignment of the given type
  ///   in bytes.
  public func buildAlignOf(_ val: IRType) -> IRValue {
    return LLVMAlignOf(val.asLLVM())
  }

  /// Builds a constant expression that returns the size of the given type in
  /// bytes.
  ///
  /// - parameter val: The type to evaluate the size of.
  ///
  /// - returns: An integer value representing the size of the given type in
  ///   bytes.
  public func buildSizeOf(_ val: IRType) -> IRValue {
    return LLVMSizeOf(val.asLLVM())
  }

  // MARK: Vector Instructions

  /// Builds an instruction to insert a value into a member field in an 
  /// aggregate value.
  ///
  /// - parameter aggregate: A value of array or structure type.
  /// - parameter element: The value to insert.
  /// - parameter index: The index at which at which to insert the value.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing an aggregate that has been updated with
  ///   the given value at the given index.
  public func buildInsertValue(aggregate: IRValue, element: IRValue, index: Int, name: String = "") -> IRValue {
    return LLVMBuildInsertValue(llvm, aggregate.asLLVM(), element.asLLVM(), UInt32(index), name)
  }

  /// Builds a vector insert instruction to nondestructively insert the given 
  /// value into the given vector.
  ///
  /// - parameter vector: A value of vector type.
  /// - parameter element: The value to insert.
  /// - parameter index: The index at which at which to insert the value.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing a vector that has been updated with
  ///   the given value at the given index.
  public func buildInsertElement(vector: IRValue, element: IRValue, index: IRValue, name: String = "") -> IRValue {
    return LLVMBuildInsertElement(llvm, vector.asLLVM(), element.asLLVM(), index.asLLVM(), name)
  }

  // MARK: Global Variable Creation Instructions

  /// Build a named global of the given type.
  ///
  /// - parameter name: The name of the newly inserted global value.
  /// - parameter type: The type of the newly inserted global value.
  ///
  /// - returns: A value representing the newly inserted global variable.
  public func addGlobal(_ name: String, type: IRType) -> Global {
    return Global(llvm: LLVMAddGlobal(module.llvm, type.asLLVM(), name))
  }

  /// Build a named global string consisting of an array of `i8` type filled in 
  /// with the nul terminated string value.
  ///
  /// - parameter name: The name of the newly inserted global string value.
  /// - parameter value: The character contents of the newly inserted global.
  ///
  /// - returns: A value representing the newly inserted global string variable.
  public func addGlobalString(name: String, value: String) -> Global {
    let length = value.utf8.count

    var global = addGlobal(name, type:
      ArrayType(elementType: IntType.int8, count: length + 1))

    global.alignment = 1
    global.initializer = value

    return global
  }

  /// Builds a named global variable containing the characters of the given 
  /// string value as an array of `i8` type filled in with the nul terminated 
  /// string value.
  ///
  /// - parameter string: The character contents of the newly inserted global.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the newly inserted global string variable.
  public func buildGlobalString(_ string: String, name: String = "") -> IRValue {
    return LLVMBuildGlobalString(llvm, string, name)
  }

  /// Builds a named global variable containing a pointer to the contents of the
  /// given string value.
  ///
  /// - parameter string: The character contents of the newly inserted global.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing a pointer to the newly inserted global 
  ///   string variable.
  public func buildGlobalStringPtr(_ string: String, name: String = "") -> IRValue {
    return LLVMBuildGlobalStringPtr(llvm, string, name)
  }
  
  deinit {
    LLVMDisposeBuilder(llvm)
  }
}
