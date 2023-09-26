{
  function basic() {
    mstore(0x80, 0x42)
    yield()
    mstore(0xa0, 0x32)
  }

  function main() {
    basic()
  }

  main()
  return(0x80, 0x40)
}
