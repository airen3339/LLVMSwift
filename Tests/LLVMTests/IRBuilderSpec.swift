import LLVM
import XCTest
import Foundation

class IRBuilderSpec : XCTestCase {
  func testIRBuilder() {
    XCTAssert(fileCheckOutput(of: .stderr, withPrefixes: ["IRBUILDER"]) {
      // IRBUILDER: ; ModuleID = 'IRBuilderTest'
      // IRBUILDER-NEXT: source_filename = "IRBuilderTest"
      let module = Module(name: "IRBuilderTest")
      let builder = IRBuilder(module: module)
      // IRBUILDER: define void @main() {
      let main = builder.addFunction("main",
                                     type: FunctionType(argTypes: [],
                                                        returnType: VoidType()))
      // IRBUILDER-NEXT: entry:
      let entry = main.appendBasicBlock(named: "entry")
      builder.positionAtEnd(of: entry)
      // IRBUILDER-NEXT: ret void
      builder.buildRetVoid()
      // IRBUILDER-NEXT: }
      module.dump()
    })

    // MARK: Arithmetic Instructions

    XCTAssert(fileCheckOutput(of: .stderr, withPrefixes: ["IRBUILDERARITH"]) {
      // IRBUILDERARITH: ; ModuleID = 'IRBuilderTest'
      // IRBUILDERARITH-NEXT: source_filename = "IRBuilderTest"
      let module = Module(name: "IRBuilderTest")
      let builder = IRBuilder(module: module)

      // IRBUILDERARITH: @a = global i32 1
      // IRBUILDERARITH-NEXT: @b = global i32 1
      var g1 = builder.addGlobal("a", type: IntType.int32)
      g1.initializer = Int32(1)
      var g2 = builder.addGlobal("b", type: IntType.int32)
      g2.initializer = Int32(1)

      // IRBUILDERARITH: define void @main() {
      let main = builder.addFunction("main",
                                     type: FunctionType(argTypes: [],
                                                        returnType: VoidType()))
      // IRBUILDERARITH-NEXT: entry:
      let entry = main.appendBasicBlock(named: "entry")
      builder.positionAtEnd(of: entry)

      // IRBUILDERARITH-NEXT: %0 = load i32, i32* @a
      let vg1 = builder.buildLoad(g1)
      // IRBUILDERARITH-NEXT: %1 = load i32, i32* @b
      let vg2 = builder.buildLoad(g2)

      // IRBUILDERARITH-NEXT: %2 = add i32 %0, %1
      _ = builder.buildAdd(vg1, vg2)
      // IRBUILDERARITH-NEXT: %3 = sub i32 %0, %1
      _ = builder.buildSub(vg1, vg2)
      // IRBUILDERARITH-NEXT: %4 = mul i32 %0, %1
      _ = builder.buildMul(vg1, vg2)
      // IRBUILDERARITH-NEXT: %5 = sdiv i32 %0, %1
      _ = builder.buildDiv(vg1, vg2, signed: true)
      // IRBUILDERARITH-NEXT: %6 = udiv i32 %0, %1
      _ = builder.buildDiv(vg1, vg2, signed: false)

      // IRBUILDERARITH-NEXT: %7 = add nsw i32 %0, %1
      _ = builder.buildAdd(vg1, vg2, overflowBehavior: .noSignedWrap)
      // IRBUILDERARITH-NEXT: %8 = sub nsw i32 %0, %1
      _ = builder.buildSub(vg1, vg2, overflowBehavior: .noSignedWrap)
      // IRBUILDERARITH-NEXT: %9 = mul nsw i32 %0, %1
      _ = builder.buildMul(vg1, vg2, overflowBehavior: .noSignedWrap)

      // IRBUILDERARITH-NEXT: %10 = add nuw i32 %0, %1
      _ = builder.buildAdd(vg1, vg2, overflowBehavior: .noUnsignedWrap)
      // IRBUILDERARITH-NEXT: %11 = sub nuw i32 %0, %1
      _ = builder.buildSub(vg1, vg2, overflowBehavior: .noUnsignedWrap)
      // IRBUILDERARITH-NEXT: %12 = mul nuw i32 %0, %1
      _ = builder.buildMul(vg1, vg2, overflowBehavior: .noUnsignedWrap)

      // IRBUILDERARITH-NEXT: %13 = sub i32 0, %0
      _ = builder.buildNeg(vg1, overflowBehavior: .default)
      // IRBUILDERARITH-NEXT: %14 = sub nuw i32 0, %0
      _ = builder.buildNeg(vg1, overflowBehavior: .noUnsignedWrap)
      // IRBUILDERARITH-NEXT: %15 = sub nsw i32 0, %0
      _ = builder.buildNeg(vg1, overflowBehavior: .noSignedWrap)


      // IRBUILDERARITH-NEXT: ret void
      builder.buildRetVoid()
      // IRBUILDERARITH-NEXT: }
      module.dump()
    })

    // MARK: Integer comparisons
    XCTAssert(fileCheckOutput(of: .stderr, withPrefixes: ["IRBUILDERCMP"]) {
      // IRBUILDERCMP: ; ModuleID = 'IRBuilderTest'
      // IRBUILDERCMP-NEXT: source_filename = "IRBuilderTest"
      let module = Module(name: "IRBuilderTest")
      let builder = IRBuilder(module: module)

      // IRBUILDERCMP: @a = global i32 1
      // IRBUILDERCMP-NEXT: @b = global i32 1
      var g1 = builder.addGlobal("a", type: IntType.int32)
      g1.initializer = Int32(1)
      var g2 = builder.addGlobal("b", type: IntType.int32)
      g2.initializer = Int32(1)

      // IRBUILDERCMP: define void @main() {
      let main = builder.addFunction("main",
                                     type: FunctionType(argTypes: [],
                                                        returnType: VoidType()))
      // IRBUILDERCMP-NEXT: entry:
      let entry = main.appendBasicBlock(named: "entry")
      builder.positionAtEnd(of: entry)

      // IRBUILDERCMP-NEXT: %0 = load i32, i32* @a
      let vg1 = builder.buildLoad(g1)
      // IRBUILDERCMP-NEXT: %1 = load i32, i32* @b
      let vg2 = builder.buildLoad(g2)

      // IRBUILDERCMP-NEXT: %2 = icmp eq i32 %0, %1
      _ = builder.buildICmp(vg1, vg2, .eq)
      // IRBUILDERCMP-NEXT: %3 = icmp ne i32 %0, %1
      _ = builder.buildICmp(vg1, vg2, .ne)
      // IRBUILDERCMP-NEXT: %4 = icmp ugt i32 %0, %1
      _ = builder.buildICmp(vg1, vg2, .ugt)
      // IRBUILDERCMP-NEXT: %5 = icmp uge i32 %0, %1
      _ = builder.buildICmp(vg1, vg2, .uge)
      // IRBUILDERCMP-NEXT: %6 = icmp ult i32 %0, %1
      _ = builder.buildICmp(vg1, vg2, .ult)
      // IRBUILDERCMP-NEXT: %7 = icmp ule i32 %0, %1
      _ = builder.buildICmp(vg1, vg2, .ule)
      // IRBUILDERCMP-NEXT: %8 = icmp sgt i32 %0, %1
      _ = builder.buildICmp(vg1, vg2, .sgt)
      // IRBUILDERCMP-NEXT: %9 = icmp sge i32 %0, %1
      _ = builder.buildICmp(vg1, vg2, .sge)
      // IRBUILDERCMP-NEXT: %10 = icmp slt i32 %0, %1
      _ = builder.buildICmp(vg1, vg2, .slt)
      // IRBUILDERCMP-NEXT: %11 = icmp sle i32 %0, %1
      _ = builder.buildICmp(vg1, vg2, .sle)

      // IRBUILDERCMP-NEXT: ret void
      builder.buildRetVoid()
      // IRBUILDERCMP-NEXT: }
      module.dump()
    })
  }

  #if !os(macOS)
  static var allTests = testCase([
    ("testIRBuilder", testIRBuilder),
  ])
  #endif
}
