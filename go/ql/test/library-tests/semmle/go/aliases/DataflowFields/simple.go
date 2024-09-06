package test

func source() int { return 0 }
func sink(value int) { }

type IntAlias = int
type IntStruct = struct{ field int }
type IntAliasStruct = struct{ field IntAlias }

func F() {

  x := source()
  intStruct := IntStruct{x}

  G(&intStruct)

}

func G(intAliasStruct *IntAliasStruct) {

  sink(intAliasStruct.field) // $ hasValueFlow="selection of field"

}
