var MyClass = require("../src/myClass.js");
var dsClasses = require("../src/dsClasses.js")
var sinon = require("sinon")
var myObj = new MyClass();
var chai = require("chai");
var expect = chai.expect;

describe("test suit",  function() {
  it("test the add method", function() {
    expect(myObj.add (1,2)).to.be.equal(3)
  });

  it("spy the add method", function() {
    var spy = sinon.spy(myObj, "add");
    var arg1 = 10,
     arg2 = 20;

    myObj.callAnotherFn(arg1, arg2);
    sinon.assert.calledTwice(spy);

    expect(spy.calledWith(arg1, arg2)).to.be_true;
  })
})