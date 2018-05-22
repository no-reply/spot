# Extends the hydra-editor MultiValueInput element with a dropdown to select
# the language of the value.
class MultiValueWithLanguageInput < MultiValueInput
  def available_languages
    {
      en: 'English',
      fr: 'French',
      ja: 'Japanese'
    }
  end

  protected

  def inner_wrapper
    <<-HTML
    <li class="field-wrapper">
      <div class="input-group">
        #{language_dropdown}
        #{yield}
      </div>
    </li>
    HTML
  end

  def language_dropdown
    <<-HTML
    <div class="input-group-btn language-toggle">
      <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
        Action <span class="caret"></span>
      </button>
      <ul class="dropdown-menu">
        <li class="language-option"><a href="#"> -- none -- </a></li>
        #{language_options}
      </ul>
    </div>
    HTML
  end

  private

  def language_options
    available_languages.collect { |value, label| language_option_tag(value, label) }.join
  end

  def language_option_tag(value, label)
    %Q(<li class="language-option"><a href="#" data-lang="#{value}">#{label}</a></li>)
  end

  def multiple?
    true
  end
end
