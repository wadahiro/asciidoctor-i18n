# coding: utf-8

require 'asciidoctor/extensions'
require_relative 'translator'

module Asciidoctor
  module I18n
    class Processor < Extensions::Treeprocessor
      def process(document)
        translator = Translator.new(document.attributes)
        process_document(document, translator)
        translator.save
      end

      def process_document(document, translator)
        document.find_by.each do |src|
          process_abstract_block(src, translator) if src.is_a?(Asciidoctor::AbstractBlock)
          process_block(src, translator) if src.is_a?(Asciidoctor::Block)
          process_table(src, translator) if src.is_a?(Asciidoctor::Table)
          process_list_item(src, translator) if src.is_a?(Asciidoctor::ListItem)
        end
      end

      private

      def process_abstract_block(src, translator)
        raw = src.instance_variable_get(:@title)
        raw = src.instance_variable_get(:@doctitle) unless raw
        return unless raw
        src.title = translator.translate(raw)
      end

      def process_block(src, translator)
        src.lines = translator.translate(concatenated_lines(src, src.lines))
      end

      def process_table(src, translator)
        (src.rows.head + src.rows.body).each do |row|
          row.each do |cell|
            process_table_cell(cell, translator)
          end
        end
      end

      def process_list_item(src, translator)
        raw = src.instance_variable_get(:@text)
        return unless raw
        text = concatenated_lines(src, raw.split("\n")).join("\n")
        src.text = translator.translate(text)
      end

      def process_table_cell(src, translator)
        if src.style != :asciidoc
          text = src.instance_variable_get(:@text)
          return unless text
          src.text = translator.translate(text)
        else
          process_document(src.inner_document, translator)
        end
      end

      # concat continuous lines if no hard line break exists
      def concatenated_lines(src, lines)
        return lines if skip_concatenate?(src, lines)
        result = [lines.first]
        lines.drop(1).each do |line|
          if line_break?(src, result.last, line)
            result.push(line)
          else
            result[-1] = result[-1] + " #{line}"
          end
        end
        result
      end

      def skip_concatenate?(src, lines)
        lines.empty? || !%i[simple compound].include?(src.content_model)
      end

      def line_break?(src, prev_line, next_line)
        content = src.apply_subs("#{prev_line}\n#{next_line}", src.subs)
        content.gsub(/<br>\s*$/).include?('<br>')
      end
    end
  end
end
