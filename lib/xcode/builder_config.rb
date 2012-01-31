module Xcode
  class BuilderConfig
   
   def initialize
     @values = {}
     @before = {}
     @after = {}
   end
   
   def method_missing(method, *args)
     @values[method.to_sym] = args[0]
   end
   
   def before(event, &block)
     @before[event]=[] if @before[event].nil?
     @before[event]<< block
   end
   
   def after(event, &block)
     @after[event]=[] if @after[event].nil?
     @after[event]<< block
   end
   
   def self.load(file)
     bc = Xcode::BuilderConfig.new
     eval(File.read(file), bc, file)
     bc
   end
    
   def build
     config = Xcode.project(@values[:project]).target(@values[:target]).config(@values[:config])
     config.info_plist do |info|
       info.version = @values[:version]
     end
     builder = config.builder
     builder.identity = @values[:identity]
     builder.profile = @values[:profile]
     
     @before[:clean].each do |b|
       b.call(builder)
     end
     builder.clean
     @after[:clean].each do |b|
       b.call(builder)
     end
     
     @before[:build].each do |b|
       b.call(builder)
     end
     builder.build
     @after[:build].each do |b|
       b.call(builder)
     end
     
     @before[:package].each do |b|
       b.call(builder)
     end
     builder.package
     @after[:package].each do |b|
       b.call(builder)
     end
          
      
     if @values.has_key? :testflight_api_token and @values.has_key? :testflight_team_token
       `curl -X POST http://testflightapp.com/api/builds.json -F file=@"#{builder.ipa_path}" -F dsym=@"#{builder.dsym_zip_path}" -F api_token='#{@values[:testflight_api_token]}' -F team_token='#{@values[:testflight_team_token]}' -F notify=True -F notes=\"#{@values[:testflight_notes]}\" -F distribution_lists='#{@values[:testflight_list]}'`
     end
     
     builder
   end
   
  end
end