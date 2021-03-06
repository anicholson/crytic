require "../src/crytic/runner"
require "./fake_reporter"
require "./fake_generator"
require "./spec_helper"

describe Crytic::Runner do
  describe "#run" do
    it "raises for empty specs" do
      expect_raises(ArgumentError) do
        runner.run("", [] of String)
      end
    end

    it "raises for non-existent files" do
      expect_raises(ArgumentError, "Source file") do
        runner.run("./nope.cr", ["./nope_spec.cr"])
      end
      expect_raises(ArgumentError, "Source file") do
        runner.run(["./nope.cr", "./fixtures/simple/bar.cr"], ["./fixtures/simple/bar_spec.cr"])
      end
      expect_raises(ArgumentError, "Spec file") do
        runner.run("./fixtures/simple/bar.cr", ["./nope_spec.cr"])
      end
    end

    it "takes comma separated list of subjects" do
      reporter = FakeReporter.new
      runner = Crytic::Runner.new(
        threshold: 100.0,
        generator: FakeGenerator.new,
        reporters: [reporter] of Crytic::Reporter::Reporter)

      runner.run(
        ["./fixtures/require_order/blog.cr", "./fixtures/require_order/pages/blog/archive.cr"],
        ["./fixtures/simple/bar_spec.cr"]).should eq true
    end

    it "reports events in order" do
      reporter = FakeReporter.new
      runner = Crytic::Runner.new(
        threshold: 100.0,
        generator: FakeGenerator.new,
        reporters: [reporter] of Crytic::Reporter::Reporter)

      runner.run("./fixtures/simple/bar.cr", ["./fixtures/simple/bar_spec.cr"])

      reporter.events.should eq ["report_original_result", "report_mutations", "report_summary", "report_msi"]
    end
  end
end

private def runner
  Crytic::Runner.new(
    threshold: 100.0,
    reporters: [Crytic::Reporter::IoReporter.new(IO::Memory.new)] of Crytic::Reporter::Reporter,
    generator: FakeGenerator.new)
end
