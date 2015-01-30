Heathen::Task.register 'smooth_greyscale_tiff', 'image/.*' do |job|
  ImageConverter.convert_to_tiff job, resolution: '300dpi'
  ImageConverter.smooth_speckling job
end

Heathen::Task.register 'ocr', 'image/.*' do |job|
  Task.perform 'smooth_greyscale_tiff', job
  Tesseract.perform job
end
