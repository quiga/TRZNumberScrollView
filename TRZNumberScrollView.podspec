Pod::Spec.new do |spec|
  spec.name         = 'TRZNumberScrollView'
  spec.version      = '0.1'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/thomasrzhao/TRZNumberScrollView'
  spec.authors      = 'Thomas Zhao'
  spec.summary      = 'An efficient animated number scrolling view for iOS and OS X.'
  spec.source       = { :git => 'https://github.com/thomasrzhao/TRZNumberScrollView.git', :branch => 'master' }
  spec.source_files = 'NumberScrollView.swift'
  spec.ios.deployment_target  = '10.0'
end