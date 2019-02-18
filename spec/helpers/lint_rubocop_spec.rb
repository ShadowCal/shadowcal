# frozen_string_literal: true

require 'spec_helper'

describe 'Check that the files we have changed have correct syntax' do
  before do
    @files = `git diff --no-commit-id --name-only --diff-filter=d -r HEAD | grep .rb`
  end

  it 'runs rubocop on changed ruby files' do
    if @files.empty?
      puts "Linting not performed. No ruby files changed."
    else
      puts
      puts "Running rubocop for changed files: "
      puts @files
      puts

      @files.tr!("\n", ' ')
      result = system "bundle exec rubocop --force-exclusion --config .rubocop.yml --fail-level warn #{@files}"
      puts
      puts
      expect(result).to be(true)
    end
  end
end
