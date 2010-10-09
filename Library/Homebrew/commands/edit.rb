def brew_edit
  if ARGV.named.empty?
    # EDITOR isn't a good fit here, we need a GUI client that actually has
    # a UI for projects, so apologies if this wasn't what you expected,
    # please improve it! :)
    exec 'mate', *Dir["#{HOMEBREW_REPOSITORY}/Library/*"]<<
                      "#{HOMEBREW_REPOSITORY}/bin/brew"<<
                      "#{HOMEBREW_REPOSITORY}/README.md"
  else
    require 'formula'
    # Don't use ARGV.formulae as that will throw if the file doesn't parse
    paths = ARGV.named.collect do |name|
      path = Formula.path(Formula.resolve_alias(name))
      unless File.exist? path
        raise FormulaUnavailableError, name
      else
        path
      end
    end
    exec_editor(*paths)
  end
end