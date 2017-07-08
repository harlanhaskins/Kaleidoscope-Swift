# Kaleidoscope-Swift

This is the LLVM-backed compiler from part 3 of the
[Building a Compiler in Swift with LLVM](https://harlanhaskins.com/2017/01/11/building-a-compiler-with-swift-in-llvm-part-3-code-generation-to-llvm-ir.html) 
series.

# Important Installation Instructions:

> Apologies, but the project currently only works on macOS due to some build
> behavior we need to fix for LLVMSwift. We hope to have it building on Linux
> by the end of this week.

You must follow the instructions specificed in the README for `LLVMSwift` to be
able to compile this project. Namely, you must copy `cllvm.pc` into
`/usr/local/lib/pkgconfig` before the project will build.

Once that's done, just open this folder and run

```bash
swift build
```

and you should have a binary at `.build/Debug/Kaleidoscope`.

On macOS, you can also run

```bash
swift package generate-xcodeproj
```

to create an Xcode project for this repo.

# Author

Harlan Haskins ([@harlanhskins](https://github.com/harlanhaskins))

# License

This project is released under the MIT license, a copy of which is attached
to this repo.
