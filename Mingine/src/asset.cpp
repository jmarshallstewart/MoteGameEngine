#include "asset.h"
#include "platform.h"

#ifdef _WIN32
#include <SDL_image.h>
#include <SDL_mixer.h>
#include <SDL_ttf.h>
#else
#include <SDL2/SDL_image.h>
#include <SDL2/SDL_mixer.h>
#include <SDL2/SDL_ttf.h>
#endif

namespace mingine {

extern SDL_Renderer* renderer;

Asset::Asset()
{
    // do nothing
}

Asset::~Asset()
{
    // do nothing
}

bool Image::load(const LoadParameters& loadParameters)
{
	assetData = nullptr;
	SDL_Surface* imageLoaded = IMG_Load(loadParameters.path);
	
	if (imageLoaded != nullptr)
	{
		assetData = SDL_CreateTextureFromSurface(renderer, imageLoaded);
		
		if (assetData == nullptr)
		{
			return false;
		}

		SDL_FreeSurface(imageLoaded);
	}
	else
	{
		SDL_Log(IMG_GetError());
	}

	return !SDL_QueryTexture((SDL_Texture*)assetData, nullptr, nullptr, &width, &height); 
}

void Image::free()
{
    SDL_DestroyTexture((SDL_Texture*)assetData);
    assetData = nullptr;
}

// param angle = angle in degrees, + rotation = clockwise
void Image::draw(int x, int y, double angle, double scale, uint8_t r, uint8_t g, uint8_t b)
{
	SDL_Rect destRect;
	destRect.x = x;
	destRect.y = y;
	destRect.w = (int)(width * scale);
	destRect.h = (int)(height * scale);

	SDL_SetTextureColorMod((SDL_Texture*)assetData, r, g, b);
	SDL_RenderCopyEx(renderer, (SDL_Texture*)assetData, nullptr, &destRect, angle, nullptr, SDL_FLIP_NONE);
}

void Image::drawFrame(int x, int y, int frameWidth, int frameHeight, int frame, double angle, double scale, uint8_t r, uint8_t g, uint8_t b)
{
	SDL_Rect destRect;
	destRect.x = x;
	destRect.y = y;
	destRect.w = (int)(frameWidth * scale);
	destRect.h = (int)(frameHeight * scale);

	int columns = width / frameWidth;

	SDL_Rect sourceRect;
	sourceRect.x = (frame % columns) * frameWidth;
	sourceRect.y = (frame / columns) * frameHeight;
	sourceRect.w = frameWidth;
	sourceRect.h = frameHeight;

	SDL_SetTextureColorMod((SDL_Texture*)assetData, r, g, b);
	SDL_RenderCopyEx(renderer, (SDL_Texture*)assetData, &sourceRect, &destRect, angle, nullptr, SDL_FLIP_NONE);
}

bool Font::load(const LoadParameters& loadParameters)
{
    assetData = TTF_OpenFont(loadParameters.path, loadParameters.size);
    return assetData != nullptr;
}

void Font::free()
{
    TTF_CloseFont((TTF_Font*)assetData);
    assetData = nullptr;
}

void Font::draw(const char* text, int x, int y, uint8_t r, uint8_t g, uint8_t b)
{
	SDL_Surface* textDestination = nullptr;

	SDL_Color color;

	color.r = r;
	color.g = g;
	color.b = b;

	textDestination = TTF_RenderText_Solid((TTF_Font*)assetData, text, color);
	SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, textDestination);

	SDL_Rect destRect;
	destRect.x = x;
	destRect.y = y;
	destRect.w = textDestination->w;
	destRect.h = textDestination->h;

	SDL_RenderCopy(renderer, texture, nullptr, &destRect);
	
	SDL_FreeSurface(textDestination);
	SDL_DestroyTexture(texture);
}

bool Sound::load(const LoadParameters& loadParameters)
{
    assetData = Mix_LoadWAV(loadParameters.path);
    return assetData != nullptr;
}

void Sound::free()
{
    Mix_FreeChunk((Mix_Chunk*)assetData);
    assetData = nullptr;
}

void Sound::play()
{
    Mix_PlayChannel(-1, (Mix_Chunk*)assetData, 0);
}

bool Music::load(const LoadParameters& loadParameters)
{
    assetData = Mix_LoadMUS(loadParameters.path);
    return assetData != nullptr;
}

void Music::free()
{
    Mix_FreeMusic((Mix_Music*)assetData);
    assetData = nullptr;
}

void Music::play()
{
    Mix_PlayMusic((Mix_Music*)assetData, -1);
}

} // end of namespace mingine 