#!/usr/bin/env -S mise x ruby@latest -- ruby
Dir.chdir(File.dirname(__FILE__))
require "bundler/setup"
require "bubbletea"


class Counter
  include Bubbletea::Model

  def initialize
    @count = 0
  end

  def init
    [self, nil]
  end

  def update(message)
    case message
    when Bubbletea::KeyMessage
      case message.to_s
      when "q", "ctrl+c"
        [self, Bubbletea.quit]
      when "up", "k"
        @count += 1
        [self, nil]
      when "down", "j"
        @count -= 1
        [self, nil]
      else
        [self, nil]
      end
    else
      [self, nil]
    end
  end

  def view
    "Count: #{@count}\n\nPress up/down to change, q to quit"
  end
end

Bubbletea.run(Counter.new)
