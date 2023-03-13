# coding: utf-8

require 'test/unit'
require 'asciidoctor'

require 'asciidoctor/i18n/processor'
require 'asciidoctor/i18n/translator'

class TestProcessor < Test::Unit::TestCase
  setup do
    @po = GetText::PO.new
    @po['Hello'] = 'こんにちは'
    @po['Chapter Title'] = '章タイトル'
    @po['Chapter2 Title'] = '章2タイトル'
    @po['Hello *bold*'] = 'こんにちは *太字*'
    @po["Hello +\nHello"] = "こんにちは +\nこんにちは"
    @po['*bold*, _italic phrase_, `monospace phrase`'] = '*太字*、_イタリックのフレーズ_、`モノスペースのフレーズ`'
    @translator = Asciidoctor::I18n::Translator.new('old-po' => @po)
    @processor = Asciidoctor::I18n::Processor.new
  end

  data(
    'paragraph' => ['Hello', :paragraph, :source, 'こんにちは'],
    'literal' => [' Hello', :literal, :source, 'こんにちは'],
    'line breaks' => ["Hello +\nHello", :paragraph, :source, "こんにちは +\nこんにちは"],
    'admonition' => ['NOTE: Hello', :admonition, :source, 'こんにちは'],
    'lead paragraph' => ["[.lead]\nHello", :paragraph, :source, 'こんにちは'],
    'bold, italic and monospace' => [
      '*bold*, _italic phrase_, `monospace phrase`',
      :paragraph,
      :source,
      '*太字*、_イタリックのフレーズ_、`モノスペースのフレーズ`',
    ],
    'section' => ['= Chapter Title', :section, :title, '章タイトル'],
    'section2' => ['== Chapter2 Title', :section, :title, '章2タイトル'],
    'section with style' => ['=== Hello *bold*', :section, :title, 'こんにちは <strong>太字</strong>'],
    'unordered list item' => ['* Hello', :list_item, :text, 'こんにちは'],
    'ordered list item' => ['. Hello', :list_item, :text, 'こんにちは'],
    'check list item' => ['* [*] Hello', :list_item, :text, 'こんにちは'],
    'labeled single line item' => ['Hello:: Hello', :list_item, :text, 'こんにちは'],
    'labeled multi line item' => ["Hello::\n  Hello", :list_item, :text, 'こんにちは'],
    'sidebar' => [['.Hello', '****', 'Hello', '****'].join("\n"), :sidebar, :title, 'こんにちは'],
    'blockquote' => [['____', 'Hello', '____'].join("\n"), :paragraph, :source, 'こんにちは'],
    'codeblock' => [['----', 'Hello', '----'].join("\n"), :listing, :source, 'こんにちは']
  )
  def test_processor(data)
    source, context, attr, expected = data
    doc = Asciidoctor.load(source)
    @processor.process_document(doc, @translator)
    nodes = doc.find_by(context: context)
    assert !nodes.empty?
    assert_equal [expected] * nodes.size, nodes.map(&attr)
  end

  def test_simple_table
    doc = Asciidoctor.load(['|===', '|Hello', '|==='].join("\n"))
    @processor.process_document(doc, @translator)
    table = doc.find_by(context: :table).first
    assert_equal 'こんにちは', table.rows.body[0][0].text
  end

  def test_complex_table
    doc = Asciidoctor.load("|===\na|* Hello\n|===\n")
    @processor.process_document(doc, @translator)
    table = doc.find_by(context: :table).first
    assert_equal 'こんにちは', table.rows.body[0][0].inner_document.find_by.last.text
  end

  def test_table_header
    doc = Asciidoctor.load("[options=header]\n|===\n|Hello\n|===\n")
    @processor.process_document(doc, @translator)
    table = doc.find_by(context: :table).first
    assert_equal 'こんにちは', table.rows.head[0][0].text
  end

  def test_no_translation
    doc = Asciidoctor.load('foo bar')
    @processor.process_document(doc, @translator)
    paragraph = doc.find_by(context: :paragraph).first
    assert_equal 'foo bar', paragraph.source
  end
end
