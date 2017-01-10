import cllvm

/// `StructType` is used to represent a collection of data members together in
/// memory. The elements of a structure may be any type that has a size.
///
/// Structures in memory are accessed using `load` and `store` by getting a
/// pointer to a field with the ‘getelementptr‘ instruction. Structures in
/// registers are accessed using the `extractvalue` and `insertvalue`
/// instructions.
///
/// Structures may optionally be "packed" structures, which indicate that the
/// alignment of the struct is one byte, and that there is no padding between
/// the elements. In non-packed structs, padding between field types is inserted
/// as defined by the `DataLayout` of the module, which is required to match
/// what the underlying code generator expects.
///
/// Structures can either be "literal" or "identified". A literal structure is
/// defined inline with other types (e.g. {i32, i32}*) whereas identified types
/// are always defined at the top level with a name. Literal types are uniqued
/// by their contents and can never be recursive or opaque since there is no way
/// to write one. Identified types can be recursive, can be opaqued, and are
/// never uniqued.
public struct StructType: IRType {
  internal let llvm: LLVMTypeRef

  /// Initializes a structure type from the given LLVM type object.
  public init(llvm: LLVMTypeRef) {
    self.llvm = llvm
  }

  /// Invalidates and resets the member types of this structure.
  ///
  /// - parameter types: A list of types of members of this structure.
  /// - parameter isPacked: Whether or not this structure is 1-byte aligned with
  /// - no packing between fields.  Defaults to `false`.
  public func setBody(_ types: [IRType], isPacked: Bool = false) {
    var _types = types.map { $0.asLLVM() as Optional }
    _types.withUnsafeMutableBufferPointer { buf in
      LLVMStructSetBody(asLLVM(), buf.baseAddress, UInt32(buf.count), isPacked.llvm)
    }
  }

  /// Creates a constant value of this structure type initialized with the given
  /// list of values.
  ///
  /// - parameter values: A list of values of members of this structure.
  /// - parameter isPacked: Whether or not this structure is 1-byte aligned with
  /// - no packing between fields.  Defaults to `false`.
  ///
  /// - returns: A value representing a constant value of this structure type.
  public static func constant(values: [IRValue], isPacked: Bool = false) -> IRValue {
    var vals = values.map { $0.asLLVM() as Optional }
    return vals.withUnsafeMutableBufferPointer { buf in
      return LLVMConstStruct(buf.baseAddress, UInt32(buf.count), isPacked.llvm)
    }
  }

  /// Retrieves the underlying LLVM type object.
  public func asLLVM() -> LLVMTypeRef {
    return llvm
  }
}
