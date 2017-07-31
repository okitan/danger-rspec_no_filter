require "git_diff_parser"

module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  # @example Ensure people are well warned about merging on Mondays
  #
  #          my_plugin.warn_on_mondays
  #
  # @see  okitan/danger-rspec_no_filter
  # @tags monday, weekends, time, rattata
  #
  class DangerRspecNoFilter < Plugin
    # A method that you can call from your Dangerfile
    # @return   [Array<String>]
    #
    def warn_for_rspec_filter_tags(tags = tags_from_spec_helper)
      regexp = Regexp.new([ "fit", "fcontext", *tags ].map {|item| "\\s+#{item}\\s+" }.join("|"))

      diff = GitDiffParser.parse(github.pr_diff)

      diff.each do |diff_per_file|
        next unless diff_per_file.file.end_with?(".rb") # for shared examples _spec.rb is not enough

        diff_per_file.changed_lines.each do |line|
          if line.content =~ regexp
            warn "#{line.content} on #{diff_per_file.file}:#{line.number} includes #{regexp}"
          end
        end
      end
    end

    protected
    def tags_from_spec_helper
      `bundle exec ruby -r rspec -r ./spec/spec_helper -e "print RSpec.configuration.filter_run.merge(RSpec.configuration.filter_run_when_matching).keys.join(',')"`.split(",").map {|item| "\\:#{item}" }
    rescue
      []
    end
  end
end
