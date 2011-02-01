require File.expand_path('../../spec_helper', __FILE__)

describe Reak::Parser::Newspeak do
  before { @parser = Reak::Parser::Newspeak.new }

  describe "newlines" do
    subject { @parser.newline }
    it { should parse("\r\n") }
    it { should parse("\n") }
    it { should parse("\r") }
  end

  describe "locals" do
    subject { @parser.locals }
    it { should parse("| foo |") }
    it { should parse("| foo = code. |") }
    it { should parse("| foo foo = code. |") }
    it { should_not parse("| foo = code |") }
  end

  describe "assignment" do
    subject { @parser.assignment }
    it { should parse("foo =") }
    it { should_not parse("foo :=") }
    it { should_not parse("foo _") }
  end

  describe "unary expression" do
    subject { @parser.unary_expression }
    it { should parse("foo") }
    it { should parse("foo bar") }
    it { should parse("(foo bar) baz") }
  end

  describe "binary expression" do
    subject { @parser.binary_expression }
    it { should parse("+ 2") }
    it { should parse("1 + 2") }
    it { should parse("1 + 2 + 3") }
    it { should parse("(1 + 2) + 3") }
  end

  describe "keyword expression" do
    subject { @parser.keyword_expression }
    it { should parse("test: argument") }
    it { should parse("test: arg1 with: arg2") }
    it { should parse("test: 1 + 2 with: 3 + 4") }
    it { should parse("test: foo bar with: 3 + 4") }
    it { should parse("self test: foo bar with: 3 + 4") }
  end

  describe "method" do
    subject { @parser.method }
    it { should parse("foo = ( ^ code )") }
    it { should parse("foo: a = ( ^ code )") }
    it { should parse("~= a = ( ^ code )") }
    it { should parse("div: aBlock = (
      ^ rectangleWithContent: aBlock value.
    )")}
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
    it { should parse("'a category'
      method = (
        ^ code.
      )") }
    it { should parse("'a category'
      method = (
        ^ code.
      )
      method2: arg = (
        ^ code.
      )") }
    it { subject.repeat.should parse("'a category'
      method = (
        ^ code.
      )'another category'
      method2: arg = (
        ^ code.
      )") }
  end

  describe "classes" do
    header = "class Test on: platform = Object (|bar instVar = foo.|)"
    cat_body = "'cat1'\nass = (^ a)\nbass = (^ b)\n'cat2'\narr = (^ 1)"
    nested_class = "#{header}(#{cat_body})"
    outer_class = "#{header}(#{nested_class}#{cat_body})"
    file_out = "Newsqueak2\r\n'Category'\r\n#{outer_class}"

    describe "class_definition" do
      subject { @parser.class_definition }
      it { should parse(nested_class) }
      it { should parse(outer_class) }
    end

    describe "file_out" do
      subject { @parser.file_out }
      it { should parse(file_out) }
      it { should parse(File.read(File.expand_path('../file_out.ns2', __FILE__))) }
      it { should parse(File.read(File.expand_path('../nested_file_out.ns2', __FILE__))) }
    end
  end
end
