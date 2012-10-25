require 'tk'
require 'git/duet'
require_relative 'command_methods'

class Git::Duet::PreCommitTkCommand
  include Git::Duet::CommandMethods

  def initialize(quiet = false)
    @quiet = !!quiet
  end

  def execute!
    build
    Tk.mainloop
  end

  private

  def build
    return if @already_built

    @root = Tk::Root.new do
      title 'Git Duet'
      minsize(200, 80)
    end
    @confirm_button = Tk::Button.new(@root) do
      text 'OK'
    end
    @confirm_button.command { initials_entry_callback }
    @confirm_button.pack(side: 'bottom')
    @initials_entry = Tk::Entry.new(@root) do
    end
    @initials_entry.pack(side: 'bottom')
    @initials_variable = TkVariable.new
    @initials_entry.textvariable = @initials_variable
    @initials_label = Tk::Label.new(@root) do
      text "Who's in this duet (or solo)?"
    end
    @initials_label.pack(side: 'top')

    @already_built = true
  end

  def initials_entry_callback
    initials = @initials_variable.value.split.map(&:strip)
    if initials.length == 1
      require_relative 'solo_command'
      Git::Duet::SoloCommand.new(initials.first).execute!
      exit_success
    elsif initials.length == 2
      require_relative 'duet_command'
      Git::Duet::DuetCommand.new(initials.first, initials.last).execute!
      exit_success
    else
      error "What are we supposed to do with this??? -> #{initials.inspect}"
      exit_failure
    end
  rescue KeyError => e
    error "Failed to lookup authors by initials!: #{e.message}"
    require 'pry'
    binding.pry
  end

  def exit_success
    exit 0
  end

  def exit_failure
    exit 1
  end
end

if $0 == __FILE__
  Git::Duet::PreCommitTkCommand.new.execute!
end
