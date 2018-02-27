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

#include <cassert>
#include <cstdio>

namespace mingine {

const int MAX_CONTROLLERS = 4;
const int JOYSTICK_DEADZONE = 6000;
const int NUM_SDL_SCANCODES = 512;
bool prevKeys[NUM_SDL_SCANCODES];
bool keys[NUM_SDL_SCANCODES];

// this is scratchpad memory to build strings for logging, debugging, etc.
char stringBuilderBuffer[MAX_STRING];

SDL_Window* window = nullptr;
SDL_Renderer* renderer = nullptr;
SDL_Texture* backbuffer = nullptr;
SDL_Joystick* controllers[MAX_CONTROLLERS];

void acquireController(int controllerIndex)
{
	assert(controllerIndex >= 0 && controllerIndex < MAX_CONTROLLERS);
	assert(controllers[controllerIndex] == nullptr);
	controllers[controllerIndex] = SDL_JoystickOpen(controllerIndex);
}

void releaseController(int controllerIndex)
{
	assert(controllerIndex >= 0 && controllerIndex < MAX_CONTROLLERS);

	if (controllers[controllerIndex])
	{
		SDL_JoystickClose(controllers[controllerIndex]);
		controllers[controllerIndex] = nullptr;
	}
}

void detectDisplayModes(int displayIndex)
{
	SDL_DisplayMode mode;
	int numModes = SDL_GetNumDisplayModes(displayIndex);

	for (int i = 0; i < numModes; ++i)
	{
		int result = SDL_GetDisplayMode(displayIndex, i, &mode);

		if (result) // != 0 indicates an error
		{
			SDL_Log("Error reading display mode %i %i: %s", displayIndex, i, SDL_GetError());
		}
		else
		{
			SDL_Log("Display Mode %i %i: %i x %i @%ihz", displayIndex, i, mode.w, mode.h, mode.refresh_rate);
		}
	}
}

void detectCurrentDisplayMode(int displayIndex)
{
	SDL_DisplayMode mode;
	int result = SDL_GetCurrentDisplayMode(displayIndex, &mode);

	if (result) // != 0 indicates an error
	{
		SDL_Log("Error reading current display mode for display %i: %s", displayIndex, SDL_GetError());
	}
	else
	{
		SDL_Log("Current Display Mode for Display %i: %i x %i @%ihz format: %i", displayIndex, mode.w, mode.h, mode.refresh_rate, mode.format);
	}
}

bool initPlatform(int screenWidth, int screenHeight, bool fullscreen)
{
	for (int i = 0; i < MAX_CONTROLLERS; ++i)
	{
		controllers[i] = nullptr;
	}

	if (SDL_Init(SDL_INIT_EVERYTHING) < 0)
    {
        return false;
    }

	int numDisplays = SDL_GetNumVideoDisplays();
	for (int i = 0; i < numDisplays; ++i)
	{
		//detectDisplayModes(i);
		detectCurrentDisplayMode(i);
	}
			
	Uint32 flags = SDL_WINDOW_SHOWN;
	if (fullscreen)
	{
		flags |= SDL_WINDOW_FULLSCREEN;
	}

	window = SDL_CreateWindow("", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, screenWidth, screenHeight, flags);

	if (!window)
	{
		return false;
	}

	renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);

	if (!renderer)
	{
		return false;
	}

	SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
	SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0xff, 0xff);
	SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

	int imageFlags = IMG_INIT_PNG;
	if (!(IMG_Init(imageFlags) & imageFlags))
	{
		return false;
	}
	    
    if (Mix_OpenAudio(22050, MIX_DEFAULT_FORMAT, 2, 1024) == -1)
    {
        return false;
    }

    if (TTF_Init() == -1)
    {
        return false;
    }

	backbuffer = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, screenWidth, screenHeight);
	
	if (!backbuffer)
	{
		return false;
	}
		
	return true;
}

