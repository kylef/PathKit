Pod::Spec.new do |spec|
  spec.name = 'PathKit'
  spec.version = '1.0.0'
  spec.summary = 'Effortless path operations in Swift.'
  spec.homepage = 'https://github.com/kylef/PathKit'
  spec.license = { :type => 'BSD', :file => 'LICENSE' }
  spec.author = { 'Kyle Fuller' => 'kyle@fuller.li' }
  spec.social_media_url = 'http://twitter.com/kylefuller'
  spec.source = { :git => 'https://github.com/kylef/PathKit.git', :tag => spec.version }
  spec.source_files = 'Sources/PathKit.swift'
  spec.ios.deployment_target = '8.0'
  spec.osx.deployment_target = '10.9'
  spec.tvos.deployment_target = '9.0'
  spec.requires_arc = true
end
