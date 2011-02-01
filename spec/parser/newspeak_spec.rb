require File.expand_path('../../spec_helper', __FILE__)

describe Reak::Parser::Newspeak do
  before { @parser = Reak::Parser::Newspeak.new }

  describe "locals" do
    subject { @parser.locals }
    it { should parse("| foo |") }
    it { should parse("| foo = code. |") }
    it { should parse("| foo foo = code. |") }
    it { should_not parse("| foo = code |") }
  end

  describe "expression" do
    subject { @parser.expression }
    it { should_not parse("foo := bar") }
    it { should_not parse("foo _ bar") }
  end

  describe "method" do
    subject { @parser.method }
    it { should parse("foo = ( ^ code )") }
    it { should parse("foo: a = ( ^ code )") }
    it { should parse("~= a = ( ^ code )") }
  end

  describe "class_header" do
    subject { @parser.class_header }
    it { should parse("class Test = ()") }
    it { should parse("class Test = (||)") }
    it { should parse("class Test = (
      | instanceVariable |
    )") }
    it { should parse("class Test = (
      | instanceVariable = Object. |
    )") }
    it { should parse("class Test = (
      | instanceVariable = Object. |
      code.
    )") }
    it { should parse("class Test = Object ()") }
    it { should parse("class Test on: platform = ()") }
    it { should parse("class Test on: platform = Object ()") }
    it { should_not parse("class Test = Object on: platform ()") }
  end

  describe "category" do
    subject { @parser.category }
    it { should parse("('a category'
      method = (
        ^ code.
      )
    )") }
    it { should parse("('a category'
      method = (
        ^ code.
      )
      method2: arg = (
        ^ code.
      )
    )") }
  end
end
