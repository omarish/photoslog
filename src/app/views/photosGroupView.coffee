View = require('view')
ImageView = require('imageView')
ratio = require('ratio')
months = require('months')
config = require('config')

class PhotosGroupView extends View
  className: 'photosGroupView'

  constructor: ->
    super
    @loaded = false
    @cacheFrame = true

  render: =>
    @label = new View(tag: 'h2')
    @label.text(@options.group.name)
    @addSubview(@label)

    @date = new View(tag: 'span')
    date = new Date(@options.group.date)
    monthString = months[date.getMonth()].toUpperCase()
    @date.text("#{monthString} #{date.getFullYear()}")
    @label.addSubview(@date)

    @appendFullImage(@options.group.images[0])
    @appendRowImages(@options.group.images[1..@options.group.images.length - 1])

  bindEvents: =>
    window.addEventListener('resize', @invalidate)
    window.addEventListener('resize', @onResize)
    @on('addedToDOM', @layout)

  appendFullImage: (image) =>
    @fullImage = image
    image.view = @createImageView(image, 'full')
    @addSubview(image.view)

  appendRowImages: (images) =>
    @images = images
    margins = (@images.length - 1) * 7

    totalWidthAt1000 = 0
    # Process ratios
    for image in @images
      image.ratio = image.size.width / image.size.height
      totalWidthAt1000 += 1000 * image.ratio
    for image in @images
      image.layout =
        widthPercent: 1000 * image.ratio / totalWidthAt1000

    # Render
    for i, image of @images
      image.view = @createImageView(image, 'row')
      @addSubview(image.view)
      image.view.el.style.width = "calc((100% - #{margins}px) * #{image.layout.widthPercent})"

  layout: =>
    imageWidth = @images[0].view.width()
    return if !imageWidth

    margins = (@images.length - 1) * 7

    # Layout
    height = imageWidth / @images[0].ratio
    for i, image of @images
      image.view.el.style.height = "#{height}px"

    @fullImage.view.el.style.height = "#{@fullImage.size.height / @fullImage.size.width * @fullImage.view.width()}px"
    @invalidateCachedFrame()

  createImageView: (image, type) =>
    imageRatio = if type == 'full' then ratio else "1x"
    filePath = image.files[imageRatio]
    imageView = new ImageView(
      className: type,
      queue: @options.queue,
      imagePath: config.imagesRootPath + filePath,
      object: image,
      loadingIndicator: true
    )
    imageView.on('click', @onClick)
    imageView

  loadImages: =>
    for i, image of @images
      image.view.load()
    @fullImage.view.load()

  setDisabled: (bool) =>
    @el.classList.toggle('disabled', bool)
    for i, image of @images
      image.view.setDisabled(bool)
    @fullImage.view.setDisabled(bool)

  imageViewForImage: (image) =>
    for view in @subviews
      return view if view.options.object == image
    return null

  # Events
  onClick: (imageView) =>
    @trigger('click', @, imageView, imageView.options.object)

  onResize: =>
    @setDisabled(true)
    clearTimeout(@resizeTimeout) if @resizeTimeout?
    @resizeTimeout = setTimeout(=>
      @setDisabled(false)
      @layout()
    , 300)

module.exports = PhotosGroupView
