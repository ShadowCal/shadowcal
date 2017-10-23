require 'spec_helper'

RSpec.describe 'Check that the files we have changed have correct syntax' do
  before do
    current_sha = 'origin/master..HEAD'
    @files = `git diff-tree --no-commit-id --name-only -r #{current_sha} | grep .rb`
    @files.tr!("\n", ' ')
  end

  it 'runs rubocop on changed ruby files' do
    if @files.empty?
      puts "Linting not performed. No ruby files changed."
    else
      puts "Running rubocop for changed files: #{@files}"
      result = system "bundle exec rubocop --config .rubocop.yml --fail-level warn #{@files}"
      expect(result).to be(true)
    end
  end
end
