class MyClass {
  constructor () {
    console.log("initiate")
  }

  add (arg1, arg2) {
    var result;
    result = arg1 + arg2;
    return result;
  }

  callAnotherFn(arg1, arg2) {
    var result = this.add(arg1, arg2);
    return result
  }
}

module.exports = MyClass