# The "Formulary" was merged back into "Formula" after the latest alias
# changes. But now we want to support multiple repos, so we need an
# abstraction for that.
#
# A "repository" or "repo" is just a folder with Alias and Formula
# subfolders.

require 'extend/pathname'


class Repository
  attr_reader :path

  def initialize path
    @path = Pathname.new(path)
  end
end

DEFAULT_REPOSITORY = Repository.new(HOMEBREW_REPOSITORY+'Library')
