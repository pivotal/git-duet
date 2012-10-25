require 'git/duet'
require 'tk'

class Git::Duet::PreCommitTkInput
  def initialize
    @root = Tk::Root.new { title "Git Duet" }
  end

  def get_input!(&block)
    raise StandardError.new("We need a block!") if !block_given?
    @input_block = block
    build
    Tk.mainloop
  end

  private

  def build
    return if @already_built
    @confirm_button = Tk::Button.new(@root) { text 'OK' }
    @confirm_button.pack(side: 'bottom', fill: 'y')
    @confirm_button.bind('Enter') { callback }
    @initials_entry = Tk::Entry.new(@root).pack(side: 'bottom', fill: 'x')
    @initials_label = Tk::Label.new(@root) { text "Who's in this duet (or solo)?" }
    @initials_label.pack(side: 'top')
    @already_built = true
  end

  def callback(button)
    require 'pry'
    binding.pry
  end
end

if $0 == __FILE__
  Git::Duet::PreCommitTkInput.new.get_input! do |text|
    puts text
  end
end
