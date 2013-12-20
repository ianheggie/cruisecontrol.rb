# A BuildLogParser understands how to parse Test::Unit and RSpec test errors generated by a build
# run and turn them into a more succinct error representation.
class BuildLogParser
  TEST_FAILURE_REGEX = /^={2,}\nFailure\:(?:\s|\n)*?(\S.*?)\n(.*?)\n(.*?)\n={2,}/m
  TEST_ERROR_REGEX = /^={2,}\nError\:\s+(\S+)\n\s+?(.*?)\n(.*?)\n={2,}/m

  RSPEC_ERROR_REGEX = /^(\S+) in '(.*)'\n((.*\n)+)/
  RSPEC_FAILURE_REGEX = /^'(.*)' FAILED\n((.+\n)+)/
  RSPEC_STACK_TRACE_REGEX = /^.*:\d+:.*$/
  RSPEC_STACK_TRACE_MAYBE_END_REGEX = /\n\nFinished.*$/

  TEST_NAME_REGEX = /\S+/
  MESSAGE_REGEX = /\]\:\n([\s\S]+)/
  STACK_TRACE_REGEX = /\[([\s\S]*?)\]\:/

  def initialize(log)
    @log = log
  end

  def errors
    test_errors + rspec_errors
  end

  def fix_name(name)
    name.match(/(.*?)\((.*?)\)/) do |match|
      name = "#{match[2]}.#{match[1]}"
    end
    name
  end

  def test_errors
    test_errors = []
    @log.scan(TEST_ERROR_REGEX) do |match|
      name = $1
      message = $2
      stacktrace = $3
      name = fix_name(name)
      test_errors << TestErrorEntry.create_error(name, message, stacktrace)
    end
    return test_errors
  end

  def rspec_errors
    errors = []
    [@log.split(/\d+\)/)[1..-1]].compact.flatten.each do |issue_content|
      issue_content.chop.scan(RSPEC_ERROR_REGEX) do |match|
        exception_name = $1
        spec_name = $2
        content = $3
        rest_of_the_message, stack_trace = rspec_rest_of_message_and_stack_trace(content)
        message = "#{exception_name} in '#{spec_name}'\n#{rest_of_the_message}"
        errors << TestErrorEntry.create_error(spec_name, message, stack_trace)
      end
    end
    errors
  end

  def failures
    test_failures + rspec_failures
  end

  def test_failures
    test_failures = []
    @log.scan(TEST_FAILURE_REGEX) do |match|
      name = $2
      message = $1
      stacktrace = $3
      name = fix_name(name)
      test_failures << TestErrorEntry.create_failure(name, message, stacktrace)
    end
    test_failures
  end

  def rspec_failures
    failures = []
    [@log.split(/\d+\)/)[1..-1]].compact.flatten.each do |issue_content|
      issue_content.chop.scan(RSPEC_FAILURE_REGEX) do |match|
        spec_name = $1
        content = $2
        rest_of_the_message, stack_trace = rspec_rest_of_message_and_stack_trace(content)
        failures << TestErrorEntry.create_failure(spec_name, rest_of_the_message, stack_trace)
      end
    end
    failures
  end

  def failures_and_errors
    failures + errors
  end

  def rspec_rest_of_message_and_stack_trace(content)
    rest_of_the_message = []
    stack_trace = ""
    content_lines = content.split("\n")
    content_lines.each_with_index do |line, index|
      if line =~ RSPEC_STACK_TRACE_REGEX
        stack_trace << content_lines[index..-1].join("\n").gsub(RSPEC_STACK_TRACE_MAYBE_END_REGEX, "")
        break
      else
        rest_of_the_message << line
      end
    end
    [rest_of_the_message.join("\n"), stack_trace]
  end
end
