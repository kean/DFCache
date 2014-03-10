Pod::Spec.new do |s|
    s.name = 'DFCache'
    s.version = '1.0.0'
    s.license = 'MIT'
    s.homepage = 'https://github.com/kean/DFCache'
    s.authors = 'Alexander Grebenyuk'
    s.summary = 'Composite cache with LRU cleaup. User metadata on top of UNIX extended file attributes.'

    s.ios.deployment_target = '6.0'
    s.osx.deployment_target = '10.7'
    s.requires_arc = true
    s.source = {
        :git => 'https://github.com/kean/DFCache.git',
        :tag => s.version.to_s
    }
    s.public_header_files = 'DFCache/*.{h}', 'DFCache/Extended File Attributes/*.{h}', 'DFCache/Key-Value File Storage/*.{h.}'
    s.source_files = 'DFCache/**/*.{h,m}'
end
