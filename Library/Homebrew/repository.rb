# The "Formulary" was merged back into "Formula" after the latest alias
# changes. But now we want to support multiple repos, so we need an
# abstraction for that.
#
# A "repository" or "repo" is just a folder with Alias and Formula
# subfolders.


class Repository
  attr_reader :path

  def initialize path
    @path = Pathname.new(path)
  end

  def alias_location
    path+"Aliases"
  end

  def formula_location
    path+"Formula"
  end

  # an array of all Formula names in this repo
  # todo - need to hang on to the repo reference as well
  def names
    Dir["#{formula_location}/*.rb"].map{ |f| File.basename f, '.rb' }.sort
  end

  # an array of all alias names in this repo
  # todo - need to hang on to the repo reference as well
  def aliases
    Dir["#{alias_location}/*"].map{ |f| File.basename f }.sort
  end

  # Bad name for this method
  def formula_path name
    formula_location+"#{name.downcase}.rb"
  end
end

DEFAULT_REPOSITORY = Repository.new(HOMEBREW_REPOSITORY+'Library')
