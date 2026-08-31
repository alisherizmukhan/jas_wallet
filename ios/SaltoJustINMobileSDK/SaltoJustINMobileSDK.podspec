Pod::Spec.new do |s|
  s.name             = 'SaltoJustINMobileSDK'
  s.version          = '4.1.0'
  s.summary          = 'SALTO JustIN Mobile SDK for BLE/NFC access'
  s.homepage         = 'https://www.salto.com'
  s.license          = { :type => 'Commercial' }
  s.author           = 'SALTO Systems'
  s.source           = { :path => '.' }
  s.ios.deployment_target = '15.0'
  s.vendored_frameworks = 'SaltoJustINMobileSDK.xcframework'
  s.frameworks = 'CoreBluetooth'
end
