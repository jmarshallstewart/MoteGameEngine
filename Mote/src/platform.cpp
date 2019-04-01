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
#include <cstring> // for memset
#include <map>

namespace mote {

	const int MAX_CONTROLLERS = 4;
	const int JOYSTICK_DEADZONE = 6000;
	const int MAX_CONTROLLER_BUTTONS = 10;
	const int MAX_CONTROLLER_AXES = 6;
	const int NUM_SDL_SCANCODES = 512;
	bool prevKeys[NUM_SDL_SCANCODES];
	bool keys[NUM_SDL_SCANCODES];

	// NOTE: There are actually three sets of IDs to keep up when using controllers.
	// The SDL2 API makes this confusing because event.jdevice.which refers to the
	// device id when acquiring the controller, but the joystick id when releasing the
	// controller. (Not all devices are joysticks, hence the difference, but the way it is
	// handled in SDL2 is confusing.) To make things more clear, the names of parameters, 
	// variables, etc. will use this terminology to help keep things clear:
	// Device Id: The nth input device attached to the system.
	// Joystick Id: The id used internally by SDL to identify different game controllers.
	// Controller Id: The index of the controller from the POV of Mote (0 = player 1, 1 = player 2, etc.)
	// Mote consistently uses Controller Id to identify the controller in Lua and in Platform functions,
	// but uses Device Id and Joystick Id internally to acquire, release, and read the controllers.
	class Controller
	{
	public:
		float axis[MAX_CONTROLLER_AXES];
		bool button[MAX_CONTROLLER_BUTTONS];
		int hat;
		SDL_Joystick* sdlJoystick{ nullptr };
		
		bool isAttached() const
		{
			return sdlJoystick != nullptr;
		}

		int attach(SDL_Joystick* joystick)
		{
			std::memset(this, 0, sizeof(Controller));
			sdlJoystick = joystick;

			for (int i = 0; i < MAX_CONTROLLER_AXES; ++i)
			{
				setAxis(i, SDL_JoystickGetAxis(sdlJoystick, i));
			}
						
			return SDL_JoystickInstanceID(sdlJoystick);
		}

		void detach()
		{
			SDL_JoystickClose(sdlJoystick);
			sdlJoystick = nullptr;
		}

		void setAxis(int axisId, int rawAxisValue)
		{
			assert(axisId >= 0 && axisId < MAX_CONTROLLER_AXES);

			if (abs(rawAxisValue) > JOYSTICK_DEADZONE)
			{
				axis[axisId] = rawAxisValue / 32768.0f;
			}
			else
			{
				axis[axisId] = 0;
			}
		}
	};

	// this is scratchpad memory to build strings for logging, debugging, etc.
	char stringBuilderBuffer[MAX_STRING];

	SDL_Window* window = nullptr;
	SDL_Renderer* renderer = nullptr;
	SDL_Texture* backbuffer = nullptr;
	Controller controllers[MAX_CONTROLLERS];
	std::map<int, int> joystickIdToPlayerId;

	int getAvailableController()
	{
		for (int i = 0; i < MAX_CONTROLLERS; ++i)
		{
			if (!controllers[i].isAttached())
			{
				return i;
			}
		}

		// no more controllers slots are available.
		return -1;
	}
		
	void acquireController(int deviceId)
	{
		int availableSlot = getAvailableController();

		if (availableSlot == -1)
		{
			log("Max controller slots exceeded. Ignoring new controller.");
		}
		else
		{
			SDL_Joystick* joystick = SDL_JoystickOpen(deviceId);
			int joystickId = controllers[availableSlot].attach(joystick);
			joystickIdToPlayerId[joystickId] = availableSlot;

			snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "Acquiring controller: %i", availableSlot);
			log(stringBuilderBuffer);
		}
	}

	void releaseController(int joystickId)
	{
		int playerId = joystickIdToPlayerId[joystickId];

		snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "Releasing controller: %i", playerId);
		log(stringBuilderBuffer);

		assert(playerId >= 0 && playerId < MAX_CONTROLLERS);
		assert(controllers[playerId].isAttached());

		controllers[playerId].detach();
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
			if (controllers[i].isAttached())
			{
				controllers[i].detach();
			}
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
	bool pollEvents()
	{
		SDL_Event event;

		bool running = true;
		int playerId;

		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
			case SDL_JOYAXISMOTION:
				playerId = joystickIdToPlayerId[event.jdevice.which];
				controllers[playerId].setAxis(event.jaxis.axis, event.jaxis.value);
				break;
			case SDL_JOYBUTTONDOWN:
				playerId = joystickIdToPlayerId[event.jbutton.which];
				controllers[playerId].button[event.jbutton.button] = true;
				break;
			case SDL_JOYBUTTONUP:
				playerId = joystickIdToPlayerId[event.jbutton.which];
				controllers[playerId].button[event.jbutton.button] = false;
				break;
			case SDL_JOYHATMOTION:
				playerId = event.jhat.which;
				controllers[playerId].hat = event.jhat.value;
				break;
			case SDL_JOYDEVICEADDED:
				acquireController(event.jdevice.which); // here which == device id.
				break;
			case SDL_JOYDEVICEREMOVED:
				releaseController(event.jdevice.which); // here which == joystick id.
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

	bool isControllerAttached(int controllerId)
	{
		assert(controllerId >= 0 && controllerId < MAX_CONTROLLERS);
		
		return controllers[controllerId].isAttached();
	}

	bool readControllerButton(int controllerId, int buttonId)
	{
		assert(controllerId >= 0 && controllerId < MAX_CONTROLLERS);
		assert(buttonId >= 0 && buttonId < MAX_CONTROLLER_BUTTONS);

		return controllers[controllerId].button[buttonId];
	}

	int readControllerHat(int controllerId)
	{
		assert(controllerId >= 0 && controllerId < MAX_CONTROLLERS);

		return controllers[controllerId].hat;
	}

	float readControllerAxis(int controllerId, int axisId)
	{
		assert(controllerId >= 0 && controllerId < MAX_CONTROLLERS);
		assert(axisId >= 0 && axisId < MAX_CONTROLLER_AXES);

		return controllers[controllerId].axis[axisId];
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

		for (int side = 0; side < 32; ++side)
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

} // end of namespace mote