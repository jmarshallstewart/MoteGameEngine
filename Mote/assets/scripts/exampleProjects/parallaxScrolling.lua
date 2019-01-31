-- This script demonstrates how to create a parallax scrolling background.

BACKGROUND_WIDTH = 272
BACKGROUND_HEIGHT = 160
SCALE = 2
parallaxLayers = {}

function AddParallaxLayer(imagePath, scrollSpeed)
	layer = {}
	layer.image = LoadImage(imagePath)
	layer.x1 = 0
	layer.width = GetImageWidth(layer.image)
	layer.x2 = layer.width
	layer.scrollSpeed = scrollSpeed
	
	parallaxLayers[#parallaxLayers + 1] = layer
end

function Start()
    CreateWindow(BACKGROUND_WIDTH * SCALE, BACKGROUND_HEIGHT * SCALE)
    SetWindowTitle("Parallax Scrolling")
	
	backgroundImage = LoadImage("images/parallaxLayers/parallax-mountain-bg.png")
	
	AddParallaxLayer("images/parallaxLayers/parallax-mountain-mountain-far.png", 0.5)
	AddParallaxLayer("images/parallaxLayers/parallax-mountain-mountains.png", 1)
	AddParallaxLayer("images/parallaxLayers/parallax-mountain-trees.png", 1.5)
	AddParallaxLayer("images/parallaxLayers/parallax-mountain-foreground-trees.png", 2)
end

function Update()
	for i = 1, #parallaxLayers do
		local layer = parallaxLayers[i]
		
		layer.x1 = layer.x1 - layer.scrollSpeed
		if layer.x1 <= -layer.width then layer.x1 = layer.width end
		
		layer.x2 = layer.x2 - layer.scrollSpeed
		if layer.x2 <= -layer.width then layer.x2 = layer.width end
	end
end

function Draw()
	--not needed for scrolling algorithm; just here to make the background larger.
	SetDrawScale(SCALE, SCALE)
	
	DrawImage(backgroundImage, 0, 0)
	
	for i = 1, #parallaxLayers do
		DrawImage(parallaxLayers[i].image, parallaxLayers[i].x1, 0)
		DrawImage(parallaxLayers[i].image, parallaxLayers[i].x2, 0)
	end
end