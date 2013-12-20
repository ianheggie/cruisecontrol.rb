# BuildMailer is an ActionMailer class that understands how to send build status reports.
class BuildMailer < ActionMailer::Base

  def build_report(build, recipients, from, subject, message, sent_at = Time.now)
    @subject             = "[CruiseControl] #{subject}"
    @build               = build
    @message             = message
    @failures_and_errors = parse_failures_and_errors(BuildLogParser.new(build.output).failures_and_errors)
    @recipients          = recipients
    @from                = from
    @sent_on             = sent_at
    @headers             = {}
    mail(:to => @recipients, :subject => @subject, :from => @from)
  end

  def send_release_note(build, recipients, from, subject, message, sent_at = Time.now)
    @subject             = "[CruiseControl][ReleaseNote] #{subject}"
    @build               = build
    @message             = message
    @failures_and_errors = BuildLogParser.new(build.output).failures_and_errors.map { |e| formatted_error(e) }
    @recipients          = recipients
    @from                = from
    @sent_on             = sent_at
    @headers             = {}
    mail(:to => @recipients, :subject => @subject, :from => @from)
  end

  def test(recipients,  sent_at = Time.now)
    @subject             = 'Test CI E-mail'
    @build               = nil
    @message             = 'Hi, mom'
    @failures_and_errors = []
    @recipients          = recipients
    @sent_on             = sent_at
    @headers             = {}
    mail(:to => @recipients, :subject => @subject)
  end

  def parse_failures_and_errors(errors)
    parsed = {}
    message = ''
    errors.each do |e|
      e.type.downcase!
      parsed[e.type] ||= []
      parsed[e.type] << e
    end

    parsed.keys.sort.each do |k|
      header = "TEST #{k.upcase}S"
      message << [header, "-" * header.size].join("\n")
      parsed[k].each do |e|

        message << ["\n", "#{e.test_name}: #{e.message}", e.stacktrace].join("\n")
      end
      message << "\n\n"
    end
    message
  end

  def formatted_error(error)
    return "Name: #{error.test_name}\n" +
           "Type: #{error.type}\n" +
           "Message: #{error.message}\n\n" +
           error.stacktrace + "\n\n\n"
  end

end