void freePlatform()
{
	for (int i = 0; i < MAX_CONTROLLERS; ++i)
	{
		releaseController(i);
	}
	
	SDL_DestroyTexture(backbuffer);
    SDL_DestroyWindow(window);
	SDL_DestroyRenderer(renderer);
    Mix_CloseAudio();
    TTF_Quit();
	IMG_Quit();
    SDL_Quit();
}

// set the title of the window in the title bar (not visible in fullscreen mode)
void setWindowTitle(const char* title)
{
	SDL_SetWindowTitle(window, title);
}

// Handles incoming events from the OS and SDL.
// parameter eventHandler can be null
bool pollEvents(void (*eventHandler)(const char*, int value))
{
    SDL_Event event;

    bool running = true;

    while (SDL_PollEvent(&event))
    {
		switch (event.type)
		{
		case SDL_JOYAXISMOTION:
			if (eventHandler != nullptr)
			{
				snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "controller_%i_axis_%i", event.jdevice.which, event.jaxis.axis);
				
				if (abs(event.jaxis.value) > JOYSTICK_DEADZONE)
				{
					eventHandler(stringBuilderBuffer, event.jaxis.value);

					//snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "axis: %i %i %i", event.jdevice.which, event.jaxis.axis, event.jaxis.value);
					//log(stringBuilderBuffer);
				}
				else
				{
					eventHandler(stringBuilderBuffer, 0);
				}
			}
			break;
		case SDL_JOYBUTTONDOWN:
			if (eventHandler != nullptr)
			{
				snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "controller_%i_button_%i", event.jbutton.which, event.jbutton.button);
				eventHandler(stringBuilderBuffer, 1);
			}

			//snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "button down: %i %i", event.jbutton.which, event.jbutton.button);
			//log(stringBuilderBuffer);
			break;
		case SDL_JOYBUTTONUP:
			if (eventHandler != nullptr)
			{
				snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "controller_%i_button_%i", event.jbutton.which, event.jbutton.button);
				eventHandler(stringBuilderBuffer, 0);
			}

			//snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "button up: %i %i", event.jbutton.which, event.jbutton.button);
			//log(stringBuilderBuffer);
			break;
		case SDL_JOYHATMOTION:
			if (eventHandler != nullptr)
			{
				snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "controller_%i_hat", event.jhat.which);
				eventHandler(stringBuilderBuffer, event.jhat.value);
			}

			//snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "hat motion: %i %i", event.jhat.which, event.jhat.value);
			//log(stringBuilderBuffer);
			break;
			break;
		case SDL_JOYDEVICEADDED:
			acquireController(event.jdevice.which);
			break;
		case SDL_JOYDEVICEREMOVED:
			releaseController(event.jdevice.which);
			break;
		case SDL_KEYDOWN:
			keys[event.key.keysym.scancode] = true;

			if (event.key.keysym.sym == SDLK_ESCAPE)
			{
				running = false;
			}
			break;
		case SDL_KEYUP:
			keys[event.key.keysym.scancode] = false;
			break;
		case SDL_QUIT:
			running = false;
			break;
		}
    }

    return running;
}

void updateInput(int* mouseX, int* mouseY)
{
	SDL_GetMouseState(mouseX, mouseY);
}

bool isMouseButtonDown(int buttonId)
{
	return (SDL_GetMouseState(nullptr, nullptr) & SDL_BUTTON(buttonId)) != 0;
}

void getRenderState(Render::Setting renderSetting, RenderParameters& renderParameters)
{
	switch (renderSetting)
	{
	case Render::DrawColor:
		SDL_GetRenderDrawColor(renderer, &renderParameters.u8[0], &renderParameters.u8[1], &renderParameters.u8[2], &renderParameters.u8[3]);
		break;
	case Render::LogicalSize:
		SDL_RenderGetLogicalSize(renderer, &renderParameters.i[0], &renderParameters.i[1]);
		break;
	case Render::Scale:
		SDL_RenderGetScale(renderer, &renderParameters.f[0], &renderParameters.f[1]);
		break;
	}
}

