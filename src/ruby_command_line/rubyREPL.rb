#!/usr/bin/ruby
require "irb"

class Evaluator

  def initialize(binding = TOPLEVEL_BINDING)
    @binding = binding
  end

  def eval(input)
    # Binding#source_location is available since Ruby 2.6.
    if @binding.respond_to? :source_location
      "#{@binding.eval(input, *@binding.source_location).inspect}"
    else
      "#{@binding.eval(input).inspect}"
    end
  rescue Exception => exc
    puts exc
  end

end

class IW_RUBY

    def initialize
      @line_length = 1
      @Evaluator = Evaluator.new
    end

    def run
      print "Infoworks Ruby Console:\n"
      in_loop
      print "Exited!"
    end

    def in_loop
      loop do
        print "[#{@line_length}] irb>>"
        input = $stdin.gets
        if input == 'exit' or input == 'exit()'
          break
        else
          begin
            p @Evaluator.eval(input)
          rescue Exception => e
            print "#{e}\n"
          end
        end
        @line_length += 1
      end
    end
end
#run console
IW_RUBY.new().run
