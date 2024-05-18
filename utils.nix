{ lib }:
with lib; {
  llvmVersionFromCMakeLists = file:
    let
      cmakeTxtSplit = splitString "\n" (builtins.readFile file);
      findSetVariableStatement = var: builtins.match " *set\\(${var} ?([0-9]*)\)";
      findSetVariableStatementFromList = var: findFirst (str: (findSetVariableStatement var str) != null) null;
      findVersion = kind:
        let
          varName = "LLVM_VERSION_${kind}";
        in
        builtins.elemAt (findSetVariableStatement varName (findSetVariableStatementFromList varName cmakeTxtSplit)) 0;
    in
    "${findVersion "MAJOR"}.${findVersion "MINOR"}.${findVersion "PATCH"}${findVersion "SUFFIX"}";
}