void setRenderState(Render::Setting renderSetting, RenderParameters& renderParameters)
{
	switch (renderSetting)
	{
	case Render::DrawColor:
		SDL_SetRenderDrawColor(renderer, renderParameters.u8[0], renderParameters.u8[1], renderParameters.u8[2], renderParameters.u8[3]);
		break;
	case Render::LogicalSize:
		SDL_RenderSetLogicalSize(renderer, renderParameters.i[0], renderParameters.i[1]); 
		break;
	case Render::Scale:
		SDL_RenderSetScale(renderer, renderParameters.f[0], renderParameters.f[1]);
		break;
	}
}

void drawPoint(int x, int y)
{
	SDL_RenderDrawPoint(renderer, x, y);
}

void drawLine(int startX, int startY, int endX, int endY)
{
	SDL_RenderDrawLine(renderer, startX, startY, endX, endY);
}

void drawCircle(int x, int y, int radius)
{
	float angleStep = (float)(M_PI / 16.0);
	float angle = 0.0f;

	int prevX = x + (int)(cos(angle) * radius);
	int prevY = y + (int)(sin(angle) * radius);
	
	for (int side = 0; side < 32; ++side )
	{
		angle += angleStep;
		int nextX = x + (int)(cos(angle) * radius);
		int nextY = y + (int)(sin(angle) * radius);

		SDL_RenderDrawLine(renderer, prevX, prevY, nextX, nextY);
		
		prevX = nextX;
		prevY = nextY;
	}
}

void drawRect(int x, int y, int w, int h)
{
	SDL_Rect rect{ x, y, w, h };
	SDL_RenderDrawRect(renderer, &rect);
}

void fillRect(int x, int y, int w, int h)
{
	SDL_Rect rect{ x, y, w, h };
	SDL_RenderFillRect(renderer, &rect);
}

void clearScreen(uint8_t r, uint8_t g, uint8_t b)
{
	SDL_SetRenderDrawColor(renderer, r, g, b, 0xff);
	SDL_RenderClear(renderer);
}

void beginFrame()
{
	SDL_SetRenderTarget(renderer, backbuffer);
}

// The code below can be used to rotate the backbuffer. This might be a useful effect
// when transitioning to a new game state or something, but this is currently a w.i.p. It works here
// but has not been exposed to script. Also, there are issues with fullscreen possibly, I forget.
void presentFrameRotating()
{
	SDL_SetRenderTarget(renderer, nullptr);

	static double angle = 0;
	int w = 0;
	int h = 0;

	SDL_QueryTexture(backbuffer, nullptr, nullptr, &w, &h);

	w = (int)(w / 1.5f);
	h = (int)(h / 1.5f);

	SDL_Rect destRect;
	destRect.x = w / 2 - w / 4;
	destRect.y = h / 2 - h / 4;
	destRect.w = w;
	destRect.h = h;

	SDL_Point center = { w / 2, h / 2 };

	clearScreen(0, 0, 0);
	SDL_RenderCopyEx(renderer, backbuffer, nullptr, &destRect, angle, &center, SDL_FLIP_NONE);
	angle += 0.4;

	SDL_RenderPresent(renderer);
}

void presentFrame()
{
	SDL_SetRenderTarget(renderer, nullptr);
			
	clearScreen(0, 0, 0);

	SDL_RenderCopyEx(renderer, backbuffer, nullptr, nullptr, 0, nullptr, SDL_FLIP_NONE);
	SDL_RenderPresent(renderer);
}

void endUpdate()
{
	SDL_memcpy(&prevKeys, &keys, NUM_SDL_SCANCODES);
}

void stopMusic()
{
	Mix_HaltMusic();
}

void log(const char* message)
{
	SDL_Log("%s\n", message);
}

void showErrorBox(const char* message)
{
	SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Error", message, nullptr);
}

} // end of namespace mingine 
