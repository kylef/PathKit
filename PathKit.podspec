Pod::Spec.new do |spec|
  spec.name = 'PathKit'
  spec.version = '0.1.0'
  spec.summary = 'Effortless path operations in Swift.'
  spec.homepage = 'https://github.com/kylef/PathKit'
  spec.license = { :type => 'BSD', :file => 'LICENSE' }
  spec.author = { 'Kyle Fuller' => 'inbox@kylefuller.co.uk' }
  spec.social_media_url = 'http://twitter.com/kylefuller'
  spec.source = { :git => 'https://github.com/kylef/PathKit.git', :tag => "#{spec.version}" }
  spec.source_files = 'PathKit/PathKit.swift'
  spec.requires_arc = true
end

