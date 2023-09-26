{
  function basic() {
    mstore(0x80, 0x42)
  }

  function func1(val) {
    mstore(0xa0, val)
  }

  function main() {
    spawn(func1(0x32))
    basic()
  }

  main()
  return(0x80, 0x40)
}
