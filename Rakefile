require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :docs do
  partial_keyword = '<<<<<'
  ignore_keyword = "# IGNORE\n"
  comment_keyword = "# COMMENT\n"
  src = './docs/README.template.md'
  target = './README.md'
  content = File.readlines(src).flat_map {|line|
    if line.lstrip.start_with?(partial_keyword)
      partial_file = line.lstrip[partial_keyword.size...-1]
      sh 'ruby', partial_file
      File.readlines partial_file
    else
      line
    end
  }
  File.open(target, 'w') {|f|
    content.reject{|line|
      line.end_with?(ignore_keyword)
    }.each_cons(2){|line1,line2|
      next if line1.end_with?(comment_keyword)
      if line2.end_with?(comment_keyword)
        f.puts "#{line1.chomp} # #{line2.match(/'(.*)'/)[1]}\n"
      else
        f.puts line1
      end
    }
  }
end

task :default => :test
