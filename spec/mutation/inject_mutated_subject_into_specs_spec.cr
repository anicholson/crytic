require "../../src/crytic/mutation/inject_mutated_subject_into_specs"
require "compiler/crystal/syntax/*"
require "../spec_helper"

module Crytic::Mutation
  describe InjectMutatedSubjectIntoSpecs do
    Spec.before_each do
      InjectMutatedSubjectIntoSpecs.reset
    end

    it "can replace the subject in a direct require" do
      spec_file = "./fixtures/simple/bar_spec.cr"
      InjectMutatedSubjectIntoSpecs
        .new(
        path: spec_file,
        source: File.read(spec_file),
        subject_path: "./fixtures/simple/bar.cr",
        mutated_subject_source: "puts \"mutated source\"")
        .to_covered_source
        .should eq <<-CODE
        # require of `fixtures/simple/bar.cr` from `fixtures/simple/bar_spec.cr:1`
        puts("mutated source")
        require "spec"
        describe("bar") do
          it("works") do
            bar.should(eq(2))
          end
        end

        CODE
    end

    it "can follow a one level deep require" do
      spec_file = "./fixtures/simple/bar_with_helper_spec.cr"
      InjectMutatedSubjectIntoSpecs
        .new(
        path: spec_file,
        source: File.read(spec_file),
        subject_path: "./fixtures/simple/bar.cr",
        mutated_subject_source: "puts \"mutated source\"")
        .to_covered_source
        .should eq <<-CODE
        # require of `fixtures/simple/spec_helper.cr` from `fixtures/simple/bar_with_helper_spec.cr:1`
        require "http"
        # require of `fixtures/simple/bar.cr` from `fixtures/simple/spec_helper.cr:2`
        puts("mutated source")

        require "spec"
        describe("bar") do
          it("works") do
            bar.should(eq(2))
          end
        end

        CODE
    end

    it "respects the crystal require order" do
      spec_file = "./fixtures/require_order/blog_spec.cr"
      subject_file = "./fixtures/require_order/blog.cr"
      InjectMutatedSubjectIntoSpecs
        .new(
        path: spec_file,
        source: File.read(spec_file),
        subject_path: subject_file,
        mutated_subject_source: File.read(subject_file))
        .to_covered_source
        .should eq <<-CODE
        # require of `fixtures/require_order/blog.cr` from `fixtures/require_order/blog_spec.cr:1`
        # require of `fixtures/require_order/pages/main_layout.cr` from `fixtures/require_order/blog.cr:1`
        abstract class MainLayout
        end# require of `fixtures/require_order/pages/blog/archive.cr` from `fixtures/require_order/blog.cr:1`
        class Archive < MainLayout
          def render
            "welcome page"
          end
        end
        class Blog
          def render
            "\#{Archive.new.render} \#{1}"
          end
        end

        require "spec"
        describe(Blog) do
          it("renders") do
            Blog.new.render.should(eq("welcome page 1"))
          end
        end

        CODE
    end
  end
end
